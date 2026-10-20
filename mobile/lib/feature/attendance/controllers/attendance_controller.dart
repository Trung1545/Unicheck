import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/widgets/verification_check_item.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/models/timetable_slot_model.dart';
import '../models/attendance_checkin_request_model.dart';
import '../models/attendance_checkin_response_model.dart';
import '../models/face_status_model.dart';
import '../models/qr_payload_model.dart';
import '../models/room_wifi_ap_model.dart';
import '../services/attendance_api_service.dart';
import '../utils/wifi_validator.dart';

class AttendanceController extends GetxController {
  final AttendanceApiService apiService;
  final WifiValidator wifiValidator;

  AttendanceController({
    AttendanceApiService? apiService,
    WifiValidator? wifiValidator,
  })  : apiService = apiService ??
            AttendanceApiService(
              apiClient: Get.isRegistered<ApiClient>()
                  ? Get.find<ApiClient>()
                  : ApiClient(
                      tokenStorage: Get.isRegistered<TokenStorage>()
                          ? Get.find<TokenStorage>()
                          : PlatformTokenStorage(),
                    ),
            ),
        wifiValidator = wifiValidator ?? WifiValidator();

  final Rxn<TimetableSlotModel> currentSession = Rxn<TimetableSlotModel>();
  final Rxn<QrPayloadModel> qrPayload = Rxn<QrPayloadModel>();

  // Filter chips in SelectAttendanceSessionView: 'all', 'open', 'checked', 'closed'
  final RxString sessionFilter = 'all'.obs;

  // 5 Criteria Verification States
  final Rx<VerificationStatus> qrStatus = VerificationStatus.pending.obs;
  final RxString qrNote = 'Chờ quét mã QR phòng học'.obs;

  final Rx<VerificationStatus> wifiStatus = VerificationStatus.pending.obs;
  final RxString wifiNote = 'Chờ đối soát mạng Wi-Fi giảng đường'.obs;
  final RxnString connectedSsid = RxnString();
  final RxnString connectedBssid = RxnString();

  final Rx<VerificationStatus> timeStatus = VerificationStatus.pending.obs;
  final RxString timeNote = 'Chờ kiểm tra khung giờ ca học'.obs;

  final Rx<VerificationStatus> enrollmentStatus = VerificationStatus.pending.obs;
  final RxString enrollmentNote = 'Chờ đối soát danh sách học phần'.obs;

  final Rx<VerificationStatus> faceStatus = VerificationStatus.pending.obs;
  final RxString faceNote = 'Chờ đối soát dữ liệu Face-ID'.obs;
  final RxBool isFaceRegistered = false.obs;

  final RxBool isEvaluating = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxString diagnosticCode = ''.obs;
  final RxString diagnosticReason = ''.obs;

  // Receipt details for Success screen
  final RxString receiptId = ''.obs;
  final RxString attendanceTimestamp = ''.obs;

  int get passedCriteriaCount {
    int count = 0;
    if (qrStatus.value == VerificationStatus.pass) count++;
    if (wifiStatus.value == VerificationStatus.pass) count++;
    if (timeStatus.value == VerificationStatus.pass) count++;
    if (enrollmentStatus.value == VerificationStatus.pass) count++;
    if (faceStatus.value == VerificationStatus.pass) count++;
    return count;
  }

  bool get isAllPassed => passedCriteriaCount == 5;

  void selectSession(TimetableSlotModel slot) {
    currentSession.value = slot;
  }

  void setFilter(String filter) {
    sessionFilter.value = filter;
  }

  Future<void> onQrCodeScanned(String raw) async {
    final payload = QrPayloadModel.parse(raw);
    qrPayload.value = payload;

    // If currentSession is not set, resolve matching session
    if (currentSession.value == null && Get.isRegistered<DashboardController>()) {
      final dash = Get.find<DashboardController>();
      if (payload.slotId != null) {
        final match = dash.allSlots.firstWhereOrNull((s) => s.id == payload.slotId);
        if (match != null) {
          currentSession.value = match;
        }
      }
      if (currentSession.value == null && payload.roomCode != null) {
        final match = dash.todaySlots.firstWhereOrNull((s) =>
            s.roomCode?.toLowerCase() == payload.roomCode?.toLowerCase() ||
            s.roomName?.toLowerCase() == payload.roomCode?.toLowerCase());
        if (match != null) {
          currentSession.value = match;
        }
      }
      if (currentSession.value == null && dash.activeAttendanceSession != null) {
        currentSession.value = dash.activeAttendanceSession;
      }
    }

    await runEligibilityChecks();
  }

