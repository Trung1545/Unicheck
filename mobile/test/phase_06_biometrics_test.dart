import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:unicheck_mobile/core/network/api_client.dart';
import 'package:unicheck_mobile/core/storage/token_storage.dart';
import 'package:unicheck_mobile/core/theme/app_theme.dart';
import 'package:unicheck_mobile/feature/attendance/controllers/attendance_controller.dart';
import 'package:unicheck_mobile/feature/attendance/models/attendance_checkin_request_model.dart';
import 'package:unicheck_mobile/feature/attendance/models/attendance_checkin_response_model.dart';
import 'package:unicheck_mobile/feature/attendance/models/face_enrollment_result_model.dart';
import 'package:unicheck_mobile/feature/attendance/models/face_status_model.dart';
import 'package:unicheck_mobile/feature/attendance/models/qr_payload_model.dart';
import 'package:unicheck_mobile/feature/attendance/models/room_wifi_ap_model.dart';
import 'package:unicheck_mobile/feature/attendance/services/attendance_api_service.dart';
import 'package:unicheck_mobile/feature/attendance/views/face_enrollment_result_view.dart';
import 'package:unicheck_mobile/feature/attendance/views/face_enrollment_view.dart';
import 'package:unicheck_mobile/feature/auth/controllers/auth_controller.dart';
import 'package:unicheck_mobile/feature/auth/models/user_model.dart';
import 'package:unicheck_mobile/feature/dashboard/models/timetable_slot_model.dart';

class MockAttendanceApiService extends AttendanceApiService {
  final bool shouldCheckinFail;
  final String? failMessage;
  final String? failErrorCode;
  final AttendanceCheckinResponseModel? customCheckinResponse;

  MockAttendanceApiService({
    this.shouldCheckinFail = false,
    this.failMessage,
    this.failErrorCode,
    this.customCheckinResponse,
  }) : super(
          apiClient: ApiClient(
            tokenStorage: PlatformTokenStorage(),
          ),
        );

  @override
  Future<List<RoomWifiAccessPointModel>> getRoomWifiAccessPoints(int roomId) async {
    return [
      RoomWifiAccessPointModel(
        id: 1,
        roomId: roomId,
        bssid: 'AA:BB:CC:DD:EE:01',
        ssid: 'BK_CAMPUS_A2',
        isPrimary: true,
      ),
    ];
  }

  @override
  Future<FaceStatusModel> getFaceStatus() async {
    return const FaceStatusModel(
      isRegistered: true,
      faceDataStatus: 'REGISTERED',
    );
  }

  @override
  Future<FaceEnrollmentResultModel> registerFace({
    required String primaryImageBase64,
    required List<Map<String, String>> samples,
    bool isReEnrollment = true,
  }) async {
    return FaceEnrollmentResultModel(
      success: true,
      status: 'REGISTERED',
      registeredAt: DateTime(2026, 10, 20, 14, 30),
      version: 'v3.2',
      modelName: 'ArcFace MobileFaceNet (512-dim)',
      embeddingDimension: 512,
      tokenHash: 'e8f9c18d40a87f12e09b11933df01c7784a9235e8932b12fa9080c3b2190',
      studentName: 'Nguyễn Văn An',
      studentCode: '2251120001',
    );
  }

