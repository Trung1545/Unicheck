// ==============================================================================
// UniCheck - Semester Management API Client Services
// Directly interfacing with Spring Boot SemesterController endpoints
// ==============================================================================

import apiClient from '../api-client/axios-instance';
import {
  ApiResponse,
  PageResponse,
  SemesterCreateRequest,
  SemesterQueryParams,
  SemesterResponse,
  SemesterUpdateRequest,
} from '../types/api';

/**
 * 1. Lấy danh sách học kỳ có tìm kiếm, lọc trạng thái và phân trang (GET /api/v1/semesters)
 */
export const getSemestersApi = async (
  params?: SemesterQueryParams
): Promise<ApiResponse<PageResponse<SemesterResponse>>> => {
  const queryParams: Record<string, any> = {};

  if (params?.search && params.search.trim()) {
    queryParams.search = params.search.trim();
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

  return apiClient.get('/semesters', { params: queryParams });
};

/**
 * 2. Lấy thông tin học kỳ hiện hành đang mở (GET /api/v1/semesters/active)
 */
export const getActiveSemesterApi = async (): Promise<ApiResponse<SemesterResponse | null>> => {
  return apiClient.get('/semesters/active');
};

/**
 * 3. Lấy thông tin chi tiết học kỳ theo ID (GET /api/v1/semesters/{id})
 */
export const getSemesterByIdApi = async (
  id: number | string
): Promise<ApiResponse<SemesterResponse>> => {
  return apiClient.get(`/semesters/${id}`);
};

/**
 * 4. Kiểm tra tính khả dụng của mã học kỳ (GET /api/v1/semesters/check-code)
 */
export const checkSemesterCodeApi = async (
  code: string
): Promise<ApiResponse<{ available: boolean }>> => {
  return apiClient.get('/semesters/check-code', {
    params: { code },
  });
};

/**
 * 5. Tạo mới học kỳ kèm cấu hình (POST /api/v1/semesters)
 */
export const createSemesterApi = async (
  data: SemesterCreateRequest
): Promise<ApiResponse<SemesterResponse>> => {
  return apiClient.post('/semesters', data);
};

/**
 * 6. Cập nhật học kỳ theo ID (PUT /api/v1/semesters/{id})
 */
export const updateSemesterApi = async (
  id: number | string,
  data: SemesterUpdateRequest
): Promise<ApiResponse<SemesterResponse>> => {
  return apiClient.put(`/semesters/${id}`, data);
};

/**
 * 7. Khóa sổ lưu trữ học kỳ (PATCH /api/v1/semesters/{id}/lock)
 */
export const lockSemesterApi = async (
  id: number | string
): Promise<ApiResponse<SemesterResponse>> => {
  return apiClient.patch(`/semesters/${id}/lock`);
};

/**
 * 8. Xóa học kỳ theo ID (DELETE /api/v1/semesters/{id})
 */
export const deleteSemesterApi = async (
  id: number | string
): Promise<ApiResponse<void>> => {
  return apiClient.delete(`/semesters/${id}`);
};
