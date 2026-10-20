import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'uni_card.dart';

/// UniCheck Standard Academic Metric Card
/// Based on Google Stitch Dashboard 3-Card Metric Grid (Screen: 201c64df9c7d465d8bc8dacc30b91828)
class AttendanceMetricCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String? valueSuffix;
  final String badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final String footnote;
  final Color? iconColor;
  final VoidCallback? onTap;

  const AttendanceMetricCard({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    this.valueSuffix,
    required this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    required this.footnote,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? UniColors.primary;

    return UniCard(
      onTap: onTap,
      padding: const EdgeInsets.all(UniSpacing.spaceSm + 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Label + Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: UniTypography.caption.copyWith(
                  color: UniColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Icon(
                icon,
                size: 18,
                color: effectiveIconColor,
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Big Value Text
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              text: value,
              style: UniTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: UniColors.textPrimary,
                height: 1.1,
              ),
              children: [
                if (valueSuffix != null)
                  TextSpan(
                    text: valueSuffix,
                    style: UniTypography.bodySmall.copyWith(
                      color: UniColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          // Status Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor ?? UniColors.statusPresentBg,
              borderRadius: UniSpacing.borderRadiusSm,
            ),
            child: Text(
              badgeText,
              style: UniTypography.caption.copyWith(
                color: badgeTextColor ?? UniColors.statusPresentText,
                fontWeight: FontWeight.w700,
                fontSize: 9.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 4),

          // Footnote caption
          Text(
            footnote,
            style: UniTypography.caption.copyWith(
              color: UniColors.textMuted,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
