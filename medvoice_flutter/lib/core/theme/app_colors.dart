import 'package:flutter/material.dart';

/// MedVoice Flutter color palette.
///
/// The Flutter app is the source of truth for the new dark clinical design
/// system: black surfaces, green primary actions, and high-contrast accents.
abstract final class AppColors {
  // Centralized Palette Hexes
  static const Color primaryBackground = Color(0xFF050B0A);
  static const Color secondaryBackground = Color(0xFF0D1413);
  static const Color surface = Color(0xFF121A19);
  static const Color primaryAccent = Color(0xFF22C55E);
  static const Color secondaryAccent = Color(0xFF16A34A);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA3A3A3);
  static const Color textMuted = Color(0xFF6B7280);

  // Marketing & Legacy Brand Aliases
  static const Color marketingPrimary = primaryAccent;
  static const Color marketingSecondary = Color(0xFF14B8A6);
  static const Color marketingAccent = Color(0xFFA3E635);
  static const Color marketingSurface = Color(0xFF0D1F17);

  // Auth and Primary Actions
  static const Color authPanelBlue = secondaryBackground;
  static const Color authBlue600 = primaryAccent;
  static const Color authBlue700 = secondaryAccent;
  static const Color authBlue200 = Color(0xFF86EFAC);
  static const Color authBlue100 = Color(0xFF0D2817);

  // Shared Brand Aliases
  static const Color primary = primaryAccent;
  static const Color primaryDark = Color(0xFF166534);
  static const Color primaryLight = Color(0xFF86EFAC);
  static const Color secondary = marketingSecondary;
  static const Color accent = marketingAccent;

  // Neutrals (Standardized around the design system background and surfaces)
  static const Color background = primaryBackground;
  static const Color surfaceVariant = secondaryBackground;
  static const Color elevatedSurface = Color(0xFF172221);
  static const Color border = Color(0xFF22332F);
  static const Color divider = Color(0xFF192523);

  // Text
  static const Color textMain = textPrimary;
  static const Color textLabel = textSecondary;
  static const Color textDisabled = textMuted;
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic detailed background & border
  static const Color successBg = Color(0xFF052E16);
  static const Color successBorder = Color(0xFF15803D);
  static const Color warningBg = Color(0xFF451A03);
  static const Color warningBorder = Color(0xFFB45309);
  static const Color errorBg = Color(0xFF450A0A);
  static const Color errorBorder = Color(0xFF991B1B);
  static const Color infoBg = Color(0xFF082F49);
  static const Color infoBorder = Color(0xFF0369A1);

  // Role accents
  static const Color patient = Color(0xFF22C55E);
  static const Color hospital = Color(0xFF14B8A6);
  static const Color authority = Color(0xFFA3E635);
  static const Color admin = Color(0xFFF59E0B);

  // Dark theme aliases
  static const Color darkBackground = background;
  static const Color darkSurface = surface;
  static const Color darkSurfaceVariant = surfaceVariant;
}
