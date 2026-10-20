package com.unicheck.model.dto.ai;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiVerifyFaceRequest {

    @JsonProperty("source_embedding")
    private List<Float> sourceEmbedding;

    @JsonProperty("target_embedding")
    private List<Float> targetEmbedding;

    @JsonProperty("source_image_base64")
    private String sourceImageBase64;

    @JsonProperty("target_image_base64")
    private String targetImageBase64;

    private Double threshold;

    private String metric;
}