  Future<void> runEligibilityChecks() async {
    isEvaluating.value = true;
    diagnosticCode.value = '';
    diagnosticReason.value = '';

    try {
      final slot = currentSession.value;
      final payload = qrPayload.value;

      // 1. Evaluate QR Code
      if (payload != null && payload.isValid) {
        qrStatus.value = VerificationStatus.pass;
        final timeStr = '${payload.timestamp.hour.toString().padLeft(2, '0')}:${payload.timestamp.minute.toString().padLeft(2, '0')}:${payload.timestamp.second.toString().padLeft(2, '0')}';
        qrNote.value = 'Mã QR phòng học đã ký số bảo mật lúc $timeStr.';
      } else {
        qrStatus.value = VerificationStatus.fail;
        qrNote.value = 'Mã QR không hợp lệ hoặc đã hết hạn phiên.';
        diagnosticCode.value = 'ERR_QR_INVALID_SIGNATURE';
        diagnosticReason.value = 'Mã QR quét được không đáp ứng cấu trúc bảo mật hợp lệ.';
      }

      // 2. Evaluate Wi-Fi & Room Location
      wifiStatus.value = VerificationStatus.checking;
      List<RoomWifiAccessPointModel> allowedAps = [];
      if (slot?.roomId != null) {
        try {
          allowedAps = await apiService.getRoomWifiAccessPoints(slot!.roomId!);
        } catch (e) {
          if (kDebugMode) {
            print('Could not fetch room wifi APs: $e');
          }
        }
      }

      final wifiResult = await wifiValidator.validateRoomWifi(
        allowedAps: allowedAps,
        expectedRoomCode: slot?.roomCode ?? slot?.roomName,
      );

      connectedSsid.value = wifiResult.connectedSsid;
      connectedBssid.value = wifiResult.connectedBssid;

      if (wifiResult.isMatched) {
        wifiStatus.value = VerificationStatus.pass;
        wifiNote.value = wifiResult.reason;
      } else {
        wifiStatus.value = VerificationStatus.fail;
        wifiNote.value = wifiResult.reason;
        if (diagnosticCode.value.isEmpty) {
          diagnosticCode.value = 'ERR_WIFI_OUT_OF_RANGE';
          diagnosticReason.value =
              'Thiết bị chưa kết nối vào trạm phát Wi-Fi phòng học theo quy định.';
        }
      }

      // 3. Evaluate Class Time Window
      timeStatus.value = VerificationStatus.checking;
      final now = DateTime.now();
      bool isInWindow = true;
      if (slot != null && slot.startTime != null && slot.endTime != null) {
        final startParts = slot.startTime!.split(':');
        final endParts = slot.endTime!.split(':');
        if (startParts.length >= 2 && endParts.length >= 2) {
          final startH = int.tryParse(startParts[0]) ?? 0;
          final startM = int.tryParse(startParts[1]) ?? 0;
          final endH = int.tryParse(endParts[0]) ?? 23;
          final endM = int.tryParse(endParts[1]) ?? 59;

          final slotStart = DateTime(now.year, now.month, now.day, startH, startM)
              .subtract(const Duration(minutes: 30)); // 30-min window before class
          final slotEnd = DateTime(now.year, now.month, now.day, endH, endM)
              .add(const Duration(minutes: 30));

          if (slot.date != null && !slot.isScheduledOn(now)) {
            isInWindow = false;
          } else if (now.isBefore(slotStart) || now.isAfter(slotEnd)) {
            isInWindow = false;
          }
        }
      }

      if (isInWindow) {
        timeStatus.value = VerificationStatus.pass;
        timeNote.value =
            'Trong khung giờ cho phép (${slot?.timeSlot ?? 'Hiện tại'}). Ca học đang diễn ra hợp lệ.';
      } else {
        timeStatus.value = VerificationStatus.fail;
        timeNote.value =
            'Ngoài khung giờ mở điểm danh cho ca học này (${slot?.timeSlot ?? 'Khác ngày'}).';
        if (diagnosticCode.value.isEmpty) {
          diagnosticCode.value = 'ERR_TIME_WINDOW_CLOSED';
          diagnosticReason.value =
              'Khung giờ điểm danh ca học đã kết thúc hoặc chưa đến thời gian mở.';
        }
      }

      // 4. Evaluate Course Enrollment
      enrollmentStatus.value = VerificationStatus.checking;
      bool isEnrolled = true;
      if (Get.isRegistered<DashboardController>() && slot != null) {
        final dash = Get.find<DashboardController>();
        if (dash.enrollments.isNotEmpty) {
          final found = dash.enrollments.any((e) =>
              e.courseCode.toLowerCase() == slot.courseCode.toLowerCase() ||
              (slot.className != null &&
                  e.className?.toLowerCase() == slot.className?.toLowerCase()));
          if (!found) {
            isEnrolled = false;
          }
        }
      }

      if (isEnrolled) {
        enrollmentStatus.value = VerificationStatus.pass;
        enrollmentNote.value =
            'Sinh viên có tên trong danh sách lớp chính thức. Đủ điều kiện chuyên cần.';
      } else {
        enrollmentStatus.value = VerificationStatus.fail;
        enrollmentNote.value =
            'Mã sinh viên không nằm trong danh sách học phần ${slot?.courseCode ?? ''}.';
        if (diagnosticCode.value.isEmpty) {
          diagnosticCode.value = 'ERR_NOT_ENROLLED_IN_COURSE';
          diagnosticReason.value =
              'Tài khoản sinh viên chưa đăng ký hoặc không thuộc lớp học phần này.';
        }
      }

      // 5. Evaluate Face-ID Registration
      faceStatus.value = VerificationStatus.checking;
      FaceStatusModel faceModel = const FaceStatusModel();
      try {
        faceModel = await apiService.getFaceStatus();
      } catch (_) {
        // Fallback to AuthController user face status if offline/test
        if (Get.isRegistered<AuthController>()) {
          final user = Get.find<AuthController>().user.value;
          final reg = user?.faceDataStatus == 'REGISTERED' ||
              user?.faceDataStatus == 'COMPLETED';
          faceModel = FaceStatusModel(isRegistered: reg);
        }
      }

      isFaceRegistered.value = faceModel.isRegistered;
      if (faceModel.isRegistered) {
        faceStatus.value = VerificationStatus.pass;
        faceNote.value =
            'Mẫu sinh trắc học đã đăng ký trong hồ sơ. Camera trước sẵn sàng.';
      } else {
        faceStatus.value = VerificationStatus.fail;
        faceNote.value =
            'Chưa có dữ liệu Face-ID hoặc mẫu chưa được duyệt. Cần thiết lập Face-ID.';
        if (diagnosticCode.value.isEmpty) {
          diagnosticCode.value = 'ERR_BIOMETRICS_NOT_REGISTERED';
          diagnosticReason.value =
              'Sinh viên chưa hoàn tất thiết lập hồ sơ khuôn mặt sinh trắc học.';
        }
      }
    } finally {
      isEvaluating.value = false;
    }
  }

