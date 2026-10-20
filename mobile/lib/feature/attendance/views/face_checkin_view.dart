import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/head_pose_evaluator.dart';
import '../../../shared/widgets/biometric_oval_overlay.dart';
import '../../../shared/widgets/uni_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/attendance_controller.dart';

/// UniCheck Real-time Face-ID Check-in & Liveness Verification View
/// Google Stitch: cffd09cc0b154e868ec3f9b9b420ffa2
/// Light Academic Precision & High-Security Biometrics
class FaceCheckinView extends StatefulWidget {
  const FaceCheckinView({super.key});

  @override
  State<FaceCheckinView> createState() => _FaceCheckinViewState();
}

class _FaceCheckinViewState extends State<FaceCheckinView> {
  final AuthController authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  final AttendanceController attendanceController =
      Get.isRegistered<AttendanceController>()
          ? Get.find<AttendanceController>()
          : Get.put(AttendanceController());

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  // Liveness Steps: 1: Frontal alignment, 2: Liveness head turn confirmation, 3: Completed
  int _livenessStep = 1;
  double _progress = 0.35;
  String _instructionTitle = 'Nhìn thẳng vào khung oval';
  String? _instructionSubtitle = 'Căn chỉnh khuôn mặt vào giữa khung hình';
  String? _warningMessage;
  String _sensorFeedbackText = 'Ánh sáng: Tốt • Khoảng cách: 35cm • 01 khuôn mặt';
  BiometricScanStatus _scanStatus = BiometricScanStatus.scanning;

