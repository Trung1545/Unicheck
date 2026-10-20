import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/uni_card.dart';
import '../../../shared/widgets/uni_empty_state.dart';
import '../../../shared/widgets/uni_text_field.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';

class StudentCoursesView extends StatelessWidget {
  const StudentCoursesView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
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
            // Student Meta & Academic Summary Card
            _buildAcademicSummaryCard(authController, controller),
            const SizedBox(height: UniSpacing.spaceMd),

            // Search Bar
            UniTextField(
              hint: 'Tìm tên môn, mã HP (vd: IT301)...',
              prefixIcon: Icons.search_rounded,
              onChanged: (val) => controller.setCourseSearch(val),
            ),
            const SizedBox(height: UniSpacing.spaceSm),

            // Filter Chips
            Obx(() => _buildFilterChips(controller)),
            const SizedBox(height: UniSpacing.spaceMd),

            // Course Cards List
            Obx(() {
              final courses = controller.filteredCourses;

              if (courses.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: UniSpacing.spaceXl),
                  child: UniEmptyState(
                    title: 'Không tìm thấy lớp học phần',
                    message:
                        'Không có lớp học phần nào phù hợp với bộ lọc tìm kiếm hiện tại.',
                    icon: Icons.school_outlined,
                  ),
                );
              }

              return Column(
                children: courses.map((course) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: UniSpacing.spaceSm),
                    child: UniCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Code Badge + Status Chip
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: UniColors.primaryLight,
                                  borderRadius: UniSpacing.borderRadiusSm,
                                ),
                                child: Text(
                                  '${course.courseCode}${course.className != null ? ' • ${course.className}' : ''}',
                                  style: UniTypography.labelSmall.copyWith(
                                    color: UniColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: UniColors.secondaryLight
                                      .withValues(alpha: 0.5),
                                  borderRadius: UniSpacing.borderRadiusFull,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: UniColors.secondary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      course.isActive
                                          ? 'Đang học'
                                          : (course.status ?? 'Đang học'),
                                      style: UniTypography.labelSmall.copyWith(
                                        color: UniColors.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: UniSpacing.spaceSm),
                          // Course Name
                          Text(
                            course.courseName,
                            style: UniTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '3 Tín chỉ • Lý thuyết & Thực hành',
                            style: UniTypography.caption.copyWith(
                              color: UniColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: UniSpacing.spaceSm),
                          // Info box
                          Container(
                            padding: const EdgeInsets.all(UniSpacing.spaceSm),
                            decoration: BoxDecoration(
                              color: UniColors.canvas,
                              borderRadius: UniSpacing.borderRadiusMd,
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  Icons.school_rounded,
                                  'Khoa Công nghệ Thông tin',
                                ),
                                const SizedBox(height: 4),
                                _buildInfoRow(
                                  Icons.calendar_today_rounded,
                                  'Học kỳ I (2024 - 2025)',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: UniSpacing.spaceSm),
                          // Attendance Progress Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Chuyên cần: 100% (6/6 buổi)',
                                style: UniTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Vắng: 0 buổi',
                                style: UniTypography.caption.copyWith(
                                  color: UniColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: UniSpacing.borderRadiusFull,
                            child: const LinearProgressIndicator(
                              value: 1.0,
                              minHeight: 6,
                              backgroundColor: UniColors.canvas,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  UniColors.success),
                            ),
                          ),
                          const SizedBox(height: UniSpacing.spaceSm),
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
                        ],
                      ),
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

  Widget _buildAcademicSummaryCard(
      AuthController authController, DashboardController controller) {
    return Obx(() {
      final user = authController.user.value;
      final studentCode = user?.code ?? 'N/A';
      final totalCourses = controller.enrollments.length;

      return Container(
        width: double.infinity,
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
                Text(
                  'MSSV: $studentCode',
                  style: UniTypography.labelMedium.copyWith(
                    color: UniColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: UniColors.primaryLight,
                    borderRadius: UniSpacing.borderRadiusFull,
                  ),
                  child: Text(
                    'Học kỳ I (2024 - 2025)',
                    style: UniTypography.labelSmall.copyWith(
                      color: UniColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: UniSpacing.spaceMd),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Lớp học phần',
                    totalCourses.toString().padLeft(2, '0'),
                    'lớp',
                  ),
                ),
                const SizedBox(width: UniSpacing.spaceSm),
                Expanded(
                  child: _buildMetricTile(
                    'Tổng tín chỉ',
                    '${totalCourses * 3}',
                    'TC',
                  ),
                ),
                const SizedBox(width: UniSpacing.spaceSm),
                Expanded(
                  child: _buildMetricTile(
                    'Chuyên cần TB',
                    '95.2%',
                    'Tốt',
                    valueColor: UniColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMetricTile(String label, String value, String unit,
      {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(UniSpacing.spaceSm),
      decoration: BoxDecoration(
        color: UniColors.canvas,
        borderRadius: UniSpacing.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: UniTypography.caption.copyWith(
              color: UniColors.textSecondary,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: UniTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? UniColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: UniTypography.caption.copyWith(
                  color: UniColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: UniColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: UniTypography.caption.copyWith(
              color: UniColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(DashboardController controller) {
    final current = controller.courseFilterCategory.value;
    final total = controller.enrollments.length;

    final chips = [
      {'key': 'all', 'label': 'Tất cả ($total)'},
      {'key': 'active', 'label': 'Đang học'},
      {'key': 'completed', 'label': 'Đã hoàn thành'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((c) {
          final isSelected = current == c['key'];
          return Padding(
            padding: const EdgeInsets.only(right: UniSpacing.spaceSm),
            child: ChoiceChip(
              label: Text(
                c['label']!,
                style: UniTypography.labelSmall.copyWith(
                  color: isSelected ? Colors.white : UniColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: UniColors.primary,
              backgroundColor: UniColors.canvas,
              side: BorderSide(
                color: isSelected ? UniColors.primary : UniColors.border,
              ),
              onSelected: (_) => controller.setCourseFilter(c['key']!),
            ),
          );
        }).toList(),
      ),
    );
  }
}