  Future<bool> submitAttendanceCheckin({
    required String faceSampleBase64,
    required bool livenessPassed,
    List<String>? livenessSteps,
  }) async {
    isSubmitting.value = true;
    diagnosticCode.value = '';
    diagnosticReason.value = '';

    try {
      final slot = currentSession.value;
      final payload = qrPayload.value;

      final request = AttendanceCheckinRequestModel(
        sessionId: payload?.sessionId ?? slot?.id,
        slotId: slot?.id,
        qrToken: payload?.token ?? payload?.raw ?? payload?.roomCode,
        wifiBssid: connectedBssid.value,
        wifiSsid: connectedSsid.value,
        faceSampleBase64: faceSampleBase64,
        livenessPassed: livenessPassed,
        livenessSteps: livenessSteps ?? ['frontal', 'liveness_verified'],
      );

      final AttendanceCheckinResponseModel response;
      try {
        response = await apiService.checkInFace(request);
      } catch (err) {
        if (kDebugMode) {
          print('Attendance checkin API: $err');
        }
        diagnosticCode.value = 'ERR_BACKEND_TASK_06_CHECKIN_UNAVAILABLE';
        diagnosticReason.value = err is ApiException
            ? err.message
            : 'Máy chủ điểm danh chưa tiếp nhận yêu cầu check-in (TASK-06 In Progress).';
        return false;
      }

      generateReceipt(customReceiptId: response.receiptId);
      return true;
    } finally {
      isSubmitting.value = false;
    }
  }

  void generateReceipt({String? customReceiptId}) {
    if (customReceiptId != null && customReceiptId.isNotEmpty) {
      receiptId.value = customReceiptId;
    } else {
      final now = DateTime.now();
      final y = now.year.toString();
      final m = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');
      final rand = (1000 + (now.millisecond * 7) % 9000).toString();
      final code = currentSession.value?.courseCode ?? 'ATT';
      receiptId.value = '#ATT-$y$m$d-$code-$rand';
    }

    final now = DateTime.now();
    final d = now.day.toString().padLeft(2, '0');
    final m = now.month.toString().padLeft(2, '0');
    final y = now.year.toString();
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final sec = now.second.toString().padLeft(2, '0');
    attendanceTimestamp.value = '$d/$m/$y $h:$min:$sec';
  }
}
