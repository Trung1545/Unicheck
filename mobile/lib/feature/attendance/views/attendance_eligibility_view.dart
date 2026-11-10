import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/uni_card.dart';
import '../../../shared/widgets/uni_primary_button.dart';
import '../../../shared/widgets/verification_check_item.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/attendance_controller.dart';

class AttendanceEligibilityView extends StatelessWidget {
  const AttendanceEligibilityView({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceController = Get.find<AttendanceController>();
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: UniColors.canvas,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: UniSpacing.margin,
            vertical: UniSpacing.spaceMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Progress Stepper Tracker
              _buildProgressStepper(),
              const SizedBox(height: UniSpacing.spaceMd),

              // 2. Academic Protocol Banner
              _buildProtocolBanner(),
              const SizedBox(height: UniSpacing.spaceMd),
              Obx(() => _buildRecheckAlertBanner(attendanceController)),
              const SizedBox(height: UniSpacing.spaceMd),

              // 3. Class & Session Info Card
              _buildSessionInfoCard(attendanceController, authController),
              const SizedBox(height: UniSpacing.spaceMd),

              // 4. Section Header with Counter Badge
              _buildCriteriaHeader(attendanceController),
              const SizedBox(height: UniSpacing.spaceSm),

              // 5. Eligibility Checklist Stack (5 VerificationCheckItems)
              _buildChecklistStack(attendanceController),
              const SizedBox(height: UniSpacing.spaceMd),

              // 6. Error Diagnostic Card (Conditional)
              Obx(() {
                final isPassed = attendanceController.isAllPassed;
                final isEval = attendanceController.isEvaluating.value;
                if (isEval || isPassed) {
                  return const SizedBox.shrink();
                }
                return _buildErrorDiagnosticCard(attendanceController);
              }),

              // 7. Action Panel
              _buildActionPanel(attendanceController),
              const SizedBox(height: UniSpacing.spaceXl),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: UniColors.card,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: UniColors.textPrimary),
        onPressed: () => Get.back(),
      ),
      title: Text(
        'Check In Verification',
        style: UniTypography.titleLarge.copyWith(
          fontWeight: FontWeight.bold,
          color: UniColors.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.verified_user_outlined,
              color: UniColors.primary),
          onPressed: () {},
        ),
        const Padding(
          padding: EdgeInsets.only(right: UniSpacing.margin),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: UniColors.primary,
            child: Icon(Icons.person, size: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStepper() {
    return UniCard(
      padding: const EdgeInsets.symmetric(
        horizontal: UniSpacing.spaceMd,
        vertical: UniSpacing.spaceSm + 4,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Connecting Track
          Positioned(
            left: 36,
            right: 36,
            top: 16,
            child: Container(
              height: 2,
              color: UniColors.border,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Step 1: Quét QR (Completed)
              _buildStepNode(
                stepNum: '1. Quét QR',
                subText: 'Hoàn tất',
                icon: Icons.check,
                isCompleted: true,
                isActive: false,
              ),

              // Step 2: Đối soát (Active)
              _buildStepNode(
                stepNum: '2. Đối soát',
                subText: 'Đang xác thực',
                icon: Icons.verified_outlined,
                isCompleted: false,
                isActive: true,
              ),

              // Step 3: Face-ID (Pending)
              _buildStepNode(
                stepNum: '3. Face-ID',
                subText: 'Kế tiếp',
                icon: Icons.face_rounded,
                isCompleted: false,
                isActive: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode({
    required String stepNum,
    required String subText,
    required IconData icon,
    required bool isCompleted,
    required bool isActive,
  }) {
    Color circleColor;
    Color iconColor;
    Color textColor;

    if (isCompleted) {
      circleColor = UniColors.statusPresent;
      iconColor = Colors.white;
      textColor = UniColors.statusPresentText;
    } else if (isActive) {
      circleColor = UniColors.primary;
      iconColor = Colors.white;
      textColor = UniColors.primary;
    } else {
      circleColor = const Color(0xFFF1F5F9);
      iconColor = UniColors.textMuted;
      textColor = UniColors.textSecondary;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: UniColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(height: 4),
        Text(
          stepNum,
          style: UniTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          subText,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProtocolBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: UniColors.primaryLight,
        borderRadius: UniSpacing.borderRadiusSm,
        border: Border.all(color: UniColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.security, size: 18, color: UniColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Xác thực tuân thủ tiêu chuẩn an toàn dữ liệu. Nghiêm cấm mọi hành vi điểm danh hộ.',
              style: UniTypography.caption.copyWith(
                color: UniColors.primaryDark,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecheckAlertBanner(AttendanceController controller) {
    final recheck = controller.activeRecheckRequest.value;
    if (recheck == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: UniSpacing.spaceMd),
      padding: const EdgeInsets.all(UniSpacing.spaceMd),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: UniSpacing.borderRadiusMd,
        border: Border.all(color: const Color(0xFFF97316), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_problem_rounded, color: Color(0xFFEA580C), size: 28),
          const SizedBox(width: UniSpacing.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ĐIỂM DANH LẠI THEO YÊU CẦU GIẢNG VIÊN',
                  style: UniTypography.labelSmall.copyWith(
                    color: const Color(0xFF9A3412),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Giảng viên ${recheck.requestedByName}: "${recheck.reason}"',
                  style: UniTypography.bodySmall.copyWith(
                    color: const Color(0xFF7C2D12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfoCard(
    AttendanceController attendanceController,
    AuthController authController,
  ) {
    return Obx(() {
      final slot = attendanceController.currentSession.value;
      final user = authController.user.value;

      return UniCard(
        padding: const EdgeInsets.all(UniSpacing.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: UniColors.primaryLight,
                    borderRadius: UniSpacing.borderRadiusFull,
                  ),
                  child: Text(
                    '${slot?.courseCode ?? 'HP'} • ${slot?.className ?? 'Lớp 01'}',
                    style: UniTypography.caption.copyWith(
                      color: UniColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: UniColors.statusPresentBg,
                    borderRadius: UniSpacing.borderRadiusFull,
                  ),
                  child: Text(
                    slot?.periodsDisplay ?? 'Tiết học',
                    style: UniTypography.caption.copyWith(
                      color: UniColors.statusPresentText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: UniSpacing.spaceSm),
            Text(
              slot?.courseName ?? 'Môn học chưa xác định',
              style: UniTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: UniSpacing.spaceSm),

            // Metadata row
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.meeting_room_outlined,
                        size: 14, color: UniColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      slot?.roomDisplay ?? 'Phòng học',
                      style: UniTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline,
                        size: 14, color: UniColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      slot?.lecturerDisplay ?? 'Giảng viên',
                      style: UniTypography.caption.copyWith(
                        color: UniColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: UniSpacing.spaceSm),

            // Time Window container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: UniColors.canvas,
                borderRadius: UniSpacing.borderRadiusSm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 16, color: UniColors.primary),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CỬA SỔ ĐIỂM DANH',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: UniColors.textMuted,
                            ),
                          ),
                          Text(
                            slot?.timeSlot ?? 'Đang diễn ra',
                            style: UniTypography.caption.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'TRẠNG THÁI',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: UniColors.textMuted,
                        ),
                      ),
                      Text(
                        'Đang hoạt động',
                        style: UniTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: UniColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: UniSpacing.spaceSm),

            // Student row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sinh viên: ${user?.fullName ?? 'N/A'}',
                  style: UniTypography.caption.copyWith(
                    color: UniColors.textSecondary,
                  ),
                ),
                Text(
                  'MSSV: ${user?.code ?? user?.username ?? 'N/A'}',
                  style: UniTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCriteriaHeader(AttendanceController controller) {
    return Obx(() {
      final passedCount = controller.passedCriteriaCount;
      final isAll = controller.isAllPassed;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined,
                  size: 20, color: UniColors.primary),
              const SizedBox(width: 6),
              Text(
                'Tiêu chí điều kiện',
                style: UniTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isAll
                  ? UniColors.statusPresentBg
                  : UniColors.warning.withValues(alpha: 0.15),
              borderRadius: UniSpacing.borderRadiusFull,
            ),
            child: Text(
              '$passedCount/5 Đạt yêu cầu',
              style: UniTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: isAll ? UniColors.statusPresentText : UniColors.warning,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildChecklistStack(AttendanceController controller) {
    return Obx(() {
      return Column(
        children: [
          // 1. QR Code
          VerificationCheckItem(
            stepNumber: 1,
            title: 'Mã QR giảng đường hợp lệ',
            description: controller.qrNote.value,
            icon: Icons.qr_code_scanner_rounded,
            status: controller.qrStatus.value,
            onRetry: () => Get.back(),
          ),
          const SizedBox(height: UniSpacing.spaceSm),

          // 2. Wi-Fi & Room Location
          VerificationCheckItem(
            stepNumber: 2,
            title: 'Mạng Wi-Fi & Vị trí phòng học',
            description: controller.wifiNote.value,
            icon: Icons.wifi_rounded,
            status: controller.wifiStatus.value,
            customStatusText: (controller.wifiSimulationAllowed.value &&
                    controller.wifiStatus.value == VerificationStatus.pass)
                ? 'Wi-Fi mô phỏng (Demo) – Đạt'
                : null,
            note: controller.wifiSimulationAllowed.value
                ? 'Chế độ Wi-Fi mô phỏng (Demo) trên Android Emulator được máy chủ cấp phép.'
                : 'Lưu ý: Kết nối Wi-Fi chỉ đối soát phòng học, không thay thế xác thực sinh trắc học Face-ID.',
            onRetry: () => controller.runEligibilityChecks(),
          ),
          const SizedBox(height: UniSpacing.spaceSm),

          // 3. Time Window
          VerificationCheckItem(
            stepNumber: 3,
            title: 'Khung giờ ca học quy định',
            description: controller.timeNote.value,
            icon: Icons.more_time_rounded,
            status: controller.timeStatus.value,
            onRetry: () => controller.runEligibilityChecks(),
          ),
          const SizedBox(height: UniSpacing.spaceSm),

          // 4. Course Enrollment
          VerificationCheckItem(
            stepNumber: 4,
            title: 'Trạng thái ghi danh học phần',
            description: controller.enrollmentNote.value,
            icon: Icons.how_to_reg_rounded,
            status: controller.enrollmentStatus.value,
            onRetry: () => controller.runEligibilityChecks(),
          ),
          const SizedBox(height: UniSpacing.spaceSm),

          // 5. Face-ID Profile
          VerificationCheckItem(
            stepNumber: 5,
            title: 'Dữ liệu khuôn mặt Face-ID',
            description: controller.faceNote.value,
            icon: Icons.face_retouching_natural_rounded,
            status: controller.faceStatus.value,
            onRetry: () {
              if (!controller.isFaceRegistered.value) {
                Get.toNamed(AppRoutes.faceEnrollment);
              } else {
                controller.runEligibilityChecks();
              }
            },
          ),
        ],
      );
    });
  }

  Widget _buildErrorDiagnosticCard(AttendanceController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: UniSpacing.spaceMd),
      padding: const EdgeInsets.all(UniSpacing.spaceMd),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: UniSpacing.borderRadiusMd,
        border: Border.all(color: UniColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gpp_maybe, color: UniColors.error, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Không đủ điều kiện điểm danh',
                  style: UniTypography.titleSmall.copyWith(
                    color: UniColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            controller.diagnosticReason.value.isNotEmpty
                ? controller.diagnosticReason.value
                : 'Vui lòng kiểm tra lại thiết lập kết nối để tiếp tục điểm danh.',
            style: UniTypography.bodySmall.copyWith(
              color: UniColors.error,
            ),
          ),
          if (controller.diagnosticCode.value.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Mã lỗi: ${controller.diagnosticCode.value}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: UniColors.error.withValues(alpha: 0.8),
              ),
            ),
          ],
          const SizedBox(height: UniSpacing.spaceSm),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => controller.runEligibilityChecks(),
              style: ElevatedButton.styleFrom(
                backgroundColor: UniColors.error,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: UniSpacing.borderRadiusSm,
                ),
              ),
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Thử kết nối lại',
                  style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPanel(AttendanceController controller) {
    return Obx(() {
      final isAllPassed = controller.isAllPassed;
      final isEvaluating = controller.isEvaluating.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UniPrimaryButton(
            text: isAllPassed
                ? 'Tiếp tục quét khuôn mặt'
                : 'Xem kết quả đối soát',
            icon: isAllPassed
                ? Icons.arrow_forward_rounded
                : Icons.report_problem_outlined,
            isLoading: isEvaluating,
            onPressed: isEvaluating
                ? null
                : () {
                    if (isAllPassed) {
                      Get.toNamed(AppRoutes.checkIn);
                    } else {
                      Get.toNamed(AppRoutes.attendanceFailure);
                    }
                  },
          ),
          const SizedBox(height: 8),
          Text(
            'Hệ thống sẽ kích hoạt camera trước để nhận diện Face-ID trong 15 giây.',
            textAlign: TextAlign.center,
            style: UniTypography.caption.copyWith(
              color: UniColors.textSecondary,
            ),
          ),
          const SizedBox(height: UniSpacing.spaceSm),
          TextButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.cancel_outlined,
                size: 16, color: UniColors.textMuted),
            label: const Text(
              'Hủy phiên điểm danh',
              style: TextStyle(color: UniColors.textMuted, fontSize: 13),
            ),
          ),
        ],
      );
    });
  }
}
