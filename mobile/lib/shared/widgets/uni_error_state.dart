import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'uni_primary_button.dart';

/// UniCheck Standard Academic Error State Widget
/// Based on Google Stitch Error / Alert Components (Screen: e33ee574d1d84c8a8c5a65c09d27f83c)
class UniErrorState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String retryButtonText;
  final VoidCallback? onRetry;
  final bool isCompact;

  const UniErrorState({
    super.key,
    this.icon = Icons.wifi_off_rounded,
    this.title = 'Mất kết nối máy chủ',
    required this.message,
    this.retryButtonText = 'Thử lại',
    this.onRetry,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.all(UniSpacing.spaceMd),
        decoration: BoxDecoration(
          color: UniColors.statusAbsentBg,
          borderRadius: UniSpacing.borderRadiusMd,
          border: Border.all(color: const Color(0xFFFECACA), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: UniColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: UniTypography.labelMedium.copyWith(
                      color: UniColors.statusAbsentText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: UniTypography.caption.copyWith(
                      color: UniColors.statusAbsentText.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: UniColors.error,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(retryButtonText),
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UniSpacing.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: UniColors.statusAbsentBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: UniColors.error,
              ),
            ),
            const SizedBox(height: UniSpacing.spaceMd),
            Text(
              title,
              textAlign: TextAlign.center,
              style: UniTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: UniColors.textPrimary,
              ),
            ),
            const SizedBox(height: UniSpacing.spaceXs + 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: UniTypography.bodyMedium.copyWith(
                  color: UniColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: UniSpacing.spaceLg),
              UniPrimaryButton(
                text: retryButtonText,
                onPressed: onRetry,
                icon: Icons.refresh_rounded,
                isFullWidth: false,
                height: 42,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
