import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/head_pose_evaluator.dart';
import '../../auth/controllers/auth_controller.dart';

class FaceEnrollmentView extends StatefulWidget {
  const FaceEnrollmentView({super.key});

  @override
  State<FaceEnrollmentView> createState() => _FaceEnrollmentViewState();
}

class _FaceEnrollmentViewState extends State<FaceEnrollmentView> {
  final AuthController authController = Get.find<AuthController>();
  late final ApiClient _apiClient;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _alignmentMessage = 'Khớp khuôn mặt vào khung Oval';
  int _currentStep = 1; // 1: Frontal, 2: Left 15°, 3: Right 15°
  final List<Map<String, String>> _capturedSamples = [];

  late final FaceDetector _faceDetector;

  @override
  void initState() {
    super.initState();
    _apiClient = Get.isRegistered<ApiClient>()
        ? Get.find<ApiClient>()
        : ApiClient(
            tokenStorage: Get.isRegistered<TokenStorage>()
                ? Get.find<TokenStorage>()
                : PlatformTokenStorage(),
          );

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: false,
        enableLandmarks: true,
        enableContours: false,
        enableTracking: false,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _alignmentMessage = 'Không tìm thấy thiết bị Camera';
        });
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
        _alignmentMessage = 'Nhìn thẳng vào camera và giữ ổn định';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _alignmentMessage = 'Lỗi truy cập Camera: $e';
        });
      }
    }
  }

  Future<void> _captureCurrentFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _alignmentMessage = 'Đang phân tích góc mặt Bước $_currentStep/3...';
    });

    try {
      final XFile imageFile = await _cameraController!.takePicture();

      // 1. Run Real Head Pose Estimation using Google ML Kit
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
            _isProcessing = false;
            _alignmentMessage = validation.warningMessage ?? validation.guideMessage;
          });
        }
        return; // REJECT: Do NOT advance step when pose is invalid!
      }

      // 2. Pose Valid! Store frame
      final bytes = await imageFile.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final stepName = _currentStep == 1
          ? 'frontal'
          : (_currentStep == 2 ? 'left' : 'right');

      _capturedSamples.add({
        'step': stepName,
        'imageBase64': base64String,
      });

      if (_currentStep < 3) {
        setState(() {
          _currentStep++;
          _isProcessing = false;
          _alignmentMessage = _currentStep == 2
              ? 'Nghiêng nhẹ mặt sang trái (15°)'
              : 'Nghiêng nhẹ mặt sang phải (15°)';
        });
      } else {
        // Complete 3 angles -> submit to backend
        await _submitEnrollment();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _alignmentMessage = 'Chụp ảnh không thành công: $e';
        });
      }
    }
  }

  Future<void> _submitEnrollment() async {
    setState(() {
      _alignmentMessage = 'Đang trích xuất vector ArcFace 512 chiều...';
    });

    try {
      final primaryImage = _capturedSamples.first['imageBase64']!;
      final response = await _apiClient.dio.post(
        '/attendance/register-face',
        data: {
          'imageBase64': primaryImage,
          'samples': _capturedSamples,
          'isReEnrollment': true,
        },
      );

      if (mounted && response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        setState(() {
          _isProcessing = false;
          _alignmentMessage = 'Đăng ký thất bại: ${response.data?['message'] ?? 'Lỗi kết nối'}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _alignmentMessage = 'Lỗi gửi dữ liệu lên máy chủ: $e';
        });
      }
    }
  }

  void _showSuccessDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Text('Đăng Ký Thành Công!', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sinh viên: ${authController.user.value?.fullName ?? ""}',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 6),
            const Text('Mô hình: ArcFace MobileFaceNet (512-dim)',
                style: TextStyle(color: Color(0xFF06B6D4), fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'UniCheck cam kết KHÔNG lưu ảnh gốc, chỉ lưu vector toán học an toàn.',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () {
              Get.back(); // close dialog
              Get.back(); // return to student shell
            },
            child: const Text('Hoàn tất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  void dispose() {
    _faceDetector.close();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Đăng Ký Face-ID (v4.2)', style: TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Guidance Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF06B6D4), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _alignmentMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Camera Viewport & Oval Guideline
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isCameraInitialized && _cameraController != null)
                        CameraPreview(_cameraController!)
                      else
                        const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),

                      // Darkening mask
                      Container(color: Colors.black.withValues(alpha: 0.35)),

                      // Face Oval Guideline
                      Container(
                        width: 240,
                        height: 320,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _isProcessing ? const Color(0xFF10B981) : const Color(0xFF06B6D4),
                            width: 3,
                          ),
                          borderRadius: const BorderRadius.all(Radius.elliptical(120, 160)),
                        ),
                        child: const Stack(
                          alignment: Alignment.center,
                          children: [
                            Divider(color: Colors.cyan, thickness: 0.5),
                            VerticalDivider(color: Colors.cyan, thickness: 0.5),
                          ],
                        ),
                      ),

                      // Step Indicator Overlay
                      Positioned(
                        top: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            'Bước $_currentStep / 3',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      // Non-Liveness Disclaimer
                      const Positioned(
                        bottom: 12,
                        child: Text(
                          'Passive Frame Analysis (Chưa xác nhận Anti-Spoofing MiniFASNet)',
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Action Controls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isProcessing ? null : _captureCurrentFrame,
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: Text(
                        _isProcessing ? 'Đang xử lý...' : 'Chụp khung hình ($_currentStep/3)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
