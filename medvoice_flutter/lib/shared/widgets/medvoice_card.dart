import 'package:flutter/material.dart';
import 'package:medvoice_flutter/core/theme/app_colors.dart';
import 'package:medvoice_flutter/core/theme/app_radius.dart';
import 'package:medvoice_flutter/core/theme/app_spacing.dart';
import 'package:medvoice_flutter/core/theme/app_shadows.dart';

/// Centralized card container matching the dark clinical aesthetic.
class MedVoiceCard extends StatelessWidget {
  const MedVoiceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.backgroundColor = AppColors.surface,
    this.borderColor,
    this.hasShadow = false,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color backgroundColor;
  final Color? borderColor;
  final bool hasShadow;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(AppRadius.md);
    
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: effectiveBorderRadius,
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: 1.0,
        ),
        boxShadow: hasShadow ? AppShadows.standard : null,
      ),
      child: child,
    );
  }
}
