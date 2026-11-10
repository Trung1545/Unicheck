import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:unicheck_mobile/core/routes/app_routes.dart';
import 'package:unicheck_mobile/core/theme/app_theme.dart';
import 'package:unicheck_mobile/feature/attendance/controllers/attendance_controller.dart';
import 'package:unicheck_mobile/feature/attendance/models/face_status_model.dart';
import 'package:unicheck_mobile/feature/attendance/models/qr_payload_model.dart';
import 'package:unicheck_mobile/feature/attendance/models/room_wifi_ap_model.dart';
import 'package:unicheck_mobile/feature/attendance/services/attendance_api_service.dart';
import 'package:unicheck_mobile/feature/attendance/utils/wifi_validator.dart';
import 'package:unicheck_mobile/feature/attendance/views/attendance_eligibility_view.dart';
import 'package:unicheck_mobile/feature/attendance/views/attendance_failure_view.dart';
import 'package:unicheck_mobile/feature/attendance/views/attendance_success_view.dart';
import 'package:unicheck_mobile/feature/attendance/views/select_attendance_session_view.dart';
import 'package:unicheck_mobile/feature/auth/controllers/auth_controller.dart';
import 'package:unicheck_mobile/feature/auth/models/user_model.dart';
import 'package:unicheck_mobile/feature/dashboard/controllers/dashboard_controller.dart';
import 'package:unicheck_mobile/feature/dashboard/models/enrollment_model.dart';
import 'package:unicheck_mobile/feature/dashboard/models/timetable_slot_model.dart';
import 'package:unicheck_mobile/feature/dashboard/services/dashboard_api_service.dart';
import 'package:unicheck_mobile/shared/widgets/verification_check_item.dart';

class MockAttendanceApiService extends Fake implements AttendanceApiService {
  List<RoomWifiAccessPointModel> mockAps = [];
  FaceStatusModel mockFace = const FaceStatusModel(isRegistered: true);
  Map<String, dynamic>? mockQrResult;

  @override
  Future<List<RoomWifiAccessPointModel>> getRoomWifiAccessPoints(int roomId) async {
    return mockAps;
  }

  @override
  Future<FaceStatusModel> getFaceStatus() async {
    return mockFace;
  }

  @override
  Future<Map<String, dynamic>> validateQrToken({
    required String qrToken,
    required int sessionId,
  }) async {
    return mockQrResult ?? {'valid': true, 'sessionId': sessionId};
  }
}

class MockNetworkInfo extends Fake implements NetworkInfo {
  String? mockSsid = 'HCMUT_Student_A4';
  String? mockBssid = '00:11:22:33:44:55';

  @override
  Future<String?> getWifiName() async => mockSsid;

  @override
  Future<String?> getWifiBSSID() async => mockBssid;
}

class MockDashboardService extends Fake implements DashboardApiService {
  List<TimetableSlotModel> mockSlots = [];
  List<EnrollmentModel> mockEnrollments = [];

  @override
  Future<List<TimetableSlotModel>> getMyTimetable({
    DateTime? startDate,
    DateTime? endDate,
  }) async =>
      mockSlots;

  @override
  Future<List<EnrollmentModel>> getMyEnrollments({
    int? studentId,
    int page = 0,
    int size = 50,
  }) async =>
      mockEnrollments;
}

