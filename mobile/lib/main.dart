import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/role_guard.dart';
import 'core/theme/app_theme.dart';
import 'feature/attendance/views/face_checkin_view.dart';
import 'feature/attendance/views/face_enrollment_view.dart';
import 'feature/auth/bindings/auth_binding.dart';
import 'feature/auth/views/login_view.dart';
import 'feature/shell/views/admin_shell_view.dart';
import 'feature/shell/views/lecturer_shell_view.dart';
import 'feature/shell/views/student_shell_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UniCheckMobileApp());
}

class UniCheckMobileApp extends StatelessWidget {
  const UniCheckMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'UniCheck Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.login,
      initialBinding: AuthBinding(),
      getPages: [
        GetPage(
          name: AppRoutes.login,
          page: () => LoginView(),
          binding: AuthBinding(),
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
          middlewares: [
            AuthGuard(),
            RoleGuard(allowedRoles: ['STUDENT']),
          ],
        ),
        GetPage(
          name: AppRoutes.checkIn,
          page: () => FaceCheckinView(),
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
      ],
    );
  }
}
