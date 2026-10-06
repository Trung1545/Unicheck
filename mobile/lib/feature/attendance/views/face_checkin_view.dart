import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';

class FaceCheckinView extends StatelessWidget {
  FaceCheckinView({Key? key}) : super(key: key);

  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm Danh Khuôn Mặt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Camera preview simulator placeholder
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF6366F1), width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 64,
                            color: Colors.white54,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Đặt khuôn mặt trong khung hình\nKiểm tra chớp mắt / quay đầu (Liveness)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                      // Face oval outline
                      Container(
                        width: 220,
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF06B6D4), width: 2),
                          borderRadius: const BorderRadius.all(Radius.elliptical(110, 150)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Student Info Banner
              Obx(() {
                final user = authController.user.value;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF6366F1),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Sinh viên',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              'MSSV: ${user?.username ?? "N/A"}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Chip(
                        label: Text('Phòng A201', style: TextStyle(fontSize: 11)),
                        backgroundColor: Color(0xFF312E81),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Get.snackbar(
                    'Điểm danh thành công',
                    'Độ khớp khuôn mặt: 99.2% - Liveness: Hợp lệ',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFF065F46),
                    colorText: Colors.white,
                  );
                },
                icon: const Icon(Icons.verified_user),
                label: const Text('XÁC NHẬN ĐIỂM DANH SINH TRẮC HỌC'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
