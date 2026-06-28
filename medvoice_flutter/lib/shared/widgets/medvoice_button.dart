import 'package:flutter/material.dart';
import 'package:medvoice_flutter/core/theme/app_colors.dart';
import 'package:medvoice_flutter/core/theme/app_radius.dart';
import 'package:medvoice_flutter/core/theme/app_spacing.dart';
import 'package:medvoice_flutter/core/theme/app_animations.dart';

enum MedVoiceButtonVariant { primary, secondary, outlined, text, danger }

/// Centralized premium action button for MedVoice clinical design system.
class MedVoiceButton extends StatelessWidget {
  const MedVoiceButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MedVoiceButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final MedVoiceButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Dynamic color settings
    final Color buttonColor;
    final Color textColor;
    final BorderSide borderSide;

    switch (variant) {
      case MedVoiceButtonVariant.primary:
        buttonColor = AppColors.primary;
        textColor = const Color(0xFF031008); // high contrast text on green
        borderSide = BorderSide.none;
        break;
      case MedVoiceButtonVariant.secondary:
        buttonColor = AppColors.secondaryAccent;
        textColor = Colors.white;
        borderSide = BorderSide.none;
        break;
      case MedVoiceButtonVariant.outlined:
        buttonColor = Colors.transparent;
        textColor = AppColors.primary;
        borderSide = const BorderSide(color: AppColors.primary, width: 1.5);
        break;
      case MedVoiceButtonVariant.text:
        buttonColor = Colors.transparent;
        textColor = AppColors.textSecondary;
        borderSide = BorderSide.none;
        break;
      case MedVoiceButtonVariant.danger:
        buttonColor = AppColors.error;
        textColor = Colors.white;
        borderSide = BorderSide.none;
        break;
    }

    final effectiveOnPressed = (isLoading || onPressed == null) ? null : onPressed;

    Widget child = AnimatedSwitcher(
      duration: AppAnimations.fast,
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            )
          : Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: textColor),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: effectiveOnPressed == null ? textColor.withValues(alpha: 0.5) : textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );

    Widget button;
    if (variant == MedVoiceButtonVariant.text) {
      button = TextButton(
        onPressed: effectiveOnPressed,
        style: TextButton.styleFrom(
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: child,
      );
    } else {
      button = AnimatedContainer(
        duration: AppAnimations.fast,
        decoration: BoxDecoration(
          color: effectiveOnPressed == null ? buttonColor.withValues(alpha: 0.2) : buttonColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: borderSide == BorderSide.none
              ? null
              : Border.all(color: borderSide.color, width: borderSide.width),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: effectiveOnPressed,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      );
    }

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
