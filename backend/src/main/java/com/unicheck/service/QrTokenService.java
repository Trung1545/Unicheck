package com.unicheck.service;

import com.unicheck.security.QrTokenClaims;

import java.time.Duration;
import java.time.Instant;

public interface QrTokenService {

    /**
     * Sinh token QR động bảo mật ký HMAC-SHA256
     *
     * @param sessionId ID của AttendanceSession
     * @param issuedAt Thời điểm phát hành
     * @param ttl Thời hạn hiệu lực toàn phần của token
     * @param rotationInterval Chu kỳ làm mới hiển thị QR
     * @return Compact JWT token
     */
    String generateQrToken(Long sessionId, Instant issuedAt, Duration ttl, Duration rotationInterval);

    /**
     * Xác thực chữ ký và trích xuất claims từ QR token
     *
     * @param qrToken Chuỗi compact QR token
     * @return QrTokenClaims nếu hợp lệ
     * @throws com.unicheck.exception.AppException nếu chữ ký sai hoặc hết hạn
     */
    QrTokenClaims parseAndValidateToken(String qrToken);
}
