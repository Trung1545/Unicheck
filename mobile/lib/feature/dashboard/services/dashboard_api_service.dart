import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/enrollment_model.dart';
import '../models/timetable_slot_model.dart';

class DashboardApiService {
  final ApiClient apiClient;

  DashboardApiService({required this.apiClient});

  Dio get _dio => apiClient.dio;

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<List<TimetableSlotModel>> getMyTimetable({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = _formatDate(startDate);
      }
      if (endDate != null) {
        queryParams['endDate'] = _formatDate(endDate);
      }

      final response = await _dio.get(
        ApiConstants.timetableMe,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final rawData = response.data;
      final dynamic listData = rawData is Map ? rawData['data'] : null;

      if (listData is List) {
        return listData
            .map((item) =>
                TimetableSlotModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      final msg = ApiClient.extractErrorMessage(e);
      throw ApiException(message: msg);
    }
  }

  Future<List<EnrollmentModel>> getMyEnrollments({
    int? studentId,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (studentId != null) {
        queryParams['studentId'] = studentId;
      }

      final response = await _dio.get(
        ApiConstants.enrollments,
        queryParameters: queryParams,
      );

      final rawData = response.data;
      final dynamic data = rawData is Map ? rawData['data'] : null;

      if (data is Map && data['content'] is List) {
        return (data['content'] as List)
            .map((item) =>
                EnrollmentModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (data is List) {
        return data
            .map((item) =>
                EnrollmentModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      final msg = ApiClient.extractErrorMessage(e);
      throw ApiException(message: msg);
    }
  }
}
