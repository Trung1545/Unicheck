package com.unicheck.model.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "attendance_recheck_requests",
    indexes = {
        @Index(name = "idx_recheck_session", columnList = "session_id"),
        @Index(name = "idx_recheck_student", columnList = "student_id"),
        @Index(name = "idx_recheck_status", columnList = "status")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AttendanceRecheckRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    private AttendanceSession session;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private User student;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "requested_by", nullable = false)
    private User requestedBy;

    @Column(name = "reason", nullable = false, length = 500)
    private String reason;

    @Column(name = "status", nullable = false, length = 30)
    @Builder.Default
    private String status = "PENDING";

    @Column(name = "requested_at", nullable = false)
    @Builder.Default
    private LocalDateTime requestedAt = LocalDateTime.now();

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @PrePersist
    protected void onCreate() {
        if (requestedAt == null) {
            requestedAt = LocalDateTime.now();
        }
        if (status == null) {
            status = "PENDING";
        }
    }

    public boolean isExpired() {
        return expiresAt != null && LocalDateTime.now().isAfter(expiresAt);
    }

    public boolean isPending() {
        return "PENDING".equalsIgnoreCase(status) && !isExpired();
    }
}
