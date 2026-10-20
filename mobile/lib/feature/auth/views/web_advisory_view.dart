import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/uni_app_header.dart';
import '../../../shared/widgets/uni_card.dart';
import '../../../shared/widgets/uni_primary_button.dart';
import '../controllers/auth_controller.dart';

class WebAdvisoryView extends StatelessWidget {
  const WebAdvisoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final user = controller.user.value;
    final roleName = user?.isAdmin == true ? 'Quản Trị Viên (ADMIN)' : 'Giảng Viên (LECTURER)';

    return Scaffold(
      backgroundColor: UniColors.canvas,
      appBar: const UniAppHeader(
        title: 'Cổng Quản Trị Web',
        showBrand: false,
        showBackButton: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: UniSpacing.screenMargin,
              vertical: UniSpacing.spaceMd,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: UniColors.primaryContainer.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.computer,
                        color: UniColors.primary,
                        size: 36,
                      ),
                    ),
                  ),

                  const SizedBox(height: UniSpacing.spaceMd),

                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: UniColors.surfaceContainerLow,
                        borderRadius:
                            BorderRadius.circular(UniSpacing.radiusFull),
                        border: Border.all(color: UniColors.border),
                      ),
                      child: Text(
                        roleName,
                        style: UniTypography.labelSmall.copyWith(
                          color: UniColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: UniSpacing.spaceSm),

                  Text(
                    'Vui Lòng Sử Dụng Web Portal Trên Máy Tính',
                    textAlign: TextAlign.center,
                    style: UniTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: UniColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: UniSpacing.spaceSm),

                  Text(
                    'Ứng dụng di động UniCheck Mobile được tối ưu chuyên biệt cho Sinh viên thực hiện điểm danh khuôn mặt và đối soát thiết bị phòng học.\n\nCác tính năng quản lý lớp học phần, khởi tạo ca điểm danh, thống kê sinh viên vắng mặt và giám sát hệ thống dành cho $roleName được vận hành trên cổng Web Portal.',
                    textAlign: TextAlign.center,
                    style: UniTypography.bodyMedium.copyWith(
                      color: UniColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: UniSpacing.spaceLg),

                  UniCard(
                    padding: const EdgeInsets.all(UniSpacing.spaceMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.language,
                              color: UniColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: UniSpacing.spaceSm),
                            Text(
                              'Địa Chỉ Truy Cập Cổng Web',
                              style: UniTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: UniColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(UniSpacing.spaceSm),
                          decoration: BoxDecoration(
                            color: UniColors.surfaceContainerLow,
                            borderRadius:
                                BorderRadius.circular(UniSpacing.radiusSm),
                          ),
                          child: Text(
                            'https://unicheck.edu.vn/portal',
                            style: UniTypography.bodyMedium.copyWith(
                              color: UniColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: UniSpacing.spaceSm),
                        Text(
                          'Sử dụng trình duyệt Chrome, Edge hoặc Safari trên máy tính để đăng nhập với cùng tài khoản.',
                          style: UniTypography.bodySmall.copyWith(
                            color: UniColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: UniSpacing.spaceXl),

                  UniPrimaryButton(
                    text: 'Đăng Xuất Tài Khoản',
                    icon: Icons.logout,
                    backgroundColor: UniColors.statusAbsent,
                    onPressed: () => controller.logout(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
