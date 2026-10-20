import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum AttendanceStatus {
  present, // Có mặt
  late, // Đi muộn
  absent, // Vắng không phép
  excused, // Vắng có phép / Đang đối soát
  danger, // Nguy cơ cấm thi
  pending, // Chờ điểm danh / Đang diễn ra
  ongoing, // Đang diễn ra
  scheduled, // Sắp tới
}

/// UniCheck Standard Academic Attendance Status Badge
/// Based on Google Stitch Status Badge Tokens (Screen: e5dc325d674f478ca6d5ac7c910898a6)
class AttendanceStatusBadge extends StatelessWidget {
  final AttendanceStatus status;
  final String? customLabel;
  final bool showDot;
  final IconData? icon;
  final bool isCompact;

  const AttendanceStatusBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.showDot = true,
    this.icon,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = _getStatusStyle(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: UniSpacing.borderRadiusFull,
        border: Border.all(
          color: style.borderColor,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isCompact ? 12 : 14, color: style.textColor),
            const SizedBox(width: 4),
          ] else if (showDot) ...[
            Container(
              width: isCompact ? 5 : 6,
              height: isCompact ? 5 : 6,
              decoration: BoxDecoration(
                color: style.dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            customLabel ?? style.label,
            style:
                (isCompact ? UniTypography.caption : UniTypography.labelSmall)
                    .copyWith(
              color: style.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _StatusBadgeStyle _getStatusStyle(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const _StatusBadgeStyle(
          label: 'Có mặt đúng giờ',
          dotColor: UniColors.statusPresent,
          textColor: UniColors.statusPresentText,
          backgroundColor: UniColors.statusPresentBg,
          borderColor: Color(0xFFA7F3D0),
        );
      case AttendanceStatus.late:
        return const _StatusBadgeStyle(
          label: 'Đi muộn',
          dotColor: UniColors.statusLate,
          textColor: UniColors.statusLateText,
          backgroundColor: UniColors.statusLateBg,
          borderColor: Color(0xFFFDE68A),
        );
      case AttendanceStatus.absent:
        return const _StatusBadgeStyle(
          label: 'Vắng không phép',
          dotColor: UniColors.statusAbsent,
          textColor: UniColors.statusAbsentText,
          backgroundColor: UniColors.statusAbsentBg,
          borderColor: Color(0xFFFECACA),
        );
      case AttendanceStatus.excused:
        return const _StatusBadgeStyle(
          label: 'Vắng có phép',
          dotColor: UniColors.statusExcused,
          textColor: UniColors.statusExcusedText,
          backgroundColor: UniColors.statusExcusedBg,
          borderColor: Color(0xFFBFDBFE),
        );
      case AttendanceStatus.danger:
        return const _StatusBadgeStyle(
          label: 'Nguy cơ cấm thi',
          dotColor: UniColors.error,
          textColor: UniColors.error,
          backgroundColor: UniColors.statusAbsentBg,
          borderColor: Color(0xFFFECACA),
        );
      case AttendanceStatus.pending:
        return const _StatusBadgeStyle(
          label: 'Chưa mở điểm danh',
          dotColor: UniColors.textMuted,
          textColor: UniColors.textSecondary,
          backgroundColor: Color(0xFFF1F5F9),
          borderColor: UniColors.border,
        );
      case AttendanceStatus.ongoing:
        return const _StatusBadgeStyle(
          label: 'Đang diễn ra',
          dotColor: UniColors.primary,
          textColor: UniColors.primaryDark,
          backgroundColor: UniColors.primaryLight,
          borderColor: Color(0xFFBFDBFE),
        );
      case AttendanceStatus.scheduled:
        return const _StatusBadgeStyle(
          label: 'Sắp tới',
          dotColor: UniColors.textMuted,
          textColor: UniColors.textSecondary,
          backgroundColor: Color(0xFFF1F5F9),
          borderColor: UniColors.border,
        );
    }
  }
}

class _StatusBadgeStyle {
  final String label;
  final Color dotColor;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  const _StatusBadgeStyle({
    required this.label,
    required this.dotColor,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });
}
