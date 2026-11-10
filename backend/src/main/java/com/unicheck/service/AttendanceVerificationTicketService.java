package com.unicheck.service;

import com.unicheck.model.dto.VerificationTicket;

import java.util.Optional;

/**
 * Quản lý vòng đời của Vé xác thực điểm danh (Attendance Verification Ticket)
 * Gắn với:
 * - Student ID (từ JWT)
 * - Attendance Session ID
 * - Thời điểm QR/OTP được xác thực
 * - Thời gian hết hạn riêng (mặc định 180s)
 */
public interface AttendanceVerificationTicketService {

    /**
     * Cấp phát phiếu xác thực mới khi QR hoặc OTP được chứng thực hợp lệ
     */
    VerificationTicket issueTicket(Long studentId, Long sessionId, Long slotId, String verificationMethod);

    /**
     * Xác thực phiếu điểm danh khi sinh viên hoàn thành Face-ID
     * Đảm bảo đúng sinh viên, đúng phiên học và chưa hết hạn (> 180s)
     */
    Optional<VerificationTicket> validateTicket(String ticketId, Long studentId, Long sessionId);

    /**
     * Tiêu thụ vé sau khi điểm danh thành công (tránh tái sử dụng replay attack)
     */
    void consumeTicket(String ticketId);

    /**
     * Hủy vé khi có sự cố
     */
    void revokeTicket(String ticketId);

    int getTicketTtlSeconds();
}
