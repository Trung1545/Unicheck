package com.unicheck.model.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceRecheckCreateRequest {

    @NotBlank(message = "Lý do yêu cầu điểm danh lại không được để trống")
    @Size(min = 5, max = 500, message = "Lý do phải từ 5 đến 500 ký tự")
    private String reason;

    @Min(value = 1, message = "Thời hạn tối thiểu là 1 phút")
    @Max(value = 120, message = "Thời hạn tối đa là 120 phút")
    @Builder.Default
    private Integer expirationMinutes = 15;
}
