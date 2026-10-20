package com.unicheck.model.dto;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class QrValidationResponse {

    private Boolean valid;
    private Long sessionId;
    private String className;
    private String roomName;
    private LocalDateTime issuedAt;
    private LocalDateTime expiresAt;
    private String message;
}
