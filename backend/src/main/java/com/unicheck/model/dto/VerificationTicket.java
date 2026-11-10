package com.unicheck.model.dto;

import java.time.Instant;

/**
 * Phiếu xác thực điểm danh (Attendance Verification Ticket)
 * Được cấp phát sau khi sinh viên xác thực QR hoặc OTP hợp lệ ban đầu.
 * Cho phép sinh viên tiếp tục thực hiện kiểm tra 5 tiêu chí và Face-ID
 * trong khung thời hạn riêng (mặc định 180s), độc lập với chu kỳ xoay vòng mã QR/OTP.
 */
public record VerificationTicket(
        String ticketId,
        Long studentId,
        Long sessionId,
        Long slotId,
        String verificationMethod,
        Instant verifiedAt,
        Instant expiresAt
) {
    public boolean isExpired(Instant now) {
        return now.isAfter(expiresAt);
    }

    public String serialize() {
        return ticketId + "|" + studentId + "|" + sessionId + "|"
                + (slotId != null ? slotId : "") + "|"
                + (verificationMethod != null ? verificationMethod : "QR") + "|"
                + verifiedAt.toEpochMilli() + "|"
                + expiresAt.toEpochMilli();
    }

    public static VerificationTicket deserialize(String raw) {
        if (raw == null || raw.trim().isEmpty()) {
            return null;
        }
        String[] parts = raw.split("\\|", 7);
        if (parts.length != 7) {
            return null;
        }
        try {
            String ticketId = parts[0];
            Long studentId = Long.parseLong(parts[1]);
            Long sessionId = Long.parseLong(parts[2]);
            Long slotId = parts[3].isEmpty() ? null : Long.parseLong(parts[3]);
            String method = parts[4];
            Instant verifiedAt = Instant.ofEpochMilli(Long.parseLong(parts[5]));
            Instant expiresAt = Instant.ofEpochMilli(Long.parseLong(parts[6]));
            return new VerificationTicket(ticketId, studentId, sessionId, slotId, method, verifiedAt, expiresAt);
        } catch (Exception e) {
            return null;
        }
    }
}
