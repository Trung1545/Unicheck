package com.unicheck.model.dto;

import com.unicheck.model.enums.ClassSectionStatus;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClassSectionCreateRequest {

    @NotBlank(message = "Mã lớp học phần không được để trống")
    @Size(max = 50, message = "Mã lớp học phần tối đa 50 ký tự")
    @Pattern(regexp = "^[A-Za-z0-9_.-]+$", message = "Mã lớp học phần chỉ chứa chữ, số, dấu gạch ngang, gạch dưới hoặc chấm")
    private String className;

    @NotNull(message = "Học phần không được để trống")
    private Long courseId;

    @NotNull(message = "Học kỳ không được để trống")
    private Long semesterId;

    private Long lecturerId;

    @NotNull(message = "Sĩ số tối đa không được để trống")
    @Min(value = 1, message = "Sĩ số tối đa phải lớn hơn 0")
    @Builder.Default
    private Integer maxStudents = 70;

    private Integer numberOfSlots;

    @Builder.Default
    private ClassSectionStatus status = ClassSectionStatus.OPEN;
}
