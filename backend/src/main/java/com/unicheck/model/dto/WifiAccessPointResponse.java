package com.unicheck.model.dto;

import com.unicheck.model.entity.WifiAccessPoint;
import com.unicheck.model.enums.WifiApStatus;
import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WifiAccessPointResponse {

    private Long id;
    private String ssid;
    private String bssid;
    private String name;
    private String location;
    private WifiApStatus status;
    private Long assignedRoomsCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static WifiAccessPointResponse fromEntity(WifiAccessPoint ap, Long assignedRoomsCount) {
        if (ap == null) return null;
        return WifiAccessPointResponse.builder()
                .id(ap.getId())
                .ssid(ap.getSsid())
                .bssid(ap.getBssid())
                .name(ap.getName())
                .location(ap.getLocation())
                .status(ap.getStatus())
                .assignedRoomsCount(assignedRoomsCount != null ? assignedRoomsCount : 0L)
                .createdAt(ap.getCreatedAt())
                .updatedAt(ap.getUpdatedAt())
                .build();
    }
}
