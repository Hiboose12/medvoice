import 'package:flutter/material.dart';
import 'package:medvoice_flutter/core/theme/app_colors.dart';

/// Patient module palette from the Flutter MedVoice design system.
abstract final class PatientColors {
  static const Color primary = AppColors.primaryAccent;
  static const Color textMain = AppColors.textPrimary;
  static const Color textMuted = AppColors.textSecondary;
  static const Color bgLight = AppColors.primaryBackground;
  static const Color medicalTeal = AppColors.marketingSecondary;
  static const Color medicalOrange = AppColors.warning;
  static const Color medicalRed = AppColors.error;
  static const Color border = AppColors.border;
  static const Color cardBorder = AppColors.divider;
  static const Color card = AppColors.secondaryBackground;
  static const Color cardElevated = AppColors.surface;
}
