package com.unicheck.security;

import com.unicheck.model.entity.User;
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.UUID;

@Slf4j
@Component
public class JwtUtil {

    @Value("${security.jwt.secret:4c9a58b29f7e1b3d5c7a9e0f2b4d6e8a0c2e4f6a8b0d2e4f6a8b0d2e4f6a8b0d}")
    private String secret;

    // 15 minutes = 900,000 ms (as required by prompt)
    @Value("${security.jwt.expiration-ms:900000}")
    private Long accessTokenExpirationMs;

    // 7 days = 604,800,000 ms (as required by prompt)
    @Value("${security.jwt.refresh-expiration-ms:604800000}")
    private Long refreshTokenExpirationMs;

    private SecretKey key;

    @PostConstruct
    public void init() {
        byte[] keyBytes = secret.getBytes(StandardCharsets.UTF_8);
        if (keyBytes.length < 32) {
            // Ensure minimum key length of 32 bytes for HMAC-SHA256
            byte[] padded = new byte[32];
            System.arraycopy(keyBytes, 0, padded, 0, Math.min(keyBytes.length, 32));
            keyBytes = padded;
        }
        this.key = Keys.hmacShaKeyFor(keyBytes);
    }

    public String generateAccessToken(User user) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + accessTokenExpirationMs);

        return Jwts.builder()
                .subject(user.getUsername())
                .claim("userId", user.getId())
                .claim("role", user.getRole() != null ? user.getRole().name() : "STUDENT")
                .claim("email", user.getEmail())
                .claim("type", "access")
                .id(UUID.randomUUID().toString())
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(key)
                .compact();
    }

    public String generateRefreshToken(User user) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + refreshTokenExpirationMs);

        return Jwts.builder()
                .subject(user.getUsername())
                .claim("userId", user.getId())
                .claim("type", "refresh")
                .id(UUID.randomUUID().toString())
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(key)
                .compact();
    }

    // Helper for testing token expiration
    public String generateTokenWithCustomExpiration(User user, long expirationMs) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + expirationMs);

        return Jwts.builder()
                .subject(user.getUsername())
                .claim("userId", user.getId())
                .claim("role", user.getRole() != null ? user.getRole().name() : "STUDENT")
                .claim("email", user.getEmail())
                .claim("type", "access")
                .id(UUID.randomUUID().toString())
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(key)
                .compact();
    }

    public Claims getClaims(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public String extractUsername(String token) {
        return getClaims(token).getSubject();
    }

    public String extractRole(String token) {
        Object role = getClaims(token).get("role");
        return role != null ? role.toString() : null;
    }

    public boolean validateToken(String token) {
        try {
            Claims claims = getClaims(token);
            return claims.getExpiration().after(new Date());
        } catch (JwtException | IllegalArgumentException e) {
            log.debug("Invalid JWT token: {}", e.getMessage());
            return false;
        }
    }

    public boolean isTokenExpired(String token) {
        try {
            Claims claims = getClaims(token);
            return claims.getExpiration().before(new Date());
        } catch (ExpiredJwtException e) {
            return true;
        } catch (Exception e) {
            return true;
        }
    }

    public long getRemainingExpirationMs(String token) {
        try {
            Claims claims = getClaims(token);
            long diff = claims.getExpiration().getTime() - System.currentTimeMillis();
            return Math.max(0, diff);
        } catch (Exception e) {
            return 0;
        }
    }

    public Long getAccessTokenExpirationMs() {
        return accessTokenExpirationMs;
    }

    public Long getRefreshTokenExpirationMs() {
        return refreshTokenExpirationMs;
    }
}
