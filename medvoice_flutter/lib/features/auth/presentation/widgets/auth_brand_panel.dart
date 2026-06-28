import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/core/theme/app_colors.dart';

/// Left-side brand panel from login.html / register.html.
class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showStats = false,
    this.opacity = 0.8,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool showStats;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.authPanelBlue,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: opacity,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.shade900.withValues(alpha: 0.5),
                    Colors.green.shade800.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: showStats ? 56 : 48,
                  height: showStats ? 56 : 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(showStats ? 12 : 8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: showStats ? 28 : 24),
                ),
                SizedBox(height: showStats ? 32 : 24),
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: showStats ? 40 : 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: showStats ? AppColors.authBlue100 : AppColors.authBlue200,
                    height: 1.6,
                  ),
                ),
                if (showStats) ...[
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.only(top: 40),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            value: '100%',
                            label: 'Secure & Private',
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            value: 'Verified',
                            label: 'Official Authorities',
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 16,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 16,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppColors.authBlue200,
          ),
        ),
      ],
    );
  }
}
