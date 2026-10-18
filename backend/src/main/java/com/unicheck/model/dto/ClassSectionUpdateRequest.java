package com.unicheck.model.dto;

import com.unicheck.model.enums.ClassSectionStatus;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClassSectionUpdateRequest {

    private Long lecturerId;

    @NotNull(message = "Sĩ số tối đa không được để trống")
    @Min(value = 1, message = "Sĩ số tối đa phải lớn hơn 0")
    private Integer maxStudents;

    private Integer numberOfSlots;

    @NotNull(message = "Trạng thái lớp không được để trống")
    private ClassSectionStatus status;
}
