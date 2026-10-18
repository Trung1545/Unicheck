package com.unicheck.model.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AttendanceSessionStatsResponse {

    private Long totalToday;
    private Long morningSessions;
    private Long afternoonSessions;
    private Long openCount;
    private Long closedCount;
    private Long upcomingCount;
    private Long abnormalCount;
    private Double attendanceRatePercentage;
}
