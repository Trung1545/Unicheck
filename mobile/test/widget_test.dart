import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:unicheck_mobile/core/network/api_client.dart';
import 'package:unicheck_mobile/core/routes/app_routes.dart';
import 'package:unicheck_mobile/core/storage/token_storage.dart';
import 'package:unicheck_mobile/feature/auth/controllers/auth_controller.dart';
import 'package:unicheck_mobile/feature/auth/models/auth_tokens.dart';
import 'package:unicheck_mobile/feature/auth/models/user_model.dart';
import 'package:unicheck_mobile/feature/auth/services/auth_api_service.dart';
import 'package:unicheck_mobile/main.dart';

class WidgetTestTokenStorage implements TokenStorage {
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

class WidgetTestAuthApiService extends AuthApiService {
  WidgetTestAuthApiService() : super(apiClient: ApiClient(tokenStorage: WidgetTestTokenStorage()));

  bool shouldFailLogin = false;
  String loginErrorMessage = 'Tên đăng nhập hoặc mật khẩu không chính xác';

  @override
  Future<({UserModel user, AuthTokens tokens})> login({
    required String username,
    required String password,
  }) async {
    if (shouldFailLogin) {
      throw ApiException(message: loginErrorMessage);
    }
    return (
      user: UserModel(
        id: 101,
        code: 'SV2026',
        username: username,
        fullName: 'Nguyễn Văn Sinh Viên',
        email: '$username@unicheck.edu.vn',
        role: 'STUDENT',
      ),
      tokens: const AuthTokens(
        accessToken: 'mock_jwt_access',
        refreshToken: 'mock_uuid_refresh',
        expiresIn: 900,
      ),
    );
  }

  @override
  Future<UserModel> getMe() async {
    return UserModel(
      id: 101,
      code: 'SV2026',
      username: 'student_01',
      fullName: 'Nguyễn Văn Sinh Viên',
      email: 'student01@unicheck.edu.vn',
      role: 'STUDENT',
    );
  }

  @override
  Future<void> logout() async {}
}

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('UniCheck Mobile app smoke test: renders login screen and inputs',
      (WidgetTester tester) async {
    await tester.pumpWidget(const UniCheckMobileApp());
    await tester.pumpAndSettle();

    // Verify brand title and login elements
    expect(find.text('UniCheck'), findsOneWidget);
    expect(find.text('Hệ thống Điểm danh Sinh trắc học Thông minh'), findsOneWidget);
    expect(find.text('Tên đăng nhập / MSSV / Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Đăng Nhập'), findsOneWidget);
  });

  testWidgets('Login validation: empty submission shows error banner',
      (WidgetTester tester) async {
    await tester.pumpWidget(const UniCheckMobileApp());
    await tester.pumpAndSettle();

    // Tap submit button with empty textfields
    final submitButton = find.widgetWithText(ElevatedButton, 'Đăng Nhập');
    expect(submitButton, findsOneWidget);
    await tester.tap(submitButton);
    await tester.pump();

    // Verify error banner is rendered
    expect(find.text('Vui lòng nhập tên đăng nhập và mật khẩu'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('Widget Test (401 Bad Credentials): displays error banner on failed login',
      (WidgetTester tester) async {
    final fakeService = WidgetTestAuthApiService()..shouldFailLogin = true;
    final fakeStorage = WidgetTestTokenStorage();

    // Register controller before pumpWidget
    Get.put<TokenStorage>(fakeStorage);
    Get.put<AuthApiService>(fakeService);
    final controller = Get.put<AuthController>(
      AuthController(authApiService: fakeService, tokenStorage: fakeStorage),
    );

    await tester.pumpWidget(const UniCheckMobileApp());
    await tester.pumpAndSettle();

    final usernameField = find.byType(TextField).at(0);
    final passwordField = find.byType(TextField).at(1);
    final submitButton = find.widgetWithText(ElevatedButton, 'Đăng Nhập');

    await tester.enterText(usernameField, 'wrong_user');
    await tester.enterText(passwordField, 'wrong_pass');
    await tester.tap(submitButton);
    await tester.pump();

    expect(controller.errorMessage.value, equals('Tên đăng nhập hoặc mật khẩu không chính xác'));
    expect(find.text('Tên đăng nhập hoặc mật khẩu không chính xác'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('Widget Test (401 Expired Session): forceLogout displays expired session banner',
      (WidgetTester tester) async {
    await tester.pumpWidget(const UniCheckMobileApp());
    await tester.pumpAndSettle();

    final controller = Get.find<AuthController>();
    controller.forceLogout();
    await tester.pumpAndSettle();

    expect(find.text('Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('Widget Test (403 / Role Mismatch): verifies role guard blocks unauthorized access',
      (WidgetTester tester) async {
    await tester.pumpWidget(const UniCheckMobileApp());
    await tester.pumpAndSettle();

    final controller = Get.find<AuthController>();
    // Student user trying to access admin
    controller.user.value = UserModel(
      id: 101,
      username: 'student_01',
      fullName: 'Sinh Viên',
      email: 'sv@unicheck.edu.vn',
      role: 'STUDENT',
    );

    // Verify student is recognized and not admin
    expect(controller.user.value?.isAdmin, isFalse);
    expect(controller.user.value?.isStudent, isTrue);

    // If navigated to admin, role guard should redirect to student shell
    Get.toNamed(AppRoutes.admin);
    await tester.pumpAndSettle();

    // Expect student shell is rendered, NOT admin shell
    expect(find.text('Sinh Viên (STUDENT)'), findsOneWidget);
    expect(find.text('Quản Trị Hệ Thống (ADMIN)'), findsNothing);
  });
}
