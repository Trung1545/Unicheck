package com.unicheck.service.impl;

import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.QrTokenResponse;
import com.unicheck.model.dto.QrValidationRequest;
import com.unicheck.model.dto.QrValidationResponse;
import com.unicheck.model.entity.AttendanceSession;
import com.unicheck.model.entity.User;
import com.unicheck.model.enums.AttendanceSessionStatus;
import com.unicheck.model.enums.Role;
import com.unicheck.repository.AttendanceSessionRepository;
import com.unicheck.security.DynamicQrRedisService;
import com.unicheck.security.QrTokenClaims;
import com.unicheck.security.UserPrincipal;
import com.unicheck.service.DynamicQrService;
import com.unicheck.service.QrTokenService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;

@Slf4j
@Service
@RequiredArgsConstructor
public class DynamicQrServiceImpl implements DynamicQrService {

    private final AttendanceSessionRepository attendanceSessionRepository;
    private final QrTokenService qrTokenService;
    private final DynamicQrRedisService dynamicQrRedisService;

    @Value("${security.qr.rotation-seconds:10}")
    private int defaultRotationSeconds;

    @Value("${security.qr.ttl-seconds:15}")
    private int defaultTtlSeconds;

    private final java.util.concurrent.ConcurrentMap<Long, Object> sessionLocks = new java.util.concurrent.ConcurrentHashMap<>();

    @Override
    @Transactional(readOnly = true)
    public QrTokenResponse generateOrGetActiveQrToken(UserPrincipal principal, Long sessionId) {
        validateAuthenticatedUser(principal);
        User user = principal.getUser();

        if (user.getRole() == Role.STUDENT) {
            throw new AppException(ErrorCode.FORBIDDEN, "Sinh viên không có quyền lấy hoặc phát mã QR");
        }

        AttendanceSession session = attendanceSessionRepository.findById(sessionId)
                .orElseThrow(() -> new AppException(ErrorCode.ATTENDANCE_SESSION_NOT_FOUND,
                        "Không tìm thấy phiên điểm danh với ID: " + sessionId));

        // Object-level authorization for LECTURER
        if (user.getRole() == Role.LECTURER) {
            if (session.getLecturer() == null || !session.getLecturer().getId().equals(user.getId())) {
                throw new AppException(ErrorCode.LECTURER_NOT_ASSIGNED_TO_CLASS,
                        "Giảng viên không phụ trách phiên điểm danh này");
            }
        }

        // Strict Session OPEN status check
        if (session.getStatus() != AttendanceSessionStatus.OPEN) {
            if (session.getStatus() == AttendanceSessionStatus.CLOSED) {
                throw new AppException(ErrorCode.SESSION_NOT_OPEN,
                        "Phiên điểm danh đã kết thúc, không thể phát mã QR");
            } else if (session.getStatus() == AttendanceSessionStatus.CREATED) {
                throw new AppException(ErrorCode.SESSION_NOT_OPEN,
                        "Phiên điểm danh chưa được mở, vui lòng mở phiên trước khi hiển thị QR");
            } else {
                throw new AppException(ErrorCode.SESSION_NOT_OPEN,
                        "Trạng thái phiên không hợp lệ: " + session.getStatus());
            }
        }

        int rotationIntervalSeconds = defaultRotationSeconds > 0 ? defaultRotationSeconds : 10;
        int ttlSeconds = defaultTtlSeconds > rotationIntervalSeconds ? defaultTtlSeconds : rotationIntervalSeconds + 5;

        Object lock = sessionLocks.computeIfAbsent(sessionId, k -> new Object());
        synchronized (lock) {
            Instant now = Instant.now();

            // Check if there is an active QR code within rotation interval
            DynamicQrRedisService.ActiveQrEntry activeEntry = dynamicQrRedisService.getActiveQr(sessionId);
            if (activeEntry != null && !activeEntry.isRotationExpired(now)) {
                long remaining = Duration.between(now, activeEntry.rotationExpiresAt()).getSeconds();
                if (remaining < 0) remaining = 0;

                LocalDateTime issuedLdt = LocalDateTime.ofInstant(activeEntry.issuedAt(), ZoneId.systemDefault());
                LocalDateTime expiresLdt = LocalDateTime.ofInstant(activeEntry.expiresAt(), ZoneId.systemDefault());
                LocalDateTime rotExpLdt = LocalDateTime.ofInstant(activeEntry.rotationExpiresAt(), ZoneId.systemDefault());

                return QrTokenResponse.builder()
                        .sessionId(sessionId)
                        .qrToken(activeEntry.qrToken())
                        .issuedAt(issuedLdt)
                        .expiresAt(expiresLdt)
                        .rotationExpiresAt(rotExpLdt)
                        .rotationIntervalSeconds(rotationIntervalSeconds)
                        .remainingSeconds(remaining)
                        .status(session.getStatus())
                        .build();
            }

            // Generate new rotating QR token
            Instant issuedAt = now;
            Instant expiresAt = now.plusSeconds(ttlSeconds);
            Instant rotationExpiresAt = now.plusSeconds(rotationIntervalSeconds);

            String token = qrTokenService.generateQrToken(
                    sessionId,
                    issuedAt,
                    Duration.ofSeconds(ttlSeconds),
                    Duration.ofSeconds(rotationIntervalSeconds)
            );

            // Save into Redis / Resilient fallback store
            dynamicQrRedisService.saveActiveQr(sessionId, token, issuedAt, expiresAt, rotationExpiresAt);

            log.info("Issued new dynamic QR token for session #{} (TTL: {}s, Rotation: {}s)",
                    sessionId, ttlSeconds, rotationIntervalSeconds);

            LocalDateTime issuedLdt = LocalDateTime.ofInstant(issuedAt, ZoneId.systemDefault());
            LocalDateTime expiresLdt = LocalDateTime.ofInstant(expiresAt, ZoneId.systemDefault());
            LocalDateTime rotExpLdt = LocalDateTime.ofInstant(rotationExpiresAt, ZoneId.systemDefault());

            return QrTokenResponse.builder()
                    .sessionId(sessionId)
                    .qrToken(token)
                    .issuedAt(issuedLdt)
                    .expiresAt(expiresLdt)
                    .rotationExpiresAt(rotExpLdt)
                    .rotationIntervalSeconds(rotationIntervalSeconds)
                    .remainingSeconds((long) rotationIntervalSeconds)
                    .status(session.getStatus())
                    .build();
        }
    }

