import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_tokens.dart';
import '../models/user_model.dart';

class AuthApiService {
  final ApiClient apiClient;

  AuthApiService({required this.apiClient});

  Dio get _dio => apiClient.dio;

  Future<({UserModel user, AuthTokens tokens})> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final tokens = AuthTokens.fromJson(data);
      final user = UserModel.fromJson(data);

      return (user: user, tokens: tokens);
    } catch (e) {
      final msg = ApiClient.extractErrorMessage(e);
      throw ApiException(message: msg);
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      final data = response.data['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } catch (e) {
      final msg = ApiClient.extractErrorMessage(e);
      throw ApiException(message: msg);
    }
  }

  Future<AuthTokens> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return AuthTokens.fromJson(data);
    } catch (e) {
      final msg = ApiClient.extractErrorMessage(e);
      throw ApiException(message: msg);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } catch (_) {
      // Best-effort server logout
    }
  }

  Future<String> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
      final message = response.data['message'] as String? ??
          'Nếu email tồn tại trong hệ thống, mã xác thực 6 chữ số đã được gửi qua email';
      return message;
    } catch (e) {
      final msg = ApiClient.extractErrorMessage(e);
      throw ApiException(message: msg);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        ApiConstants.resetPassword,
        data: {
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      final msg = ApiClient.extractErrorMessage(e);
      throw ApiException(message: msg);
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        ApiConstants.changePassword,
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      final msg = ApiClient.extractErrorMessage(e);
      throw ApiException(message: msg);
    }
  }
}
