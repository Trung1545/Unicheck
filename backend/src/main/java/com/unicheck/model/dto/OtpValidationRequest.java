package com.unicheck.model.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.*;

/**
 * DTO yêu cầu xác thực mã OTP 6 chữ số từ Flutter Mobile.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OtpValidationRequest {

    @NotBlank(message = "Mã OTP không được để trống")
    @Pattern(regexp = "^[0-9]{6}$", message = "Mã OTP phải gồm đúng 6 chữ số")
    private String otpCode;

    private Long sessionId;
}
