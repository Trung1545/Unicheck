import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:unicheck_mobile/core/routes/app_routes.dart';
import 'package:unicheck_mobile/core/routes/role_guard.dart';
import 'package:unicheck_mobile/feature/auth/controllers/auth_controller.dart';
import 'package:unicheck_mobile/feature/auth/models/user_model.dart';
import 'auth_controller_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Route Guards Tests (AuthGuard & RoleGuard)', () {
    late AuthController authController;

    setUp(() {
      Get.testMode = true;
      authController = AuthController(
        authApiService: FakeAuthApiService(),
        tokenStorage: FakeTokenStorage(),
      );
      Get.put<AuthController>(authController);
    });

    tearDown(() {
      Get.reset();
    });

    test('AuthGuard: redirects to /login when user is unauthenticated', () {
      final guard = AuthGuard();
      final redirect = guard.redirect('/admin');

      expect(redirect, isNotNull);
      expect(redirect?.name, equals(AppRoutes.login));
    });

    test('AuthGuard: allows access when user is authenticated', () {
      authController.user.value = UserModel(
        id: 1,
        username: 'test_user',
        fullName: 'Test User',
        email: 'test@unicheck.edu.vn',
        role: 'STUDENT',
      );

      final guard = AuthGuard();
      final redirect = guard.redirect('/student');

      expect(redirect, isNull);
    });

    test('RoleGuard: allows access when user role matches allowed roles', () {
      authController.user.value = UserModel(
        id: 1,
        username: 'admin_user',
        fullName: 'Admin User',
        email: 'admin@unicheck.edu.vn',
        role: 'ADMIN',
      );

      final guard = RoleGuard(allowedRoles: ['ADMIN']);
      final redirect = guard.redirect('/admin');

      expect(redirect, isNull);
    });

    test('RoleGuard: redirects student away from admin route to /student', () {
      authController.user.value = UserModel(
        id: 1,
        username: 'student_user',
        fullName: 'Student User',
        email: 'student@unicheck.edu.vn',
        role: 'STUDENT',
      );

      final guard = RoleGuard(allowedRoles: ['ADMIN']);
      final redirect = guard.redirect('/admin');

      expect(redirect, isNotNull);
      expect(redirect?.name, equals(AppRoutes.student));
    });

    test('RoleGuard: redirects lecturer away from admin route to /lecturer', () {
      authController.user.value = UserModel(
        id: 2,
        username: 'lecturer_user',
        fullName: 'Lecturer User',
        email: 'lecturer@unicheck.edu.vn',
        role: 'LECTURER',
      );

      final guard = RoleGuard(allowedRoles: ['ADMIN']);
      final redirect = guard.redirect('/admin');

      expect(redirect, isNotNull);
      expect(redirect?.name, equals(AppRoutes.lecturer));
    });
  });
}
