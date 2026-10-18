package com.unicheck.model.dto;

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

    private String note;
}