    @Override
    @Transactional(readOnly = true)
    public QrValidationResponse validateQrToken(QrValidationRequest request) {
        if (request == null || request.getQrToken() == null || request.getSessionId() == null) {
            throw new AppException(ErrorCode.INVALID_REQUEST, "Dữ liệu yêu cầu xác minh QR không hợp lệ");
        }

        // 1. Verify token signature, structure and expiration
        QrTokenClaims claims = qrTokenService.parseAndValidateToken(request.getQrToken());

        // 2. Verify Session ID binding
        if (!claims.getSessionId().equals(request.getSessionId())) {
            log.warn("QR session mismatch: tokenSession={}, requestSession={}",
                    claims.getSessionId(), request.getSessionId());
            throw new AppException(ErrorCode.QR_SESSION_MISMATCH,
                    "Mã QR thuộc về phiên khác (#" + claims.getSessionId() + ") không khớp với phiên #" + request.getSessionId());
        }

        // 3. Verify Session in Database
        AttendanceSession session = attendanceSessionRepository.findById(request.getSessionId())
                .orElseThrow(() -> new AppException(ErrorCode.ATTENDANCE_SESSION_NOT_FOUND,
                        "Không tìm thấy phiên điểm danh với ID: " + request.getSessionId()));

        // 4. Session status must be OPEN
        if (session.getStatus() != AttendanceSessionStatus.OPEN) {
            log.warn("Attempt to validate QR against non-OPEN session #{}, current status: {}",
                    session.getId(), session.getStatus());
            throw new AppException(ErrorCode.SESSION_NOT_OPEN,
                    "Phiên điểm danh hiện không ở trạng thái mở (trạng thái: " + session.getStatus() + ")");
        }

        // Extract metadata for student UI check-in confirmation
        String className = "N/A";
        String roomName = "N/A";
        if (session.getTimetableSlot() != null) {
            if (session.getTimetableSlot().getClassSection() != null) {
                className = session.getTimetableSlot().getClassSection().getClassName();
            }
            if (session.getTimetableSlot().getRoom() != null) {
                roomName = session.getTimetableSlot().getRoom().getName() != null 
                        ? session.getTimetableSlot().getRoom().getName() 
                        : session.getTimetableSlot().getRoom().getCode();
            }
        }

        LocalDateTime issuedLdt = LocalDateTime.ofInstant(claims.getIssuedAt(), ZoneId.systemDefault());
        LocalDateTime expiresLdt = LocalDateTime.ofInstant(claims.getExpiresAt(), ZoneId.systemDefault());

        log.info("Validated dynamic QR token successfully for session #{}", session.getId());

        return QrValidationResponse.builder()
                .valid(true)
                .sessionId(session.getId())
                .className(className)
                .roomName(roomName)
                .issuedAt(issuedLdt)
                .expiresAt(expiresLdt)
                .message("Xác thực mã QR thành công")
                .build();
    }

    @Override
    public void invalidateSessionQr(Long sessionId) {
        if (sessionId != null) {
            dynamicQrRedisService.invalidate(sessionId);
        }
    }

    private void validateAuthenticatedUser(UserPrincipal principal) {
        if (principal == null || principal.getUser() == null) {
            throw new AppException(ErrorCode.UNAUTHORIZED, "Người dùng chưa đăng nhập hoặc phiên đã hết hạn");
        }
    }
}
