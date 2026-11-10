import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'attendance_status_badge.dart';
import 'uni_card.dart';

/// UniCheck Standard Academic Class Session Card
/// Based on Google Stitch Screen: 201c64df9c7d465d8bc8dacc30b91828 & 6a863a458210432b8a8f46ec8a199842
class ClassSessionCard extends StatelessWidget {
  final String courseCode;
  final String courseName;
  final String? classSection;
  final String room;
  final String lecturerName;
  final String timeSlot;
  final AttendanceStatus? status;
  final String? customStatusLabel;
  final String? timeRemaining;
  final double? attendanceRate;
  final String? attendanceCountText;
  final String? actionButtonText;
  final IconData? actionButtonIcon;
  final VoidCallback? onActionButtonTap;
  final VoidCallback? onTap;

  const ClassSessionCard({
    super.key,
    required this.courseCode,
    required this.courseName,
    this.classSection,
    required this.room,
    required this.lecturerName,
    required this.timeSlot,
    this.status,
    this.customStatusLabel,
    this.timeRemaining,
    this.attendanceRate,
    this.attendanceCountText,
    this.actionButtonText,
    this.actionButtonIcon,
    this.onActionButtonTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return UniCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Header: Course Code Badge + Status Badge / Countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: UniColors.primaryLight,
                  borderRadius: UniSpacing.borderRadiusSm,
                ),
                child: Text(
                  classSection != null
                      ? '$courseCode • $classSection'
                      : courseCode,
                  style: UniTypography.labelSmall.copyWith(
                    color: UniColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (timeRemaining != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 15,
                      color: UniColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeRemaining!,
                      style: UniTypography.labelSmall.copyWith(
                        color: UniColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else if (status != null)
                AttendanceStatusBadge(
                  status: status!,
                  customLabel: customStatusLabel,
                  isCompact: true,
                ),
            ],
          ),

          const SizedBox(height: UniSpacing.spaceSm),

          // Course Name Title
          Text(
            courseName,
            style: UniTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: UniSpacing.spaceSm),

          // Info Container (Room, Lecturer, Time)
          Container(
            padding: const EdgeInsets.all(UniSpacing.spaceSm + 2),
            decoration: BoxDecoration(
              color: UniColors.canvas,
              borderRadius: UniSpacing.borderRadiusMd,
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.meeting_room_outlined, room),
                const SizedBox(height: 6),
                _buildInfoRow(Icons.person_outline, lecturerName),
                const SizedBox(height: 6),
                _buildInfoRow(Icons.schedule_outlined, timeSlot),
              ],
            ),
          ),

          // Progress Bar (if attendance rate is provided)
          if (attendanceRate != null) ...[
            const SizedBox(height: UniSpacing.spaceSm + 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chuyên cần: ${(attendanceRate! * 100).toStringAsFixed(1)}%',
                  style: UniTypography.labelSmall.copyWith(
                    color: _getRateColor(attendanceRate!),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (attendanceCountText != null)
                  Text(
                    attendanceCountText!,
                    style: UniTypography.caption,
                  ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: UniSpacing.borderRadiusFull,
              child: LinearProgressIndicator(
                value: attendanceRate!.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: UniColors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(
                    _getRateColor(attendanceRate!)),
              ),
            ),
          ],

          // Optional Action Button (Unified Enabled & Disabled styling)
          if (actionButtonText != null) ...[
            const SizedBox(height: UniSpacing.spaceMd),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onActionButtonTap,
                icon: Icon(
                  actionButtonIcon ??
                      (onActionButtonTap != null
                          ? Icons.qr_code_scanner_rounded
                          : (status == AttendanceStatus.present ||
                                  status == AttendanceStatus.late
                              ? Icons.check_circle_outline_rounded
                              : Icons.lock_outline_rounded)),
                  size: 18,
                ),
                label: Text(actionButtonText!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: onActionButtonTap != null
                      ? UniColors.primary
                      : const Color(0xFFF1F5F9),
                  foregroundColor: onActionButtonTap != null
                      ? Colors.white
                      : UniColors.textMuted,
                  disabledBackgroundColor: const Color(0xFFF1F5F9),
                  disabledForegroundColor: UniColors.textMuted,
                  elevation: onActionButtonTap != null ? 1 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: UniSpacing.borderRadiusMd,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: UniColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: UniTypography.bodySmall.copyWith(
              color: UniColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getRateColor(double rate) {
    if (rate >= 0.8) return UniColors.statusPresent;
    if (rate >= 0.7) return UniColors.statusLate;
    return UniColors.statusAbsent;
  }
}
