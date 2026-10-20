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

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  late final AuthController controller;
  late final String email;
  late final String otp;

  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  int strengthScore = 0; // 0-4
  bool hasMinLength = false;
  bool hasUppercase = false;
  bool hasNumber = false;
  bool hasSpecialChar = false;
  bool isMatching = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>();
    final args = Get.arguments as Map<String, dynamic>?;
    email = args?['email'] as String? ?? '';
    otp = args?['otp'] as String? ?? '';
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _evaluatePassword(String pwd) {
    setState(() {
      hasMinLength = pwd.length >= 8;
      hasUppercase = pwd.contains(RegExp(r'[A-Z]'));
      hasNumber = pwd.contains(RegExp(r'[0-9]'));
      hasSpecialChar = pwd.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

      strengthScore = (hasMinLength ? 1 : 0) +
          (hasUppercase ? 1 : 0) +
          (hasNumber ? 1 : 0) +
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
        return 'Quá yếu (1/4)';
      case 2:
        return 'Trung bình (2/4)';
      case 3:
        return 'Khá mạnh (3/4)';
      case 4:
      default:
        return 'Rất mạnh (4/4)';
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
        return UniColors.primary;
      case 4:
      default:
        return UniColors.statusPresent;
    }
  }

  Future<void> _handleSubmit() async {
    final pwd = newPasswordController.text;
    final confirm = confirmPasswordController.text;

    if (pwd.length < 8) {
      Get.snackbar(
        'Lỗi mật khẩu',
        'Mật khẩu phải có tối thiểu 8 ký tự',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: UniColors.statusAbsentBg,
        colorText: UniColors.statusAbsent,
        margin: const EdgeInsets.all(UniSpacing.spaceMd),
      );
      return;
    }

    if (pwd != confirm) {
      Get.snackbar(
        'Lỗi mật khẩu',
        'Mật khẩu xác nhận không trùng khớp',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: UniColors.statusAbsentBg,
        colorText: UniColors.statusAbsent,
        margin: const EdgeInsets.all(UniSpacing.spaceMd),
      );
      return;
    }

    final success = await controller.resetPassword(
      email: email,
      otp: otp,
      newPassword: pwd,
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
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: UniColors.statusPresentBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  color: UniColors.statusPresent,
                  size: 32,
                ),
              ),
              const SizedBox(height: UniSpacing.spaceMd),
              Text(
                'Đặt Lại Mật Khẩu Thành Công!',
                style: UniTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: UniColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: UniSpacing.spaceXs),
              Text(
                'Mật khẩu tài khoản học vụ của bạn đã được cập nhật thành công. Vui lòng đăng nhập lại để tiếp tục.',
                textAlign: TextAlign.center,
                style: UniTypography.bodyMedium.copyWith(
                  color: UniColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: UniSpacing.spaceLg),
              UniPrimaryButton(
                text: 'Đăng Nhập Ngay',
                onPressed: () {
                  Get.back();
                  Get.offAllNamed(AppRoutes.login);
                },
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UniColors.canvas,
      appBar: UniAppHeader(
        title: 'Đặt Lại Mật Khẩu',
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
                // Header Visual Badge & Stage Tracker
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: UniColors.surfaceContainerLow,
                              borderRadius:
                                  BorderRadius.circular(UniSpacing.radiusMd),
                            ),
                            child: const Icon(
                              Icons.lock_reset,
                              color: UniColors.primary,
                              size: 32,
                            ),
                          ),
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: UniColors.accentDark,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_user,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: UniSpacing.spaceSm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: UniColors.surfaceContainerLow,
                          borderRadius:
                              BorderRadius.circular(UniSpacing.radiusFull),
                        ),
                        child: Text(
                          'BƯỚC 3/3 • BẢO MẬT',
                          style: UniTypography.labelSmall.copyWith(
                            color: UniColors.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: UniSpacing.spaceSm),
                      Text(
                        'Thiết lập mật khẩu mới',
                        style: UniTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: UniColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: UniSpacing.spaceXs),
                      Text(
                        'Tạo mật khẩu có độ bảo mật cao cho tài khoản của bạn. Mật khẩu không được trùng với mật khẩu gần nhất.',
                        textAlign: TextAlign.center,
                        style: UniTypography.bodySmall.copyWith(
                          color: UniColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: UniSpacing.spaceMd),

                // Error Message Banner if any
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
                      // Input 1: Mật khẩu mới
                      UniTextField(
                        label: 'Mật khẩu mới *',
                        hint: 'Nhập mật khẩu mới...',
                        controller: newPasswordController,
                        prefixIcon: Icons.key,
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
                        children: List.generate(4, (index) {
                          final isFilled = index < strengthScore;
                          return Expanded(
                            child: Container(
                              height: 4,
                              margin: EdgeInsets.only(
                                right: index < 3 ? 4 : 0,
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

                      // Criteria Checklist Box
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
                              'Có ít nhất 1 chữ in hoa (A-Z)',
                              hasUppercase,
                            ),
                            const SizedBox(height: 4),
                            _buildRuleItem(
                              'Có ít nhất 1 chữ số (0-9)',
                              hasNumber,
                            ),
                            const SizedBox(height: 4),
                            _buildRuleItem(
                              'Có ít nhất 1 ký tự đặc biệt (!@#\$%^&*)',
                              hasSpecialChar,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: UniSpacing.spaceMd),

                      // Input 2: Xác nhận mật khẩu mới
                      UniTextField(
                        label: 'Xác nhận mật khẩu mới *',
                        hint: 'Nhập lại mật khẩu...',
                        controller: confirmPasswordController,
                        prefixIcon: Icons.enhanced_encryption,
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
                                isMatching ? Icons.verified : Icons.cancel,
                                size: 16,
                                color: isMatching
                                    ? UniColors.statusPresent
                                    : UniColors.statusAbsent,
                              ),
                              const SizedBox(width: UniSpacing.spaceXs),
                              Text(
                                isMatching
                                    ? 'Mật khẩu xác nhận khớp hoàn toàn'
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

                      const SizedBox(height: UniSpacing.spaceLg),

                      // Submit Button
                      Obx(
                        () => UniPrimaryButton(
                          text: 'Cập nhật mật khẩu',
                          icon: Icons.arrow_forward,
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
