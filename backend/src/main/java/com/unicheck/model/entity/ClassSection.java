package com.unicheck.model.entity;

import com.unicheck.model.enums.ClassSectionStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "class_sections",
    indexes = {
        @Index(name = "idx_class_sections_course_id", columnList = "course_id"),
        @Index(name = "idx_class_sections_semester_id", columnList = "semester_id"),
        @Index(name = "idx_class_sections_lecturer_id", columnList = "lecturer_id")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClassSection {

    @Id
    @Column(name = "class_name", length = 50, nullable = false)
    private String className;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "course_id", nullable = false)
    private Course course;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "semester_id", nullable = false)
    private Semester semester;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lecturer_id")
    private User lecturer;

    @Column(name = "number_of_slots", nullable = false)
    private Integer numberOfSlots;

    @Column(name = "max_students", nullable = false)
    private Integer maxStudents;

    @Column(name = "current_enrollment", nullable = false)
    @Builder.Default
    private Integer currentEnrollment = 0;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private ClassSectionStatus status = ClassSectionStatus.OPEN;

    @Column(name = "grades_submitted", nullable = false)
    @Builder.Default
    private Boolean gradesSubmitted = false;

    @Column(name = "grades_submitted_at")
    private LocalDateTime gradesSubmittedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "grades_submitted_by")
    private User gradesSubmittedBy;

    @Column(name = "grades_published", nullable = false)
    @Builder.Default
    private Boolean gradesPublished = false;

    @Column(name = "grades_published_at")
    private LocalDateTime gradesPublishedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "grades_published_by")
    private User gradesPublishedBy;

    @Column(name = "resit_grades_published", nullable = false)
    @Builder.Default
    private Boolean resitGradesPublished = false;

    @Column(name = "resit_grades_published_at")
    private LocalDateTime resitGradesPublishedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resit_grades_published_by")
    private User resitGradesPublishedBy;

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
        if (currentEnrollment == null) {
            currentEnrollment = 0;
        }
        if (gradesSubmitted == null) {
            gradesSubmitted = false;
        }
        if (gradesPublished == null) {
            gradesPublished = false;
        }
        if (resitGradesPublished == null) {
            resitGradesPublished = false;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
