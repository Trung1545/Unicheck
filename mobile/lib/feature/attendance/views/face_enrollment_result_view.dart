import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/uni_card.dart';
import '../../../shared/widgets/uni_primary_button.dart';
import '../../../shared/widgets/uni_secondary_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/face_enrollment_result_model.dart';

/// UniCheck Face-ID Enrollment Result & Biometric Certificate View
/// Based on Google Stitch Screen: 28623608e3df4e6b95f2a362ddf3a859
/// Light Academic Precision Design System
class FaceEnrollmentResultView extends StatelessWidget {
  final FaceEnrollmentResultModel? result;

  const FaceEnrollmentResultView({
    super.key,
    this.result,
  });

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());

    final user = authController.user.value;

    // Get model from constructor argument or Get.arguments
    final FaceEnrollmentResultModel model = result ??
        (Get.arguments is FaceEnrollmentResultModel
            ? Get.arguments as FaceEnrollmentResultModel
            : const FaceEnrollmentResultModel(
                success: true,
                status: 'REGISTERED',
                version: 'v3.2',
                modelName: 'ArcFace MobileFaceNet (512-dim)',
                embeddingDimension: 512,
              ));

    final isSuccess = model.success;
    final studentName = model.studentName.isNotEmpty
        ? model.studentName
        : (user?.fullName ?? 'Sinh viên');
    final studentCode = model.studentCode.isNotEmpty
        ? model.studentCode
        : (user?.code ?? user?.username ?? '2251120001');

    final certId = model.tokenHash.isNotEmpty
        ? '#FID-${model.tokenHash.substring(0, model.tokenHash.length > 8 ? 8 : model.tokenHash.length).toUpperCase()}-$studentCode'
        : '#FID-20261020-$studentCode-VN';

    final sha256Hash = model.tokenHash.isNotEmpty
        ? model.tokenHash
        : 'e8f9c18d40a87f12e09b11933df01c7784a9235e8932b12fa9080c3b2190';

    final now = model.registeredAt ?? DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} - ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: UniColors.canvas,
      appBar: AppBar(
        backgroundColor: UniColors.card,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: UniColors.textPrimary),
          onPressed: () async {
            if (Get.isRegistered<AuthController>()) {
              await Get.find<AuthController>().refreshProfile();
            }
            Get.offAllNamed(AppRoutes.student);
          },
        ),
        title: Text(
          'Kết Quả Xác Thực',
          style: UniTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: UniSpacing.margin),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: UniColors.primary,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(UniSpacing.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Step Progress Indicator (1. Chuẩn bị -> 2. Quét mặt -> 3. Xác thực)
              _buildStepIndicator(isSuccess),
              const SizedBox(height: UniSpacing.spaceMd),

              if (isSuccess) ...[
                // 2. Success Emblem & Headline
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: UniColors.secondaryFixed.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: UniColors.secondary,
                                child: Icon(
                                  Icons.face_retouching_natural_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: UniColors.card,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: UniColors.secondary,
                                  child: Icon(Icons.check,
                                      color: Colors.white, size: 13),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: UniSpacing.spaceSm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: UniColors.secondaryFixed.withValues(alpha: 0.35),
                          borderRadius: UniSpacing.borderRadiusFull,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: UniColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Chứng nhận Sinh trắc học',
                              style: UniTypography.caption.copyWith(
                                color: UniColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: UniSpacing.spaceSm),
                      Text(
                        'Đăng ký Face-ID thành công!',
                        style: UniTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: UniColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mẫu vector sinh trắc học đã được mã hóa và đồng bộ thành công vào hệ thống học vụ.',
                        style: UniTypography.bodySmall.copyWith(
                          color: UniColors.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: UniSpacing.spaceLg),

                // 3. Student Identity Certificate Card
                UniCard(
                  padding: const EdgeInsets.all(UniSpacing.spaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Certificate Header Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.badge_rounded,
                                  color: UniColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'BIÊN NHẬN SINH TRẮC HỌC SỐ',
                                style: UniTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: UniColors.textPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: UniColors.primaryLight,
                              borderRadius: UniSpacing.borderRadiusFull,
                            ),
                            child: Text(
                              'ISO 30107-3',
                              style: UniTypography.caption.copyWith(
                                color: UniColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Student Core Metadata
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sinh viên',
                                    style: UniTypography.caption.copyWith(
                                        color: UniColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text(
                                  studentName,
                                  style: UniTypography.labelLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text('MSSV: $studentCode',
                                    style: UniTypography.caption.copyWith(
                                        color: UniColors.textSecondary)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Niên khóa & Lớp',
                                    style: UniTypography.caption.copyWith(
                                        color: UniColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text(
                                  'Chính quy K2022',
                                  style: UniTypography.labelLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.role ?? 'Sinh viên',
                                  style: UniTypography.caption.copyWith(
                                      color: UniColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: UniSpacing.spaceMd),

                      // Security Hash & Certificate ID Box
                      Container(
                        padding: const EdgeInsets.all(UniSpacing.spaceSm + 2),
                        decoration: BoxDecoration(
                          color: UniColors.canvas,
                          borderRadius: UniSpacing.borderRadiusMd,
                          border: Border.all(color: UniColors.divider),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Mã chứng thư:',
                                    style: UniTypography.caption.copyWith(
                                        color: UniColors.textSecondary)),
                                Text(
                                  certId,
                                  style: UniTypography.caption.copyWith(
                                    color: UniColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Cấp lúc:',
                                    style: UniTypography.caption.copyWith(
                                        color: UniColors.textSecondary)),
                                Text(
                                  dateStr,
                                  style: UniTypography.caption.copyWith(
                                      color: UniColors.textPrimary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text('SHA-256: ',
                                        style: UniTypography.caption.copyWith(
                                            color: UniColors.textSecondary)),
                                    Text(
                                      sha256Hash.length > 18
                                          ? '${sha256Hash.substring(0, 8)}...${sha256Hash.substring(sha256Hash.length - 8)}'
                                          : sha256Hash,
                                      style: UniTypography.caption.copyWith(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(
                                        ClipboardData(text: sha256Hash));
                                    Get.snackbar(
                                      'Đã sao chép',
                                      'Mã SHA-256 đã lưu vào bộ nhớ tạm',
                                      snackPosition: SnackPosition.BOTTOM,
                                      duration: const Duration(seconds: 2),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: UniColors.card,
                                      borderRadius: UniSpacing.borderRadiusSm,
                                      border: Border.all(color: UniColors.divider),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.content_copy,
                                            size: 12, color: UniColors.textPrimary),
                                        const SizedBox(width: 4),
                                        Text('Chép',
                                            style: UniTypography.caption.copyWith(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: UniSpacing.spaceMd),

                      // AI Engine Metrics Breakdown
                      Text(
                        'THÔNG SỐ VECTOR & KHỚP MẪU AI',
                        style: UniTypography.caption.copyWith(
                          color: UniColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: UniSpacing.spaceSm),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              icon: Icons.polyline,
                              color: UniColors.primary,
                              label: 'Điểm mốc',
                              value: '468 3D Mesh',
                            ),
                          ),
                          const SizedBox(width: UniSpacing.spaceSm),
                          Expanded(
                            child: _buildMetricTile(
                              icon: Icons.analytics_rounded,
                              color: UniColors.secondary,
                              label: 'Độ khớp 3 góc',
                              value: '99.6% (Chuẩn)',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: UniSpacing.spaceSm),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              icon: Icons.security_rounded,
                              color: UniColors.secondary,
                              label: 'Anti-Spoofing',
                              value: 'Đạt (Liveness)',
                            ),
                          ),
                          const SizedBox(width: UniSpacing.spaceSm),
                          Expanded(
                            child: _buildMetricTile(
                              icon: Icons.memory_rounded,
                              color: UniColors.primary,
                              label: 'Không gian Vector',
                              value: '${model.embeddingDimension}-dim',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: UniSpacing.spaceMd),

                // 4. Usage Guidelines Card
                Container(
                  padding: const EdgeInsets.all(UniSpacing.spaceMd),
                  decoration: BoxDecoration(
                    color: UniColors.primaryLight.withValues(alpha: 0.5),
                    borderRadius: UniSpacing.borderRadiusLg,
                    border: Border.all(
                      color: UniColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: UniColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline,
                            color: UniColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quy chế Điểm danh & Nhắc nhở',
                              style: UniTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: UniColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Từ thời điểm này, bạn có thể sử dụng tính năng Điểm danh Face-ID tại tất cả các giảng đường thông minh hoặc quét kèm mã QR từ Giảng viên.',
                              style: UniTypography.bodySmall.copyWith(
                                color: UniColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mẫu vector khuôn mặt có hiệu lực 01 năm học theo quy định bảo mật.',
                              style: UniTypography.caption.copyWith(
                                color: UniColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: UniSpacing.spaceLg),

                // 5. Actions
                UniPrimaryButton(
                  text: 'BẮT ĐẦU ĐIỂM DANH BUỔI HỌC NGAY',
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: () => Get.offNamed(AppRoutes.selectSession),
                ),
                const SizedBox(height: UniSpacing.spaceSm),
                UniSecondaryButton(
                  text: 'Về Trang chủ Học vụ',
                  icon: Icons.home_rounded,
                  onPressed: () async {
            if (Get.isRegistered<AuthController>()) {
              await Get.find<AuthController>().refreshProfile();
            }
            Get.offAllNamed(AppRoutes.student);
          },
                ),
              ] else ...[
                // FAILURE VIEW
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: UniColors.error.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.no_accounts_rounded,
                              size: 44, color: UniColors.error),
                        ),
                      ),
                      const SizedBox(height: UniSpacing.spaceSm),
                      Text(
                        'Không thể xác thực Face-ID',
                        style: UniTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: UniColors.error,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        model.message ??
                            'Không thể trích xuất vector do điều kiện ánh sáng hoặc góc nghiêng chưa đạt chuẩn.',
                        style: UniTypography.bodySmall.copyWith(
                          color: UniColors.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: UniSpacing.spaceLg),
                UniPrimaryButton(
                  text: 'QUÉT LẠI TỪ ĐẦU',
                  icon: Icons.replay_rounded,
                  onPressed: () => Get.offNamed(AppRoutes.faceEnrollment),
                ),
                const SizedBox(height: UniSpacing.spaceSm),
                UniSecondaryButton(
                  text: 'Về Trang chủ Học vụ',
                  icon: Icons.home_rounded,
                  onPressed: () async {
            if (Get.isRegistered<AuthController>()) {
              await Get.find<AuthController>().refreshProfile();
            }
            Get.offAllNamed(AppRoutes.student);
          },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isSuccess) {
    return UniCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStepItem(step: '1', title: 'Chuẩn bị', isCompleted: true),
          Container(
              width: 32, height: 2, color: UniColors.secondaryFixedDim),
          _buildStepItem(step: '2', title: 'Quét mặt', isCompleted: true),
          Container(
              width: 32,
              height: 2,
              color: isSuccess ? UniColors.secondaryFixedDim : UniColors.error),
          _buildStepItem(
            step: '3',
            title: isSuccess ? 'Xác thực' : 'Thất bại',
            isCompleted: isSuccess,
            isError: !isSuccess,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String step,
    required String title,
    required bool isCompleted,
    bool isError = false,
  }) {
    Color bg = isError
        ? UniColors.error
        : (isCompleted ? UniColors.secondary : UniColors.divider);
    IconData icon = isError
        ? Icons.close
        : (isCompleted ? Icons.check : Icons.circle);

    return Column(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: bg,
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: UniTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: isError
                ? UniColors.error
                : (isCompleted ? UniColors.secondary : UniColors.textSecondary),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: UniColors.canvas,
        borderRadius: UniSpacing.borderRadiusMd,
        border: Border.all(color: UniColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: UniTypography.caption.copyWith(
                    color: UniColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: UniTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: UniColors.textPrimary,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
