import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/app/router/route_paths.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/community_feed_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/create_post_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/patient_dashboard_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/patient_utility_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/widgets/create_post_form.dart';
import 'package:provider/provider.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PatientColors.bgLight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Container(
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
              child: CreatePostForm(
                onCancel: () => context.go(RoutePaths.patientFeed),
                onSubmit: (data) async {
                  final createProvider = context.read<CreatePostProvider>();
                  final feedProvider = context.read<CommunityFeedProvider>();
                  final dashboardProvider =
                      context.read<PatientDashboardProvider>();

                  final success = await createProvider.submit(
                    title: data.title,
                    description: data.description,
                    category: data.category,
                    unregisteredHospitalName: data.unregisteredHospitalName,
                  );

                  if (!context.mounted) return;
                  if (success) {
                    await feedProvider.loadFeed();
                    await dashboardProvider.refresh();
                    if (!context.mounted) return;
                    context.read<PatientUtilityProvider>().loadComplaints();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Complaint posted successfully!',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    context.go(RoutePaths.patientFeed);
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
