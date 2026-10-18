package com.unicheck.model.dto;

import com.unicheck.model.enums.FaceDataStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FaceStatusResponse {

    private Long userId;
    private String studentCode;
    private String fullName;
    private FaceDataStatus faceDataStatus;
    private Boolean isRegistered;
    private LocalDateTime registeredAt;
    private String version;
    private Integer attempts;
    private LocalDateTime blockedUntil;
    private String tokenHash;
}
