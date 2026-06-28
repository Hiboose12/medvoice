import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/core/theme/app_colors.dart';
import 'package:medvoice_flutter/core/theme/app_typography.dart';

/// Material 3 theme for the MedVoice Flutter design system.
abstract final class AppTheme {
  static ThemeData get light => _buildTheme(Brightness.dark);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final colorScheme = isLight ? _lightColorScheme : _darkColorScheme;
    final textTheme = isLight
        ? AppTypography.textTheme
        : AppTypography.darkTextTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: GoogleFonts.publicSans().fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: textTheme.titleLarge,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
          return AppColors.authBlue600;
          }
          return null;
        }),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.authBlue600, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: textTheme.titleSmall,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textDisabled,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.authBlue600,
          foregroundColor: const Color(0xFF031008),
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.authBlue600,
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.authBlue600,
    onPrimary: AppColors.textOnPrimary,
    primaryContainer: AppColors.authBlue100,
    onPrimaryContainer: AppColors.authBlue700,
    secondary: AppColors.marketingSecondary,
    onSecondary: AppColors.textOnPrimary,
    secondaryContainer: AppColors.marketingSurface,
    onSecondaryContainer: AppColors.marketingSecondary,
    tertiary: AppColors.marketingAccent,
    onTertiary: AppColors.textOnPrimary,
    error: AppColors.error,
    onError: AppColors.textOnPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.border,
    outlineVariant: AppColors.divider,
    shadow: Color(0x1A000000),
    scrim: Color(0x66000000),
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.surface,
    inversePrimary: AppColors.authBlue600,
    surfaceTint: AppColors.authBlue600,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.authBlue600,
    onPrimary: Color(0xFF031008),
    primaryContainer: AppColors.authBlue100,
    onPrimaryContainer: AppColors.primaryLight,
    secondary: AppColors.secondary,
    onSecondary: Color(0xFF02110F),
    secondaryContainer: Color(0xFF06332F),
    onSecondaryContainer: Color(0xFF99F6E4),
    tertiary: AppColors.marketingAccent,
    onTertiary: Color(0xFF101500),
    error: AppColors.error,
    onError: Color(0xFF320711),
    surface: AppColors.darkSurface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.darkSurfaceVariant,
    outlineVariant: AppColors.border,
    shadow: Color(0x66000000),
    scrim: Color(0x99000000),
    inverseSurface: AppColors.surface,
    onInverseSurface: AppColors.textPrimary,
    inversePrimary: AppColors.authBlue600,
    surfaceTint: AppColors.primaryLight,
  );
}
