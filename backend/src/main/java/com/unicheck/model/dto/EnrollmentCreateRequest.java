package com.unicheck.model.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EnrollmentCreateRequest {

    @NotBlank(message = "Mã lớp học phần không được để trống")
    private String className;

    @NotNull(message = "ID sinh viên không được để trống")
    private Long studentId;
}
