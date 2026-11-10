import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:unicheck_mobile/core/routes/app_routes.dart';
import 'package:unicheck_mobile/core/theme/app_theme.dart';
import 'package:unicheck_mobile/feature/attendance/controllers/attendance_controller.dart';
import 'package:unicheck_mobile/feature/attendance/models/attendance_recheck_model.dart';
import 'package:unicheck_mobile/feature/attendance/services/attendance_api_service.dart';
import 'package:unicheck_mobile/feature/auth/controllers/auth_controller.dart';
import 'package:unicheck_mobile/feature/auth/models/user_model.dart';
import 'package:unicheck_mobile/feature/dashboard/controllers/dashboard_controller.dart';
import 'package:unicheck_mobile/feature/dashboard/models/enrollment_model.dart';
import 'package:unicheck_mobile/feature/dashboard/models/timetable_slot_model.dart';
import 'package:unicheck_mobile/feature/dashboard/services/dashboard_api_service.dart';
import 'package:unicheck_mobile/feature/dashboard/views/student_timetable_view.dart';
import 'package:unicheck_mobile/feature/shell/views/student_shell_view.dart';
import 'package:unicheck_mobile/shared/widgets/attendance_metric_card.dart';
import 'package:unicheck_mobile/shared/widgets/attendance_status_badge.dart';
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

class MockAttendanceApiService extends Fake implements AttendanceApiService {
  List<AttendanceRecheckModel> mockRechecks = [];
  Map<String, dynamic> sessionStatusResponse = {
    'status': 'OPEN',
    'isOpen': true,
    'isClosed': false,
  };

  @override
  Future<Map<String, dynamic>> getSessionStatus(int sessionId) async {
    return sessionStatusResponse;
  }

