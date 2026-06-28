import 'package:flutter/material.dart';

/// Centralized shadow decoration tokens for MedVoice.
abstract final class AppShadows {
  /// Subtle shadow for micro-components
  static final List<BoxShadow> subtle = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      offset: const Offset(0, 2),
      blurRadius: 6,
      spreadRadius: -1,
    ),
  ];

  /// Standard shadow for cards and dialogs
  static final List<BoxShadow> standard = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
  ];

  /// Highly elevated shadow for floating panels, dropdowns, and drawers
  static final List<BoxShadow> elevated = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.45),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];
}
