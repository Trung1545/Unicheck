import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/attendance_checkin_request_model.dart';
import '../models/attendance_checkin_response_model.dart';
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
      return FaceEnrollmentResultModel(
        success: response.statusCode == 200,
        status: 'REGISTERED',
        registeredAt: DateTime.now(),
      );
    } catch (e) {
      final msg = ApiClient.extractErrorMessage(e);
      throw ApiException(message: msg);
    }
  }

  /// Gửi kết quả xác thực sinh trắc học và điểm danh sinh viên
  /// Lưu ý: Backend Spring Boot đang trong tiến độ hoàn thiện TASK-06 cho endpoint check-in.
  /// Method này gửi payload chuẩn và cung cấp chẩn đoán lỗi minh bạch khi API chưa mở.
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
      return AttendanceCheckinResponseModel(
        status: 'PRESENT',
        method: 'FACE_QR',
        checkInTime: DateTime.now(),
      );
    } on DioException catch (dioErr) {
      final statusCode = dioErr.response?.statusCode;
      if (statusCode == 404 || statusCode == 501) {
        throw ApiException(
          message:
              'Máy chủ học vụ chưa mở cổng tiếp nhận điểm danh trực tuyến (TASK-06 Blocker: HTTP $statusCode).',
          statusCode: statusCode,
        );
      }
      final msg = ApiClient.extractErrorMessage(dioErr);
      throw ApiException(message: msg, statusCode: statusCode);
    } catch (e) {
      final msg = ApiClient.extractErrorMessage(e);
      throw ApiException(message: msg);
    }
  }
}
