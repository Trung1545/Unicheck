package com.unicheck.model.dto.ai;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class AiExtractEmbeddingResponse {

    private Boolean success;

    private String message;

    @JsonProperty("errorCode")
    private String errorCode;

    private String error;

    // Nested payload returned by Flask AI Service
    private AiExtractData data;

    // Flat root fields for legacy contracts / test builders
    @JsonProperty("face_detected")
    private Boolean faceDetected;

    private List<Float> embedding;

    @JsonProperty("embedding_dimension")
    private Integer embeddingDimension;

    @JsonProperty("model_name")
    private String modelName;

    @JsonProperty("model_version")
    private String modelVersion;

    private Map<String, Object> quality;

    public List<Float> getEmbedding() {
        if (data != null && data.getEmbedding() != null) {
            return data.getEmbedding();
        }
        return embedding;
    }

    public Integer getEmbeddingDimension() {
        if (data != null && data.getEmbeddingDimension() != null) {
            return data.getEmbeddingDimension();
        }
        return embeddingDimension;
    }

    public Boolean getFaceDetected() {
        if (data != null && data.getFaceDetected() != null) {
            return data.getFaceDetected();
        }
        return faceDetected;
    }

    public String getModelName() {
        if (data != null && data.getModelName() != null) {
            return data.getModelName();
        }
        return modelName;
    }

    public String getModelVersion() {
        if (data != null && data.getModelVersion() != null) {
            return data.getModelVersion();
        }
        return modelVersion;
    }

    public String getErrorCode() {
        if (errorCode != null && !errorCode.isBlank()) {
            return errorCode;
        }
        return error;
    }

    public String getError() {
        if (error != null && !error.isBlank()) {
            return error;
        }
        return errorCode;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class AiExtractData {
        private List<Float> embedding;

        @JsonProperty("embedding_dimension")
        private Integer embeddingDimension;

        @JsonProperty("face_detected")
        private Boolean faceDetected;

        @JsonProperty("model_name")
        private String modelName;

        @JsonProperty("model_version")
        private String modelVersion;

        private Double confidence;

        @JsonProperty("face_count")
        private Integer faceCount;

        @JsonProperty("bounding_box")
        private Map<String, Object> boundingBox;

        private Map<String, Object> quality;
    }
}
