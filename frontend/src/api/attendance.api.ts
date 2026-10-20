// ==============================================================================
// UniCheck - Attendance Session API Client Services (TASK-05)
// Dual Route Compatibility: /api/v1/attendance/... & /api/attendance/...
// ==============================================================================

import apiClient from '../api-client/axios-instance';
import {
  ApiResponse,
  AttendanceConfigDto,
  AttendanceSessionCreateRequest,
  AttendanceSessionQueryParams,
  AttendanceSessionResponse,
  AttendanceSessionStatsResponse,
  AttendanceSessionStatusResponse,
  PageResponse,
  StudentAttendanceResponse,
} from '../types/api';

/**
 * 1. Lấy danh sách phiên điểm danh có phân trang, tìm kiếm và lọc (GET /api/v1/attendance/sessions)
 */
export const getAttendanceSessionsApi = async (
  params?: AttendanceSessionQueryParams
): Promise<ApiResponse<PageResponse<AttendanceSessionResponse>>> => {
  const queryParams: Record<string, any> = {};

  if (params?.search && params.search.trim()) {
    queryParams.search = params.search.trim();
  }
  if (params?.semesterId !== undefined) {
    queryParams.semesterId = params.semesterId;
  }
  if (params?.className && params.className.trim()) {
    queryParams.className = params.className.trim();
  }
  if (params?.lecturerId !== undefined) {
    queryParams.lecturerId = params.lecturerId;
  }
  if (params?.date && params.date.trim()) {
    queryParams.date = params.date.trim();
  }
  if (params?.status && params.status !== 'ALL') {
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

  return apiClient.get('/attendance/sessions', { params: queryParams });
};

/**
 * 2. Lấy chi tiết phiên điểm danh theo ID (GET /api/v1/attendance/sessions/{id})
 */
export const getAttendanceSessionByIdApi = async (
  id: number
): Promise<ApiResponse<AttendanceSessionResponse>> => {
  return apiClient.get(`/attendance/sessions/${id}`);
};

/**
 * 3. Tạo phiên điểm danh mới từ timetable slot (POST /api/v1/attendance/sessions)
 */
export const createAttendanceSessionApi = async (
  data: AttendanceSessionCreateRequest
): Promise<ApiResponse<AttendanceSessionResponse>> => {
  return apiClient.post('/attendance/sessions', data);
};

/**
 * 4. Mở phiên điểm danh (POST /api/v1/attendance/sessions/{id}/open)
 */
export const openAttendanceSessionApi = async (
  id: number
): Promise<ApiResponse<AttendanceSessionResponse>> => {
  return apiClient.post(`/attendance/sessions/${id}/open`);
};

/**
 * 5. Đóng phiên điểm danh (POST /api/v1/attendance/sessions/{id}/close)
 */
export const closeAttendanceSessionApi = async (
  id: number
): Promise<ApiResponse<AttendanceSessionResponse>> => {
  return apiClient.post(`/attendance/sessions/${id}/close`);
};

/**
 * 6. Lấy trạng thái phiên điểm danh - Contract cho TASK-06 (GET /api/v1/attendance/sessions/{id}/status)
 */
export const getAttendanceSessionStatusApi = async (
  id: number
): Promise<ApiResponse<AttendanceSessionStatusResponse>> => {
  return apiClient.get(`/attendance/sessions/${id}/status`);
};

/**
 * 7. Lấy thống kê KPI các phiên điểm danh trong ngày (GET /api/v1/attendance/sessions/stats)
 */
export const getAttendanceSessionStatsApi = async (): Promise<
  ApiResponse<AttendanceSessionStatsResponse>
> => {
  return apiClient.get('/attendance/sessions/stats');
};

/**
 * 8. Lấy cấu hình cơ chế điểm danh toàn hệ thống (GET /api/v1/attendance/configs)
 */
export const getAttendanceConfigApi = async (): Promise<
  ApiResponse<AttendanceConfigDto>
> => {
  return apiClient.get('/attendance/configs');
};

/**
 * 9. Cập nhật cấu hình cơ chế điểm danh toàn hệ thống (PUT /api/v1/attendance/configs)
 */
export const updateAttendanceConfigApi = async (
  data: Partial<AttendanceConfigDto>
): Promise<ApiResponse<AttendanceConfigDto>> => {
  return apiClient.put('/attendance/configs', data);
};

/**
 * 10. Lấy danh sách điểm danh của sinh viên trong phiên (GET /api/v1/attendance/sessions/{id}/attendances)
 */
export const getAttendanceCheckInsApi = async (
  sessionId: number
): Promise<ApiResponse<StudentAttendanceResponse[]>> => {
  return apiClient.get(`/attendance/sessions/${sessionId}/recent-checkins`);
};
