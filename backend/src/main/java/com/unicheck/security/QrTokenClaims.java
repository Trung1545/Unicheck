package com.unicheck.security;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class QrTokenClaims {

    private Long sessionId;
    private Instant issuedAt;
    private Instant expiresAt;
    private Instant rotationExpiresAt;
    private String nonce;
    private String tokenType;
}
