import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// UniCheck Standard Mobile Bottom Navigation Bar
/// Based on Google Stitch Role 1 Student Navigation Spec (Screen: e5dc325d674f478ca6d5ac7c910898a6)
class UniBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onScanQrTap;

  const UniBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onScanQrTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UniColors.card,
        border: const Border(
          top: BorderSide(color: UniColors.border, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Tab 0: Tổng quan
              _buildNavItem(
                index: 0,
                label: 'Tổng quan',
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
              ),

              // Tab 1: Thời khóa
              _buildNavItem(
                index: 1,
                label: 'Thời khóa',
                icon: Icons.calendar_month_outlined,
                activeIcon: Icons.calendar_month_rounded,
              ),

              // Tab 2: Prominent Center QR Scanner FAB
              _buildCenterScanButton(),

              // Tab 3: Lớp học
              _buildNavItem(
                index: 3,
                label: 'Lớp học',
                icon: Icons.school_outlined,
                activeIcon: Icons.school_rounded,
              ),

              // Tab 4: Cá nhân
              _buildNavItem(
                index: 4,
                label: 'Cá nhân',
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? UniColors.primary : UniColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: UniColors.primaryLight,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: UniTypography.labelSmall.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterScanButton() {
    return Expanded(
      child: InkWell(
        onTap: onScanQrTap ?? () => onTap(2),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    UniColors.primary,
                    UniColors.primaryContainer,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: UniColors.primary.withValues(alpha: 0.35),
                    offset: const Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Điểm danh',
              style: UniTypography.labelSmall.copyWith(
                color: currentIndex == 2
                    ? UniColors.primary
                    : UniColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
