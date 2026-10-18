package com.unicheck.model.dto;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TimetableConflictCheckRequest {

    private Long excludeSlotId;

    private String className;

    private Long lecturerId;

    private Long roomId;

    @NotNull(message = "Ngày kiểm tra không được để trống")
    private LocalDate date;

    @NotNull(message = "Tiết bắt đầu không được để trống")
    private Integer slotNumber;

    private Integer endSlotNumber;
}
