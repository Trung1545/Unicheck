// ==============================================================================
// UniCheck - Enrollment API Client Services (F-15)
// Directly interfacing with Spring Boot EnrollmentController
// ==============================================================================

import apiClient from '../api-client/axios-instance';
import {
  ApiResponse,
  EnrollmentCreateRequest,
  EnrollmentQueryParams,
  EnrollmentResponse,
  PageResponse,
} from '../types/api';

/**
 * 1. Lấy danh sách ghi danh có phân trang, lọc và tìm kiếm (GET /api/v1/enrollments)
 */
export const getEnrollmentsApi = async (
  params?: EnrollmentQueryParams
): Promise<ApiResponse<PageResponse<EnrollmentResponse>>> => {
  const queryParams: Record<string, any> = {};

  if (params?.className && params.className.trim()) {
    queryParams.className = params.className.trim();
  }
  if (params?.studentId !== undefined) {
    queryParams.studentId = params.studentId;
  }
  if (params?.status && params.status !== 'all') {
    queryParams.status = params.status;
  }
  if (params?.search && params.search.trim()) {
    queryParams.search = params.search.trim();
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

  return apiClient.get('/enrollments', { params: queryParams });
};

/**
 * 2. Lấy thông tin chi tiết một bản ghi ghi danh (GET /api/v1/enrollments/{id})
 */
export const getEnrollmentByIdApi = async (
  id: number | string
): Promise<ApiResponse<EnrollmentResponse>> => {
  return apiClient.get(`/enrollments/${id}`);
};

/**
 * 3. Ghi danh sinh viên vào lớp học phần (POST /api/v1/enrollments)
 */
export const createEnrollmentApi = async (
  data: EnrollmentCreateRequest
): Promise<ApiResponse<EnrollmentResponse>> => {
  return apiClient.post('/enrollments', data);
};

/**
 * 4. Hủy ghi danh sinh viên khỏi lớp học phần (DELETE /api/v1/enrollments/{id})
 */
export const deleteEnrollmentApi = async (
  id: number | string
): Promise<ApiResponse<void>> => {
  return apiClient.delete(`/enrollments/${id}`);
};
