package com.unicheck.model.dto;

import com.unicheck.model.enums.Role;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginResponse {

    private String token; // access token
    private String refreshToken;
    @Builder.Default
    private String tokenType = "Bearer";
    private Long expiresIn; // seconds (900 for 15 mins)
    private Long userId;
    private String code;
    private String username;
    private String fullName;
    private String email;
    private Role role;
    private Boolean isPasswordChanged;
}
