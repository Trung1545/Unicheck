package com.unicheck.model.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class QrValidationRequest {

    @NotBlank(message = "QR token không được để trống")
    private String qrToken;

    @NotNull(message = "Session ID không được để trống")
    private Long sessionId;
}
