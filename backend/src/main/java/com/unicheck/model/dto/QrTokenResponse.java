package com.unicheck.model.dto;

import com.unicheck.model.enums.AttendanceSessionStatus;
import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class QrTokenResponse {

    private Long sessionId;
    private String qrToken;
    private String otpCode;
    private LocalDateTime issuedAt;
    private LocalDateTime expiresAt;
    private LocalDateTime rotationExpiresAt;
    private Integer rotationIntervalSeconds;
    private Long remainingSeconds;
    private AttendanceSessionStatus status;
    private String mode;
}
