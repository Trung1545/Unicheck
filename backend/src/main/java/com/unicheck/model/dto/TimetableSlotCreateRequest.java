package com.unicheck.model.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.*;

import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TimetableSlotCreateRequest {

    @NotBlank(message = "Mã lớp học phần không được để trống")
    @Size(max = 50, message = "Mã lớp học phần tối đa 50 ký tự")
    private String className;

    private Long roomId;

    private Long slotTypeId;

    @NotNull(message = "Ngày học không được để trống")
    private LocalDate date;

    @NotNull(message = "Tiết bắt đầu không được để trống")
    @Min(value = 1, message = "Tiết học phải từ 1 đến 12")
    @Max(value = 12, message = "Tiết học phải từ 1 đến 12")
    private Integer slotNumber;

    @Min(value = 1, message = "Tiết kết thúc phải từ 1 đến 12")
    @Max(value = 12, message = "Tiết kết thúc phải từ 1 đến 12")
    private Integer endSlotNumber;

    @Size(max = 500, message = "Ghi chú tối đa 500 ký tự")
    private String note;

    @Builder.Default
    private Boolean recurring = false;

    private LocalDate recurringUntil;
}
