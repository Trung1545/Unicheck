// ==============================================================================
// UniCheck - User Management API Client Services
// Directly interfacing with Spring Boot UserController endpoints
// ==============================================================================

import apiClient from '../api-client/axios-instance';
import {
  ApiResponse,
  CsvImportResultResponse,
  PageResponse,
  UserCreateRequest,
  UserQueryParams,
  UserResponse,
  UserStatusUpdateRequest,
  UserUpdateRequest,
} from '../types/api';

/**
 * 1. Lấy danh sách người dùng có tìm kiếm, lọc, phân trang và sắp xếp (GET /api/v1/users)
 */
export const getUsersApi = async (
  params?: UserQueryParams
): Promise<ApiResponse<PageResponse<UserResponse>>> => {
  const queryParams: Record<string, any> = {};

  if (params?.search && params.search.trim()) {
    queryParams.search = params.search.trim();
  }
  if (params?.role && params.role !== 'all') {
    queryParams.role = params.role;
  }
  if (params?.status && params.status !== 'all') {
    queryParams.status = params.status;
  }
  if (params?.page !== undefined) {
    queryParams.page = params.page;
  }
  if (params?.size !== undefined) {
    queryParams.size = params.size;
  }
  if (params?.sort) {
    queryParams.sort = params.sort;
  }

  return apiClient.get('/users', { params: queryParams });
};

/**
 * 2. Lấy thông tin chi tiết người dùng theo ID (GET /api/v1/users/{id})
 */
export const getUserByIdApi = async (
  id: number | string
): Promise<ApiResponse<UserResponse>> => {
  return apiClient.get(`/users/${id}`);
};

/**
 * 3. Tạo mới tài khoản người dùng kèm hồ sơ (POST /api/v1/users)
 */
export const createUserApi = async (
  data: UserCreateRequest
): Promise<ApiResponse<UserResponse>> => {
  return apiClient.post('/users', data);
};

/**
 * 4. Cập nhật thông tin người dùng theo ID (PUT /api/v1/users/{id})
 */
export const updateUserApi = async (
  id: number | string,
  data: UserUpdateRequest
): Promise<ApiResponse<UserResponse>> => {
  return apiClient.put(`/users/${id}`, data);
};

/**
 * 5. Cập nhật trạng thái người dùng (Khóa/Mở khóa) (PATCH /api/v1/users/{id}/status)
 */
export const updateUserStatusApi = async (
  id: number | string,
  data: UserStatusUpdateRequest
): Promise<ApiResponse<UserResponse>> => {
  return apiClient.patch(`/users/${id}/status`, data);
};

/**
 * 6. Xóa mềm tài khoản người dùng (DELETE /api/v1/users/{id})
 */
export const deleteUserApi = async (
  id: number | string
): Promise<ApiResponse<void>> => {
  return apiClient.delete(`/users/${id}`);
};

/**
 * 7. Kiểm tra tính khả dụng của tên đăng nhập (GET /api/v1/users/check-username)
 */
export const checkUsernameApi = async (
  username: string
): Promise<ApiResponse<{ available: boolean }>> => {
  return apiClient.get('/users/check-username', {
    params: { username },
  });
};

/**
 * 8. Nhập danh sách tài khoản hàng loạt bằng file CSV (POST /api/v1/users/import-csv)
 */
export const importUsersCsvApi = async (
  file: File
): Promise<ApiResponse<CsvImportResultResponse>> => {
  const formData = new FormData();
  formData.append('file', file);

  return apiClient.post('/users/import-csv', formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });
};
