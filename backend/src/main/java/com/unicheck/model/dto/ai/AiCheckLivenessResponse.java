package com.unicheck.model.dto.ai;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class AiCheckLivenessResponse {

    private Boolean success;
    private String message;

    @JsonProperty("errorCode")
    private String errorCode;

    private AiLivenessData data;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class AiLivenessData {
        @JsonProperty("is_live")
        private Boolean isLive;

        @JsonProperty("liveness_score")
        private Double livenessScore;

        private Double threshold;

        @JsonProperty("attack_type_detected")
        private String attackTypeDetected;

        private String status;

        @JsonProperty("fail_closed")
        private Boolean failClosed;
    }

    public boolean isLive() {
        if (data != null && data.getIsLive() != null) {
            return data.getIsLive();
        }
        return false;
    }

    public Double getLivenessScore() {
        return data != null ? data.getLivenessScore() : null;
    }

    public static AiCheckLivenessResponse of(boolean isLive, double score) {
        return AiCheckLivenessResponse.builder()
                .success(true)
                .data(new AiLivenessData(isLive, score, 0.70, null, isLive ? "LIVE" : "SPOOF", false))
                .build();
    }
}
