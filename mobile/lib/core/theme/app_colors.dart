import 'package:flutter/material.dart';

/// UniCheck Mobile Design System - Color Tokens
/// Based on Google Stitch Design Specification (Screen: e5dc325d674f478ca6d5ac7c910898a6)
class UniColors {
  UniColors._();

  // Brand & Primary
  static const Color primary =
      Color(0xFF1D4ED8); // Primary Blue - Nút chính & nhận diện
  static const Color primaryDark =
      Color(0xFF1E40AF); // Primary Dark - Active state & AppBar
  static const Color primaryContainer = Color(0xFF0037B0);
  static const Color primaryLight = Color(0xFFEFF4FF); // Nền nhấn sáng
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Biometric & Accent (Secondary)
  static const Color accent =
      Color(0xFF14B8A6); // Accent Teal - Sinh trắc & QR Success
  static const Color accentDark = Color(0xFF006B5F);
  static const Color accentContainer = Color(0xFF6DF5E1);
  static const Color accentLight = Color(0xFFECFDF5);
  static const Color onAccent = Color(0xFFFFFFFF);

  // Canvas & Background (Light Academic Precision)
  static const Color canvas = Color(0xFFF8FAFC); // Slate Canvas
  static const Color card = Color(0xFFFFFFFF); // Card & Dialog Surface
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFE6EEFF);
  static const Color surfaceContainerHighest = Color(0xFFD5E3FC);

  // Text & Content Hierarchy
  static const Color textPrimary =
      Color(0xFF0D1C2E); // onSurface - Tiêu đề & nội dung chính
  static const Color textSecondary =
      Color(0xFF434655); // onSurfaceVariant - Nhãn phụ & mô tả
  static const Color textMuted =
      Color(0xFF747686); // outline - Placeholder & ghi chú mờ
  static const Color onInverseSurface = Color(0xFFEAF1FF);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0); // Viền thẻ & phân cách
  static const Color divider = border;
  static const Color borderFocus = Color(0xFF1D4ED8); // Viền input khi focus
  static const Color borderError = Color(0xFFEF4444); // Viền input khi lỗi

  // Academic Semantic Status Colors
  // Có mặt (Present) - Emerald
  static const Color statusPresent = Color(0xFF10B981);
  static const Color statusPresentBg = Color(0xFFECFDF5);
  static const Color statusPresentText = Color(0xFF065F46);

  // Đi muộn (Late) - Amber
  static const Color statusLate = Color(0xFFF59E0B);
  static const Color statusLateBg = Color(0xFFFFFBEB);
  static const Color statusLateText = Color(0xFF92400E);

  // Vắng không phép / Nguy cơ cấm thi (Absent) - Rose
  static const Color statusAbsent = Color(0xFFEF4444);
  static const Color statusAbsentBg = Color(0xFFFEF2F2);
  static const Color statusAbsentText = Color(0xFF991B1B);

  // Vắng có phép / Đang đối soát (Excused) - Blue Info
  static const Color statusExcused = Color(0xFF3B82F6);
  static const Color statusExcusedBg = Color(0xFFEFF6FF);
  static const Color statusExcusedText = Color(0xFF1E40AF);

  // Cảnh báo chung (Warning)
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);

  // Lỗi hệ thống (Error)
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Shimmer & Overlay
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF1F5F9);
  static const Color overlayDark =
      Color(0x99000000); // 60% black cho camera darkening
  static const Color laserCyan = Color(0xFF71F8E4); // Tia laser quét sinh trắc

  // Stitch Semantic Aliases
  static const Color success = statusPresent;
  static const Color secondary = accent;
  static const Color secondaryLight = accentLight;
  static const Color secondaryFixed = laserCyan;
  static const Color secondaryFixedDim = accent;
  static const Color borderLight = Color(0xFFF1F5F9);
}
