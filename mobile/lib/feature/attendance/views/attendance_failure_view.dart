import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/uni_card.dart';
import '../../../shared/widgets/uni_primary_button.dart';
import '../../../shared/widgets/uni_secondary_button.dart';
import '../../../shared/widgets/verification_check_item.dart';
import '../controllers/attendance_controller.dart';

class AttendanceFailureView extends StatelessWidget {
  const AttendanceFailureView({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceController = Get.find<AttendanceController>();
    final slot = attendanceController.currentSession.value;

    final diagCode = attendanceController.diagnosticCode.value.isNotEmpty
        ? attendanceController.diagnosticCode.value
        : 'ERR_WIFI_OUT_OF_RANGE';
    final diagReason = attendanceController.diagnosticReason.value.isNotEmpty
        ? attendanceController.diagnosticReason.value
        : 'Thiết bị đang kết nối mạng ngoài khuôn viên trường hoặc không thuộc trạm phát phòng học.';

    return Scaffold(
      backgroundColor: UniColors.canvas,
      appBar: AppBar(
        backgroundColor: UniColors.card,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.close, color: UniColors.textPrimary),
          onPressed: () => Get.offAllNamed(AppRoutes.studentDashboard),
        ),
        title: Text(
          'Kết Quả Điểm Danh',
          style: UniTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: UniSpacing.margin,
            vertical: UniSpacing.spaceMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Error Emblem
              _buildHeroErrorSection(),
              const SizedBox(height: UniSpacing.spaceMd),

              // 2. Diagnostic Card
              _buildDiagnosticCard(diagCode, diagReason, attendanceController),
              const SizedBox(height: UniSpacing.spaceMd),

              // 3. Session Context Card
              if (slot != null) ...[
                _buildSessionContextCard(slot),
                const SizedBox(height: UniSpacing.spaceMd),
              ],

              // 4. Action Buttons
              UniPrimaryButton(
                text: 'Thử đối soát lại',
                icon: Icons.refresh_rounded,
                onPressed: () {
                  attendanceController.runEligibilityChecks();
                  Get.back();
                },
              ),
              const SizedBox(height: UniSpacing.spaceSm),
              UniSecondaryButton(
                text: 'Về trang chủ sinh viên',
                icon: Icons.home_outlined,
                onPressed: () => Get.offAllNamed(AppRoutes.studentDashboard),
              ),
              const SizedBox(height: UniSpacing.spaceXl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroErrorSection() {
    return Column(
      children: [
        // Error Emblem
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFFFECEC),
            shape: BoxShape.circle,
            border: Border.all(
              color: UniColors.error.withValues(alpha: 0.3),
              width: 3,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.gpp_maybe_rounded,
              size: 40,
              color: UniColors.error,
            ),
          ),
        ),
        const SizedBox(height: UniSpacing.spaceSm + 2),

        // Status Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFECEC),
            borderRadius: UniSpacing.borderRadiusFull,
          ),
          child: Text(
            'XÁC THỰC CHƯA HOÀN TẤT',
            style: UniTypography.caption.copyWith(
              color: UniColors.error,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: UniSpacing.spaceSm),

        // Heading & Subheading
        Text(
          'Điểm danh không thành công',
          style: UniTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Hệ thống chưa thể ghi nhận kết quả do thông tin đối soát chưa đáp ứng yêu cầu xác thực điểm danh.',
          textAlign: TextAlign.center,
          style: UniTypography.bodySmall.copyWith(
            color: UniColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosticCard(
    String diagCode,
    String diagReason,
    AttendanceController controller,
  ) {
    return UniCard(
      padding: const EdgeInsets.all(UniSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: UniColors.canvas,
              borderRadius: UniSpacing.borderRadiusSm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MÃ CHẨN ĐOÁN HỆ THỐNG',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: UniColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      diagCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: UniColors.error,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.verified_user_outlined,
                  size: 20,
                  color: UniColors.border,
                ),
              ],
            ),
          ),
          const SizedBox(height: UniSpacing.spaceSm + 2),

          // Diagnostic Narrative
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 16, color: UniColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  diagReason,
                  style: UniTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.policy_outlined,
                  size: 16, color: UniColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quy chế yêu cầu sinh viên phải có mặt trực tiếp trong vùng phát sóng Wi-Fi phòng học để đảm bảo tính minh bạch.',
                  style: UniTypography.caption.copyWith(
                    color: UniColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: UniSpacing.spaceMd),

          // Triple Validation Criteria Check
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: UniColors.canvas,
              borderRadius: UniSpacing.borderRadiusSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'BẢNG ĐỐI SOÁT TIÊU CHÍ (3 LỚP BẢO VỆ)',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: UniColors.textMuted,
                      ),
                    ),
                    Text(
                      '${controller.passedCriteriaCount}/5 Đạt',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: controller.isAllPassed
                            ? UniColors.success
                            : UniColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildCriteriaStatusRow(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Mã phản hồi QR phòng học',
                  isPass: controller.qrStatus.value == VerificationStatus.pass,
                  statusText: controller.qrStatus.value == VerificationStatus.pass
                      ? 'Hợp lệ'
                      : 'Không hợp lệ',
                ),
                const SizedBox(height: 6),
                _buildCriteriaStatusRow(
                  icon: Icons.wifi_rounded,
                  title: 'Mạng Wi-Fi trạm cơ sở',
                  isPass: controller.wifiStatus.value == VerificationStatus.pass,
                  statusText: controller.wifiStatus.value == VerificationStatus.pass
                      ? 'Hợp lệ'
                      : 'Không hợp lệ',
                ),
                const SizedBox(height: 6),
                _buildCriteriaStatusRow(
                  icon: Icons.face_rounded,
                  title: 'Khuôn mặt Face-ID',
                  isPass: controller.faceStatus.value == VerificationStatus.pass,
                  statusText: controller.faceStatus.value == VerificationStatus.pass
                      ? 'Sẵn sàng'
                      : 'Tạm dừng',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaStatusRow({
    required IconData icon,
    required String title,
    required bool isPass,
    required String statusText,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              isPass ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 16,
              color: isPass ? UniColors.statusPresent : UniColors.error,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: UniTypography.caption.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isPass
                ? UniColors.statusPresentBg
                : UniColors.statusAbsentBg,
            borderRadius: UniSpacing.borderRadiusFull,
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isPass
                  ? UniColors.statusPresentText
                  : UniColors.statusAbsentText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionContextCard(dynamic slot) {
    return UniCard(
      padding: const EdgeInsets.all(UniSpacing.spaceSm + 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.school_outlined,
                  size: 16, color: UniColors.primary),
              const SizedBox(width: 6),
              Text(
                '${slot.courseCode} • ${slot.courseName}',
                style: UniTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: UniColors.canvas,
              borderRadius: UniSpacing.borderRadiusSm,
            ),
            child: Text(
              slot.roomDisplay,
              style: const TextStyle(
                fontSize: 10,
                color: UniColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
