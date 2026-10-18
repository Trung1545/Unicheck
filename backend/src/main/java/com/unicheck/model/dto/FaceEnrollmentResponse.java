package com.unicheck.model.dto;

import com.unicheck.model.enums.FaceDataStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FaceEnrollmentResponse {

    private Boolean success;
    private FaceDataStatus status;
    private LocalDateTime registeredAt;
    private String version;
    private String modelName;
    private Integer embeddingDimension;
    private String tokenHash;
    private String message;
    private String studentName;
    private String studentCode;
}
