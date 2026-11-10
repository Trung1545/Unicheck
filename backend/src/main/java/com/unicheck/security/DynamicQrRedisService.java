package com.unicheck.security;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
public class DynamicQrRedisService {

    private final StringRedisTemplate redisTemplate;

    public record ActiveQrEntry(
            String qrToken,
            String otpCode,
            Instant issuedAt,
            Instant expiresAt,
            Instant rotationExpiresAt
    ) {
        public boolean isRotationExpired(Instant now) {
            return now.isAfter(rotationExpiresAt);
        }

        public boolean isTokenExpired(Instant now) {
            return now.isAfter(expiresAt);
        }

        public String serialize() {
            return qrToken + "|" + (otpCode != null ? otpCode : "") + "|"
                    + issuedAt.toEpochMilli() + "|" + expiresAt.toEpochMilli() + "|"
                    + rotationExpiresAt.toEpochMilli();
        }

        public static ActiveQrEntry deserialize(String raw) {
            if (raw == null || raw.trim().isEmpty()) {
                return null;
            }
            String[] parts = raw.split("\\|", 5);
            if (parts.length == 5) {
                String token = parts[0];
                String otp = parts[1].isEmpty() ? null : parts[1];
                return new ActiveQrEntry(
                        token,
                        otp,
                        Instant.ofEpochMilli(Long.parseLong(parts[2])),
                        Instant.ofEpochMilli(Long.parseLong(parts[3])),
                        Instant.ofEpochMilli(Long.parseLong(parts[4]))
                );
            } else if (parts.length == 4) {
                // Backward compatibility
                return new ActiveQrEntry(
                        parts[0],
                        null,
                        Instant.ofEpochMilli(Long.parseLong(parts[1])),
                        Instant.ofEpochMilli(Long.parseLong(parts[2])),
                        Instant.ofEpochMilli(Long.parseLong(parts[3]))
                );
            }
            return null;
        }
    }

    // In-memory resilient cache when Redis is unavailable
    private final Map<String, ActiveQrEntry> localFallbackCache = new ConcurrentHashMap<>();
    private final Map<String, Long> localOtpToSessionCache = new ConcurrentHashMap<>();

    // In-memory rate limiting counter fallback: studentId -> RateLimitCounter
    private record RateLimitCounter(int count, long timestamp) {}
    private final Map<Long, RateLimitCounter> localRateLimitMap = new ConcurrentHashMap<>();

