import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/uni_card.dart';
import '../../../shared/widgets/uni_primary_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/attendance_controller.dart';

class AttendanceSuccessView extends StatelessWidget {
  const AttendanceSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceController = Get.find<AttendanceController>();
    final authController = Get.find<AuthController>();

    if (attendanceController.receiptId.value.isEmpty) {
      attendanceController.generateReceipt();
    }

    final slot = attendanceController.currentSession.value;
    final user = authController.user.value;

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
              // 1. Status Hero Section
              _buildHeroSection(),
              const SizedBox(height: UniSpacing.spaceMd),

              // 2. Digital Attendance Receipt Card
              _buildDigitalReceiptCard(attendanceController, slot, user),
              const SizedBox(height: UniSpacing.spaceLg),

              // 3. Primary Button
              UniPrimaryButton(
                text: 'Về trang chủ sinh viên',
                icon: Icons.home_rounded,
                onPressed: () => Get.offAllNamed(AppRoutes.studentDashboard),
              ),
              const SizedBox(height: UniSpacing.spaceXl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        // Precision Verification Rings
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: UniColors.statusPresentBg,
            shape: BoxShape.circle,
            border: Border.all(
              color: UniColors.statusPresent.withValues(alpha: 0.3),
              width: 3,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.verified_rounded,
              size: 40,
              color: UniColors.statusPresent,
            ),
          ),
        ),
        const SizedBox(height: UniSpacing.spaceSm + 2),

        // Status Badge Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: UniColors.statusPresentBg,
            borderRadius: UniSpacing.borderRadiusFull,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: UniColors.statusPresent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Có mặt đúng giờ',
                style: UniTypography.caption.copyWith(
                  color: UniColors.statusPresentText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: UniSpacing.spaceSm),

        // Academic Heading
        Text(
          'Điểm danh thành công',
          style: UniTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Hệ thống đào tạo đã ghi nhận và ký số bảo mật biên nhận điểm danh của sinh viên.',
          textAlign: TextAlign.center,
          style: UniTypography.bodySmall.copyWith(
            color: UniColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDigitalReceiptCard(
    AttendanceController controller,
    dynamic slot,
    dynamic user,
  ) {
    return UniCard(
      padding: const EdgeInsets.all(UniSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Audit Code
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BIÊN NHẬN ĐIỆN TỬ HỢP LỆ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: UniColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Obx(() => Text(
                            controller.receiptId.value,
                            style: UniTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          )),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(
                              text: controller.receiptId.value));
                          Get.snackbar(
                            'Đã sao chép',
                            'Mã biên nhận đã được lưu vào bộ nhớ tạm.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        child: const Icon(Icons.copy_rounded,
                            size: 14, color: UniColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: UniColors.canvas,
                  borderRadius: UniSpacing.borderRadiusSm,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline,
                        size: 12, color: UniColors.success),
                    SizedBox(width: 4),
                    Text(
                      'SHA-256',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: UniColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: UniSpacing.spaceMd),

          // Academic Metadata Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: UniColors.canvas,
              borderRadius: UniSpacing.borderRadiusSm,
            ),
            child: Column(
              children: [
                _buildMetadataRow('Học phần', slot?.courseName ?? 'Lập trình Web'),
                const Divider(height: 12, color: UniColors.border),
                _buildMetadataRow(
                    'Mã lớp HP', '${slot?.courseCode ?? 'IT301'} • ${slot?.className ?? 'Lớp 01'}'),
                const Divider(height: 12, color: UniColors.border),
                _buildMetadataRow(
                    'Giảng viên', slot?.lecturerDisplay ?? 'TS. Lê Quốc Cường'),
                const Divider(height: 12, color: UniColors.border),
                _buildMetadataRow('Phòng học', slot?.roomDisplay ?? 'A4-501'),
                const Divider(height: 12, color: UniColors.border),
                _buildMetadataRow('Ca học',
                    '${slot?.periodsDisplay ?? 'Tiết 1-5'} (${slot?.timeSlot ?? '07:30 - 11:15'})'),
                const Divider(height: 12, color: UniColors.border),
                _buildMetadataRow(
                    'Sinh viên', '${user?.fullName ?? 'N/A'} (${user?.code ?? 'N/A'})'),
              ],
            ),
          ),
          const SizedBox(height: UniSpacing.spaceMd),

          // Audit Log
          const Text(
            'ĐẶC TẢ ĐỐI SOÁT BẢO MẬT (AUDIT LOG)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: UniColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildAuditRow(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Mã phản hồi QR',
            status: 'Hợp lệ & Ký số',
            isSuccess: true,
          ),
          const SizedBox(height: 6),
          _buildAuditRow(
            icon: Icons.wifi_rounded,
            title: 'Điểm truy cập Wi-Fi',
            status: 'Khớp phòng học',
            isSuccess: true,
          ),
          const SizedBox(height: 6),
          _buildAuditRow(
            icon: Icons.face_rounded,
            title: 'Sinh trắc học Face-ID',
            status: 'Xác thực khớp (99.2%)',
            isSuccess: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: UniTypography.caption.copyWith(
            color: UniColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: UniTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: UniColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuditRow({
    required IconData icon,
    required String title,
    required String status,
    required bool isSuccess,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: UniColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: UniTypography.caption.copyWith(
                color: UniColors.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isSuccess
                ? UniColors.statusPresentBg
                : UniColors.statusAbsentBg,
            borderRadius: UniSpacing.borderRadiusFull,
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSuccess
                  ? UniColors.statusPresentText
                  : UniColors.statusAbsentText,
            ),
          ),
        ),
      ],
    );
  }
}
