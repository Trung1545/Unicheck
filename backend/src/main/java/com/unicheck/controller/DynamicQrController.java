package com.unicheck.controller;

import com.unicheck.common.dto.ApiResponse;
import com.unicheck.model.dto.*;
import com.unicheck.security.UserPrincipal;
import com.unicheck.service.DynamicQrService;
import com.unicheck.service.StaticTestQrService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping({"/api/attendance", "/api/v1/attendance"})
@RequiredArgsConstructor
public class DynamicQrController {

    private final DynamicQrService dynamicQrService;
    private final StaticTestQrService staticTestQrService;

    /**
     * API Phát mã QR và mã OTP cho phiên điểm danh đang mở (OPEN)
     * Hỗ trợ mode=DYNAMIC_QR (mặc định) và mode=STATIC_TEST_QR (kiểm thử Emulator cô lập)
     */
    @GetMapping("/sessions/{sessionId}/qr")
    @PreAuthorize("hasAnyRole('ADMIN', 'LECTURER')")
    public ResponseEntity<ApiResponse<QrTokenResponse>> getSessionQr(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable Long sessionId,
            @RequestParam(name = "mode", required = false, defaultValue = "DYNAMIC_QR") String mode
    ) {
        QrTokenResponse response;
        if ("STATIC_TEST_QR".equalsIgnoreCase(mode)) {
            response = staticTestQrService.generateOrGetStaticQrToken(principal, sessionId);
            return ResponseEntity.ok(ApiResponse.ok(response, "Lấy mã QR Test cố định thành công (TEST MODE)"));
        } else {
            response = dynamicQrService.generateOrGetActiveQrToken(principal, sessionId);
            return ResponseEntity.ok(ApiResponse.ok(response, "Lấy mã QR động thành công"));
        }
    }

    /**
     * API Kiểm tra điều kiện và trạng thái Static Test QR cho phiên điểm danh
     */
    @GetMapping("/sessions/{sessionId}/static-qr/status")
    @PreAuthorize("hasAnyRole('ADMIN', 'LECTURER')")
    public ResponseEntity<ApiResponse<StaticQrStatusResponse>> getStaticQrStatus(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable Long sessionId
    ) {
        StaticQrStatusResponse response = staticTestQrService.checkStaticQrCapability(principal, sessionId);
        return ResponseEntity.ok(ApiResponse.ok(response, "Kiểm tra trạng thái Static Test QR"));
    }

    /**
     * API Phát mã Static Test QR cố định
     */
    @GetMapping("/sessions/{sessionId}/static-qr")
    @PreAuthorize("hasAnyRole('ADMIN', 'LECTURER')")
    public ResponseEntity<ApiResponse<QrTokenResponse>> getStaticQr(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable Long sessionId
    ) {
        QrTokenResponse response = staticTestQrService.generateOrGetStaticQrToken(principal, sessionId);
        return ResponseEntity.ok(ApiResponse.ok(response, "Lấy mã QR Test cố định thành công (TEST MODE)"));
    }

    /**
     * API Thu hồi và tái tạo mã Static Test QR mới cho phiên
     */
    @PostMapping("/sessions/{sessionId}/static-qr/regenerate")
    @PreAuthorize("hasAnyRole('ADMIN', 'LECTURER')")
    public ResponseEntity<ApiResponse<QrTokenResponse>> regenerateStaticQr(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable Long sessionId
    ) {
        QrTokenResponse response = staticTestQrService.regenerateStaticQrToken(principal, sessionId);
        return ResponseEntity.ok(ApiResponse.ok(response, "Tái tạo mã QR Test cố định thành công"));
    }

    /**
     * API Thu hồi mã Static Test QR
     */
    @PostMapping("/sessions/{sessionId}/static-qr/revoke")
    @PreAuthorize("hasAnyRole('ADMIN', 'LECTURER')")
    public ResponseEntity<ApiResponse<Void>> revokeStaticQr(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable Long sessionId
    ) {
        staticTestQrService.revokeStaticQrToken(principal, sessionId);
        return ResponseEntity.ok(ApiResponse.ok(null, "Thu hồi mã QR Test cố định thành công"));
    }

    /**
     * API Xác thực QR token sinh viên quét được (Tự động nhận diện Dynamic QR hoặc Static Test QR)
     * Dành cho mọi người dùng đã đăng nhập (STUDENT, LECTURER, ADMIN)
     */
    @PostMapping("/qr/validate")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<QrValidationResponse>> validateQr(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody QrValidationRequest request
    ) {
        QrValidationResponse response;
        if (staticTestQrService.isStaticToken(request.getQrToken())) {
            response = staticTestQrService.validateStaticQrToken(request, principal);
        } else {
            response = dynamicQrService.validateQrToken(request, principal);
        }
        return ResponseEntity.ok(ApiResponse.ok(response, "Xác thực mã QR thành công"));
    }

    /**
     * API Xác thực mã OTP điểm danh 6 chữ số
     * Dành cho sinh viên đã đăng nhập
     */
    @PostMapping("/otp/validate")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<OtpValidationResponse>> validateOtp(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody OtpValidationRequest request
    ) {
        OtpValidationResponse response = dynamicQrService.validateOtp(request, principal);
        return ResponseEntity.ok(ApiResponse.ok(response, "Xác thực mã OTP thành công"));
    }
}
