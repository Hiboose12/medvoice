import 'package:flutter/material.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';
import 'package:medvoice_flutter/features/patient/domain/models/complaint_status.dart';

class PatientStatusBadge extends StatelessWidget {
  const PatientStatusBadge({super.key, required this.status});

  final ComplaintStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      ComplaintStatus.resolved => (
          const Color(0xFFCCFBF1),
          const Color(0xFF0F766E),
        ),
      ComplaintStatus.review => (
          const Color(0xFFDBEAFE),
          PatientColors.primary,
        ),
      _ => (
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          color: colors.$2,
        ),
      ),
    );
  }
}
