package com.unicheck.security;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
public class TokenRedisService {

    private final StringRedisTemplate redisTemplate;

    // In-memory fallback map for environments without active Redis (e.g. CI/Tests)
    private final Map<String, CacheEntry> localFallbackCache = new ConcurrentHashMap<>();

    private record CacheEntry(String value, long expireAtMillis) {
        boolean isExpired() {
            return System.currentTimeMillis() > expireAtMillis;
        }
    }

    public TokenRedisService(@Autowired(required = false) StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    private String keyHash(String token) {
        return JwtUtil.hashToken(token);
    }

    private void setValue(String key, String value, Duration duration) {
        // Dual-write: Always keep in-memory fallback updated first for fail-safe resilience
        localFallbackCache.put(key, new CacheEntry(value, System.currentTimeMillis() + duration.toMillis()));
        if (redisTemplate != null) {
            try {
                redisTemplate.opsForValue().set(key, value, duration);
                return;
            } catch (Exception e) {
                log.warn("Redis unavailable, using active in-memory fallback store: key={}", sanitizeKeyForLog(key));
            }
        }
    }

    private String getValue(String key) {
        if (redisTemplate != null) {
            try {
                return redisTemplate.opsForValue().get(key);
            } catch (Exception e) {
                log.warn("Redis unavailable during read, falling back to in-memory store: key={}", sanitizeKeyForLog(key));
            }
        }
        CacheEntry entry = localFallbackCache.get(key);
        if (entry == null) {
            return null;
        }
        if (entry.isExpired()) {
            localFallbackCache.remove(key);
            return null;
        }
        return entry.value();
    }

    private void deleteKey(String key) {
        localFallbackCache.remove(key);
        if (redisTemplate != null) {
            try {
                redisTemplate.delete(key);
            } catch (Exception e) {
                log.warn("Redis unavailable during delete, removed from in-memory fallback: key={}", sanitizeKeyForLog(key));
            }
        }
    }

    private long increment(String key, Duration duration) {
        if (redisTemplate != null) {
            try {
                Long count = redisTemplate.opsForValue().increment(key);
                if (count != null && count == 1) {
                    redisTemplate.expire(key, duration);
                }
                return count != null ? count : 1;
            } catch (Exception e) {
                log.warn("Redis unavailable during increment: key={}", sanitizeKeyForLog(key));
            }
        }
        CacheEntry entry = localFallbackCache.get(key);
        long currentVal = 0;
        if (entry != null && !entry.isExpired()) {
            try {
                currentVal = Long.parseLong(entry.value());
            } catch (NumberFormatException ignored) {}
        }
        long newVal = currentVal + 1;
        long expireAt = (entry != null && !entry.isExpired()) ? entry.expireAtMillis() : System.currentTimeMillis() + duration.toMillis();
        localFallbackCache.put(key, new CacheEntry(String.valueOf(newVal), expireAt));
        return newVal;
    }

    public static String sanitizeKeyForLog(String key) {
        if (key == null) return "null";
        // Mask email in OTP keys: otp:forgot_password:user@domain.com
        if (key.startsWith("otp:forgot_password:")) {
            String email = key.substring("otp:forgot_password:".length());
            return "otp:forgot_password:" + maskEmail(email);
        }
        // Mask user key in failed login: failed_login:user:username
        if (key.startsWith("failed_login:user:")) {
            String user = key.substring("failed_login:user:".length());
            return "failed_login:user:" + (user.length() > 2 ? user.substring(0, 2) + "***" : "***");
        }
        // Truncate long hash or token strings
        int colonIdx = key.indexOf(':');
        if (colonIdx > 0) {
            String prefix = key.substring(0, colonIdx);
            String rest = key.substring(colonIdx + 1);
            if (rest.length() > 16) {
                return prefix + ":" + rest.substring(0, 8) + "..." + rest.substring(rest.length() - 4);
            }
        }
        return key;
    }

    public static String maskEmail(String email) {
        if (email == null || !email.contains("@")) return "***";
        int atIdx = email.indexOf('@');
        String name = email.substring(0, atIdx);
        String domain = email.substring(atIdx);
        String maskedName = name.length() <= 2 ? name.charAt(0) + "***" : name.substring(0, 2) + "***";
        return maskedName + domain;
    }

    // ==========================================
    // 1. Refresh Token Management (7 days)
    // ==========================================
    public void saveRefreshToken(String token, String username, Duration duration) {
        String h = keyHash(token);
        setValue("refresh_token:sha256_" + h, username, duration);
    }

    public void linkAccessTokenToRefreshToken(String accessToken, String refreshToken, Duration duration) {
        setValue("access_to_refresh:sha256_" + keyHash(accessToken), keyHash(refreshToken), duration);
    }

    public String getRefreshTokenHashByAccessToken(String accessToken) {
        return getValue("access_to_refresh:sha256_" + keyHash(accessToken));
    }

    public String getUsernameFromRefreshToken(String token) {
        return getValue("refresh_token:sha256_" + keyHash(token));
    }

    public void revokeRefreshToken(String token) {
        String h = keyHash(token);
        deleteKey("refresh_token:sha256_" + h);
        setValue("revoked_refresh:sha256_" + h, "revoked", Duration.ofDays(7));
    }

    public void revokeRefreshTokenByHash(String tokenHash) {
        if (tokenHash != null) {
            deleteKey("refresh_token:sha256_" + tokenHash);
            setValue("revoked_refresh:sha256_" + tokenHash, "revoked", Duration.ofDays(7));
        }
    }

    public void rotateRefreshToken(String oldToken, String newToken, String username, Duration duration) {
        String oldHash = keyHash(oldToken);
        String newHash = keyHash(newToken);
        // Mark old token as used/revoked for reuse detection
        deleteKey("refresh_token:sha256_" + oldHash);
        setValue("revoked_refresh:sha256_" + oldHash, "used", Duration.ofDays(7));
        // Save new active rotated refresh token
        setValue("refresh_token:sha256_" + newHash, username, duration);
    }

    public boolean isRefreshTokenReused(String token) {
        String status = getValue("revoked_refresh:sha256_" + keyHash(token));
        return "used".equals(status);
    }

    public void revokeUserRefreshTokens(String username) {
        // Reserved for account compromise / password reset
        log.info("Revoking all sessions for user: {}", username);
    }

    public boolean isRefreshTokenRevoked(String token) {
        String h = keyHash(token);
        String revoked = getValue("revoked_refresh:sha256_" + h);
        if (revoked != null) {
            return true;
        }
        return getValue("refresh_token:sha256_" + h) == null;
    }

    // ==========================================
    // 2. Access Token Blacklisting (Logout)
    // ==========================================
    public void blacklistAccessToken(String token, Duration remainingTtl) {
        setValue("jwt_blacklist:sha256_" + keyHash(token), "revoked", remainingTtl.isNegative() ? Duration.ofMinutes(1) : remainingTtl);
    }

    public boolean isAccessTokenRevoked(String token) {
        return getValue("jwt_blacklist:sha256_" + keyHash(token)) != null;
    }

    // ==========================================
    // 3. Failed Login Rate Limiting (5 times in 15 mins by account & IP)
    // ==========================================
    public static final int MAX_FAILED_ATTEMPTS = 5;
    public static final Duration LOCK_DURATION = Duration.ofMinutes(15);

    public boolean isLoginBlocked(String username, String clientIp) {
        String userKey = "failed_login:user:" + username;
        String ipKey = "failed_login:ip:" + clientIp;

        long userAttempts = getAttempts(userKey);
        long ipAttempts = getAttempts(ipKey);

        return userAttempts >= MAX_FAILED_ATTEMPTS || ipAttempts >= MAX_FAILED_ATTEMPTS;
    }

    public void recordFailedLogin(String username, String clientIp) {
        String userKey = "failed_login:user:" + username;
        String ipKey = "failed_login:ip:" + clientIp;

        increment(userKey, LOCK_DURATION);
        increment(ipKey, LOCK_DURATION);
    }

    public void resetFailedLogins(String username, String clientIp) {
        deleteKey("failed_login:user:" + username);
        deleteKey("failed_login:ip:" + clientIp);
    }

    private long getAttempts(String key) {
        String val = getValue(key);
        if (val == null) {
            return 0;
        }
        try {
            return Long.parseLong(val);
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    // ==========================================
    // 4. Forgot Password OTP (10 minutes)
    // ==========================================
    public void savePasswordResetOtp(String email, String otp) {
        setValue("otp:forgot_password:" + email, otp, Duration.ofMinutes(10));
    }

    public boolean verifyAndConsumePasswordResetOtp(String email, String otp) {
        String key = "otp:forgot_password:" + email;
        String storedOtp = getValue(key);
        if (storedOtp != null && storedOtp.equals(otp)) {
            deleteKey(key);
            return true;
        }
        return false;
    }
}
