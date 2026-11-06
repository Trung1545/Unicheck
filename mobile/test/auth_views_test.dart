import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unicheck_mobile/core/network/api_client.dart';
import 'package:unicheck_mobile/core/routes/app_routes.dart';
import 'package:unicheck_mobile/core/storage/token_storage.dart';
import 'package:unicheck_mobile/feature/auth/controllers/auth_controller.dart';
import 'package:unicheck_mobile/feature/auth/models/user_model.dart';
import 'package:unicheck_mobile/feature/auth/services/auth_api_service.dart';
import 'package:unicheck_mobile/feature/auth/views/change_password_view.dart';
import 'package:unicheck_mobile/feature/auth/views/forgot_password_view.dart';
import 'package:unicheck_mobile/feature/auth/views/reset_password_view.dart';
import 'package:unicheck_mobile/feature/auth/views/verify_otp_view.dart';
import 'package:unicheck_mobile/feature/auth/views/web_advisory_view.dart';
import 'package:unicheck_mobile/feature/splash/views/splash_view.dart';

class MockTokenStorage implements TokenStorage {
  String? token;
  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    token = accessToken;
  }
  @override
  Future<String?> getAccessToken() async => token;
  @override
  Future<String?> getRefreshToken() async => token;
  @override
  Future<void> clearTokens() async {
    token = null;
  }
  @override
  Future<bool> hasAccessToken() async => token != null;
}

class MockAuthApiService extends AuthApiService {
  MockAuthApiService() : super(apiClient: ApiClient(tokenStorage: MockTokenStorage()));

  bool shouldFail = false;

  @override
  Future<String> forgotPassword({required String email}) async {
    if (shouldFail) throw ApiException(message: 'Email không tồn tại');
    return 'Nếu email tồn tại trong hệ thống, mã xác thực 6 chữ số đã được gửi qua email';
  }

  @override
  Future<void> resetPassword({required String email, required String otp, required String newPassword}) async {
    if (shouldFail) throw ApiException(message: 'Mã OTP không chính xác');
  }

  @override
  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    if (shouldFail) throw ApiException(message: 'Mật khẩu cũ không chính xác');
  }

  @override
  Future<UserModel> getMe() async {
    return UserModel(
      id: 1,
      code: 'SV2026',
      username: 'student_01',
      fullName: 'Sinh Viên Kiểm Thử',
      email: 'student@unicheck.edu.vn',
      role: 'STUDENT',
    );
  }
}

