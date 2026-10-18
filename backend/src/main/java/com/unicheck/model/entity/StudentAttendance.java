package com.unicheck.model.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "student_attendances",
    indexes = {
        @Index(name = "idx_student_attendances_session_id", columnList = "session_id"),
        @Index(name = "idx_student_attendances_student_id", columnList = "student_id")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StudentAttendance {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    private AttendanceSession session;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private User student;

    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private String status = "ABSENT";

    @Column(name = "method", length = 20)
    private String method;

    @Column(name = "check_in_time")
    private LocalDateTime checkInTime;

    @Column(name = "face_confidence")
    private Double faceConfidence;

    @Column(name = "wifi_bssid", length = 17)
    private String wifiBssid;

    @Column(name = "wifi_rssi")
    private Integer wifiRssi;

    @Column(name = "note", length = 500)
    private String note;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "updated_by_id")
    private User updatedBy;

    @Column(name = "attempt_count")
    @Builder.Default
    private Integer attemptCount = 0;

    @Column(name = "failure_reason", length = 500)
    private String failureReason;

    @Column(name = "requires_manual_verify")
    @Builder.Default
    private Boolean requiresManualVerify = false;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "manual_verified_by")
    private User manualVerifiedBy;

    @Column(name = "manual_verified_at")
    private LocalDateTime manualVerifiedAt;

    @Column(name = "captured_face_url", length = 500)
    private String capturedFaceUrl;

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
        if (status == null) {
            status = "ABSENT";
        }
        if (attemptCount == null) {
            attemptCount = 0;
        }
        if (requiresManualVerify == null) {
            requiresManualVerify = false;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
