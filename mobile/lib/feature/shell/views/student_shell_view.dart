import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import 'responsive_shell.dart';

class StudentShellView extends StatelessWidget {
  const StudentShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return ResponsiveShell(
      title: 'Sinh Viên (STUDENT)',
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
                      'Xin chào, ${user?.fullName ?? "Sinh viên"}!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'MSSV: ${user?.code ?? "N/A"} | Email: ${user?.email ?? ""}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            const Text(
              'Chức năng sinh viên',
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
                  _buildStudentCard(
                    icon: Icons.face_retouching_natural,
                    title: 'Đăng Ký Face-ID',
                    subtitle: 'Quét và đăng ký khuôn mẫu nhận diện khuôn mặt sinh trắc học',
                    color: const Color(0xFF3B82F6),
                    onTap: () => Get.toNamed('/face-enrollment'),
                  ),
                  _buildStudentCard(
                    icon: Icons.camera_front_outlined,
                    title: 'Điểm Danh Khuôn Mặt',
                    subtitle: 'Mở camera quét khuôn mặt và kiểm tra thực thể (Liveness)',
                    color: const Color(0xFF6366F1),
                    onTap: () => Get.toNamed('/check-in'),
                  ),
                  _buildStudentCard(
                    icon: Icons.schedule_outlined,
                    title: 'Lịch Học Cá Nhân',
                    subtitle: 'Xem thời khóa biểu các môn học và phòng học hôm nay',
                    color: const Color(0xFF06B6D4),
                    onTap: () {},
                  ),
                  _buildStudentCard(
                    icon: Icons.history_outlined,
                    title: 'Lịch Sử Điểm Danh',
                    subtitle: 'Xem trạng thái có mặt, vắng mặt hoặc đi trễ của các buổi học',
                    color: const Color(0xFF10B981),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