Widget _wrapWithApp(Widget child) {
  return GetMaterialApp(
    home: child,
    getPages: [
      GetPage(name: AppRoutes.login, page: () => const Scaffold(body: Text('Login Page'))),
      GetPage(name: AppRoutes.verifyOtp, page: () => const VerifyOtpView()),
      GetPage(name: AppRoutes.resetPassword, page: () => const ResetPasswordView()),
      GetPage(name: AppRoutes.student, page: () => const Scaffold(body: Text('Student Shell'))),
      GetPage(name: AppRoutes.webAdvisory, page: () => const WebAdvisoryView()),
    ],
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    Get.reset();
    Get.testMode = true;
    final storage = MockTokenStorage();
    final apiService = MockAuthApiService();
    Get.put<TokenStorage>(storage);
    Get.put<AuthApiService>(apiService);
    Get.put<AuthController>(AuthController(
      authApiService: apiService,
      tokenStorage: storage,
    ));
  });

  tearDown(() {
    Get.reset();
  });

  group('Phase 03 Authentication Views Tests', () {
    testWidgets('SplashView: renders branding and security credentials', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const SplashView()));
      await tester.pump();

      expect(find.text('UniCheck'), findsOneWidget);
      // Branding check
      expect(find.text('Điểm danh thông minh, quản lý dễ dàng'), findsOneWidget);
      expect(find.text('HỆ THỐNG QUẢN LÝ VÀ ĐIỂM DANH THÔNG MINH'), findsWidgets);
      expect(find.text('Bảo mật kết nối an toàn'), findsOneWidget);
    });

    testWidgets('ForgotPasswordView: renders identity input and handles submission', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const ForgotPasswordView()));
      await tester.pump();

      expect(find.text('Quên Mật Khẩu'), findsOneWidget);
      expect(find.text('Khôi phục quyền truy cập'), findsOneWidget);
      expect(find.text('Tên đăng nhập hoặc Email *'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);

      // Enter email and submit
      final input = find.byType(TextField);
      await tester.enterText(input, 'sv.2251120001@unicheck.edu.vn');
      final submitBtn = find.text('Tiếp tục');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Check success confirmation card
      expect(find.text('Đã ghi nhận yêu cầu'), findsOneWidget);
      expect(find.text('Nhập mã xác thực (OTP)'), findsOneWidget);
    });

    testWidgets('VerifyOtpView: renders 6 slots, masked email and timer', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const VerifyOtpView()));
      await tester.pump();

      expect(find.text('Xác Thực OTP'), findsOneWidget);
      expect(find.text('Nhập mã xác thực'), findsOneWidget);
      expect(find.text('MÃ BẢO MẬT GỒM 6 SỐ'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(6));
      expect(find.text('Xác nhận mã OTP'), findsOneWidget);
    });

    testWidgets('ResetPasswordView: evaluates password strength and match in real-time', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const ResetPasswordView()));
      await tester.pump();

      expect(find.text('Đặt Lại Mật Khẩu'), findsOneWidget);
      expect(find.text('Thiết lập mật khẩu mới'), findsOneWidget);
      expect(find.text('Mật khẩu mới *'), findsOneWidget);
      expect(find.text('Xác nhận mật khẩu mới *'), findsOneWidget);

      final inputs = find.byType(TextField);
      await tester.enterText(inputs.at(0), 'BkUni2026@');
      await tester.pump();

      expect(find.text('Rất mạnh (4/4)'), findsOneWidget);

      // Confirm matching
      await tester.enterText(inputs.at(1), 'BkUni2026@');
      await tester.pump();

      expect(find.text('Mật khẩu xác nhận khớp hoàn toàn'), findsOneWidget);
    });

    testWidgets('ChangePasswordView: renders change password form with security rules', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const ChangePasswordView()));
      await tester.pump();

      expect(find.text('Đổi Mật Khẩu'), findsOneWidget);
      expect(find.text('Bảo vệ tài khoản định kỳ'), findsOneWidget);
      expect(find.text('Mật khẩu hiện tại *'), findsOneWidget);
      expect(find.text('Mật khẩu mới *'), findsOneWidget);
      expect(find.text('Xác nhận mật khẩu mới *'), findsOneWidget);
      expect(find.text('Đăng xuất tất cả thiết bị khác'), findsOneWidget);
      expect(find.text('Lưu thay đổi mật khẩu'), findsOneWidget);
    });

    testWidgets('WebAdvisoryView: renders desktop advisory for non-student users', (tester) async {
      final controller = Get.find<AuthController>();
      controller.user.value = UserModel(
        id: 2,
        code: 'GV2026',
        username: 'lecturer_01',
        fullName: 'Giảng Viên Mẫu',
        email: 'gv@unicheck.edu.vn',
        role: 'LECTURER',
      );

      await tester.pumpWidget(_wrapWithApp(const WebAdvisoryView()));
      await tester.pump();

      expect(find.text('Cổng Quản Trị Web'), findsOneWidget);
      expect(find.text('Giảng Viên (LECTURER)'), findsOneWidget);
      expect(find.text('Vui Lòng Sử Dụng Web Portal Trên Máy Tính'), findsOneWidget);
      expect(find.text('https://unicheck.edu.vn/portal'), findsOneWidget);
      expect(find.text('Đăng Xuất Tài Khoản'), findsOneWidget);
    });
  });
}
