import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';
import 'package:medvoice_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:medvoice_flutter/features/patient/domain/models/complaint_status.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/community_feed_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/create_post_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/patient_dashboard_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/patient_utility_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/widgets/complaint_post_card.dart';
import 'package:medvoice_flutter/features/patient/presentation/widgets/create_post_modal.dart';
import 'package:medvoice_flutter/features/patient/presentation/widgets/feed_composer.dart';
import 'package:provider/provider.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityFeedProvider>().loadFeed();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreatePost({ComplaintSeverity? presetSeverity}) async {
    final createProvider = context.read<CreatePostProvider>();
    final feedProvider = context.read<CommunityFeedProvider>();
    final dashboardProvider = context.read<PatientDashboardProvider>();

    createProvider.reset();
    if (presetSeverity != null) {
      createProvider.setSeverity(presetSeverity);
    }

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
          }
        }
      },
    );
  }

  Widget _buildErrorState(CommunityFeedProvider feed) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: PatientColors.medicalOrange),
            const SizedBox(height: 16),
            Text(feed.errorMessage ?? 'An error occurred', textAlign: TextAlign.center, style: const TextStyle(color: PatientColors.textMain)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: feed.retry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final feed = context.watch<CommunityFeedProvider>();
    final userInitial = auth.user?.firstName.isNotEmpty == true
        ? auth.user!.firstName[0]
        : auth.user?.username[0] ?? 'P';

    return ColoredBox(
      color: PatientColors.bgLight,
      child: RefreshIndicator(
        onRefresh: feed.loadFeed,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 768),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Community Feed',
                                    style: GoogleFonts.manrope(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: PatientColors.textMain,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Browse and interact with shared healthcare '
                                    'complaints anonymously.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: PatientColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 220,
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: (q) {
                                  feed.search(q);
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search complaints...',
                                  prefixIcon: IconButton(
                                    icon: const Icon(
                                      Icons.search,
                                      color: PatientColors.textMuted,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      feed.search(_searchController.text);
                                    },
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            size: 18,
                                            color: PatientColors.textMuted,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            feed.search('');
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: PatientColors.card,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: PatientColors.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: PatientColors.border,
                                    ),
                                  ),
                                ),
                                onChanged: (v) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        FeedComposer(
                          userInitial: userInitial,
                          onTap: () => _openCreatePost(),
                          onMediaTap: () => _openCreatePost(),
                          onCategoryTap: () => _openCreatePost(),
                          onUrgentTap: () =>
                              _openCreatePost(presetSeverity: ComplaintSeverity.high),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (feed.isLoading && feed.posts.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (feed.errorMessage != null && feed.posts.isEmpty)
              _buildErrorState(feed)
            else if (feed.posts.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No complaints found.',
                    style: TextStyle(color: PatientColors.textMuted),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 768),
                      child: Column(
                        children: feed.posts
                            .map(
                              (post) => ComplaintPostCard(
                                post: post,
                                onLike: () => feed.toggleLike(post.id),
                                onCommentAdded: () => feed.loadFeed(),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
