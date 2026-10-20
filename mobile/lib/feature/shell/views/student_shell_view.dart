import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/uni_app_header.dart';
import '../../../shared/widgets/uni_bottom_nav_bar.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/views/student_courses_view.dart';
import '../../dashboard/views/student_dashboard_view.dart';
import '../../dashboard/views/student_profile_tab_view.dart';
import '../../dashboard/views/student_timetable_view.dart';

class StudentShellView extends StatelessWidget {
  const StudentShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final dashboardController = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : Get.put(DashboardController());

    return Scaffold(
      backgroundColor: UniColors.canvas,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Obx(() {
          final user = authController.user.value;
          final initial = (user?.fullName.isNotEmpty ?? false)
              ? user!.fullName[0].toUpperCase()
              : 'SV';

          return UniAppHeader(
            showBrand: true,
            userInitial: initial,
            unreadNotifications: 3,
            onNotificationTap: () => _showNotificationDialog(context),
            onProfileTap: () => dashboardController.selectedTab.value = 4,
          );
        }),
      ),
      body: Obx(() {
        final currentTab = dashboardController.selectedTab.value;

        return IndexedStack(
          index: currentTab,
          children: const [
            // Tab 0: Tổng quan (Dashboard)
            StudentDashboardView(),
            // Tab 1: Thời khóa (Timetable)
            StudentTimetableView(),
            // Tab 2: Dummy center scan view
            SizedBox.shrink(),
            // Tab 3: Lớp học (Courses)
            StudentCoursesView(),
            // Tab 4: Cá nhân (Profile)
            StudentProfileTabView(),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        return UniBottomNavBar(
          currentIndex: dashboardController.selectedTab.value,
          onTap: (index) {
            if (index == 2) {
              _navigateToAttendanceFlow(context);
            } else {
              dashboardController.selectedTab.value = index;
            }
          },
          onScanQrTap: () => _navigateToAttendanceFlow(context),
        );
      }),
    );
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: UniColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: UniSpacing.borderRadiusLg,
        ),
        title: Row(
          children: [
            const Icon(Icons.notifications_active_rounded,
                color: UniColors.primary),
            const SizedBox(width: 8),
            Text(
              'Thông báo học vụ',
              style: UniTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationItem(
              'Nhắc nhở điểm danh',
              'Ca học tiếp theo sắp mở cổng trong 15 phút nữa.',
              '10 phút trước',
            ),
            const Divider(height: 16, color: UniColors.borderLight),
            _buildNotificationItem(
              'Lịch thi dự kiến',
              'Đã cập nhật lịch thi kết thúc học phần Học kỳ I (2024 - 2025).',
              'Hôm qua',
            ),
            const Divider(height: 16, color: UniColors.borderLight),
            _buildNotificationItem(
              'Đăng ký Face-ID',
              'Vui lòng hoàn tất đăng ký nhận diện khuôn mẫu trước ngày 30/11.',
              '3 ngày trước',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Đóng',
              style: UniTypography.labelLarge.copyWith(
                color: UniColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String title, String desc, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: UniTypography.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              time,
              style: UniTypography.caption.copyWith(
                color: UniColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          style: UniTypography.bodySmall.copyWith(
            color: UniColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _navigateToAttendanceFlow(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();
    final attendanceController = Get.isRegistered<AttendanceController>()
        ? Get.find<AttendanceController>()
        : Get.put(AttendanceController());

    final activeSlot = dashboardController.activeAttendanceSession;
    if (activeSlot != null) {
      attendanceController.selectSession(activeSlot);
      Get.toNamed(AppRoutes.qrScanner);
    } else {
      Get.toNamed(AppRoutes.selectSession);
    }
  }
}
