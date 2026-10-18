import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../feature/auth/controllers/auth_controller.dart';
import 'app_routes.dart';

class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<AuthController>()) {
      return const RouteSettings(name: AppRoutes.login);
    }
    final authController = Get.find<AuthController>();
    if (!authController.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}

class RoleGuard extends GetMiddleware {
  final List<String> allowedRoles;

  RoleGuard({required this.allowedRoles});

  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<AuthController>()) {
      return const RouteSettings(name: AppRoutes.login);
    }
    final authController = Get.find<AuthController>();
    final user = authController.user.value;

    if (user == null) {
      return const RouteSettings(name: AppRoutes.login);
    }

    final userRole = user.role.toUpperCase();
    if (allowedRoles.map((r) => r.toUpperCase()).contains(userRole)) {
      return null;
    }

    // Role mismatch -> redirect to appropriate home shell
    if (user.isAdmin) {
      return const RouteSettings(name: AppRoutes.admin);
    } else if (user.isLecturer) {
      return const RouteSettings(name: AppRoutes.lecturer);
    } else {
      return const RouteSettings(name: AppRoutes.student);
    }
  }
}
