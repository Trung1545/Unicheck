package com.unicheck.controller;

import com.unicheck.common.dto.ApiResponse;
import com.unicheck.model.dto.FaceEnrollmentResponse;
import com.unicheck.model.dto.FaceRegistrationRequest;
import com.unicheck.model.dto.FaceStatusResponse;
import com.unicheck.service.FaceEnrollmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequiredArgsConstructor
public class FaceEnrollmentController {

    private final FaceEnrollmentService faceEnrollmentService;

    /**
     * Endpoint F-17: Đăng ký hoặc cập nhật dữ liệu sinh trắc học khuôn mặt cho sinh viên.
     * Dual-routed: /api/v1/attendance/register-face, /api/attendance/register-face, /api/v1/face/enroll
     */
    @PostMapping({"/api/v1/attendance/register-face", "/api/attendance/register-face", "/api/v1/face/enroll", "/api/face/enroll"})
    @PreAuthorize("hasAnyRole('STUDENT', 'LECTURER', 'ADMIN')")
    public ResponseEntity<ApiResponse<FaceEnrollmentResponse>> registerFace(
            @Valid @RequestBody FaceRegistrationRequest request,
            Authentication authentication
    ) {
        String currentUsername = authentication.getName();
        log.info("Nhận yêu cầu đăng ký Face-ID từ người dùng: {}", currentUsername);
        FaceEnrollmentResponse response = faceEnrollmentService.registerFace(request, currentUsername);
        return ResponseEntity.ok(ApiResponse.ok(response, "Đăng ký khuôn mẫu Face-ID thành công"));
    }

    /**
     * Tra cứu trạng thái đăng ký Face-ID của tài khoản đang đăng nhập.
     * Dual-routed: /api/v1/attendance/face-status, /api/attendance/face-status, /api/v1/face/status
     */
    @GetMapping({"/api/v1/attendance/face-status", "/api/attendance/face-status", "/api/v1/face/status", "/api/face/status"})
    @PreAuthorize("hasAnyRole('STUDENT', 'LECTURER', 'ADMIN')")
    public ResponseEntity<ApiResponse<FaceStatusResponse>> getFaceStatus(Authentication authentication) {
        String currentUsername = authentication.getName();
        FaceStatusResponse response = faceEnrollmentService.getFaceStatus(currentUsername);
        return ResponseEntity.ok(ApiResponse.ok(response, "Lấy trạng thái hồ sơ Face-ID thành công"));
    }

    /**
     * Thu hồi / xóa dữ liệu Face-ID để đăng ký lại từ đầu.
     * Dual-routed: /api/v1/attendance/face-data, /api/attendance/face-data
     */
    @DeleteMapping({"/api/v1/attendance/face-data", "/api/attendance/face-data", "/api/v1/face/data", "/api/face/data"})
    @PreAuthorize("hasAnyRole('STUDENT', 'LECTURER', 'ADMIN')")
    public ResponseEntity<ApiResponse<Void>> resetFaceData(Authentication authentication) {
        String currentUsername = authentication.getName();
        log.info("Nhận yêu cầu xóa dữ liệu Face-ID từ người dùng: {}", currentUsername);
        faceEnrollmentService.resetFaceData(currentUsername);
        return ResponseEntity.ok(ApiResponse.ok(null, "Xóa dữ liệu khuôn mẫu Face-ID thành công. Bạn có thể thu thập lại ảnh mẫu."));
    }

    /**
     * Dành riêng cho Quản trị viên xem trạng thái Face-ID của sinh viên theo ID.
     */
    @GetMapping({"/api/v1/attendance/face-status/user/{userId}", "/api/attendance/face-status/user/{userId}"})
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<FaceStatusResponse>> getFaceStatusByUserId(@PathVariable Long userId) {
        FaceStatusResponse response = faceEnrollmentService.getFaceStatusByUserId(userId);
        return ResponseEntity.ok(ApiResponse.ok(response, "Lấy thông tin sinh trắc học người dùng thành công"));
    }
}
