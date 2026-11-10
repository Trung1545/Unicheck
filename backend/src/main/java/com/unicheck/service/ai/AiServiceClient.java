package com.unicheck.service.ai;

import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.ai.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
public class AiServiceClient {

    private final RestClient restClient;
    private final String aiServiceUrl;
    private final ObjectMapper objectMapper;

    public AiServiceClient(
            @Value("${ai-service.url:http://localhost:5000}") String aiServiceUrl,
            ObjectMapper objectMapper
    ) {
        this.aiServiceUrl = aiServiceUrl;
        this.objectMapper = objectMapper != null ? objectMapper : new ObjectMapper();
        this.restClient = RestClient.builder()
                .baseUrl(aiServiceUrl)
                .build();
    }

    /**
     * Gửi ảnh sang AI Service trích xuất vector đặc trưng 512 chiều ArcFace.
     */
    public AiExtractEmbeddingResponse extractEmbedding(String imageBase64) {
        if (imageBase64 == null || imageBase64.trim().isEmpty()) {
            throw new AppException(ErrorCode.INVALID_REQUEST, "Chuỗi ảnh Base64 không được để trống");
        }

        String correlationId = UUID.randomUUID().toString().substring(0, 8);
        log.info("[CorrID={}] Bắt đầu gửi yêu cầu trích xuất embedding tới AI Service", correlationId);

        try {
            AiExtractEmbeddingRequest request = AiExtractEmbeddingRequest.builder()
                    .imageBase64(imageBase64)
                    .build();

            AiExtractEmbeddingResponse response = restClient.post()
                    .uri("/api/v1/face/extract-embedding")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(request)
                    .retrieve()
                    .onStatus(HttpStatusCode::is4xxClientError, (req, resp) -> {
                        int statusCode = resp.getStatusCode().value();
                        AiExtractEmbeddingResponse errBody = null;
                        try {
                            errBody = objectMapper.readValue(resp.getBody(), AiExtractEmbeddingResponse.class);
                        } catch (Exception parseEx) {
                            log.warn("[CorrID={}] Không thể giải mã body lỗi 4xx từ AI Service: {}", correlationId, parseEx.getMessage());
                        }

                        String errCode = errBody != null ? errBody.getErrorCode() : null;
                        String errMsg = errBody != null && errBody.getMessage() != null
                                ? errBody.getMessage()
                                : "Lỗi xử lý ảnh từ AI Service (HTTP " + statusCode + ")";

                        log.warn("[CorrID={}] AI Service báo lỗi 4xx (HTTP {}): errorCode={}, message={}",
                                correlationId, statusCode, errCode, errMsg);

                        if ("ERR_3001".equals(errCode)) {
                            throw new AppException(ErrorCode.FACE_NOT_DETECTED, errMsg);
                        }
                        if ("ERR_3002".equals(errCode)) {
                            throw new AppException(ErrorCode.MULTIPLE_FACES_DETECTED, errMsg);
                        }
                        if ("ERR_3023".equals(errCode) || "ERR_1001".equals(errCode)) {
                            throw new AppException(ErrorCode.FACE_IMAGE_INVALID, errMsg);
                        }
                        throw new AppException(ErrorCode.INVALID_REQUEST, errMsg);
                    })
                    .onStatus(HttpStatusCode::is5xxServerError, (req, resp) -> {
                        int statusCode = resp.getStatusCode().value();
                        String errorMsg = "AI Service báo lỗi nội bộ (HTTP " + statusCode + ")";
                        try {
                            AiExtractEmbeddingResponse errBody = objectMapper.readValue(resp.getBody(), AiExtractEmbeddingResponse.class);
                            if (errBody != null && errBody.getMessage() != null) {
                                errorMsg = errBody.getMessage();
                            }
                        } catch (Exception parseEx) {
                            log.warn("[CorrID={}] Không thể giải mã body lỗi 5xx từ AI Service: {}", correlationId, parseEx.getMessage());
                        }
                        log.error("[CorrID={}] AI Service báo lỗi 5xx (HTTP {}): message={}", correlationId, statusCode, errorMsg);
                        throw new AppException(ErrorCode.AI_SERVICE_UNAVAILABLE, errorMsg);
                    })
                    .body(AiExtractEmbeddingResponse.class);

            if (response == null || !Boolean.TRUE.equals(response.getSuccess()) || response.getEmbedding() == null) {
                String errCode = response != null ? response.getErrorCode() : null;
                String errMsg = response != null && response.getMessage() != null
                        ? response.getMessage()
                        : "Không nhận được vector đặc trưng từ AI Service";

                log.warn("[CorrID={}] Phản hồi AI Service không hợp lệ: success={}, errorCode={}, message={}",
                        correlationId, response != null ? response.getSuccess() : null, errCode, errMsg);

                if ("ERR_3001".equals(errCode)) {
                    throw new AppException(ErrorCode.FACE_NOT_DETECTED, errMsg);
                }
                if ("ERR_3002".equals(errCode)) {
                    throw new AppException(ErrorCode.MULTIPLE_FACES_DETECTED, errMsg);
                }
                throw new AppException(ErrorCode.AI_SERVICE_UNAVAILABLE, errMsg);
            }

            log.info("[CorrID={}] Trích xuất vector thành công: model={}, version={}, dimension={}",
                    correlationId, response.getModelName(), response.getModelVersion(), response.getEmbedding().size());

            return response;
        } catch (AppException e) {
            throw e;
        } catch (Exception e) {
            log.error("[CorrID={}] Lỗi kết nối tới AI Service ({}): {}", correlationId, aiServiceUrl, e.getMessage());
            throw new AppException(ErrorCode.AI_SERVICE_UNAVAILABLE, "Không thể kết nối đến AI Service để nhận diện khuôn mặt");
        }
    }

