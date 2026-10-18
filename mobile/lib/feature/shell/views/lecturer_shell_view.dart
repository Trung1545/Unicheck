import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import 'responsive_shell.dart';

class LecturerShellView extends StatelessWidget {
  const LecturerShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return ResponsiveShell(
      title: 'Giảng Viên (LECTURER)',
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              final user = authController.user.value;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào Giảng viên, ${user?.fullName ?? "Thầy/Cô"}!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mã GV: ${user?.code ?? "N/A"} | Email: ${user?.email ?? ""}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            const Text(
              'Quản lý giảng dạy & điểm danh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width >= 1024
                    ? 3
                    : (MediaQuery.of(context).size.width >= 640 ? 2 : 1),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: MediaQuery.of(context).size.width >= 1024
                    ? 1.6
                    : (MediaQuery.of(context).size.width >= 640 ? 2.2 : 2.8),
                children: [
                  _buildLecturerCard(
                    icon: Icons.calendar_today_outlined,
                    title: 'Lịch Giảng Dạy',
                    subtitle: 'Xem thời khóa biểu các lớp học phần trong tuần',
                    color: const Color(0xFF6366F1),
                  ),
                  _buildLecturerCard(
                    icon: Icons.qr_code_scanner_outlined,
                    title: 'Mở Ca Điểm Danh',
                    subtitle: 'Kích hoạt ca điểm danh sinh trắc học và Wi-Fi phòng học',
                    color: const Color(0xFFF59E0B),
                  ),
                  _buildLecturerCard(
                    icon: Icons.fact_check_outlined,
                    title: 'Báo Cáo Điểm Danh Lớp',
                    subtitle: 'Xem danh sách sinh viên có mặt / vắng mặt và duyệt lý do',
                    color: const Color(0xFF10B981),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLecturerCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
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
