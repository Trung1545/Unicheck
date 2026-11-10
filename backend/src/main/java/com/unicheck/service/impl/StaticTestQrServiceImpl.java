package com.unicheck.service.impl;

import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.QrTokenResponse;
import com.unicheck.model.dto.QrValidationRequest;
import com.unicheck.model.dto.QrValidationResponse;
import com.unicheck.model.dto.StaticQrStatusResponse;
import com.unicheck.model.entity.AttendanceSession;
import com.unicheck.model.entity.TimetableSlot;
import com.unicheck.model.entity.User;
import com.unicheck.model.enums.AttendanceSessionStatus;
import com.unicheck.model.enums.Role;
import com.unicheck.repository.AttendanceSessionRepository;
import com.unicheck.security.UserPrincipal;
import com.unicheck.service.StaticTestQrService;
import com.unicheck.service.WifiSimulationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
public class StaticTestQrServiceImpl implements StaticTestQrService {

    public static final String STATIC_TOKEN_PREFIX = "STQR:";
    public static final String MODE_STATIC_TEST_QR = "STATIC_TEST_QR";

    private final AttendanceSessionRepository attendanceSessionRepository;
    private final StringRedisTemplate redisTemplate;
    private final Environment environment;
    private final WifiSimulationService wifiSimulationService;
    private final com.unicheck.service.AttendanceVerificationTicketService verificationTicketService;

    @Value("${unicheck.testing.static-qr.enabled:false}")
    private boolean staticQrEnabled;

    @Value("${unicheck.testing.static-qr.allowed-class-name:SE1801-PRJ301,UNICHECK-E2E-01}")
    private String allowedClassName;

    @Value("${unicheck.testing.static-qr.ttl-minutes:30}")
    private int ttlMinutes;

    private final SecureRandom secureRandom = new SecureRandom();

    /**
     * Entry lưu trữ thông tin Static QR.
     * TUYỆT ĐỐI KHÔNG LƯU PLAINTEXT TOKEN: chỉ lưu tokenHash (SHA-256).
     */
    public record StaticQrEntry(
            String tokenHash,
            Long sessionId,
            Instant issuedAt,
            Instant expiresAt,
            boolean revoked
    ) {
        public boolean isExpired(Instant now) {
            return now.isAfter(expiresAt);
        }

        public String serialize() {
            return tokenHash + "|" + sessionId + "|" + issuedAt.toEpochMilli() + "|" + expiresAt.toEpochMilli() + "|" + (revoked ? "1" : "0");
        }

        public static StaticQrEntry deserialize(String raw) {
            if (raw == null || raw.trim().isEmpty()) {
                return null;
            }
            String[] parts = raw.split("\\|", 5);
            if (parts.length < 5) {
                return null;
            }
            return new StaticQrEntry(
                    parts[0],
                    Long.parseLong(parts[1]),
                    Instant.ofEpochMilli(Long.parseLong(parts[2])),
                    Instant.ofEpochMilli(Long.parseLong(parts[3])),
                    "1".equals(parts[4])
            );
        }
    }

    // In-memory dual-write fallback cache
    private final Map<String, StaticQrEntry> localFallbackCache = new ConcurrentHashMap<>();
    private final Map<Long, Object> sessionLocks = new ConcurrentHashMap<>();

    public StaticTestQrServiceImpl(
            AttendanceSessionRepository attendanceSessionRepository,
            @Autowired(required = false) StringRedisTemplate redisTemplate,
            Environment environment
    ) {
        this(attendanceSessionRepository, redisTemplate, environment, null, null);
    }

    public StaticTestQrServiceImpl(
            AttendanceSessionRepository attendanceSessionRepository,
            @Autowired(required = false) StringRedisTemplate redisTemplate,
            Environment environment,
            @Autowired(required = false) WifiSimulationService wifiSimulationService
    ) {
        this(attendanceSessionRepository, redisTemplate, environment, wifiSimulationService, null);
    }

    @Autowired
    public StaticTestQrServiceImpl(
            AttendanceSessionRepository attendanceSessionRepository,
            @Autowired(required = false) StringRedisTemplate redisTemplate,
            Environment environment,
            @Autowired(required = false) WifiSimulationService wifiSimulationService,
            @Autowired(required = false) com.unicheck.service.AttendanceVerificationTicketService verificationTicketService
    ) {
        this.attendanceSessionRepository = attendanceSessionRepository;
        this.redisTemplate = redisTemplate;
        this.environment = environment;
        this.wifiSimulationService = wifiSimulationService;
        this.verificationTicketService = verificationTicketService;
    }

