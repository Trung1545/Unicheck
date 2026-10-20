package com.unicheck.service.impl;

import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.security.QrTokenClaims;
import com.unicheck.service.QrTokenService;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;

@Slf4j
@Service
public class QrTokenServiceImpl implements QrTokenService {

    @Value("${security.qr.secret:${security.jwt.secret}}")
    private String secret;

    private SecretKey key;

    public static final String ISSUER = "unicheck-backend";
    public static final String TOKEN_TYPE = "DYNAMIC_QR";

    @PostConstruct
    public void init() {
        byte[] keyBytes = secret.getBytes(StandardCharsets.UTF_8);
        if (keyBytes.length < 32) {
            byte[] padded = new byte[32];
            System.arraycopy(keyBytes, 0, padded, 0, Math.min(keyBytes.length, 32));
            keyBytes = padded;
        }
        this.key = Keys.hmacShaKeyFor(keyBytes);
    }

    @Override
    public String generateQrToken(Long sessionId, Instant issuedAt, Duration ttl, Duration rotationInterval) {
        if (sessionId == null) {
            throw new AppException(ErrorCode.INVALID_REQUEST, "Session ID không được để trống khi sinh mã QR");
        }

        Instant expiryInstant = issuedAt.plus(ttl);
        Instant rotationExpiryInstant = issuedAt.plus(rotationInterval);

        Date iatDate = Date.from(issuedAt);
        Date expDate = Date.from(expiryInstant);

        return Jwts.builder()
                .issuer(ISSUER)
                .subject("UNICHECK_DYNAMIC_QR")
                .id(UUID.randomUUID().toString())
                .claim("sessionId", sessionId)
                .claim("type", TOKEN_TYPE)
                .claim("rotExp", rotationExpiryInstant.toEpochMilli())
                .issuedAt(iatDate)
                .expiration(expDate)
                .signWith(key)
                .compact();
    }

    @Override
    public QrTokenClaims parseAndValidateToken(String qrToken) {
        if (qrToken == null || qrToken.trim().isEmpty()) {
            throw new AppException(ErrorCode.QR_TOKEN_INVALID, "Mã QR rỗng hoặc không tồn tại");
        }

        try {
            Claims payload = Jwts.parser()
                    .verifyWith(key)
                    .clockSkewSeconds(2) // 2s tolerance for clock skew
                    .build()
                    .parseSignedClaims(qrToken.trim())
                    .getPayload();

            String tokenType = payload.get("type", String.class);
            if (!TOKEN_TYPE.equals(tokenType)) {
                log.warn("Invalid token type in QR token: {}", tokenType);
                throw new AppException(ErrorCode.QR_TOKEN_INVALID, "Loại mã xác thực không phải là Dynamic QR");
            }

            Long sessionId = payload.get("sessionId", Long.class);
            if (sessionId == null) {
                throw new AppException(ErrorCode.QR_TOKEN_INVALID, "Mã QR thiếu định danh phiên");
            }

            Long rotExpMillis = payload.get("rotExp", Long.class);
            Instant rotExp = (rotExpMillis != null) ? Instant.ofEpochMilli(rotExpMillis) : payload.getExpiration().toInstant();

            return QrTokenClaims.builder()
                    .sessionId(sessionId)
                    .issuedAt(payload.getIssuedAt().toInstant())
                    .expiresAt(payload.getExpiration().toInstant())
                    .rotationExpiresAt(rotExp)
                    .nonce(payload.getId())
                    .tokenType(tokenType)
                    .build();

        } catch (ExpiredJwtException e) {
            log.info("QR token has expired: exp={}", e.getClaims().getExpiration());
            throw new AppException(ErrorCode.QR_TOKEN_EXPIRED, "Mã QR điểm danh đã hết hạn");
        } catch (JwtException | IllegalArgumentException e) {
            log.warn("QR token verification failed: reason={}", e.getMessage());
            throw new AppException(ErrorCode.QR_TOKEN_INVALID, "Mã QR không hợp lệ hoặc đã bị chỉnh sửa");
        }
    }
}
