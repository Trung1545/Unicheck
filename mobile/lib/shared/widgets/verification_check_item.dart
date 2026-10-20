import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'uni_card.dart';

enum VerificationStatus {
  pass, // Đạt (Emerald)
  fail, // Không đạt (Rose/Red)
  checking, // Đang đối soát (Amber / Spinner)
  pending, // Chờ lượt (Muted)
}

/// UniCheck Attendance Criteria Checklist Item
/// Based on Google Stitch Screen: cf28a360666e440bb4802ac1414ebeb7
class VerificationCheckItem extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;
  final VerificationStatus status;
  final String? customStatusText;
  final String? note;
  final VoidCallback? onRetry;

  const VerificationCheckItem({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.status,
    this.customStatusText,
    this.note,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig();

    return UniCard(
      padding: const EdgeInsets.all(UniSpacing.spaceMd),
      borderColor: status == VerificationStatus.fail
          ? UniColors.error.withValues(alpha: 0.5)
          : null,
      backgroundColor: status == VerificationStatus.fail
          ? const Color(0xFFFFF5F5)
          : UniColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Box
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusConfig.iconBoxColor,
                  borderRadius: UniSpacing.borderRadiusSm,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: statusConfig.iconColor,
                ),
              ),

              const SizedBox(width: UniSpacing.spaceSm + 2),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$stepNumber. $title',
                      style: UniTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: UniTypography.bodySmall.copyWith(
                        color: UniColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Status Badge Pill
              _buildStatusPill(statusConfig),
            ],
          ),

          // Optional Extra Note or Retry Action
          if (note != null ||
              (status == VerificationStatus.fail && onRetry != null)) ...[
            const SizedBox(height: UniSpacing.spaceSm),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: UniColors.canvas,
                borderRadius: UniSpacing.borderRadiusSm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: UniColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      note ?? 'Tiêu chí chưa đạt. Vui lòng thử lại.',
                      style: UniTypography.caption.copyWith(
                        color: UniColors.textSecondary,
                      ),
                    ),
                  ),
                  if (status == VerificationStatus.fail && onRetry != null)
                    InkWell(
                      onTap: onRetry,
                      child: Text(
                        'Thử lại',
                        style: UniTypography.caption.copyWith(
                          color: UniColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusPill(_StatusConfig config) {
    if (status == VerificationStatus.checking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: UniSpacing.borderRadiusFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(config.textColor),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              customStatusText ?? config.label,
              style: UniTypography.caption.copyWith(
                color: config.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: UniSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: config.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            customStatusText ?? config.label,
            style: UniTypography.caption.copyWith(
              color: config.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig() {
    switch (status) {
      case VerificationStatus.pass:
        return const _StatusConfig(
          label: 'Đạt',
          iconBoxColor: UniColors.statusPresentBg,
          iconColor: UniColors.statusPresent,
          backgroundColor: UniColors.statusPresentBg,
          textColor: UniColors.statusPresentText,
          dotColor: UniColors.statusPresent,
        );
      case VerificationStatus.fail:
        return const _StatusConfig(
          label: 'Chưa đạt',
          iconBoxColor: UniColors.statusAbsentBg,
          iconColor: UniColors.error,
          backgroundColor: UniColors.statusAbsentBg,
          textColor: UniColors.statusAbsentText,
          dotColor: UniColors.error,
        );
      case VerificationStatus.checking:
        return const _StatusConfig(
          label: 'Đang kiểm tra',
          iconBoxColor: UniColors.statusLateBg,
          iconColor: UniColors.warning,
          backgroundColor: UniColors.statusLateBg,
          textColor: UniColors.statusLateText,
          dotColor: UniColors.warning,
        );
      case VerificationStatus.pending:
        return const _StatusConfig(
          label: 'Chờ',
          iconBoxColor: Color(0xFFF1F5F9),
          iconColor: UniColors.textMuted,
          backgroundColor: Color(0xFFF1F5F9),
          textColor: UniColors.textSecondary,
          dotColor: UniColors.textMuted,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color iconBoxColor;
  final Color iconColor;
  final Color backgroundColor;
  final Color textColor;
  final Color dotColor;

  const _StatusConfig({
    required this.label,
    required this.iconBoxColor,
    required this.iconColor,
    required this.backgroundColor,
    required this.textColor,
    required this.dotColor,
  });
}
