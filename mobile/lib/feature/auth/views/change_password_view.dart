import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/uni_app_header.dart';
import '../../../shared/widgets/uni_card.dart';
import '../../../shared/widgets/uni_primary_button.dart';
import '../../../shared/widgets/uni_text_field.dart';
import '../controllers/auth_controller.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  late final AuthController controller;
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  int strengthScore = 0;
  bool hasMinLength = false;
  bool hasUpperLowerNumber = false;
  bool hasSpecialChar = false;
  bool isDifferentFromOld = false;
  bool isMatching = false;
  bool revokeOtherSessions = true;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>();
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _evaluatePassword(String pwd) {
    setState(() {
      hasMinLength = pwd.length >= 8;
      final hasUpper = pwd.contains(RegExp(r'[A-Z]'));
      final hasLower = pwd.contains(RegExp(r'[a-z]'));
      final hasNum = pwd.contains(RegExp(r'[0-9]'));
      hasUpperLowerNumber = hasUpper && hasLower && hasNum;
      hasSpecialChar = pwd.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
      isDifferentFromOld =
          pwd.isNotEmpty && pwd != oldPasswordController.text;

      strengthScore = (hasMinLength ? 1 : 0) +
          (hasUpperLowerNumber ? 1 : 0) +
          (hasSpecialChar ? 1 : 0);

      _checkMatch();
    });
  }

  void _checkMatch() {
    setState(() {
      final p1 = newPasswordController.text;
      final p2 = confirmPasswordController.text;
      isMatching = p1.isNotEmpty && p1 == p2;
    });
  }

  String get _strengthLabel {
    switch (strengthScore) {
      case 0:
      case 1:
        return 'Yếu (1/3)';
      case 2:
        return 'Trung bình (2/3)';
      case 3:
      default:
        return 'Mạnh (85/100)';
    }
  }

  Color get _strengthColor {
    switch (strengthScore) {
      case 0:
      case 1:
        return UniColors.statusAbsent;
      case 2:
        return UniColors.statusLate;
      case 3:
      default:
        return UniColors.statusPresent;
    }
  }

  Future<void> _handleSubmit() async {
    final oldP = oldPasswordController.text.trim();
    final newP = newPasswordController.text;
    final confirm = confirmPasswordController.text;

    if (oldP.isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng nhập mật khẩu hiện tại',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: UniColors.statusAbsentBg,
        colorText: UniColors.statusAbsent,
        margin: const EdgeInsets.all(UniSpacing.spaceMd),
      );
      return;
    }

    if (newP.length < 8) {
      Get.snackbar(
        'Lỗi',
        'Mật khẩu mới phải có tối thiểu 8 ký tự',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: UniColors.statusAbsentBg,
        colorText: UniColors.statusAbsent,
        margin: const EdgeInsets.all(UniSpacing.spaceMd),
      );
      return;
    }

    if (newP != confirm) {
      Get.snackbar(
        'Lỗi',
        'Mật khẩu xác nhận không trùng khớp',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: UniColors.statusAbsentBg,
        colorText: UniColors.statusAbsent,
        margin: const EdgeInsets.all(UniSpacing.spaceMd),
      );
      return;
    }

    final success = await controller.changePassword(
      oldPassword: oldP,
      newPassword: newP,
    );

    if (success && mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UniSpacing.radiusXl),
        ),
        backgroundColor: UniColors.card,
        child: Padding(
          padding: const EdgeInsets.all(UniSpacing.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: UniColors.statusPresentBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: UniColors.statusPresent,
                  size: 30,
                ),
              ),
              const SizedBox(height: UniSpacing.spaceMd),
              Text(
                'Đổi Mật Khẩu Thành Công!',
                style: UniTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: UniColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: UniSpacing.spaceXs),
              Text(
                'Mật khẩu mới của bạn đã được cập nhật an toàn vào hệ thống đào tạo UniCheck. Vui lòng ghi nhớ mật khẩu mới.',
                textAlign: TextAlign.center,
                style: UniTypography.bodyMedium.copyWith(
                  color: UniColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: UniSpacing.spaceLg),
              UniPrimaryButton(
                text: 'Xác Nhận',
                onPressed: () {
                  Get.back(); // close dialog
                  Get.back(); // return to previous view
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = controller.user.value;
    final displayName = user?.fullName ?? 'Sinh viên';
    final userCode = user?.username ?? '';

    return Scaffold(
      backgroundColor: UniColors.canvas,
      appBar: UniAppHeader(
        title: 'Đổi Mật Khẩu',
        showBrand: false,
        showBackButton: true,
        onBack: () => Get.back(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: UniSpacing.screenMargin,
            vertical: UniSpacing.spaceMd,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Account Security Status Context Card (Stitch 3fd3a6913b854f03867d682c6da6cc59)
                UniCard(
                  padding: const EdgeInsets.all(UniSpacing.spaceMd),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: UniColors.primaryContainer.withAlpha(25),
                          borderRadius:
                              BorderRadius.circular(UniSpacing.radiusSm),
                        ),
                        child: const Icon(
                          Icons.security,
                          color: UniColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: UniSpacing.spaceSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Bảo vệ tài khoản định kỳ',
                                  style:
                                      UniTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: UniColors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: UniColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'BẢO MẬT',
                                    style:
                                        UniTypography.labelSmall.copyWith(
                                      color: UniColors.primary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bạn đang đăng nhập với tư cách $displayName ($userCode). Khuyến nghị đổi mật khẩu ít nhất 90 ngày/lần để bảo vệ dữ liệu học tập và sinh trắc học.',
                              style: UniTypography.bodySmall.copyWith(
                                color: UniColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: UniSpacing.spaceMd),

                // Error Banner if any
                Obx(() {
                  final error = controller.errorMessage.value;
                  if (error.isEmpty) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: UniSpacing.spaceMd),
                    padding: const EdgeInsets.all(UniSpacing.spaceMd),
                    decoration: BoxDecoration(
                      color: UniColors.statusAbsentBg,
                      borderRadius:
                          BorderRadius.circular(UniSpacing.radiusMd),
                      border: Border.all(
                        color: UniColors.statusAbsent.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: UniColors.statusAbsent,
                          size: 20,
                        ),
                        const SizedBox(width: UniSpacing.spaceSm),
                        Expanded(
                          child: Text(
                            error,
                            style: UniTypography.bodySmall.copyWith(
                              color: UniColors.statusAbsent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Form Container
                UniCard(
                  padding: const EdgeInsets.all(UniSpacing.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Field 1: Current Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mật khẩu hiện tại *',
                            style: UniTypography.labelMedium.copyWith(
                              color: UniColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              Get.toNamed(AppRoutes.forgotPassword);
                            },
                            child: Text(
                              'Quên mật khẩu?',
                              style: UniTypography.labelSmall.copyWith(
                                color: UniColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: UniSpacing.spaceXs),
                      UniTextField(
                        hint: 'Nhập mật khẩu hiện tại',
                        controller: oldPasswordController,
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: UniSpacing.spaceMd),

                      // Field 2: New Password
                      UniTextField(
                        label: 'Mật khẩu mới *',
                        hint: 'Nhập mật khẩu mới an toàn',
                        controller: newPasswordController,
                        prefixIcon: Icons.lock_reset,
                        isPassword: true,
                        onChanged: _evaluatePassword,
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: UniSpacing.spaceSm),

                      // Strength Meter Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Độ mạnh mật khẩu:',
                            style: UniTypography.labelSmall.copyWith(
                              color: UniColors.textSecondary,
                            ),
                          ),
                          Text(
                            _strengthLabel,
                            style: UniTypography.labelSmall.copyWith(
                              color: _strengthColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(3, (index) {
                          final isFilled = index < strengthScore;
                          return Expanded(
                            child: Container(
                              height: 4,
                              margin: EdgeInsets.only(
                                right: index < 2 ? 4 : 0,
                              ),
                              decoration: BoxDecoration(
                                color: isFilled
                                    ? _strengthColor
                                    : UniColors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: UniSpacing.spaceSm),

                      // Rules Checklist
                      Container(
                        padding: const EdgeInsets.all(UniSpacing.spaceSm),
                        decoration: BoxDecoration(
                          color: UniColors.surfaceContainerLow,
                          borderRadius:
                              BorderRadius.circular(UniSpacing.radiusSm),
                        ),
                        child: Column(
                          children: [
                            _buildRuleItem('Tối thiểu 8 ký tự', hasMinLength),
                            const SizedBox(height: 4),
                            _buildRuleItem(
                              'Bao gồm chữ hoa, chữ thường và chữ số',
                              hasUpperLowerNumber,
                            ),
                            const SizedBox(height: 4),
                            _buildRuleItem(
                              'Ký tự đặc biệt (@, #, \$, %, ...)',
                              hasSpecialChar,
                            ),
                            const SizedBox(height: 4),
                            _buildRuleItem(
                              'Không trùng với mật khẩu hiện tại',
                              isDifferentFromOld,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: UniSpacing.spaceMd),

                      // Field 3: Confirm New Password
                      UniTextField(
                        label: 'Xác nhận mật khẩu mới *',
                        hint: 'Nhập lại mật khẩu mới',
                        controller: confirmPasswordController,
                        prefixIcon: Icons.verified_outlined,
                        isPassword: true,
                        onChanged: (_) => _checkMatch(),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleSubmit(),
                      ),

                      if (confirmPasswordController.text.isNotEmpty) ...[
                        const SizedBox(height: UniSpacing.spaceXs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: UniSpacing.spaceSm,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isMatching
                                ? UniColors.statusPresentBg
                                : UniColors.statusAbsentBg,
                            borderRadius:
                                BorderRadius.circular(UniSpacing.radiusSm),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isMatching ? Icons.task_alt : Icons.cancel,
                                size: 16,
                                color: isMatching
                                    ? UniColors.statusPresent
                                    : UniColors.statusAbsent,
                              ),
                              const SizedBox(width: UniSpacing.spaceXs),
                              Text(
                                isMatching
                                    ? 'Mật khẩu xác nhận trùng khớp'
                                    : 'Mật khẩu xác nhận chưa khớp',
                                style: UniTypography.labelSmall.copyWith(
                                  color: isMatching
                                      ? UniColors.statusPresent
                                      : UniColors.statusAbsent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: UniSpacing.spaceSm),

                      // Security Checkbox Switch
                      Container(
                        padding: const EdgeInsets.all(UniSpacing.spaceSm),
                        decoration: BoxDecoration(
                          color: UniColors.surfaceContainerLow,
                          borderRadius:
                              BorderRadius.circular(UniSpacing.radiusSm),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: revokeOtherSessions,
                                activeColor: UniColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    revokeOtherSessions = val ?? true;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: UniSpacing.spaceSm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Đăng xuất tất cả thiết bị khác',
                                    style:
                                        UniTypography.labelSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: UniColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Đồng bộ phiên bảo mật mới trên hệ thống',
                                    style:
                                        UniTypography.bodySmall.copyWith(
                                      color: UniColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: UniSpacing.spaceLg),

                      // Submit Button
                      Obx(
                        () => UniPrimaryButton(
                          text: 'Lưu thay đổi mật khẩu',
                          icon: Icons.save,
                          isLoading: controller.isLoading.value,
                          onPressed: _handleSubmit,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.circle_outlined,
          size: 14,
          color: isMet ? UniColors.statusPresent : UniColors.textMuted,
        ),
        const SizedBox(width: UniSpacing.spaceXs),
        Expanded(
          child: Text(
            text,
            style: UniTypography.bodySmall.copyWith(
              color: isMet ? UniColors.textPrimary : UniColors.textMuted,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
