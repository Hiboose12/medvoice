import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';

class ReportIssueCard extends StatelessWidget {
  const ReportIssueCard({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PatientColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: PatientColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report a New Issue',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Encountered an issue with healthcare services? Our team is '
                'here to help you get it resolved.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xCCFFFFFF),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: onGetStarted,
                style: TextButton.styleFrom(
                  backgroundColor: PatientColors.card,
                  foregroundColor: PatientColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(
                  'Get Started',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: -16,
            bottom: -16,
            child: Icon(
              Icons.campaign_outlined,
              size: 96,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
