package com.unicheck.service.impl;

import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.FaceEnrollmentResponse;
import com.unicheck.model.dto.FaceRegistrationRequest;
import com.unicheck.model.dto.FaceStatusResponse;
import com.unicheck.model.dto.ai.AiExtractEmbeddingResponse;
import com.unicheck.model.entity.FaceEncoding;
import com.unicheck.model.entity.User;
import com.unicheck.model.enums.FaceDataStatus;
import com.unicheck.model.enums.UserStatus;
import com.unicheck.repository.FaceEncodingRepository;
import com.unicheck.repository.UserRepository;
import com.unicheck.service.FaceEnrollmentService;
import com.unicheck.service.ai.AiServiceClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class FaceEnrollmentServiceImpl implements FaceEnrollmentService {

    private final UserRepository userRepository;
    private final FaceEncodingRepository faceEncodingRepository;
    private final AiServiceClient aiServiceClient;

    private static final int MAX_ATTEMPTS = 10;
    private static final int LOCKOUT_MINUTES = 15;
    private static final String FACE_MODEL_VERSION = "v4.2";

    @Override
    @Transactional
    public FaceEnrollmentResponse registerFace(FaceRegistrationRequest request, String currentUsername) {
        User user = userRepository.findByUsername(currentUsername)
                .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "Không tìm thấy thông tin tài khoản người dùng"));

        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new AppException(ErrorCode.ACCOUNT_INACTIVE, "Tài khoản của bạn hiện chưa được kích hoạt");
        }

        // Kiểm tra tài khoản có đang bị khóa đăng ký khuôn mặt không
        if (user.getFaceRegistrationBlockedUntil() != null && user.getFaceRegistrationBlockedUntil().isAfter(LocalDateTime.now())) {
            throw new AppException(
                    ErrorCode.FACE_REGISTRATION_BLOCKED,
                    "Tài khoản bị tạm khóa đăng ký Face-ID do vượt quá số lần thử. Vui lòng thử lại sau: " + user.getFaceRegistrationBlockedUntil()
            );
        }

        // Tăng số lần thử đăng ký
        int currentAttempts = (user.getFaceRegistrationAttempts() != null ? user.getFaceRegistrationAttempts() : 0) + 1;
        user.setFaceRegistrationAttempts(currentAttempts);

        if (currentAttempts >= MAX_ATTEMPTS) {
            user.setFaceRegistrationBlockedUntil(LocalDateTime.now().plusMinutes(LOCKOUT_MINUTES));
            userRepository.save(user);
            throw new AppException(
                    ErrorCode.FACE_REGISTRATION_BLOCKED,
                    "Bạn đã thử đăng ký thất bại quá " + MAX_ATTEMPTS + " lần. Tài khoản bị tạm khóa 15 phút."
            );
        }
        userRepository.save(user);

        // Gửi sang Flask AI Service để phát hiện khuôn mặt và trích xuất vector 512 chiều ArcFace
        log.info("Bắt đầu trích xuất vector khuôn mặt cho người dùng: {}", currentUsername);
        AiExtractEmbeddingResponse aiResponse = aiServiceClient.extractEmbedding(request.getImageBase64());

        if (aiResponse.getEmbedding() == null || aiResponse.getEmbedding().size() != 512) {
            log.error("AI Service trả về kích thước vector không hợp lệ (size={})",
                    aiResponse.getEmbedding() != null ? aiResponse.getEmbedding().size() : 0);
            throw new AppException(ErrorCode.AI_SERVICE_UNAVAILABLE, "Vector đặc trưng khuôn mặt không đạt tiêu chuẩn 512 chiều");
        }

        // Chuyển đổi 512 số float thành mảng 2048 bytes để lưu trữ trong PostgreSQL BYTEA
        byte[] encodingData = AiServiceClient.floatListToByteArray(aiResponse.getEmbedding());

        // Lưu hoặc cập nhật bản ghi trong bảng face_encodings
        FaceEncoding faceEncoding = faceEncodingRepository.findByUserId(user.getId())
                .orElseGet(() -> FaceEncoding.builder()
                        .user(user)
                        .build());

        faceEncoding.setEncodingData(encodingData);
        faceEncoding.setRegisteredAt(LocalDateTime.now());
        // Tuyên bố kỹ thuật: chưa tích hợp MiniFASNet nên liveness_verified = false (Fail-Closed)
        faceEncoding.setLivenessVerified(false);
        // Không lưu trữ raw biometric images theo Nghị định 13/2023/NĐ-CP & ISO 27001
        faceEncoding.setFaceImage(null);
        faceEncodingRepository.save(faceEncoding);

        // Cập nhật trạng thái người dùng
        user.setFaceDataStatus(FaceDataStatus.REGISTERED);
        user.setFaceRegistrationAttempts(0);
        user.setFaceRegistrationBlockedUntil(null);
        user.setUpdatedAt(LocalDateTime.now());
        userRepository.save(user);

        // Tính toán chữ ký băm token SHA-256
        String tokenHash = AiServiceClient.computeSha256Token(encodingData, user.getUsername());

        log.info("Đăng ký Face-ID thành công cho sinh viên {} ({})", user.getFullName(), user.getUsername());

        return FaceEnrollmentResponse.builder()
                .success(true)
                .status(FaceDataStatus.REGISTERED)
                .registeredAt(faceEncoding.getRegisteredAt())
                .version(FACE_MODEL_VERSION)
                .modelName(aiResponse.getModelName() != null ? aiResponse.getModelName() : "arcface-mobilefacenet-w600k")
                .embeddingDimension(512)
                .tokenHash(tokenHash)
                .message("Đăng ký Face-ID thành công! Khuôn mẫu nhận diện đã được mã hóa an toàn.")
                .studentName(user.getFullName())
                .studentCode(user.getCode() != null ? user.getCode() : user.getUsername())
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public FaceStatusResponse getFaceStatus(String currentUsername) {
        User user = userRepository.findByUsername(currentUsername)
                .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "Không tìm thấy thông tin tài khoản người dùng"));

        return buildFaceStatusResponse(user);
    }

    @Override
    @Transactional
    public void resetFaceData(String currentUsername) {
        User user = userRepository.findByUsername(currentUsername)
                .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "Không tìm thấy thông tin tài khoản người dùng"));

        faceEncodingRepository.deleteByUserId(user.getId());
        user.setFaceDataStatus(FaceDataStatus.NOT_REGISTERED);
        user.setFaceRegistrationAttempts(0);
        user.setFaceRegistrationBlockedUntil(null);
        user.setUpdatedAt(LocalDateTime.now());
        userRepository.save(user);

        log.info("Đã xóa dữ liệu Face-ID cho người dùng: {}", currentUsername);
    }

    @Override
    @Transactional(readOnly = true)
    public FaceStatusResponse getFaceStatusByUserId(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND, "Không tìm thấy thông tin sinh viên yêu cầu"));

        return buildFaceStatusResponse(user);
    }

    private FaceStatusResponse buildFaceStatusResponse(User user) {
        Optional<FaceEncoding> faceEncodingOpt = faceEncodingRepository.findByUserId(user.getId());
        boolean hasEncoding = faceEncodingOpt.isPresent();
        boolean isRegistered = (user.getFaceDataStatus() == FaceDataStatus.REGISTERED || user.getFaceDataStatus() == FaceDataStatus.ACTIVE) && hasEncoding;

        String tokenHash = null;
        LocalDateTime registeredAt = null;

        if (hasEncoding) {
            FaceEncoding fe = faceEncodingOpt.get();
            registeredAt = fe.getRegisteredAt();
            tokenHash = AiServiceClient.computeSha256Token(fe.getEncodingData(), user.getUsername());
        }

        return FaceStatusResponse.builder()
                .userId(user.getId())
                .studentCode(user.getCode() != null ? user.getCode() : user.getUsername())
                .fullName(user.getFullName())
                .faceDataStatus(user.getFaceDataStatus())
                .isRegistered(isRegistered)
                .registeredAt(registeredAt)
                .version(FACE_MODEL_VERSION)
                .attempts(user.getFaceRegistrationAttempts())
                .blockedUntil(user.getFaceRegistrationBlockedUntil())
                .tokenHash(tokenHash)
                .build();
    }
}
