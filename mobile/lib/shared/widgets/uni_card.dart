import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// UniCheck Standard Academic Surface Card
/// Based on Google Stitch Card Specification (Screen: e5dc325d674f478ca6d5ac7c910898a6)
class UniCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  final Color? accentStripeColor;
  final String? title;
  final IconData? titleIcon;
  final Widget? trailing;

  const UniCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(UniSpacing.spaceMd),
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.width,
    this.height,
    this.accentStripeColor,
    this.title,
    this.titleIcon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (title != null || titleIcon != null || trailing != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (titleIcon != null) ...[
                Icon(
                  titleIcon,
                  size: 20,
                  color: UniColors.primary,
                ),
                const SizedBox(width: 8),
              ],
              if (title != null)
                Expanded(
                  child: Text(
                    title!,
                    style: UniTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: UniSpacing.spaceSm),
          child,
        ],
      );
    }

    Widget cardBody = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? UniColors.card,
        borderRadius: UniSpacing.borderRadiusLg,
        border: Border.all(
          color: borderColor ?? UniColors.border,
          width: 1,
        ),
        boxShadow: UniSpacing.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (accentStripeColor != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 5,
              child: Container(color: accentStripeColor),
            ),
          Padding(
            padding: EdgeInsets.only(
              left: (accentStripeColor != null ? 5 : 0) +
                  (padding?.horizontal ?? UniSpacing.spaceMd * 2) / 2,
              right: (padding?.horizontal ?? UniSpacing.spaceMd * 2) / 2,
              top: (padding?.vertical ?? UniSpacing.spaceMd * 2) / 2,
              bottom: (padding?.vertical ?? UniSpacing.spaceMd * 2) / 2,
            ),
            child: content,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: UniSpacing.borderRadiusLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: UniSpacing.borderRadiusLg,
          splashColor: UniColors.primaryLight,
          highlightColor: Colors.transparent,
          child: cardBody,
        ),
      );
    }

    return cardBody;
  }
}