  @override
  Future<AttendanceCheckinResponseModel> checkInFace(
      AttendanceCheckinRequestModel request) async {
    if (shouldCheckinFail) {
      throw ApiException(
        message: failMessage ??
            'Máy chủ học vụ chưa mở cổng tiếp nhận điểm danh trực tuyến (TASK-06 Blocker: HTTP 404).',
        errorCode: failErrorCode,
        statusCode: failErrorCode != null ? 400 : 404,
      );
    }

    if (customCheckinResponse != null) {
      return customCheckinResponse!;
    }

    return AttendanceCheckinResponseModel(
      id: 999,
      studentId: 101,
      studentCode: '2251120001',
      studentName: 'Nguyễn Văn An',
      status: 'PRESENT',
      method: 'FACE_QR',
      checkInTime: DateTime(2026, 10, 20, 14, 30),
      faceConfidence: 0.992,
      receiptId: '#ATT-20261020-CS101-7890',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Phase 06 Models Unit Tests', () {
    test('FaceEnrollmentResultModel parses JSON correctly', () {
      final json = {
        'success': true,
        'status': 'REGISTERED',
        'registeredAt': '2026-10-20T13:42:15',
        'version': 'v3.2',
        'modelName': 'ArcFace MobileFaceNet (512-dim)',
        'embeddingDimension': 512,
        'tokenHash': 'e8f9c18d40a87f12e09b11933df01c7784a9235e8932b12fa9080c3b2190',
        'studentName': 'Nguyễn Văn An',
        'studentCode': '2251120001',
      };

      final model = FaceEnrollmentResultModel.fromJson(json);

      expect(model.success, isTrue);
      expect(model.status, 'REGISTERED');
      expect(model.version, 'v3.2');
      expect(model.embeddingDimension, 512);
      expect(model.tokenHash, 'e8f9c18d40a87f12e09b11933df01c7784a9235e8932b12fa9080c3b2190');
      expect(model.studentName, 'Nguyễn Văn An');
      expect(model.studentCode, '2251120001');
      expect(model.registeredAt?.year, 2026);
    });

    test('AttendanceCheckinRequestModel generates compliant JSON', () {
      const request = AttendanceCheckinRequestModel(
        sessionId: 105,
        slotId: 42,
        qrToken: 'UNICHECK:TOKEN:SECURE',
        wifiBssid: 'AA:BB:CC:DD:EE:01',
        wifiSsid: 'BK_CAMPUS_A2',
        faceSampleBase64: 'data:image/jpeg;base64,sample',
        livenessPassed: true,
        livenessSteps: ['frontal', 'liveness_head_turn_verified'],
        deviceModel: 'Pixel 7 Pro',
      );

      final json = request.toJson();

      expect(json['sessionId'], 105);
      expect(json['slotId'], 42);
      expect(json['qrToken'], 'UNICHECK:TOKEN:SECURE');
      expect(json['wifiBssid'], 'AA:BB:CC:DD:EE:01');
      expect(json['wifiSsid'], 'BK_CAMPUS_A2');
      expect(json['faceSampleBase64'], 'data:image/jpeg;base64,sample');
      expect(json['livenessPassed'], isTrue);
      expect(json['livenessSteps'], ['frontal', 'liveness_head_turn_verified']);
      expect(json['deviceModel'], 'Pixel 7 Pro');
    });

    test('AttendanceCheckinResponseModel parses response correctly', () {
      final json = {
        'id': 1001,
        'studentId': 202,
        'studentCode': '2251120001',
        'studentName': 'Nguyễn Văn An',
        'status': 'PRESENT',
        'method': 'FACE_QR',
        'checkInTime': '2026-10-20T14:05:00',
        'faceConfidence': 0.995,
        'receiptId': '#ATT-20261020-CS101-1234',
        'note': 'Điểm danh đúng giờ',
      };

      final model = AttendanceCheckinResponseModel.fromJson(json);

      expect(model.id, 1001);
      expect(model.studentCode, '2251120001');
      expect(model.studentName, 'Nguyễn Văn An');
      expect(model.status, 'PRESENT');
      expect(model.faceConfidence, 0.995);
      expect(model.receiptId, '#ATT-20261020-CS101-1234');
      expect(model.checkInTime?.hour, 14);
    });
  });

