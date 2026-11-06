import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/uni_card.dart';
import '../../../shared/widgets/uni_primary_button.dart';
import '../../../shared/widgets/uni_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final AuthController controller;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = true;
  int selectedRoleIndex = 0; // 0: Sinh viên, 1: Giảng viên, 2: Quản trị

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (controller.isLoading.value) return;
    controller.login(
      usernameController.text,
      passwordController.text,
    );
  }

  void _onRoleTabChanged(int index) {
    setState(() {
      selectedRoleIndex = index;
    });
    if (index != 0) {
      final roleName = index == 1 ? 'Giảng viên' : 'Quản trị viên';
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
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: UniColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: UniSpacing.spaceMd),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: UniColors.primaryContainer.withAlpha(30),
                      borderRadius: BorderRadius.circular(UniSpacing.radiusMd),
                    ),
                    child: const Icon(
                      Icons.desktop_windows,
                      color: UniColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: UniSpacing.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cổng Thông Tin $roleName',
                          style: UniTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Nền tảng Quản trị & Giảng dạy Web Desktop',
                          style: UniTypography.bodySmall.copyWith(
                            color: UniColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UniSpacing.spaceMd),
              Text(
                'Ứng dụng di động UniCheck được thiết kế chuyên biệt cho Sinh viên điểm danh sinh trắc học và theo dõi học tập.\n\n$roleName vui lòng truy cập cổng quản lý thông qua trình duyệt Web Desktop để sử dụng đầy đủ các tính năng điểm danh và quản lý học phần.',
                style: UniTypography.bodyMedium.copyWith(
                  color: UniColors.textPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: UniSpacing.spaceLg),
              UniPrimaryButton(
                text: 'Đã hiểu, tiếp tục với tư cách Sinh viên',
                onPressed: () {
                  setState(() {
                    selectedRoleIndex = 0;
                  });
                  Get.back();
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showSsoNotice() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UniSpacing.radiusLg),
        ),
        backgroundColor: UniColors.card,
        child: Padding(
          padding: const EdgeInsets.all(UniSpacing.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: UniColors.primaryContainer.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school,
                  color: UniColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(height: UniSpacing.spaceMd),
              Text(
                'Đăng nhập Một Lần (SSO)',
                style: UniTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: UniSpacing.spaceXs),
              Text(
                'Tính năng tích hợp Single Sign-On (SSO) đang được hoàn thiện.\n\nVui lòng sử dụng Tên đăng nhập và Mật khẩu được cấp để đăng nhập hệ thống.',
                textAlign: TextAlign.center,
                style: UniTypography.bodyMedium.copyWith(
                  color: UniColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: UniSpacing.spaceLg),
              UniPrimaryButton(
                text: 'Đóng',
                onPressed: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UniColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: UniSpacing.screenMargin,
              vertical: UniSpacing.spaceMd,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Branding Module (Stitch e33ee574d1d84c8a8c5a65c09d27f83c)
                  Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: UniColors.primary,
                          borderRadius:
                              BorderRadius.circular(UniSpacing.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: UniColors.primary.withAlpha(40),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: UniSpacing.spaceSm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'UniCheck',
                            style: UniTypography.headlineLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: UniColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: UniSpacing.spaceXs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: UniColors.surfaceContainerLow,
                              borderRadius:
                                  BorderRadius.circular(UniSpacing.radiusFull),
                              border: Border.all(color: UniColors.border),
                            ),
                            child: Text(
                              'HỌC VỤ & ĐIỂM DANH',
                              style: UniTypography.labelSmall.copyWith(
                                color: UniColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: UniSpacing.spaceXs),
                      Text(
                        'Hệ thống Điểm danh Sinh trắc học Thông minh',
                        textAlign: TextAlign.center,
                        style: UniTypography.bodySmall.copyWith(
                          color: UniColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: UniSpacing.spaceMd),

                  // Role Selector Segmented Tab
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: UniColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(UniSpacing.radiusMd),
                      border: Border.all(color: UniColors.border),
                    ),
                    child: Row(
                      children: [
                        _buildRoleTab(0, 'Sinh viên'),
                        _buildRoleTab(1, 'Giảng viên'),
                        _buildRoleTab(2, 'Quản trị'),
                      ],
                    ),
                  ),

                  const SizedBox(height: UniSpacing.spaceMd),

                  // Dynamic Alert Banner Area
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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

                  // Form Card Container
                  UniCard(
                    padding: const EdgeInsets.all(UniSpacing.spaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Username Field
                        UniTextField(
                          label: 'Tên đăng nhập / MSSV / Email',
                          hint: 'VD: 2251120001 hoặc email @edu.vn',
                          controller: usernameController,
                          prefixIcon: Icons.badge_outlined,
                          showClearButton: true,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: UniSpacing.spaceMd),

                        // Password Field
                        UniTextField(
                          label: 'Mật khẩu',
                          hint: 'Nhập mật khẩu của bạn',
                          controller: passwordController,
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),

                        const SizedBox(height: UniSpacing.spaceXs),

                        // Remember Me & Forgot Password Row (Overflow-safe)
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: rememberMe,
                                      activeColor: UniColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          rememberMe = val ?? true;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: UniSpacing.spaceXs),
                                  Flexible(
                                    child: Text(
                                      'Ghi nhớ đăng nhập',
                                      style:
                                          UniTypography.bodySmall.copyWith(
                                        color: UniColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                Get.toNamed(AppRoutes.forgotPassword);
                              },
                              child: Text(
                                'Quên mật khẩu?',
                                style: UniTypography.labelMedium.copyWith(
                                  color: UniColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: UniSpacing.spaceLg),

                        // Primary Login Button
                        Obx(
                          () => UniPrimaryButton(
                            text: 'Đăng Nhập',
                            isLoading: controller.isLoading.value,
                            onPressed: _submit,
                          ),
                        ),

                        const SizedBox(height: UniSpacing.spaceMd),

                        // Institutional Divider
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: UniSpacing.spaceSm,
                              ),
                              child: Text(
                                'HOẶC ĐĂNG NHẬP LIÊN KẾT',
                                style: UniTypography.labelSmall.copyWith(
                                  color: UniColors.textMuted,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: UniSpacing.spaceMd),

                        // SSO Institutional Button
                        OutlinedButton(
                          onPressed: _showSsoNotice,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              UniSpacing.minButtonHeight,
                            ),
                            side: const BorderSide(color: UniColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: UniSpacing.borderRadiusMd,
                            ),
                            backgroundColor: UniColors.surfaceContainerLow,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color:
                                      UniColors.primaryContainer.withAlpha(30),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.school,
                                  size: 16,
                                  color: UniColors.primary,
                                ),
                              ),
                              const SizedBox(width: UniSpacing.spaceSm),
                              Flexible(
                                child: Text(
                                  'Đăng nhập tài khoản trường (@edu.vn)',
                                  style: UniTypography.labelMedium.copyWith(
                                    color: UniColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: UniSpacing.spaceLg),

                  // Institutional Compliance Footnote (Wrap to prevent overflow on small viewports)
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: UniSpacing.spaceXs,
                    runSpacing: 2,
                    children: [
                      const Icon(
                        Icons.verified_user,
                        size: 14,
                        color: UniColors.statusPresent,
                      ),
                      Text(
                        'Bảo mật kết nối SSL/TLS 256-bit',
                        style: UniTypography.bodySmall.copyWith(
                          color: UniColors.textSecondary,
                        ),
                      ),
                      Text(
                        '• UniCheck Mobile v2.4.0',
                        style: UniTypography.labelSmall.copyWith(
                          color: UniColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(int index, String title) {
    final isSelected = selectedRoleIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onRoleTabChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? UniColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(UniSpacing.radiusSm),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: UniTypography.labelMedium.copyWith(
              color: isSelected ? UniColors.primary : UniColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
