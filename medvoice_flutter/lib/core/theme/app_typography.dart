import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/core/theme/app_colors.dart';

/// Typography matching Django templates (Public Sans + Manrope).
abstract final class AppTypography {
  static TextStyle get _publicSans => GoogleFonts.publicSans();
  static TextStyle get _manrope => GoogleFonts.manrope();

  static TextTheme get textTheme => TextTheme(
        displayLarge: _manrope.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
        displayMedium: _manrope.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.25,
        ),
        displaySmall: _manrope.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        headlineLarge: _manrope.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.2,
          letterSpacing: -0.5,
        ),
        headlineMedium: _manrope.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        headlineSmall: _manrope.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.35,
        ),
        titleLarge: _manrope.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: _publicSans.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleSmall: _publicSans.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textLabel,
        ),
        bodyLarge: _publicSans.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        bodyMedium: _publicSans.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodySmall: _publicSans.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.45,
        ),
        labelLarge: _publicSans.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.textOnPrimary,
        ),
        labelMedium: _publicSans.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        labelSmall: _publicSans.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.textSecondary,
        ),
      );

  static TextTheme get darkTextTheme => textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      );
}