void main() {
  group('Phase 05 Unit Tests - Models & QR Parsing', () {
    test('QrPayloadModel parses JSON payload correctly', () {
      const jsonStr =
          '{"sessionId": 101, "slotId": 101, "roomCode": "A4-501", "courseCode": "IT301", "token": "xyz123"}';
      final payload = QrPayloadModel.parse(jsonStr);

      expect(payload.sessionId, 101);
      expect(payload.slotId, 101);
      expect(payload.roomCode, 'A4-501');
      expect(payload.courseCode, 'IT301');
      expect(payload.token, 'xyz123');
      expect(payload.isValid, isTrue);
    });

    test('QrPayloadModel parses URI format correctly', () {
      const uriStr = 'unicheck://attendance?sessionId=202&slotId=202&roomCode=H6-302';
      final payload = QrPayloadModel.parse(uriStr);

      expect(payload.sessionId, 202);
      expect(payload.slotId, 202);
      expect(payload.roomCode, 'H6-302');
      expect(payload.isValid, isTrue);
    });

    test('QrPayloadModel parses delimited string format UNICHECK:id:room', () {
      const delimited = 'UNICHECK:303:B1-201';
      final payload = QrPayloadModel.parse(delimited);

      expect(payload.sessionId, 303);
      expect(payload.slotId, 303);
      expect(payload.roomCode, 'B1-201');
      expect(payload.isValid, isTrue);
    });

    test('QrPayloadModel parses Static Test QR format STQR:sessionId:token', () {
      const staticQr = 'STQR:101:a8f9b23e71d49c6e';
      final payload = QrPayloadModel.parse(staticQr);

      expect(payload.sessionId, 101);
      expect(payload.slotId, 101);
      expect(payload.token, staticQr);
      expect(payload.isValid, isTrue);
    });

    test('QrPayloadModel parses Dynamic QR compact JWT format', () {
      // {"sessionId":101,"type":"DYNAMIC_QR","iat":1700000000}
      // base64Url for payload: eyJzZXNzaW9uSWQiOjEwMSwidHlwZSI6IkRZTkFNSUNfUVIiLCJpYXQiOjE3MDAwMDAwMDB9
      const jwtToken =
          'eyJhbGciOiJIUzI1NiJ9.eyJzZXNzaW9uSWQiOjEwMSwidHlwZSI6IkRZTkFNSUNfUVIiLCJpYXQiOjE3MDAwMDAwMDB9.dummySignature';
      final payload = QrPayloadModel.parse(jwtToken);

      expect(payload.sessionId, 101);
      expect(payload.slotId, 101);
      expect(payload.token, jwtToken);
      expect(payload.isValid, isTrue);
    });

    test('QrPayloadModel rejects invalid/corrupted string', () {
      const invalid = 'INVALID_GARBAGE_TOKEN';
      final payload = QrPayloadModel.parse(invalid);

      expect(payload.sessionId, isNull);
      expect(payload.slotId, isNull);
      expect(payload.isValid, isFalse);
    });

    test('RoomWifiAccessPointModel parses from JSON', () {
      final json = {
        'id': 12,
        'roomId': 45,
        'roomCode': 'A4-501',
        'roomName': 'Phòng 501 Tòa A4',
        'ssid': 'HCMUT_Student_A4',
        'bssid': '00:11:22:33:44:55',
        'signalStrength': -58,
        'isPrimary': true,
      };

      final model = RoomWifiAccessPointModel.fromJson(json);
      expect(model.id, 12);
      expect(model.roomId, 45);
      expect(model.ssid, 'HCMUT_Student_A4');
      expect(model.bssid, '00:11:22:33:44:55');
      expect(model.signalStrength, -58);
      expect(model.isPrimary, isTrue);
    });

    test('FaceStatusModel parses registered and unregistered state', () {
      final regJson = {
        'userId': 99,
        'faceDataStatus': 'REGISTERED',
        'isRegistered': true,
      };
      final regModel = FaceStatusModel.fromJson(regJson);
      expect(regModel.isRegistered, isTrue);

      final unregJson = {
        'userId': 100,
        'faceDataStatus': 'NOT_REGISTERED',
        'isRegistered': false,
      };
      final unregModel = FaceStatusModel.fromJson(unregJson);
      expect(unregModel.isRegistered, isFalse);
    });
  });

  group('Phase 05 Unit Tests - WifiValidator & AttendanceController', () {
    test('WifiValidator validates matching BSSID and SSID correctly', () async {
      final mockNet = MockNetworkInfo();
      mockNet.mockSsid = '"HCMUT_Student_A4"';
      mockNet.mockBssid = '00:11:22:33:44:55';

      final validator = WifiValidator(networkInfo: mockNet);

      final allowed = [
        const RoomWifiAccessPointModel(
          id: 1,
          ssid: 'HCMUT_Student_A4',
          bssid: '00:11:22:33:44:55',
          roomCode: 'A4-501',
        ),
      ];

      final matchResult = await validator.validateRoomWifi(
        allowedAps: allowed,
        expectedRoomCode: 'A4-501',
      );

      expect(matchResult.isMatched, isTrue);
      expect(matchResult.connectedSsid, 'HCMUT_Student_A4');
      expect(matchResult.connectedBssid, '00:11:22:33:44:55');

      // Test Mismatch
      final mismatchResult = await validator.validateRoomWifi(
        allowedAps: [
          const RoomWifiAccessPointModel(
            id: 2,
            ssid: 'Other_AP',
            bssid: 'aa:bb:cc:dd:ee:ff',
            roomCode: 'B2-101',
          ),
        ],
        expectedRoomCode: 'B2-101',
      );

      expect(mismatchResult.isMatched, isFalse);
      expect(mismatchResult.reason, contains('Cần kết nối trạm phát phòng học'));
    });

    test('WifiValidator validates DEMO_WIFI_SIMULATION on Android Emulator', () async {
      final mockNet = MockNetworkInfo();
      // Android emulator typically returns null or <unknown ssid> and 02:00:00:00:00:00
      mockNet.mockSsid = '<unknown ssid>';
      mockNet.mockBssid = '02:00:00:00:00:00';

      final validator = WifiValidator(networkInfo: mockNet);

      final allowedAps = [
        const RoomWifiAccessPointModel(
          id: 5,
          ssid: 'FU-Student-AL',
          bssid: '00:1A:2B:3C:01:02',
          roomCode: 'AL-L201',
        ),
      ];

      // 1. When simulation is disabled: rejects because AP doesn't match
      final rejected = await validator.validateRoomWifi(
        allowedAps: allowedAps,
        expectedRoomCode: 'AL-L201',
        isSimulationAllowed: false,
      );
      expect(rejected.isMatched, isFalse);
      expect(rejected.reason, contains('chưa kết nối Wi-Fi phòng học'));

      // 2. When simulation is allowed: matches simulated AP
      final accepted = await validator.validateRoomWifi(
        allowedAps: allowedAps,
        expectedRoomCode: 'AL-L201',
        isSimulationAllowed: true,
        simulatedSsid: 'AndroidWifi',
        simulatedBssid: '02:00:00:00:00:00',
      );
      expect(accepted.isMatched, isTrue);
      expect(accepted.connectedSsid, 'AndroidWifi');
      expect(accepted.connectedBssid, '02:00:00:00:00:00');
      expect(accepted.reason, contains('Wi-Fi mô phỏng (Demo)'));
      expect(accepted.reason, contains('AL-L201'));
    });

    test('AttendanceController handles DEMO_WIFI_SIMULATION and passes all 5 criteria', () async {
      Get.reset();
      final mockApi = MockAttendanceApiService();
      mockApi.mockQrResult = {
        'valid': true,
        'sessionId': 83,
        'slotId': 136,
        'className': 'SE1801-PRJ301',
        'roomId': 5,
        'roomCode': 'AL-L201',
        'wifiSimulationAllowed': true,
        'simulatedSsid': 'AndroidWifi',
        'simulatedBssid': '02:00:00:00:00:00',
      };
      mockApi.mockAps = [
        const RoomWifiAccessPointModel(
          id: 5,
          roomId: 5,
          ssid: 'FU-Student-AL',
          bssid: '00:1A:2B:3C:01:02',
          roomCode: 'AL-L201',
        ),
      ];
      mockApi.mockFace = const FaceStatusModel(isRegistered: true);

      // Emulator network: unreadable SSID, virtual BSSID
      final mockNet = MockNetworkInfo();
      mockNet.mockSsid = null;
      mockNet.mockBssid = '02:00:00:00:00:00';

      final validator = WifiValidator(networkInfo: mockNet);
      final controller = AttendanceController(
        apiService: mockApi,
        wifiValidator: validator,
      );

      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final slot = TimetableSlotModel.fromJson({
        'id': 136,
        'className': 'SE1801-PRJ301',
        'courseCode': 'PRJ301',
        'courseName': 'Java Web Application Development',
        'roomName': 'AL-L201',
        'roomId': 5,
        'startTime': '00:00:00',
        'endTime': '23:59:59',
        'date': todayStr,
        'hasAttendanceSession': true,
      });

      controller.selectSession(slot);
      await controller.onQrCodeScanned('STQR:83:demo-token');

      // Verify server simulation flag populated
      expect(controller.wifiSimulationAllowed.value, isTrue);
      expect(controller.simulatedSsid.value, 'AndroidWifi');
      expect(controller.simulatedBssid.value, '02:00:00:00:00:00');

      // Verify criteria passed with Wi-Fi simulation note
      expect(controller.qrStatus.value, VerificationStatus.pass);
      expect(controller.wifiStatus.value, VerificationStatus.pass);
      expect(controller.wifiNote.value, contains('Wi-Fi mô phỏng (Demo)'));
      expect(controller.timeStatus.value, VerificationStatus.pass);
      expect(controller.enrollmentStatus.value, VerificationStatus.pass);
      expect(controller.faceStatus.value, VerificationStatus.pass);
      expect(controller.passedCriteriaCount, 5);
      expect(controller.isAllPassed, isTrue);
    });

    test('AttendanceController evaluates all 5 criteria and generates receipt',
        () async {
      Get.reset();
      final mockApi = MockAttendanceApiService();
      mockApi.mockAps = [
        const RoomWifiAccessPointModel(
          id: 1,
          roomId: 50,
          ssid: 'HCMUT_Student_A4',
          bssid: '00:11:22:33:44:55',
          roomCode: 'A4-501',
        ),
      ];
      mockApi.mockFace = const FaceStatusModel(isRegistered: true);

      final mockNet = MockNetworkInfo();
      final validator = WifiValidator(networkInfo: mockNet);

      final controller = AttendanceController(
        apiService: mockApi,
        wifiValidator: validator,
      );

      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final slot = TimetableSlotModel.fromJson({
        'id': 101,
        'className': 'L01',
        'courseCode': 'IT301',
        'courseName': 'Lập trình Web & Ứng dụng',
        'roomName': 'A4-501',
        'roomId': 50,
        'startTime': '00:00:00',
        'endTime': '23:59:59',
        'date': todayStr,
        'hasAttendanceSession': true,
      });

      controller.selectSession(slot);
      await controller.onQrCodeScanned('{"sessionId": 101, "slotId": 101, "roomCode": "A4-501"}');

      expect(controller.qrStatus.value, VerificationStatus.pass);
      expect(controller.wifiStatus.value, VerificationStatus.pass);
      expect(controller.timeStatus.value, VerificationStatus.pass);
      expect(controller.enrollmentStatus.value, VerificationStatus.pass);
      expect(controller.faceStatus.value, VerificationStatus.pass);
      expect(controller.passedCriteriaCount, 5);
      expect(controller.isAllPassed, isTrue);

      controller.generateReceipt();
      expect(controller.receiptId.value, startsWith('#ATT-'));
      expect(controller.attendanceTimestamp.value.isNotEmpty, isTrue);
    });
  });

  group('Phase 05 Widget Tests - SelectAttendanceSessionView', () {
    late AuthController authController;
    late DashboardController dashboardController;
    late AttendanceController attendanceController;

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

      final mockDash = MockDashboardService();
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      mockDash.mockSlots = [
        TimetableSlotModel.fromJson({
          'id': 101,
          'className': 'L01',
          'courseCode': 'IT301',
          'courseName': 'Lập trình Web & Ứng dụng',
          'roomName': 'A4-501',
          'lecturerName': 'TS. Trần Minh Đức',
          'startTime': '13:30',
          'endTime': '16:15',
          'date': todayStr,
          'hasAttendanceSession': true,
        }),
      ];

      dashboardController = Get.put(DashboardController(apiService: mockDash));
      await dashboardController.loadDashboardData();

      attendanceController = Get.put(AttendanceController(
        apiService: MockAttendanceApiService(),
        wifiValidator: WifiValidator(networkInfo: MockNetworkInfo()),
      ));
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('SelectAttendanceSessionView renders header, banner, 3-step pipeline',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const SelectAttendanceSessionView(),
          getPages: [
            GetPage(
              name: AppRoutes.qrScanner,
              page: () => const Scaffold(body: Text('Scanner Screen')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Điểm Danh'), findsOneWidget);
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      expect(find.text('2251120001'), findsOneWidget);

      // Banner & Filter Chips
      expect(find.text('Quy trình xác thực 3 bước'), findsOneWidget);
      expect(find.text('Chuẩn học đường'), findsOneWidget);
      expect(find.text('Quét mã QR'), findsOneWidget);
      expect(find.text('Wi-Fi & Phòng'), findsOneWidget);
      expect(find.text('Face-ID AI'), findsOneWidget);

      // Sessions list & active card
      expect(find.text('Phiên học trực tiếp'), findsOneWidget);
      expect(find.text('Đang mở điểm danh'), findsOneWidget);
      expect(find.text('Lập trình Web & Ứng dụng'), findsOneWidget);
      expect(find.text('Bắt đầu điểm danh QR'), findsOneWidget);

      // Tap action selects session into AttendanceController
      await tester.ensureVisible(find.text('Bắt đầu điểm danh QR'));
      await tester.tap(find.text('Bắt đầu điểm danh QR'));
      await tester.pumpAndSettle();
      expect(attendanceController.currentSession.value?.id, 101);
      expect(find.text('Scanner Screen'), findsOneWidget);
    });
  });

  group('Phase 05 Widget Tests - AttendanceEligibilityView', () {
    late AuthController authController;
    late AttendanceController attendanceController;

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
      );

      final mockApi = MockAttendanceApiService();
      final mockNet = MockNetworkInfo();
      attendanceController = Get.put(AttendanceController(
        apiService: mockApi,
        wifiValidator: WifiValidator(networkInfo: mockNet),
      ));

      final slot = TimetableSlotModel.fromJson({
        'id': 101,
        'className': 'L01',
        'courseCode': 'IT301',
        'courseName': 'Lập trình Web & Ứng dụng',
        'roomName': 'A4-501',
        'startTime': '13:30',
        'endTime': '16:15',
        'hasAttendanceSession': true,
      });
      attendanceController.selectSession(slot);
      attendanceController.qrStatus.value = VerificationStatus.pass;
      attendanceController.wifiStatus.value = VerificationStatus.pass;
      attendanceController.timeStatus.value = VerificationStatus.pass;
      attendanceController.enrollmentStatus.value = VerificationStatus.pass;
      attendanceController.faceStatus.value = VerificationStatus.pass;
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('AttendanceEligibilityView renders 3-step progress and 5 checklist criteria',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const AttendanceEligibilityView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Check In Verification'), findsOneWidget);
      expect(find.text('1. Quét QR'), findsOneWidget);
      expect(find.text('2. Đối soát'), findsOneWidget);
      expect(find.text('3. Face-ID'), findsOneWidget);

      expect(find.text('Tiêu chí điều kiện'), findsOneWidget);
      expect(find.text('5/5 Đạt yêu cầu'), findsOneWidget);

      expect(find.byType(VerificationCheckItem), findsNWidgets(5));
      expect(find.text('1. Mã QR giảng đường hợp lệ'), findsOneWidget);
      expect(find.text('2. Mạng Wi-Fi & Vị trí phòng học'), findsOneWidget);
      expect(find.text('3. Khung giờ ca học quy định'), findsOneWidget);
      expect(find.text('4. Trạng thái ghi danh học phần'), findsOneWidget);
      expect(find.text('5. Dữ liệu khuôn mặt Face-ID'), findsOneWidget);

      expect(find.text('Tiếp tục quét khuôn mặt'), findsOneWidget);
    });

    testWidgets('AttendanceEligibilityView displays "Wi-Fi mô phỏng (Demo) – Đạt" pill when Wi-Fi simulation active',
        (tester) async {
      attendanceController.wifiSimulationAllowed.value = true;
      attendanceController.wifiNote.value =
          'Wi-Fi mô phỏng (Demo) – Đạt (Phòng AL-L201)';

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const AttendanceEligibilityView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Wi-Fi mô phỏng (Demo) – Đạt'), findsOneWidget);
      expect(
        find.text(
            'Chế độ Wi-Fi mô phỏng (Demo) trên Android Emulator được máy chủ cấp phép.'),
        findsOneWidget,
      );
      expect(
        find.text('Wi-Fi mô phỏng (Demo) – Đạt (Phòng AL-L201)'),
        findsOneWidget,
      );
    });
  });

  group('Phase 05 Widget Tests - AttendanceSuccessView & FailureView', () {
    late AuthController authController;
    late AttendanceController attendanceController;

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
      );

      final mockApi = MockAttendanceApiService();
      final mockNet = MockNetworkInfo();
      attendanceController = Get.put(AttendanceController(
        apiService: mockApi,
        wifiValidator: WifiValidator(networkInfo: mockNet),
      ));

      final slot = TimetableSlotModel.fromJson({
        'id': 101,
        'className': 'L01',
        'courseCode': 'IT301',
        'courseName': 'Lập trình Web & Ứng dụng',
        'roomName': 'A4-501',
      });
      attendanceController.selectSession(slot);
      attendanceController.generateReceipt();
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('AttendanceSuccessView renders receipt code and academic details',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const AttendanceSuccessView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kết Quả Điểm Danh'), findsOneWidget);
      expect(find.text('Điểm danh thành công'), findsOneWidget);
      expect(find.text('Có mặt đúng giờ'), findsOneWidget);
      expect(find.text('BIÊN NHẬN ĐIỆN TỬ HỢP LỆ'), findsOneWidget);
      expect(find.text('Về trang chủ sinh viên'), findsOneWidget);
    });

    testWidgets('AttendanceFailureView renders error code and diagnostic audit list',
        (tester) async {
      attendanceController.diagnosticCode.value = 'ERR_WIFI_OUT_OF_RANGE';
      attendanceController.diagnosticReason.value =
          'Thiết bị chưa kết nối vào trạm phát Wi-Fi phòng học theo quy định.';

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const AttendanceFailureView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Điểm danh không thành công'), findsOneWidget);
      expect(find.text('XÁC THỰC CHƯA HOÀN TẤT'), findsOneWidget);
      expect(find.text('ERR_WIFI_OUT_OF_RANGE'), findsOneWidget);
      expect(find.text('Thử đối soát lại'), findsOneWidget);
      expect(find.text('Về trang chủ sinh viên'), findsOneWidget);
    });
  });
}