    /**
     * So khớp vector khuôn mặt đã đăng ký với ảnh điểm danh thực tế (Cosine Similarity).
     */
    public AiVerifyFaceResponse verifyFace(List<Float> sourceEmbedding, String targetImageBase64, Double threshold) {
        if (sourceEmbedding == null || sourceEmbedding.isEmpty()) {
            throw new AppException(ErrorCode.INVALID_REQUEST, "Vector đặc trưng gốc không được để trống");
        }
        if (targetImageBase64 == null || targetImageBase64.trim().isEmpty()) {
            throw new AppException(ErrorCode.INVALID_REQUEST, "Ảnh điểm danh không được để trống");
        }

        String correlationId = UUID.randomUUID().toString().substring(0, 8);
        log.info("[CorrID={}] Bắt đầu gửi yêu cầu so khớp khuôn mặt tới AI Service", correlationId);

        try {
            AiVerifyFaceRequest request = AiVerifyFaceRequest.builder()
                    .sourceEmbedding(sourceEmbedding)
                    .targetImageBase64(targetImageBase64)
                    .threshold(threshold != null ? threshold : 0.68)
                    .metric("cosine")
                    .build();

            AiVerifyFaceResponse response = restClient.post()
                    .uri("/api/v1/face/verify-face")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(request)
                    .retrieve()
                    .onStatus(HttpStatusCode::is4xxClientError, (req, resp) -> {
                        int statusCode = resp.getStatusCode().value();
                        AiVerifyFaceResponse errBody = null;
                        try {
                            errBody = objectMapper.readValue(resp.getBody(), AiVerifyFaceResponse.class);
                        } catch (Exception parseEx) {
                            log.warn("[CorrID={}] Không thể giải mã body 4xx verifyFace: {}", correlationId, parseEx.getMessage());
                        }

                        String errCode = errBody != null ? errBody.getErrorCode() : null;
                        String errMsg = errBody != null && errBody.getMessage() != null
                                ? errBody.getMessage()
                                : "Lỗi so khớp khuôn mặt (HTTP " + statusCode + ")";

                        log.warn("[CorrID={}] AI Service verify-face báo lỗi 4xx (HTTP {}): errorCode={}, message={}",
                                correlationId, statusCode, errCode, errMsg);

                        if ("ERR_3001".equals(errCode)) {
                            throw new AppException(ErrorCode.FACE_NOT_DETECTED, errMsg);
                        }
                        if ("ERR_3002".equals(errCode)) {
                            throw new AppException(ErrorCode.MULTIPLE_FACES_DETECTED, errMsg);
                        }
                        if ("ERR_3004".equals(errCode)) {
                            throw new AppException(ErrorCode.FACE_NOT_MATCHED, errMsg);
                        }
                        if ("ERR_3023".equals(errCode) || "ERR_1001".equals(errCode)) {
                            throw new AppException(ErrorCode.FACE_IMAGE_INVALID, errMsg);
                        }
                        throw new AppException(ErrorCode.INVALID_REQUEST, errMsg);
                    })
                    .onStatus(HttpStatusCode::is5xxServerError, (req, resp) -> {
                        int statusCode = resp.getStatusCode().value();
                        log.error("[CorrID={}] AI Service verifyFace báo lỗi 5xx (HTTP {})", correlationId, statusCode);
                        throw new AppException(ErrorCode.AI_SERVICE_UNAVAILABLE, "Dịch vụ AI nhận diện khuôn mặt tạm thời không khả dụng");
                    })
                    .body(AiVerifyFaceResponse.class);

            if (response == null || !Boolean.TRUE.equals(response.getSuccess()) || response.getData() == null) {
                String errMsg = response != null && response.getMessage() != null
                        ? response.getMessage()
                        : "Không nhận được kết quả so khớp khuôn mặt từ AI Service";
                log.warn("[CorrID={}] Phản hồi AI Verify không hợp lệ: {}", correlationId, errMsg);
                throw new AppException(ErrorCode.AI_SERVICE_UNAVAILABLE, errMsg);
            }

            log.info("[CorrID={}] Kết quả so khớp khuôn mặt: matched={}, similarity={}",
                    correlationId, response.isMatched(), response.getSimilarity());

            return response;
        } catch (AppException e) {
            throw e;
        } catch (Exception e) {
            log.error("[CorrID={}] Lỗi kết nối AI Service verifyFace: {}", correlationId, e.getMessage());
            throw new AppException(ErrorCode.AI_SERVICE_UNAVAILABLE, "Không thể kết nối đến AI Service để so khớp khuôn mặt");
        }
    }

