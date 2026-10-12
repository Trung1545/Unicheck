package com.unicheck.model.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(
    name = "user_sessions",
    indexes = {
        @Index(name = "idx_user_sessions_user_id", columnList = "user_id"),
        @Index(name = "idx_user_sessions_token", columnList = "token")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "token", length = 500)
    private String token;

    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    @Column(name = "province", length = 100)
    private String province;

    @Column(name = "city", length = 100)
    private String city;

    @Column(name = "latitude", precision = 10, scale = 8)
    private BigDecimal latitude;

    @Column(name = "longitude", precision = 11, scale = 8)
    private BigDecimal longitude;

    @Column(name = "login_time", nullable = false)
    @Builder.Default
    private LocalDateTime loginTime = LocalDateTime.now();

    @Column(name = "last_activity_time", nullable = false)
    @Builder.Default
    private LocalDateTime lastActivityTime = LocalDateTime.now();

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "user_agent", length = 500)
    private String userAgent;
}
