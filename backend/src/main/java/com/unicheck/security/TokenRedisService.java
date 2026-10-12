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

    private void setValue(String key, String value, Duration duration) {
        if (redisTemplate != null) {
            try {
                redisTemplate.opsForValue().set(key, value, duration);
                return;
            } catch (Exception e) {
                log.warn("Redis unavailable, falling back to in-memory store for key {}: {}", key, e.getMessage());
            }
        }
        localFallbackCache.put(key, new CacheEntry(value, System.currentTimeMillis() + duration.toMillis()));
    }

    private String getValue(String key) {
        if (redisTemplate != null) {
            try {
                return redisTemplate.opsForValue().get(key);
            } catch (Exception e) {
                log.warn("Redis unavailable, falling back to in-memory store for key {}: {}", key, e.getMessage());
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
        if (redisTemplate != null) {
            try {
                redisTemplate.delete(key);
            } catch (Exception e) {
                log.warn("Redis unavailable during delete for key {}: {}", key, e.getMessage());
            }
        }
        localFallbackCache.remove(key);
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
                log.warn("Redis unavailable during increment for key {}: {}", key, e.getMessage());
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

    // ==========================================
    // 1. Refresh Token Management (7 days)
    // ==========================================
    public void saveRefreshToken(String token, String username, Duration duration) {
        setValue("refresh_token:" + token, username, duration);
        setValue("user_refresh:" + username, token, duration);
    }

    public void linkAccessTokenToRefreshToken(String accessToken, String refreshToken, Duration duration) {
        setValue("access_to_refresh:" + accessToken, refreshToken, duration);
    }

    public String getRefreshTokenByAccessToken(String accessToken) {
        return getValue("access_to_refresh:" + accessToken);
    }

    public String getUsernameFromRefreshToken(String token) {
        return getValue("refresh_token:" + token);
    }

    public void revokeRefreshToken(String token) {
        deleteKey("refresh_token:" + token);
        setValue("revoked_refresh:" + token, "revoked", Duration.ofDays(7));
    }

    public void revokeUserRefreshTokens(String username) {
        String token = getValue("user_refresh:" + username);
        if (token != null) {
            revokeRefreshToken(token);
            deleteKey("user_refresh:" + username);
        }
    }

    public boolean isRefreshTokenRevoked(String token) {
        String revoked = getValue("revoked_refresh:" + token);
        return revoked != null || getValue("refresh_token:" + token) == null;
    }

    // ==========================================
    // 2. Access Token Blacklisting (Logout)
    // ==========================================
    public void blacklistAccessToken(String token, Duration remainingTtl) {
        setValue("jwt_blacklist:" + token, "revoked", remainingTtl.isNegative() ? Duration.ofMinutes(1) : remainingTtl);
    }

    public boolean isAccessTokenRevoked(String token) {
        return getValue("jwt_blacklist:" + token) != null;
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
