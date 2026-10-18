package com.unicheck.model.dto;

import com.unicheck.model.enums.CourseStatus;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.*;

import java.util.Set;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CourseCreateRequest {

    @NotBlank(message = "Mã học phần không được để trống")
    @Size(max = 20, message = "Mã học phần tối đa 20 ký tự")
    private String code;

    @NotBlank(message = "Tên học phần không được để trống")
    @Size(max = 200, message = "Tên học phần tối đa 200 ký tự")
    private String name;

    private String description;

    @NotNull(message = "Số tín chỉ không được để trống")
    @Min(value = 1, message = "Số tín chỉ tối thiểu là 1")
    @Max(value = 20, message = "Số tín chỉ tối đa là 20")
    private Integer credits;

    @NotNull(message = "Số tiết học không được để trống")
    @Min(value = 1, message = "Số tiết học tối thiểu là 1")
    private Integer numberOfSlots;

    @Builder.Default
    private CourseStatus status = CourseStatus.ACTIVE;

    @Builder.Default
    private Boolean isCalculatedInGpa = true;

    private Set<Long> prerequisiteIds;
}
