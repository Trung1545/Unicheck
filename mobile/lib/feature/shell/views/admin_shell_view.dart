import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import 'responsive_shell.dart';

class AdminShellView extends StatelessWidget {
  const AdminShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return ResponsiveShell(
      title: 'Quản Trị Hệ Thống (ADMIN)',
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
                      'Xin chào Quản trị viên, ${user?.fullName ?? "Admin"}!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tài khoản: ${user?.username ?? ""} | Email: ${user?.email ?? ""}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            const Text(
              'Chức năng quản trị viên',
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
                  _buildAdminCard(
                    icon: Icons.people_alt_outlined,
                    title: 'Quản Lý Người Dùng',
                    subtitle: 'Tạo tài khoản, phân quyền ADMIN / LECTURER / STUDENT',
                    color: const Color(0xFF6366F1),
                  ),
                  _buildAdminCard(
                    icon: Icons.analytics_outlined,
                    title: 'Giám Sát Ca Điểm Danh',
                    subtitle: 'Theo dõi tỷ lệ có mặt, cảnh báo vắng học theo thời gian thực',
                    color: const Color(0xFF06B6D4),
                  ),
                  _buildAdminCard(
                    icon: Icons.security_outlined,
                    title: 'Audit Log & Bảo Mật',
                    subtitle: 'Kiểm tra nhật ký truy cập và hoạt động hệ thống',
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

  Widget _buildAdminCard({
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
