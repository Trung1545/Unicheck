import 'package:flutter/material.dart';

/// UniCheck Mobile Design System - Spacing & Elevation Tokens
/// Based on Google Stitch 8-Point Grid (Screen: e5dc325d674f478ca6d5ac7c910898a6)
class UniSpacing {
  UniSpacing._();

  // 8-Point Grid Scale
  static const double space2xs = 2.0; // Micro tick
  static const double spaceXs = 4.0; // Micro spacing
  static const double spaceSm = 8.0; // Spacing nhỏ giữa các thành phần con
  static const double spaceMd = 16.0; // Standard Margin & Padding chuẩn lề
  static const double spaceLg = 24.0; // Gutter giữa các khối chức năng
  static const double spaceXl = 32.0; // Khoảng cách Section lớn
  static const double space2xl = 48.0; // Spacing đỉnh màn hình

  // Lề màn hình tiêu chuẩn
  static const double margin = 16.0;
  static const double screenMargin = 16.0;
  static const double screenGutter = 12.0;

  // Touch Target tối thiểu chuẩn HIG & Material 3 (44x44 dp)
  static const double minTouchTarget = 44.0;
  static const double minButtonHeight = 48.0;

  // Border Radii
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0; // Thẻ Card chuẩn
  static const double radiusXl = 24.0; // Modal / Viewport
  static const double radiusFull = 999.0; // Pill & Avatar tròn

  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);
  static BorderRadius get borderRadiusFull => BorderRadius.circular(radiusFull);

  // Shadows tinh tế theo Stitch
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: const Color(0xFF1D4ED8).withValues(alpha: 0.18),
          offset: const Offset(0, 2),
          blurRadius: 8,
        ),
      ];

  static List<BoxShadow> get dialogShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.12),
          offset: const Offset(0, 8),
          blurRadius: 28,
        ),
      ];
}
