package com.unicheck.model.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(
    name = "student_profiles",
    indexes = {
        @Index(name = "idx_student_profiles_user_id", columnList = "user_id")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StudentProfile {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "course", length = 20)
    private String course;

    @Column(name = "gpa")
    @Builder.Default
    private Double gpa = 0.0;

    @Column(name = "major_id")
    private Long majorId;

    @Column(name = "specialization_id")
    private Long specializationId;

    @Column(name = "sub_specialization_id")
    private Long subSpecializationId;
}
