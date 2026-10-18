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
public class SemesterCreateRequest {

    @NotBlank(message = "Mã học kỳ không được để trống")
    @Size(max = 20, message = "Mã học kỳ tối đa 20 ký tự")
    private String code;

    @NotBlank(message = "Tên học kỳ không được để trống")
    @Size(max = 100, message = "Tên học kỳ tối đa 100 ký tự")
    private String name;

    @NotNull(message = "Ngày bắt đầu học kỳ không được để trống")
    private LocalDate startDate;

    @NotNull(message = "Ngày kết thúc học kỳ không được để trống")
    private LocalDate endDate;

    @Builder.Default
    private SemesterStatus status = SemesterStatus.ACTIVE;

    private String description;

    @Builder.Default
    private Integer maxSlotPerDay = 6;

    @Builder.Default
    private Integer slotPerSubjectPerWeek = 2;

    @Builder.Default
    private Integer slotDuration = 50;

    @Builder.Default
    private Boolean isPublished = false;
}
