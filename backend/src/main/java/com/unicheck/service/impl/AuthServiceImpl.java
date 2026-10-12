package com.unicheck.service.impl;

import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.*;
import com.unicheck.model.entity.*;
import com.unicheck.model.enums.UserStatus;
import com.unicheck.repository.*;
import com.unicheck.security.JwtAuthenticationFilter;
import com.unicheck.security.JwtUtil;
import com.unicheck.security.TokenRedisService;
import com.unicheck.service.AuthService;
import com.unicheck.service.EmailService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final StudentProfileRepository studentProfileRepository;
    private final LecturerProfileRepository lecturerProfileRepository;
    private final UserSessionRepository userSessionRepository;
    private final AccessLogRepository accessLogRepository;
    private final JwtUtil jwtUtil;
    private final TokenRedisService tokenRedisService;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;

    private static final SecureRandom RANDOM = new SecureRandom();

    @Override
    @Transactional
    public LoginResponse login(LoginRequest request, HttpServletRequest httpRequest) {
        String clientIp = extractClientIp(httpRequest);
        String usernameOrIdentifier = request.getUsername().trim();

        // 1. Rate limiting check (5 failed attempts within 15 minutes by account & IP)
        if (tokenRedisService.isLoginBlocked(usernameOrIdentifier, clientIp)) {
            log.warn("Login attempt blocked due to rate limiting for identifier: {}, IP: {}", usernameOrIdentifier, clientIp);
            throw new AppException(ErrorCode.RATE_LIMIT_EXCEEDED);
        }

        // 2. Lookup user by username, email or code
        User user = userRepository.findByUsername(usernameOrIdentifier)
                .or(() -> userRepository.findByEmail(usernameOrIdentifier))
                .or(() -> userRepository.findByCode(usernameOrIdentifier))
                .orElse(null);

        // 3. Validate credentials without revealing if user exists or not
        if (user == null || user.getPassword() == null || !passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            tokenRedisService.recordFailedLogin(usernameOrIdentifier, clientIp);
            log.warn("Invalid login attempt for identifier: {}, IP: {}", usernameOrIdentifier, clientIp);
            throw new AppException(ErrorCode.INVALID_CREDENTIALS);
        }

        // 4. Check account status
        if (user.getStatus() == UserStatus.BLOCKED) {
            throw new AppException(ErrorCode.ACCOUNT_LOCKED);
        }
        if (user.getStatus() == UserStatus.INACTIVE) {
            throw new AppException(ErrorCode.ACCOUNT_INACTIVE);
        }

        // 5. Reset failed login attempts on success
        tokenRedisService.resetFailedLogins(usernameOrIdentifier, clientIp);

        // 6. Generate access token (15 mins) and refresh token (7 days)
        String accessToken = jwtUtil.generateAccessToken(user);
        String refreshToken = jwtUtil.generateRefreshToken(user);

        // 7. Store refresh token in Redis (7 days TTL) and link with access token
        tokenRedisService.saveRefreshToken(refreshToken, user.getUsername(), Duration.ofMillis(jwtUtil.getRefreshTokenExpirationMs()));
        tokenRedisService.linkAccessTokenToRefreshToken(accessToken, refreshToken, Duration.ofMillis(jwtUtil.getRefreshTokenExpirationMs()));

        // 8. Record user session in database
        String userAgent = httpRequest != null ? httpRequest.getHeader("User-Agent") : "Unknown";
        UserSession session = UserSession.builder()
                .user(user)
                .token(accessToken)
                .ipAddress(clientIp)
                .userAgent(userAgent != null && userAgent.length() > 500 ? userAgent.substring(0, 500) : userAgent)
                .isActive(true)
                .loginTime(LocalDateTime.now())
                .lastActivityTime(LocalDateTime.now())
                .build();
        userSessionRepository.save(session);

        // 9. Record access log in database
        AccessLog accessLog = AccessLog.builder()
                .user(user)
                .location("Vietnam")
                .status("SUCCESS")
                .ipAddress(clientIp)
                .userAgent(userAgent != null && userAgent.length() > 255 ? userAgent.substring(0, 255) : userAgent)
                .accessTime(LocalDateTime.now())
                .build();
        accessLogRepository.save(accessLog);

        return LoginResponse.builder()
                .token(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(jwtUtil.getAccessTokenExpirationMs() / 1000)
                .userId(user.getId())
                .code(user.getCode())
                .username(user.getUsername())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .role(user.getRole())
                .isPasswordChanged(user.getIsPasswordChanged())
                .build();
    }

    @Override
    @Transactional
    public void logout(HttpServletRequest httpRequest) {
        String token = JwtAuthenticationFilter.extractJwtFromRequest(httpRequest);
        String currentUsername = getCurrentUsernameOrNull();

        if (StringUtils.hasText(token)) {
            // 1. Blacklist access token in Redis for remaining validity duration
            long remainingMs = jwtUtil.getRemainingExpirationMs(token);
            tokenRedisService.blacklistAccessToken(token, Duration.ofMillis(remainingMs));

            // 2. Revoke associated refresh token from Redis
            String linkedRefreshToken = tokenRedisService.getRefreshTokenByAccessToken(token);
            if (linkedRefreshToken != null) {
                tokenRedisService.revokeRefreshToken(linkedRefreshToken);
            }

            String headerRefreshToken = httpRequest != null ? httpRequest.getHeader("X-Refresh-Token") : null;
            if (StringUtils.hasText(headerRefreshToken)) {
                tokenRedisService.revokeRefreshToken(headerRefreshToken);
            }

            if (currentUsername == null) {
                try {
                    currentUsername = jwtUtil.extractUsername(token);
                } catch (Exception ignored) {}
            }

            // 3. Revoke all user refresh tokens and invalidate sessions
            if (currentUsername != null) {
                tokenRedisService.revokeUserRefreshTokens(currentUsername);

                userRepository.findByUsername(currentUsername).ifPresent(user -> {
                    // Invalidate active sessions
                    List<UserSession> sessions = userSessionRepository.findByUserIdAndIsActiveTrue(user.getId());
                    for (UserSession s : sessions) {
                        s.setIsActive(false);
                        s.setLastActivityTime(LocalDateTime.now());
                    }
                    userSessionRepository.saveAll(sessions);

                    // Record logout in AccessLog
                    AccessLog logoutLog = AccessLog.builder()
                            .user(user)
                            .location("Vietnam")
                            .status("LOGOUT")
                            .ipAddress(extractClientIp(httpRequest))
                            .userAgent(httpRequest != null ? httpRequest.getHeader("User-Agent") : null)
                            .accessTime(LocalDateTime.now())
                            .build();
                    accessLogRepository.save(logoutLog);
                });
            }
        }
    }

    @Override
    @Transactional(readOnly = true)
    public TokenRefreshResponse refreshToken(RefreshTokenRequest request) {
        String refreshToken = request.getRefreshToken();
        if (!StringUtils.hasText(refreshToken)) {
            throw new AppException(ErrorCode.TOKEN_INVALID);
        }

        // 1. Check if refresh token is in Redis and not revoked
        String username = tokenRedisService.getUsernameFromRefreshToken(refreshToken);
        if (username == null || tokenRedisService.isRefreshTokenRevoked(refreshToken)) {
            throw new AppException(ErrorCode.TOKEN_REVOKED);
        }

        // 2. Validate token signature and expiration
        if (!jwtUtil.validateToken(refreshToken)) {
            throw new AppException(ErrorCode.TOKEN_EXPIRED);
        }

        // 3. Lookup user
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new AppException(ErrorCode.INVALID_CREDENTIALS));

        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new AppException(ErrorCode.ACCOUNT_LOCKED);
        }

        // 4. Generate new access token and link with refresh token
        String newAccessToken = jwtUtil.generateAccessToken(user);
        tokenRedisService.linkAccessTokenToRefreshToken(newAccessToken, refreshToken, Duration.ofMillis(jwtUtil.getRefreshTokenExpirationMs()));

        return TokenRefreshResponse.builder()
                .token(newAccessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(jwtUtil.getAccessTokenExpirationMs() / 1000)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public UserProfileResponse getCurrentUserProfile() {
        String username = getCurrentAuthenticatedUsername();
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND));

        return buildUserProfileResponse(user);
    }

    @Override
    @Transactional
    public UserProfileResponse updateProfile(UpdateProfileRequest request) {
        String username = getCurrentAuthenticatedUsername();
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND));

        if (StringUtils.hasText(request.getFullName())) {
            user.setFullName(request.getFullName().trim());
        }
        if (StringUtils.hasText(request.getPhone())) {
            user.setPhone(request.getPhone().trim());
        }
        if (request.getDob() != null) {
            user.setDob(request.getDob());
        }
        if (StringUtils.hasText(request.getSex())) {
            user.setSex(request.getSex().trim());
        }
        if (StringUtils.hasText(request.getAvatar())) {
            user.setAvatar(request.getAvatar().trim());
        }

        User updatedUser = userRepository.save(user);
        return buildUserProfileResponse(updatedUser);
    }

    @Override
    @Transactional
    public void changePassword(ChangePasswordRequest request) {
        String username = getCurrentAuthenticatedUsername();
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new AppException(ErrorCode.RESOURCE_NOT_FOUND));

        // Validate old password
        if (!passwordEncoder.matches(request.getOldPassword(), user.getPassword())) {
            throw new AppException(ErrorCode.PASSWORD_MISMATCH);
        }

        // Update with BCrypt encoded new password
        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        user.setIsPasswordChanged(true);
        userRepository.save(user);
    }

    @Override
    public void processForgotPassword(ForgotPasswordRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        // Lookup user by email
        userRepository.findByEmail(email).ifPresent(user -> {
            // Generate random 6-digit OTP
            String otp = String.format("%06d", RANDOM.nextInt(1000000));
            // Save in Redis for 10 minutes (600 seconds)
            tokenRedisService.savePasswordResetOtp(email, otp);
            // Send OTP email
            emailService.sendOtpEmail(email, otp);
        });
        // Never reveal whether the email actually exists
    }

    @Override
    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        String otp = request.getOtp().trim();

        // 1. Verify and consume OTP from Redis
        boolean isOtpValid = tokenRedisService.verifyAndConsumePasswordResetOtp(email, otp);
        if (!isOtpValid) {
            throw new AppException(ErrorCode.INVALID_OTP);
        }

        // 2. Find user and update password
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new AppException(ErrorCode.INVALID_OTP));

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        user.setIsPasswordChanged(true);
        userRepository.save(user);
    }

    private String getCurrentAuthenticatedUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }
        return authentication.getName();
    }

    private String getCurrentUsernameOrNull() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication != null && authentication.isAuthenticated() && !"anonymousUser".equals(authentication.getPrincipal())) {
                return authentication.getName();
            }
        } catch (Exception ignored) {}
        return null;
    }

    private String extractClientIp(HttpServletRequest request) {
        if (request == null) {
            return "127.0.0.1";
        }
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (StringUtils.hasText(xForwardedFor)) {
            return xForwardedFor.split(",")[0].trim();
        }
        String remoteAddr = request.getRemoteAddr();
        return StringUtils.hasText(remoteAddr) ? remoteAddr : "127.0.0.1";
    }

    private UserProfileResponse buildUserProfileResponse(User user) {
        UserProfileResponse.UserProfileResponseBuilder builder = UserProfileResponse.builder()
                .id(user.getId())
                .code(user.getCode())
                .username(user.getUsername())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .dob(user.getDob())
                .phone(user.getPhone())
                .sex(user.getSex())
                .role(user.getRole())
                .status(user.getStatus())
                .faceDataStatus(user.getFaceDataStatus())
                .avatar(user.getAvatar())
                .isPasswordChanged(user.getIsPasswordChanged())
                .createdAt(user.getCreatedAt());

        // Student Profile details
        studentProfileRepository.findByUserId(user.getId()).ifPresent(sp -> {
            builder.studentCourse(sp.getCourse())
                    .gpa(sp.getGpa())
                    .majorId(sp.getMajorId())
                    .specializationId(sp.getSpecializationId())
                    .subSpecializationId(sp.getSubSpecializationId());
        });

        // Lecturer Profile details
        lecturerProfileRepository.findByUserId(user.getId()).ifPresent(lp -> {
            builder.department(lp.getDepartment())
                    .expertise(lp.getExpertise())
                    .bio(lp.getBio());
        });

        // Permissions
        if (user.getPermissions() != null) {
            List<String> perms = user.getPermissions().stream()
                    .map(UserPermission::getPermission)
                    .collect(Collectors.toList());
            builder.permissions(perms);
        }

        return builder.build();
    }
}
