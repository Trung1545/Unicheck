import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:unicheck_mobile/core/routes/app_routes.dart';
import 'package:unicheck_mobile/core/theme/app_theme.dart';
import 'package:unicheck_mobile/feature/auth/controllers/auth_controller.dart';
import 'package:unicheck_mobile/feature/auth/models/user_model.dart';
import 'package:unicheck_mobile/feature/dashboard/controllers/dashboard_controller.dart';
import 'package:unicheck_mobile/feature/dashboard/models/enrollment_model.dart';
import 'package:unicheck_mobile/feature/dashboard/models/timetable_slot_model.dart';
import 'package:unicheck_mobile/feature/dashboard/services/dashboard_api_service.dart';
import 'package:unicheck_mobile/feature/shell/views/student_shell_view.dart';
import 'package:unicheck_mobile/shared/widgets/attendance_metric_card.dart';
import 'package:unicheck_mobile/shared/widgets/class_session_card.dart';
import 'package:unicheck_mobile/shared/widgets/uni_bottom_nav_bar.dart';

class MockDashboardApiService extends Fake implements DashboardApiService {
  List<TimetableSlotModel> mockSlots = [];
  List<EnrollmentModel> mockEnrollments = [];

  @override
  Future<List<TimetableSlotModel>> getMyTimetable({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return mockSlots;
  }

  @override
  Future<List<EnrollmentModel>> getMyEnrollments({
    int? studentId,
    int page = 0,
    int size = 50,
  }) async {
    return mockEnrollments;
  }
}

void main() {
  group('Phase 04 Models & Logic Unit Tests', () {
    test('TimetableSlotModel parses json correctly with helpers', () {
      final json = {
        'id': 101,
        'className': 'L01',
        'courseCode': 'IT301',
        'courseName': 'Lập trình Thiết bị Di động',
        'lecturerName': 'TS. Lê Quốc Cường',
        'roomName': 'H6-302',
        'building': 'Cơ sở 1',
        'startTime': '07:30:00',
        'endTime': '11:15:00',
        'date': '2026-10-20',
        'dayOfWeek': 2,
        'slotNumber': 1,
        'endSlotNumber': 5,
        'hasAttendanceSession': true,
      };

      final slot = TimetableSlotModel.fromJson(json);

      expect(slot.id, 101);
      expect(slot.courseCode, 'IT301');
      expect(slot.courseName, 'Lập trình Thiết bị Di động');
      expect(slot.timeSlot, '07:30 - 11:15');
      expect(slot.roomDisplay, 'H6-302 (Cơ sở 1)');
      expect(slot.lecturerDisplay, 'TS. Lê Quốc Cường');
      expect(slot.periodsDisplay, 'Tiết 1 - 5');
      expect(slot.hasAttendanceSession, isTrue);
      expect(slot.isScheduledOn(DateTime(2026, 10, 20)), isTrue);
      expect(slot.isScheduledOn(DateTime(2026, 10, 21)), isFalse);
    });

    test('EnrollmentModel parses json correctly', () {
      final json = {
        'id': 501,
        'className': 'IT301.N12',
        'courseCode': 'IT301',
        'courseName': 'Lập trình Web & Ứng dụng',
        'status': 'ACTIVE',
      };

      final enrollment = EnrollmentModel.fromJson(json);

      expect(enrollment.id, 501);
      expect(enrollment.courseCode, 'IT301');
      expect(enrollment.courseName, 'Lập trình Web & Ứng dụng');
      expect(enrollment.isActive, isTrue);
    });

    test('DashboardController correctly calculates week days and slots', () async {
      final mockService = MockDashboardApiService();
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      mockService.mockSlots = [
        TimetableSlotModel.fromJson({
          'id': 1,
          'courseCode': 'IT301',
          'courseName': 'Mobile Dev',
          'startTime': '08:00',
          'endTime': '11:30',
          'date': todayStr,
          'hasAttendanceSession': true,
        }),
        TimetableSlotModel.fromJson({
          'id': 2,
          'courseCode': 'SE214',
          'courseName': 'Software Architecture',
          'startTime': '13:30',
          'endTime': '16:15',
          'date': todayStr,
          'hasAttendanceSession': false,
        }),
      ];

      mockService.mockEnrollments = [
        const EnrollmentModel(
          id: 1,
          courseCode: 'IT301',
          courseName: 'Mobile Dev',
          status: 'ACTIVE',
        ),
      ];

      final controller = DashboardController(apiService: mockService);
      await controller.loadDashboardData();

      expect(controller.weeklyDays.length, 7);
      expect(controller.todaySlots.length, 2);
      expect(controller.activeAttendanceSession?.id, 1);
      expect(controller.nextClassSession, isNotNull);
      expect(controller.filteredCourses.length, 1);

      // Filtering search test
      controller.setCourseSearch('SE');
      expect(controller.filteredCourses.isEmpty, isTrue);
      controller.setCourseSearch('Mobile');
      expect(controller.filteredCourses.length, 1);
    });
  });

  group('StudentShellView & Navigation Widget Tests', () {
    late AuthController authController;
    late DashboardController dashboardController;

    setUp(() {
      Get.reset();
      authController = Get.put(AuthController());
      authController.user.value = UserModel(
        id: 1,
        code: '2251120001',
        username: 'student_test',
        fullName: 'Nguyễn Văn An',
        email: 'an.nguyen@unicheck.edu.vn',
        role: 'STUDENT',
        faceDataStatus: 'REGISTERED',
      );

      final mockService = MockDashboardApiService();
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      mockService.mockSlots = [
        TimetableSlotModel.fromJson({
          'id': 1,
          'className': 'L01',
          'courseCode': 'IT301',
          'courseName': 'Lập trình Thiết bị Di động',
          'lecturerName': 'TS. Lê Quốc Cường',
          'roomName': 'H6-302',
          'startTime': '07:30',
          'endTime': '11:15',
          'date': todayStr,
          'hasAttendanceSession': true,
        }),
      ];

      mockService.mockEnrollments = [
        const EnrollmentModel(
          id: 1,
          className: 'L01',
          courseCode: 'IT301',
          courseName: 'Lập trình Thiết bị Di động',
          status: 'ACTIVE',
        ),
      ];

      dashboardController = Get.put(DashboardController(apiService: mockService));
      dashboardController.loadDashboardData();
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('StudentShellView renders header, bottom bar, and student badge',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const StudentShellView(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header branding
      expect(find.text('UniCheck'), findsOneWidget);

      // Verify Student role badge is present for test compatibility
      expect(find.text('Sinh Viên (STUDENT)'), findsOneWidget);

      // Verify Greeting card
      expect(find.text('Xin chào, Nguyễn Văn An 👋'), findsOneWidget);

      // Verify Bottom Navigation Bar is present
      expect(find.byType(UniBottomNavBar), findsOneWidget);
      expect(find.text('Tổng quan'), findsOneWidget);
      expect(find.text('Thời khóa'), findsOneWidget);
      expect(find.text('Điểm danh'), findsWidgets);
      expect(find.text('Lớp học'), findsOneWidget);
      expect(find.text('Cá nhân'), findsOneWidget);

      // Verify Metric Cards rendered
      expect(find.byType(AttendanceMetricCard), findsWidgets);
      expect(find.text('Chuyên cần'), findsOneWidget);
      expect(find.text('Đã vắng'), findsOneWidget);
      expect(find.text('Face-ID'), findsOneWidget);

      // Verify Active check-in card
      expect(find.text('Phiên mở điểm danh'), findsOneWidget);
      expect(find.text('Lập trình Thiết bị Di động'), findsWidgets);

      // Verify Next Class session card
      expect(find.byType(ClassSessionCard), findsWidgets);
    });

    testWidgets('Tapping bottom tabs switches views smoothly', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.student,
          getPages: [
            GetPage(name: AppRoutes.student, page: () => const StudentShellView()),
            GetPage(
              name: AppRoutes.qrScanner,
              page: () => const Scaffold(body: Text('QR Scanner Screen')),
            ),
            GetPage(
              name: AppRoutes.selectSession,
              page: () => const Scaffold(body: Text('Select Session Screen')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Initially on Tab 0
      expect(dashboardController.selectedTab.value, 0);

      // Tap Tab 1: Thời khóa
      await tester.tap(find.text('Thời khóa'));
      await tester.pumpAndSettle();
      expect(dashboardController.selectedTab.value, 1);
      expect(find.text('Thời khóa biểu tuần'), findsOneWidget);
      expect(find.text('Hôm nay'), findsOneWidget);

      // Tap Tab 3: Lớp học
      await tester.tap(find.text('Lớp học'));
      await tester.pumpAndSettle();
      expect(dashboardController.selectedTab.value, 3);
      expect(find.text('Lớp học phần'), findsOneWidget);
      expect(find.text('Tổng tín chỉ'), findsOneWidget);

      // Tap Tab 4: Cá nhân
      await tester.tap(find.text('Cá nhân'));
      await tester.pumpAndSettle();
      expect(dashboardController.selectedTab.value, 4);
      expect(find.text('Bảo mật & Sinh trắc học'), findsOneWidget);
      expect(find.text('Đăng xuất tài khoản'), findsOneWidget);

      // Tap Center QR scan button navigates to real QR / Session flow
      await tester.tap(find.byIcon(Icons.qr_code_scanner_rounded).last);
      await tester.pumpAndSettle();
      expect(find.text('QR Scanner Screen'), findsOneWidget);
    });
  });
}
