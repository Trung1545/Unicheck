package com.unicheck.model.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AttendanceCheckInRequest {

    private Long sessionId;

    @NotBlank(message = "Mã QR điểm danh không được để trống")
    private String qrToken;

    @NotBlank(message = "Ảnh quét khuôn mặt không được để trống")
    private String faceImageBase64;

    private String wifiBssid;

    private Integer wifiRssi;

    private Double latitude;

    private Double longitude;

    private String deviceInfo;
}
