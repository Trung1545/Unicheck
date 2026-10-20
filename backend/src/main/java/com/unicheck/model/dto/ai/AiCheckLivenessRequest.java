package com.unicheck.model.dto.ai;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AiCheckLivenessRequest {

    @JsonProperty("image_base64")
    private String imageBase64;

    @JsonProperty("threshold")
    @Builder.Default
    private Double threshold = 0.70;
}
