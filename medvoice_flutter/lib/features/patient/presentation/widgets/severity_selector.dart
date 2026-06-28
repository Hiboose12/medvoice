import 'package:flutter/material.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';
import 'package:medvoice_flutter/features/patient/domain/models/complaint_status.dart';

class SeveritySelector extends StatelessWidget {
  const SeveritySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ComplaintSeverity selected;
  final ValueChanged<ComplaintSeverity> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ComplaintSeverity.values.map((severity) {
        final isSelected = severity == selected;
        final colors = _colors(severity);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: severity != ComplaintSeverity.high ? 12 : 0,
            ),
            child: InkWell(
              onTap: () => onChanged(severity),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? colors.$1 : PatientColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? colors.$2 : PatientColors.border,
                  ),
                ),
                child: Text(
                  severity.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? colors.$2 : PatientColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  (Color, Color) _colors(ComplaintSeverity severity) {
    return switch (severity) {
      ComplaintSeverity.low => (
          const Color(0xFF0F2A1D),
          PatientColors.medicalTeal,
        ),
      ComplaintSeverity.medium => (
          const Color(0xFF33260A),
          PatientColors.medicalOrange,
        ),
      ComplaintSeverity.high => (
          const Color(0xFF321218),
          PatientColors.medicalRed,
        ),
    };
  }
}
