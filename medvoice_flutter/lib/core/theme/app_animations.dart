import 'package:flutter/material.dart';

/// Centralized animation durations and curves for MedVoice.
abstract final class AppAnimations {
  // Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // Curves
  static const Curve primary = Curves.easeInOut;
  static const Curve decelerate = Curves.easeOutCubic;
  static const Curve accent = Curves.elasticOut;
}
