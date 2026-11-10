package com.unicheck.model.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceManualAdjustRequest {

    @NotBlank(message = "Trạng thái mới không được để trống")
    @Pattern(regexp = "^(PRESENT|LATE|ABSENT)$", message = "Trạng thái chỉ được là PRESENT, LATE hoặc ABSENT")
    private String newStatus;

    @NotBlank(message = "Lý do điều chỉnh không được để trống")
    @Size(min = 5, max = 500, message = "Lý do điều chỉnh phải từ 5 đến 500 ký tự")
    private String reason;
}
