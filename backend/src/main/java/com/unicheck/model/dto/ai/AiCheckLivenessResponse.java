package com.unicheck.model.dto.ai;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.util.Map;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiCheckLivenessResponse {

    private Boolean success;
    private LivenessData data;
    private String message;
    private String errorCode;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class LivenessData {
        @JsonProperty("is_live")
        private Boolean isLive;

        private Double confidence;

        private Map<String, Double> probabilities;

        @JsonProperty("prediction_class")
        private String predictionClass;

        private Double threshold;

        @JsonProperty("model_mode")
        private String modelMode;

        private String status;

        @JsonProperty("fail_closed")
        private Boolean failClosed;
    }
}
