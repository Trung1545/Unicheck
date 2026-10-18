package com.unicheck.model.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(
    name = "lecturer_profiles",
    indexes = {
        @Index(name = "idx_lecturer_profiles_user_id", columnList = "user_id")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LecturerProfile {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "department", length = 100)
    private String department;

    @Column(name = "expertise", length = 100)
    private String expertise;

    @Column(name = "bio", columnDefinition = "TEXT")
    private String bio;
}
