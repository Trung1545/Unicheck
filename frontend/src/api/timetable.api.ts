// ==============================================================================
// UniCheck - Timetable & Slot Operations API Client (TASK-02D - F-16)
// Interfacing with Spring Boot TimetableController (/api/v1/timetable)
// ==============================================================================

import apiClient from '../api-client/axios-instance';
import {
  ApiResponse,
  PageResponse,
  TimetableSlotResponse,
  TimetableSlotCreateRequest,
  TimetableSlotUpdateRequest,
  TimetableSlotQueryParams,
  TimetableConflictCheckRequest,
  TimetableConflictCheckResponse,
  AvailableRoomsQueryParams,
  RoomResponse,
  SlotTypeResponse,
  TimetableStatsResponse,
} from '../types/api';

/**
 * 1. Lấy danh sách lịch học theo tuần / ngày hoặc lọc theo các tiêu chí
 */
export const getTimetableSlotsApi = async (
  params?: TimetableSlotQueryParams
): Promise<ApiResponse<TimetableSlotResponse[] | PageResponse<TimetableSlotResponse>>> => {
  const queryParams: Record<string, any> = {};

  if (params?.startDate) queryParams.startDate = params.startDate;
  if (params?.endDate) queryParams.endDate = params.endDate;
  if (params?.date) queryParams.date = params.date;
  if (params?.semesterId) queryParams.semesterId = params.semesterId;
  if (params?.className) queryParams.className = params.className.trim();
  if (params?.lecturerId) queryParams.lecturerId = params.lecturerId;
  if (params?.roomId) queryParams.roomId = params.roomId;
  if (params?.status) queryParams.status = params.status;
  if (params?.paged !== undefined) queryParams.paged = params.paged;
  if (params?.page !== undefined) queryParams.page = params.page;
  if (params?.size !== undefined) queryParams.size = params.size;
  if (params?.sort) queryParams.sort = params.sort;

  return apiClient.get('/timetable/slots', { params: queryParams });
};

/**
 * 2. Lấy chi tiết tiết học theo ID
 */
export const getTimetableSlotByIdApi = async (
  id: number
): Promise<ApiResponse<TimetableSlotResponse>> => {
  return apiClient.get(`/timetable/slots/${id}`);
};

/**
 * 3. Tạo mới tiết học trên thời khóa biểu (Admin only)
 */
export const createTimetableSlotApi = async (
  request: TimetableSlotCreateRequest
): Promise<ApiResponse<TimetableSlotResponse>> => {
  return apiClient.post('/timetable/slots', request);
};

/**
 * 4. Cập nhật tiết học (Admin only)
 */
export const updateTimetableSlotApi = async (
  id: number,
  request: TimetableSlotUpdateRequest
): Promise<ApiResponse<TimetableSlotResponse>> => {
  return apiClient.put(`/timetable/slots/${id}`, request);
};

/**
 * 5. Hủy hoặc xóa tiết học (Admin only)
 */
export const deleteTimetableSlotApi = async (
  id: number
): Promise<ApiResponse<{ id: number; deleted: boolean }>> => {
  return apiClient.delete(`/timetable/slots/${id}`);
};

/**
 * 6. Lấy thời khóa biểu cá nhân của người dùng hiện tại (/me)
 */
export const getMyTimetableApi = async (
  startDate?: string,
  endDate?: string
): Promise<ApiResponse<TimetableSlotResponse[]>> => {
  const params: Record<string, any> = {};
  if (startDate) params.startDate = startDate;
  if (endDate) params.endDate = endDate;

  return apiClient.get('/timetable/me', { params });
};

/**
 * 7. Kiểm tra xung đột thời gian thực trước khi lưu (Pre-flight Validation)
 */
export const checkConflictApi = async (
  request: TimetableConflictCheckRequest
): Promise<ApiResponse<TimetableConflictCheckResponse>> => {
  return apiClient.post('/timetable/conflicts/check', request);
};

/**
 * 7b. Lấy danh sách phòng học còn trống / khả dụng theo thời gian thực (Real-time Available Rooms)
 */
export const getAvailableRoomsApi = async (
  params: AvailableRoomsQueryParams
): Promise<ApiResponse<RoomResponse[]>> => {
  const queryParams: Record<string, any> = {
    date: params.date,
    slotNumber: params.slotNumber,
  };

  if (params.endSlotNumber !== undefined && params.endSlotNumber !== null) queryParams.endSlotNumber = params.endSlotNumber;
  if (params.className) queryParams.className = params.className.trim();
  if (params.recurring !== undefined && params.recurring !== null) queryParams.recurring = params.recurring;
  if (params.recurringUntil) queryParams.recurringUntil = params.recurringUntil;
  if (params.semesterId) queryParams.semesterId = params.semesterId;
  if (params.excludeSlotId !== undefined && params.excludeSlotId !== null) queryParams.excludeSlotId = params.excludeSlotId;

  return apiClient.get('/timetable/available-rooms', { params: queryParams });
};

/**
 * 8. Lấy danh mục ca học / loại tiết (Slot Types)
 */
export const getSlotTypesApi = async (
  semesterId?: number
): Promise<ApiResponse<SlotTypeResponse[]>> => {
  const params: Record<string, any> = {};
  if (semesterId) params.semesterId = semesterId;

  return apiClient.get('/timetable/slot-types', { params });
};

/**
 * 9. Lấy thống kê KPI thời khóa biểu
 */
export const getTimetableStatsApi = async (
  semesterId?: number,
  weekStartDate?: string
): Promise<ApiResponse<TimetableStatsResponse>> => {
  const params: Record<string, any> = {};
  if (semesterId) params.semesterId = semesterId;
  if (weekStartDate) params.weekStartDate = weekStartDate;

  return apiClient.get('/timetable/stats', { params });
};

/**
 * 10. Công bố thời khóa biểu chính thức (Admin only)
 */
export const publishTimetableApi = async (
  semesterId: number
): Promise<ApiResponse<{ semesterId: number; published: boolean }>> => {
  return apiClient.post('/timetable/publish', null, {
    params: { semesterId },
  });
};
