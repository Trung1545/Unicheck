// ==============================================================================
// UniCheck - Class Section API Client Services (F-14)
// Directly interfacing with Spring Boot ClassSectionController
// ==============================================================================

import apiClient from '../api-client/axios-instance';
import {
  ApiResponse,
  ClassSectionCreateRequest,
  ClassSectionQueryParams,
  ClassSectionResponse,
  ClassSectionStatsResponse,
  ClassSectionSummaryDto,
  ClassSectionUpdateRequest,
  EnrollmentResponse,
  PageResponse,
} from '../types/api';

/**
 * 1. Lấy danh sách lớp học phần có phân trang, tìm kiếm và lọc (GET /api/v1/classes)
 */
export const getClassesApi = async (
  params?: ClassSectionQueryParams
): Promise<ApiResponse<PageResponse<ClassSectionResponse>>> => {
  const queryParams: Record<string, any> = {};

  if (params?.search && params.search.trim()) {
    queryParams.search = params.search.trim();
  }
  if (params?.semesterId !== undefined) {
    queryParams.semesterId = params.semesterId;
  }
  if (params?.courseId !== undefined) {
    queryParams.courseId = params.courseId;
  }
  if (params?.lecturerId !== undefined) {
    queryParams.lecturerId = params.lecturerId;
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

  return apiClient.get('/classes', { params: queryParams });
};

/**
 * 2. Lấy danh sách tóm tắt lớp học phần cho dropdown selection (GET /api/v1/classes/summaries)
 */
export const getClassSummariesApi = async (
  semesterId?: number
): Promise<ApiResponse<ClassSectionSummaryDto[]>> => {
  const params: Record<string, any> = {};
  if (semesterId !== undefined) {
    params.semesterId = semesterId;
  }
  return apiClient.get('/classes/summaries', { params });
};

/**
 * 3. Lấy thống kê bento metrics cho lớp học phần (GET /api/v1/classes/stats)
 */
export const getClassStatsApi = async (
  semesterId?: number
): Promise<ApiResponse<ClassSectionStatsResponse>> => {
  const params: Record<string, any> = {};
  if (semesterId !== undefined) {
    params.semesterId = semesterId;
  }
  return apiClient.get('/classes/stats', { params });
};

/**
 * 4. Kiểm tra mã lớp học phần đã tồn tại chưa (GET /api/v1/classes/check-name)
 */
export const checkClassNameApi = async (
  className: string
): Promise<ApiResponse<{ available: boolean }>> => {
  return apiClient.get('/classes/check-name', {
    params: { className },
  });
};

/**
 * 5. Lấy chi tiết lớp học phần theo className (GET /api/v1/classes/{className})
 */
export const getClassByClassNameApi = async (
  className: string
): Promise<ApiResponse<ClassSectionResponse>> => {
  return apiClient.get(`/classes/${className}`);
};

/**
 * 6. Tạo mới lớp học phần (POST /api/v1/classes)
 */
export const createClassApi = async (
  data: ClassSectionCreateRequest
): Promise<ApiResponse<ClassSectionResponse>> => {
  return apiClient.post('/classes', data);
};

/**
 * 7. Cập nhật thông tin lớp học phần (PUT /api/v1/classes/{className})
 */
export const updateClassApi = async (
  className: string,
  data: ClassSectionUpdateRequest
): Promise<ApiResponse<ClassSectionResponse>> => {
  return apiClient.put(`/classes/${className}`, data);
};

/**
 * 8. Xóa lớp học phần (DELETE /api/v1/classes/{className})
 */
export const deleteClassApi = async (
  className: string
): Promise<ApiResponse<void>> => {
  return apiClient.delete(`/classes/${className}`);
};

/**
 * 9. Lấy danh sách sinh viên theo lớp học phần (GET /api/v1/classes/{className}/students)
 */
export const getClassStudentsApi = async (
  className: string
): Promise<ApiResponse<EnrollmentResponse[]>> => {
  return apiClient.get(`/classes/${className}/students`);
};

/**
 * 10. Ghi danh sinh viên vào lớp học phần qua route lồng nhau (POST /api/v1/classes/{className}/students)
 */
export const addStudentToClassApi = async (
  className: string,
  studentId: number
): Promise<ApiResponse<EnrollmentResponse>> => {
  return apiClient.post(`/classes/${className}/students`, { studentId });
};
