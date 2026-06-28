import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';

/// Profile tab placeholder — full profile screen is out of Phase 3 scope.
class PatientProfilePlaceholderScreen extends StatelessWidget {
  const PatientProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_circle_outlined,
              size: 56,
              color: PatientColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Profile',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Patient profile screen coming in a future phase.',
              textAlign: TextAlign.center,
              style: TextStyle(color: PatientColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
