package com.unicheck.model.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AttendanceSessionOpenRequest {

    @Min(value = 10, message = "Thời gian thay đổi mã QR tối thiểu 10 giây")
    @Max(value = 300, message = "Thời gian thay đổi mã QR tối đa 300 giây")
    @Builder.Default
    private Integer qrRotationIntervalSeconds = 10;
}
