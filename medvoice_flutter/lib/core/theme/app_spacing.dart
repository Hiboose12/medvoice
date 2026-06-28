import 'package:flutter/material.dart';

/// Centralized spacing tokens for MedVoice.
abstract final class AppSpacing {
  /// 4.0
  static const double xxs = 4.0;

  /// 8.0
  static const double xs = 8.0;

  /// 12.0
  static const double sm = 12.0;

  /// 16.0
  static const double md = 16.0;

  /// 24.0
  static const double lg = 24.0;

  /// 32.0
  static const double xl = 32.0;

  /// 48.0
  static const double xxl = 48.0;

  // Edge Insets convenience builders
  static const EdgeInsets allXXS = EdgeInsets.all(xxs);
  static const EdgeInsets allXS = EdgeInsets.all(xs);
  static const EdgeInsets allSM = EdgeInsets.all(sm);
  static const EdgeInsets allMD = EdgeInsets.all(md);
  static const EdgeInsets allLG = EdgeInsets.all(lg);
  static const EdgeInsets allXL = EdgeInsets.all(xl);

  static const EdgeInsets symHXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets symHSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets symHMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets symHLg = EdgeInsets.symmetric(horizontal: lg);

  static const EdgeInsets symVXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets symVSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets symVMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets symVLg = EdgeInsets.symmetric(vertical: lg);
}
