import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/role_guard.dart';
import 'core/theme/app_theme.dart';
import 'feature/attendance/bindings/attendance_binding.dart';
import 'feature/attendance/views/attendance_eligibility_view.dart';
import 'feature/attendance/views/attendance_failure_view.dart';
import 'feature/attendance/views/attendance_success_view.dart';
import 'feature/attendance/views/face_checkin_view.dart';
import 'feature/attendance/views/face_enrollment_result_view.dart';
import 'feature/attendance/views/face_enrollment_view.dart';
import 'feature/attendance/views/qr_scanner_view.dart';
import 'feature/attendance/views/select_attendance_session_view.dart';
import 'feature/auth/bindings/auth_binding.dart';
import 'feature/dashboard/bindings/dashboard_binding.dart';
import 'feature/auth/views/change_password_view.dart';
import 'feature/auth/views/forgot_password_view.dart';
import 'feature/auth/views/login_view.dart';
import 'feature/auth/views/reset_password_view.dart';
import 'feature/auth/views/verify_otp_view.dart';
import 'feature/auth/views/web_advisory_view.dart';
import 'feature/shell/views/admin_shell_view.dart';
import 'feature/shell/views/lecturer_shell_view.dart';
import 'feature/shell/views/student_shell_view.dart';
import 'feature/splash/views/splash_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UniCheckMobileApp());
}

class UniCheckMobileApp extends StatelessWidget {
  final String initialRoute;

  const UniCheckMobileApp({
    super.key,
    this.initialRoute = AppRoutes.login,
  });

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'UniCheck Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: initialRoute,
      initialBinding: AuthBinding(),
      getPages: [
        GetPage(
          name: AppRoutes.splash,
          page: () => const SplashView(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: AppRoutes.login,
          page: () => const LoginView(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: AppRoutes.forgotPassword,
          page: () => const ForgotPasswordView(),
        ),
        GetPage(
          name: AppRoutes.verifyOtp,
          page: () => const VerifyOtpView(),
        ),
        GetPage(
          name: AppRoutes.resetPassword,
          page: () => const ResetPasswordView(),
        ),
        GetPage(
          name: AppRoutes.changePassword,
          page: () => const ChangePasswordView(),
          middlewares: [
            AuthGuard(),
          ],
        ),
        GetPage(
          name: AppRoutes.webAdvisory,
          page: () => const WebAdvisoryView(),
        ),
        GetPage(
          name: AppRoutes.admin,
          page: () => const AdminShellView(),
          middlewares: [
            AuthGuard(),
            RoleGuard(allowedRoles: ['ADMIN']),
          ],
        ),
        GetPage(
          name: AppRoutes.lecturer,
          page: () => const LecturerShellView(),
          middlewares: [
            AuthGuard(),
            RoleGuard(allowedRoles: ['LECTURER']),
          ],
        ),
        GetPage(
          name: AppRoutes.student,
          page: () => const StudentShellView(),
          binding: DashboardBinding(),
          middlewares: [
            AuthGuard(),
            RoleGuard(allowedRoles: ['STUDENT']),
          ],
        ),
        GetPage(
          name: AppRoutes.checkIn,
          page: () => const FaceCheckinView(),
          binding: AttendanceBinding(),
          middlewares: [
            AuthGuard(),
            RoleGuard(allowedRoles: ['STUDENT', 'ADMIN']),
          ],
        ),
        GetPage(
          name: AppRoutes.faceEnrollment,
          page: () => const FaceEnrollmentView(),
          middlewares: [
            AuthGuard(),
            RoleGuard(allowedRoles: ['STUDENT', 'ADMIN']),
          ],
        ),
        GetPage(
          name: AppRoutes.faceEnrollmentResult,
          page: () => const FaceEnrollmentResultView(),
          middlewares: [
            AuthGuard(),
            RoleGuard(allowedRoles: ['STUDENT', 'ADMIN']),
          ],
        ),
        GetPage(
          name: AppRoutes.selectSession,
          page: () => const SelectAttendanceSessionView(),
          binding: AttendanceBinding(),
          middlewares: [
            AuthGuard(),
            RoleGuard(allowedRoles: ['STUDENT', 'ADMIN']),
          ],
        ),
        GetPage(
          name: AppRoutes.qrScanner,
          page: () => const QrScannerView(),
          binding: AttendanceBinding(),
          middlewares: [
            AuthGuard(),
            RoleGuard(allowedRoles: ['STUDENT', 'ADMIN']),
          ],
        ),
        GetPage(
          name: AppRoutes.attendanceEligibility,
          page: () => const AttendanceEligibilityView(),
          binding: AttendanceBinding(),
          middlewares: [
            AuthGuard(),
            RoleGuard(allowedRoles: ['STUDENT', 'ADMIN']),
          ],
        ),
        GetPage(
          name: AppRoutes.attendanceSuccess,
          page: () => const AttendanceSuccessView(),
          binding: AttendanceBinding(),
          middlewares: [
            AuthGuard(),
            RoleGuard(allowedRoles: ['STUDENT', 'ADMIN']),
          ],
        ),
        GetPage(
          name: AppRoutes.attendanceFailure,
          page: () => const AttendanceFailureView(),
          binding: AttendanceBinding(),
          middlewares: [
            AuthGuard(),
            RoleGuard(allowedRoles: ['STUDENT', 'ADMIN']),
          ],
        ),
      ],
    );
  }
}
