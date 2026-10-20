import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// UniCheck Standard Academic Loading State Widget
/// Based on Google Stitch Screen: be7be0462f9c4a41a404eb0d4a44fb37
class UniLoadingState extends StatelessWidget {
  final String title;
  final String? subtitle;

  const UniLoadingState({
    super.key,
    this.title = 'Đang tải dữ liệu học vụ...',
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UniSpacing.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: UniColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(UniColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: UniSpacing.spaceMd),
            Text(
              title,
              textAlign: TextAlign.center,
              style: UniTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: UniSpacing.spaceXs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: UniTypography.bodySmall.copyWith(
                  color: UniColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
