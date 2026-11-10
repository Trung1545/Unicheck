import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../dashboard/models/timetable_slot_model.dart';
import '../models/attendance_recheck_model.dart';
import '../controllers/attendance_controller.dart';

/// Painter tạo lớp phủ tối xung quanh khung quét QR bằng kỹ thuật Path.combine(difference).
/// Loại bỏ hoàn toàn lỗi màn hình đen do ColorFiltered / BlendMode.srcOut trên Flutter Impeller và Android Texture.
class QrScannerOverlayPainter extends CustomPainter {
  final Rect scanBoxRect;
  final double borderRadius;
  final Color overlayColor;

  const QrScannerOverlayPainter({
    required this.scanBoxRect,
    this.borderRadius = 20.0,
    this.overlayColor = const Color(0x8C000000), // 55% transparent black
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Toàn bộ kích thước khung nhìn màn hình
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 2. Hình chữ nhật bo góc của khung quét ở giữa
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          scanBoxRect,
          Radius.circular(borderRadius),
        ),
      );

    // 3. Trừ vùng khung quét ra khỏi nền: Không vẽ bất kỳ pixel nào vào khung giữa
    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant QrScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanBoxRect != scanBoxRect ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.overlayColor != overlayColor;
  }
}

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
      autoStart: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.arguments is Map) {
        final args = Get.arguments as Map;
        if (args['slot'] is TimetableSlotModel) {
          _attendanceController.selectSession(args['slot'] as TimetableSlotModel);
        }
        if (args['recheck'] is AttendanceRecheckModel) {
          _attendanceController.setActiveRecheckRequest(args['recheck'] as AttendanceRecheckModel);
        }
      }
    });
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
        if (!_scannerController.value.isRunning) {
          _scannerController.start();
        }
        break;
      case AppLifecycleState.inactive:
        if (_scannerController.value.isRunning) {
          _scannerController.stop();
        }
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _navigateToEligibility() async {
    if (_scannerController.value.isRunning) {
      try {
        await _scannerController.stop();
      } catch (_) {}
    }
    if (mounted) {
      await Get.toNamed(AppRoutes.attendanceEligibility);
      if (mounted && !_scannerController.value.isRunning) {
        try {
          await _scannerController.start();
        } catch (_) {}
      }
    }
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
        await _navigateToEligibility();
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
      await _navigateToEligibility();
    }
    if (mounted) {
      setState(() {
        _isProcessingCode = false;
      });
    }
  }

  void _showOtpInputDialog() {
    final textController = TextEditingController();
    String? localError;
    bool isSubmittingOtp = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.pin_rounded, color: UniColors.accent, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Mã OTP Điểm Danh',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.of(bottomSheetCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nhập mã OTP gồm đúng 6 chữ số đang hiển thị trên màn hình giảng viên:',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: textController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 14,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    hintStyle: const TextStyle(
                      color: Colors.white24,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 14,
                      fontFamily: 'monospace',
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: UniColors.accent, width: 2),
                    ),
                  ),
                  onChanged: (val) {
                    if (localError != null) {
                      setModalState(() {
                        localError = null;
                      });
                    }
                  },
                ),
                if (localError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            localError!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isSubmittingOtp
                      ? null
                      : () async {
                          final code = textController.text.trim();
                          if (code.length != 6 || int.tryParse(code) == null) {
                            setModalState(() {
                              localError = 'Vui lòng nhập đúng 6 chữ số OTP.';
                            });
                            return;
                          }

                          setModalState(() {
                            isSubmittingOtp = true;
                            localError = null;
                          });

                          try {
                            await _attendanceController.onOtpSubmitted(code);
                            if (mounted && bottomSheetCtx.mounted) {
                              Navigator.of(bottomSheetCtx).pop();
                              await _navigateToEligibility();
                            }
                          } catch (err) {
                            setModalState(() {
                              isSubmittingOtp = false;
                              localError = err is ApiException
                                  ? err.message
                                  : 'Xác thực mã OTP thất bại. Vui lòng kiểm tra lại.';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UniColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmittingOtp
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Xác nhận OTP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isSubmittingOtp ? null : () => Navigator.of(bottomSheetCtx).pop(),
                  child: const Text('Hủy / Quay lại quét QR', style: TextStyle(color: Colors.white60)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showManualTokenInputDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.bug_report, color: UniColors.accent, size: 22),
            SizedBox(width: 8),
            Text(
              'Nhập / Dán Mã QR Test',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chế độ kiểm thử Emulator (Debug Only).\nDán mã Static Test QR (bắt đầu bằng STQR:) hoặc token từ màn hình Giảng viên:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              maxLines: 3,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: 'STQR:sessionId:token...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: UniColors.accent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final raw = textController.text.trim();
              if (raw.isEmpty) return;
              Navigator.of(dialogCtx).pop();
              setState(() {
                _isProcessingCode = true;
              });
              try {
                await _attendanceController.onQrCodeScanned(raw);
                if (mounted) {
                  await _navigateToEligibility();
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isProcessingCode = false;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: UniColors.primary,
            ),
            child: const Text('Xác nhận QR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getReadableCameraError(MobileScannerException error) {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Quyền truy cập camera bị từ chối. Vui lòng cấp quyền máy ảnh để điểm danh QR.';
      case MobileScannerErrorCode.unsupported:
        return 'Thiết bị hoặc camera giả lập hiện tại không hỗ trợ chế độ quét này.';
      case MobileScannerErrorCode.controllerAlreadyInitialized:
        return 'Camera đang được tái kích hoạt. Vui lòng đợi trong giây lát.';
      case MobileScannerErrorCode.controllerDisposed:
        return 'Bộ điều khiển camera đã giải phóng.';
      case MobileScannerErrorCode.controllerUninitialized:
        return 'Camera đang chuẩn bị luồng dữ liệu...';
      case MobileScannerErrorCode.genericError:
        final detail = error.errorDetails?.message;
        if (detail != null && detail.isNotEmpty) {
          return 'Không thể kết nối camera: $detail';
        }
        return 'Không thể kết nối camera giả lập. Vui lòng nhấn Thử lại hoặc dùng chế độ Dán mã QR Test.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final slot = _attendanceController.currentSession.value;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Scanner Preview (Fill full screen behind overlay)
          MobileScanner(
            controller: _scannerController,
            fit: BoxFit.cover,
            onDetect: _handleBarcode,
            placeholderBuilder: (context, child) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(UniColors.accent),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Đang kết nối camera giảng đường...',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              );
            },
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
                        _getReadableCameraError(error),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (!_scannerController.value.isRunning) {
                                try {
                                  await _scannerController.start();
                                } catch (_) {}
                              }
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Thử lại'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: UniColors.primary,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _simulateScanForDemo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white24,
                            ),
                            child: const Text('Mô phỏng QR'),
                          ),
                        ],
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _showManualTokenInputDialog,
                          icon: const Icon(
                            Icons.paste_rounded,
                            color: UniColors.accent,
                            size: 16,
                          ),
                          label: const Text(
                            'Dán mã Static Test QR (Debug Emulator)',
                            style: TextStyle(
                              color: UniColors.accent,
                              fontSize: 12,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: UniColors.accent),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Academic Precision Viewfinder Overlay with Vector Difference Cutout
          _buildScanOverlay(context),

          // 3. Top Safe Action Bar
          _buildTopActionBar(context, slot),

          // 4. Bottom Guidance & Manual Trigger
          _buildBottomGuidance(context),

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
    final scanBoxRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanBoxSize,
      height: scanBoxSize,
    );

    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Lớp phủ vector: Trong suốt hoàn toàn ở vùng trung tâm scanBoxRect, không bị ảnh hưởng bởi lỗi blend mode
          CustomPaint(
            size: size,
            painter: QrScannerOverlayPainter(
              scanBoxRect: scanBoxRect,
              borderRadius: 20.0,
              overlayColor: Colors.black.withValues(alpha: 0.55),
            ),
          ),

          // 4 góc định vị Academic Precision
          Center(
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
      ),
    );
  }

  Widget _buildTopActionBar(BuildContext context, TimetableSlotModel? slot) {
    return SafeArea(
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

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Flip Camera Button (VirtualScene Rear <-> Webcam0 Front)
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                        shape: const CircleBorder(),
                      ),
                      tooltip: 'Đổi camera (Trước / Sau)',
                      icon: const Icon(
                        Icons.flip_camera_android_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        try {
                          await _scannerController.switchCamera();
                        } catch (e) {
                          if (kDebugMode) {
                            print('Switch camera failed: $e');
                          }
                        }
                      },
                    ),

                    const SizedBox(width: 4),

                    // Torch Toggle Button
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: _isTorchOn
                            ? UniColors.primary
                            : Colors.black45,
                        shape: const CircleBorder(),
                      ),
                      tooltip: 'Đèn Flash',
                      icon: Icon(
                        _isTorchOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        try {
                          await _scannerController.toggleTorch();
                          setState(() {
                            _isTorchOn = !_isTorchOn;
                          });
                        } catch (e) {
                          if (kDebugMode) {
                            print('Toggle torch unsupported on emulator: $e');
                          }
                        }
                      },
                    ),
                  ],
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
    );
  }

  Widget _buildBottomGuidance(BuildContext context) {
    return SafeArea(
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
              // Button "Nhập mã OTP điểm danh"
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showOtpInputDialog,
                  icon: const Icon(Icons.pin_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'Nhập mã OTP điểm danh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UniColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
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
              if (kDebugMode) ...[
                const SizedBox(height: UniSpacing.spaceSm),
                OutlinedButton.icon(
                  onPressed: _showManualTokenInputDialog,
                  icon: const Icon(
                    Icons.paste_rounded,
                    color: UniColors.accent,
                    size: 16,
                  ),
                  label: const Text(
                    'Dán mã QR Test (Debug Emulator)',
                    style: TextStyle(
                      color: UniColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: UniColors.accent),
                    backgroundColor: Colors.black45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
