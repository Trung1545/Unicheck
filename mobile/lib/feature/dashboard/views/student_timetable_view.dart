import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/attendance_status_badge.dart';
import '../../../shared/widgets/class_session_card.dart';
import '../../../shared/widgets/uni_empty_state.dart';
import '../../../shared/widgets/weekly_day_picker_strip.dart';
import '../controllers/dashboard_controller.dart';

class StudentTimetableView extends StatelessWidget {
  const StudentTimetableView({super.key});

  String _formatWeekRange(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    final startStr =
        '${monday.day.toString().padLeft(2, '0')}/${monday.month.toString().padLeft(2, '0')}';
    final endStr =
        '${sunday.day.toString().padLeft(2, '0')}/${sunday.month.toString().padLeft(2, '0')}/${sunday.year}';
    return '$startStr - $endStr';
  }

  String _formatDayHeading(DateTime date) {
    const dayNames = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ];
    final dayName = dayNames[date.weekday - 1];
    return '$dayName, ngày ${date.day} tháng ${date.month}, ${date.year}';
  }

  Widget _buildPendingRecheckBanner(
      BuildContext context, DashboardController controller) {
    final pending = controller.pendingRechecks;
    if (pending.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: pending.map((recheck) {
        final exp = recheck.expiresAt;
        final expStr = exp != null
            ? '${exp.hour.toString().padLeft(2, '0')}:${exp.minute.toString().padLeft(2, '0')}'
            : '';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: UniSpacing.spaceMd),
          padding: const EdgeInsets.all(UniSpacing.spaceSm),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: UniSpacing.borderRadiusMd,
            border: Border.all(color: const Color(0xFFF97316), width: 1.2),
          ),
          child: Row(
            children: [
              const Icon(Icons.sync_problem_rounded, color: Color(0xFFEA580C), size: 24),
              const SizedBox(width: UniSpacing.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YÊU CẦU ĐIỂM DANH LẠI: ${recheck.courseCode} (${recheck.className})',
                      style: UniTypography.labelSmall.copyWith(
                        color: const Color(0xFF9A3412),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lý do: ${recheck.reason} (Hạn: $expStr)',
                      style: UniTypography.bodySmall.copyWith(
                        color: const Color(0xFF7C2D12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: UniSpacing.spaceSm),
              ElevatedButton(
                onPressed: () => controller.handleRecheckTap(context, recheck),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('Điểm danh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return RefreshIndicator(
      color: UniColors.primary,
      onRefresh: () => controller.loadDashboardData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: UniSpacing.screenMargin,
          vertical: UniSpacing.spaceMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Context Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thời khóa biểu tuần',
                      style: UniTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Học kỳ I (2024 - 2025) • Tuần 10',
                      style: UniTypography.caption.copyWith(
                        color: UniColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => controller.goToToday(),
                  borderRadius: UniSpacing.borderRadiusFull,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: UniColors.primaryLight,
                      borderRadius: UniSpacing.borderRadiusFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: UniColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Hôm nay',
                          style: UniTypography.labelMedium.copyWith(
                            color: UniColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: UniSpacing.spaceMd),

            // Pending Recheck Banner
            Obx(() => _buildPendingRecheckBanner(context, controller)),

            // Weekly Week Navigator
            Obx(() {
              final monday = controller.currentWeekStart.value;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: UniSpacing.spaceSm,
                  vertical: UniSpacing.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: UniColors.card,
                  borderRadius: UniSpacing.borderRadiusLg,
                  border: Border.all(color: UniColors.border, width: 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded,
                          color: UniColors.primary),
                      onPressed: () => controller.previousWeek(),
                      tooltip: 'Tuần trước',
                    ),
                    Column(
                      children: [
                        Text(
                          'Tuần ${monday.day}/${monday.month} - ${monday.add(const Duration(days: 6)).day}/${monday.add(const Duration(days: 6)).month}',
                          style: UniTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatWeekRange(monday),
                          style: UniTypography.caption.copyWith(
                            color: UniColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded,
                          color: UniColors.primary),
                      onPressed: () => controller.nextWeek(),
                      tooltip: 'Tuần kế tiếp',
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: UniSpacing.spaceSm),

            // Day Selector Strip
            Obx(() {
              return WeeklyDayPickerStrip(
                days: controller.weeklyDays,
                selectedIndex: controller.selectedDayIndex,
                onDaySelected: (index) => controller.selectDay(index),
              );
            }),
            const SizedBox(height: UniSpacing.spaceLg),

            // Date Context Indicator
            Obx(() {
              final sel = controller.selectedDate.value;
              return Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: UniColors.primary,
                  ),
                  const SizedBox(width: UniSpacing.spaceSm),
                  Text(
                    _formatDayHeading(sel),
                    style: UniTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: UniColors.textPrimary,
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: UniSpacing.spaceMd),

            // Main Timeline Class Cards
            Obx(() {
              final slots = controller.selectedDaySlots;

              if (slots.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: UniSpacing.spaceXl),
                  child: UniEmptyState(
                    title: 'Không có lịch học hôm nay!',
                    message:
                        'Hôm nay không có lớp học nào được xếp lịch. Hãy tận hưởng thời gian tự học hoặc nghỉ ngơi để nạp năng lượng nhé!',
                    icon: Icons.event_available_rounded,
                  ),
                );
              }

              return Column(
                children: slots.map((slot) {
                  final isEnrolled = controller.isStudentEnrolled(slot);
                  final matchingRecheck = controller.pendingRechecks.firstWhereOrNull(
                    (r) => r.isPending && (r.sessionId == slot.attendanceSessionId ||
                           (slot.className != null && r.className.toLowerCase() == slot.className!.toLowerCase()))
                  );
                  final canCheckIn = matchingRecheck != null || slot.canCheckInNow(isEnrolled: isEnrolled);
                  final buttonText = matchingRecheck != null
                      ? 'Điểm danh lại'
                      : slot.getAttendanceButtonText(isEnrolled: isEnrolled);
                  final badgeStatus = matchingRecheck != null
                      ? AttendanceStatus.pending
                      : slot.getAttendanceBadgeStatus(isEnrolled: isEnrolled);
                  final badgeLabel = matchingRecheck != null
                      ? 'Yêu cầu điểm danh lại'
                      : slot.getAttendanceBadgeLabel(isEnrolled: isEnrolled);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: UniSpacing.spaceSm),
                    child: ClassSessionCard(
                      courseCode: slot.courseCode,
                      courseName: slot.courseName,
                      classSection: slot.className,
                      room: slot.roomDisplay,
                      lecturerName: slot.lecturerDisplay,
                      timeSlot: slot.timeSlot,
                      status: badgeStatus,
                      customStatusLabel: badgeLabel,
                      actionButtonText: buttonText,
                      onActionButtonTap: canCheckIn
                          ? () => matchingRecheck != null
                              ? controller.handleRecheckTap(context, matchingRecheck)
                              : controller.handleCheckInTap(context, slot)
                          : null,
                    ),
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: UniSpacing.spaceXl),
          ],
        ),
      ),
    );
  }
}
