import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/uni_app_header.dart';
import '../../../shared/widgets/uni_card.dart';
import '../../../shared/widgets/uni_primary_button.dart';
import '../../../shared/widgets/uni_secondary_button.dart';
import '../../../shared/widgets/uni_text_field.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  late final AuthController controller;
  final TextEditingController identityController = TextEditingController();
  bool isSent = false;
  String submittedEmail = '';

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>();
  }

  @override
  void dispose() {
    identityController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final identity = identityController.text.trim();
    if (identity.isEmpty) {
      Get.snackbar(
        'Thông báo',
        'Vui lòng nhập địa chỉ email hoặc mã định danh của bạn',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: UniColors.card,
        colorText: UniColors.textPrimary,
        margin: const EdgeInsets.all(UniSpacing.spaceMd),
      );
      return;
    }

    submittedEmail = identity;
    final result = await controller.forgotPassword(identity);
    if (result != null) {
      setState(() {
        isSent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UniColors.canvas,
      appBar: UniAppHeader(
        title: 'Quên Mật Khẩu',
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
            child: isSent ? _buildSuccessCard() : _buildFormCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Brand & Visual Security Icon (Stitch 47a42ff114e84d66af4ccae58e34c7ac)
        Center(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: UniColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(UniSpacing.radiusLg),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: UniColors.card,
                        borderRadius:
                            BorderRadius.circular(UniSpacing.radiusMd),
                        boxShadow: UniSpacing.cardShadow,
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        color: UniColors.primary,
                        size: 32,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: UniColors.accentDark,
                        borderRadius:
                            BorderRadius.circular(UniSpacing.radiusFull),
                        boxShadow: UniSpacing.cardShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: UniColors.accentLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'BẢO MẬT',
                            style: UniTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 9,
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
              Text(
                'Khôi phục quyền truy cập',
                style: UniTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: UniColors.textPrimary,
                ),
              ),
              const SizedBox(height: UniSpacing.spaceXs),
              Text(
                'Nhập mã số sinh viên hoặc email trường (@edu.vn) đã được đăng ký trên hệ thống UniCheck để nhận mã xác thực đặt lại mật khẩu.',
                textAlign: TextAlign.center,
                style: UniTypography.bodyMedium.copyWith(
                  color: UniColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: UniSpacing.spaceLg),

        // Error message banner if any
        Obx(() {
          final error = controller.errorMessage.value;
          if (error.isEmpty) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(bottom: UniSpacing.spaceMd),
            padding: const EdgeInsets.all(UniSpacing.spaceMd),
            decoration: BoxDecoration(
              color: UniColors.statusAbsentBg,
              borderRadius: BorderRadius.circular(UniSpacing.radiusMd),
              border: Border.all(color: UniColors.statusAbsent.withAlpha(80)),
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

        // Form Section
        UniCard(
          padding: const EdgeInsets.all(UniSpacing.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UniTextField(
                label: 'Tên đăng nhập hoặc Email *',
                hint: 'VD: 2251120001 hoặc user@unicheck.edu.vn',
                helperText:
                    'Chỉ áp dụng cho tài khoản đã được cấp trong hệ thống.',
                controller: identityController,
                prefixIcon: Icons.badge_outlined,
                showClearButton: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleSend(),
              ),
              const SizedBox(height: UniSpacing.spaceLg),
              Obx(
                () => UniPrimaryButton(
                  text: 'Tiếp tục',
                  icon: Icons.send,
                  isLoading: controller.isLoading.value,
                  onPressed: _handleSend,
                ),
              ),
              const SizedBox(height: UniSpacing.spaceSm),
              TextButton.icon(
                onPressed: () {
                  Get.bottomSheet(
                    Container(
                      padding: const EdgeInsets.all(UniSpacing.spaceLg),
                      decoration: const BoxDecoration(
                        color: UniColors.card,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(UniSpacing.radiusXl),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hỗ Trợ Học Vụ & Kỹ Thuật',
                            style: UniTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: UniSpacing.spaceSm),
                          Text(
                            'Nếu bạn quên địa chỉ email hoặc mất quyền truy cập vào tài khoản, vui lòng liên hệ quản trị viên để được cấp lại mật khẩu.',
                            style: UniTypography.bodyMedium.copyWith(
                              color: UniColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: UniSpacing.spaceLg),
                          UniPrimaryButton(
                            text: 'Đã rõ',
                            onPressed: () => Get.back(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.support_agent,
                  size: 18,
                  color: UniColors.primary,
                ),
                label: Text(
                  'Cần trợ giúp? Liên hệ Quản trị viên',
                  style: UniTypography.labelMedium.copyWith(
                    color: UniColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: UniSpacing.spaceXl),
        _buildComplianceFooter(),
      ],
    );
  }

  Widget _buildSuccessCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // OWASP Neutral Feedback Box
        UniCard(
          padding: const EdgeInsets.all(UniSpacing.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: UniColors.statusPresentBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read,
                      color: UniColors.statusPresent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: UniSpacing.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đã ghi nhận yêu cầu',
                          style: UniTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: UniColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Bảo mật học bạ & dữ liệu sinh trắc học',
                          style: UniTypography.labelSmall.copyWith(
                            color: UniColors.statusPresent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UniSpacing.spaceMd),
              const Divider(),
              const SizedBox(height: UniSpacing.spaceMd),
              Text(
                'Để bảo vệ quyền riêng tư và an ninh học vụ, nếu tài khoản ($submittedEmail) tồn tại trong hệ thống, hướng dẫn và mã xác thực 6 chữ số đã được gửi qua email trường đã đăng ký. Vui lòng kiểm tra hộp thư đến và thư mục spam.',
                style: UniTypography.bodyMedium.copyWith(
                  color: UniColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: UniSpacing.spaceMd),
              // Security Checklist Box
              Container(
                padding: const EdgeInsets.all(UniSpacing.spaceSm),
                decoration: BoxDecoration(
                  color: UniColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(UniSpacing.radiusSm),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: UniColors.statusPresent,
                        ),
                        const SizedBox(width: UniSpacing.spaceXs),
                        Expanded(
                          child: Text(
                            'Mã OTP có hiệu lực trong vòng 10 phút',
                            style: UniTypography.bodySmall.copyWith(
                              color: UniColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: UniSpacing.spaceXs),
                    Row(
                      children: [
                        const Icon(
                          Icons.shield,
                          size: 16,
                          color: UniColors.statusPresent,
                        ),
                        const SizedBox(width: UniSpacing.spaceXs),
                        Expanded(
                          child: Text(
                            'Tuyệt đối không chia sẻ mã xác thực với bất kỳ ai',
                            style: UniTypography.bodySmall.copyWith(
                              color: UniColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: UniSpacing.spaceLg),

        // Action Buttons
        UniPrimaryButton(
          text: 'Nhập mã xác thực (OTP)',
          icon: Icons.pin,
          onPressed: () {
            Get.toNamed(
              AppRoutes.verifyOtp,
              arguments: {'email': submittedEmail},
            );
          },
        ),
        const SizedBox(height: UniSpacing.spaceSm),
        UniSecondaryButton(
          text: 'Thử lại với tài khoản khác',
          onPressed: () {
            setState(() {
              isSent = false;
            });
          },
        ),
        const SizedBox(height: UniSpacing.spaceXs),
        TextButton(
          onPressed: () => Get.offAllNamed(AppRoutes.login),
          child: Text(
            'Quay lại màn hình Đăng nhập',
            style: UniTypography.labelMedium.copyWith(
              color: UniColors.primary,
            ),
          ),
        ),

        const SizedBox(height: UniSpacing.spaceXl),
        _buildComplianceFooter(),
      ],
    );
  }

  Widget _buildComplianceFooter() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: UniSpacing.spaceXs,
      runSpacing: 2,
      children: [
        const Icon(
          Icons.lock_outline,
          size: 14,
          color: UniColors.textMuted,
        ),
        Text(
          'Mã hóa SSL/TLS 256-bit',
          style: UniTypography.labelSmall.copyWith(
            color: UniColors.textMuted,
          ),
        ),
        Text(
          '• Bảo mật tài khoản đa lớp',
          style: UniTypography.labelSmall.copyWith(
            color: UniColors.textMuted,
          ),
        ),
      ],
    );
  }
}
