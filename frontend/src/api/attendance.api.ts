// ==============================================================================
// UniCheck - Attendance Session API Client Services (TASK-05)
// Dual Route Compatibility: /api/v1/attendance/... & /api/attendance/...
// ==============================================================================

import apiClient from '../api-client/axios-instance';
import {
  ApiResponse,
  AttendanceConfigDto,
  AttendanceSessionCreateRequest,
  AttendanceSessionOpenRequest,
  AttendanceSessionQueryParams,
  AttendanceSessionResponse,
  AttendanceSessionStatsResponse,
  AttendanceSessionStatusResponse,
  PageResponse,
  StudentAttendanceResponse,
} from '../types/api';
import {
  SessionStudentAttendanceDto,
  AttendanceManualAdjustRequest,
  AttendanceRecheckCreateRequest,
  AttendanceRecheckResponse,
  AttendanceHistoryRecordDto,
} from '../types/attendance';

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
  id: number,
  data?: AttendanceSessionOpenRequest
): Promise<ApiResponse<AttendanceSessionResponse>> => {
  return apiClient.post(`/attendance/sessions/${id}/open`, data);
};

/**
 * 4b. Cập nhật chu kỳ đổi mã QR động (PUT /api/v1/attendance/sessions/{id}/qr-interval)
 */
export const updateAttendanceSessionQrIntervalApi = async (
  id: number,
  data: AttendanceSessionOpenRequest
): Promise<ApiResponse<AttendanceSessionResponse>> => {
  return apiClient.put(`/attendance/sessions/${id}/qr-interval`, data);
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

/**
 * 11. Lấy mã QR cho phiên điểm danh OPEN (GET /api/v1/attendance/sessions/{id}/qr)
 * Hỗ trợ mode='DYNAMIC_QR' hoặc mode='STATIC_TEST_QR'
 */
export const getSessionQrTokenApi = async (
  sessionId: number,
  mode: string = 'DYNAMIC_QR'
): Promise<ApiResponse<import('../types/attendance').QrTokenResponse>> => {
  return apiClient.get(`/attendance/sessions/${sessionId}/qr`, {
    params: { mode },
  });
};

/**
 * 11b. Kiểm tra điều kiện và trạng thái Static Test QR (GET /api/v1/attendance/sessions/{id}/static-qr/status)
 */
export const getStaticQrStatusApi = async (
  sessionId: number
): Promise<ApiResponse<import('../types/attendance').StaticQrStatusResponse>> => {
  return apiClient.get(`/attendance/sessions/${sessionId}/static-qr/status`);
};

/**
 * 11c. Lấy mã Static Test QR cố định (GET /api/v1/attendance/sessions/{id}/static-qr)
 */
export const getStaticQrTokenApi = async (
  sessionId: number
): Promise<ApiResponse<import('../types/attendance').QrTokenResponse>> => {
  return apiClient.get(`/attendance/sessions/${sessionId}/static-qr`);
};

/**
 * 11d. Tái tạo mã Static Test QR mới (POST /api/v1/attendance/sessions/{id}/static-qr/regenerate)
 */
export const regenerateStaticQrTokenApi = async (
  sessionId: number
): Promise<ApiResponse<import('../types/attendance').QrTokenResponse>> => {
  return apiClient.post(`/attendance/sessions/${sessionId}/static-qr/regenerate`);
};

/**
 * 11e. Thu hồi mã Static Test QR (POST /api/v1/attendance/sessions/{id}/static-qr/revoke)
 */
export const revokeStaticQrTokenApi = async (
  sessionId: number
): Promise<ApiResponse<void>> => {
  return apiClient.post(`/attendance/sessions/${sessionId}/static-qr/revoke`);
};

/**
 * 12. Xác thực mã QR điểm danh (POST /api/v1/attendance/qr/validate)
 */
export const validateQrTokenApi = async (
  request: import('../types/attendance').QrValidationRequest
): Promise<ApiResponse<import('../types/attendance').QrValidationResponse>> => {
  return apiClient.post('/attendance/qr/validate', request);
};

/**
 * 13. Lấy lượt điểm danh gần đây cho Live Drawer (GET /api/v1/attendance/sessions/{id}/recent-checkins)
 */
export const getRecentCheckInsApi = async (
  sessionId: number,
  limit: number = 10
): Promise<ApiResponse<StudentAttendanceResponse[]>> => {
  return apiClient.get(`/attendance/sessions/${sessionId}/recent-checkins`, {
    params: { limit },
  });
};

/**
 * 14. Lấy toàn bộ danh sách sinh viên ghi danh trong phiên kèm trạng thái điểm danh và recheck
 * (GET /api/v1/attendance/sessions/{sessionId}/students)
 */
export const getSessionStudentsApi = async (
  sessionId: number
): Promise<ApiResponse<SessionStudentAttendanceDto[]>> => {
  return apiClient.get(`/attendance/sessions/${sessionId}/students`);
};

/**
 * 15. Giảng viên điều chỉnh thủ công kết quả điểm danh của sinh viên (PRESENT, LATE, ABSENT) kèm lý do
 * (PATCH /api/v1/attendance/sessions/{sessionId}/students/{studentId})
 */
export const adjustStudentAttendanceApi = async (
  sessionId: number,
  studentId: number,
  data: AttendanceManualAdjustRequest
): Promise<ApiResponse<StudentAttendanceResponse>> => {
  return apiClient.patch(`/attendance/sessions/${sessionId}/students/${studentId}`, data);
};

/**
 * 16. Giảng viên gửi yêu cầu điểm danh lại (Recheck Request) cho sinh viên
 * (POST /api/v1/attendance/sessions/{sessionId}/students/{studentId}/recheck)
 */
export const createRecheckRequestApi = async (
  sessionId: number,
  studentId: number,
  data: AttendanceRecheckCreateRequest
): Promise<ApiResponse<AttendanceRecheckResponse>> => {
  return apiClient.post(`/attendance/sessions/${sessionId}/students/${studentId}/recheck`, data);
};

/**
 * 17. Lấy lịch sử điều chỉnh điểm danh và tái xác thực của phiên
 * (GET /api/v1/attendance/sessions/{sessionId}/history)
 */
export const getSessionAdjustmentHistoryApi = async (
  sessionId: number
): Promise<ApiResponse<AttendanceHistoryRecordDto[]>> => {
  return apiClient.get(`/attendance/sessions/${sessionId}/history`);
};
