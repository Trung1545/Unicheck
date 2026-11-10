package com.unicheck.model.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "attendance_verification_attempts",
    indexes = {
        @Index(name = "idx_attempt_recheck_id", columnList = "recheck_request_id"),
        @Index(name = "idx_attempt_student_id", columnList = "student_id")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AttendanceVerificationAttempt {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recheck_request_id")
    private AttendanceRecheckRequest recheckRequest;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private User student;

    @Column(name = "attempted_at", nullable = false)
    @Builder.Default
    private LocalDateTime attemptedAt = LocalDateTime.now();

    @Column(name = "qr_result", nullable = false, length = 20)
    private String qrResult;

    @Column(name = "wifi_result", nullable = false, length = 20)
    private String wifiResult;

    @Column(name = "face_match_result", nullable = false, length = 20)
    private String faceMatchResult;

    @Column(name = "liveness_result", nullable = false, length = 20)
    private String livenessResult;

    @Column(name = "verification_status", nullable = false, length = 20)
    private String verificationStatus;

    @Column(name = "failure_code", length = 50)
    private String failureCode;

    @Column(name = "failure_reason", length = 500)
    private String failureReason;

    @PrePersist
    protected void onCreate() {
        if (attemptedAt == null) {
            attemptedAt = LocalDateTime.now();
        }
    }
}
