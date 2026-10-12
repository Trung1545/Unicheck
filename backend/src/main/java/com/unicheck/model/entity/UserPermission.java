package com.unicheck.model.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "user_permissions",
    indexes = {
        @Index(name = "idx_user_permissions_user_id", columnList = "user_id"),
        @Index(name = "idx_user_permissions_permission", columnList = "permission")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserPermission {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "permission", nullable = false, length = 50)
    private String permission;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "granted_by")
    private User grantedBy;

    @Column(name = "granted_at", nullable = false)
    @Builder.Default
    private LocalDateTime grantedAt = LocalDateTime.now();

    @PrePersist
    protected void onCreate() {
        if (grantedAt == null) {
            grantedAt = LocalDateTime.now();
        }
    }
}
