package com.unicheck.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
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

    @JsonProperty("totalSessionsToday")
    public Long getTotalSessionsToday() {
        return totalToday != null ? totalToday : 0L;
    }

    @JsonProperty("activeOpenSessions")
    public Long getActiveOpenSessions() {
        return openCount != null ? openCount : 0L;
    }

    @JsonProperty("completedSessions")
    public Long getCompletedSessions() {
        return closedCount != null ? closedCount : 0L;
    }

    @JsonProperty("abnormalSessions")
    public Long getAbnormalSessions() {
        return abnormalCount != null ? abnormalCount : 0L;
    }

    @JsonProperty("onTimeRate")
    public Double getOnTimeRate() {
        return attendanceRatePercentage != null ? attendanceRatePercentage : 100.0;
    }
}
