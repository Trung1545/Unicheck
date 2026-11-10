package com.unicheck.model.entity;

import com.unicheck.model.enums.AttendanceSessionStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "attendance_sessions",
    indexes = {
        @Index(name = "idx_attendance_sessions_status", columnList = "status"),
        @Index(name = "idx_attendance_sessions_lecturer_id", columnList = "lecturer_id"),
        @Index(name = "idx_attendance_sessions_created_at", columnList = "created_at")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AttendanceSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "timetable_slot_id", nullable = false)
    private TimetableSlot timetableSlot;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lecturer_id")
    private User lecturer;

    @Column(name = "opened_at")
    private LocalDateTime openedAt;

    @Column(name = "closed_at")
    private LocalDateTime closedAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private AttendanceSessionStatus status = AttendanceSessionStatus.CREATED;

    @Column(name = "qr_rotation_interval_seconds")
    @Builder.Default
    private Integer qrRotationIntervalSeconds = 10;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (status == null) {
            status = AttendanceSessionStatus.CREATED;
        }
        if (qrRotationIntervalSeconds == null) {
            qrRotationIntervalSeconds = 10;
        }
    }
}
