import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';
import 'package:medvoice_flutter/features/patient/domain/models/dashboard_stats.dart';

class CommunityActivityCard extends StatelessWidget {
  const CommunityActivityCard({
    super.key,
    required this.stats,
    required this.onGoToFeed,
  });

  final DashboardStats stats;
  final VoidCallback onGoToFeed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PatientColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatientColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Community Activity',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: PatientColors.textMain,
            ),
          ),
          const SizedBox(height: 16),
          _ActivityRow(
            color: PatientColors.primary,
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: PatientColors.textMuted,
                ),
                children: [
                  TextSpan(
                    text: '${stats.communityBillingCount} new topics in ',
                  ),
                  const TextSpan(
                    text: 'Billing Issues',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: PatientColors.textMain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ActivityRow(
            color: PatientColors.medicalTeal,
            child: Text(
              '${stats.communityResolvedToday} success stories shared today',
              style: const TextStyle(
                fontSize: 14,
                color: PatientColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ActivityRow(
            color: PatientColors.medicalOrange,
            child: Text.rich(
              const TextSpan(
                style: TextStyle(fontSize: 14, color: PatientColors.textMuted),
                children: [
                  TextSpan(text: 'Join the discussion on '),
                  TextSpan(
                    text: 'Rural Access',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: PatientColors.textMain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onGoToFeed,
              style: OutlinedButton.styleFrom(
                foregroundColor: PatientColors.textMuted,
                side: const BorderSide(color: PatientColors.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Go to Community Feed',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.color,
    required this.child,
  });

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}
