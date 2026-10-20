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

class _FaceEnrollmentViewState extends State<FaceEnrollmentView> {
  final AuthController authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  late final AttendanceApiService _apiService;

  // View state: 'terms' or 'scan'
  bool _showTerms = true;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  int _currentStep = 1; // 1: Frontal, 2: Left 15°, 3: Right 15°
  final List<Map<String, String>> _capturedSamples = [];

  String _instructionTitle = 'Nhìn thẳng vào khung hình oval';
  String? _instructionSubtitle = 'Cử động thực thể sống';
  String? _warningMessage;
  String _sensorFeedbackText = 'Ánh sáng: Tốt • Khoảng cách: 35cm • 01 khuôn mặt';
  BiometricScanStatus _scanStatus = BiometricScanStatus.scanning;

  late final FaceDetector _faceDetector;
  Timer? _continuousAnalysisTimer;

  @override
  void initState() {
    super.initState();
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
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _warningMessage = null;
        _instructionTitle = 'Nhìn thẳng vào giữa khung hình';
        _instructionSubtitle = 'Giữ yên tư thế để hệ thống quét tự động';
      });

      _startContinuousAnalysisLoop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _warningMessage = 'Lỗi truy cập Camera: $e';
        });
      }
    }
  }

  void _startContinuousAnalysisLoop() {
    _continuousAnalysisTimer?.cancel();
    // Periodically capture frame and run head pose evaluation (NO manual shutter button!)
    _continuousAnalysisTimer =
        Timer.periodic(const Duration(milliseconds: 700), (_) async {
      if (!_isCameraInitialized ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized ||
          _isProcessing ||
          _currentStep > 3) {
        return;
      }
      await _analyzeCurrentFrame();
    });
  }

  Future<void> _analyzeCurrentFrame() async {
    if (_isProcessing || _cameraController == null) return;
    _isProcessing = true;

    XFile? imageFile;
    try {
      imageFile = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      final currentStepEnum = _currentStep == 1
          ? EnrollmentStep.frontal
          : (_currentStep == 2 ? EnrollmentStep.left : EnrollmentStep.right);

      final face = faces.isNotEmpty ? faces.first : null;
      final validation = HeadPoseEvaluator.validate(
        step: currentStepEnum,
        eulerY: face?.headEulerAngleY,
        eulerX: face?.headEulerAngleX,
        eulerZ: face?.headEulerAngleZ,
        faceCount: faces.length,
      );

      if (!validation.isValid) {
        if (mounted) {
          setState(() {
            _scanStatus = BiometricScanStatus.error;
            _warningMessage = validation.warningMessage ?? validation.guideMessage;
            if (faces.isEmpty) {
              _sensorFeedbackText = 'Chưa phát hiện khuôn mặt';
            } else if (faces.length > 1) {
              _sensorFeedbackText = 'Phát hiện > 1 người trong khung hình!';
            } else {
              _sensorFeedbackText = 'Góc nghiêng chưa đạt chuẩn';
            }
          });
        }
        // Cleanup temp file
        try {
          File(imageFile.path).deleteSync();
        } catch (_) {}
        _isProcessing = false;
        return;
      }

      // Valid pose detected! Record frame bytes and advance step
      final bytes = await imageFile.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final stepName = _currentStep == 1
          ? 'frontal'
          : (_currentStep == 2 ? 'left' : 'right');

      _capturedSamples.add({
        'step': stepName,
        'imageBase64': base64String,
      });

      // Cleanup temp file
      try {
        File(imageFile.path).deleteSync();
      } catch (_) {}

      if (_currentStep < 3) {
        if (mounted) {
          setState(() {
            _currentStep++;
            _scanStatus = BiometricScanStatus.scanning;
            _warningMessage = null;
            if (_currentStep == 2) {
              _instructionTitle = 'Từ từ quay mặt sang trái (15°)';
              _instructionSubtitle = 'Nghiêng nhẹ mặt sang phía bên trái';
            } else {
              _instructionTitle = 'Từ từ quay mặt sang phải (15°)';
              _instructionSubtitle = 'Nghiêng nhẹ mặt sang phía bên phải';
            }
            _sensorFeedbackText = 'Ánh sáng: Tốt • Khoảng cách: 35cm • Khớp 01 khuôn mặt';
          });
        }
        _isProcessing = false;
      } else {
        // Complete 3 angles -> submit to backend
        _continuousAnalysisTimer?.cancel();
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _warningMessage = 'Lỗi phân tích khung hình: $e';
        });
      }
      _isProcessing = false;
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

      if (mounted) {
        // Navigate to Google Stitch Certificate Result View (replacing old AlertDialog!)
        Get.offNamed(
          AppRoutes.faceEnrollmentResult,
          arguments: result,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _scanStatus = BiometricScanStatus.error;
          _warningMessage = 'Đăng ký không thành công: $e';
        });
      }
    }
  }

  // Demo simulator for QA/emulator testing without front camera
  void _simulateStepProgression() {
    if (_isProcessing) return;
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
    _continuousAnalysisTimer?.cancel();
    _faceDetector.close();
    _cameraController?.dispose();
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

          // 4. Simulator quick switch button for testing environments without front camera
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
