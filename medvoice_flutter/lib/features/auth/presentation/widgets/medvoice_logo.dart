import 'package:flutter/material.dart';
import 'package:medvoice_flutter/core/theme/app_colors.dart';
import 'package:medvoice_flutter/core/theme/app_typography.dart';

/// Matches `templates/includes/medvoice_logo.html`.
class MedVoiceLogo extends StatelessWidget {
  const MedVoiceLogo({
    super.key,
    this.iconColor = AppColors.marketingPrimary,
    this.textColor = AppColors.textPrimary,
    this.showTagline = false,
    this.compact = false,
  });

  final Color iconColor;
  final Color textColor;
  final bool showTagline;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 28.0 : 32.0;
    final fontSize = compact ? 18.0 : 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: CustomPaint(
                painter: _MedVoiceIconPainter(color: iconColor),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'MedVoice',
              style: AppTypography.textTheme.titleLarge?.copyWith(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: iconSize + 12),
            child: Text(
              'MEDICAL TRANSPARENCY',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.marketingSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MedVoiceIconPainter extends CustomPainter {
  _MedVoiceIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48;
    final paint = Paint()..color = color;

    final path = Path()
      ..moveTo(36.7273 * scale, 44 * scale)
      ..cubicTo(
        33.9891 * scale, 44 * scale,
        31.6043 * scale, 39.8386 * scale,
        30.3636 * scale, 33.69 * scale,
      )
      ..cubicTo(
        29.123 * scale, 39.8386 * scale,
        26.7382 * scale, 44 * scale,
        24 * scale, 44 * scale,
      )
      ..cubicTo(
        21.2618 * scale, 44 * scale,
        18.877 * scale, 39.8386 * scale,
        17.6364 * scale, 33.69 * scale,
      )
      ..cubicTo(
        16.3957 * scale, 39.8386 * scale,
        14.0109 * scale, 44 * scale,
        11.2727 * scale, 44 * scale,
      )
      ..cubicTo(
        7.25611 * scale, 44 * scale,
        4 * scale, 35.0457 * scale,
        4 * scale, 24 * scale,
      )
      ..cubicTo(
        4 * scale, 12.9543 * scale,
        7.25611 * scale, 4 * scale,
        11.2727 * scale, 4 * scale,
      )
      ..cubicTo(
        14.0109 * scale, 4 * scale,
        16.3957 * scale, 8.16144 * scale,
        17.6364 * scale, 14.31 * scale,
      )
      ..cubicTo(
        18.877 * scale, 8.16144 * scale,
        21.2618 * scale, 4 * scale,
        24 * scale, 4 * scale,
      )
      ..cubicTo(
        26.7382 * scale, 4 * scale,
        29.123 * scale, 8.16144 * scale,
        30.3636 * scale, 14.31 * scale,
      )
      ..cubicTo(
        31.6043 * scale, 8.16144 * scale,
        33.9891 * scale, 4 * scale,
        36.7273 * scale, 4 * scale,
      )
      ..cubicTo(
        40.7439 * scale, 4 * scale,
        44 * scale, 12.9543 * scale,
        44 * scale, 24 * scale,
      )
      ..cubicTo(
        44 * scale, 35.0457 * scale,
        40.7439 * scale, 44 * scale,
        36.7273 * scale, 44 * scale,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MedVoiceIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
