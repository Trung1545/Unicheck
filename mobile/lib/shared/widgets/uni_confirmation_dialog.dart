import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'uni_primary_button.dart';
import 'uni_secondary_button.dart';

/// UniCheck Standard Academic Confirmation Dialog
/// Based on Google Stitch Dialog Components (Screen: e5dc325d674f478ca6d5ac7c910898a6)
class UniConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final IconData icon;
  final bool isDestructive;
  final Widget? customContent;

  const UniConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Xác nhận',
    this.cancelText = 'Hủy bỏ',
    required this.onConfirm,
    this.onCancel,
    this.icon = Icons.help_outline_rounded,
    this.isDestructive = false,
    this.customContent,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Xác nhận',
    String cancelText = 'Hủy bỏ',
    IconData icon = Icons.help_outline_rounded,
    bool isDestructive = false,
    Widget? customContent,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => UniConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: icon,
        isDestructive: isDestructive,
        customContent: customContent,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = isDestructive ? UniColors.error : UniColors.primary;
    final iconBgColor =
        isDestructive ? UniColors.statusAbsentBg : UniColors.primaryLight;

    return Dialog(
      elevation: 0,
      backgroundColor: UniColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: UniSpacing.borderRadiusXl,
        side: const BorderSide(color: UniColors.border, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(UniSpacing.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Icon Badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: iconColor,
                ),
              ),

              const SizedBox(height: UniSpacing.spaceMd),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: UniTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: UniColors.textPrimary,
                ),
              ),

              const SizedBox(height: UniSpacing.spaceSm),

              // Description Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: UniTypography.bodyMedium.copyWith(
                  color: UniColors.textSecondary,
                  height: 1.45,
                ),
              ),

              if (customContent != null) ...[
                const SizedBox(height: UniSpacing.spaceMd),
                customContent!,
              ],

              const SizedBox(height: UniSpacing.spaceLg),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: UniSecondaryButton(
                      text: cancelText,
                      onPressed:
                          onCancel ?? () => Navigator.of(context).pop(false),
                      isFullWidth: true,
                      height: 44,
                    ),
                  ),
                  const SizedBox(width: UniSpacing.spaceSm + 2),
                  Expanded(
                    child: UniPrimaryButton(
                      text: confirmText,
                      onPressed: onConfirm,
                      backgroundColor:
                          isDestructive ? UniColors.error : UniColors.primary,
                      isFullWidth: true,
                      height: 44,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
