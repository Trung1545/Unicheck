// ==============================================================================
// UniCheck - Face-ID Biometric API Client Services
// F-17 & Google Stitch a17db05b39144990b49bee366c1e3b43
// ==============================================================================

import apiClient from '../api-client/axios-instance';
import {
  ApiResponse,
  FaceEnrollmentResponse,
  FaceRegistrationRequest,
  FaceStatusResponse,
} from '../types/api';

/**
 * 1. Đăng ký / Thu thập dữ liệu Face-ID cho sinh viên
 * POST /api/v1/attendance/register-face
 */
export const registerFaceApi = async (
  data: FaceRegistrationRequest
): Promise<ApiResponse<FaceEnrollmentResponse>> => {
  return apiClient.post('/attendance/register-face', data);
};

/**
 * 2. Lấy trạng thái đăng ký Face-ID của tài khoản hiện tại
 * GET /api/v1/attendance/face-status
 */
export const getFaceStatusApi = async (): Promise<ApiResponse<FaceStatusResponse>> => {
  return apiClient.get('/attendance/face-status');
};

/**
 * 3. Xóa dữ liệu Face-ID để đăng ký lại từ đầu
 * DELETE /api/v1/attendance/face-data
 */
export const resetFaceDataApi = async (): Promise<ApiResponse<void>> => {
  return apiClient.delete('/attendance/face-data');
};

/**
 * 4. Dành cho Admin tra cứu trạng thái Face-ID của sinh viên theo ID
 * GET /api/v1/attendance/face-status/user/:userId
 */
export const getStudentFaceStatusAdminApi = async (
  userId: number
): Promise<ApiResponse<FaceStatusResponse>> => {
  return apiClient.get(`/attendance/face-status/user/${userId}`);
};
