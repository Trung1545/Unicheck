import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/uni_card.dart';
import '../../../shared/widgets/uni_confirmation_dialog.dart';
import '../../../shared/widgets/uni_secondary_button.dart';
import '../../auth/controllers/auth_controller.dart';

class StudentProfileTabView extends StatelessWidget {
  const StudentProfileTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: UniSpacing.screenMargin,
        vertical: UniSpacing.spaceMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Profile Information Card
          _buildUserInfoCard(authController),
          const SizedBox(height: UniSpacing.spaceMd),

          // Biometrics & Security Section
          Text(
            'Bảo mật & Sinh trắc học',
            style: UniTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: UniSpacing.spaceSm),
          _buildSecurityCard(context, authController),
          const SizedBox(height: UniSpacing.spaceLg),

          // Academic Information Section
          Text(
            'Thông tin đào tạo',
            style: UniTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: UniSpacing.spaceSm),
          _buildAcademicDetailsCard(authController),
          const SizedBox(height: UniSpacing.spaceXl),

          // Logout Action Button
          UniSecondaryButton(
            text: 'Đăng xuất tài khoản',
            icon: Icons.logout_rounded,
            textColor: UniColors.error,
            onPressed: () => _confirmLogout(context, authController),
          ),
          const SizedBox(height: UniSpacing.spaceMd),
          Center(
            child: Text(
              'Phiên bản ứng dụng UniCheck Mobile v2.4 (Phase 04)',
              style: UniTypography.caption.copyWith(
                color: UniColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: UniSpacing.spaceLg),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(AuthController authController) {
    return Obx(() {
      final user = authController.user.value;
      final fullName = user?.fullName ?? 'Sinh Viên';
      final studentCode = user?.code ?? 'N/A';
      final email = user?.email ?? '';
      final isFaceRegistered = user?.faceDataStatus == 'REGISTERED';

      return UniCard(
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: UniColors.primaryLight,
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
                    style: UniTypography.headlineMedium.copyWith(
                      color: UniColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: UniSpacing.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: UniTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'MSSV: $studentCode',
                        style: UniTypography.labelMedium.copyWith(
                          color: UniColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: UniTypography.caption.copyWith(
                            color: UniColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: UniSpacing.spaceMd),
            const Divider(height: 1, color: UniColors.borderLight),
            const SizedBox(height: UniSpacing.spaceSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: UniColors.primaryLight,
                    borderRadius: UniSpacing.borderRadiusFull,
                  ),
                  child: Text(
                    'Sinh viên chính quy',
                    style: UniTypography.labelSmall.copyWith(
                      color: UniColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFaceRegistered
                        ? UniColors.secondaryLight.withValues(alpha: 0.5)
                        : UniColors.canvas,
                    borderRadius: UniSpacing.borderRadiusFull,
                    border: Border.all(
                      color: isFaceRegistered
                          ? UniColors.secondary
                          : UniColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFaceRegistered
                            ? Icons.verified_user_rounded
                            : Icons.help_outline_rounded,
                        size: 14,
                        color: isFaceRegistered
                            ? UniColors.secondary
                            : UniColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFaceRegistered
                            ? 'Face-ID: Sẵn sàng'
                            : 'Face-ID: Chưa đăng ký',
                        style: UniTypography.labelSmall.copyWith(
                          color: isFaceRegistered
                              ? UniColors.secondary
                              : UniColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSecurityCard(
      BuildContext context, AuthController authController) {
    return UniCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.face_retouching_natural_rounded,
            title: 'Đăng ký khuôn mẫu Face-ID',
            subtitle: 'Thu thập và mã hóa vector khuôn mặt phục vụ điểm danh',
            onTap: () => Get.toNamed(AppRoutes.faceEnrollment),
          ),
          const Divider(height: 1, color: UniColors.borderLight),
          _buildActionTile(
            icon: Icons.lock_reset_rounded,
            title: 'Đổi mật khẩu tài khoản',
            subtitle: 'Cập nhật mật khẩu định kỳ để bảo vệ tài khoản',
            onTap: () => Get.toNamed(AppRoutes.changePassword),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: UniSpacing.borderRadiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: UniColors.primary, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: UniTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: UniTypography.caption.copyWith(
                      color: UniColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: UniColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicDetailsCard(AuthController authController) {
    return UniCard(
      padding: const EdgeInsets.all(UniSpacing.spaceMd),
      child: Column(
        children: [
          _buildDetailRow('Hệ đào tạo', 'Đại học Chính quy'),
          const Divider(height: 16, color: UniColors.borderLight),
          _buildDetailRow('Khoa / Viện', 'Khoa Công nghệ Thông tin'),
          const Divider(height: 16, color: UniColors.borderLight),
          _buildDetailRow('Chuyên ngành', 'Kỹ thuật Phần mềm'),
          const Divider(height: 16, color: UniColors.borderLight),
          _buildDetailRow('Niên khóa', '2022 - 2026'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: UniTypography.bodyMedium.copyWith(
            color: UniColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: UniTypography.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (ctx) => UniConfirmationDialog(
        title: 'Đăng xuất tài khoản',
        message:
            'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng UniCheck Mobile?',
        confirmText: 'Đăng xuất',
        cancelText: 'Hủy',
        isDestructive: true,
        onConfirm: () async {
          Navigator.of(ctx).pop();
          await authController.logout();
        },
      ),
    );
  }
}
