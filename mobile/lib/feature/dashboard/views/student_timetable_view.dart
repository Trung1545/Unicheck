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
                      icon: const Icon(Icons.chevron_left_rounded),
                      color: UniColors.textPrimary,
                      tooltip: 'Tuần trước',
                      onPressed: () => controller.previousWeek(),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 16, color: UniColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          _formatWeekRange(monday),
                          style: UniTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      color: UniColors.textPrimary,
                      tooltip: 'Tuần kế tiếp',
                      onPressed: () => controller.nextWeek(),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: UniSpacing.spaceSm),

            // Horizontal 7-Day Date Strip
            Obx(() => WeeklyDayPickerStrip(
                  days: controller.weeklyDays,
                  selectedIndex: controller.selectedDayIndex,
                  onDaySelected: (idx) => controller.selectDay(idx),
                )),
            const SizedBox(height: UniSpacing.spaceMd),

            // Daily Summary Strip
            Obx(() {
              final selDate = controller.selectedDate.value;
              final slots = controller.selectedDaySlots;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDayHeading(selDate),
                        style: UniTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: UniColors.canvas,
                          borderRadius: UniSpacing.borderRadiusFull,
                          border: Border.all(color: UniColors.borderLight),
                        ),
                        child: Text(
                          'Học kỳ 241',
                          style: UniTypography.labelSmall.copyWith(
                            color: UniColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: UniColors.secondaryLight.withValues(alpha: 0.5),
                      borderRadius: UniSpacing.borderRadiusFull,
                    ),
                    child: Text(
                      '${slots.length} lớp học trong ngày',
                      style: UniTypography.labelSmall.copyWith(
                        color: UniColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: UniSpacing.spaceSm),
                    child: ClassSessionCard(
                      courseCode: slot.courseCode,
                      courseName: slot.courseName,
                      classSection: slot.className,
                      room: slot.roomDisplay,
                      lecturerName: slot.lecturerDisplay,
                      timeSlot: slot.timeSlot,
                      status: slot.hasAttendanceSession
                          ? AttendanceStatus.ongoing
                          : AttendanceStatus.scheduled,
                      actionButtonText: slot.hasAttendanceSession
                          ? 'Điểm danh ngay'
                          : null,
                      onActionButtonTap: slot.hasAttendanceSession
                          ? () => _showPhase05Advisory(context)
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

  void _showPhase05Advisory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: UniColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(UniSpacing.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: UniColors.border,
                  borderRadius: UniSpacing.borderRadiusFull,
                ),
              ),
              const SizedBox(height: UniSpacing.spaceMd),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: UniColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: UniColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: UniSpacing.spaceSm),
              Text(
                'Điểm Danh Lớp Học',
                style: UniTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: UniSpacing.spaceSm),
              Text(
                'Chức năng quét mã QR & kiểm tra thực thể Face-ID sẽ được triển khai đầy đủ tại Phase 05.',
                textAlign: TextAlign.center,
                style: UniTypography.bodyMedium.copyWith(
                  color: UniColors.textSecondary,
                ),
              ),
              const SizedBox(height: UniSpacing.spaceLg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UniColors.primary,
                    foregroundColor: UniColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: UniSpacing.borderRadiusMd,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Đã hiểu'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
