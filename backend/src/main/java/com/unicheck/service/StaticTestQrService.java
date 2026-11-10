package com.unicheck.service;

import com.unicheck.model.dto.QrTokenResponse;
import com.unicheck.model.dto.QrValidationRequest;
import com.unicheck.model.dto.QrValidationResponse;
import com.unicheck.model.dto.StaticQrStatusResponse;
import com.unicheck.security.UserPrincipal;

public interface StaticTestQrService {

    /**
     * Kiểm tra phiên điểm danh và môi trường hiện tại có đủ điều kiện bật Static Test QR không.
     */
    StaticQrStatusResponse checkStaticQrCapability(UserPrincipal principal, Long sessionId);

    /**
     * Lấy token Static Test QR hiện tại hoặc tạo mới nếu chưa tồn tại.
     */
    QrTokenResponse generateOrGetStaticQrToken(UserPrincipal principal, Long sessionId);

    /**
     * Thu hồi và tạo token Static Test QR mới cho phiên.
     */
    QrTokenResponse regenerateStaticQrToken(UserPrincipal principal, Long sessionId);

    /**
     * Thu hồi token Static Test QR hiện tại của phiên.
     */
    void revokeStaticQrToken(UserPrincipal principal, Long sessionId);

    /**
     * Kiểm tra chuỗi QR token có phải là định dạng Static Test QR không.
     */
    boolean isStaticToken(String qrToken);

    /**
     * Xác thực token Static Test QR từ sinh viên / emulator.
     */
    QrValidationResponse validateStaticQrToken(QrValidationRequest request);

    /**
     * Xác thực token Static Test QR từ sinh viên / emulator và cấp Verification Ticket.
     */
    QrValidationResponse validateStaticQrToken(QrValidationRequest request, UserPrincipal principal);

    /**
     * Hủy bỏ Static Test QR khi phiên đóng.
     */
    void invalidateSessionStaticQr(Long sessionId);

    /**
     * Kiểm tra cấu hình và profile môi trường có cho phép Static Test QR không.
     */
    boolean isStaticQrEnabledInEnvironment();
}