  group('Phase 06 AttendanceController Check-in Unit Tests', () {
    test('submitAttendanceCheckin succeeds and populates receiptId when API returns success',
        () async {
      final mockService = MockAttendanceApiService(shouldCheckinFail: false);
      final controller = AttendanceController(apiService: mockService);

      controller.currentSession.value = const TimetableSlotModel(
        id: 42,
        courseCode: 'CS101',
        courseName: 'Cơ sở lập trình',
      );
      controller.qrPayload.value = QrPayloadModel.parse('UNICHECK:42:A2-101');
      controller.connectedBssid.value = 'AA:BB:CC:DD:EE:01';
      controller.connectedSsid.value = 'BK_CAMPUS_A2';

      final result = await controller.submitAttendanceCheckin(
        faceSampleBase64: 'data:image/jpeg;base64,sample',
        livenessPassed: true,
        livenessSteps: ['frontal', 'liveness_verified'],
      );

      expect(result, isTrue);
      expect(controller.receiptId.value, '#ATT-20261020-CS101-7890');
      expect(controller.diagnosticCode.value, isEmpty);
    });

    test(
        'submitAttendanceCheckin captures TASK-06 backend blocker cleanly without throwing',
        () async {
      final mockService = MockAttendanceApiService(
        shouldCheckinFail: true,
        failMessage:
            'Máy chủ học vụ chưa mở cổng tiếp nhận điểm danh trực tuyến (TASK-06 Blocker: HTTP 404).',
      );
      final controller = AttendanceController(apiService: mockService);

      controller.currentSession.value = const TimetableSlotModel(
        id: 42,
        courseCode: 'CS101',
        courseName: 'Cơ sở lập trình',
      );
      controller.qrPayload.value = QrPayloadModel.parse('UNICHECK:42:A2-101');

      final result = await controller.submitAttendanceCheckin(
        faceSampleBase64: 'data:image/jpeg;base64,sample',
        livenessPassed: true,
      );

      expect(result, isFalse);
      expect(controller.diagnosticCode.value, 'ERR_BACKEND_TASK_06_CHECKIN_UNAVAILABLE');
      expect(controller.diagnosticReason.value, contains('TASK-06 Blocker'));
    });

    test(
        'submitAttendanceCheckin captures backend ERR_3004 (Face not matched) and sets diagnosticCode',
        () async {
      final mockService = MockAttendanceApiService(
        shouldCheckinFail: true,
        failMessage: 'Khuôn mặt không khớp với hồ sơ đã đăng ký',
        failErrorCode: 'ERR_3004',
      );
      final controller = AttendanceController(apiService: mockService);

      controller.currentSession.value = const TimetableSlotModel(
        id: 42,
        courseCode: 'CS101',
        courseName: 'Cơ sở lập trình',
      );
      controller.qrPayload.value = QrPayloadModel.parse('UNICHECK:42:A2-101');

      final result = await controller.submitAttendanceCheckin(
        faceSampleBase64: 'data:image/jpeg;base64,sample',
        livenessPassed: true,
      );

      expect(result, isFalse);
      expect(controller.diagnosticCode.value, 'ERR_3004');
      expect(controller.diagnosticReason.value, contains('Khuôn mặt không khớp'));
    });

    test(
        'submitAttendanceCheckin fails when server returns invalid non-PRESENT/LATE status',
        () async {
      final mockService = MockAttendanceApiService(
        customCheckinResponse: const AttendanceCheckinResponseModel(
          status: 'ABSENT',
          receiptId: '#ATT-20261020-CS101-1',
        ),
      );
      final controller = AttendanceController(apiService: mockService);
      controller.currentSession.value = const TimetableSlotModel(id: 42, courseCode: 'CS101', courseName: 'Cơ sở lập trình');
      controller.qrPayload.value = QrPayloadModel.parse('UNICHECK:42:A2-101');

      final result = await controller.submitAttendanceCheckin(
        faceSampleBase64: 'data:image/jpeg;base64,sample',
        livenessPassed: true,
      );

      expect(result, isFalse);
      expect(controller.diagnosticCode.value, 'ERR_CHECKIN_STATUS_INVALID');
    });

    test(
        'submitAttendanceCheckin fails when server receiptId is missing or empty',
        () async {
      final mockService = MockAttendanceApiService(
        customCheckinResponse: const AttendanceCheckinResponseModel(
          status: 'PRESENT',
          receiptId: null,
        ),
      );
      final controller = AttendanceController(apiService: mockService);
      controller.currentSession.value = const TimetableSlotModel(id: 42, courseCode: 'CS101', courseName: 'Cơ sở lập trình');
      controller.qrPayload.value = QrPayloadModel.parse('UNICHECK:42:A2-101');

      final result = await controller.submitAttendanceCheckin(
        faceSampleBase64: 'data:image/jpeg;base64,sample',
        livenessPassed: true,
      );

      expect(result, isFalse);
      expect(controller.diagnosticCode.value, 'ERR_NO_RECEIPT');
    });
  });

