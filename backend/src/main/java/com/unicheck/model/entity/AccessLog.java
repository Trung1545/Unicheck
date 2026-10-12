package com.unicheck.model.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "access_logs",
    indexes = {
        @Index(name = "idx_access_logs_user_id", columnList = "user_id")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AccessLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "location", nullable = false, length = 100)
    private String location;

    @Column(name = "status", nullable = false, length = 50)
    private String status;

    @Column(name = "access_time", nullable = false)
    @Builder.Default
    private LocalDateTime accessTime = LocalDateTime.now();

    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    @Column(name = "user_agent", length = 255)
    private String userAgent;

    @PrePersist
    protected void onCreate() {
        if (accessTime == null) {
            accessTime = LocalDateTime.now();
        }
    }
}
