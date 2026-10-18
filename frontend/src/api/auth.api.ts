// ==============================================================================
// UniCheck - Auth API Client Services
// Directly interfacing with Spring Boot AuthController endpoints
// ==============================================================================

import apiClient from '../api-client/axios-instance';
import {
  ApiResponse,
  ChangePasswordRequest,
  ForgotPasswordRequest,
  LoginRequest,
  LoginResponse,
  RefreshTokenRequest,
  ResetPasswordRequest,
  TokenRefreshResponse,
  UpdateProfileRequest,
  UserProfileResponse,
} from '../types/api';

/**
 * 1. Đăng nhập hệ thống (POST /api/v1/auth/login)
 */
export const loginApi = async (data: LoginRequest): Promise<ApiResponse<LoginResponse>> => {
  return apiClient.post('/auth/login', data);
};

/**
 * 2. Đăng xuất hệ thống (POST /api/v1/auth/logout)
 */
export const logoutApi = async (): Promise<ApiResponse<void>> => {
  return apiClient.post('/auth/logout');
};

/**
 * 3. Làm mới access token (POST /api/v1/auth/refresh-token)
 */
export const refreshTokenApi = async (data: RefreshTokenRequest): Promise<ApiResponse<TokenRefreshResponse>> => {
  return apiClient.post('/auth/refresh-token', data);
};

/**
 * 4. Lấy thông tin hồ sơ người dùng hiện tại (GET /api/v1/auth/me)
 */
export const getProfileApi = async (): Promise<ApiResponse<UserProfileResponse>> => {
  return apiClient.get('/auth/me');
};

/**
 * 5. Cập nhật thông tin hồ sơ (PUT /api/v1/auth/profile)
 */
export const updateProfileApi = async (data: UpdateProfileRequest): Promise<ApiResponse<UserProfileResponse>> => {
  return apiClient.put('/auth/profile', data);
};

/**
 * 6. Đổi mật khẩu cá nhân (POST /api/v1/auth/change-password)
 */
export const changePasswordApi = async (data: ChangePasswordRequest): Promise<ApiResponse<void>> => {
  return apiClient.post('/auth/change-password', data);
};

/**
 * 7. Yêu cầu khôi phục mật khẩu gửi mã OTP (POST /api/v1/auth/forgot-password)
 */
export const forgotPasswordApi = async (data: ForgotPasswordRequest): Promise<ApiResponse<void>> => {
  return apiClient.post('/auth/forgot-password', data);
};

/**
 * 8. Đặt lại mật khẩu với mã OTP (POST /api/v1/auth/reset-password)
 */
export const resetPasswordApi = async (data: ResetPasswordRequest): Promise<ApiResponse<void>> => {
  return apiClient.post('/auth/reset-password', data);
};
