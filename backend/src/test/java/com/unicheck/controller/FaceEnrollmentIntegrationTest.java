package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.FaceRegistrationRequest;
import com.unicheck.model.dto.ai.AiExtractEmbeddingResponse;
import com.unicheck.model.entity.FaceEncoding;
import com.unicheck.model.entity.User;
import com.unicheck.model.enums.FaceDataStatus;
import com.unicheck.model.enums.Role;
import com.unicheck.model.enums.UserStatus;
import com.unicheck.repository.FaceEncodingRepository;
import com.unicheck.repository.UserRepository;
import com.unicheck.security.JwtUtil;
import com.unicheck.service.ai.AiServiceClient;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class FaceEnrollmentIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private FaceEncodingRepository faceEncodingRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @MockBean
    private AiServiceClient aiServiceClient;

    private User studentUser;
    private User adminUser;
    private String studentToken;
    private String adminToken;

    @BeforeEach
    void setUp() {
        faceEncodingRepository.deleteAll();

        studentUser = userRepository.findByUsername("test_student_face")
                .orElseGet(() -> userRepository.save(User.builder()
                        .username("test_student_face")
                        .password(passwordEncoder.encode("Password123!"))
                        .fullName("Nguyễn Sinh Viên Test")
                        .email("student_face@unicheck.edu.vn")
                        .code("SV-FACE-01")
                        .role(Role.STUDENT)
                        .status(UserStatus.ACTIVE)
                        .faceDataStatus(FaceDataStatus.NOT_REGISTERED)
                        .sex("NAM")
                        .build()));

        // Reset user status for clean test
        studentUser.setFaceDataStatus(FaceDataStatus.NOT_REGISTERED);
        studentUser.setFaceRegistrationAttempts(0);
        studentUser.setFaceRegistrationBlockedUntil(null);
        userRepository.save(studentUser);

        adminUser = userRepository.findByUsername("test_admin_face")
                .orElseGet(() -> userRepository.save(User.builder()
                        .username("test_admin_face")
                        .password(passwordEncoder.encode("Password123!"))
                        .fullName("Quản Trị Viên Test")
                        .email("admin_face@unicheck.edu.vn")
                        .code("AD-FACE-01")
                        .role(Role.ADMIN)
                        .status(UserStatus.ACTIVE)
                        .sex("NAM")
                        .build()));

        studentToken = "Bearer " + jwtUtil.generateAccessToken(studentUser);
        adminToken = "Bearer " + jwtUtil.generateAccessToken(adminUser);
    }

    private List<Float> createMock512Vector() {
        List<Float> list = new ArrayList<>(Collections.nCopies(512, 0.04419f)); // ~1.0 L2 norm
        return list;
    }

    @Test
    @DisplayName("1. Đăng ký Face-ID thành công: Trích xuất vector 512D, lưu BYTEA và cập nhật REGISTERED")
    void testRegisterFace_Success() throws Exception {
        List<Float> mockVector = createMock512Vector();
        when(aiServiceClient.extractEmbedding(anyString())).thenReturn(
                AiExtractEmbeddingResponse.builder()
                        .success(true)
                        .faceDetected(true)
                        .embedding(mockVector)
                        .embeddingDimension(512)
                        .modelName("arcface-mobilefacenet-w600k")
                        .modelVersion("1.0.0")
                        .build()
        );

        FaceRegistrationRequest request = FaceRegistrationRequest.builder()
                .imageBase64("data:image/jpeg;base64,/9j/4AAQSkZJRg==")
                .build();

        mockMvc.perform(post("/api/v1/attendance/register-face")
                        .header("Authorization", studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("REGISTERED"))
                .andExpect(jsonPath("$.data.embeddingDimension").value(512))
                .andExpect(jsonPath("$.data.modelName").value("arcface-mobilefacenet-w600k"))
                .andExpect(jsonPath("$.data.studentName").value(studentUser.getFullName()))
                .andExpect(jsonPath("$.data.tokenHash").isNotEmpty());

        // Kiểm tra trong PostgreSQL
        assertTrue(faceEncodingRepository.existsByUserId(studentUser.getId()));
        FaceEncoding fe = faceEncodingRepository.findByUserId(studentUser.getId()).orElseThrow();
        assertEquals(2048, fe.getEncodingData().length);
        assertFalse(fe.getLivenessVerified());
        assertNull(fe.getFaceImage()); // Zero raw biometric storage

        User updatedUser = userRepository.findById(studentUser.getId()).orElseThrow();
        assertEquals(FaceDataStatus.REGISTERED, updatedUser.getFaceDataStatus());
    }

    @Test
    @DisplayName("2. Từ chối khi không phát hiện khuôn mặt (ERR_3001)")
    void testRegisterFace_NoFaceDetected() throws Exception {
        when(aiServiceClient.extractEmbedding(anyString()))
                .thenThrow(new AppException(ErrorCode.FACE_NOT_DETECTED, "Không phát hiện khuôn mặt trong ảnh"));

        FaceRegistrationRequest request = FaceRegistrationRequest.builder()
                .imageBase64("data:image/jpeg;base64,invalid_face")
                .build();

        mockMvc.perform(post("/api/v1/attendance/register-face")
                        .header("Authorization", studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("ERR_3001"));
    }

    @Test
    @DisplayName("3. Từ chối khi có nhiều hơn một khuôn mặt (ERR_3002)")
    void testRegisterFace_MultipleFaces() throws Exception {
        when(aiServiceClient.extractEmbedding(anyString()))
                .thenThrow(new AppException(ErrorCode.MULTIPLE_FACES_DETECTED, "Phát hiện nhiều hơn một khuôn mặt"));

        FaceRegistrationRequest request = FaceRegistrationRequest.builder()
                .imageBase64("data:image/jpeg;base64,two_faces")
                .build();

        mockMvc.perform(post("/api/v1/attendance/register-face")
                        .header("Authorization", studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("ERR_3002"));
    }

    @Test
    @DisplayName("4. Tra cứu trạng thái Face-ID: Sinh viên chưa đăng ký")
    void testGetFaceStatus_NotRegistered() throws Exception {
        mockMvc.perform(get("/api/v1/attendance/face-status")
                        .header("Authorization", studentToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.isRegistered").value(false))
                .andExpect(jsonPath("$.data.faceDataStatus").value("NOT_REGISTERED"));
    }

    @Test
    @DisplayName("5. Tra cứu trạng thái Face-ID: Sinh viên đã đăng ký")
    void testGetFaceStatus_Registered() throws Exception {
        studentUser.setFaceDataStatus(FaceDataStatus.REGISTERED);
        userRepository.save(studentUser);

        faceEncodingRepository.save(FaceEncoding.builder()
                .user(studentUser)
                .encodingData(new byte[2048])
                .build());

        mockMvc.perform(get("/api/v1/attendance/face-status")
                        .header("Authorization", studentToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.isRegistered").value(true))
                .andExpect(jsonPath("$.data.faceDataStatus").value("REGISTERED"))
                .andExpect(jsonPath("$.data.tokenHash").isNotEmpty());
    }

    @Test
    @DisplayName("6. Xóa dữ liệu Face-ID để đăng ký lại")
    void testResetFaceData_Success() throws Exception {
        studentUser.setFaceDataStatus(FaceDataStatus.REGISTERED);
        userRepository.save(studentUser);
        faceEncodingRepository.save(FaceEncoding.builder()
                .user(studentUser)
                .encodingData(new byte[2048])
                .build());

        mockMvc.perform(delete("/api/v1/attendance/face-data")
                        .header("Authorization", studentToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        assertFalse(faceEncodingRepository.existsByUserId(studentUser.getId()));
        User updated = userRepository.findById(studentUser.getId()).orElseThrow();
        assertEquals(FaceDataStatus.NOT_REGISTERED, updated.getFaceDataStatus());
    }

    @Test
    @DisplayName("7. Kiểm tra tương thích Dual-Routing: /api/attendance/register-face và /api/face/status")
    void testDualRoutingCompatibility() throws Exception {
        mockMvc.perform(get("/api/face/status")
                        .header("Authorization", studentToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    @DisplayName("8. Quản trị viên xem thông tin sinh trắc học của sinh viên")
    void testAdminGetStudentFaceStatus() throws Exception {
        mockMvc.perform(get("/api/v1/attendance/face-status/user/" + studentUser.getId())
                        .header("Authorization", adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.userId").value(studentUser.getId()));
    }
}