    public DynamicQrRedisService(@Autowired(required = false) StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    private String buildKey(Long sessionId) {
        return "unicheck:qr:session:" + sessionId + ":active";
    }

    private String buildOtpKey(String otpCode) {
        return "unicheck:otp:code:" + otpCode;
    }

    private String buildRateLimitKey(Long studentId) {
        return "unicheck:otp:ratelimit:student:" + studentId;
    }

    public void saveActiveQr(Long sessionId, String token, Instant issuedAt, Instant expiresAt, Instant rotationExpiresAt) {
        saveActiveQr(sessionId, token, null, issuedAt, expiresAt, rotationExpiresAt);
    }

    public void saveActiveQr(Long sessionId, String token, String otpCode, Instant issuedAt, Instant expiresAt, Instant rotationExpiresAt) {
        String key = buildKey(sessionId);
        ActiveQrEntry entry = new ActiveQrEntry(token, otpCode, issuedAt, expiresAt, rotationExpiresAt);

        // Dual-write: Always update in-memory cache first
        localFallbackCache.put(key, entry);
        if (otpCode != null && !otpCode.trim().isEmpty()) {
            localOtpToSessionCache.put(otpCode.trim(), sessionId);
        }

        if (redisTemplate != null) {
            try {
                Duration ttl = Duration.between(Instant.now(), expiresAt);
                if (ttl.isNegative() || ttl.isZero()) {
                    ttl = Duration.ofSeconds(15);
                }
                redisTemplate.opsForValue().set(key, entry.serialize(), ttl);

                if (otpCode != null && !otpCode.trim().isEmpty()) {
                    redisTemplate.opsForValue().set(buildOtpKey(otpCode.trim()), sessionId.toString(), ttl);
                }
            } catch (Exception e) {
                log.warn("Redis unavailable during QR/OTP cache write, relying on in-memory store: sessionId={}", sessionId);
            }
        }
    }

    public ActiveQrEntry getActiveQr(Long sessionId) {
        String key = buildKey(sessionId);
        Instant now = Instant.now();

        if (redisTemplate != null) {
            try {
                String raw = redisTemplate.opsForValue().get(key);
                ActiveQrEntry entry = ActiveQrEntry.deserialize(raw);
                if (entry != null && !entry.isTokenExpired(now)) {
                    return entry;
                }
            } catch (Exception e) {
                log.warn("Redis unavailable during QR cache read, checking in-memory store: sessionId={}", sessionId);
            }
        }

        ActiveQrEntry localEntry = localFallbackCache.get(key);
        if (localEntry != null) {
            if (localEntry.isTokenExpired(now)) {
                localFallbackCache.remove(key);
                if (localEntry.otpCode() != null) {
                    localOtpToSessionCache.remove(localEntry.otpCode());
                }
                return null;
            }
            return localEntry;
        }

        return null;
    }

    public Long getSessionIdByOtp(String otpCode) {
        if (otpCode == null || otpCode.trim().isEmpty()) {
            return null;
        }
        String cleanOtp = otpCode.trim();

        if (redisTemplate != null) {
            try {
                String val = redisTemplate.opsForValue().get(buildOtpKey(cleanOtp));
                if (val != null && !val.trim().isEmpty()) {
                    return Long.parseLong(val.trim());
                }
            } catch (Exception e) {
                log.warn("Redis unavailable during OTP lookup: {}", e.getMessage());
            }
        }

        return localOtpToSessionCache.get(cleanOtp);
    }

    public void invalidate(Long sessionId) {
        String key = buildKey(sessionId);
        ActiveQrEntry existing = localFallbackCache.remove(key);
        if (existing != null && existing.otpCode() != null) {
            localOtpToSessionCache.remove(existing.otpCode());
        }

        if (redisTemplate != null) {
            try {
                if (existing != null && existing.otpCode() != null) {
                    redisTemplate.delete(buildOtpKey(existing.otpCode()));
                }
                redisTemplate.delete(key);
            } catch (Exception e) {
                log.warn("Redis unavailable during QR invalidation: sessionId={}", sessionId);
            }
        }
        log.info("Invalidated dynamic QR and OTP cache for session #{}", sessionId);
    }

    // Rate Limiting for OTP Validation (Max 5 attempts per 60 seconds)
    public int recordOtpFailure(Long studentId) {
        if (studentId == null) return 1;

        if (redisTemplate != null) {
            try {
                String rateKey = buildRateLimitKey(studentId);
                Long count = redisTemplate.opsForValue().increment(rateKey);
                if (count != null && count == 1) {
                    redisTemplate.expire(rateKey, Duration.ofSeconds(60));
                }
                return count != null ? count.intValue() : 1;
            } catch (Exception e) {
                log.warn("Redis error recording OTP rate limit, using fallback: {}", e.getMessage());
            }
        }

        long now = System.currentTimeMillis();
        RateLimitCounter updated = localRateLimitMap.compute(studentId, (k, v) -> {
            if (v == null || now - v.timestamp() > 60_000) {
                return new RateLimitCounter(1, now);
            }
            return new RateLimitCounter(v.count() + 1, v.timestamp());
        });
        return updated.count();
    }

    public void clearOtpFailure(Long studentId) {
        if (studentId == null) return;

        if (redisTemplate != null) {
            try {
                redisTemplate.delete(buildRateLimitKey(studentId));
            } catch (Exception e) {
                log.warn("Redis error clearing OTP rate limit: {}", e.getMessage());
            }
        }
        localRateLimitMap.remove(studentId);
    }

    public boolean isOtpRateLimited(Long studentId) {
        if (studentId == null) return false;

        if (redisTemplate != null) {
            try {
                String val = redisTemplate.opsForValue().get(buildRateLimitKey(studentId));
                if (val != null) {
                    return Integer.parseInt(val.trim()) >= 5;
                }
                return false;
            } catch (Exception e) {
                log.warn("Redis error checking OTP rate limit: {}", e.getMessage());
            }
        }

        RateLimitCounter counter = localRateLimitMap.get(studentId);
        if (counter != null && System.currentTimeMillis() - counter.timestamp() <= 60_000) {
            return counter.count() >= 5;
        }
        return false;
    }
}
