package com.unicheck.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.model.dto.*;
import com.unicheck.model.entity.User;
import com.unicheck.model.enums.Role;
import com.unicheck.model.enums.UserStatus;
import com.unicheck.repository.UserRepository;
import com.unicheck.security.JwtUtil;
import com.unicheck.security.TokenRedisService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.time.LocalDate;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DisplayName("Module Authentication Integration Tests")
class AuthenticationIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private TokenRedisService tokenRedisService;

    private User studentUser;
    private User adminUser;
    private User lecturerUser;

    @BeforeEach
    void setUp() {
        long ts = System.currentTimeMillis();

        // 1. Student User
        studentUser = User.builder()
                .code("SV_" + ts)
                .username("student_" + ts)
                .email("student_" + ts + "@unicheck.edu.vn")
                .password(passwordEncoder.encode("Student@123"))
                .fullName("Nguyễn Sinh Viên")
                .role(Role.STUDENT)
                .status(UserStatus.ACTIVE)
                .build();
        studentUser = userRepository.save(studentUser);

        // 2. Admin User
        adminUser = User.builder()
                .code("AD_" + ts)
                .username("admin_" + ts)
                .email("admin_" + ts + "@unicheck.edu.vn")
                .password(passwordEncoder.encode("Admin@123"))
                .fullName("Quản Trị Viên")
                .role(Role.ADMIN)
                .status(UserStatus.ACTIVE)
                .build();
        adminUser = userRepository.save(adminUser);

        // 3. Lecturer User
        lecturerUser = User.builder()
                .code("GV_" + ts)
                .username("lecturer_" + ts)
                .email("lecturer_" + ts + "@unicheck.edu.vn")
                .password(passwordEncoder.encode("Lecturer@123"))
                .fullName("Trần Giảng Viên")
                .role(Role.LECTURER)
                .status(UserStatus.ACTIVE)
                .build();
        lecturerUser = userRepository.save(lecturerUser);

        // Reset rate limits for test users and local IP
        tokenRedisService.resetFailedLogins(studentUser.getUsername(), "127.0.0.1");
        tokenRedisService.resetFailedLogins(adminUser.getUsername(), "127.0.0.1");
        tokenRedisService.resetFailedLogins(lecturerUser.getUsername(), "127.0.0.1");
        tokenRedisService.resetFailedLogins("wrong_user", "127.0.0.1");
    }

    // =========================================================================
    // 1. Luồng Sai mật khẩu & Không tiết lộ tài khoản tồn tại
    // =========================================================================
    @Test
    @DisplayName("Test 1: Sai mật khẩu trả về 401 Unauthorized và không tiết lộ tài khoản có tồn tại hay không")
    void testWrongPasswordAndNonExistentUser() throws Exception {
        // Case 1a: Đúng username, sai mật khẩu
        LoginRequest wrongPassRequest = LoginRequest.builder()
                .username(studentUser.getUsername())
                .password("WrongPassword999")
                .build();

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(wrongPassRequest)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_2002")))
                .andExpect(jsonPath("$.message", containsString("Tên đăng nhập hoặc mật khẩu không chính xác")));

        // Case 1b: Sai username hoàn toàn (người dùng không tồn tại) -> thông báo lỗi giống hệt
        LoginRequest nonExistentUserRequest = LoginRequest.builder()
                .username("non_existent_user_999")
                .password("SomePassword123")
                .build();

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(nonExistentUserRequest)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_2002")))
                .andExpect(jsonPath("$.message", containsString("Tên đăng nhập hoặc mật khẩu không chính xác")));
    }

    // =========================================================================
    // 2. Luồng Token hết hạn (Expired Token)
    // =========================================================================
    @Test
    @DisplayName("Test 2: Token JWT đã hết hạn bị từ chối với mã lỗi 401 Unauthorized")
    void testExpiredToken() throws Exception {
        // Tạo token đã hết hạn 5 giây trước
        String expiredToken = jwtUtil.generateTokenWithCustomExpiration(studentUser, -5000L);

        mockMvc.perform(get("/api/auth/me")
                        .header("Authorization", "Bearer " + expiredToken))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_2000")));
    }

    // =========================================================================
    // 3. Luồng Token đã thu hồi (Revoked Token sau khi Logout)
    // =========================================================================
    @Test
    @DisplayName("Test 3: Token đã thu hồi sau khi logout không thể truy cập lại (401 Unauthorized)")
    void testRevokedTokenAfterLogout() throws Exception {
        // 3a. Đăng nhập thành công
        LoginRequest loginRequest = LoginRequest.builder()
                .username(studentUser.getUsername())
                .password("Student@123")
                .build();

        MvcResult loginResult = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.token", notNullValue()))
                .andReturn();

        String responseBody = loginResult.getResponse().getContentAsString();
        String accessToken = objectMapper.readTree(responseBody).get("data").get("token").asText();
        String refreshToken = objectMapper.readTree(responseBody).get("data").get("refreshToken").asText();

        // 3b. Kiểm tra truy cập /me trước khi logout thành công
        mockMvc.perform(get("/api/auth/me")
                        .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.username", is(studentUser.getUsername())));

        // 3c. Thực hiện logout
        mockMvc.perform(post("/api/auth/logout")
                        .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", containsString("Đăng xuất thành công")));

        // 3d. Sử dụng lại Access Token vừa bị logout -> bị chặn 401 TOKEN_REVOKED
        mockMvc.perform(get("/api/auth/me")
                        .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errorCode", is("ERR_2010")));

        // 3e. Thử dùng Refresh Token vừa bị logout để lấy token mới -> thất bại
        RefreshTokenRequest refreshReq = RefreshTokenRequest.builder()
                .refreshToken(refreshToken)
                .build();

        mockMvc.perform(post("/api/auth/refresh-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(refreshReq)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errorCode", is("ERR_2010")));
    }

    // =========================================================================
    // 4. Luồng Phân quyền bằng Method Security (ADMIN, LECTURER, STUDENT)
    // =========================================================================
    @Test
    @DisplayName("Test 4: Kiểm tra Method Security theo vai trò: STUDENT truy cập ADMIN trả về 403 Forbidden")
    void testMethodSecurityRoles() throws Exception {
        String studentToken = jwtUtil.generateAccessToken(studentUser);
        String lecturerToken = jwtUtil.generateAccessToken(lecturerUser);
        String adminToken = jwtUtil.generateAccessToken(adminUser);

        // 4a. STUDENT truy cập endpoint của STUDENT -> 200 OK
        mockMvc.perform(get("/api/auth/test/student")
                        .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", containsString("Sinh viên")));

        // 4b. STUDENT cố truy cập endpoint của ADMIN -> 403 Forbidden
        mockMvc.perform(get("/api/auth/test/admin")
                        .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.errorCode", is("ERR_2001")))
                .andExpect(jsonPath("$.message", containsString("không có quyền truy cập")));

        // 4c. STUDENT cố truy cập endpoint của LECTURER -> 403 Forbidden
        mockMvc.perform(get("/api/auth/test/lecturer")
                        .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.errorCode", is("ERR_2001")));

        // 4d. LECTURER truy cập endpoint của LECTURER -> 200 OK
        mockMvc.perform(get("/api/auth/test/lecturer")
                        .header("Authorization", "Bearer " + lecturerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", containsString("Giảng viên")));

        // 4e. ADMIN truy cập endpoint của ADMIN -> 200 OK
        mockMvc.perform(get("/api/auth/test/admin")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", containsString("Quản trị viên")));
    }

    // =========================================================================
    // 5. Luồng Vượt giới hạn đăng nhập (Rate Limiting: 5 lần trong 15 phút)
    // =========================================================================
    @Test
    @DisplayName("Test 5: Vượt quá 5 lần đăng nhập sai kích hoạt khóa 15 phút (429 Too Many Requests)")
    void testLoginRateLimiting() throws Exception {
        String targetUsername = studentUser.getUsername();
        LoginRequest badRequest = LoginRequest.builder()
                .username(targetUsername)
                .password("WrongPassword123")
                .build();

        // Thực hiện 5 lần đăng nhập thất bại
        for (int i = 1; i <= 5; i++) {
            mockMvc.perform(post("/api/auth/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(badRequest)))
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.errorCode", is("ERR_2002")));
        }

        // Lần thứ 6: Ngay lập tức bị khóa 429 Too Many Requests (kể cả có nhập đúng mật khẩu sau đó)
        LoginRequest correctRequestAfterLock = LoginRequest.builder()
                .username(targetUsername)
                .password("Student@123")
                .build();

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(correctRequestAfterLock)))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.errorCode", is("ERR_2007")))
                .andExpect(jsonPath("$.message", containsString("15 phút")));
    }

    // =========================================================================
    // 6. Luồng Quên mật khẩu qua Email, OTP 10 phút & Reset Password
    // =========================================================================
    @Test
    @DisplayName("Test 6: Quên mật khẩu gửi OTP 10 phút qua Redis và đổi mật khẩu thành công")
    void testForgotPasswordAndResetPassword() throws Exception {
        String email = studentUser.getEmail();

        // 6a. Yêu cầu cấp lại mật khẩu
        ForgotPasswordRequest forgotReq = ForgotPasswordRequest.builder()
                .email(email)
                .build();

        mockMvc.perform(post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(forgotReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", containsString("mã xác thực")));

        // Giả lập lấy OTP hợp lệ từ Redis
        String testOtp = "123456";
        tokenRedisService.savePasswordResetOtp(email, testOtp);

        // 6b. Reset password với OTP sai -> thất bại
        ResetPasswordRequest badOtpReq = ResetPasswordRequest.builder()
                .email(email)
                .otp("999999")
                .newPassword("NewPassword@999")
                .build();

        mockMvc.perform(post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(badOtpReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode", is("ERR_2008")));

        // 6c. Reset password với OTP đúng -> thành công
        ResetPasswordRequest goodOtpReq = ResetPasswordRequest.builder()
                .email(email)
                .otp(testOtp)
                .newPassword("NewStudentPassword@2026")
                .build();

        mockMvc.perform(post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(goodOtpReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", containsString("Đặt lại mật khẩu thành công")));

        // 6d. Đăng nhập bằng mật khẩu cũ -> thất bại
        LoginRequest oldPassLogin = LoginRequest.builder()
                .username(studentUser.getUsername())
                .password("Student@123")
                .build();
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(oldPassLogin)))
                .andExpect(status().isUnauthorized());

        // 6e. Đăng nhập bằng mật khẩu mới -> thành công
        LoginRequest newPassLogin = LoginRequest.builder()
                .username(studentUser.getUsername())
                .password("NewStudentPassword@2026")
                .build();
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(newPassLogin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.token", notNullValue()));
    }

    // =========================================================================
    // 7. Luồng Xem hồ sơ, Cập nhật hồ sơ & Đổi mật khẩu chủ động
    // =========================================================================
    @Test
    @DisplayName("Test 7: Xem hồ sơ, cập nhật thông tin và đổi mật khẩu chủ động")
    void testProfileAndChangePassword() throws Exception {
        String token = jwtUtil.generateAccessToken(studentUser);

        // 7a. Xem hồ sơ
        mockMvc.perform(get("/api/auth/profile")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.email", is(studentUser.getEmail())))
                .andExpect(jsonPath("$.data.role", is("STUDENT")));

        // 7b. Cập nhật hồ sơ
        UpdateProfileRequest updateReq = UpdateProfileRequest.builder()
                .fullName("Nguyễn Sinh Viên Pro")
                .phone("0912345678")
                .dob(LocalDate.of(2003, 8, 15))
                .sex("MALE")
                .avatar("https://cdn.unicheck.edu.vn/avatar.jpg")
                .build();

        mockMvc.perform(put("/api/auth/profile")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.fullName", is("Nguyễn Sinh Viên Pro")))
                .andExpect(jsonPath("$.data.phone", is("0912345678")));

        // 7c. Đổi mật khẩu: Nhập sai mật khẩu cũ -> 400 Bad Request
        ChangePasswordRequest wrongOldPass = ChangePasswordRequest.builder()
                .oldPassword("WrongOldPass123")
                .newPassword("NewSuperSecret@123")
                .build();

        mockMvc.perform(post("/api/auth/change-password")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(wrongOldPass)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode", is("ERR_2009")));

        // 7d. Đổi mật khẩu: Đúng mật khẩu cũ -> 200 OK
        ChangePasswordRequest rightPass = ChangePasswordRequest.builder()
                .oldPassword("Student@123")
                .newPassword("NewSuperSecret@123")
                .build();

        mockMvc.perform(post("/api/auth/change-password")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(rightPass)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", containsString("Đổi mật khẩu thành công")));
    }

    // =========================================================================
    // 8. TASK P02: Kiểm tra bảo mật JWT, Phân tách Access/Refresh và Session
    // =========================================================================

    @Test
    @DisplayName("P02-1: Refresh Token gửi trong Authorization Bearer bị từ chối truy cập /me (401 Unauthorized)")
    void testRefreshTokenCannotAccessProtectedEndpoint() throws Exception {
        LoginRequest loginRequest = LoginRequest.builder()
                .username(studentUser.getUsername())
                .password("Student@123")
                .build();

        MvcResult loginResult = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();

        String responseBody = loginResult.getResponse().getContentAsString();
        String accessToken = objectMapper.readTree(responseBody).get("data").get("token").asText();
        String refreshToken = objectMapper.readTree(responseBody).get("data").get("refreshToken").asText();

        // 8a. Access token hợp lệ truy cập /me thành công (200 OK)
        mockMvc.perform(get("/api/auth/me")
                        .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.username", is(studentUser.getUsername())));

        // 8b. Refresh token cố tình gửi vào Authorization Bearer ở /me -> Bị từ chối 401 Unauthorized
        mockMvc.perform(get("/api/auth/me")
                        .header("Authorization", "Bearer " + refreshToken))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.errorCode", is("ERR_2000")));
    }

    @Test
    @DisplayName("P02-2: Xoay vòng Refresh Token (Rotation) và Chặn tái sử dụng token cũ (Reuse Detection)")
    void testRefreshTokenRotationAndReuseDetection() throws Exception {
        LoginRequest loginRequest = LoginRequest.builder()
                .username(studentUser.getUsername())
                .password("Student@123")
                .build();

        MvcResult loginResult = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();

        String responseBody = loginResult.getResponse().getContentAsString();
        String initialRefreshToken = objectMapper.readTree(responseBody).get("data").get("refreshToken").asText();

        // Lần 1: Dùng initialRefreshToken đổi lấy cặp mới
        RefreshTokenRequest refreshReq1 = RefreshTokenRequest.builder()
                .refreshToken(initialRefreshToken)
                .build();

        MvcResult refreshResult1 = mockMvc.perform(post("/api/auth/refresh-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(refreshReq1)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.token", notNullValue()))
                .andExpect(jsonPath("$.data.refreshToken", notNullValue()))
                .andReturn();

        String refreshBody1 = refreshResult1.getResponse().getContentAsString();
        String newAccessToken = objectMapper.readTree(refreshBody1).get("data").get("token").asText();
        String rotatedRefreshToken = objectMapper.readTree(refreshBody1).get("data").get("refreshToken").asText();

        // Xác nhận token mới khác token cũ (Rotation)
        org.junit.jupiter.api.Assertions.assertNotEquals(initialRefreshToken, rotatedRefreshToken,
                "Rotated refresh token must be different from initial refresh token");

        // New access token hoạt động bình thường
        mockMvc.perform(get("/api/auth/me")
                        .header("Authorization", "Bearer " + newAccessToken))
                .andExpect(status().isOk());

        // Lần 2: Thử tái sử dụng initialRefreshToken đã qua sử dụng -> Phải bị từ chối 401 (Reuse Detection)
        mockMvc.perform(post("/api/auth/refresh-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(refreshReq1)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errorCode", is("ERR_2010")));

        // Lần 3: Dùng rotatedRefreshToken mới -> Thành công tiếp tục xoay vòng
        RefreshTokenRequest refreshReq2 = RefreshTokenRequest.builder()
                .refreshToken(rotatedRefreshToken)
                .build();

        mockMvc.perform(post("/api/auth/refresh-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(refreshReq2)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.token", notNullValue()));
    }

    @Test
    @DisplayName("P02-3: Đa thiết bị (Multi-Device) – Logout trên Thiết bị 1 không làm mất phiên Thiết bị 2")
    void testMultiDeviceSessionIsolation() throws Exception {
        LoginRequest loginRequest = LoginRequest.builder()
                .username(studentUser.getUsername())
                .password("Student@123")
                .build();

        // Thiết bị 1 (Mobile) đăng nhập
        MvcResult dev1Result = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("User-Agent", "UniCheck-Flutter-Mobile/1.0.0")
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();
        String dev1Token = objectMapper.readTree(dev1Result.getResponse().getContentAsString()).get("data").get("token").asText();

        // Thiết bị 2 (Web Browser) đăng nhập
        MvcResult dev2Result = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0")
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();
        String dev2Token = objectMapper.readTree(dev2Result.getResponse().getContentAsString()).get("data").get("token").asText();

        // Cả 2 thiết bị đều truy cập được /me
        mockMvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + dev1Token)).andExpect(status().isOk());
        mockMvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + dev2Token)).andExpect(status().isOk());

        // Thiết bị 1 thực hiện logout
        mockMvc.perform(post("/api/auth/logout")
                        .header("Authorization", "Bearer " + dev1Token))
                .andExpect(status().isOk());

        // Thiết bị 1 bị chặn (401)
        mockMvc.perform(get("/api/auth/me")
                        .header("Authorization", "Bearer " + dev1Token))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errorCode", is("ERR_2010")));

        // Thiết bị 2 VẪN HOẠT ĐỘNG BÌNH THƯỜNG (200 OK)
        mockMvc.perform(get("/api/auth/me")
                        .header("Authorization", "Bearer " + dev2Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.username", is(studentUser.getUsername())));
    }
}
