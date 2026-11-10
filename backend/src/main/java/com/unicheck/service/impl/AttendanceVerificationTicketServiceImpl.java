package com.unicheck.service.impl;

import com.unicheck.model.dto.VerificationTicket;
import com.unicheck.service.AttendanceVerificationTicketService;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Quản lý vòng đời của Vé xác thực điểm danh (Attendance Verification Ticket)
 * Hỗ trợ lưu trữ kép Redis và bộ nhớ cục bộ chống lỗi (resilient dual storage).
 */
@Slf4j
@Service
public class AttendanceVerificationTicketServiceImpl implements AttendanceVerificationTicketService {

    private final StringRedisTemplate redisTemplate;

    @Getter
    @Value("${unicheck.attendance.verification-ticket.ttl-seconds:180}")
    private int ticketTtlSeconds;

    private final Map<String, VerificationTicket> localTicketCache = new ConcurrentHashMap<>();

    public AttendanceVerificationTicketServiceImpl(@Autowired(required = false) StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
        this.ticketTtlSeconds = 180;
    }

    private String buildKey(String ticketId) {
        return "unicheck:attendance:ticket:" + ticketId;
    }

    @Override
    public VerificationTicket issueTicket(Long studentId, Long sessionId, Long slotId, String verificationMethod) {
        String cleanTicketId = "VTK-" + UUID.randomUUID().toString().replace("-", "").substring(0, 24);
        Instant now = Instant.now();
        Instant expiresAt = now.plus(Duration.ofSeconds(ticketTtlSeconds > 0 ? ticketTtlSeconds : 180));

        VerificationTicket ticket = new VerificationTicket(
                cleanTicketId,
                studentId,
                sessionId,
                slotId,
                verificationMethod != null ? verificationMethod : "QR",
                now,
                expiresAt
        );

        // 1. Lưu bộ nhớ cục bộ
        localTicketCache.put(cleanTicketId, ticket);

        // 2. Lưu Redis nếu có
        if (redisTemplate != null) {
            try {
                Duration ttl = Duration.between(now, expiresAt);
                if (ttl.isNegative() || ttl.isZero()) {
                    ttl = Duration.ofSeconds(180);
                }
                redisTemplate.opsForValue().set(buildKey(cleanTicketId), ticket.serialize(), ttl);
            } catch (Exception e) {
                log.warn("Redis không khả dụng khi lưu Verification Ticket, sử dụng bộ nhớ cục bộ: {}", e.getMessage());
            }
        }

        log.info("Cấp phát Verification Ticket thành công: ticketId={}, studentId={}, sessionId={}, method={}, TTL={}s",
                cleanTicketId, studentId, sessionId, verificationMethod, ticketTtlSeconds);

        return ticket;
    }

    @Override
    public Optional<VerificationTicket> validateTicket(String ticketId, Long studentId, Long sessionId) {
        if (ticketId == null || ticketId.trim().isEmpty()) {
            return Optional.empty();
        }
        String cleanTicketId = ticketId.trim();
        Instant now = Instant.now();
        VerificationTicket ticket = null;

        // 1. Đọc từ Redis trước
        if (redisTemplate != null) {
            try {
                String raw = redisTemplate.opsForValue().get(buildKey(cleanTicketId));
                if (raw != null) {
                    ticket = VerificationTicket.deserialize(raw);
                }
            } catch (Exception e) {
                log.warn("Lỗi khi đọc Verification Ticket từ Redis: {}", e.getMessage());
            }
        }

        // 2. Fallback đọc từ bộ nhớ cục bộ nếu Redis không có hoặc lỗi
        if (ticket == null) {
            ticket = localTicketCache.get(cleanTicketId);
        }

        if (ticket == null) {
            log.warn("Không tìm thấy Verification Ticket: {}", cleanTicketId);
            return Optional.empty();
        }

        // 3. Kiểm tra thời hạn hiệu lực (mặc định 180s)
        if (ticket.isExpired(now)) {
            log.warn("Verification Ticket #{} đã hết hạn (Hết hạn lúc: {})", cleanTicketId, ticket.expiresAt());
            consumeTicket(cleanTicketId);
            return Optional.empty();
        }

        // 4. Kiểm tra đúng sinh viên
        if (studentId != null && !studentId.equals(ticket.studentId())) {
            log.error("CẢNH BÁO BẢO MẬT: Sinh viên #{} sử dụng trái phép Ticket của sinh viên #{}",
                    studentId, ticket.studentId());
            return Optional.empty();
        }

        // 5. Kiểm tra đúng phiên học
        if (sessionId != null && !sessionId.equals(ticket.sessionId())) {
            log.error("CẢNH BÁO: Ticket #{} thuộc phiên #{} nhưng được dùng cho phiên #{}",
                    cleanTicketId, ticket.sessionId(), sessionId);
            return Optional.empty();
        }

        return Optional.of(ticket);
    }

    @Override
    public void consumeTicket(String ticketId) {
        if (ticketId == null || ticketId.trim().isEmpty()) return;
        String cleanTicketId = ticketId.trim();

        localTicketCache.remove(cleanTicketId);
        if (redisTemplate != null) {
            try {
                redisTemplate.delete(buildKey(cleanTicketId));
            } catch (Exception e) {
                log.warn("Lỗi khi xóa Verification Ticket trên Redis: {}", e.getMessage());
            }
        }
        log.info("Đã tiêu thụ Verification Ticket #{}", cleanTicketId);
    }

    @Override
    public void revokeTicket(String ticketId) {
        consumeTicket(ticketId);
    }
}
