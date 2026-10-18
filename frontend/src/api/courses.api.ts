// ==============================================================================
// UniCheck - Course Catalog API Client Services
// Directly interfacing with Spring Boot CourseController endpoints
// ==============================================================================

import apiClient from '../api-client/axios-instance';
import {
  ApiResponse,
  CourseCreateRequest,
  CourseQueryParams,
  CourseResponse,
  CourseSummaryDto,
  CourseUpdateRequest,
  PageResponse,
} from '../types/api';

/**
 * 1. Lấy danh sách học phần có tìm kiếm, lọc theo tín chỉ/trạng thái và phân trang (GET /api/v1/courses)
 */
export const getCoursesApi = async (
  params?: CourseQueryParams
): Promise<ApiResponse<PageResponse<CourseResponse>>> => {
  const queryParams: Record<string, any> = {};

  if (params?.search && params.search.trim()) {
    queryParams.search = params.search.trim();
  }
  if (params?.credits !== undefined) {
    queryParams.credits = params.credits;
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

  return apiClient.get('/courses', { params: queryParams });
};

/**
 * 2. Lấy danh sách tóm tắt toàn bộ học phần phục vụ chọn môn tiên quyết (GET /api/v1/courses/summaries)
 */
export const getCourseSummariesApi = async (): Promise<ApiResponse<CourseSummaryDto[]>> => {
  return apiClient.get('/courses/summaries');
};

/**
 * 3. Lấy thông tin chi tiết học phần theo ID (GET /api/v1/courses/{id})
 */
export const getCourseByIdApi = async (
  id: number | string
): Promise<ApiResponse<CourseResponse>> => {
  return apiClient.get(`/courses/${id}`);
};

/**
 * 4. Kiểm tra tính khả dụng của mã học phần (GET /api/v1/courses/check-code)
 */
export const checkCourseCodeApi = async (
  code: string
): Promise<ApiResponse<{ available: boolean }>> => {
  return apiClient.get('/courses/check-code', {
    params: { code },
  });
};

/**
 * 5. Tạo mới học phần (POST /api/v1/courses)
 */
export const createCourseApi = async (
  data: CourseCreateRequest
): Promise<ApiResponse<CourseResponse>> => {
  return apiClient.post('/courses', data);
};

/**
 * 6. Cập nhật học phần theo ID (PUT /api/v1/courses/{id})
 */
export const updateCourseApi = async (
  id: number | string,
  data: CourseUpdateRequest
): Promise<ApiResponse<CourseResponse>> => {
  return apiClient.put(`/courses/${id}`, data);
};

/**
 * 7. Xóa học phần theo ID (DELETE /api/v1/courses/{id})
 */
export const deleteCourseApi = async (
  id: number | string
): Promise<ApiResponse<void>> => {
  return apiClient.delete(`/courses/${id}`);
};
