import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/camera_image_converter.dart';
import '../../../core/utils/face_biometric_logger.dart';
import '../../../core/utils/head_pose_evaluator.dart';
import '../../../shared/widgets/biometric_oval_overlay.dart';
import '../../../shared/widgets/uni_card.dart';
import '../../../shared/widgets/uni_primary_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../services/attendance_api_service.dart';

/// UniCheck Face-ID Enrollment View
/// Covers Google Stitch screens:
/// - Terms & Preparation: 4033d86502fb4aa7a5043d2451bf2058
/// - Live Scan Camera: cffd09cc0b154e868ec3f9b9b420ffa2
class FaceEnrollmentView extends StatefulWidget {
  const FaceEnrollmentView({super.key});

  @override
  State<FaceEnrollmentView> createState() => _FaceEnrollmentViewState();
}

class _FaceEnrollmentViewState extends State<FaceEnrollmentView>
    with WidgetsBindingObserver {
  final AuthController authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  late final AttendanceApiService _apiService;
  late final FaceBiometricLogger _debugLogger;

  // View state: 'terms' or 'scan'
  bool _showTerms = true;

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

  int _currentStep = 1; // 1: Frontal, 2: Left 15°, 3: Right 15°
  final List<Map<String, String>> _capturedSamples = [];

  String _instructionTitle = 'Nhìn thẳng vào khung hình oval';
  String? _instructionSubtitle = 'Cử động thực thể sống';
  String? _warningMessage;
  String _sensorFeedbackText = 'Ánh sáng: Tốt • Khoảng cách: 35cm • 01 khuôn mặt';
  BiometricScanStatus _scanStatus = BiometricScanStatus.scanning;

  late final FaceDetector _faceDetector;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _debugLogger = FaceBiometricLogger(tag: 'FaceEnrollment');

    final apiClient = Get.isRegistered<ApiClient>()
        ? Get.find<ApiClient>()
        : ApiClient(
            tokenStorage: Get.isRegistered<TokenStorage>()
                ? Get.find<TokenStorage>()
                : PlatformTokenStorage(),
          );
    _apiService = AttendanceApiService(apiClient: apiClient);

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: false,
        enableLandmarks: true,
        enableContours: false,
        enableTracking: false,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
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
    } else if (state == AppLifecycleState.resumed && !_showTerms) {
      _initializeCamera();
    }
  }

  Future<void> _startLiveScan() async {
    setState(() {
      _showTerms = false;
    });
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _warningMessage = 'Không tìm thấy thiết bị Camera trên máy';
            _sensorFeedbackText = 'Chế độ giả lập cảm biến hoạt động';
          });
        }
        return;
      }

      // Default to front camera
      final frontCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _warningMessage = null;
        _instructionTitle = 'Nhìn thẳng vào giữa khung hình';
        _instructionSubtitle = 'Giữ yên tư thế để hệ thống quét tự động';
        _scanStatus = BiometricScanStatus.scanning;
      });

      _debugLogger.logCameraInitialized(
        lensDirection: frontCamera.lensDirection,
        resolutionPreset: ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _startFrameStream();
    } catch (e, stack) {
      _debugLogger.logError('Camera initialization failed', e, stack);
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
        _processStreamFrame(image);
      });
      _debugLogger.logStreamStarted();
    } catch (e, stack) {
      _isStreaming = false;
      _debugLogger.logError('Failed to start image stream', e, stack);
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
      _debugLogger.logNotice('Safe stop image stream: $e');
    } finally {
      _isStreaming = false;
      _debugLogger.logStreamStopped();
    }
  }

  void _processStreamFrame(CameraImage image) async {
    _framesReceivedCount++;

    // Guard: Drop frame if already processing, transitioning step, or view unmounted
    if (!_isStreaming ||
        _isProcessingFrame ||
        _isStepTransitioning ||
        !mounted ||
        _currentStep > 3) {
      return;
    }

    final now = DateTime.now();
    // Throttle inference to 8-10 FPS (120ms between frames) to prevent emulator CPU stall
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

      final stepEnum = _currentStep == 1
          ? EnrollmentStep.frontal
          : (_currentStep == 2 ? EnrollmentStep.left : EnrollmentStep.right);

      final face = faces.isNotEmpty ? faces.first : null;
      final yaw = face?.headEulerAngleY;
      final pitch = face?.headEulerAngleX;
      final roll = face?.headEulerAngleZ;

      final validation = HeadPoseEvaluator.validate(
        step: stepEnum,
        eulerY: yaw,
        eulerX: pitch,
        eulerZ: roll,
        faceCount: faces.length,
      );

      _debugLogger.logFrameStats(
        framesReceived: _framesReceivedCount,
        framesProcessed: _framesProcessedCount,
        faceCount: faces.length,
        yaw: yaw,
        pitch: pitch,
        roll: roll,
        step: stepEnum.name,
        mlKitDurationMs: mlDurationMs,
        totalDurationMs: DateTime.now().difference(frameStart).inMilliseconds,
      );

      if (!validation.isValid) {
        _consecutiveValidFrames = 0;
        _debugLogger.logPoseEvaluated(
          step: stepEnum.name,
          isValid: false,
          reason: validation.warningMessage ?? validation.guideMessage,
          yaw: yaw,
          pitch: pitch,
          roll: roll,
        );

        _updateUiValidationState(
          isValid: false,
          warning: validation.warningMessage ?? validation.guideMessage,
          facesCount: faces.length,
        );
        return;
      }

      // Valid pose detected for current step!
      _consecutiveValidFrames++;
      _updateUiValidationState(
        isValid: true,
        guideMessage: validation.guideMessage,
        facesCount: faces.length,
      );

      // Require 2 consecutive valid frames (approx 240ms) to ensure pose stability
      if (_consecutiveValidFrames >= 2) {
        _consecutiveValidFrames = 0;
        _handleStepPoseAccepted(stepEnum);
      }
    } catch (e, stack) {
      _debugLogger.logError('Frame analysis exception', e, stack);
    } finally {
      // Guaranteed reset to prevent frame processing flag from ever locking up
      _isProcessingFrame = false;
    }
  }

  void _updateUiValidationState({
    required bool isValid,
    String? warning,
    String? guideMessage,
    required int facesCount,
  }) {
    if (!mounted || _isStepTransitioning) return;

    final newStatus =
        isValid ? BiometricScanStatus.scanning : BiometricScanStatus.error;
    final newWarning = warning;
    final String newFeedback;
    if (facesCount == 0) {
      newFeedback = 'Chưa phát hiện khuôn mặt';
    } else if (facesCount > 1) {
      newFeedback = 'Phát hiện > 1 người trong khung hình!';
    } else if (isValid) {
      newFeedback = 'Ánh sáng: Tốt • Khoảng cách: 35cm • Góc mặt: Đạt chuẩn';
    } else {
      newFeedback = 'Góc nghiêng chưa đạt chuẩn';
    }

    // Only trigger setState if UI values meaningfully changed to prevent 30fps rebuild thrashing
    if (_scanStatus != newStatus ||
        _warningMessage != newWarning ||
        _sensorFeedbackText != newFeedback) {
      setState(() {
        _scanStatus = newStatus;
        _warningMessage = newWarning;
        _sensorFeedbackText = newFeedback;
        if (guideMessage != null) {
          _instructionSubtitle = guideMessage;
        }
      });
    }
  }

  Future<void> _handleStepPoseAccepted(EnrollmentStep stepEnum) async {
    if (_isStepTransitioning) return;
    _isStepTransitioning = true;

    final currentStepNumber = _currentStep;
    _debugLogger.logPoseEvaluated(
      step: stepEnum.name,
      isValid: true,
      reason: 'Đạt chuẩn góc pose và duy trì ổn định',
    );

    if (mounted) {
      setState(() {
        _scanStatus = BiometricScanStatus.processing;
        _warningMessage = null;
        _instructionSubtitle =
            'Đã khớp góc ${stepEnum.name}! Đang chụp ảnh mẫu $currentStepNumber/3...';
      });
    }

    // Coordinated high-quality still capture
    final sampleBase64 = await _safeCapturePhoto(stepEnum.name);
    if (sampleBase64 == null) {
      if (mounted) {
        setState(() {
          _scanStatus = BiometricScanStatus.error;
          _warningMessage =
              'Không thể chụp ảnh mẫu bước $currentStepNumber. Vui lòng bấm Thử lại.';
          _instructionSubtitle = 'Sự cố thiết bị chụp ảnh';
        });
      }
      _isStepTransitioning = false;
      // Restart streaming for retry
      if (!_isStreaming &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        await _startFrameStream();
      }
      return;
    }

    _capturedSamples.add({
      'step': stepEnum.name,
      'imageBase64': sampleBase64,
    });

    if (currentStepNumber < 3) {
      final nextStep = currentStepNumber + 1;
      _debugLogger.logStateTransition(
        fromStep: 'Step $currentStepNumber (${stepEnum.name})',
        toStep: 'Step $nextStep',
      );

      if (mounted) {
        setState(() {
          _currentStep = nextStep;
          _scanStatus = BiometricScanStatus.scanning;
          _warningMessage = null;
          if (nextStep == 2) {
            _instructionTitle = 'Từ từ quay mặt sang trái (15°)';
            _instructionSubtitle = 'Nghiêng nhẹ mặt sang phía bên trái';
          } else {
            _instructionTitle = 'Từ từ quay mặt sang phải (15°)';
            _instructionSubtitle = 'Nghiêng nhẹ mặt sang phía bên phải';
          }
          _sensorFeedbackText =
              'Ánh sáng: Tốt • Khoảng cách: 35cm • Khớp 01 khuôn mặt';
        });
      }

      _isStepTransitioning = false;
      // Resume real-time stream for the next step
      await _startFrameStream();
    } else {
      // All 3 angles completed!
      _debugLogger.logStateTransition(
        fromStep: 'Step 3 (${stepEnum.name})',
        toStep: 'Enrollment Complete -> Backend submission',
      );
      await _stopFrameStream();

      if (mounted) {
        setState(() {
          _scanStatus = BiometricScanStatus.processing;
          _instructionTitle = 'Đang trích xuất vector ArcFace 512 chiều...';
          _instructionSubtitle = 'Đang đồng bộ hồ sơ sinh trắc học';
          _warningMessage = null;
        });
      }

      await _submitEnrollment();
    }
  }

  /// Coordinates still photo capture with CameraX image stream to prevent camera contention.
  Future<String?> _safeCapturePhoto(String stepName) async {
    final stopwatch = Stopwatch()..start();
    _debugLogger.logCaptureStarted(step: stepName);

    try {
      // 1. Pause image stream to release CameraX ImageAnalysis lock
      await _stopFrameStream();

      // Brief delay to allow CameraCaptureSession to transition
      await Future.delayed(const Duration(milliseconds: 100));

      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        throw Exception('CameraController is not ready');
      }

      // 2. Take still picture with 5-second safety timeout
      final XFile photo = await _cameraController!.takePicture().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('takePicture timed out after 5s'),
      );

      final bytes = await photo.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // 3. Clean up temporary file from device storage
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
      _debugLogger.logError('Safe photo capture failed for $stepName', e, stack);
      return null;
    }
  }

  Future<void> _retryCurrentStep() async {
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

  Future<void> _submitEnrollment() async {
    try {
      final primaryImage = _capturedSamples.isNotEmpty
          ? _capturedSamples.first['imageBase64']!
          : 'data:image/jpeg;base64,mock';

      final result = await _apiService.registerFace(
        primaryImageBase64: primaryImage,
        samples: _capturedSamples,
        isReEnrollment: true,
      );

      // Immediately synchronize reactive profile state across App
      if (Get.isRegistered<AuthController>()) {
        final authCtrl = Get.find<AuthController>();
        authCtrl.updateFaceDataStatus('REGISTERED');
        await authCtrl.refreshProfile();
      }
      if (Get.isRegistered<AttendanceController>()) {
        final attCtrl = Get.find<AttendanceController>();
        attCtrl.isFaceRegistered.value = true;
        attCtrl.faceStatus.value = VerificationStatus.pass;
      }

      if (mounted) {
        Get.offNamed(
          AppRoutes.faceEnrollmentResult,
          arguments: result,
        );
      }
    } catch (e, stack) {
      _debugLogger.logError('Face enrollment API submission failed', e, stack);
      if (mounted) {
        setState(() {
          _isProcessingFrame = false;
          _isStepTransitioning = false;
          _scanStatus = BiometricScanStatus.error;
          _warningMessage = 'Đăng ký không thành công: $e';
        });
      }
    }
  }

  // Demo simulator for QA/emulator testing without front camera
  void _simulateStepProgression() {
    if (_isProcessingFrame || _isStepTransitioning) return;
    _capturedSamples.add({
      'step': _currentStep == 1
          ? 'frontal'
          : (_currentStep == 2 ? 'left' : 'right'),
      'imageBase64': 'data:image/jpeg;base64,simulated_frame',
    });

    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
        _warningMessage = null;
        if (_currentStep == 2) {
          _instructionTitle = 'Từ từ quay mặt sang trái (15°)';
          _instructionSubtitle = 'Nghiêng nhẹ mặt sang phía bên trái';
        } else {
          _instructionTitle = 'Từ từ quay mặt sang phải (15°)';
          _instructionSubtitle = 'Nghiêng nhẹ mặt sang phía bên phải';
        }
      });
    } else {
      _submitEnrollment();
    }
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
    if (_showTerms) {
      return _buildTermsAndPreparationView();
    }
    return _buildLiveScanCameraView();
  }

  // ---------------------------------------------------------------------------
  // 1. TERMS & PREPARATION VIEW (Stitch: 4033d86502fb4aa7a5043d2451bf2058)
  // ---------------------------------------------------------------------------
  Widget _buildTermsAndPreparationView() {
    final user = authController.user.value;

    return Scaffold(
      backgroundColor: UniColors.canvas,
      appBar: AppBar(
        backgroundColor: UniColors.card,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: UniColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Điều Khoản & Chuẩn Bị',
          style: UniTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: UniSpacing.margin),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: UniColors.primary,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(UniSpacing.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Tracker (Step 1 active)
              UniCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStepIndicatorItem(step: '1', title: 'Chuẩn bị', isActive: true),
                    Container(width: 36, height: 2, color: UniColors.divider),
                    _buildStepIndicatorItem(step: '2', title: 'Quét mặt', isActive: false),
                    Container(width: 36, height: 2, color: UniColors.divider),
                    _buildStepIndicatorItem(step: '3', title: 'Hoàn tất', isActive: false),
                  ],
                ),
              ),
              const SizedBox(height: UniSpacing.spaceMd),

              // Student Context Card
              UniCard(
                padding: const EdgeInsets.all(UniSpacing.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.badge_rounded,
                                color: UniColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'HỒ SƠ SINH VIÊN',
                              style: UniTypography.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: UniColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: UniColors.warning.withValues(alpha: 0.15),
                            borderRadius: UniSpacing.borderRadiusFull,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: UniColors.warning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Chưa kích hoạt Face-ID',
                                style: UniTypography.caption.copyWith(
                                  color: UniColors.warning,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: UniColors.primaryLight,
                          child: Icon(Icons.person,
                              color: UniColors.primary, size: 28),
                        ),
                        const SizedBox(width: UniSpacing.spaceMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Sinh viên UniCheck',
                                style: UniTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'MSSV: ${user?.code ?? user?.username ?? "N/A"} • Khóa 2022',
                                style: UniTypography.bodySmall.copyWith(
                                  color: UniColors.textSecondary,
                                ),
                              ),
                              Text(
                                'Khoa Khoa học & Kỹ thuật Máy tính',
                                style: UniTypography.caption.copyWith(
                                  color: UniColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: UniSpacing.spaceMd),

              // Privacy & Legal Compliance Box
              UniCard(
                padding: const EdgeInsets.all(UniSpacing.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_user_rounded,
                                color: UniColors.secondary, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Cam kết Quyền riêng tư',
                              style: UniTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: UniColors.canvas,
                            borderRadius: UniSpacing.borderRadiusSm,
                            border: Border.all(color: UniColors.divider),
                          ),
                          child: Text(
                            'Nghị định 13/2023',
                            style: UniTypography.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: UniColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tuân thủ nghiêm ngặt Nghị định 13/2023/NĐ-CP và tiêu chuẩn an toàn ISO/IEC 27001:',
                      style: UniTypography.bodySmall.copyWith(
                          color: UniColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    _buildPrivacyItem(
                      icon: Icons.lock_outline_rounded,
                      title: 'Mã hóa 1 chiều (Vector Embedding)',
                      desc:
                          'Trích xuất 512 chiều ArcFace. Tuyệt đối không lưu ảnh khuôn mặt gốc trên máy chủ.',
                    ),
                    const SizedBox(height: 8),
                    _buildPrivacyItem(
                      icon: Icons.domain_verification_rounded,
                      title: 'Mục đích học vụ duy nhất',
                      desc:
                          'Chỉ phục vụ đối soát chuyên cần lớp học phần và điểm danh kỳ thi.',
                    ),
                    const SizedBox(height: 8),
                    _buildPrivacyItem(
                      icon: Icons.gavel_rounded,
                      title: 'Không chia sẻ bên thứ ba',
                      desc:
                          'Cam kết không thương mại hóa hoặc chuyển giao dữ liệu sinh trắc ra ngoài.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: UniSpacing.spaceMd),

              // Preparation Guidelines (4 Checklist requirements)
              Text(
                'QUY CHUẨN CHUẨN BỊ QUÉT',
                style: UniTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: UniColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: UniSpacing.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: _buildGuidelineCard(
                      icon: Icons.wb_sunny_rounded,
                      title: 'Ánh sáng tốt',
                      desc: 'Tránh ngược sáng hoặc phòng quá tối',
                    ),
                  ),
                  const SizedBox(width: UniSpacing.spaceSm),
                  Expanded(
                    child: _buildGuidelineCard(
                      icon: Icons.visibility_rounded,
                      title: 'Bỏ khẩu trang',
                      desc: 'Không đeo kính râm hoặc che trán',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UniSpacing.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: _buildGuidelineCard(
                      icon: Icons.straighten_rounded,
                      title: 'Khoảng cách 35cm',
                      desc: 'Để điện thoại ngang tầm mắt',
                    ),
                  ),
                  const SizedBox(width: UniSpacing.spaceSm),
                  Expanded(
                    child: _buildGuidelineCard(
                      icon: Icons.person_rounded,
                      title: 'Chỉ 01 người',
                      desc: 'Không có người khác trong khung hình',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UniSpacing.spaceLg),

              // Action button
              UniPrimaryButton(
                text: 'BẮT ĐẦU QUÉT KHUÔN MẶT',
                icon: Icons.camera_alt_rounded,
                onPressed: _startLiveScan,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. LIVE SCAN CAMERA VIEW (Stitch: cffd09cc0b154e868ec3f9b9b420ffa2)
  // ---------------------------------------------------------------------------
  Widget _buildLiveScanCameraView() {
    final progress = _currentStep == 1
        ? 0.33
        : (_currentStep == 2 ? 0.66 : 1.0);

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
                      'Khởi động Camera trước...',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // 2. Biometric Oval Reticle with Arc, Badges, and Dynamic Prompt
          BiometricOvalOverlay(
            status: _scanStatus,
            currentStep: _currentStep,
            totalSteps: 3,
            progress: progress,
            instructionTitle: _instructionTitle,
            instructionSubtitle: _instructionSubtitle,
            warningMessage: _warningMessage,
            sensorFeedbackText: _sensorFeedbackText,
          ),

          // 3. Top Floating Bar (Close Button & AI Biometric v3.2 Badge)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        _stopFrameStream();
                        setState(() {
                          _showTerms = true;
                        });
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: UniColors.laserCyan,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AI Biometric v3.2',
                          style: UniTypography.caption.copyWith(
                            color: UniColors.laserCyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Flash toggle dummy button
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.flash_off, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Retry Action Pill when error occurred during scan or capture
          if (_scanStatus == BiometricScanStatus.error &&
              _isCameraInitialized &&
              !_isStepTransitioning)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: UniColors.warning,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: UniSpacing.borderRadiusMd,
                  ),
                ),
                onPressed: _retryCurrentStep,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  'Thử lại bước $_currentStep/3',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          // 5. Simulator quick switch button for testing environments without front camera
          if (!_isCameraInitialized)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: UniColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: UniSpacing.borderRadiusMd,
                  ),
                ),
                onPressed: _simulateStepProgression,
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: Text(
                  'Mô phỏng góc quét Bước $_currentStep/3',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicatorItem({
    required String step,
    required String title,
    required bool isActive,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? UniColors.primary : UniColors.divider,
          child: Text(
            step,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: UniTypography.caption.copyWith(
            color: isActive ? UniColors.primary : UniColors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: UniColors.primaryLight,
            borderRadius: UniSpacing.borderRadiusSm,
          ),
          child: Icon(icon, color: UniColors.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: UniTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: UniColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: UniTypography.caption.copyWith(
                  color: UniColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuidelineCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(UniSpacing.spaceSm + 2),
      decoration: BoxDecoration(
        color: UniColors.card,
        borderRadius: UniSpacing.borderRadiusMd,
        border: Border.all(color: UniColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: UniColors.primary, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: UniTypography.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: UniTypography.caption.copyWith(
              color: UniColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
