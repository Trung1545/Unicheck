package com.unicheck.model.dto.ai;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AiVerifyFaceRequest {

    @JsonProperty("source_embedding")
    private List<Float> sourceEmbedding;

    @JsonProperty("target_embedding")
    private List<Float> targetEmbedding;

    @JsonProperty("source_image_base64")
    private String sourceImageBase64;

    @JsonProperty("target_image_base64")
    private String targetImageBase64;

    @JsonProperty("threshold")
    @Builder.Default
    private Double threshold = 0.68;

    private String metric;
}
