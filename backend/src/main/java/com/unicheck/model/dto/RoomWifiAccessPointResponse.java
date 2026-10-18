package com.unicheck.model.dto;

import com.unicheck.model.entity.RoomWifiAccessPoint;
import com.unicheck.model.enums.WifiApStatus;
import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoomWifiAccessPointResponse {

    private Long id;
    private Long roomId;
    private String roomCode;
    private String roomName;
    private Long wifiAccessPointId;
    private String ssid;
    private String bssid;
    private String apName;
    private String location;
    private WifiApStatus apStatus;
    private Integer signalStrength;
    private Boolean isPrimary;
    private String positionNote;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static RoomWifiAccessPointResponse fromEntity(RoomWifiAccessPoint mapping) {
        if (mapping == null) return null;
        return RoomWifiAccessPointResponse.builder()
                .id(mapping.getId())
                .roomId(mapping.getRoom() != null ? mapping.getRoom().getId() : null)
                .roomCode(mapping.getRoom() != null ? mapping.getRoom().getCode() : null)
                .roomName(mapping.getRoom() != null ? mapping.getRoom().getName() : null)
                .wifiAccessPointId(mapping.getWifiAccessPoint() != null ? mapping.getWifiAccessPoint().getId() : null)
                .ssid(mapping.getWifiAccessPoint() != null ? mapping.getWifiAccessPoint().getSsid() : null)
                .bssid(mapping.getWifiAccessPoint() != null ? mapping.getWifiAccessPoint().getBssid() : null)
                .apName(mapping.getWifiAccessPoint() != null ? mapping.getWifiAccessPoint().getName() : null)
                .location(mapping.getWifiAccessPoint() != null ? mapping.getWifiAccessPoint().getLocation() : null)
                .apStatus(mapping.getWifiAccessPoint() != null ? mapping.getWifiAccessPoint().getStatus() : null)
                .signalStrength(mapping.getSignalStrength())
                .isPrimary(mapping.getIsPrimary())
                .positionNote(mapping.getPositionNote())
                .createdAt(mapping.getCreatedAt())
                .updatedAt(mapping.getUpdatedAt())
                .build();
    }
}
