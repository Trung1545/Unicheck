package com.unicheck.model.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AttendanceSessionCreateRequest {

    @NotNull(message = "ID tiết học (timetableSlotId) không được để trống")
    private Long timetableSlotId;

    @Builder.Default
    private Boolean autoOpen = false;

    @Min(value = 10, message = "Thời gian thay đổi mã QR tối thiểu 10 giây")
    @Max(value = 300, message = "Thời gian thay đổi mã QR tối đa 300 giây")
    @Builder.Default
    private Integer qrRotationIntervalSeconds = 10;

    private String note;
}
