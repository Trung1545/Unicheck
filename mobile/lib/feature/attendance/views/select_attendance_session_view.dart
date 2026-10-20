import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/attendance_status_badge.dart';
import '../../../shared/widgets/uni_card.dart';
import '../../../shared/widgets/uni_empty_state.dart';
import '../../../shared/widgets/uni_primary_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/models/timetable_slot_model.dart';
import '../controllers/attendance_controller.dart';

class SelectAttendanceSessionView extends StatelessWidget {
  const SelectAttendanceSessionView({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceController = Get.isRegistered<AttendanceController>()
        ? Get.find<AttendanceController>()
        : Get.put(AttendanceController());

    final dashboardController = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : Get.put(DashboardController());

    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());

    return Scaffold(
      backgroundColor: UniColors.canvas,
      appBar: _buildAppBar(context, authController),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await dashboardController.loadDashboardData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: UniSpacing.margin,
              vertical: UniSpacing.spaceMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Context & Academic Banner
                _buildAcademicBanner(dashboardController, attendanceController),
                const SizedBox(height: UniSpacing.spaceMd),

                // 2. Attendance Verification 3-Step Pipeline Card
                _buildThreeStepPipelineCard(),
                const SizedBox(height: UniSpacing.spaceMd),

                // 3. Attendance Sessions List Header
                _buildSessionListHeader(dashboardController),
                const SizedBox(height: UniSpacing.spaceSm),

                // 4. Session Cards List
                Obx(() {
                  final allToday = dashboardController.todaySlots;
                  final filter = attendanceController.sessionFilter.value;

                  List<TimetableSlotModel> filtered = allToday;
                  if (filter == 'open') {
                    filtered = allToday.where((s) => s.hasAttendanceSession).toList();
                  } else if (filter == 'closed') {
                    filtered = allToday.where((s) => !s.hasAttendanceSession).toList();
                  }

                  if (filtered.isEmpty) {
                    return UniCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: UniSpacing.spaceXl,
                        horizontal: UniSpacing.spaceMd,
                      ),
                      child: UniEmptyState(
                        title: 'Không có phiên học phù hợp',
                        message: filter == 'open'
                            ? 'Hiện chưa có ca học nào mở cổng điểm danh.'
                            : 'Không tìm thấy phiên học nào trong ngày hôm nay.',
                        icon: Icons.event_available_outlined,
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: UniSpacing.spaceSm + 2),
                    itemBuilder: (context, index) {
                      final slot = filtered[index];
                      return _buildSessionCard(
                        context,
                        slot,
                        attendanceController,
                      );
                    },
                  );
                }),
                const SizedBox(height: UniSpacing.spaceXl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, AuthController authController) {
    return AppBar(
      backgroundColor: UniColors.card,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: UniColors.textPrimary),
        onPressed: () => Get.back(),
      ),
      title: Obx(() {
        final user = authController.user.value;
        final name = user?.fullName ?? 'Sinh viên';
        final code = user?.code ?? user?.username ?? '2251120001';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Điểm Danh',
              style: UniTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: UniColors.textPrimary,
              ),
            ),
            Row(
              children: [
                Text(
                  name,
                  style: UniTypography.caption.copyWith(
                    color: UniColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('•', style: TextStyle(color: UniColors.border)),
                const SizedBox(width: 4),
                Text(
                  code,
                  style: UniTypography.caption.copyWith(
                    color: UniColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        );
      }),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded,
              color: UniColors.textSecondary),
          onPressed: () {
            Get.snackbar(
              'Thông báo',
              'Không có thông báo điểm danh mới.',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.only(right: UniSpacing.margin),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: UniColors.primary,
            child: Icon(Icons.person, size: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicBanner(
    DashboardController dashboardController,
    AttendanceController attendanceController,
  ) {
    final now = DateTime.now();
    const days = [
      'Chủ Nhật',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy'
    ];
    final dayName = days[now.weekday % 7];
    final dateStr =
        '$dayName, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    return UniCard(
      padding: const EdgeInsets.all(UniSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: UniColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Hôm nay: $dateStr',
                    style: UniTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: UniColors.primaryLight,
                  borderRadius: UniSpacing.borderRadiusFull,
                ),
                child: Text(
                  'Học kỳ I',
                  style: UniTypography.caption.copyWith(
                    color: UniColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: UniSpacing.spaceSm),
          Obx(() {
            final todaySlots = dashboardController.todaySlots;
            final openCount =
                todaySlots.where((s) => s.hasAttendanceSession).length;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: UniColors.canvas,
                borderRadius: UniSpacing.borderRadiusSm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school_outlined,
                          size: 16, color: UniColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Năm học 2024 - 2025',
                        style: UniTypography.caption.copyWith(
                          color: UniColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: openCount > 0
                              ? UniColors.success
                              : UniColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${todaySlots.length} ca hôm nay • $openCount ca đang mở',
                        style: UniTypography.caption.copyWith(
                          color: openCount > 0
                              ? UniColors.primary
                              : UniColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: UniSpacing.spaceSm),
          // Filter Chips Row
          Obx(() {
            final currentFilter = attendanceController.sessionFilter.value;
            final allCount = dashboardController.todaySlots.length;
            final openCount = dashboardController.todaySlots
                .where((s) => s.hasAttendanceSession)
                .length;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Tất cả',
                    count: allCount,
                    isSelected: currentFilter == 'all',
                    onTap: () => attendanceController.setFilter('all'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Đang mở',
                    count: openCount,
                    isSelected: currentFilter == 'open',
                    onTap: () => attendanceController.setFilter('open'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Chưa mở',
                    count: allCount - openCount,
                    isSelected: currentFilter == 'closed',
                    onTap: () => attendanceController.setFilter('closed'),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: UniSpacing.borderRadiusFull,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? UniColors.primary : UniColors.canvas,
          borderRadius: UniSpacing.borderRadiusFull,
          border: Border.all(
            color: isSelected ? UniColors.primary : UniColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: UniTypography.caption.copyWith(
                color: isSelected ? Colors.white : UniColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : UniColors.border.withValues(alpha: 0.5),
                borderRadius: UniSpacing.borderRadiusFull,
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : UniColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreeStepPipelineCard() {
    return UniCard(
      padding: const EdgeInsets.all(UniSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 20,
                    color: UniColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Quy trình xác thực 3 bước',
                    style: UniTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: UniColors.statusPresentBg,
                  borderRadius: UniSpacing.borderRadiusFull,
                ),
                child: Text(
                  'Chuẩn học đường',
                  style: UniTypography.caption.copyWith(
                    color: UniColors.statusPresentText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: UniSpacing.spaceSm + 2),
          // 3 Step Columns
          Row(
            children: [
              Expanded(
                child: _buildStepItem(
                  stepNum: 'Bước 1',
                  label: 'Quét mã QR',
                  icon: Icons.qr_code_scanner_rounded,
                  statusText: 'Sẵn sàng',
                  isActive: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStepItem(
                  stepNum: 'Bước 2',
                  label: 'Wi-Fi & Phòng',
                  icon: Icons.wifi_tethering_rounded,
                  statusText: 'Tự đối soát',
                  isActive: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStepItem(
                  stepNum: 'Bước 3',
                  label: 'Face-ID AI',
                  icon: Icons.face_retouching_natural_rounded,
                  statusText: 'Sinh trắc',
                  isActive: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: UniSpacing.spaceSm),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: UniColors.canvas,
              borderRadius: UniSpacing.borderRadiusSm,
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: UniColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Quét mã QR giảng đường → Đối soát vị trí Wi-Fi → Xác nhận gương mặt sinh trắc học Face-ID trong 15 giây.',
                    style: UniTypography.caption.copyWith(
                      color: UniColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String stepNum,
    required String label,
    required IconData icon,
    required String statusText,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: UniColors.canvas,
        borderRadius: UniSpacing.borderRadiusSm,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                isActive ? UniColors.primary : UniColors.border.withValues(alpha: 0.5),
            child: Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : UniColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stepNum,
            style: UniTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: isActive ? UniColors.primary : UniColors.textSecondary,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: UniTypography.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 10, color: UniColors.success),
              const SizedBox(width: 2),
              Text(
                statusText,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: UniColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionListHeader(DashboardController controller) {
    return Obx(() {
      final total = controller.todaySlots.length;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Phiên học trực tiếp',
                style: UniTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: UniColors.primaryLight,
                  borderRadius: UniSpacing.borderRadiusFull,
                ),
                child: Text(
                  '$total lớp',
                  style: UniTypography.caption.copyWith(
                    color: UniColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Hôm nay',
            style: UniTypography.caption.copyWith(
              color: UniColors.textSecondary,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSessionCard(
    BuildContext context,
    TimetableSlotModel slot,
    AttendanceController attendanceController,
  ) {
    final isOpen = slot.hasAttendanceSession;

    return UniCard(
      padding: const EdgeInsets.all(UniSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isOpen)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: UniColors.statusPresentBg,
                    borderRadius: UniSpacing.borderRadiusFull,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: UniColors.statusPresent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Đang mở điểm danh',
                        style: UniTypography.caption.copyWith(
                          color: UniColors.statusPresentText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const AttendanceStatusBadge(
                  status: AttendanceStatus.pending,
                  customLabel: 'Chưa mở điểm danh',
                ),
              Text(
                slot.periodsDisplay,
                style: UniTypography.caption.copyWith(
                  color: UniColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: UniSpacing.spaceSm),

          // Course Code & Name
          Text(
            '${slot.courseCode} • ${slot.className ?? 'Lớp học phần'}',
            style: UniTypography.caption.copyWith(
              color: UniColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            slot.courseName,
            style: UniTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: UniSpacing.spaceSm),

          // Room & Time & Lecturer
          Row(
            children: [
              const Icon(Icons.meeting_room_outlined,
                  size: 14, color: UniColors.textMuted),
              const SizedBox(width: 4),
              Text(
                slot.roomDisplay,
                style: UniTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.schedule, size: 14, color: UniColors.textMuted),
              const SizedBox(width: 4),
              Text(
                slot.timeSlot,
                style: UniTypography.caption.copyWith(
                  color: UniColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 14, color: UniColors.textMuted),
              const SizedBox(width: 4),
              Text(
                slot.lecturerDisplay,
                style: UniTypography.caption.copyWith(
                  color: UniColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: UniSpacing.spaceMd),

          // Action Button
          UniPrimaryButton(
            text: isOpen ? 'Bắt đầu điểm danh QR' : 'Quét QR phiên này',
            icon: Icons.qr_code_scanner_rounded,
            onPressed: () {
              attendanceController.selectSession(slot);
              Get.toNamed(AppRoutes.qrScanner);
            },
          ),
        ],
      ),
    );
  }
}
