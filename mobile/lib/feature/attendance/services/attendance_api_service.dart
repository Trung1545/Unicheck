import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/attendance_checkin_request_model.dart';
import '../models/attendance_checkin_response_model.dart';
import '../models/attendance_recheck_model.dart';
import '../models/face_enrollment_result_model.dart';
import '../models/face_status_model.dart';
import '../models/room_wifi_ap_model.dart';

class AttendanceApiService {
  final ApiClient apiClient;

  AttendanceApiService({required this.apiClient});

  Dio get _dio => apiClient.dio;

  /// Fetches registered Wi-Fi Access Points for a given room ID
  Future<List<RoomWifiAccessPointModel>> getRoomWifiAccessPoints(int roomId) async {
    try {
      final response = await _dio.get(ApiConstants.roomWifiAps(roomId));
      final rawData = response.data;
      final dynamic listData = rawData is Map ? rawData['data'] : null;

      if (listData is List) {
        return listData
            .map((item) =>
                RoomWifiAccessPointModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      final msg = ApiClient.extractErrorMessage(e);
      throw ApiException(message: msg);
    }
  }

  /// Tra cứu trạng thái đăng ký Face-ID của sinh viên hiện tại
  Future<FaceStatusModel> getFaceStatus() async {
    try {
      final response = await _dio.get(ApiConstants.faceStatus);
      final rawData = response.data;
      final dynamic objData = rawData is Map ? rawData['data'] : null;

      if (objData is Map<String, dynamic>) {
        return FaceStatusModel.fromJson(objData);
      }
      return const FaceStatusModel();
    } catch (e) {
      final msg = ApiClient.extractErrorMessage(e);
      throw ApiException(message: msg);
    }
  }

  /// Đăng ký bộ 3 mẫu khuôn mặt sinh trắc học lên máy chủ (F-17)
  Future<FaceEnrollmentResultModel> registerFace({
    required String primaryImageBase64,
    required List<Map<String, String>> samples,
    bool isReEnrollment = true,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.registerFace,
        data: {
          'imageBase64': primaryImageBase64,
          'samples': samples,
          'isReEnrollment': isReEnrollment,
        },
      );

      final rawData = response.data;
      final dynamic objData = rawData is Map ? rawData['data'] : null;
      if (objData is Map<String, dynamic>) {
        return FaceEnrollmentResultModel.fromJson(objData);
      }
      throw ApiException(
        message: 'Dữ liệu phản hồi đăng ký từ máy chủ không hợp lệ',
        errorCode: 'ERR_INVALID_RESPONSE',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      final msg = ApiClient.extractErrorMessage(e);
      final code = ApiClient.extractErrorCode(e);
      throw ApiException(message: msg, errorCode: code);
    }
  }

  /// Gửi kết quả xác thực sinh trắc học và điểm danh sinh viên
  Future<AttendanceCheckinResponseModel> checkInFace(
      AttendanceCheckinRequestModel request) async {
    try {
      final response = await _dio.post(
        ApiConstants.checkInFace,
        data: request.toJson(),
      );

      final rawData = response.data;
      final dynamic objData = rawData is Map ? rawData['data'] : null;
      if (objData is Map<String, dynamic>) {
        return AttendanceCheckinResponseModel.fromJson(objData);
      }
      throw ApiException(
        message: 'Dữ liệu phản hồi điểm danh từ máy chủ không hợp lệ',
        errorCode: 'ERR_INVALID_RESPONSE',
      );
    } on DioException catch (dioErr) {
      final statusCode = dioErr.response?.statusCode;
      final msg = ApiClient.extractErrorMessage(dioErr);
      final code = ApiClient.extractErrorCode(dioErr);
      throw ApiException(message: msg, errorCode: code, statusCode: statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      final msg = ApiClient.extractErrorMessage(e);
      final code = ApiClient.extractErrorCode(e);
      throw ApiException(message: msg, errorCode: code);
    }
  }

  /// Xác thực mã QR (Dynamic hoặc Static Test) với Backend qua API /attendance/qr/validate
  Future<Map<String, dynamic>> validateQrToken({
    required String qrToken,
    required int sessionId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.validateQr,
        data: {
          'qrToken': qrToken,
          'sessionId': sessionId,
        },
      );
      final rawData = response.data;
      final dynamic objData = rawData is Map ? rawData['data'] : null;
      if (objData is Map<String, dynamic>) {
        return objData;
      }
      return {'valid': response.statusCode == 200};
    } catch (e) {
      final msg = ApiClient.extractErrorMessage(e);
      throw ApiException(message: msg);
    }
  }

  /// Xác thực mã OTP điểm danh 6 chữ số với Backend qua API /attendance/otp/validate
  Future<Map<String, dynamic>> validateOtp({
    required String otpCode,
    int? sessionId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.validateOtp,
        data: {
          'otpCode': otpCode.trim(),
          if (sessionId != null) 'sessionId': sessionId,
        },
      );
      final rawData = response.data;
      final dynamic objData = rawData is Map ? rawData['data'] : null;
      if (objData is Map<String, dynamic>) {
        return objData;
      }
      return {'valid': response.statusCode == 200};
    } on DioException catch (dioErr) {
      final msg = ApiClient.extractErrorMessage(dioErr);
      final code = ApiClient.extractErrorCode(dioErr);
      throw ApiException(message: msg, errorCode: code, statusCode: dioErr.response?.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      final msg = ApiClient.extractErrorMessage(e);
      final code = ApiClient.extractErrorCode(e);
      throw ApiException(message: msg, errorCode: code);
    }
  }

  /// Tra cứu trạng thái phiên điểm danh từ Backend: /attendance/sessions/{sessionId}/status
  Future<Map<String, dynamic>> getSessionStatus(int sessionId) async {
    try {
      final response = await _dio.get(ApiConstants.sessionStatus(sessionId));
      final rawData = response.data;
      final dynamic objData = rawData is Map ? rawData['data'] : null;
      if (objData is Map<String, dynamic>) {
        return objData;
      }
      return {'status': 'UNKNOWN', 'isOpen': false};
    } catch (e) {
      final msg = ApiClient.extractErrorMessage(e);
      throw ApiException(message: msg);
    }
  }

  /// Lấy danh sách yêu cầu điểm danh lại đang chờ của sinh viên (PENDING)
  Future<List<AttendanceRecheckModel>> getPendingRecheckRequests() async {
    try {
      final response = await _dio.get(ApiConstants.pendingRechecks);
      final rawData = response.data;
      final dynamic listData = rawData is Map ? rawData['data'] : null;

      if (listData is List) {
        return listData
            .map((item) =>
                AttendanceRecheckModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      final msg = ApiClient.extractErrorMessage(e);
      throw ApiException(message: msg);
    }
  }

  /// Lấy chi tiết một yêu cầu điểm danh lại
  Future<AttendanceRecheckModel> getRecheckRequestDetails(int requestId) async {
    try {
      final response = await _dio.get(ApiConstants.recheckDetails(requestId));
      final rawData = response.data;
      final dynamic objData = rawData is Map ? rawData['data'] : null;

      if (objData is Map<String, dynamic>) {
        return AttendanceRecheckModel.fromJson(objData);
      }
      throw ApiException(message: 'Dữ liệu yêu cầu điểm danh lại không hợp lệ');
    } catch (e) {
      final msg = ApiClient.extractErrorMessage(e);
      throw ApiException(message: msg);
    }
  }
}
