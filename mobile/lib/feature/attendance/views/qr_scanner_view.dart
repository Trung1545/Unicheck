import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/attendance_controller.dart';

class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView>
    with WidgetsBindingObserver {
  late final MobileScannerController _scannerController;
  final AttendanceController _attendanceController =
      Get.isRegistered<AttendanceController>()
          ? Get.find<AttendanceController>()
          : Get.put(AttendanceController());

  bool _isProcessingCode = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_scannerController.value.isInitialized) {
      return;
    }
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _scannerController.start();
        break;
      case AppLifecycleState.inactive:
        _scannerController.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessingCode) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() {
      _isProcessingCode = true;
    });

    try {
      await _attendanceController.onQrCodeScanned(rawValue);
      if (mounted) {
        Get.toNamed(AppRoutes.attendanceEligibility);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingCode = false;
        });
      }
    }
  }

  void _simulateScanForDemo() async {
    if (_isProcessingCode) return;
    setState(() {
      _isProcessingCode = true;
    });

    final slot = _attendanceController.currentSession.value;
    final mockQr = 'UNICHECK:${slot?.id ?? 101}:${slot?.roomCode ?? 'A4-501'}';

    await _attendanceController.onQrCodeScanned(mockQr);
    if (mounted) {
      Get.toNamed(AppRoutes.attendanceEligibility);
    }
    setState(() {
      _isProcessingCode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final slot = _attendanceController.currentSession.value;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Camera Scanner Preview
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_off_rounded,
                        color: Colors.white70,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Không thể truy cập camera: ${error.errorCode}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _simulateScanForDemo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: UniColors.primary,
                        ),
                        child: const Text('Thử nghiệm mô phỏng QR'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Academic Precision Viewfinder Overlay
          _buildScanOverlay(context),

          // 3. Top Safe Action Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: UniSpacing.margin,
                vertical: UniSpacing.spaceSm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black45,
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),

                      // Screen Title
                      Text(
                        'Quét Mã QR Giảng Đường',
                        style: UniTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Torch Toggle Button
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: _isTorchOn
                              ? UniColors.primary
                              : Colors.black45,
                          shape: const CircleBorder(),
                        ),
                        icon: Icon(
                          _isTorchOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _scannerController.toggleTorch();
                          setState(() {
                            _isTorchOn = !_isTorchOn;
                          });
                        },
                      ),
                    ],
                  ),

                  // Session Info Pill if session selected
                  if (slot != null) ...[
                    const SizedBox(height: UniSpacing.spaceSm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: UniSpacing.borderRadiusFull,
                        border: Border.all(
                          color: Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            size: 14,
                            color: UniColors.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${slot.courseCode} • ${slot.roomDisplay}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 4. Bottom Guidance & Manual Trigger
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(UniSpacing.spaceLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: UniSpacing.borderRadiusMd,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            color: UniColors.accent,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Căn chỉnh mã QR chiếu tại giảng đường vào khung quét để hệ thống đối soát.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: UniSpacing.spaceSm),
                    TextButton.icon(
                      onPressed: _simulateScanForDemo,
                      icon: const Icon(
                        Icons.bolt,
                        color: UniColors.accent,
                        size: 16,
                      ),
                      label: const Text(
                        'Mô phỏng quét mã thử nghiệm (UX Test)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Processing Loader Overlay
          if (_isProcessingCode)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Đang giải mã và đối soát bảo mật...',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanBoxSize = size.width * 0.72;

    return Stack(
      children: [
        // Cutout Mask
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.55),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: scanBoxSize,
                  height: scanBoxSize,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Precision Corner Reticles
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: scanBoxSize,
            height: scanBoxSize,
            child: Stack(
              children: [
                // Top-Left Corner
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: UniColors.accent, width: 4),
                        left: BorderSide(color: UniColors.accent, width: 4),
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
                // Top-Right Corner
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: UniColors.accent, width: 4),
                        right: BorderSide(color: UniColors.accent, width: 4),
                      ),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
                // Bottom-Left Corner
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: UniColors.accent, width: 4),
                        left: BorderSide(color: UniColors.accent, width: 4),
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
                // Bottom-Right Corner
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: UniColors.accent, width: 4),
                        right: BorderSide(color: UniColors.accent, width: 4),
                      ),
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
