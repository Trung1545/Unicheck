import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/attendance_metric_card.dart';
import '../../../shared/widgets/attendance_status_badge.dart';
import '../../../shared/widgets/class_session_card.dart';
import '../../../shared/widgets/weekly_day_picker_strip.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';

class StudentDashboardView extends StatelessWidget {
  const StudentDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final controller = Get.find<DashboardController>();

    return RefreshIndicator(
      color: UniColors.primary,
      onRefresh: () async {
        await controller.loadDashboardData();
        await authController.restoreSession();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: UniSpacing.screenMargin,
          vertical: UniSpacing.spaceMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Greeting & Academic Profile Box
            _buildProfileGreetingCard(authController),
            const SizedBox(height: UniSpacing.spaceMd),

            // 2. Prominent Quick Check-in CTA Card
            Obx(() => _buildQuickCheckInCard(context, controller)),
            const SizedBox(height: UniSpacing.spaceMd),

            // 3. Key Metrics 3-Card Grid
            Obx(() => _buildMetricsGrid(authController)),
            const SizedBox(height: UniSpacing.spaceLg),

            // 4. Today's Upcoming Class Card
            Obx(() => _buildNextClassSection(controller)),
            const SizedBox(height: UniSpacing.spaceLg),

            // 5. Weekly Timetable Preview Module
            Obx(() => _buildWeeklyTimetablePreview(controller)),
            const SizedBox(height: UniSpacing.spaceLg),

            // 6. Course Attendance Health & Eligibility List
            Obx(() => _buildCourseAttendanceHealthSection(controller)),
            const SizedBox(height: UniSpacing.spaceXl),
          ],
        ),
      ),
    );
  }

  // --- 1. Academic Greeting Box ---
  Widget _buildProfileGreetingCard(AuthController authController) {
    return Obx(() {
      final user = authController.user.value;
      final studentCode = user?.code ?? 'N/A';
      final fullName = user?.fullName ?? 'Sinh viên';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(UniSpacing.spaceMd),
        decoration: BoxDecoration(
          color: UniColors.card,
          borderRadius: UniSpacing.borderRadiusLg,
          border: Border.all(color: UniColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with online status
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: UniColors.primaryLight,
                      child: Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
                        style: UniTypography.titleLarge.copyWith(
                          color: UniColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: UniColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: UniColors.card, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: UniSpacing.spaceSm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào, $fullName 👋',
                        style: UniTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: UniColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'MSSV: $studentCode • Khóa 2024',
                        style: UniTypography.caption.copyWith(
                          color: UniColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status pill with exact role string for test compatibility
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: UniColors.primaryLight,
                    borderRadius: UniSpacing.borderRadiusFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: UniColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sinh Viên (STUDENT)',
                        style: UniTypography.labelSmall.copyWith(
                          color: UniColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: UniSpacing.spaceSm + 4),
            const Divider(height: 1, color: UniColors.borderLight),
            const SizedBox(height: UniSpacing.spaceSm),
            // Semester row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 15, color: UniColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Học kỳ I (2024 - 2025)',
                      style: UniTypography.labelMedium.copyWith(
                        color: UniColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Tuần học thứ 10',
                  style: UniTypography.caption.copyWith(
                    color: UniColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // --- 2. Prominent Quick Check-in CTA Card ---
  Widget _buildQuickCheckInCard(
      BuildContext context, DashboardController controller) {
    final activeSlot = controller.activeAttendanceSession;

    if (activeSlot != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(UniSpacing.spaceMd),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              UniColors.primary,
              UniColors.primaryDark,
            ],
          ),
          borderRadius: UniSpacing.borderRadiusLg,
          boxShadow: [
            BoxShadow(
              color: UniColors.primary.withValues(alpha: 0.3),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: UniSpacing.borderRadiusFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: UniColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Phiên mở điểm danh',
                        style: UniTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded,
                        size: 15, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      'Đang diễn ra',
                      style: UniTypography.caption.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: UniSpacing.spaceSm + 2),
            Text(
              activeSlot.courseName,
              style: UniTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${activeSlot.roomDisplay} • ${activeSlot.lecturerDisplay}',
              style: UniTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: UniSpacing.spaceMd),
            // CTA Action Button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: UniColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: UniSpacing.borderRadiusMd,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                    label: Text(
                      'Điểm danh ngay',
                      style: UniTypography.labelLarge.copyWith(
                        color: UniColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => _onCheckInPressed(context, controller),
                  ),
                ),
                const SizedBox(width: UniSpacing.spaceSm),
                InkWell(
                  onTap: () => _onCheckInPressed(context, controller),
                  borderRadius: UniSpacing.borderRadiusMd,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: UniSpacing.borderRadiusMd,
                    ),
                    child: const Icon(
                      Icons.face_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Default state: No active session
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(UniSpacing.spaceMd),
      decoration: BoxDecoration(
        color: UniColors.card,
        borderRadius: UniSpacing.borderRadiusLg,
        border: Border.all(color: UniColors.border, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: UniColors.primaryLight,
              borderRadius: UniSpacing.borderRadiusMd,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: UniColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: UniSpacing.spaceSm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chưa có phiên điểm danh mở',
                  style: UniTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hệ thống sẽ tự động kích hoạt khi giảng viên mở cổng điểm danh.',
                  style: UniTypography.caption.copyWith(
                    color: UniColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Key Metrics 3-Card Grid ---
  Widget _buildMetricsGrid(AuthController authController) {
    final user = authController.user.value;
    final isFaceRegistered = user?.faceDataStatus == 'REGISTERED';

    return Row(
      children: [
        // Metric 1: Chuyên cần
        const Expanded(
          child: AttendanceMetricCard(
            label: 'Chuyên cần',
            icon: Icons.pie_chart_outline_rounded,
            value: '--%',
            badgeText: '≥ 80% Chuẩn',
            footnote: 'Đang tổng hợp',
            iconColor: UniColors.primary,
          ),
        ),
        const SizedBox(width: UniSpacing.spaceSm),
        // Metric 2: Đã vắng
        const Expanded(
          child: AttendanceMetricCard(
            label: 'Đã vắng',
            icon: Icons.event_busy_outlined,
            value: '0',
            valueSuffix: '/3',
            badgeText: 'Trong hạn mức',
            footnote: 'Chưa ghi nhận vắng',
            iconColor: UniColors.warning,
          ),
        ),
        const SizedBox(width: UniSpacing.spaceSm),
        // Metric 3: Face-ID
        Expanded(
          child: AttendanceMetricCard(
            label: 'Face-ID',
            icon: isFaceRegistered
                ? Icons.verified_user_rounded
                : Icons.face_retouching_natural,
            value: isFaceRegistered ? 'Sẵn sàng' : 'Chưa tạo',
            badgeText: isFaceRegistered ? 'Đã xác thực' : 'Cần thiết lập',
            footnote: isFaceRegistered ? 'Sẵn sàng điểm danh' : 'Nhấn để quét',
            iconColor:
                isFaceRegistered ? UniColors.success : UniColors.textMuted,
            onTap: () {
              if (!isFaceRegistered) {
                Get.toNamed(AppRoutes.faceEnrollment);
              }
            },
          ),
        ),
      ],
    );
  }

  // --- 4. Today's Upcoming Class Card ---
  Widget _buildNextClassSection(DashboardController controller) {
    final nextSlot = controller.nextClassSession;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: UniColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Lớp học tiếp theo hôm nay',
                  style: UniTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (nextSlot != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: UniColors.canvas,
                  borderRadius: UniSpacing.borderRadiusFull,
                  border: Border.all(color: UniColors.border),
                ),
                child: Text(
                  nextSlot.periodsDisplay,
                  style: UniTypography.labelSmall.copyWith(
                    color: UniColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: UniSpacing.spaceSm),
        if (nextSlot != null)
          ClassSessionCard(
            courseCode: nextSlot.courseCode,
            courseName: nextSlot.courseName,
            classSection: nextSlot.className,
            room: nextSlot.roomDisplay,
            lecturerName: nextSlot.lecturerDisplay,
            timeSlot: nextSlot.timeSlot,
            status: nextSlot.hasAttendanceSession
                ? AttendanceStatus.ongoing
                : AttendanceStatus.scheduled,
            timeRemaining: 'Hôm nay',
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(UniSpacing.spaceLg),
            decoration: BoxDecoration(
              color: UniColors.card,
              borderRadius: UniSpacing.borderRadiusLg,
              border: Border.all(color: UniColors.border, width: 0.8),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.event_available_rounded,
                  size: 36,
                  color: UniColors.textMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  'Không có lớp học nào tiếp theo hôm nay',
                  style: UniTypography.bodyMedium.copyWith(
                    color: UniColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // --- 5. Weekly Timetable Preview Module ---
  Widget _buildWeeklyTimetablePreview(DashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.date_range_rounded,
                    size: 20, color: UniColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Thời khóa biểu tuần',
                  style: UniTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => controller.selectedTab.value = 1,
              child: Text(
                'Xem tất cả',
                style: UniTypography.labelMedium.copyWith(
                  color: UniColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: UniSpacing.spaceXs),
        // Horizontal Day Strip
        WeeklyDayPickerStrip(
          days: controller.weeklyDays,
          selectedIndex: controller.selectedDayIndex,
          onDaySelected: (idx) => controller.selectDay(idx),
        ),
        const SizedBox(height: UniSpacing.spaceSm),
        // Classes of selected day
        ...controller.selectedDaySlots.map((slot) {
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
            ),
          );
        }),
        if (controller.selectedDaySlots.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: UniSpacing.spaceSm),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(UniSpacing.spaceMd),
              decoration: BoxDecoration(
                color: UniColors.canvas,
                borderRadius: UniSpacing.borderRadiusMd,
                border: Border.all(color: UniColors.borderLight),
              ),
              child: Text(
                'Không có tiết học nào trong ngày này.',
                textAlign: TextAlign.center,
                style: UniTypography.caption.copyWith(
                  color: UniColors.textMuted,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- 6. Course Attendance Health & Eligibility List ---
  Widget _buildCourseAttendanceHealthSection(DashboardController controller) {
    final courses = controller.enrollments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiến độ chuyên cần môn học',
                  style: UniTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Điều kiện dự thi cuối kỳ: Chuyên cần ≥ 80%',
                  style: UniTypography.caption.copyWith(
                    color: UniColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.assignment_turned_in_outlined,
              size: 22,
              color: UniColors.textMuted,
            ),
          ],
        ),
        const SizedBox(height: UniSpacing.spaceSm),
        if (courses.isNotEmpty)
          ...courses.map((c) {
            return Container(
              margin: const EdgeInsets.only(bottom: UniSpacing.spaceSm),
              padding: const EdgeInsets.all(UniSpacing.spaceMd),
              decoration: BoxDecoration(
                color: UniColors.card,
                borderRadius: UniSpacing.borderRadiusLg,
                border: Border.all(color: UniColors.border, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${c.courseCode} • ${c.className ?? "Lớp HP"}',
                            style: UniTypography.labelSmall.copyWith(
                              color: UniColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c.courseName,
                            style: UniTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '100%',
                        style: UniTypography.titleMedium.copyWith(
                          color: UniColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: UniSpacing.spaceSm),
                  ClipRRect(
                    borderRadius: UniSpacing.borderRadiusFull,
                    child: const LinearProgressIndicator(
                      value: 1.0,
                      minHeight: 6,
                      backgroundColor: UniColors.canvas,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(UniColors.success),
                    ),
                  ),
                  const SizedBox(height: UniSpacing.spaceSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 14, color: UniColors.success),
                          const SizedBox(width: 4),
                          Text(
                            'Đủ điều kiện dự thi',
                            style: UniTypography.caption.copyWith(
                              color: UniColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Vắng: 0 buổi',
                        style: UniTypography.caption.copyWith(
                          color: UniColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          })
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(UniSpacing.spaceMd),
            decoration: BoxDecoration(
              color: UniColors.card,
              borderRadius: UniSpacing.borderRadiusMd,
              border: Border.all(color: UniColors.borderLight),
            ),
            child: Text(
              'Chưa có dữ liệu lớp học phần đăng ký trong học kỳ.',
              textAlign: TextAlign.center,
              style: UniTypography.caption.copyWith(
                color: UniColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }

  void _onCheckInPressed(BuildContext context, DashboardController controller) {
    final activeSlot = controller.activeAttendanceSession;
    final attendanceController = Get.isRegistered<AttendanceController>()
        ? Get.find<AttendanceController>()
        : Get.put(AttendanceController());

    if (activeSlot != null) {
      attendanceController.selectSession(activeSlot);
      Get.toNamed(AppRoutes.qrScanner);
    } else {
      Get.toNamed(AppRoutes.selectSession);
    }
  }
}
