package com.unicheck.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.unicheck.common.dto.ApiResponse;
import com.unicheck.exception.ErrorCode;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

import java.io.IOException;

@Component
public class JwtAuthenticationEntryPoint implements AuthenticationEntryPoint {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void commence(HttpServletRequest request,
                         HttpServletResponse response,
                         AuthenticationException authException) throws IOException {
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);

        Boolean isRevoked = (Boolean) request.getAttribute("jwt_revoked");
        ApiResponse<Void> apiResponse;
        if (Boolean.TRUE.equals(isRevoked)) {
            apiResponse = ApiResponse.error(ErrorCode.TOKEN_REVOKED.getMessage(), ErrorCode.TOKEN_REVOKED.getCode());
        } else {
            apiResponse = ApiResponse.error(ErrorCode.UNAUTHORIZED.getMessage(), ErrorCode.UNAUTHORIZED.getCode());
        }

        response.getWriter().write(objectMapper.writeValueAsString(apiResponse));
    }
}
