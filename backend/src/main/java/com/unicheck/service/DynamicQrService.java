package com.unicheck.service;

import com.unicheck.model.dto.QrTokenResponse;
import com.unicheck.model.dto.QrValidationRequest;
import com.unicheck.model.dto.QrValidationResponse;
import com.unicheck.security.UserPrincipal;

public interface DynamicQrService {

    /**
     * Lấy token QR hiện tại đang active hoặc sinh token mới theo chu kỳ rotation
     *
     * @param principal Người dùng đang đăng nhập (Giảng viên hoặc Admin)
     * @param sessionId ID của phiên điểm danh
     * @return QrTokenResponse chứa token, expiresAt, remainingSeconds
     */
    QrTokenResponse generateOrGetActiveQrToken(UserPrincipal principal, Long sessionId);

    /**
     * Xác thực QR token sinh viên quét được
     *
     * @param request QrValidationRequest chứa token và sessionId
     * @return QrValidationResponse kết quả xác thực hợp lệ
     */
    QrValidationResponse validateQrToken(QrValidationRequest request);

    /**
     * Thu hồi và xóa sạch mã QR đang active của session khi phiên bị đóng
     *
     * @param sessionId ID của phiên điểm danh
     */
    void invalidateSessionQr(Long sessionId);
}