  group('Phase 06 Widget Tests - FaceEnrollmentResultView (Stitch: 28623608e3df4e6b95f2a362ddf3a859)',
      () {
    testWidgets('FaceEnrollmentResultView renders success certificate with all Stitch specs',
        (WidgetTester tester) async {
      final auth = AuthController();
      auth.user.value = UserModel(
        id: 1,
        username: 'student1',
        email: 'student1@unicheck.edu.vn',
        fullName: 'Nguyễn Văn An',
        code: '2251120001',
        role: 'STUDENT',
      );
      Get.put<AuthController>(auth);

      final resultModel = FaceEnrollmentResultModel(
        success: true,
        status: 'REGISTERED',
        registeredAt: DateTime(2026, 10, 20, 13, 42, 15),
        version: 'v3.2',
        modelName: 'ArcFace MobileFaceNet (512-dim)',
        embeddingDimension: 512,
        tokenHash: 'e8f9c18d40a87f12e09b11933df01c7784a9235e8932b12fa9080c3b2190',
        studentName: 'Nguyễn Văn An',
        studentCode: '2251120001',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: FaceEnrollmentResultView(result: resultModel),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar & Headline
      expect(find.text('Kết Quả Xác Thực'), findsOneWidget);
      expect(find.text('Chứng nhận Sinh trắc học'), findsOneWidget);
      expect(find.text('Đăng ký Face-ID thành công!'), findsOneWidget);

      // Certificate Card elements
      expect(find.text('BIÊN NHẬN SINH TRẮC HỌC SỐ'), findsOneWidget);
      expect(find.text('ISO 30107-3'), findsOneWidget);
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      expect(find.text('MSSV: 2251120001'), findsOneWidget);
      expect(find.text('Chép'), findsOneWidget);

      // AI Metrics
      expect(find.text('468 3D Mesh'), findsOneWidget);
      expect(find.text('99.6% (Chuẩn)'), findsOneWidget);
      expect(find.text('Đạt (Liveness)'), findsOneWidget);
      expect(find.text('512-dim'), findsOneWidget);

      // Actions
      expect(find.text('BẮT ĐẦU ĐIỂM DANH BUỔI HỌC NGAY'), findsOneWidget);
      expect(find.text('Về Trang chủ Học vụ'), findsOneWidget);
    });

    testWidgets('FaceEnrollmentResultView renders failure diagnostic when success is false',
        (WidgetTester tester) async {
      final auth = AuthController();
      Get.put<AuthController>(auth);

      const failModel = FaceEnrollmentResultModel(
        success: false,
        status: 'FAILED',
        message: 'Độ sắc nét chưa đạt chuẩn (Clarity 42/100). Vui lòng quét lại.',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const FaceEnrollmentResultView(result: failModel),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không thể xác thực Face-ID'), findsOneWidget);
      expect(find.textContaining('Độ sắc nét chưa đạt chuẩn'), findsOneWidget);
      expect(find.text('QUÉT LẠI TỪ ĐẦU'), findsOneWidget);
      expect(find.text('Về Trang chủ Học vụ'), findsOneWidget);
    });
  });

  group('Phase 06 Widget Tests - FaceEnrollmentView Terms (Stitch: 4033d86502fb4aa7a5043d2451bf2058)',
      () {
    testWidgets('FaceEnrollmentView renders Terms & Preparation layout with Decree 13 and guidelines',
        (WidgetTester tester) async {
      final auth = AuthController();
      auth.user.value = UserModel(
        id: 1,
        username: 'student1',
        email: 'student1@unicheck.edu.vn',
        fullName: 'Nguyễn Văn An',
        code: '2251120001',
        role: 'STUDENT',
      );
      Get.put<AuthController>(auth);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const FaceEnrollmentView(),
        ),
      );
      await tester.pumpAndSettle();

      // Terms screen header & context
      expect(find.text('Điều Khoản & Chuẩn Bị'), findsOneWidget);
      expect(find.text('HỒ SƠ SINH VIÊN'), findsOneWidget);
      expect(find.text('Chưa kích hoạt Face-ID'), findsOneWidget);
      expect(find.text('Cam kết Quyền riêng tư'), findsOneWidget);
      expect(find.text('Nghị định 13/2023'), findsOneWidget);

      // 4 Guidelines
      expect(find.text('Ánh sáng tốt'), findsOneWidget);
      expect(find.text('Bỏ khẩu trang'), findsOneWidget);
      expect(find.text('Khoảng cách 35cm'), findsOneWidget);
      expect(find.text('Chỉ 01 người'), findsOneWidget);

      // Start button
      expect(find.text('BẮT ĐẦU QUÉT KHUÔN MẶT'), findsOneWidget);
    });
  });

  group('Phase 07 Contract Tests - AttendanceCheckinResponseModel deserialization', () {
    test('AttendanceCheckinResponseModel parses full backend check-in payload', () {
      final backendJson = {
        'id': 101,
        'sessionId': 10,
        'studentId': 2,
        'studentCode': 'STU-CK-01',
        'studentName': 'Nguyễn Văn An',
        'status': 'PRESENT',
        'method': 'FACE_QR',
        'checkInTime': '2026-10-20T13:45:35',
        'faceConfidence': 0.945,
        'note': 'Điểm danh qua Mobile Face-ID (Pixel 8 Pro)',
        'receiptId': '#ATT-20261020-CS202-101',
        'courseCode': 'CS202',
        'courseName': 'Cấu trúc dữ liệu và giải thuật',
        'className': 'CS202.01',
        'roomCode': 'B1-202',
        'message': 'Điểm danh thành công',
      };

      final model = AttendanceCheckinResponseModel.fromJson(backendJson);
      expect(model.id, 101);
      expect(model.studentId, 2);
      expect(model.studentCode, 'STU-CK-01');
      expect(model.studentName, 'Nguyễn Văn An');
      expect(model.status, 'PRESENT');
      expect(model.method, 'FACE_QR');
      expect(model.receiptId, '#ATT-20261020-CS202-101');
      expect(model.faceConfidence, 0.945);
      expect(model.checkInTime, isNotNull);
      expect(model.note, contains('Pixel 8 Pro'));
    });
  });
}
