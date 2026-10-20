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
            return qrToken + "|" + issuedAt.toEpochMilli() + "|" + expiresAt.toEpochMilli() + "|" + rotationExpiresAt.toEpochMilli();
        }

        public static ActiveQrEntry deserialize(String raw) {
            if (raw == null || raw.trim().isEmpty()) {
                return null;
            }
            String[] parts = raw.split("\\|", 4);
            if (parts.length < 4) {
                return null;
            }
            return new ActiveQrEntry(
                    parts[0],
                    Instant.ofEpochMilli(Long.parseLong(parts[1])),
                    Instant.ofEpochMilli(Long.parseLong(parts[2])),
                    Instant.ofEpochMilli(Long.parseLong(parts[3]))
            );
        }
    }

    // In-memory resilient cache when Redis is unavailable
    private final Map<String, ActiveQrEntry> localFallbackCache = new ConcurrentHashMap<>();

    public DynamicQrRedisService(@Autowired(required = false) StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    private String buildKey(Long sessionId) {
        return "unicheck:qr:session:" + sessionId + ":active";
    }

    public void saveActiveQr(Long sessionId, String token, Instant issuedAt, Instant expiresAt, Instant rotationExpiresAt) {
        String key = buildKey(sessionId);
        ActiveQrEntry entry = new ActiveQrEntry(token, issuedAt, expiresAt, rotationExpiresAt);

        // Dual-write: Always update in-memory cache first
        localFallbackCache.put(key, entry);

        if (redisTemplate != null) {
            try {
                Duration ttl = Duration.between(Instant.now(), expiresAt);
                if (ttl.isNegative() || ttl.isZero()) {
                    ttl = Duration.ofSeconds(15);
                }
                redisTemplate.opsForValue().set(key, entry.serialize(), ttl);
            } catch (Exception e) {
                log.warn("Redis unavailable during QR cache write, relying on in-memory store: sessionId={}", sessionId);
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
                return null;
            }
            return localEntry;
        }

        return null;
    }

    public void invalidate(Long sessionId) {
        String key = buildKey(sessionId);
        localFallbackCache.remove(key);

        if (redisTemplate != null) {
            try {
                redisTemplate.delete(key);
            } catch (Exception e) {
                log.warn("Redis unavailable during QR invalidation: sessionId={}", sessionId);
            }
        }
        log.info("Invalidated dynamic QR cache for session #{}", sessionId);
    }
}
