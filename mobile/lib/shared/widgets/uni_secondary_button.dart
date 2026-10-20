import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// UniCheck Standard Mobile Secondary / Outlined Button
/// Based on Google Stitch Secondary Button Spec (Screen: e5dc325d674f478ca6d5ac7c910898a6)
class UniSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;
  final bool isOutlined;
  final Color? textColor;
  final Color? backgroundColor;
  final double height;
  final double? width;

  const UniSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    this.isOutlined = true,
    this.textColor,
    this.backgroundColor,
    this.height = UniSpacing.minButtonHeight,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFg = textColor ?? UniColors.primary;
    final effectiveBg = backgroundColor ??
        (isOutlined ? UniColors.card : UniColors.primaryLight);

    return SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : width,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: effectiveBg,
          foregroundColor: effectiveFg,
          disabledForegroundColor: UniColors.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          side: isOutlined
              ? const BorderSide(color: UniColors.border, width: 1.2)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: UniSpacing.borderRadiusMd,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveFg),
                ),
              )
            : Row(
                mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: effectiveFg),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: UniTypography.labelLarge.copyWith(
                        color: effectiveFg,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
