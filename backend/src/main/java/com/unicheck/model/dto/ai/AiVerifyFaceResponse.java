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
public class AiVerifyFaceResponse {

    private Boolean success;
    private String message;

    @JsonProperty("errorCode")
    private String errorCode;

    private AiVerifyData data;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class AiVerifyData {
        private Boolean matched;
        private Double similarity;
        private Double distance;
        private Double threshold;
        private String metric;
        private Boolean verified;
    }

    public static class VerifyData extends AiVerifyData {
        public VerifyData() {
            super();
        }
    }

    public boolean isMatched() {
        if (data != null && data.getMatched() != null) {
            return data.getMatched();
        }
        return Boolean.TRUE.equals(success);
    }

    public Double getSimilarity() {
        return data != null ? data.getSimilarity() : null;
    }

    public static AiVerifyFaceResponse of(boolean matched, double similarity) {
        return AiVerifyFaceResponse.builder()
                .success(true)
                .data(AiVerifyData.builder()
                        .matched(matched)
                        .similarity(similarity)
                        .distance(1.0 - similarity)
                        .threshold(0.68)
                        .metric("cosine")
                        .verified(matched)
                        .build())
                .build();
    }
}
