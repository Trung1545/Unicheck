import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/uni_app_header.dart';
import '../../../shared/widgets/uni_card.dart';
import '../../../shared/widgets/uni_primary_button.dart';
import '../controllers/auth_controller.dart';

class VerifyOtpView extends StatefulWidget {
  const VerifyOtpView({super.key});

  @override
  State<VerifyOtpView> createState() => _VerifyOtpViewState();
}

class _VerifyOtpViewState extends State<VerifyOtpView> {
  late final AuthController controller;
  late final String email;
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _countdownTimer;
  int _secondsRemaining = 600; // 10 minutes from backend Redis TTL
  int _resendCooldown = 60; // 60s cooldown for resend button
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>();
    final args = Get.arguments as Map<String, dynamic>?;
    email = args?['email'] as String? ?? 'sv@vnu.edu.vn';
    _startTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        }
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          _canResend = true;
        }
      });
    });
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _currentOtp =>
      _otpControllers.map((c) => c.text.trim()).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_currentOtp.length == 6) {
          _verifyAndProceed();
        }
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    setState(() {
      _canResend = false;
      _resendCooldown = 60;
    });

    final res = await controller.forgotPassword(email);
    if (res != null && mounted) {
      Get.snackbar(
        'Đã gửi lại mã',
        'Mã xác thực mới đã được gửi tới hòm thư $email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: UniColors.card,
        colorText: UniColors.textPrimary,
        margin: const EdgeInsets.all(UniSpacing.spaceMd),
      );
    }
  }

  void _verifyAndProceed() {
    final otp = _currentOtp;
    if (otp.length < 6) {
      Get.snackbar(
        'Lỗi xác thực',
        'Vui lòng nhập đủ 6 chữ số mã OTP',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: UniColors.statusAbsentBg,
        colorText: UniColors.statusAbsent,
        margin: const EdgeInsets.all(UniSpacing.spaceMd),
      );
      return;
    }

    // Navigate to Reset Password Screen with email and OTP
    Get.toNamed(
      AppRoutes.resetPassword,
      arguments: {
        'email': email,
        'otp': otp,
      },
    );
  }

  String _maskEmail(String rawEmail) {
    if (!rawEmail.contains('@')) return rawEmail;
    final parts = rawEmail.split('@');
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 3) {
      return '$name***@$domain';
    }
    return '${name.substring(0, 3)}***@$domain';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UniColors.canvas,
      appBar: UniAppHeader(
        title: 'Xác Thực OTP',
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
                // Security Shield Institutional Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: UniColors.surfaceContainerLow,
                        borderRadius:
                            BorderRadius.circular(UniSpacing.radiusFull),
                        border: Border.all(color: UniColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: UniColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: UniSpacing.spaceXs),
                          const Icon(
                            Icons.verified_user,
                            size: 14,
                            color: UniColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'BẢO MẬT 2 LỚP (2FA)',
                            style: UniTypography.labelSmall.copyWith(
                              color: UniColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.security,
                          size: 14,
                          color: UniColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ID: #AUTH-OTP',
                          style: UniTypography.labelSmall.copyWith(
                            color: UniColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: UniSpacing.spaceMd),

                // Main Title & Context Card
                UniCard(
                  padding: const EdgeInsets.all(UniSpacing.spaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
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
                              Icons.mark_email_read,
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
                                  'Nhập mã xác thực',
                                  style: UniTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: UniColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Mã 6 chữ số vừa được gửi đến hòm thư học vụ liên kết của bạn:',
                                  style: UniTypography.bodySmall.copyWith(
                                    color: UniColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: UniSpacing.spaceSm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: UniSpacing.spaceSm,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: UniColors.surfaceContainerLow,
                          borderRadius:
                              BorderRadius.circular(UniSpacing.radiusSm),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.school,
                                  size: 16,
                                  color: UniColors.primary,
                                ),
                                const SizedBox(width: UniSpacing.spaceXs),
                                Text(
                                  _maskEmail(email),
                                  style: UniTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: UniColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: UniColors.card,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: UniColors.border),
                              ),
                              child: Text(
                                _formatTimer(_secondsRemaining),
                                style: UniTypography.labelSmall.copyWith(
                                  color: UniColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: UniSpacing.spaceMd),

                // OTP 6-Digit Slots Card
                UniCard(
                  padding: const EdgeInsets.all(UniSpacing.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'MÃ BẢO MẬT GỒM 6 SỐ',
                        style: UniTypography.labelSmall.copyWith(
                          color: UniColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: UniSpacing.spaceMd),

                      // 6 Slots Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 44,
                            height: 52,
                            child: TextFormField(
                              controller: _otpControllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: UniTypography.headlineSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: UniColors.textPrimary,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                counterText: '',
                                contentPadding: EdgeInsets.zero,
                                filled: true,
                                fillColor: UniColors.surfaceContainerLow,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    UniSpacing.radiusSm,
                                  ),
                                  borderSide:
                                      const BorderSide(color: UniColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    UniSpacing.radiusSm,
                                  ),
                                  borderSide: const BorderSide(
                                    color: UniColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (val) => _onDigitChanged(index, val),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: UniSpacing.spaceMd),
                      Center(
                        child: Text(
                          'Chạm để nhập hoặc dán mã OTP từ email học vụ',
                          style: UniTypography.bodySmall.copyWith(
                            color: UniColors.textMuted,
                          ),
                        ),
                      ),

                      const SizedBox(height: UniSpacing.spaceMd),
                      const Divider(),
                      const SizedBox(height: UniSpacing.spaceSm),

                      // Expiration Timer & Resend Controls
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: UniSpacing.spaceSm,
                        runSpacing: UniSpacing.spaceXs,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 16,
                                color: UniColors.primary,
                              ),
                              const SizedBox(width: UniSpacing.spaceXs),
                              Text(
                                'Hết hạn sau: ',
                                style: UniTypography.bodySmall.copyWith(
                                  color: UniColors.textSecondary,
                                ),
                              ),
                              Text(
                                _formatTimer(_secondsRemaining),
                                style: UniTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: UniColors.primary,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: _canResend ? _handleResend : null,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text(
                              _canResend
                                  ? 'Gửi lại mã'
                                  : 'Gửi lại (${_resendCooldown}s)',
                              style: UniTypography.labelMedium.copyWith(
                                color: _canResend
                                    ? UniColors.primary
                                    : UniColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: UniSpacing.spaceMd),

                      // Submit Button
                      UniPrimaryButton(
                        text: 'Xác nhận mã OTP',
                        icon: Icons.task_alt,
                        onPressed: _verifyAndProceed,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: UniSpacing.spaceMd),

                // Help Desk Quick Box
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UniSpacing.spaceMd,
                    vertical: UniSpacing.spaceSm,
                  ),
                  decoration: BoxDecoration(
                    color: UniColors.card,
                    borderRadius: BorderRadius.circular(UniSpacing.radiusMd),
                    border: Border.all(color: UniColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.contact_support_outlined,
                              size: 18,
                              color: UniColors.primary,
                            ),
                            const SizedBox(width: UniSpacing.spaceSm),
                            Flexible(
                              child: Text(
                                'Không thể truy cập email này?',
                                style: UniTypography.bodySmall.copyWith(
                                  color: UniColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.bottomSheet(
                            Container(
                              padding:
                                  const EdgeInsets.all(UniSpacing.spaceLg),
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
                                    'Liên Hệ Phòng Đào Tạo',
                                    style: UniTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: UniSpacing.spaceSm),
                                  Text(
                                    'Địa điểm: Văn phòng Đào tạo (P.101 Nhà A1)\nHotline: 028.3865.2442\nEmail hỗ trợ: daotao@unicheck.edu.vn',
                                    style: UniTypography.bodyMedium.copyWith(
                                      color: UniColors.textPrimary,
                                      height: 1.5,
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
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              'Phòng Đào Tạo',
                              style: UniTypography.labelMedium.copyWith(
                                color: UniColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: UniColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: UniSpacing.spaceLg),

                // Trust Institutional Card
                UniCard(
                  padding: const EdgeInsets.all(UniSpacing.spaceSm),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: UniColors.surfaceContainerLow,
                          borderRadius:
                              BorderRadius.circular(UniSpacing.radiusSm),
                        ),
                        child: const Icon(
                          Icons.shield,
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
                              'Cổng xác thực sinh viên tập trung',
                              style: UniTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: UniColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Bảo vệ bảng điểm, tín chỉ và thông tin bằng cấp số',
                              style: UniTypography.bodySmall.copyWith(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