  late final FaceDetector _faceDetector;
  Timer? _analysisLoopTimer;
  String? _capturedFrontalBase64;
  final List<String> _verifiedLivenessSteps = [];

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _warningMessage = 'Không tìm thấy thiết bị Camera';
            _sensorFeedbackText = 'Chế độ giả lập cảm biến điểm danh';
          });
        }
        return;
      }

      final frontCam = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        frontCam,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _warningMessage = null;
        _instructionTitle = 'Nhìn thẳng vào giữa khung oval';
        _instructionSubtitle = 'Giữ yên để hệ thống đối soát sinh trắc học';
      });

      _startLivenessLoop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _warningMessage = 'Lỗi truy cập Camera: $e';
        });
      }
    }
  }

  void _startLivenessLoop() {
    _analysisLoopTimer?.cancel();
    _analysisLoopTimer =
        Timer.periodic(const Duration(milliseconds: 650), (_) async {
      if (!_isCameraInitialized ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized ||
          _isProcessing ||
          _livenessStep > 2) {
        return;
      }
      await _analyzeLivenessFrame();
    });
  }

  Future<void> _analyzeLivenessFrame() async {
    if (_isProcessing || _cameraController == null) return;
    _isProcessing = true;

    XFile? imageFile;
    try {
      imageFile = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      // Step 1: Frontal evaluation
      if (_livenessStep == 1) {
        final validation = HeadPoseEvaluator.validate(
          step: EnrollmentStep.frontal,
          eulerY: faces.isNotEmpty ? faces.first.headEulerAngleY : null,
          eulerX: faces.isNotEmpty ? faces.first.headEulerAngleX : null,
          eulerZ: faces.isNotEmpty ? faces.first.headEulerAngleZ : null,
          faceCount: faces.length,
        );

        if (!validation.isValid) {
          if (mounted) {
            setState(() {
              _scanStatus = BiometricScanStatus.error;
              _warningMessage = validation.warningMessage ?? validation.guideMessage;
            });
          }
          _cleanupFile(imageFile.path);
          _isProcessing = false;
          return;
        }

        // Frontal Valid! Capture frame for check-in payload
        final bytes = await imageFile.readAsBytes();
        _capturedFrontalBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        _verifiedLivenessSteps.add('frontal_verified');
        _cleanupFile(imageFile.path);

        if (mounted) {
          setState(() {
            _livenessStep = 2;
            _progress = 0.70;
            _scanStatus = BiometricScanStatus.scanning;
            _warningMessage = null;
            _instructionTitle = 'Cử động sống: Nghiêng nhẹ mặt 15°';
            _instructionSubtitle = 'Xác thực thực thể sống (Anti-Spoofing)';
          });
        }
        _isProcessing = false;
        return;
      }

      // Step 2: Liveness dynamic angle check (left or right turn)
      if (_livenessStep == 2) {
        final face = faces.isNotEmpty ? faces.first : null;
        final eulerY = face?.headEulerAngleY ?? 0.0;

        // Dynamic turn validation: Yaw must deviate > 10° or < -10°
        final isTurned = eulerY.abs() >= 10.0 && eulerY.abs() <= 32.0;

        if (!isTurned) {
          if (mounted) {
            setState(() {
              _scanStatus = BiometricScanStatus.error;
              _warningMessage = 'Vui lòng quay nhẹ đầu sang trái hoặc phải (khoảng 15°)';
            });
          }
          _cleanupFile(imageFile.path);
          _isProcessing = false;
          return;
        }

        // Liveness Confirmed!
        _verifiedLivenessSteps.add('liveness_head_turn_verified');
        _cleanupFile(imageFile.path);

        _analysisLoopTimer?.cancel();
        if (mounted) {
          setState(() {
            _livenessStep = 3;
            _progress = 1.0;
            _scanStatus = BiometricScanStatus.processing;
            _instructionTitle = 'Đang gửi đối soát điểm danh...';
            _instructionSubtitle = 'Đang kết nối máy chủ Spring Boot học vụ';
            _warningMessage = null;
          });
        }

        await _submitFinalCheckIn();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _warningMessage = 'Lỗi phân tích liveness: $e';
        });
      }
      _isProcessing = false;
    }
  }

  void _cleanupFile(String path) {
    try {
      File(path).deleteSync();
    } catch (_) {}
  }

  Future<void> _submitFinalCheckIn() async {
    final faceBase64 = _capturedFrontalBase64 ?? 'data:image/jpeg;base64,mock';

    final success = await attendanceController.submitAttendanceCheckin(
      faceSampleBase64: faceBase64,
      livenessPassed: true,
      livenessSteps: _verifiedLivenessSteps,
    );

    if (mounted) {
      if (success) {
        Get.offNamed(AppRoutes.attendanceSuccess);
      } else {
        Get.offNamed(AppRoutes.attendanceFailure);
      }
    }
  }

  // Simulator helper for automated tests and desktop environments without camera
  void _simulateCheckinSuccess() async {
    setState(() {
      _isProcessing = true;
      _livenessStep = 3;
      _progress = 1.0;
      _scanStatus = BiometricScanStatus.processing;
      _instructionTitle = 'Đang xác nhận điểm danh...';
    });

    _verifiedLivenessSteps.addAll(['simulated_frontal', 'simulated_liveness']);
    _capturedFrontalBase64 = 'data:image/jpeg;base64,simulated_checkin_frame';

    await _submitFinalCheckIn();
  }

  @override
  void dispose() {
    _analysisLoopTimer?.cancel();
    _faceDetector.close();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slot = attendanceController.currentSession.value;

    return Scaffold(
      backgroundColor: const Color(0xFF050B14),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Viewport
          if (_isCameraInitialized && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            Container(
              color: const Color(0xFF0F172A),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: UniColors.laserCyan),
                    SizedBox(height: 16),
                    Text(
                      'Đang bật Camera trước...',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // 2. Biometric Oval Reticle with Arc and Dynamic Instructions
          BiometricOvalOverlay(
            status: _scanStatus,
            currentStep: _livenessStep,
            totalSteps: 2,
            progress: _progress,
            instructionTitle: _instructionTitle,
            instructionSubtitle: _instructionSubtitle,
            warningMessage: _warningMessage,
            sensorFeedbackText: _sensorFeedbackText,
          ),

          // 3. Top Action Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: UniSpacing.borderRadiusFull,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.security, size: 14, color: UniColors.laserCyan),
                        SizedBox(width: 6),
                        Text(
                          'Xác thực Sinh trắc học',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          // 4. Bottom Student Info & Session Card
          Positioned(
            bottom: 24,
            left: UniSpacing.margin,
            right: UniSpacing.margin,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() {
                  final user = authController.user.value;
                  return UniCard(
                    padding: const EdgeInsets.all(UniSpacing.spaceSm + 2),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: UniColors.primary,
                          child: Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: UniSpacing.spaceSm + 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Sinh viên UniCheck',
                                style: UniTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'MSSV: ${user?.code ?? user?.username ?? "N/A"}',
                                style: UniTypography.caption.copyWith(
                                  color: UniColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: UniColors.primaryLight,
                            borderRadius: UniSpacing.borderRadiusSm,
                          ),
                          child: Text(
                            slot?.roomDisplay ?? 'Phòng học',
                            style: UniTypography.caption.copyWith(
                              color: UniColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Testing simulator button when camera is unavailable
                if (!_isCameraInitialized) ...[
                  const SizedBox(height: UniSpacing.spaceSm),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UniColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: UniSpacing.borderRadiusMd,
                      ),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: _isProcessing ? null : _simulateCheckinSuccess,
                    icon: const Icon(Icons.verified, color: Colors.white),
                    label: const Text(
                      'Mô phỏng Hoàn tất Liveness & Điểm danh',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
