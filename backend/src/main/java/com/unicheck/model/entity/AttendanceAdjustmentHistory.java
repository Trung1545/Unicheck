package com.unicheck.model.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "attendance_adjustment_histories",
    indexes = {
        @Index(name = "idx_adj_history_session", columnList = "session_id"),
        @Index(name = "idx_adj_history_student", columnList = "student_id"),
        @Index(name = "idx_adj_history_modified_at", columnList = "modified_at")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AttendanceAdjustmentHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    private AttendanceSession session;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private User student;

    @Column(name = "old_status", length = 20)
    private String oldStatus;

    @Column(name = "new_status", nullable = false, length = 20)
    private String newStatus;

    @Column(name = "reason", nullable = false, length = 500)
    private String reason;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "modified_by", nullable = false)
    private User modifiedBy;

    @Column(name = "modified_at", nullable = false)
    @Builder.Default
    private LocalDateTime modifiedAt = LocalDateTime.now();

    @Column(name = "modification_type", nullable = false, length = 50)
    private String modificationType;

    @PrePersist
    protected void onCreate() {
        if (modifiedAt == null) {
            modifiedAt = LocalDateTime.now();
        }
    }
}
