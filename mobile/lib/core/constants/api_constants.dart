import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api/v1';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  // Canonical Auth Endpoints (Frozen in P03)
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String me = '/auth/me';
  static const String profile = '/auth/profile';
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Biometric & Attendance Endpoints
  static const String registerFace = '/attendance/register-face';
  static const String checkInFace = '/attendance/check-in-face';
  static const String faceStatus = '/attendance/face-status';
  static const String studentSchedule = '/students/schedule';
  static String roomWifiAps(int roomId) => '/facilities/rooms/$roomId/wifi-ap';

  // Academic & Timetable Endpoints (Spring Boot)
  static const String timetableMe = '/timetable/me';
  static const String timetableSlotTypes = '/timetable/slot-types';
  static const String enrollments = '/enrollments';
}