    /**
     * So khớp khuôn mặt thời gian thực với vector đặc trưng 512 chiều đã đăng ký (TASK-03 ArcFace).
     */
    public AiVerifyFaceResponse verifyFaceWithEmbedding(List<Float> registeredEmbedding, String targetImageBase64, Double threshold) {
        if (registeredEmbedding == null || registeredEmbedding.isEmpty()) {
            throw new AppException(ErrorCode.FACE_NOT_REGISTERED, "Sinh viên chưa có vector đặc trưng Face-ID đã đăng ký");
        }
        return verifyFace(registeredEmbedding, targetImageBase64, threshold);
    }

    /**
     * Kiểm tra thực thể sống (Passive Anti-Spoofing MiniFASNet - TASK-08).
     */
    public AiCheckLivenessResponse checkLiveness(String imageBase64, Double threshold) {
        if (imageBase64 == null || imageBase64.trim().isEmpty()) {
            throw new AppException(ErrorCode.INVALID_REQUEST, "Chuỗi ảnh Base64 không được để trống");
        }

        String correlationId = UUID.randomUUID().toString().substring(0, 8);
        log.info("[CorrID={}] Bắt đầu gửi yêu cầu kiểm tra Liveness tới AI Service", correlationId);

        try {
            AiCheckLivenessRequest request = AiCheckLivenessRequest.builder()
                    .imageBase64(imageBase64)
                    .threshold(threshold != null ? threshold : 0.70)
                    .build();

            AiCheckLivenessResponse response = restClient.post()
                    .uri("/api/v1/face/check-liveness")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(request)
                    .retrieve()
                    .onStatus(HttpStatusCode::is4xxClientError, (req, resp) -> {
                        int statusCode = resp.getStatusCode().value();
                        AiCheckLivenessResponse errBody = null;
                        try {
                            errBody = objectMapper.readValue(resp.getBody(), AiCheckLivenessResponse.class);
                        } catch (Exception parseEx) {
                            log.warn("[CorrID={}] Không thể giải mã body 4xx từ AI Liveness: {}", correlationId, parseEx.getMessage());
                        }

                        String errCode = errBody != null ? errBody.getErrorCode() : null;
                        String errMsg = errBody != null && errBody.getMessage() != null
                                ? errBody.getMessage()
                                : "Lỗi xử lý ảnh kiểm tra thực thể (HTTP " + statusCode + ")";

                        log.warn("[CorrID={}] AI Service check-liveness báo lỗi 4xx (HTTP {}): errorCode={}, message={}",
                                correlationId, statusCode, errCode, errMsg);

                        if ("ERR_3001".equals(errCode)) {
                            throw new AppException(ErrorCode.FACE_NOT_DETECTED, errMsg);
                        }
                        if ("ERR_3002".equals(errCode)) {
                            throw new AppException(ErrorCode.MULTIPLE_FACES_DETECTED, errMsg);
                        }
                        if ("ERR_3003".equals(errCode)) {
                            throw new AppException(ErrorCode.FACE_LIVENESS_FAILED, errMsg);
                        }
                        if ("ERR_3023".equals(errCode) || "ERR_1001".equals(errCode)) {
                            throw new AppException(ErrorCode.FACE_IMAGE_INVALID, errMsg);
                        }
                        throw new AppException(ErrorCode.INVALID_REQUEST, errMsg);
                    })
                    .onStatus(HttpStatusCode::is5xxServerError, (req, resp) -> {
                        int statusCode = resp.getStatusCode().value();
                        if (statusCode == 503) {
                            log.warn("[CorrID={}] AI Service liveness engine 503 (Fail-Closed/Not Ready)", correlationId);
                            throw new AppException(ErrorCode.FACE_LIVENESS_FAILED,
                                    "Dịch vụ chống giả mạo khuôn mặt chưa sẵn sàng (Fail-Closed)");
                        }
                        String errorMsg = "AI Liveness Service báo lỗi nội bộ (HTTP " + statusCode + ")";
                        try {
                            AiCheckLivenessResponse errBody = objectMapper.readValue(resp.getBody(), AiCheckLivenessResponse.class);
                            if (errBody != null && errBody.getMessage() != null) {
                                errorMsg = errBody.getMessage();
                            }
                        } catch (Exception parseEx) {
                            log.warn("[CorrID={}] Không thể giải mã body 5xx từ AI Liveness: {}", correlationId, parseEx.getMessage());
                        }
                        log.error("[CorrID={}] AI Liveness Service lỗi 5xx (HTTP {}): message={}", correlationId, statusCode, errorMsg);
                        throw new AppException(ErrorCode.AI_SERVICE_UNAVAILABLE, errorMsg);
                    })
                    .body(AiCheckLivenessResponse.class);

            if (response == null || !Boolean.TRUE.equals(response.getSuccess()) || response.getData() == null) {
                String errMsg = response != null && response.getMessage() != null
                        ? response.getMessage()
                        : "Không nhận được phản hồi kiểm tra Liveness hợp lệ";
                log.warn("[CorrID={}] Phản hồi AI Liveness không hợp lệ: {}", correlationId, errMsg);
                throw new AppException(ErrorCode.AI_SERVICE_UNAVAILABLE, errMsg);
            }

            log.info("[CorrID={}] Kiểm tra Liveness hoàn tất: isLive={}, score={}",
                    correlationId, response.isLive(), response.getLivenessScore());

            return response;
        } catch (AppException e) {
            throw e;
        } catch (Exception e) {
            log.error("[CorrID={}] Lỗi kết nối tới AI Liveness ({}): {}", correlationId, aiServiceUrl, e.getMessage());
            throw new AppException(ErrorCode.AI_SERVICE_UNAVAILABLE, "Không thể kết nối đến AI Service để kiểm tra thực thể");
        }
    }

