import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unicheck_mobile/core/theme/app_colors.dart';
import 'package:unicheck_mobile/core/theme/app_spacing.dart';
import 'package:unicheck_mobile/core/theme/app_theme.dart';
import 'package:unicheck_mobile/shared/widgets/widgets.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  group('UniCheck Design Tokens & Theme Tests', () {
    test('UniColors matches Google Stitch specification', () {
      expect(UniColors.primary, const Color(0xFF1D4ED8));
      expect(UniColors.primaryDark, const Color(0xFF1E40AF));
      expect(UniColors.accent, const Color(0xFF14B8A6));
      expect(UniColors.canvas, const Color(0xFFF8FAFC));
      expect(UniColors.card, const Color(0xFFFFFFFF));
      expect(UniColors.border, const Color(0xFFE2E8F0));
      expect(UniColors.statusPresent, const Color(0xFF10B981));
      expect(UniColors.statusLate, const Color(0xFFF59E0B));
      expect(UniColors.statusAbsent, const Color(0xFFEF4444));
      expect(UniColors.statusExcused, const Color(0xFF3B82F6));
    });

    test('AppTheme.lightTheme has Material 3 enabled and valid ColorScheme',
        () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, UniColors.primary);
      expect(theme.scaffoldBackgroundColor, UniColors.canvas);
      expect(theme.cardTheme.color, UniColors.card);
      expect(theme.appBarTheme.backgroundColor, UniColors.card);
    });

    test('UniSpacing verifies 8-point grid and 44px min touch target', () {
      expect(UniSpacing.spaceSm, 8.0);
      expect(UniSpacing.spaceMd, 16.0);
      expect(UniSpacing.spaceLg, 24.0);
      expect(UniSpacing.spaceXl, 32.0);
      expect(UniSpacing.minTouchTarget, 44.0);
      expect(UniSpacing.minButtonHeight, 48.0);
    });
  });

  group('UniCheck Reusable Widgets Tests', () {
    testWidgets('UniPrimaryButton renders text and triggers callback',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: UniPrimaryButton(
              text: 'Đăng nhập',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Đăng nhập'), findsOneWidget);
      await tester.tap(find.byType(UniPrimaryButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets(
        'UniPrimaryButton displays spinner and disables tap when loading',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: UniPrimaryButton(
              text: 'Đăng nhập',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(UniPrimaryButton));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('AttendanceStatusBadge renders Vietnamese semantic labels',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Column(
              children: [
                AttendanceStatusBadge(status: AttendanceStatus.present),
                AttendanceStatusBadge(status: AttendanceStatus.late),
                AttendanceStatusBadge(status: AttendanceStatus.absent),
                AttendanceStatusBadge(status: AttendanceStatus.excused),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Có mặt đúng giờ'), findsOneWidget);
      expect(find.text('Đi muộn'), findsOneWidget);
      expect(find.text('Vắng không phép'), findsOneWidget);
      expect(find.text('Vắng có phép'), findsOneWidget);
    });

    testWidgets(
        'UniBottomNavBar renders 5 destinations and triggers tab selection',
        (tester) async {
      int selectedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: UniBottomNavBar(
              currentIndex: 0,
              onTap: (index) => selectedIndex = index,
            ),
          ),
        ),
      );

      expect(find.text('Tổng quan'), findsOneWidget);
      expect(find.text('Thời khóa'), findsOneWidget);
      expect(find.text('Điểm danh'), findsOneWidget);
      expect(find.text('Lớp học'), findsOneWidget);
      expect(find.text('Cá nhân'), findsOneWidget);

      await tester.tap(find.text('Thời khóa'));
      await tester.pump();
      expect(selectedIndex, 1);
    });

    testWidgets('VerificationCheckItem renders criteria and status',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: VerificationCheckItem(
              stepNumber: 1,
              title: 'Mã QR giảng đường hợp lệ',
              description: 'Mã QR động phòng A4-501',
              icon: Icons.qr_code_scanner,
              status: VerificationStatus.pass,
            ),
          ),
        ),
      );

      expect(find.text('1. Mã QR giảng đường hợp lệ'), findsOneWidget);
      expect(find.text('Mã QR động phòng A4-501'), findsOneWidget);
      expect(find.text('Đạt'), findsOneWidget);
    });

    testWidgets(
        'BiometricOvalOverlay renders without overflow on 360, 390, 430 widths',
        (tester) async {
      for (final width in [360.0, 390.0, 430.0]) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: BiometricOvalOverlay(
                instructionTitle: 'Nhìn thẳng chính diện vào camera',
                instructionSubtitle: 'Giữ khuôn mặt ổn định trong khung Oval',
                currentStep: 1,
                progress: 0.33,
              ),
            ),
          ),
        );

        expect(find.text('Nhìn thẳng chính diện vào camera'), findsOneWidget);
        expect(find.text('Nhìn thẳng'), findsOneWidget);
        expect(find.text('Nghiêng trái 15°'), findsOneWidget);
        expect(find.text('Nghiêng phải 15°'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });
}
