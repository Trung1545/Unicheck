package com.unicheck.model.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AttendanceConfigDto {

    private Long id;

    private String configKey;

    @NotNull(message = "manualEnabled không được để trống")
    private Boolean manualEnabled;

    @NotNull(message = "absentThresholdMinutes không được để trống")
    @Min(value = 1, message = "absentThresholdMinutes tối thiểu là 1 phút")
    @Max(value = 180, message = "absentThresholdMinutes tối đa là 180 phút")
    private Integer absentThresholdMinutes;

    @NotNull(message = "minAttendancePercentage không được để trống")
    @Min(value = 0, message = "minAttendancePercentage tối thiểu là 0%")
    @Max(value = 100, message = "minAttendancePercentage tối đa là 100%")
    private Double minAttendancePercentage;

    @NotNull(message = "faceRecognitionEnabled không được để trống")
    private Boolean faceRecognitionEnabled;

    @NotNull(message = "maxAttempts không được để trống")
    @Min(value = 1, message = "maxAttempts tối thiểu là 1")
    @Max(value = 10, message = "maxAttempts tối đa là 10")
    private Integer maxAttempts;

    @NotNull(message = "wifiLocationEnabled không được để trống")
    private Boolean wifiLocationEnabled;
}
