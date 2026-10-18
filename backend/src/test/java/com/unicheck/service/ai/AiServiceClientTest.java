package com.unicheck.service.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.ai.AiExtractEmbeddingResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.*;

class AiServiceClientTest {

    private ObjectMapper objectMapper;
    private AiServiceClient aiServiceClient;
    private MockRestServiceServer mockServer;

    @BeforeEach
    void setUp() throws Exception {
        objectMapper = new ObjectMapper();
        RestClient.Builder builder = RestClient.builder().baseUrl("http://localhost:5000");
        mockServer = MockRestServiceServer.bindTo(builder).build();
        RestClient restClient = builder.build();

        aiServiceClient = new AiServiceClient("http://localhost:5000", objectMapper);

        // Inject the mocked RestClient into aiServiceClient via reflection
        Field field = AiServiceClient.class.getDeclaredField("restClient");
        field.setAccessible(true);
        field.set(aiServiceClient, restClient);
    }

    @Test
    @DisplayName("Should parse real Flask success response envelope with nested data correctly")
    void testParseFlaskSuccessResponseEnvelope() {
        List<Float> mockEmbedding = new ArrayList<>(Collections.nCopies(512, 0.05f));
        String flaskJson = """
        {
          "success": true,
          "data": {
            "embedding": %s,
            "embedding_dimension": 512,
            "model_name": "ArcFace-MobileFaceNet",
            "model_version": "w600k_mbf_v1",
            "face_detected": true,
            "confidence": 0.985
          },
          "message": "Trích xuất đặc trưng khuôn mặt thành công",
          "errorCode": null
        }
        """.formatted(mockEmbedding.toString());

        mockServer.expect(requestTo("http://localhost:5000/api/v1/face/extract-embedding"))
                .andExpect(method(HttpMethod.POST))
                .andRespond(withSuccess(flaskJson, MediaType.APPLICATION_JSON));

        AiExtractEmbeddingResponse response = aiServiceClient.extractEmbedding("data:image/jpeg;base64,validBase64");

        mockServer.verify();
        assertNotNull(response);
        assertTrue(response.getSuccess());
        assertNotNull(response.getEmbedding());
        assertEquals(512, response.getEmbedding().size());
        assertEquals(512, response.getEmbeddingDimension());
        assertEquals("ArcFace-MobileFaceNet", response.getModelName());
        assertEquals("w600k_mbf_v1", response.getModelVersion());
        assertTrue(response.getFaceDetected());
    }

    @Test
    @DisplayName("Should correctly map ERR_3001 NoFaceDetectedError from Flask 400 response")
    void testParseFlaskNoFaceDetectedError() {
        String flaskErrorJson = """
        {
          "success": false,
          "data": {
            "face_detected": false,
            "model_name": "ArcFace-MobileFaceNet",
            "model_version": "w600k_mbf_v1"
          },
          "message": "Không phát hiện khuôn mặt trong ảnh",
          "errorCode": "ERR_3001"
        }
        """;

        mockServer.expect(requestTo("http://localhost:5000/api/v1/face/extract-embedding"))
                .andExpect(method(HttpMethod.POST))
                .andRespond(withStatus(HttpStatus.BAD_REQUEST).body(flaskErrorJson).contentType(MediaType.APPLICATION_JSON));

        AppException ex = assertThrows(AppException.class, () ->
                aiServiceClient.extractEmbedding("data:image/jpeg;base64,noFaceImage"));

        mockServer.verify();
        assertEquals(ErrorCode.FACE_NOT_DETECTED, ex.getErrorCode());
        assertEquals("Không phát hiện khuôn mặt trong ảnh", ex.getMessage());
    }

    @Test
    @DisplayName("Should correctly map ERR_3002 MultipleFacesDetectedError from Flask 400 response")
    void testParseFlaskMultipleFacesDetectedError() {
        String flaskErrorJson = """
        {
          "success": false,
          "data": {
            "face_count": 2,
            "face_detected": false,
            "model_name": "ArcFace-MobileFaceNet",
            "model_version": "w600k_mbf_v1"
          },
          "message": "Phát hiện nhiều hơn một khuôn mặt trong ảnh. Vui lòng chỉ chụp một người duy nhất",
          "errorCode": "ERR_3002"
        }
        """;

        mockServer.expect(requestTo("http://localhost:5000/api/v1/face/extract-embedding"))
                .andExpect(method(HttpMethod.POST))
                .andRespond(withStatus(HttpStatus.BAD_REQUEST).body(flaskErrorJson).contentType(MediaType.APPLICATION_JSON));

        AppException ex = assertThrows(AppException.class, () ->
                aiServiceClient.extractEmbedding("data:image/jpeg;base64,twoFacesImage"));

        mockServer.verify();
        assertEquals(ErrorCode.MULTIPLE_FACES_DETECTED, ex.getErrorCode());
        assertTrue(ex.getMessage().contains("Phát hiện nhiều hơn một khuôn mặt"));
    }

    @Test
    @DisplayName("Should handle 500 internal server error from Flask without masking cause")
    void testParseFlaskInternalServerError() {
        String flask500Json = """
        {
          "success": false,
          "data": null,
          "message": "Lỗi mô hình ONNX khi suy luận",
          "errorCode": "ERR_1000"
        }
        """;

        mockServer.expect(requestTo("http://localhost:5000/api/v1/face/extract-embedding"))
                .andExpect(method(HttpMethod.POST))
                .andRespond(withStatus(HttpStatus.INTERNAL_SERVER_ERROR).body(flask500Json).contentType(MediaType.APPLICATION_JSON));

        AppException ex = assertThrows(AppException.class, () ->
                aiServiceClient.extractEmbedding("data:image/jpeg;base64,testImage"));

        mockServer.verify();
        assertEquals(ErrorCode.AI_SERVICE_UNAVAILABLE, ex.getErrorCode());
        assertTrue(ex.getMessage().contains("Lỗi mô hình ONNX"));
    }

    @Test
    @DisplayName("Should convert 512-dim Float List to 2048-byte array and back reliably")
    void testFloatAndByteArrayConversion() {
        List<Float> original = new ArrayList<>();
        for (int i = 0; i < 512; i++) {
            original.add(i * 0.001f);
        }

        byte[] bytes = AiServiceClient.floatListToByteArray(original);
        assertEquals(2048, bytes.length);

        float[] restored = AiServiceClient.byteArrayToFloatArray(bytes);
        assertEquals(512, restored.length);
        assertEquals(original.get(0), restored[0], 0.00001f);
        assertEquals(original.get(100), restored[100], 0.00001f);
        assertEquals(original.get(511), restored[511], 0.00001f);
    }
}
