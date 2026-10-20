import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum BiometricScanStatus {
  scanning, // Đang quét và kiểm tra góc đầu
  processing, // Đang trích xuất vector ArcFace
  success, // Đã hoàn thành nhận diện
  error, // Lỗi hoặc góc mặt không hợp lệ
}

/// UniCheck Standard Biometric Oval Viewfinder Overlay
/// Based on Google Stitch Screen: cffd09cc0b154e868ec3f9b9b420ffa2
/// PURE PRESENTATIONAL UI - Does not manipulate camera streams or AI pipelines.
class BiometricOvalOverlay extends StatelessWidget {
  final BiometricScanStatus status;
  final int currentStep; // 1: Frontal, 2: Left, 3: Right
  final int totalSteps; // Usually 3
  final String instructionTitle;
  final String? instructionSubtitle;
  final String? warningMessage;
  final double progress; // 0.0 to 1.0
  final String? sensorFeedbackText;
  final double ovalWidth;
  final double ovalHeight;

  const BiometricOvalOverlay({
    super.key,
    this.status = BiometricScanStatus.scanning,
    this.currentStep = 1,
    this.totalSteps = 3,
    required this.instructionTitle,
    this.instructionSubtitle,
    this.warningMessage,
    this.progress = 0.33,
    this.sensorFeedbackText,
    this.ovalWidth = 240.0,
    this.ovalHeight = 320.0,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = _getBorderColor();

    return Stack(
      children: [
        // 1. Semi-transparent dark mask with oval transparent hole
        CustomPaint(
          size: Size.infinite,
          painter: _OvalHoleCutoutPainter(
            ovalWidth: ovalWidth,
            ovalHeight: ovalHeight,
          ),
        ),

        // 2. Oval border with circular progress arc and crosshairs
        Center(
          child: SizedBox(
            width: ovalWidth + 30,
            height: ovalHeight + 30,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Oval progress arc
                CustomPaint(
                  size: Size(ovalWidth + 24, ovalHeight + 24),
                  painter: _OvalProgressPainter(
                    progress: progress,
                    borderColor: borderColor,
                    isProcessing: status == BiometricScanStatus.processing,
                  ),
                ),

                // Center crosshair micro-brackets
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CustomPaint(
                    painter: _CrosshairBracketPainter(
                      color: borderColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),

                // Floating progress pill at bottom of oval
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                      borderRadius: UniSpacing.borderRadiusFull,
                      border: Border.all(color: Colors.white24, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (status == BiometricScanStatus.processing)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  UniColors.laserCyan),
                            ),
                          )
                        else
                          Icon(
                            status == BiometricScanStatus.success
                                ? Icons.check_circle
                                : Icons.sync,
                            size: 13,
                            color: borderColor,
                          ),
                        const SizedBox(width: 5),
                        Text(
                          'Tiến độ: ${(progress * 100).toInt()}%',
                          style: UniTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Top / Bottom Instruction Controls
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Dynamic instruction banner
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: UniSpacing.screenMargin),
                child: _buildInstructionBanner(),
              ),

              const Spacer(),

              // 3-Angle Step Badges
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: UniSpacing.screenMargin),
                child: _buildAngleStepBadges(),
              ),

              const SizedBox(height: 10),

              // Sensor feedback chips (Light, Distance, Face count)
              if (sensorFeedbackText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                      borderRadius: UniSpacing.borderRadiusFull,
                    ),
                    child: Text(
                      sensorFeedbackText!,
                      style: UniTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionBanner() {
    final hasWarning = warningMessage != null && warningMessage!.isNotEmpty;
    final isError = status == BiometricScanStatus.error || hasWarning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isError
            ? const Color(0xFF450A0A).withValues(alpha: 0.88)
            : const Color(0xFF0F172A).withValues(alpha: 0.82),
        borderRadius: UniSpacing.borderRadiusLg,
        border: Border.all(
          color: isError ? UniColors.error : Colors.white24,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isError
                  ? UniColors.error.withValues(alpha: 0.25)
                  : UniColors.accent.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isError
                  ? Icons.warning_amber_rounded
                  : (currentStep == 1
                      ? Icons.face_rounded
                      : (currentStep == 2
                          ? Icons.turn_left_rounded
                          : Icons.turn_right_rounded)),
              color: isError ? UniColors.error : UniColors.laserCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasWarning ? warningMessage! : instructionTitle,
                  style: UniTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (instructionSubtitle != null && !hasWarning) ...[
                  const SizedBox(height: 2),
                  Text(
                    instructionSubtitle!,
                    style: UniTypography.caption.copyWith(
                      color: Colors.white70,
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

  Widget _buildAngleStepBadges() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        borderRadius: UniSpacing.borderRadiusMd,
        border: Border.all(color: Colors.white12, width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStepBadge(
              stepIndex: 1,
              title: 'Nhìn thẳng',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildStepBadge(
              stepIndex: 2,
              title: 'Nghiêng trái 15°',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildStepBadge(
              stepIndex: 3,
              title: 'Nghiêng phải 15°',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBadge({
    required int stepIndex,
    required String title,
  }) {
    final isDone =
        currentStep > stepIndex || status == BiometricScanStatus.success;
    final isCurrent =
        currentStep == stepIndex && status != BiometricScanStatus.success;

    Color bg;
    Color fg;
    IconData icon;

    if (isDone) {
      bg = UniColors.accent.withValues(alpha: 0.25);
      fg = UniColors.laserCyan;
      icon = Icons.check_circle_rounded;
    } else if (isCurrent) {
      bg = UniColors.primary.withValues(alpha: 0.35);
      fg = Colors.white;
      icon = Icons.radio_button_checked_rounded;
    } else {
      bg = Colors.white.withValues(alpha: 0.06);
      fg = Colors.white54;
      icon = Icons.radio_button_unchecked_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: UniSpacing.borderRadiusSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              title,
              style: UniTypography.caption.copyWith(
                color: fg,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor() {
    switch (status) {
      case BiometricScanStatus.scanning:
        return UniColors.laserCyan;
      case BiometricScanStatus.processing:
        return const Color(0xFF60A5FA);
      case BiometricScanStatus.success:
        return UniColors.statusPresent;
      case BiometricScanStatus.error:
        return UniColors.error;
    }
  }
}

/// Custom Painter for the background dark cutout overlay
class _OvalHoleCutoutPainter extends CustomPainter {
  final double ovalWidth;
  final double ovalHeight;

  const _OvalHoleCutoutPainter({
    required this.ovalWidth,
    required this.ovalHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xB3000000) // 70% black
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(rect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _OvalHoleCutoutPainter oldDelegate) {
    return oldDelegate.ovalWidth != ovalWidth ||
        oldDelegate.ovalHeight != ovalHeight;
  }
}

/// Custom Painter for the glowing oval progress line
class _OvalProgressPainter extends CustomPainter {
  final double progress;
  final Color borderColor;
  final bool isProcessing;

  const _OvalProgressPainter({
    required this.progress,
    required this.borderColor,
    required this.isProcessing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width - 10,
      height: size.height - 10,
    );

    // Track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawOval(rect, trackPaint);

    // Progress Arc
    final progressPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _OvalProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.isProcessing != isProcessing;
  }
}

/// Custom Painter for micro-bracket crosshairs
class _CrosshairBracketPainter extends CustomPainter {
  final Color color;

  const _CrosshairBracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const arm = 6.0;

    // Top-Left
    canvas.drawLine(const Offset(0, 0), const Offset(arm, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, arm), paint);

    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - arm, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, arm), paint);

    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(arm, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height - arm), paint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - arm, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - arm), paint);
  }

  @override
  bool shouldRepaint(covariant _CrosshairBracketPainter oldDelegate) =>
      oldDelegate.color != color;
}
