package com.unicheck.model.dto;

import com.unicheck.model.enums.SemesterStatus;
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
public class SemesterUpdateRequest {

    @NotBlank(message = "Tên học kỳ không được để trống")
    @Size(max = 100, message = "Tên học kỳ tối đa 100 ký tự")
    private String name;

    @NotNull(message = "Ngày bắt đầu học kỳ không được để trống")
    private LocalDate startDate;

    @NotNull(message = "Ngày kết thúc học kỳ không được để trống")
    private LocalDate endDate;

    private SemesterStatus status;

    private String description;

    private Integer maxSlotPerDay;

    private Integer slotPerSubjectPerWeek;

    private Integer slotDuration;

    private Boolean isPublished;
}
