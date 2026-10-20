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

    @JsonProperty("totalSessionsToday")
    public Long getTotalSessionsToday() {
        return totalSessionsToday != null ? totalSessionsToday : (totalToday != null ? totalToday : 0L);
    }

    @JsonProperty("activeOpenSessions")
    public Long getActiveOpenSessions() {
        return activeOpenSessions != null ? activeOpenSessions : (openCount != null ? openCount : 0L);
    }

    @JsonProperty("completedSessions")
    public Long getCompletedSessions() {
        return completedSessions != null ? completedSessions : (closedCount != null ? closedCount : 0L);
    }

    @JsonProperty("abnormalSessions")
    public Long getAbnormalSessions() {
        return abnormalSessions != null ? abnormalSessions : (abnormalCount != null ? abnormalCount : 0L);
    }

    @JsonProperty("onTimeRate")
    public Double getOnTimeRate() {
        if (onTimeRate != null) return onTimeRate;
        return attendanceRatePercentage != null ? attendanceRatePercentage : 100.0;
    }
}
