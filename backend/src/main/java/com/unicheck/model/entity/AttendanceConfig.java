package com.unicheck.model.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "attendance_configs",
    uniqueConstraints = {
        @UniqueConstraint(name = "attendance_configs_config_key_key", columnNames = {"config_key"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AttendanceConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "config_key", nullable = false, length = 50, unique = true)
    private String configKey;

    @Column(name = "manual_enabled", nullable = false)
    @Builder.Default
    private Boolean manualEnabled = true;

    @Column(name = "absent_threshold_minutes", nullable = false)
    @Builder.Default
    private Integer absentThresholdMinutes = 15;

    @Column(name = "min_attendance_percentage", nullable = false)
    @Builder.Default
    private Double minAttendancePercentage = 80.0;

    @Column(name = "face_recognition_enabled", nullable = false)
    @Builder.Default
    private Boolean faceRecognitionEnabled = true;

    @Column(name = "max_attempts", nullable = false)
    @Builder.Default
    private Integer maxAttempts = 3;

    @Column(name = "wifi_location_enabled", nullable = false)
    @Builder.Default
    private Boolean wifiLocationEnabled = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (updatedAt == null) {
            updatedAt = LocalDateTime.now();
        }
        if (manualEnabled == null) {
            manualEnabled = true;
        }
        if (absentThresholdMinutes == null) {
            absentThresholdMinutes = 15;
        }
        if (minAttendancePercentage == null) {
            minAttendancePercentage = 80.0;
        }
        if (faceRecognitionEnabled == null) {
            faceRecognitionEnabled = true;
        }
        if (maxAttempts == null) {
            maxAttempts = 3;
        }
        if (wifiLocationEnabled == null) {
            wifiLocationEnabled = true;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
