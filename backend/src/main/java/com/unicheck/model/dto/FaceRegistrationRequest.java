package com.unicheck.model.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FaceRegistrationRequest {

    @NotBlank(message = "Ảnh khuôn mặt không được để trống")
    private String imageBase64;

    private List<FaceSampleDto> samples;

    @Builder.Default
    private Boolean isReEnrollment = false;
}
