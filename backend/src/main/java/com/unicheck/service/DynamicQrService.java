package com.unicheck.service;

import com.unicheck.model.dto.OtpValidationRequest;
import com.unicheck.model.dto.OtpValidationResponse;
import com.unicheck.model.dto.QrTokenResponse;
import com.unicheck.model.dto.QrValidationRequest;
import com.unicheck.model.dto.QrValidationResponse;
import com.unicheck.security.UserPrincipal;

public interface DynamicQrService {

    /**
     * Lấy token QR và mã OTP 6 chữ số hiện tại đang active hoặc sinh token mới theo chu kỳ rotation
     *
     * @param principal Người dùng đang đăng nhập (Giảng viên hoặc Admin)
     * @param sessionId ID của phiên điểm danh
     * @return QrTokenResponse chứa token, otpCode, expiresAt, remainingSeconds
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
     * Xác thực QR token sinh viên quét được và cấp Verification Ticket
     *
     * @param request QrValidationRequest chứa token và sessionId
     * @param principal Sinh viên đang thực hiện điểm danh
     * @return QrValidationResponse kết quả xác thực hợp lệ kèm Verification Ticket
     */
    QrValidationResponse validateQrToken(QrValidationRequest request, UserPrincipal principal);

    /**
     * Xác thực mã OTP 6 chữ số sinh viên nhập trên ứng dụng Flutter Mobile
     *
     * @param request OtpValidationRequest chứa otpCode và sessionId (tùy chọn)
     * @param principal Sinh viên đang thực hiện điểm danh
     * @return OtpValidationResponse kết quả xác thực kèm thông tin lớp và token bảo mật
     */
    OtpValidationResponse validateOtp(OtpValidationRequest request, UserPrincipal principal);

    /**
     * Thu hồi và xóa sạch mã QR và OTP đang active của session khi phiên bị đóng
     *
     * @param sessionId ID của phiên điểm danh
     */
    void invalidateSessionQr(Long sessionId);
}
