import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unicheck_mobile/core/constants/api_constants.dart';
import 'package:unicheck_mobile/core/network/api_client.dart';
import 'auth_controller_test.dart';

class MockHttpAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;
  int statusCode = 200;
  String responseBody = '{"success":true,"data":{}}';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      responseBody,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ApiClient Error Extraction and Interceptor Tests', () {
    test('extractErrorMessage parses custom message from backend response', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
          data: {
            'success': false,
            'message': 'Dữ liệu gửi lên không hợp lệ',
            'errorCode': 'ERR_1001',
          },
        ),
      );

      final msg = ApiClient.extractErrorMessage(dioError);
      expect(msg, equals('Dữ liệu gửi lên không hợp lệ'));
    });

    test('extractErrorMessage maps standard HTTP status codes when no body message', () {
      final err401 = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        ),
      );
      expect(ApiClient.extractErrorMessage(err401), equals('Tên đăng nhập hoặc mật khẩu không chính xác'));

      final err403 = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 403,
        ),
      );
      expect(ApiClient.extractErrorMessage(err403), equals('Bạn không có quyền truy cập'));

      final err429 = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 429,
        ),
      );
      expect(ApiClient.extractErrorMessage(err429), contains('Quá nhiều lần thử'));
    });

    test('extractErrorMessage maps connection timeouts to friendly message', () {
      final timeoutErr = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(ApiClient.extractErrorMessage(timeoutErr), contains('Không thể kết nối đến máy chủ'));
    });

    test('Request interceptor injects Bearer token into Authorization header', () async {
      final fakeStorage = FakeTokenStorage();
      fakeStorage.accessToken = 'test_injected_jwt_token';

      final client = ApiClient(tokenStorage: fakeStorage);
      final mockAdapter = MockHttpAdapter();
      client.dio.httpClientAdapter = mockAdapter;

      await client.dio.get('/auth/me');

      expect(mockAdapter.lastOptions?.headers['Authorization'], equals('Bearer test_injected_jwt_token'));
    });

    test('401 on login endpoint does not trigger token refresh or auth failure callback', () async {
      final fakeStorage = FakeTokenStorage();
      bool authFailureCalled = false;

      final client = ApiClient(
        tokenStorage: fakeStorage,
        onAuthFailure: () {
          authFailureCalled = true;
        },
      );
      final mockAdapter = MockHttpAdapter()
        ..statusCode = 401
        ..responseBody = '{"success":false,"message":"Invalid credentials","errorCode":"ERR_2002"}';
      client.dio.httpClientAdapter = mockAdapter;

      try {
        await client.dio.post(ApiConstants.login, data: {'username': 'u', 'password': 'p'});
      } catch (_) {
        // Expected DioException
      }

      expect(authFailureCalled, isFalse);
    });
  });
}
