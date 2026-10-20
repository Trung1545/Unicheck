package com.unicheck.model.dto.ai;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiCheckLivenessRequest {

    @JsonProperty("image_base64")
    private String imageBase64;

    private Double threshold;
}
