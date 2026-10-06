import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'feature/auth/bindings/auth_binding.dart';
import 'feature/auth/views/login_view.dart';
import 'feature/attendance/views/face_checkin_view.dart';

void main() {
  runApp(const UniCheckMobileApp());
}

class UniCheckMobileApp extends StatelessWidget {
  const UniCheckMobileApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'UniCheck Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/login',
      initialBinding: AuthBinding(),
      getPages: [
        GetPage(
          name: '/login',
          page: () => LoginView(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/check-in',
          page: () => FaceCheckinView(),
        ),
      ],
    );
  }
}
