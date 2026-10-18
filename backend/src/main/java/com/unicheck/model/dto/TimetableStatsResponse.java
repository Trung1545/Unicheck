package com.unicheck.model.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TimetableStatsResponse {

    private Long totalSlotsWeek;

    private Double roomUtilizationRate;

    private String aiEquippedRoomsRatio;

    private Long activeConflictsCount;
}
