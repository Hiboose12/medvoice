import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/app/router/route_paths.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';
import 'package:medvoice_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/community_feed_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/create_post_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/patient_dashboard_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/patient_utility_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/widgets/community_activity_card.dart';
import 'package:medvoice_flutter/features/patient/presentation/widgets/create_post_modal.dart';
import 'package:medvoice_flutter/features/patient/presentation/widgets/patient_notification_button.dart';
import 'package:medvoice_flutter/features/patient/presentation/widgets/patient_stat_card.dart';
import 'package:medvoice_flutter/features/patient/presentation/widgets/recent_activity_tile.dart';
import 'package:medvoice_flutter/features/patient/presentation/widgets/report_issue_card.dart';
import 'package:provider/provider.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientDashboardProvider>().loadDashboard();
    });
  }

  Future<void> _openCreatePost() async {
    final createProvider = context.read<CreatePostProvider>();
    final feedProvider = context.read<CommunityFeedProvider>();
    final dashboardProvider = context.read<PatientDashboardProvider>();

    createProvider.reset();
    await CreatePostModal.show(
      context,
      onSubmit: (data) async {
        final success = await createProvider.submit(
          title: data.title,
          description: data.description,
          category: data.category,
          unregisteredHospitalName: data.unregisteredHospitalName,
        );

        if (success && mounted) {
          await feedProvider.loadFeed();
          await dashboardProvider.refresh();
          if (mounted) {
            context.read<PatientUtilityProvider>().loadComplaints();
            context.go(RoutePaths.patientFeed);
          }
        }
      },
    );
  }

  Widget _buildErrorState(PatientDashboardProvider dashboard) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: PatientColors.medicalOrange),
          const SizedBox(height: 16),
          Text(dashboard.errorMessage ?? 'An error occurred', textAlign: TextAlign.center, style: const TextStyle(color: PatientColors.textMain)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: dashboard.retry, child: const Text('Retry')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<PatientDashboardProvider>();
    final user = auth.user;
    final stats = dashboard.stats;
    final now = DateTime.now();
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final today =
        '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';

    return GestureDetector(
      onTap: dashboard.closeNotificationPanel,
      child: ColoredBox(
        color: PatientColors.bgLight,
        child: dashboard.errorMessage != null && stats == null
            ? _buildErrorState(dashboard)
            : dashboard.isLoading && stats == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: dashboard.refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back, ${user?.firstName ?? user?.username ?? 'Patient'}!',
                                  style: GoogleFonts.manrope(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: PatientColors.textMain,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Today is $today',
                                  style: const TextStyle(
                                    color: PatientColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PatientNotificationButton(
                            notifications: dashboard.notifications,
                            showPanel: dashboard.showNotificationPanel,
                            onToggle: dashboard.toggleNotificationPanel,
                            onClose: dashboard.closeNotificationPanel,
                            onMarkRead: dashboard.markNotificationRead,
                          ),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                PatientColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              (user?.firstName.isNotEmpty == true
                                      ? user!.firstName[0]
                                      : user?.username[0] ?? 'P')
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: PatientColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 700;
                          final cards = [
                            PatientStatCard(
                              label: 'Total Complaints',
                              value: '${stats?.totalComplaints ?? 0}',
                              icon: Icons.assignment_outlined,
                              iconBackground: PatientColors.cardElevated,
                              iconColor: PatientColors.primary,
                            ),
                            PatientStatCard(
                              label: 'Resolved',
                              value: '${stats?.resolvedComplaints ?? 0}',
                              icon: Icons.check_circle_outline,
                              iconBackground: PatientColors.cardElevated,
                              iconColor: PatientColors.medicalTeal,
                            ),
                            PatientStatCard(
                              label: 'Pending',
                              value: '${stats?.pendingComplaints ?? 0}',
                              icon: Icons.pending_outlined,
                              iconBackground: PatientColors.cardElevated,
                              iconColor: PatientColors.medicalOrange,
                            ),
                          ];

                          if (isWide) {
                            return Row(
                              children: cards
                                  .map(
                                    (c) => Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 24),
                                        child: c,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          }

                          return Column(
                            children: cards
                                .map(
                                  (c) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: c,
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 900;
                          final recentActivity = Container(
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Recent Activity',
                                        style: GoogleFonts.manrope(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () {
                                          context.push(RoutePaths.patientComplaints);
                                        },
                                        child: const Text('View All'),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                if (stats != null && stats.recentActivity.isNotEmpty)
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: stats.recentActivity.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final post = stats.recentActivity[index];
                                      return RecentActivityTile(post: post);
                                    },
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: const BoxDecoration(
                                            color: PatientColors.cardElevated,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.sentiment_dissatisfied_outlined,
                                            size: 32,
                                            color: Color(0xFFD4D4D8),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'No complaints found.',
                                          style: TextStyle(
                                            color: PatientColors.textMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextButton(
                                            onPressed: _openCreatePost,
                                            child: const Text('File a Complaint')),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );

                          final sideColumn = Column(
                            children: [
                              ReportIssueCard(onGetStarted: _openCreatePost),
                              const SizedBox(height: 24),
                              if (stats != null)
                                CommunityActivityCard(
                                  stats: stats,
                                  onGoToFeed: () => context.go(RoutePaths.patientFeed),
                                ),
                            ],
                          );

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: recentActivity),
                                const SizedBox(width: 32),
                                Expanded(child: sideColumn),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              recentActivity,
                              const SizedBox(height: 24),
                              sideColumn,
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
