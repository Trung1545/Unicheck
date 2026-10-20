package com.unicheck.controller;

import com.unicheck.common.dto.ApiResponse;
import com.unicheck.model.dto.QrTokenResponse;
import com.unicheck.model.dto.QrValidationRequest;
import com.unicheck.model.dto.QrValidationResponse;
import com.unicheck.security.UserPrincipal;
import com.unicheck.service.DynamicQrService;
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

    /**
     * API Phát mã QR động xoay vòng cho phiên điểm danh đang mở (OPEN)
     * Chỉ dành cho LECTURER phụ trách phiên hoặc ADMIN
     */
    @GetMapping("/sessions/{sessionId}/qr")
    @PreAuthorize("hasAnyRole('ADMIN', 'LECTURER')")
    public ResponseEntity<ApiResponse<QrTokenResponse>> getSessionQr(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable Long sessionId
    ) {
        QrTokenResponse response = dynamicQrService.generateOrGetActiveQrToken(principal, sessionId);
        return ResponseEntity.ok(ApiResponse.ok(response, "Lấy mã QR động thành công"));
    }

    /**
     * API Xác thực QR token sinh viên quét được
     * Dành cho mọi người dùng đã đăng nhập (STUDENT, LECTURER, ADMIN)
     */
    @PostMapping("/qr/validate")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<QrValidationResponse>> validateQr(
            @Valid @RequestBody QrValidationRequest request
    ) {
        QrValidationResponse response = dynamicQrService.validateQrToken(request);
        return ResponseEntity.ok(ApiResponse.ok(response, "Xác thực mã QR thành công"));
    }
}
