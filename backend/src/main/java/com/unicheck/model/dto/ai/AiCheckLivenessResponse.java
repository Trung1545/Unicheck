package com.unicheck.model.dto.ai;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

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
    @Builder
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class AiLivenessData {
        @JsonProperty("is_live")
        private Boolean isLive;

        @JsonProperty("confidence")
        private Double confidence;

        @JsonProperty("liveness_score")
        private Double livenessScore;

        private Map<String, Double> probabilities;

        @JsonProperty("prediction_class")
        private String predictionClass;

        private Double threshold;

        @JsonProperty("attack_type_detected")
        private String attackTypeDetected;

        @JsonProperty("model_mode")
        private String modelMode;

        private String status;

        @JsonProperty("fail_closed")
        private Boolean failClosed;

        public Double getLivenessScore() {
            return livenessScore != null ? livenessScore : confidence;
        }

        public Double getConfidence() {
            return confidence != null ? confidence : livenessScore;
        }
    }

    public static class LivenessData extends AiLivenessData {
        public LivenessData() {
            super();
        }
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
                .data(AiLivenessData.builder()
                        .isLive(isLive)
                        .livenessScore(score)
                        .confidence(score)
                        .threshold(0.70)
                        .status(isLive ? "LIVE" : "SPOOF")
                        .failClosed(false)
                        .build())
                .build();
    }
}
