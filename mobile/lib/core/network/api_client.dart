import 'dart:async';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiException implements Exception {
  final String message;
  final String? errorCode;
  final int? statusCode;

  ApiException({
    required this.message,
    this.errorCode,
    this.statusCode,
  });

  @override
  String toString() => message;
}

class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;
  final void Function()? onAuthFailure;

  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  ApiClient({
    Dio? dio,
    required this.tokenStorage,
    this.onAuthFailure,
  }) : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final statusCode = error.response?.statusCode;
          final path = error.requestOptions.path;

          final isAuthEndpoint = path.contains(ApiConstants.login) ||
              path.contains(ApiConstants.refreshToken);

          if (statusCode == 401 && !isAuthEndpoint) {
            final refreshedToken = await _handleTokenRefresh();
            if (refreshedToken != null) {
              try {
                // Retry failed request with new access token
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $refreshedToken';
                final response = await dio.fetch(options);
                return handler.resolve(response);
              } catch (retryError) {
                return handler.reject(error);
              }
            } else {
              // Token refresh failed -> force logout
              await tokenStorage.clearTokens();
              onAuthFailure?.call();
              return handler.reject(error);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _handleTokenRefresh() async {
    if (_isRefreshing) {
      return _refreshCompleter?.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final currentRefreshToken = await tokenStorage.getRefreshToken();
      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        _isRefreshing = false;
        _refreshCompleter?.complete(null);
        return null;
      }

      // Standalone Dio instance to avoid interceptor loop
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await refreshDio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': currentRefreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final newAccessToken = data['token'] as String;
        final newRefreshToken = (data['refreshToken'] ?? currentRefreshToken) as String;

        await tokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        _isRefreshing = false;
        _refreshCompleter?.complete(newAccessToken);
        return newAccessToken;
      }
    } catch (_) {
      // Refresh failed
    }

    _isRefreshing = false;
    _refreshCompleter?.complete(null);
    return null;
  }

  static String extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final data = error.response!.data as Map;
        if (data['message'] != null) {
          return data['message'].toString();
        }
      }
      if (error.response?.statusCode == 401) {
        return 'Tên đăng nhập hoặc mật khẩu không chính xác';
      }
      if (error.response?.statusCode == 403) {
        return 'Bạn không có quyền truy cập';
      }
      if (error.response?.statusCode == 429) {
        return 'Quá nhiều lần thử đăng nhập. Vui lòng thử lại sau 15 phút';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng';
      }
      return 'Lỗi mạng hoặc hệ thống: ${error.message}';
    }
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }

  static String? extractErrorCode(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final data = error.response!.data as Map;
        if (data['errorCode'] != null) {
          return data['errorCode'].toString();
        }
      }
    }
    if (error is ApiException) {
      return error.errorCode;
    }
    return null;
  }
}
