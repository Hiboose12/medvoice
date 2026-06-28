import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/app/router/route_paths.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';
import 'package:medvoice_flutter/features/patient/domain/models/complaint_post.dart';
import 'package:medvoice_flutter/features/patient/domain/models/complaint_status.dart';
import 'package:medvoice_flutter/features/patient/presentation/widgets/patient_status_badge.dart';
import 'package:medvoice_flutter/features/patient/presentation/utils/time_helper.dart';

class RecentActivityTile extends StatelessWidget {
  const RecentActivityTile({super.key, required this.post});

  final ComplaintPost post;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(post.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(RoutePaths.patientComplaintDetail(post.id)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusStyle.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(statusStyle.icon, size: 20, color: statusStyle.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${post.title} - ${post.hospitalName}',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: PatientColors.textMain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PatientStatusBadge(status: post.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.description.length > 100
                          ? '${post.description.substring(0, 100)}...'
                          : post.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PatientColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatRelativeTime(post.createdAt)} ago',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFA1A1AA),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusStyle _statusStyle(ComplaintStatus status) {
    return switch (status) {
      ComplaintStatus.resolved => const _StatusStyle(
          background: Color(0xFFCCFBF1),
          color: Color(0xFF0F766E),
          icon: Icons.check_circle_outline,
        ),
      ComplaintStatus.review => const _StatusStyle(
          background: Color(0xFFDBEAFE),
          color: PatientColors.primary,
          icon: Icons.visibility_outlined,
        ),
      _ => const _StatusStyle(
          background: Color(0xFFFEF3C7),
          color: Color(0xFFB45309),
          icon: Icons.hourglass_empty,
        ),
    };
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.background,
    required this.color,
    required this.icon,
  });

  final Color background;
  final Color color;
  final IconData icon;
}
