package com.unicheck.service.impl;

import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.*;
import com.unicheck.model.entity.AttendanceSession;
import com.unicheck.model.entity.ClassSection;
import com.unicheck.model.entity.Course;
import com.unicheck.model.entity.Room;
import com.unicheck.model.entity.StudentAttendance;
import com.unicheck.model.entity.TimetableSlot;
import com.unicheck.model.entity.User;
import com.unicheck.model.enums.AttendanceSessionStatus;
import com.unicheck.model.enums.Role;
import com.unicheck.repository.AttendanceRecheckRequestRepository;
import com.unicheck.repository.AttendanceSessionRepository;
import com.unicheck.repository.EnrollmentRepository;
import com.unicheck.repository.StudentAttendanceRepository;
import com.unicheck.security.DynamicQrRedisService;
import com.unicheck.security.QrTokenClaims;
import com.unicheck.security.UserPrincipal;
import com.unicheck.service.DynamicQrService;
import com.unicheck.service.QrTokenService;
import com.unicheck.service.StaticTestQrService;
import com.unicheck.service.WifiSimulationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class DynamicQrServiceImpl implements DynamicQrService {

    private final AttendanceSessionRepository attendanceSessionRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final StudentAttendanceRepository studentAttendanceRepository;
    private final AttendanceRecheckRequestRepository attendanceRecheckRequestRepository;
    private final QrTokenService qrTokenService;
    private final DynamicQrRedisService dynamicQrRedisService;
    private final StaticTestQrService staticTestQrService;
    private final WifiSimulationService wifiSimulationService;
    private final com.unicheck.service.AttendanceVerificationTicketService verificationTicketService;

    private final SecureRandom secureRandom = new SecureRandom();

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
                        "Phiên điểm danh đã kết thúc, không thể phát mã QR hoặc OTP");
            } else if (session.getStatus() == AttendanceSessionStatus.CREATED) {
                throw new AppException(ErrorCode.SESSION_NOT_OPEN,
                        "Phiên điểm danh chưa được mở, vui lòng mở phiên trước khi hiển thị QR và OTP");
            } else {
                throw new AppException(ErrorCode.SESSION_NOT_OPEN,
                        "Trạng thái phiên không hợp lệ: " + session.getStatus());
            }
        }

        int sessionInterval = (session.getQrRotationIntervalSeconds() != null && session.getQrRotationIntervalSeconds() >= 10)
                ? session.getQrRotationIntervalSeconds()
                : (defaultRotationSeconds > 0 ? defaultRotationSeconds : 10);
        int rotationIntervalSeconds = Math.max(10, Math.min(300, sessionInterval));
        int gracePeriodSeconds = Math.max(5, (int) Math.round(rotationIntervalSeconds * 0.1));
        int ttlSeconds = rotationIntervalSeconds + gracePeriodSeconds;

        Object lock = sessionLocks.computeIfAbsent(sessionId, k -> new Object());
        synchronized (lock) {
            Instant now = Instant.now();

            // Check if there is an active QR code within rotation interval
            DynamicQrRedisService.ActiveQrEntry activeEntry = dynamicQrRedisService.getActiveQr(sessionId);
            if (activeEntry != null && !activeEntry.isRotationExpired(now)) {
                long remaining = Duration.between(now, activeEntry.rotationExpiresAt()).getSeconds();
                if (remaining < 0) remaining = 0;

                String activeOtp = activeEntry.otpCode();
                if (activeOtp == null || activeOtp.trim().isEmpty()) {
                    int num = secureRandom.nextInt(1_000_000);
                    activeOtp = String.format("%06d", num);
                    dynamicQrRedisService.saveActiveQr(sessionId, activeEntry.qrToken(), activeOtp,
                            activeEntry.issuedAt(), activeEntry.expiresAt(), activeEntry.rotationExpiresAt());
                }

                LocalDateTime issuedLdt = LocalDateTime.ofInstant(activeEntry.issuedAt(), ZoneId.systemDefault());
                LocalDateTime expiresLdt = LocalDateTime.ofInstant(activeEntry.expiresAt(), ZoneId.systemDefault());
                LocalDateTime rotExpLdt = LocalDateTime.ofInstant(activeEntry.rotationExpiresAt(), ZoneId.systemDefault());

                return QrTokenResponse.builder()
                        .sessionId(sessionId)
                        .qrToken(activeEntry.qrToken())
                        .otpCode(activeOtp)
                        .issuedAt(issuedLdt)
                        .expiresAt(expiresLdt)
                        .rotationExpiresAt(rotExpLdt)
                        .rotationIntervalSeconds(rotationIntervalSeconds)
                        .remainingSeconds(remaining)
                        .status(session.getStatus())
                        .mode("DYNAMIC_QR")
                        .build();
            }

            // Generate new rotating QR token & 6-digit OTP code
            Instant issuedAt = now;
            Instant expiresAt = now.plusSeconds(ttlSeconds);
            Instant rotationExpiresAt = now.plusSeconds(rotationIntervalSeconds);

            String token = qrTokenService.generateQrToken(
                    sessionId,
                    issuedAt,
                    Duration.ofSeconds(ttlSeconds),
                    Duration.ofSeconds(rotationIntervalSeconds)
            );

            // Cryptographically secure 6-digit OTP preserving leading zero (%06d)
            int otpNum = secureRandom.nextInt(1_000_000);
            String otpCode = String.format("%06d", otpNum);

            // Dual-write into Redis / Resilient fallback store
            dynamicQrRedisService.saveActiveQr(sessionId, token, otpCode, issuedAt, expiresAt, rotationExpiresAt);

            // Log without revealing plaintext OTP
            log.info("Issued new dynamic QR and OTP for session #{} (TTL: {}s, Rotation: {}s, OTP: ***{})",
                    sessionId, ttlSeconds, rotationIntervalSeconds, otpCode.substring(4));

            LocalDateTime issuedLdt = LocalDateTime.ofInstant(issuedAt, ZoneId.systemDefault());
            LocalDateTime expiresLdt = LocalDateTime.ofInstant(expiresAt, ZoneId.systemDefault());
            LocalDateTime rotExpLdt = LocalDateTime.ofInstant(rotationExpiresAt, ZoneId.systemDefault());

            return QrTokenResponse.builder()
                    .sessionId(sessionId)
                    .qrToken(token)
                    .otpCode(otpCode)
                    .issuedAt(issuedLdt)
                    .expiresAt(expiresLdt)
                    .rotationExpiresAt(rotExpLdt)
                    .rotationIntervalSeconds(rotationIntervalSeconds)
                    .remainingSeconds((long) rotationIntervalSeconds)
                    .status(session.getStatus())
                    .mode("DYNAMIC_QR")
                    .build();
        }
    }

    @Override
    @Transactional(readOnly = true)
    public QrValidationResponse validateQrToken(QrValidationRequest request) {
        return validateQrToken(request, null);
    }

    @Override
    @Transactional(readOnly = true)
    public QrValidationResponse validateQrToken(QrValidationRequest request, UserPrincipal principal) {
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

        // 4.1. Slot time validation: slot must not be ended
        TimetableSlot slot = session.getTimetableSlot();
        if (slot != null) {
            LocalDate slotDate = slot.getDate();
            LocalTime slotEndTime = slot.getEndTime();
            if (slotEndTime == null && slot.getSlotType() != null) {
                slotEndTime = slot.getSlotType().getEndTime();
            }
            LocalDate today = LocalDate.now();
            LocalTime currentTime = LocalTime.now();

            if (slotDate != null && slotDate.isBefore(today)) {
                throw new AppException(ErrorCode.SESSION_NOT_OPEN,
                        "Ca học gắn với phiên điểm danh đã kết thúc vào ngày " + slotDate);
            }
            if (slotEndTime != null && slotDate != null && slotDate.isEqual(today) && currentTime.isAfter(slotEndTime)) {
                throw new AppException(ErrorCode.SESSION_NOT_OPEN,
                        "Ca học gắn với phiên điểm danh đã kết thúc lúc " + slotEndTime);
            }
        }

        // Extract metadata for student UI check-in confirmation
        String className = "N/A";
        String roomName = "N/A";
        Long roomId = null;
        String roomCode = null;
        Long slotId = null;
        if (session.getTimetableSlot() != null) {
            slotId = session.getTimetableSlot().getId();
            if (session.getTimetableSlot().getClassSection() != null) {
                className = session.getTimetableSlot().getClassSection().getClassName();
            }
            if (session.getTimetableSlot().getRoom() != null) {
                roomId = session.getTimetableSlot().getRoom().getId();
                roomCode = session.getTimetableSlot().getRoom().getCode();
                roomName = session.getTimetableSlot().getRoom().getName() != null 
                        ? session.getTimetableSlot().getRoom().getName() 
                        : session.getTimetableSlot().getRoom().getCode();
            }
        }

        boolean simAllowed = wifiSimulationService != null && wifiSimulationService.isWifiSimulationAllowedForSession(session);

        // Cấp Verification Ticket cho sinh viên (gắn với studentId, sessionId, slotId, 180s TTL)
        String ticketId = null;
        LocalDateTime ticketExpiresAt = null;
        if (principal != null && principal.getUser() != null && verificationTicketService != null) {
            Long studentId = principal.getUser().getId();
            var ticket = verificationTicketService.issueTicket(
                    studentId,
                    session.getId(),
                    slotId,
                    "QR"
            );
            if (ticket != null) {
                ticketId = ticket.ticketId();
                ticketExpiresAt = LocalDateTime.ofInstant(ticket.expiresAt(), ZoneId.systemDefault());
            }
        }

        LocalDateTime issuedLdt = LocalDateTime.ofInstant(claims.getIssuedAt(), ZoneId.systemDefault());
        LocalDateTime expiresLdt = LocalDateTime.ofInstant(claims.getExpiresAt(), ZoneId.systemDefault());

        log.info("Validated dynamic QR token successfully for session #{} (SimulationAllowed={}, Ticket={})",
                session.getId(), simAllowed, ticketId);

        return QrValidationResponse.builder()
                .valid(true)
                .sessionId(session.getId())
                .className(className)
                .roomName(roomName)
                .roomId(roomId)
                .roomCode(roomCode)
                .wifiSimulationAllowed(simAllowed)
                .simulatedSsid(simAllowed ? wifiSimulationService.getSimulatedSsidForSession(session) : null)
                .simulatedBssid(simAllowed ? wifiSimulationService.getSimulatedBssidForSession(session) : null)
                .verificationTicket(ticketId)
                .ticketExpiresAt(ticketExpiresAt)
                .issuedAt(issuedLdt)
                .expiresAt(expiresLdt)
                .message("Xác thực mã QR thành công")
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public OtpValidationResponse validateOtp(OtpValidationRequest request, UserPrincipal principal) {
        validateAuthenticatedUser(principal);
        User student = principal.getUser();

        // 1. Role verification
        if (student.getRole() != Role.STUDENT && student.getRole() != Role.ADMIN) {
            throw new AppException(ErrorCode.FORBIDDEN, "Chỉ sinh viên mới có quyền xác thực điểm danh");
        }

        // 2. Anti-brute-force rate limiting: max 5 failed attempts per 60 seconds
        if (dynamicQrRedisService.isOtpRateLimited(student.getId())) {
            log.warn("Student #{} exceeded OTP validation rate limit", student.getId());
            throw new AppException(ErrorCode.RATE_LIMIT_EXCEEDED,
                    "Bạn đã nhập sai mã OTP quá 5 lần. Vui lòng thử lại sau 1 phút.");
        }

        if (request == null || request.getOtpCode() == null || !request.getOtpCode().matches("^[0-9]{6}$")) {
            int failCount = dynamicQrRedisService.recordOtpFailure(student.getId());
            throw new AppException(ErrorCode.INVALID_REQUEST,
                    "Mã OTP phải gồm đúng 6 chữ số (Lần sai: " + failCount + "/5)");
        }

        String submittedOtp = request.getOtpCode().trim();

        // 3. Resolve target session
        Long resolvedSessionId = request.getSessionId();
        if (resolvedSessionId == null) {
            resolvedSessionId = dynamicQrRedisService.getSessionIdByOtp(submittedOtp);
        }

        if (resolvedSessionId == null) {
            int failCount = dynamicQrRedisService.recordOtpFailure(student.getId());
            throw new AppException(ErrorCode.INVALID_OTP,
                    "Mã OTP không chính xác hoặc phiên điểm danh không tồn tại (Lần sai: " + failCount + "/5)");
        }

        final Long targetSessionId = resolvedSessionId;

        // 4. Verify Session exists
        AttendanceSession session = attendanceSessionRepository.findById(targetSessionId)
                .orElseThrow(() -> {
                    int failCount = dynamicQrRedisService.recordOtpFailure(student.getId());
                    return new AppException(ErrorCode.ATTENDANCE_SESSION_NOT_FOUND,
                            "Không tìm thấy phiên điểm danh với ID: " + targetSessionId);
                });

        // 5. Verify Session status is OPEN
        if (session.getStatus() != AttendanceSessionStatus.OPEN) {
            throw new AppException(ErrorCode.SESSION_NOT_OPEN,
                    "Phiên điểm danh hiện không ở trạng thái mở tiếp nhận (Trạng thái: " + session.getStatus() + ")");
        }

        // 6. Verify Slot time
        TimetableSlot slot = session.getTimetableSlot();
        if (slot != null) {
            LocalDate slotDate = slot.getDate();
            LocalTime slotEndTime = slot.getEndTime();
            if (slotEndTime == null && slot.getSlotType() != null) {
                slotEndTime = slot.getSlotType().getEndTime();
            }
            LocalDate today = LocalDate.now();
            LocalTime currentTime = LocalTime.now();

            if (slotDate != null && slotDate.isBefore(today)) {
                throw new AppException(ErrorCode.SESSION_NOT_OPEN,
                        "Ca học gắn với phiên điểm danh đã kết thúc vào ngày " + slotDate);
            }
            if (slotEndTime != null && slotDate != null && slotDate.isEqual(today) && currentTime.isAfter(slotEndTime)) {
                throw new AppException(ErrorCode.SESSION_NOT_OPEN,
                        "Ca học gắn với phiên điểm danh đã kết thúc lúc " + slotEndTime);
            }
        }

        // 7. Verify Student enrollment
        if (slot != null && slot.getClassSection() != null) {
            String className = slot.getClassSection().getClassName();
            boolean isEnrolled = enrollmentRepository.existsByClassSection_ClassNameAndStudent_Id(className, student.getId());
            if (!isEnrolled && student.getRole() != Role.ADMIN) {
                log.warn("Student #{} ({}) is not enrolled in class {}", student.getId(), student.getCode(), className);
                throw new AppException(ErrorCode.FORBIDDEN,
                        "Sinh viên " + student.getCode() + " không được ghi danh vào lớp học phần " + className);
            }
        }

        // 8. Verify Duplicate check-in
        Optional<StudentAttendance> existingRecordOpt = studentAttendanceRepository.findBySessionIdAndStudentId(session.getId(), student.getId());
        if (existingRecordOpt.isPresent()) {
            String status = existingRecordOpt.get().getStatus();
            if ("PRESENT".equalsIgnoreCase(status) || "LATE".equalsIgnoreCase(status)) {
                boolean hasPendingRecheck = attendanceRecheckRequestRepository
                        .findFirstBySessionIdAndStudentIdAndStatus(session.getId(), student.getId(), "PENDING")
                        .isPresent();
                if (!hasPendingRecheck) {
                    throw new AppException(ErrorCode.ALREADY_CHECKED_IN,
                            "Bạn đã điểm danh thành công cho ca học này rồi.");
                }
            }
        }

        // 9. Verify OTP match against active dynamic QR cache
        DynamicQrRedisService.ActiveQrEntry activeEntry = dynamicQrRedisService.getActiveQr(session.getId());
        Instant now = Instant.now();

        if (activeEntry == null || activeEntry.isTokenExpired(now) || activeEntry.isRotationExpired(now)) {
            int failCount = dynamicQrRedisService.recordOtpFailure(student.getId());
            throw new AppException(ErrorCode.INVALID_OTP,
                    "Mã OTP điểm danh đã hết hạn sử dụng. Vui lòng quan sát mã mới trên màn hình giảng viên (Lần sai: " + failCount + "/5)");
        }

        if (!submittedOtp.equals(activeEntry.otpCode())) {
            int failCount = dynamicQrRedisService.recordOtpFailure(student.getId());
            throw new AppException(ErrorCode.INVALID_OTP,
                    "Mã OTP điểm danh không chính xác (Lần sai: " + failCount + "/5)");
        }

        // Successful OTP check -> clear failure counter
        dynamicQrRedisService.clearOtpFailure(student.getId());

        // Secure logging: DO NOT log plaintext OTP
        log.info("Student #{} ({}) verified OTP successfully for session #{} (slot #{})",
                student.getId(), student.getCode(), session.getId(), slot != null ? slot.getId() : null);

        // Extract metadata
        String className = "N/A";
        String courseCode = "N/A";
        String courseName = "N/A";
        String roomName = "N/A";
        Long roomId = null;
        String roomCode = null;
        Long slotId = null;

        if (slot != null) {
            slotId = slot.getId();
            if (slot.getClassSection() != null) {
                className = slot.getClassSection().getClassName();
                if (slot.getClassSection().getCourse() != null) {
                    courseCode = slot.getClassSection().getCourse().getCode();
                    courseName = slot.getClassSection().getCourse().getName();
                }
            }
            if (slot.getRoom() != null) {
                roomId = slot.getRoom().getId();
                roomCode = slot.getRoom().getCode();
                roomName = slot.getRoom().getName() != null
                        ? slot.getRoom().getName()
                        : slot.getRoom().getCode();
            }
        }

        boolean simAllowed = wifiSimulationService != null && wifiSimulationService.isWifiSimulationAllowedForSession(session);
        LocalDateTime issuedLdt = LocalDateTime.ofInstant(activeEntry.issuedAt(), ZoneId.systemDefault());
        LocalDateTime expiresLdt = LocalDateTime.ofInstant(activeEntry.rotationExpiresAt(), ZoneId.systemDefault());

        // Cấp Verification Ticket cho sinh viên (gắn với studentId, sessionId, slotId, 180s TTL)
        String ticketId = null;
        LocalDateTime ticketExpiresAt = null;
        if (student != null && verificationTicketService != null) {
            var ticket = verificationTicketService.issueTicket(
                    student.getId(),
                    session.getId(),
                    slotId,
                    "OTP"
            );
            if (ticket != null) {
                ticketId = ticket.ticketId();
                ticketExpiresAt = LocalDateTime.ofInstant(ticket.expiresAt(), ZoneId.systemDefault());
            }
        }

        return OtpValidationResponse.builder()
                .valid(true)
                .sessionId(session.getId())
                .slotId(slotId)
                .className(className)
                .courseCode(courseCode)
                .courseName(courseName)
                .roomId(roomId)
                .roomCode(roomCode)
                .roomName(roomName)
                .qrToken(activeEntry.qrToken()) // Forward active QR token for subsequent checks & checkin
                .wifiSimulationAllowed(simAllowed)
                .simulatedSsid(simAllowed ? wifiSimulationService.getSimulatedSsidForSession(session) : null)
                .simulatedBssid(simAllowed ? wifiSimulationService.getSimulatedBssidForSession(session) : null)
                .verificationTicket(ticketId)
                .ticketExpiresAt(ticketExpiresAt)
                .issuedAt(issuedLdt)
                .expiresAt(expiresLdt)
                .message("Xác thực mã OTP điểm danh thành công")
                .verificationMethod("OTP")
                .build();
    }

    @Override
    public void invalidateSessionQr(Long sessionId) {
        if (sessionId != null) {
            dynamicQrRedisService.invalidate(sessionId);
            if (staticTestQrService != null) {
                staticTestQrService.invalidateSessionStaticQr(sessionId);
            }
        }
    }

    private void validateAuthenticatedUser(UserPrincipal principal) {
        if (principal == null || principal.getUser() == null) {
            throw new AppException(ErrorCode.UNAUTHORIZED, "Người dùng chưa đăng nhập hoặc phiên đã hết hạn");
        }
    }
}
