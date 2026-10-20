package com.unicheck.model.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AttendanceSessionStatsResponse {

    private Long totalToday;
    private Long totalSessionsToday;
    private Long morningSessions;
    private Long afternoonSessions;
    private Long openCount;
    private Long activeOpenSessions;
    private Long closedCount;
    private Long completedSessions;
    private Long upcomingCount;
    private Long abnormalCount;
    private Long abnormalSessions;
    private Double attendanceRatePercentage;
    private Double onTimeRate;
}

