package com.unicheck.model.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FacilityStatsResponse {

    private Long totalRooms;
    private Long availableRooms;
    private Long occupiedRooms;
    private Long maintenanceRooms;
    private Double readinessRate;
    private Long totalCapacity;
    private Long activeStudentsCount;
    private Long activeWifiAps;
    private Long totalWifiAps;
    private Integer averageRssiDbm;
    private Long onlineKiosks;
    private Long totalKiosks;
    private Integer averageFaceLatencyMs;
}
