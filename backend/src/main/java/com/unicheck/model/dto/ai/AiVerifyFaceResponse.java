package com.unicheck.model.dto.ai;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiVerifyFaceResponse {

    private Boolean success;
    private VerifyData data;
    private String message;
    private String errorCode;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class VerifyData {
        private Boolean matched;
        private Double similarity;
        private Double distance;
        private Double threshold;
        private String metric;
    }
}