  @override
  Future<List<AttendanceRecheckModel>> getPendingRecheckRequests() async {
    return mockRechecks;
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
        'attendanceSessionId': 88,
        'attendanceSessionStatus': 'OPEN',
        'studentAttendanceStatus': null,
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
      expect(slot.attendanceSessionId, 88);
      expect(slot.attendanceSessionStatus, 'OPEN');
      expect(slot.studentAttendanceStatus, isNull);
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
      final startH =
          (now.hour > 0 ? now.hour - 1 : 0).toString().padLeft(2, '0');
      final endH = ((now.hour + 2) % 24).toString().padLeft(2, '0');

      mockService.mockSlots = [
        TimetableSlotModel.fromJson({
          'id': 1,
          'courseCode': 'IT301',
          'courseName': 'Mobile Dev',
          'startTime': '$startH:00',
          'endTime': '$endH:00',
          'date': todayStr,
          'hasAttendanceSession': true,
          'attendanceSessionStatus': 'OPEN',
        }),
        TimetableSlotModel.fromJson({
          'id': 2,
          'courseCode': 'SE214',
          'courseName': 'Software Architecture',
          'startTime': '23:00',
          'endTime': '23:59',
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

  group('Weekly Timetable Slot Time and Check-in Action Tests', () {
    final demoDate = DateTime(2026, 11, 10);
    // Thời điểm kiểm thử: 10:38 ngày 10/11/2026
    final refTime1038 = DateTime(2026, 11, 10, 10, 38);

    test(
        'Ca 1 (07:00-09:25) at 10:38 is ended, locked, showing "Đã kết thúc"',
        () {
      final slot1 = TimetableSlotModel(
        id: 136,
        className: 'SE1801-PRJ301',
        courseCode: 'PRJ301',
        courseName: 'Java Web Application Development',
        startTime: '07:00',
        endTime: '09:25',
        date: demoDate,
        hasAttendanceSession: false,
        attendanceSessionId: 83,
        attendanceSessionStatus: 'CLOSED',
      );

      final timeState = slot1.getTimeState(refTime1038);
      expect(timeState, SlotTimeState.ended);

      final actionState = slot1.getAttendanceActionState(
        isEnrolled: true,
        referenceTime: refTime1038,
      );
      expect(actionState, SlotAttendanceActionState.ended);
      expect(slot1.canCheckInNow(isEnrolled: true, referenceTime: refTime1038),
          isFalse);
      expect(
          slot1.getAttendanceButtonText(
              isEnrolled: true, referenceTime: refTime1038),
          'Đã kết thúc');
      expect(
          slot1.getAttendanceBadgeStatus(
              isEnrolled: true, referenceTime: refTime1038),
          AttendanceStatus.ended);
      expect(
          slot1.getAttendanceBadgeLabel(
              isEnrolled: true, referenceTime: refTime1038),
          'Đã kết thúc');
    });

    test(
        'Ca 2 (09:45-12:10) at 10:38 is inProgress, OPEN session enables "Điểm danh ngay"',
        () {
      final slot2 = TimetableSlotModel(
        id: 137,
        className: 'SE1801-PRJ301',
        courseCode: 'PRJ301',
        courseName: 'Java Web Application Development',
        startTime: '09:45',
        endTime: '12:10',
        date: demoDate,
        hasAttendanceSession: true,
        attendanceSessionId: 84,
        attendanceSessionStatus: 'OPEN',
      );

      final timeState = slot2.getTimeState(refTime1038);
      expect(timeState, SlotTimeState.inProgress);

      final actionState = slot2.getAttendanceActionState(
        isEnrolled: true,
        referenceTime: refTime1038,
      );
      expect(actionState, SlotAttendanceActionState.canCheckIn);
      expect(slot2.canCheckInNow(isEnrolled: true, referenceTime: refTime1038),
          isTrue);
      expect(
          slot2.getAttendanceButtonText(
              isEnrolled: true, referenceTime: refTime1038),
          'Điểm danh ngay');
      expect(
          slot2.getAttendanceBadgeStatus(
              isEnrolled: true, referenceTime: refTime1038),
          AttendanceStatus.ongoing);
      expect(
          slot2.getAttendanceBadgeLabel(
              isEnrolled: true, referenceTime: refTime1038),
          'Đang diễn ra');
    });

    test(
        'Ca 2 (09:45-12:10) at 10:38 with CLOSED session disables button, showing "Chưa mở điểm danh"',
        () {
      final slot2Closed = TimetableSlotModel(
        id: 137,
        className: 'SE1801-PRJ301',
        courseCode: 'PRJ301',
        courseName: 'Java Web Application Development',
        startTime: '09:45',
        endTime: '12:10',
        date: demoDate,
        hasAttendanceSession: false,
        attendanceSessionId: 84,
        attendanceSessionStatus: 'CLOSED',
      );

      expect(slot2Closed.getTimeState(refTime1038), SlotTimeState.inProgress);
      expect(
          slot2Closed.getAttendanceActionState(
              isEnrolled: true, referenceTime: refTime1038),
          SlotAttendanceActionState.sessionNotOpen);
      expect(
          slot2Closed.canCheckInNow(
              isEnrolled: true, referenceTime: refTime1038),
          isFalse);
      expect(
          slot2Closed.getAttendanceButtonText(
              isEnrolled: true, referenceTime: refTime1038),
          'Chưa mở điểm danh');
      expect(
          slot2Closed.getAttendanceBadgeStatus(
              isEnrolled: true, referenceTime: refTime1038),
          AttendanceStatus.pending);
      expect(
          slot2Closed.getAttendanceBadgeLabel(
              isEnrolled: true, referenceTime: refTime1038),
          'Chưa mở điểm danh');
    });

    test(
        'Ca 3 (13:00-15:25) at 10:38 is notStarted, button locked showing "Chưa bắt đầu"',
        () {
      final slot3 = TimetableSlotModel(
        id: 138,
        className: 'SE1801-PRJ301',
        courseCode: 'PRJ301',
        courseName: 'Java Web Application Development',
        startTime: '13:00',
        endTime: '15:25',
        date: demoDate,
        hasAttendanceSession: false,
      );

      expect(slot3.getTimeState(refTime1038), SlotTimeState.notStarted);
      expect(
          slot3.getAttendanceActionState(
              isEnrolled: true, referenceTime: refTime1038),
          SlotAttendanceActionState.notStarted);
      expect(
          slot3.canCheckInNow(isEnrolled: true, referenceTime: refTime1038),
          isFalse);
      expect(
          slot3.getAttendanceButtonText(
              isEnrolled: true, referenceTime: refTime1038),
          'Chưa bắt đầu');
      expect(
          slot3.getAttendanceBadgeStatus(
              isEnrolled: true, referenceTime: refTime1038),
          AttendanceStatus.scheduled);
      expect(
          slot3.getAttendanceBadgeLabel(
              isEnrolled: true, referenceTime: refTime1038),
          'Chưa bắt đầu');
    });

    test(
        'Slot with student attendance PRESENT is alreadyAttended, button locked showing "Đã điểm danh"',
        () {
      final slotAttended = TimetableSlotModel(
        id: 137,
        className: 'SE1801-PRJ301',
        courseCode: 'PRJ301',
        courseName: 'Java Web Application Development',
        startTime: '09:45',
        endTime: '12:10',
        date: demoDate,
        hasAttendanceSession: true,
        attendanceSessionId: 84,
        attendanceSessionStatus: 'OPEN',
        studentAttendanceStatus: 'PRESENT',
      );

      expect(
          slotAttended.getAttendanceActionState(
              isEnrolled: true, referenceTime: refTime1038),
          SlotAttendanceActionState.alreadyAttended);
      expect(
          slotAttended.canCheckInNow(
              isEnrolled: true, referenceTime: refTime1038),
          isFalse);
      expect(
          slotAttended.getAttendanceButtonText(
              isEnrolled: true, referenceTime: refTime1038),
          'Đã điểm danh');
      expect(
          slotAttended.getAttendanceBadgeStatus(
              isEnrolled: true, referenceTime: refTime1038),
          AttendanceStatus.present);
      expect(
          slotAttended.getAttendanceBadgeLabel(
              isEnrolled: true, referenceTime: refTime1038),
          'Có mặt đúng giờ');
    });
  });

  group('StudentShellView & Navigation Widget Tests', () {
    late AuthController authController;
    late DashboardController dashboardController;
    late MockAttendanceApiService mockAttendanceService;

    setUp(() async {
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
      mockAttendanceService = MockAttendanceApiService();
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final startH =
          (now.hour > 0 ? now.hour - 1 : 0).toString().padLeft(2, '0');
      final endH = ((now.hour + 2) % 24).toString().padLeft(2, '0');

      mockService.mockSlots = [
        TimetableSlotModel.fromJson({
          'id': 1,
          'className': 'L01',
          'courseCode': 'IT301',
          'courseName': 'Lập trình Thiết bị Di động',
          'lecturerName': 'TS. Lê Quốc Cường',
          'roomName': 'H6-302',
          'startTime': '$startH:00',
          'endTime': '$endH:00',
          'date': todayStr,
          'hasAttendanceSession': true,
          'attendanceSessionId': 84,
          'attendanceSessionStatus': 'OPEN',
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

      dashboardController = Get.put(DashboardController(
        apiService: mockService,
        attendanceApiService: mockAttendanceService,
      ));
      await dashboardController.loadDashboardData();
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets(
        'StudentShellView renders header, bottom bar, and student badge',
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
            GetPage(
                name: AppRoutes.student, page: () => const StudentShellView()),
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

    testWidgets(
        'Tapping "Điểm danh ngay" on TimetableView verifies session status and navigates to qrScanner',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: StudentTimetableView()),
          getPages: [
            GetPage(
              name: AppRoutes.qrScanner,
              page: () => const Scaffold(body: Text('QR Scanner Screen')),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Find "Điểm danh ngay" button on timetable card
      final checkInButton =
          find.widgetWithText(ElevatedButton, 'Điểm danh ngay');
      expect(checkInButton, findsOneWidget);

      await tester.tap(checkInButton);
      await tester.pumpAndSettle();

      // Verifies direct navigation to QR Scanner Screen
      expect(find.text('QR Scanner Screen'), findsOneWidget);

      // Verifies AttendanceController has selected the slot
      final attendanceCtrl = Get.find<AttendanceController>();
      expect(attendanceCtrl.currentSession.value?.id, 1);
      expect(attendanceCtrl.currentSession.value?.className, 'L01');
    });

    testWidgets(
        'Tapping "Điểm danh ngay" when backend returns CLOSED aborts navigation and shows snackbar',
        (tester) async {
      // Configure mock backend to return CLOSED session
      mockAttendanceService.sessionStatusResponse = {
        'status': 'CLOSED',
        'isOpen': false,
        'isClosed': true,
      };

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: StudentTimetableView()),
          getPages: [
            GetPage(
              name: AppRoutes.qrScanner,
              page: () => const Scaffold(body: Text('QR Scanner Screen')),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final checkInButton =
          find.widgetWithText(ElevatedButton, 'Điểm danh ngay');
      expect(checkInButton, findsOneWidget);

      await tester.tap(checkInButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Did NOT navigate to QR Scanner Screen
      expect(find.text('QR Scanner Screen'), findsNothing);

      // Shows closed session notification snackbar
      expect(find.text('Phiên điểm danh đã đóng'), findsOneWidget);

      // Settle the snackbar timer and reverse animation completely
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('Pending Recheck Request renders alert card and tapping button navigates to qrScanner', (tester) async {
      final now = DateTime.now();
      final recheck = AttendanceRecheckModel(
        requestId: 42,
        sessionId: 84,
        studentId: 14,
        studentCode: 'HE180001',
        studentName: 'Nguyen Van A',
        courseCode: 'PRJ301',
        courseName: 'Java Web',
        className: 'SE1801-PRJ301',
        roomCode: 'AL-L201',
        reason: 'Nghi vấn điểm danh hộ',
        status: 'PENDING',
        expiresAt: now.add(const Duration(minutes: 15)),
        requestedByName: 'Nguyen Tan Son',
      );

      mockAttendanceService.mockRechecks = [recheck];
      await dashboardController.loadDashboardData();

      final attCtrl = AttendanceController(apiService: mockAttendanceService);
      Get.put<AttendanceController>(attCtrl);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: StudentTimetableView()),
          getPages: [
            GetPage(
              name: AppRoutes.qrScanner,
              page: () => const Scaffold(body: Text('QR Scanner Screen')),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('YÊU CẦU ĐIỂM DANH LẠI'), findsWidgets);
      expect(find.textContaining('Nghi vấn điểm danh hộ'), findsOneWidget);

      final recheckBtn = find.widgetWithText(ElevatedButton, 'Điểm danh').first;
      await tester.tap(recheckBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('QR Scanner Screen'), findsOneWidget);
      expect(attCtrl.activeRecheckRequest.value?.requestId, 42);
    });
  });
}
