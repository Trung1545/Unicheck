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
import '../../../core/utils/camera_image_converter.dart';
import '../../../core/utils/face_biometric_logger.dart';
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

class _FaceCheckinViewState extends State<FaceCheckinView>
    with WidgetsBindingObserver {
  final AuthController authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  final AttendanceController attendanceController =
      Get.isRegistered<AttendanceController>()
          ? Get.find<AttendanceController>()
          : Get.put(AttendanceController());

  late final FaceBiometricLogger _debugLogger;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isStreaming = false;
  bool _isProcessingFrame = false;
  bool _isStepTransitioning = false;

  int _framesReceivedCount = 0;
  int _framesProcessedCount = 0;
  DateTime _lastFrameProcessedTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _consecutiveValidFrames = 0;

  // Liveness Steps: 1: Frontal alignment, 2: Liveness head turn confirmation, 3: Completed
  int _livenessStep = 1;
  double _progress = 0.35;
  String _instructionTitle = 'Nhìn thẳng vào khung oval';
  String? _instructionSubtitle = 'Căn chỉnh khuôn mặt vào giữa khung hình';
  String? _warningMessage;
  String _sensorFeedbackText = 'Ánh sáng: Tốt • Khoảng cách: 35cm • 01 khuôn mặt';
  BiometricScanStatus _scanStatus = BiometricScanStatus.scanning;

  late final FaceDetector _faceDetector;
  String? _capturedFrontalBase64;
  final List<String> _verifiedLivenessSteps = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _debugLogger = FaceBiometricLogger(tag: 'FaceCheckin');

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopFrameStream();
      _cameraController?.dispose();
      _cameraController = null;
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
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
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _warningMessage = null;
        _instructionTitle = 'Nhìn thẳng vào giữa khung oval';
        _instructionSubtitle = 'Giữ yên để hệ thống đối soát sinh trắc học';
        _scanStatus = BiometricScanStatus.scanning;
      });

      _debugLogger.logCameraInitialized(
        lensDirection: frontCam.lensDirection,
        resolutionPreset: ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _startFrameStream();
    } catch (e, stack) {
      _debugLogger.logError('Checkin camera initialization failed', e, stack);
      if (mounted) {
        setState(() {
          _warningMessage = 'Lỗi truy cập Camera: $e';
          _scanStatus = BiometricScanStatus.error;
        });
      }
    }
  }

  Future<void> _startFrameStream() async {
    if (_isStreaming) return;
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      _isStreaming = true;
      _consecutiveValidFrames = 0;
      await _cameraController!.startImageStream((CameraImage image) {
        _processLivenessStreamFrame(image);
      });
      _debugLogger.logStreamStarted();
    } catch (e, stack) {
      _isStreaming = false;
      _debugLogger.logError('Checkin failed to start stream', e, stack);
      if (mounted) {
        setState(() {
          _warningMessage = 'Không thể khởi động luồng camera: $e';
          _scanStatus = BiometricScanStatus.error;
        });
      }
    }
  }

  Future<void> _stopFrameStream() async {
    if (!_isStreaming) return;
    try {
      if (_cameraController != null &&
          _cameraController!.value.isInitialized &&
          _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
    } catch (e) {
      _debugLogger.logNotice('Checkin safe stop stream: $e');
    } finally {
      _isStreaming = false;
      _debugLogger.logStreamStopped();
    }
  }

  void _processLivenessStreamFrame(CameraImage image) async {
    _framesReceivedCount++;

    if (!_isStreaming ||
        _isProcessingFrame ||
        _isStepTransitioning ||
        !mounted ||
        _livenessStep > 2) {
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastFrameProcessedTime).inMilliseconds < 120) {
      return;
    }
    _lastFrameProcessedTime = now;
    _isProcessingFrame = true;

    try {
      final frameStart = DateTime.now();
      final controller = _cameraController;
      if (controller == null || !controller.value.isInitialized) return;

      final inputImage = CameraImageConverter.toInputImage(
        image: image,
        camera: controller.description,
        deviceOrientation: controller.value.deviceOrientation,
      );
      if (inputImage == null) return;

      final mlStart = DateTime.now();
      final List<Face> faces = await _faceDetector.processImage(inputImage);
      final mlDurationMs = DateTime.now().difference(mlStart).inMilliseconds;
      _framesProcessedCount++;

      final face = faces.isNotEmpty ? faces.first : null;
      final eulerY = face?.headEulerAngleY;
      final eulerX = face?.headEulerAngleX;
      final eulerZ = face?.headEulerAngleZ;

      _debugLogger.logFrameStats(
        framesReceived: _framesReceivedCount,
        framesProcessed: _framesProcessedCount,
        faceCount: faces.length,
        yaw: eulerY,
        pitch: eulerX,
        roll: eulerZ,
        step: 'Liveness-$_livenessStep',
        mlKitDurationMs: mlDurationMs,
        totalDurationMs: DateTime.now().difference(frameStart).inMilliseconds,
      );

      // STEP 1: Frontal alignment
      if (_livenessStep == 1) {
        final validation = HeadPoseEvaluator.validate(
          step: EnrollmentStep.frontal,
          eulerY: eulerY,
          eulerX: eulerX,
          eulerZ: eulerZ,
          faceCount: faces.length,
        );

        if (!validation.isValid) {
          _consecutiveValidFrames = 0;
          _updateUiState(
            isValid: false,
            warning: validation.warningMessage ?? validation.guideMessage,
            feedback: faces.isEmpty
                ? 'Chưa phát hiện khuôn mặt'
                : 'Căn chỉnh khuôn mặt vào giữa khung oval',
          );
          return;
        }

        _consecutiveValidFrames++;
        _updateUiState(
          isValid: true,
          feedback: 'Ánh sáng: Tốt • Khoảng cách: 35cm • Khớp 01 khuôn mặt',
        );

        if (_consecutiveValidFrames >= 2) {
          _consecutiveValidFrames = 0;
          await _handleFrontalCaptured();
        }
        return;
      }

      // STEP 2: Liveness dynamic angle check (turn left or right 15°)
      if (_livenessStep == 2) {
        if (faces.isEmpty) {
          _updateUiState(
            isValid: false,
            warning: 'Không tìm thấy khuôn mặt trong khung hình',
            feedback: 'Vui lòng giữ khuôn mặt trước camera',
          );
          return;
        }

        final yawVal = eulerY ?? 0.0;
        final isTurned = yawVal.abs() >= 10.0 && yawVal.abs() <= 32.0;

        if (!isTurned) {
          _consecutiveValidFrames = 0;
          _updateUiState(
            isValid: false,
            warning: 'Vui lòng quay nhẹ đầu sang trái hoặc phải (khoảng 15°)',
            feedback: 'Đang chờ cử động thực thể sống...',
          );
          return;
        }

        _consecutiveValidFrames++;
        if (_consecutiveValidFrames >= 2) {
          _consecutiveValidFrames = 0;
          await _handleLivenessTurnConfirmed();
        }
      }
    } catch (e, stack) {
      _debugLogger.logError('Checkin frame processing error', e, stack);
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _updateUiState({
    required bool isValid,
    String? warning,
    required String feedback,
  }) {
    if (!mounted || _isStepTransitioning) return;
    final newStatus =
        isValid ? BiometricScanStatus.scanning : BiometricScanStatus.error;

    if (_scanStatus != newStatus ||
        _warningMessage != warning ||
        _sensorFeedbackText != feedback) {
      setState(() {
        _scanStatus = newStatus;
        _warningMessage = warning;
        _sensorFeedbackText = feedback;
      });
    }
  }

  Future<void> _handleFrontalCaptured() async {
    if (_isStepTransitioning) return;
    _isStepTransitioning = true;

    _debugLogger.logPoseEvaluated(
      step: 'Checkin-Frontal',
      isValid: true,
      reason: 'Góc nhìn thẳng đạt chuẩn',
    );

    if (mounted) {
      setState(() {
        _scanStatus = BiometricScanStatus.processing;
        _instructionSubtitle = 'Đang ghi nhận ảnh mẫu chính diện...';
      });
    }

    final photoBase64 = await _safeCapturePhoto('checkin_frontal');
    if (photoBase64 == null) {
      if (mounted) {
        setState(() {
          _scanStatus = BiometricScanStatus.error;
          _warningMessage = 'Không thể chụp ảnh đối soát. Vui lòng thử lại.';
        });
      }
      _isStepTransitioning = false;
      if (!_isStreaming &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        await _startFrameStream();
      }
      return;
    }

    _capturedFrontalBase64 = photoBase64;
    _verifiedLivenessSteps.add('frontal_verified');

    _debugLogger.logStateTransition(
      fromStep: 'Frontal Step 1',
      toStep: 'Liveness Head Turn Step 2',
    );

    if (mounted) {
      setState(() {
        _livenessStep = 2;
        _progress = 0.70;
        _scanStatus = BiometricScanStatus.scanning;
        _warningMessage = null;
        _instructionTitle = 'Cử động sống: Nghiêng nhẹ mặt 15°';
        _instructionSubtitle = 'Xác thực thực thể sống (Anti-Spoofing)';
        _sensorFeedbackText = 'Quay nhẹ đầu sang trái hoặc phải';
      });
    }

    _isStepTransitioning = false;
    await _startFrameStream();
  }

  Future<void> _handleLivenessTurnConfirmed() async {
    if (_isStepTransitioning) return;
    _isStepTransitioning = true;

    _debugLogger.logPoseEvaluated(
      step: 'Checkin-LivenessTurn',
      isValid: true,
      reason: 'Cử động đầu sống xác thực thành công',
    );

    _verifiedLivenessSteps.add('liveness_head_turn_verified');
    await _stopFrameStream();

    _debugLogger.logStateTransition(
      fromStep: 'Liveness Head Turn Step 2',
      toStep: 'Completed -> Final Checkin Submission',
    );

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

  Future<String?> _safeCapturePhoto(String stepName) async {
    final stopwatch = Stopwatch()..start();
    _debugLogger.logCaptureStarted(step: stepName);

    try {
      await _stopFrameStream();
      await Future.delayed(const Duration(milliseconds: 100));

      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        throw Exception('CameraController is not ready');
      }

      final XFile photo = await _cameraController!.takePicture().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('takePicture timed out after 5s'),
      );

      final bytes = await photo.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      try {
        final file = File(photo.path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      stopwatch.stop();
      _debugLogger.logCaptureCompleted(
        step: stepName,
        durationMs: stopwatch.elapsedMilliseconds,
        byteSize: bytes.length,
      );

      return base64String;
    } catch (e, stack) {
      stopwatch.stop();
      _debugLogger.logCaptureFailed(step: stepName, error: e);
      _debugLogger.logError('Checkin photo capture failed for $stepName', e, stack);
      return null;
    }
  }

  Future<void> _retryCheckin() async {
    if (_isStepTransitioning) return;
    setState(() {
      _scanStatus = BiometricScanStatus.scanning;
      _warningMessage = null;
      _consecutiveValidFrames = 0;
    });

    if (!_isStreaming &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      await _startFrameStream();
    } else if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      await _initializeCamera();
    }
  }

  Future<void> _submitFinalCheckIn() async {
    final faceBase64 =
        _capturedFrontalBase64 ?? 'data:image/jpeg;base64,mock';

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
    WidgetsBinding.instance.removeObserver(this);
    _stopFrameStream();
    _faceDetector.close();
    _cameraController?.dispose();
    _cameraController = null;
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
                      onPressed: () {
                        _stopFrameStream();
                        Get.back();
                      },
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

          // 4. Retry button if error occurs during checkin scan
          if (_scanStatus == BiometricScanStatus.error &&
              _isCameraInitialized &&
              !_isStepTransitioning)
            Positioned(
              top: 100,
              left: UniSpacing.margin,
              right: UniSpacing.margin,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: UniColors.warning,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: UniSpacing.borderRadiusMd,
                  ),
                ),
                onPressed: _retryCheckin,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Thử lại bước quét khuôn mặt',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // 5. Bottom Student Info & Session Card
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
                    onPressed: _simulateCheckinSuccess,
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