    /**
     * Chuyển đổi List<Float> 512 phần tử thành mảng byte[] (2048 bytes) lưu trữ PostgreSQL BYTEA.
     */
    public static byte[] floatListToByteArray(List<Float> floats) {
        if (floats == null) return new byte[0];
        ByteBuffer buffer = ByteBuffer.allocate(floats.size() * Float.BYTES);
        buffer.order(ByteOrder.LITTLE_ENDIAN);
        for (Float f : floats) {
            buffer.putFloat(f != null ? f : 0.0f);
        }
        return buffer.array();
    }

    /**
     * Chuyển đổi mảng byte[] PostgreSQL BYTEA thành mảng float[].
     */
    public static float[] byteArrayToFloatArray(byte[] bytes) {
        if (bytes == null || bytes.length == 0) return new float[0];
        ByteBuffer buffer = ByteBuffer.wrap(bytes);
        buffer.order(ByteOrder.LITTLE_ENDIAN);
        float[] floats = new float[bytes.length / Float.BYTES];
        for (int i = 0; i < floats.length; i++) {
            floats[i] = buffer.getFloat();
        }
        return floats;
    }

    /**
     * Chuyển đổi mảng byte[] PostgreSQL BYTEA thành List<Float>.
     */
    public static List<Float> byteArrayToFloatList(byte[] bytes) {
        if (bytes == null || bytes.length == 0) return List.of();
        float[] floats = byteArrayToFloatArray(bytes);
        List<Float> list = new ArrayList<>(floats.length);
        for (float f : floats) {
            list.add(f);
        }
        return list;
    }

    /**
     * Sinh mã băm SHA-256 chứng nhận khuôn mẫu sinh trắc học.
     */
    public static String computeSha256Token(byte[] data, String username) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            digest.update(username.getBytes(StandardCharsets.UTF_8));
            byte[] hash = digest.digest(data);
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            return "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
        }
    }
}
