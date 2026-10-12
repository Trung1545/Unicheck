package com.unicheck.controller;

import com.unicheck.common.dto.ApiResponse;
import com.unicheck.model.dto.*;
import com.unicheck.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping({"/api/auth", "/api/v1/auth"})
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@Valid @RequestBody LoginRequest request,
                                                           HttpServletRequest httpRequest) {
        LoginResponse response = authService.login(request, httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(response, "Đăng nhập thành công"));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(HttpServletRequest httpRequest) {
        authService.logout(httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(null, "Đăng xuất thành công"));
    }

    @PostMapping("/refresh-token")
    public ResponseEntity<ApiResponse<TokenRefreshResponse>> refreshToken(@Valid @RequestBody RefreshTokenRequest request) {
        TokenRefreshResponse response = authService.refreshToken(request);
        return ResponseEntity.ok(ApiResponse.ok(response, "Làm mới mã xác thực thành công"));
    }

    @GetMapping({"/me", "/profile"})
    public ResponseEntity<ApiResponse<UserProfileResponse>> getProfile() {
        UserProfileResponse response = authService.getCurrentUserProfile();
        return ResponseEntity.ok(ApiResponse.ok(response, "Lấy thông tin hồ sơ thành công"));
    }

    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateProfile(@RequestBody UpdateProfileRequest request) {
        UserProfileResponse response = authService.updateProfile(request);
        return ResponseEntity.ok(ApiResponse.ok(response, "Cập nhật hồ sơ thành công"));
    }

    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<Void>> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        authService.changePassword(request);
        return ResponseEntity.ok(ApiResponse.ok(null, "Đổi mật khẩu thành công"));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<ApiResponse<Void>> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        authService.processForgotPassword(request);
        // Generic message without revealing user existence
        return ResponseEntity.ok(ApiResponse.ok(null, "Nếu email tồn tại trong hệ thống, mã xác thực 6 chữ số đã được gửi qua email"));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<ApiResponse<Void>> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        authService.resetPassword(request);
        return ResponseEntity.ok(ApiResponse.ok(null, "Đặt lại mật khẩu thành công"));
    }

    // Role-based Method Security verification endpoints
    @GetMapping("/test/admin")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<String>> testAdminAccess() {
        return ResponseEntity.ok(ApiResponse.ok("Xin chào Quản trị viên (ADMIN)", "Quyền truy cập hợp lệ"));
    }

    @GetMapping("/test/lecturer")
    @PreAuthorize("hasRole('LECTURER')")
    public ResponseEntity<ApiResponse<String>> testLecturerAccess() {
        return ResponseEntity.ok(ApiResponse.ok("Xin chào Giảng viên (LECTURER)", "Quyền truy cập hợp lệ"));
    }

    @GetMapping("/test/student")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<String>> testStudentAccess() {
        return ResponseEntity.ok(ApiResponse.ok("Xin chào Sinh viên (STUDENT)", "Quyền truy cập hợp lệ"));
    }
}
