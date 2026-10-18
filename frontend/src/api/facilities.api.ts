// ==============================================================================
// UniCheck - Facilities & Wi-Fi Access Points API Client (TASK-02C - F-13)
// Interfacing with Spring Boot FacilityController (/api/v1/facilities)
// ==============================================================================

import apiClient from '../api-client/axios-instance';
import {
  ApiResponse,
  PageResponse,
  RoomResponse,
  RoomDetailResponse,
  RoomCreateRequest,
  RoomUpdateRequest,
  RoomQueryParams,
  WifiAccessPointResponse,
  WifiAccessPointCreateRequest,
  WifiAccessPointUpdateRequest,
  WifiAccessPointQueryParams,
  AssignWifiApRequest,
  RoomWifiAccessPointResponse,
  FacilityStatsResponse,
} from '../types/api';

// =============================================================================
// 1. Classrooms (Rooms) API
// =============================================================================

/**
 * Lấy danh sách phòng học có phân trang, tìm kiếm và lọc
 */
export const getRoomsApi = async (
  params?: RoomQueryParams
): Promise<ApiResponse<PageResponse<RoomResponse>>> => {
  const queryParams: Record<string, any> = {};

  if (params?.search && params.search.trim()) {
    queryParams.search = params.search.trim();
  }
  if (params?.building && params.building.trim()) {
    queryParams.building = params.building.trim();
  }
  if (params?.type) {
    queryParams.type = params.type;
  }
  if (params?.status) {
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

  return apiClient.get('/facilities/rooms', { params: queryParams });
};

/**
 * Lấy chi tiết phòng học theo ID
 */
export const getRoomByIdApi = async (
  id: number
): Promise<ApiResponse<RoomDetailResponse>> => {
  return apiClient.get(`/facilities/rooms/${id}`);
};

/**
 * Tạo mới phòng học
 */
export const createRoomApi = async (
  request: RoomCreateRequest
): Promise<ApiResponse<RoomResponse>> => {
  return apiClient.post('/facilities/rooms', request);
};

/**
 * Cập nhật thông tin phòng học
 */
export const updateRoomApi = async (
  id: number,
  request: RoomUpdateRequest
): Promise<ApiResponse<RoomResponse>> => {
  return apiClient.put(`/facilities/rooms/${id}`, request);
};

/**
 * Xóa phòng học
 */
export const deleteRoomApi = async (
  id: number
): Promise<ApiResponse<void>> => {
  return apiClient.delete(`/facilities/rooms/${id}`);
};

/**
 * Kiểm tra tính khả dụng của mã phòng học
 */
export const checkRoomCodeApi = async (
  code: string
): Promise<ApiResponse<{ available: boolean }>> => {
  return apiClient.get('/facilities/rooms/check-code', { params: { code } });
};

/**
 * Lấy danh sách tên tòa nhà phục vụ bộ lọc
 */
export const getBuildingsApi = async (): Promise<ApiResponse<string[]>> => {
  return apiClient.get('/facilities/rooms/buildings');
};

/**
 * Lấy chỉ số thống kê cơ sở vật chất (4 KPI cards)
 */
export const getFacilityStatsApi = async (): Promise<ApiResponse<FacilityStatsResponse>> => {
  return apiClient.get('/facilities/rooms/stats');
};

// =============================================================================
// 2. Wi-Fi Access Points API
// =============================================================================

/**
 * Lấy danh sách Wi-Fi AP có phân trang, tìm kiếm và lọc
 */
export const getWifiAccessPointsApi = async (
  params?: WifiAccessPointQueryParams
): Promise<ApiResponse<PageResponse<WifiAccessPointResponse>>> => {
  const queryParams: Record<string, any> = {};

  if (params?.search && params.search.trim()) {
    queryParams.search = params.search.trim();
  }
  if (params?.status) {
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

  return apiClient.get('/facilities/wifi-ap', { params: queryParams });
};

/**
 * Lấy thông tin Wi-Fi AP theo ID
 */
export const getWifiAccessPointByIdApi = async (
  id: number
): Promise<ApiResponse<WifiAccessPointResponse>> => {
  return apiClient.get(`/facilities/wifi-ap/${id}`);
};

/**
 * Thêm mới Wi-Fi AP
 */
export const createWifiAccessPointApi = async (
  request: WifiAccessPointCreateRequest
): Promise<ApiResponse<WifiAccessPointResponse>> => {
  return apiClient.post('/facilities/wifi-ap', request);
};

/**
 * Cập nhật Wi-Fi AP
 */
export const updateWifiAccessPointApi = async (
  id: number,
  request: WifiAccessPointUpdateRequest
): Promise<ApiResponse<WifiAccessPointResponse>> => {
  return apiClient.put(`/facilities/wifi-ap/${id}`, request);
};

/**
 * Xóa Wi-Fi AP
 */
export const deleteWifiAccessPointApi = async (
  id: number
): Promise<ApiResponse<void>> => {
  return apiClient.delete(`/facilities/wifi-ap/${id}`);
};

/**
 * Kiểm tra tính khả dụng của địa chỉ MAC / BSSID
 */
export const checkBssidApi = async (
  bssid: string
): Promise<ApiResponse<{ available: boolean }>> => {
  return apiClient.get('/facilities/wifi-ap/check-bssid', { params: { bssid } });
};

// =============================================================================
// 3. Room - Wi-Fi AP Mapping API
// =============================================================================

/**
 * Lấy danh sách Wi-Fi AP gán cho một phòng
 */
export const getRoomWifiApsApi = async (
  roomId: number
): Promise<ApiResponse<RoomWifiAccessPointResponse[]>> => {
  return apiClient.get(`/facilities/rooms/${roomId}/wifi-ap`);
};

/**
 * Gán Wi-Fi AP vào phòng học
 */
export const assignWifiApToRoomApi = async (
  roomId: number,
  request: AssignWifiApRequest
): Promise<ApiResponse<RoomWifiAccessPointResponse>> => {
  return apiClient.post(`/facilities/rooms/${roomId}/wifi-ap`, request);
};

/**
 * Hủy liên kết Wi-Fi AP khỏi phòng học
 */
export const unassignWifiApFromRoomApi = async (
  roomId: number,
  accessPointId: number
): Promise<ApiResponse<void>> => {
  return apiClient.delete(`/facilities/rooms/${roomId}/wifi-ap/${accessPointId}`);
};
