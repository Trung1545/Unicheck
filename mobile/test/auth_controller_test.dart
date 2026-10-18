import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:unicheck_mobile/core/network/api_client.dart';
import 'package:unicheck_mobile/core/storage/token_storage.dart';
import 'package:unicheck_mobile/feature/auth/controllers/auth_controller.dart';
import 'package:unicheck_mobile/feature/auth/models/auth_tokens.dart';
import 'package:unicheck_mobile/feature/auth/models/user_model.dart';
import 'package:unicheck_mobile/feature/auth/services/auth_api_service.dart';

class FakeTokenStorage implements TokenStorage {
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<bool> hasAccessToken() async => accessToken != null && accessToken!.isNotEmpty;
}

class FakeAuthApiService extends AuthApiService {
  FakeAuthApiService() : super(apiClient: ApiClient(tokenStorage: FakeTokenStorage()));

  bool shouldFailLogin = false;
  String loginErrorMessage = 'Tên đăng nhập hoặc mật khẩu không chính xác';
  bool shouldFailGetMe = false;
  bool logoutCalled = false;

  UserModel mockUser = UserModel(
    id: 101,
    code: 'SV2026',
    username: 'student_01',
    fullName: 'Nguyễn Văn Sinh Viên',
    email: 'student01@unicheck.edu.vn',
    role: 'STUDENT',
  );

  AuthTokens mockTokens = const AuthTokens(
    accessToken: 'valid_access_token_jwt',
    refreshToken: 'valid_refresh_token_uuid',
    expiresIn: 900,
  );

  @override
  Future<({UserModel user, AuthTokens tokens})> login({
    required String username,
    required String password,
  }) async {
    if (shouldFailLogin) {
      throw ApiException(message: loginErrorMessage);
    }
    return (user: mockUser, tokens: mockTokens);
  }

  @override
  Future<UserModel> getMe() async {
    if (shouldFailGetMe) {
      throw ApiException(message: 'Phiên làm việc đã hết hạn');
    }
    return mockUser;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthController Unit Tests', () {
    late FakeAuthApiService fakeService;
    late FakeTokenStorage fakeStorage;
    late AuthController controller;

    setUp(() {
      Get.testMode = true;
      fakeService = FakeAuthApiService();
      fakeStorage = FakeTokenStorage();
      controller = AuthController(
        authApiService: fakeService,
        tokenStorage: fakeStorage,
      );
    });

    tearDown(() {
      Get.reset();
    });

    test('Login validation: empty username or password returns false with validation error', () async {
      final success = await controller.login('', '');
      expect(success, isFalse);
      expect(controller.errorMessage.value, contains('Vui lòng nhập tên đăng nhập'));
      expect(controller.isAuthenticated, isFalse);
    });

    test('Login failure: network or credential error sets errorMessage and returns false', () async {
      fakeService.shouldFailLogin = true;
      fakeService.loginErrorMessage = 'Tên đăng nhập hoặc mật khẩu không chính xác';

      final success = await controller.login('student_01', 'WrongPassword');
      expect(success, isFalse);
      expect(controller.errorMessage.value, equals('Tên đăng nhập hoặc mật khẩu không chính xác'));
      expect(controller.isAuthenticated, isFalse);
      expect(await fakeStorage.hasAccessToken(), isFalse);
    });

    test('Login success: stores tokens, sets user model and marks isAuthenticated true', () async {
      final success = await controller.login('student_01', 'Student@123');
      expect(success, isTrue);
      expect(controller.errorMessage.value, isEmpty);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.user.value?.username, equals('student_01'));
      expect(controller.user.value?.role, equals('STUDENT'));
      expect(await fakeStorage.getAccessToken(), equals('valid_access_token_jwt'));
      expect(await fakeStorage.getRefreshToken(), equals('valid_refresh_token_uuid'));
    });

    test('Logout: clears token storage, purges user state and triggers server logout', () async {
      // First log in
      await controller.login('student_01', 'Student@123');
      expect(controller.isAuthenticated, isTrue);

      // Perform logout
      await controller.logout();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.user.value, isNull);
      expect(await fakeStorage.hasAccessToken(), isFalse);
      expect(fakeService.logoutCalled, isTrue);
    });

    test('Restore session: successfully populates user when valid token exists', () async {
      fakeStorage.accessToken = 'existing_valid_token';

      await controller.restoreSession();

      expect(controller.isAuthenticated, isTrue);
      expect(controller.user.value?.id, equals(101));
      expect(controller.user.value?.username, equals('student_01'));
    });

    test('Restore session failure: clears stale token when /me fails', () async {
      fakeStorage.accessToken = 'expired_stale_token';
      fakeService.shouldFailGetMe = true;

      await controller.restoreSession();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.user.value, isNull);
      expect(await fakeStorage.hasAccessToken(), isFalse);
    });
  });
}
