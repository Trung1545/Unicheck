package com.unicheck.model.entity;

import com.unicheck.model.enums.WifiApStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(
    name = "wifi_access_points",
    indexes = {
        @Index(name = "idx_wifi_ap_bssid", columnList = "bssid"),
        @Index(name = "idx_wifi_ap_status", columnList = "status"),
        @Index(name = "idx_wifi_ap_ssid", columnList = "ssid")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WifiAccessPoint {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "ssid", nullable = false, length = 100)
    private String ssid;

    @Column(name = "bssid", nullable = false, unique = true, length = 17)
    private String bssid;

    @Column(name = "name", length = 100)
    private String name;

    @Column(name = "location", length = 200)
    private String location;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private WifiApStatus status = WifiApStatus.ACTIVE;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();

    @OneToMany(mappedBy = "wifiAccessPoint", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<RoomWifiAccessPoint> roomWifiAccessPoints = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (updatedAt == null) {
            updatedAt = LocalDateTime.now();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