    @Override
    public boolean isStaticQrEnabledInEnvironment() {
        if (!staticQrEnabled) {
            return false;
        }

        String[] activeProfiles = environment.getActiveProfiles();
        if (activeProfiles == null || activeProfiles.length == 0) {
            activeProfiles = environment.getDefaultProfiles();
        }

        // Production environment is STRICTLY prohibited
        for (String profile : activeProfiles) {
            if ("prod".equalsIgnoreCase(profile) || "production".equalsIgnoreCase(profile)) {
                log.error("SECURITY ALERT: Static Test QR attempted on production profile: {}", profile);
                return false;
            }
        }

        // Profile must be in dedicated test/dev whitelist
        return Arrays.stream(activeProfiles)
                .anyMatch(p -> p.equalsIgnoreCase("test") ||
                               p.equalsIgnoreCase("e2e") ||
                               p.equalsIgnoreCase("dev") ||
                               p.equalsIgnoreCase("development") ||
                               p.equalsIgnoreCase("local"));
    }

    @Override
    @Transactional(readOnly = true)
    public StaticQrStatusResponse checkStaticQrCapability(UserPrincipal principal, Long sessionId) {
        if (!isStaticQrEnabledInEnvironment()) {
            return StaticQrStatusResponse.builder()
                    .allowed(false)
                    .reason("Môi trường hiện tại không kích hoạt Static Test QR (Yêu cầu profile dev/test cô lập)")
                    .sessionId(sessionId)
                    .build();
        }

        if (principal == null || principal.getUser() == null) {
            return StaticQrStatusResponse.builder()
                    .allowed(false)
                    .reason("Người dùng chưa xác thực")
                    .sessionId(sessionId)
                    .build();
        }

        User user = principal.getUser();
        if (user.getRole() == Role.STUDENT) {
            return StaticQrStatusResponse.builder()
                    .allowed(false)
                    .reason("Tài khoản sinh viên không có quyền quản lý mã QR Test")
                    .sessionId(sessionId)
                    .build();
        }

        AttendanceSession session = attendanceSessionRepository.findById(sessionId).orElse(null);
        if (session == null) {
            return StaticQrStatusResponse.builder()
                    .allowed(false)
                    .reason("Không tìm thấy phiên điểm danh #" + sessionId)
                    .sessionId(sessionId)
                    .build();
        }

        if (user.getRole() == Role.LECTURER) {
            if (session.getLecturer() == null || !session.getLecturer().getId().equals(user.getId())) {
                return StaticQrStatusResponse.builder()
                        .allowed(false)
                        .reason("Giảng viên không phụ trách phiên điểm danh này")
                        .sessionId(sessionId)
                        .sessionStatus(session.getStatus())
                        .build();
            }
        }

        String sessionClassName = getSessionClassName(session);
        if (!isClassAllowed(sessionClassName)) {
            return StaticQrStatusResponse.builder()
                    .allowed(false)
                    .reason("Static Test QR chỉ áp dụng cho lớp thử nghiệm chỉ định: " + allowedClassName + " (Lớp hiện tại: " + sessionClassName + ")")
                    .className(sessionClassName)
                    .sessionId(sessionId)
                    .sessionStatus(session.getStatus())
                    .build();
        }

        if (session.getStatus() != AttendanceSessionStatus.OPEN) {
            return StaticQrStatusResponse.builder()
                    .allowed(false)
                    .reason("Phiên điểm danh hiện không ở trạng thái OPEN (Trạng thái: " + session.getStatus() + ")")
                    .className(sessionClassName)
                    .sessionId(sessionId)
                    .sessionStatus(session.getStatus())
                    .build();
        }

        return StaticQrStatusResponse.builder()
                .allowed(true)
                .reason("Phiên điểm danh đủ điều kiện sử dụng mã Static Test QR")
                .className(sessionClassName)
                .sessionId(sessionId)
                .sessionStatus(session.getStatus())
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public QrTokenResponse generateOrGetStaticQrToken(UserPrincipal principal, Long sessionId) {
        validateEnvironmentAndAuthorization(principal, sessionId);

        AttendanceSession session = attendanceSessionRepository.findById(sessionId)
                .orElseThrow(() -> new AppException(ErrorCode.ATTENDANCE_SESSION_NOT_FOUND,
                        "Không tìm thấy phiên điểm danh với ID: " + sessionId));

        Object lock = sessionLocks.computeIfAbsent(sessionId, k -> new Object());
        synchronized (lock) {
            Instant now = Instant.now();
            StaticQrEntry activeEntry = getStoredEntry(sessionId);

            String activePlaintext = transientPlaintextCache.get(sessionId);
            if (activeEntry != null && !activeEntry.isExpired(now) && !activeEntry.revoked() && activePlaintext != null) {
                long remaining = Duration.between(now, activeEntry.expiresAt()).getSeconds();
                return buildResponse(sessionId, activePlaintext, activeEntry.issuedAt(), activeEntry.expiresAt(), session.getStatus(), remaining);
            }

            // Generate brand new cryptographically secure static token
            return doGenerateNewToken(sessionId, session.getStatus(), now);
        }
    }

    @Override
    @Transactional(readOnly = true)
    public QrTokenResponse regenerateStaticQrToken(UserPrincipal principal, Long sessionId) {
        validateEnvironmentAndAuthorization(principal, sessionId);

        AttendanceSession session = attendanceSessionRepository.findById(sessionId)
                .orElseThrow(() -> new AppException(ErrorCode.ATTENDANCE_SESSION_NOT_FOUND,
                        "Không tìm thấy phiên điểm danh với ID: " + sessionId));

        Object lock = sessionLocks.computeIfAbsent(sessionId, k -> new Object());
        synchronized (lock) {
            Instant now = Instant.now();
            // Invalidate old token
            revokeStaticQrTokenInternal(sessionId);

            // Generate brand new token
            return doGenerateNewToken(sessionId, session.getStatus(), now);
        }
    }

    @Override
    public void revokeStaticQrToken(UserPrincipal principal, Long sessionId) {
        validateEnvironmentAndAuthorization(principal, sessionId);
        revokeStaticQrTokenInternal(sessionId);
    }

    private void revokeStaticQrTokenInternal(Long sessionId) {
        Object lock = sessionLocks.computeIfAbsent(sessionId, k -> new Object());
        synchronized (lock) {
            transientPlaintextCache.remove(sessionId);
            String key = buildRedisKey(sessionId);
            StaticQrEntry entry = localFallbackCache.get(key);
            if (entry != null) {
                StaticQrEntry revokedEntry = new StaticQrEntry(
                        entry.tokenHash(),
                        entry.sessionId(),
                        entry.issuedAt(),
                        entry.expiresAt(),
                        true
                );
                localFallbackCache.put(key, revokedEntry);
                if (redisTemplate != null) {
                    try {
                        redisTemplate.opsForValue().set(key, revokedEntry.serialize(), Duration.ofMinutes(ttlMinutes));
                    } catch (Exception e) {
                        log.warn("Failed to write revoked static QR to Redis: {}", e.getMessage());
                    }
                }
            }
            log.info("Revoked Static Test QR for session #{}", sessionId);
        }
    }

    @Override
    public boolean isStaticToken(String qrToken) {
        if (qrToken == null || qrToken.trim().isEmpty()) {
            return false;
        }
        String trimmed = qrToken.trim();
        return trimmed.startsWith(STATIC_TOKEN_PREFIX) || trimmed.startsWith("STQR-");
    }

    @Override
    @Transactional(readOnly = true)
    public QrValidationResponse validateStaticQrToken(QrValidationRequest request) {
        return validateStaticQrToken(request, null);
    }

    @Override
    @Transactional(readOnly = true)
    public QrValidationResponse validateStaticQrToken(QrValidationRequest request, UserPrincipal principal) {
        if (request == null || request.getQrToken() == null || request.getSessionId() == null) {
            throw new AppException(ErrorCode.INVALID_REQUEST, "Dữ liệu yêu cầu xác thực QR không hợp lệ");
        }

        // Strict environment check: cannot validate static QR in production
        if (!isStaticQrEnabledInEnvironment()) {
            log.warn("Attempt to validate static test QR when static-qr is disabled in environment");
            throw new AppException(ErrorCode.STATIC_QR_NOT_ALLOWED, "Chế độ mã QR Test cố định không được phép trên môi trường này");
        }

        String rawToken = request.getQrToken().trim();
        Long requestSessionId = request.getSessionId();

        // Check format and parse session id embedded in token
        Long tokenSessionId = parseSessionIdFromToken(rawToken);
        if (tokenSessionId == null || !tokenSessionId.equals(requestSessionId)) {
            log.warn("Static QR session mismatch: tokenSession={}, requestSession={}", tokenSessionId, requestSessionId);
            throw new AppException(ErrorCode.QR_SESSION_MISMATCH,
                    "Mã QR Test không khớp với phiên điểm danh #" + requestSessionId);
        }

        // Hash token to compare with stored hash
        String computedHash = hashToken(rawToken);
        StaticQrEntry storedEntry = getStoredEntry(requestSessionId);

        if (storedEntry == null) {
            log.warn("Static QR not found or expired for session #{}", requestSessionId);
            throw new AppException(ErrorCode.QR_TOKEN_INVALID, "Mã QR Test không tồn tại hoặc đã hết hạn");
        }

        if (storedEntry.revoked()) {
            log.warn("Static QR has been revoked for session #{}", requestSessionId);
            throw new AppException(ErrorCode.QR_TOKEN_INVALID, "Mã QR Test đã bị thu hồi bởi giảng viên");
        }

        Instant now = Instant.now();
        if (storedEntry.isExpired(now)) {
            log.warn("Static QR expired for session #{}", requestSessionId);
            throw new AppException(ErrorCode.QR_TOKEN_EXPIRED, "Mã QR Test điểm danh đã hết hạn");
        }

        if (!storedEntry.tokenHash().equals(computedHash)) {
            log.warn("Static QR hash mismatch for session #{}", requestSessionId);
            throw new AppException(ErrorCode.QR_TOKEN_INVALID, "Mã QR Test không hợp lệ hoặc đã bị chỉnh sửa");
        }

        // Verify session in database
        AttendanceSession session = attendanceSessionRepository.findById(requestSessionId)
                .orElseThrow(() -> new AppException(ErrorCode.ATTENDANCE_SESSION_NOT_FOUND,
                        "Không tìm thấy phiên điểm danh với ID: " + requestSessionId));

        if (session.getStatus() != AttendanceSessionStatus.OPEN) {
            log.warn("Attempt to validate static QR against non-OPEN session #{}, status: {}",
                    session.getId(), session.getStatus());
            throw new AppException(ErrorCode.SESSION_NOT_OPEN,
                    "Phiên điểm danh hiện không ở trạng thái mở (trạng thái: " + session.getStatus() + ")");
        }

        // Verify slot is not ended
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

        // Verify class section constraint
        String className = getSessionClassName(session);
        if (!isClassAllowed(className)) {
            log.warn("Static QR validated against unauthorized class: {}", className);
            throw new AppException(ErrorCode.FORBIDDEN,
                    "Mã QR Test không áp dụng cho lớp học này (" + className + ")");
        }

        String roomName = "N/A";
        Long roomId = null;
        String roomCode = null;
        if (session.getTimetableSlot() != null && session.getTimetableSlot().getRoom() != null) {
            roomId = session.getTimetableSlot().getRoom().getId();
            roomCode = session.getTimetableSlot().getRoom().getCode();
            roomName = session.getTimetableSlot().getRoom().getName() != null
                    ? session.getTimetableSlot().getRoom().getName()
                    : session.getTimetableSlot().getRoom().getCode();
        }

        boolean simAllowed = wifiSimulationService != null && wifiSimulationService.isWifiSimulationAllowedForSession(session);

        String ticketId = null;
        LocalDateTime ticketExpiresAt = null;
        if (principal != null && principal.getUser() != null && verificationTicketService != null) {
            Long studentId = principal.getUser().getId();
            Long slotId = session.getTimetableSlot() != null ? session.getTimetableSlot().getId() : null;
            var ticket = verificationTicketService.issueTicket(
                    studentId,
                    session.getId(),
                    slotId,
                    "STATIC_TEST_QR"
            );
            if (ticket != null) {
                ticketId = ticket.ticketId();
                ticketExpiresAt = LocalDateTime.ofInstant(ticket.expiresAt(), ZoneId.systemDefault());
            }
        }

        LocalDateTime issuedLdt = LocalDateTime.ofInstant(storedEntry.issuedAt(), ZoneId.systemDefault());
        LocalDateTime expiresLdt = LocalDateTime.ofInstant(storedEntry.expiresAt(), ZoneId.systemDefault());

        log.info("Validated Static Test QR successfully for session #{} (Class: {}, SimulationAllowed={}, Ticket={})",
                session.getId(), className, simAllowed, ticketId);

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
                .message("Xác thực mã QR Test thành công (TEST MODE)")
                .build();
    }

    @Override
    public void invalidateSessionStaticQr(Long sessionId) {
        if (sessionId != null) {
            transientPlaintextCache.remove(sessionId);
            String key = buildRedisKey(sessionId);
            localFallbackCache.remove(key);
            if (redisTemplate != null) {
                try {
                    redisTemplate.delete(key);
                } catch (Exception e) {
                    log.warn("Failed to delete static QR key from Redis: {}", e.getMessage());
                }
            }
            log.info("Invalidated Static Test QR for session #{}", sessionId);
        }
    }

    // =========================================================================
    // Internal Helper Methods
    // =========================================================================

    // Transient in-memory storage of plaintext token ONLY during active issuance to display to lecturer
    private final Map<Long, String> transientPlaintextCache = new ConcurrentHashMap<>();

    private QrTokenResponse doGenerateNewToken(Long sessionId, AttendanceSessionStatus status, Instant now) {
        int durationMins = ttlMinutes > 0 ? ttlMinutes : 30;
        Instant expiresAt = now.plus(Duration.ofMinutes(durationMins));

        // 32 bytes (256 bits) cryptographically secure random bytes
        byte[] randomBytes = new byte[32];
        secureRandom.nextBytes(randomBytes);
        String randomHex = HexFormat.of().formatHex(randomBytes);

        // Format: STQR:<sessionId>:<randomHex>
        String rawToken = STATIC_TOKEN_PREFIX + sessionId + ":" + randomHex;

        // Hash token using SHA-256 (Plaintext is NEVER saved to Redis/persistent store)
        String tokenHash = hashToken(rawToken);

        StaticQrEntry entry = new StaticQrEntry(
                tokenHash,
                sessionId,
                now,
                expiresAt,
                false
        );

        String key = buildRedisKey(sessionId);
        localFallbackCache.put(key, entry);
        transientPlaintextCache.put(sessionId, rawToken);

        if (redisTemplate != null) {
            try {
                redisTemplate.opsForValue().set(key, entry.serialize(), Duration.ofMinutes(durationMins));
            } catch (Exception e) {
                log.warn("Redis unavailable during static QR write, relying on local fallback cache: {}", e.getMessage());
            }
        }

        log.info("Generated new Static Test QR for session #{}, hashPrefix: {}... (TTL: {} mins)",
                sessionId, tokenHash.substring(0, 8), durationMins);

        long remaining = Duration.between(now, expiresAt).getSeconds();
        return buildResponse(sessionId, rawToken, now, expiresAt, status, remaining);
    }

    private QrTokenResponse buildResponse(
            Long sessionId,
            String token,
            Instant issuedAt,
            Instant expiresAt,
            AttendanceSessionStatus status,
            long remainingSeconds
    ) {
        LocalDateTime issuedLdt = LocalDateTime.ofInstant(issuedAt, ZoneId.systemDefault());
        LocalDateTime expiresLdt = LocalDateTime.ofInstant(expiresAt, ZoneId.systemDefault());

        return QrTokenResponse.builder()
                .sessionId(sessionId)
                .qrToken(token)
                .issuedAt(issuedLdt)
                .expiresAt(expiresLdt)
                .rotationExpiresAt(expiresLdt) // In static mode, rotation is identical to full expiration
                .rotationIntervalSeconds(0)    // 0 indicates static mode, no interval rotation
                .remainingSeconds(Math.max(0, remainingSeconds))
                .status(status)
                .mode(MODE_STATIC_TEST_QR)
                .build();
    }

    private void validateEnvironmentAndAuthorization(UserPrincipal principal, Long sessionId) {
        if (!isStaticQrEnabledInEnvironment()) {
            throw new AppException(ErrorCode.STATIC_QR_NOT_ALLOWED,
                    "Chế độ mã QR Test cố định bị vô hiệu hóa trên môi trường hiện tại (Chỉ cho phép profile test/dev cô lập)");
        }

        if (principal == null || principal.getUser() == null) {
            throw new AppException(ErrorCode.UNAUTHORIZED, "Người dùng chưa đăng nhập hoặc phiên đã hết hạn");
        }

        User user = principal.getUser();
        if (user.getRole() == Role.STUDENT) {
            throw new AppException(ErrorCode.FORBIDDEN, "Sinh viên không có quyền phát hành hoặc quản lý mã QR Test");
        }

        AttendanceSession session = attendanceSessionRepository.findById(sessionId)
                .orElseThrow(() -> new AppException(ErrorCode.ATTENDANCE_SESSION_NOT_FOUND,
                        "Không tìm thấy phiên điểm danh với ID: " + sessionId));

        if (user.getRole() == Role.LECTURER) {
            if (session.getLecturer() == null || !session.getLecturer().getId().equals(user.getId())) {
                throw new AppException(ErrorCode.LECTURER_NOT_ASSIGNED_TO_CLASS,
                        "Giảng viên không phụ trách phiên điểm danh này");
            }
        }

        String sessionClassName = getSessionClassName(session);
        if (!isClassAllowed(sessionClassName)) {
            throw new AppException(ErrorCode.FORBIDDEN,
                    "Static Test QR chỉ áp dụng cho lớp học thử nghiệm được chỉ định: " + allowedClassName + " (Lớp hiện tại: " + sessionClassName + ")");
        }

        if (session.getStatus() != AttendanceSessionStatus.OPEN) {
            throw new AppException(ErrorCode.SESSION_NOT_OPEN,
                    "Phiên điểm danh chưa được mở (Trạng thái hiện tại: " + session.getStatus() + ")");
        }
    }

    private StaticQrEntry getStoredEntry(Long sessionId) {
        String key = buildRedisKey(sessionId);
        if (redisTemplate != null) {
            try {
                String raw = redisTemplate.opsForValue().get(key);
                if (raw != null) {
                    return StaticQrEntry.deserialize(raw);
                }
            } catch (Exception e) {
                log.warn("Redis read failed for static QR session #{}, fallback to local cache: {}", sessionId, e.getMessage());
            }
        }
        return localFallbackCache.get(key);
    }

    private Long parseSessionIdFromToken(String rawToken) {
        try {
            if (rawToken.startsWith(STATIC_TOKEN_PREFIX)) {
                String remainder = rawToken.substring(STATIC_TOKEN_PREFIX.length());
                int colonIdx = remainder.indexOf(':');
                if (colonIdx > 0) {
                    return Long.parseLong(remainder.substring(0, colonIdx));
                }
            } else if (rawToken.startsWith("STQR-")) {
                String remainder = rawToken.substring(5);
                int dashIdx = remainder.indexOf('-');
                if (dashIdx > 0) {
                    return Long.parseLong(remainder.substring(0, dashIdx));
                }
            }
        } catch (Exception e) {
            log.debug("Failed to parse sessionId from token: {}", e.getMessage());
        }
        return null;
    }

    private String hashToken(String rawToken) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(rawToken.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not available", e);
        }
    }

    private String buildRedisKey(Long sessionId) {
        return "unicheck:qr:session:" + sessionId + ":static-test";
    }

    private String getSessionClassName(AttendanceSession session) {
        if (session.getTimetableSlot() != null &&
            session.getTimetableSlot().getClassSection() != null &&
            session.getTimetableSlot().getClassSection().getClassName() != null) {
            return session.getTimetableSlot().getClassSection().getClassName();
        }
        return "N/A";
    }

    private boolean isClassAllowed(String className) {
        if (allowedClassName == null || allowedClassName.isBlank() || className == null) return false;
        String[] parts = allowedClassName.split(",");
        for (String p : parts) {
            if (p.trim().equalsIgnoreCase(className.trim())) {
                return true;
            }
        }
        return false;
    }
}
