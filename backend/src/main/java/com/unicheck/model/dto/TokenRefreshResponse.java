package com.unicheck.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TokenRefreshResponse {

    private String token; // new access token
    private String refreshToken; // new or existing refresh token
    @Builder.Default
    private String tokenType = "Bearer";
    private Long expiresIn; // seconds (900)
}
