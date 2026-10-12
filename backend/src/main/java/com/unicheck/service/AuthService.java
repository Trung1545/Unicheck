package com.unicheck.service;

import com.unicheck.model.dto.*;
import jakarta.servlet.http.HttpServletRequest;

public interface AuthService {

    LoginResponse login(LoginRequest request, HttpServletRequest httpRequest);

    void logout(HttpServletRequest httpRequest);

    TokenRefreshResponse refreshToken(RefreshTokenRequest request);

    UserProfileResponse getCurrentUserProfile();

    UserProfileResponse updateProfile(UpdateProfileRequest request);

    void changePassword(ChangePasswordRequest request);

    void processForgotPassword(ForgotPasswordRequest request);

    void resetPassword(ResetPasswordRequest request);
}
