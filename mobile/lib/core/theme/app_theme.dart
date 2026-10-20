import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// UniCheck Mobile Theme System
/// Standardizes Light Academic Precision Theme (Material 3) according to Google Stitch
class AppTheme {
  AppTheme._();

  // Backward compatibility alias
  static const Color primaryColor = UniColors.primary;
  static const Color secondaryColor = UniColors.accent;
  static const Color darkBackground = UniColors.canvas;
  static const Color cardBackground = UniColors.card;

  /// Default Theme: Light Academic Precision
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: UniColors.primary,
      onPrimary: UniColors.onPrimary,
      primaryContainer: UniColors.primaryLight,
      onPrimaryContainer: UniColors.primaryDark,
      secondary: UniColors.accent,
      onSecondary: UniColors.onAccent,
      secondaryContainer: UniColors.accentLight,
      onSecondaryContainer: UniColors.accentDark,
      surface: UniColors.card,
      onSurface: UniColors.textPrimary,
      surfaceContainerLowest: UniColors.card,
      surfaceContainerLow: UniColors.surfaceContainerLow,
      surfaceContainer: UniColors.canvas,
      surfaceContainerHigh: UniColors.surfaceContainerHigh,
      surfaceContainerHighest: UniColors.surfaceContainerHighest,
      onSurfaceVariant: UniColors.textSecondary,
      outline: UniColors.border,
      outlineVariant: UniColors.border,
      error: UniColors.error,
      onError: UniColors.onError,
      errorContainer: UniColors.errorContainer,
      onErrorContainer: UniColors.onErrorContainer,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: UniColors.primary,
      scaffoldBackgroundColor: UniColors.canvas,
      colorScheme: colorScheme,
      textTheme: UniTypography.textTheme,

      // 1. AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: UniColors.card,
        foregroundColor: UniColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: UniTypography.headlineSmall,
        iconTheme: const IconThemeData(
          color: UniColors.textPrimary,
          size: 22,
        ),
      ),

      // 2. Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: UniColors.primary,
          foregroundColor: UniColors.onPrimary,
          disabledBackgroundColor: UniColors.primary.withValues(alpha: 0.4),
          disabledForegroundColor: UniColors.onPrimary.withValues(alpha: 0.7),
          elevation: 0,
          minimumSize: const Size(double.infinity, UniSpacing.minButtonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: UniSpacing.borderRadiusMd,
          ),
          textStyle: UniTypography.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: UniColors.primary,
          backgroundColor: UniColors.card,
          disabledForegroundColor: UniColors.textMuted,
          minimumSize: const Size(double.infinity, UniSpacing.minButtonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: UniColors.border, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: UniSpacing.borderRadiusMd,
          ),
          textStyle: UniTypography.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: UniColors.primary,
          minimumSize:
              const Size(UniSpacing.minTouchTarget, UniSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: UniSpacing.borderRadiusSm,
          ),
          textStyle: UniTypography.labelLarge,
        ),
      ),

      // 3. Input & Text Field Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: UniColors.canvas,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle:
            UniTypography.bodyMedium.copyWith(color: UniColors.textMuted),
        labelStyle:
            UniTypography.bodyMedium.copyWith(color: UniColors.textSecondary),
        helperStyle: UniTypography.caption,
        errorStyle: UniTypography.caption.copyWith(color: UniColors.error),
        prefixIconColor: UniColors.textSecondary,
        suffixIconColor: UniColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: UniSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: UniColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: UniSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: UniColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: UniSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: UniColors.borderFocus, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: UniSpacing.borderRadiusMd,
          borderSide:
              const BorderSide(color: UniColors.borderError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: UniSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: UniColors.borderError, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: UniSpacing.borderRadiusMd,
          borderSide: BorderSide(
              color: UniColors.border.withValues(alpha: 0.5), width: 1),
        ),
      ),

      // 4. Card Theme
      cardTheme: CardThemeData(
        color: UniColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: UniSpacing.borderRadiusLg,
          side: const BorderSide(color: UniColors.border, width: 1),
        ),
      ),

      // 5. Navigation Bar & Bottom Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: UniColors.card,
        selectedItemColor: UniColors.primary,
        unselectedItemColor: UniColors.textMuted,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: UniColors.card,
        indicatorColor: UniColors.primaryLight,
        elevation: 2,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return UniTypography.labelSmall.copyWith(
              color: UniColors.primary,
              fontWeight: FontWeight.w700,
            );
          }
          return UniTypography.labelSmall.copyWith(
            color: UniColors.textMuted,
          );
        }),
      ),

      // 6. Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: UniColors.card,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: UniSpacing.borderRadiusXl,
          side: const BorderSide(color: UniColors.border, width: 1),
        ),
        titleTextStyle: UniTypography.headlineSmall,
        contentTextStyle: UniTypography.bodyMedium,
      ),

      // 7. Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: UniColors.card,
        elevation: 16,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(UniSpacing.radiusXl)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      ),

      // 8. SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle:
            UniTypography.bodyMedium.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: UniSpacing.borderRadiusMd,
        ),
        elevation: 4,
      ),

      // 9. Divider Theme
      dividerTheme: const DividerThemeData(
        color: UniColors.border,
        thickness: 1,
        space: 1,
      ),

      // 10. Checkbox & Switch Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return UniColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: const BorderSide(color: UniColors.border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // 11. Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: UniColors.surfaceContainerLow,
        disabledColor: UniColors.canvas,
        selectedColor: UniColors.primaryLight,
        labelStyle: UniTypography.labelSmall.copyWith(color: UniColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: UniSpacing.borderRadiusFull,
          side: BorderSide.none,
        ),
      ),

      // 12. Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: UniColors.primary,
        linearTrackColor: UniColors.surfaceContainerHigh,
        circularTrackColor: UniColors.surfaceContainerHigh,
      ),
    );
  }

  /// Dark Theme (Maintained for backward compatibility or future dark mode toggle)
  static ThemeData get darkTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: const Color(0xFF0B0F19),
      primaryColor: UniColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: UniColors.primary,
        secondary: UniColors.accent,
        surface: Color(0xFF1E293B),
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B0F19),
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
