import 'package:flutter/material.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';

class FeedComposer extends StatelessWidget {
  const FeedComposer({
    super.key,
    required this.userInitial,
    required this.onTap,
    required this.onMediaTap,
    required this.onCategoryTap,
    required this.onUrgentTap,
  });

  final String userInitial;
  final VoidCallback onTap;
  final VoidCallback onMediaTap;
  final VoidCallback onCategoryTap;
  final VoidCallback onUrgentTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PatientColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PatientColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: PatientColors.cardElevated,
                child: Text(
                  userInitial.toUpperCase(),
                  style: const TextStyle(
                    color: PatientColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: PatientColors.cardElevated,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: PatientColors.border),
                    ),
                    child: const Text(
                      'Start a complaint...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: PatientColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ActionChip(
                icon: Icons.image_outlined,
                label: 'Media',
                color: Colors.blue,
                onTap: onMediaTap,
              ),
              _ActionChip(
                icon: Icons.category_outlined,
                label: 'Category',
                color: PatientColors.medicalOrange,
                onTap: onCategoryTap,
              ),
              _ActionChip(
                icon: Icons.campaign_outlined,
                label: 'Urgent',
                color: PatientColors.medicalRed,
                onTap: onUrgentTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: PatientColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
