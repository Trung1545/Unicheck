import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'uni_secondary_button.dart';

/// UniCheck Standard Academic Empty State Widget
/// Based on Google Stitch Empty States (Screen: 04f28f5550b446529b8929a541a68dbd & 6a863a458210432b8a8f46ec8a199842)
class UniEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonTap;

  const UniEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonTap,
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
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: UniColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: UniColors.primary,
              ),
            ),
            const SizedBox(height: UniSpacing.spaceMd),
            Text(
              title,
              textAlign: TextAlign.center,
              style: UniTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
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
            if (buttonText != null && onButtonTap != null) ...[
              const SizedBox(height: UniSpacing.spaceLg),
              UniSecondaryButton(
                text: buttonText!,
                onPressed: onButtonTap,
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
