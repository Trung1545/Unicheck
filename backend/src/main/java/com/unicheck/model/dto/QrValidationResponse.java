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
    private Long roomId;
    private String roomCode;
    private Boolean wifiSimulationAllowed;
    private String simulatedSsid;
    private String simulatedBssid;
    private String verificationTicket;
    private LocalDateTime ticketExpiresAt;
    private LocalDateTime issuedAt;
    private LocalDateTime expiresAt;
    private String message;
}
