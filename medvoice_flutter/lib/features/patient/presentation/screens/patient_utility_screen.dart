import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/app/router/route_paths.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';
import 'package:medvoice_flutter/features/patient/domain/models/complaint_post.dart';
import 'package:medvoice_flutter/features/patient/domain/models/complaint_status.dart';
import 'package:medvoice_flutter/features/patient/domain/models/patient_models.dart';
import 'package:medvoice_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/patient_dashboard_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/patient_utility_provider.dart';
import 'package:provider/provider.dart';

enum PatientUtilityPage { profile, complaints, chat, notifications, settings }

class PatientUtilityScreen extends StatefulWidget {
  const PatientUtilityScreen({super.key, required this.page});

  final PatientUtilityPage page;

  @override
  State<PatientUtilityScreen> createState() => _PatientUtilityScreenState();
}

class _PatientUtilityScreenState extends State<PatientUtilityScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(PatientUtilityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) {
      _loadData();
    }
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<PatientUtilityProvider>();
      switch (widget.page) {
        case PatientUtilityPage.profile:
          provider.loadProfile();
          break;
        case PatientUtilityPage.complaints:
          provider.loadComplaints();
          break;
        case PatientUtilityPage.chat:
          provider.loadConversations();
          break;
        case PatientUtilityPage.notifications:
          provider.loadNotifications();
          break;
        case PatientUtilityPage.settings:
          provider.loadSettings();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PatientColors.bgLight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(page: widget.page),
                const SizedBox(height: 20),
                switch (widget.page) {
                  PatientUtilityPage.profile => const _PatientProfile(),
                  PatientUtilityPage.complaints => const _MyComplaints(),
                  PatientUtilityPage.chat => const _PatientChat(),
                  PatientUtilityPage.notifications =>
                    const _PatientNotifications(),
                  PatientUtilityPage.settings => const _PatientSettings(),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.page});
  final PatientUtilityPage page;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PatientColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PatientColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PatientColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon(page), color: PatientColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(page),
                  style: GoogleFonts.manrope(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: PatientColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle(page),
                  style: const TextStyle(color: PatientColors.textMuted),
                ),
              ],
            ),
          ),
          // Support button in the header when on chat page
          if (page == PatientUtilityPage.chat)
            OutlinedButton.icon(
              onPressed: () => context.push(RoutePaths.patientSupport),
              icon: const Icon(Icons.support_agent, size: 18),
              label: const Text('Support'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: PatientColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Profile ──────────────────────────────────────────────────────────────────

class _PatientProfile extends StatelessWidget {
  const _PatientProfile();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientUtilityProvider>();
    final profile = provider.profile;
    final isLoading = provider.isProfileLoading;
    final user = context.watch<AuthProvider>().user;
    final isApproved = user?.isApproved ?? false;

    if (isLoading && profile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: PatientColors.medicalOrange),
              const SizedBox(height: 16),
              Text(provider.errorMessage ?? 'An error occurred', textAlign: TextAlign.center, style: const TextStyle(color: PatientColors.textMain)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: provider.retry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (profile == null) {
      return const Center(child: Text('Failed to load profile.'));
    }

    return Column(
      children: [
        _Card(
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor:
                        PatientColors.primary.withValues(alpha: 0.1),
                    backgroundImage: profile.photoUrl != null
                        ? NetworkImage(profile.photoUrl!)
                        : null,
                    child: profile.photoUrl == null
                        ? Text(
                            (profile.firstName.isNotEmpty
                                    ? profile.firstName[0]
                                    : profile.username.isNotEmpty
                                        ? profile.username[0]
                                        : 'P')
                                .toUpperCase(),
                            style: const TextStyle(
                              color: PatientColors.primary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: PatientColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '@${profile.username}',
                      style: const TextStyle(
                          color: PatientColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: PatientColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: PatientColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: const Text(
                            'Patient',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PatientColors.textMain),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isApproved ? PatientColors.medicalTeal : PatientColors.medicalOrange).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: (isApproved ? PatientColors.medicalTeal : PatientColors.medicalOrange).withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isApproved ? Icons.verified : Icons.pending,
                                size: 14,
                                color: isApproved ? PatientColors.medicalTeal : PatientColors.medicalOrange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isApproved ? 'Verified Status' : 'Pending Verification',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isApproved ? PatientColors.medicalTeal : PatientColors.medicalOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.mail_outline, size: 13, color: PatientColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            profile.email,
                            style: const TextStyle(color: PatientColors.textMuted, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (profile.city != null || profile.state != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: PatientColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              [profile.city, profile.state]
                                  .whereType<String>()
                                  .join(', '),
                              style: const TextStyle(
                                  color: PatientColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showEditProfile(context, profile, provider),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: PatientColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InfoGrid(
          items: {
            'Total complaints': '${profile.totalComplaints}',
            'Resolved': '${profile.resolvedComplaints}',
            'Pending': '${profile.pendingComplaints}',
            'Identity': 'Anonymous by default',
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            
            final personalInfo = _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline, color: PatientColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Personal Information',
                            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _showEditProfile(context, profile, provider),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Edit Profile'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      _InfoItem(label: 'Full Name', value: profile.displayName),
                      _InfoItem(label: 'Username', value: profile.username),
                      _InfoItem(label: 'Email Address', value: profile.email),
                      _InfoItem(label: 'Phone Number', value: profile.phoneNumber ?? 'Not set'),
                    ],
                  ),
                ],
              ),
            );

            final rightColumn = Column(
              children: [
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.security, color: PatientColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Security',
                            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: PatientColors.cardElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PASSWORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PatientColors.textMuted, letterSpacing: 1.2)),
                                SizedBox(height: 4),
                                Text('••••••••••••', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PatientColors.textMain)),
                              ],
                            ),
                            OutlinedButton(
                              onPressed: () => _showChangePassword(context, provider),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: PatientColors.border),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text('Change', style: TextStyle(color: PatientColors.textMain)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: PatientColors.cardElevated.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: PatientColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.smartphone, color: PatientColors.primary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Two-Factor Authentication', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PatientColors.textMain)),
                                  Text('Coming Soon', style: TextStyle(fontSize: 12, color: PatientColors.textMuted)),
                                ],
                              ),
                            ),
                            Switch(value: false, onChanged: null, activeThumbColor: PatientColors.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, color: PatientColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Identity Verification',
                            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (isApproved ? PatientColors.medicalTeal : PatientColors.medicalOrange).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: (isApproved ? PatientColors.medicalTeal : PatientColors.medicalOrange).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: (isApproved ? PatientColors.medicalTeal : PatientColors.medicalOrange).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.badge_outlined,
                                color: isApproved ? PatientColors.medicalTeal : PatientColors.medicalOrange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Government ID: ${isApproved ? 'Verified' : 'Pending'}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PatientColors.textMain),
                                  ),
                                  Text(
                                    isApproved ? 'Successfully linked' : 'Under review',
                                    style: const TextStyle(fontSize: 12, color: PatientColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.lock_outline, color: PatientColors.textMuted, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: personalInfo),
                  const SizedBox(width: 16),
                  Expanded(child: rightColumn),
                ],
              );
            }
            return Column(
              children: [
                personalInfo,
                const SizedBox(height: 16),
                rightColumn,
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            
            final viewIssues = Expanded(
              flex: isWide ? 1 : 0,
              child: FilledButton.icon(
                onPressed: () => context.push(RoutePaths.patientComplaints),
                icon: const Icon(Icons.assignment, size: 18),
                label: const Text('View My Issues'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            );

            final logoutBtn = Expanded(
              flex: isWide ? 1 : 0,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  context.go(RoutePaths.login);
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Logout from all devices'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PatientColors.medicalRed,
                  side: const BorderSide(color: PatientColors.medicalRed),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            );

            if (isWide) {
              return Row(
                children: [
                  viewIssues,
                  const SizedBox(width: 16),
                  logoutBtn,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                viewIssues,
                const SizedBox(height: 12),
                logoutBtn,
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        // Quick Actions
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: GoogleFonts.manrope(
                    fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ActionButton(
                    icon: Icons.assignment_outlined,
                    label: 'My Complaints',
                    onTap: () => context.push(RoutePaths.patientComplaints),
                  ),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chats',
                    onTap: () => context.push(RoutePaths.patientChat),
                  ),
                  _ActionButton(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => context.push(RoutePaths.patientNotifications),
                  ),
                  _ActionButton(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => context.push(RoutePaths.patientSettings),
                  ),
                  _ActionButton(
                    icon: Icons.support_agent,
                    label: 'Support',
                    onTap: () => context.push(RoutePaths.patientSupport),
                  ),
                  _ActionButton(
                    icon: Icons.document_scanner_outlined,
                    label: 'OCR Upload',
                    onTap: () => context.push(RoutePaths.patientOcrUpload),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'MedVoice Secure Protocol · Data is encrypted at rest and in transit',
          style: TextStyle(color: PatientColors.textMuted, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showEditProfile(
    BuildContext context,
    PatientProfile profile,
    PatientUtilityProvider provider,
  ) {
    final firstNameCtrl = TextEditingController(text: profile.firstName);
    final lastNameCtrl = TextEditingController(text: profile.lastName);
    final phoneCtrl = TextEditingController(text: profile.phoneNumber ?? '');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PatientColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: PatientColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Edit Profile',
              style: GoogleFonts.manrope(
                  fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: firstNameCtrl,
              decoration: const InputDecoration(
                labelText: 'First Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lastNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await provider.updateProfile(
                    firstName: firstNameCtrl.text.trim(),
                    lastName: lastNameCtrl.text.trim(),
                    phoneNumber: phoneCtrl.text.trim(),
                  );
                  if (context.mounted) {
                    context.read<AuthProvider>().refreshUser();
                    context.read<PatientDashboardProvider>().refresh();
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Save Changes'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── My Complaints ────────────────────────────────────────────────────────────

class _MyComplaints extends StatefulWidget {
  const _MyComplaints();

  @override
  State<_MyComplaints> createState() => _MyComplaintsState();
}

class _MyComplaintsState extends State<_MyComplaints> {
  String _activeFilter = 'all';
  final _searchCtrl = TextEditingController();

  static const _filters = [
    ('all', 'All'),
    ('pending', 'Pending'),
    ('review', 'In Review'),
    ('responded', 'Responded'),
    ('resolved', 'Resolved'),
    ('escalated', 'Escalated'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientUtilityProvider>();
    final all = provider.myComplaints;
    final isLoading = provider.isComplaintsLoading;

    // Filter locally
    final filtered = all.where((post) {
      final matchStatus =
          _activeFilter == 'all' || post.status.name == _activeFilter;
      final q = _searchCtrl.text.toLowerCase();
      final matchSearch = q.isEmpty ||
          post.title.toLowerCase().contains(q) ||
          post.hospitalName.toLowerCase().contains(q) ||
          post.category.toLowerCase().contains(q);
      return matchStatus && matchSearch;
    }).toList();

    if (isLoading && all.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && all.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: PatientColors.medicalOrange),
              const SizedBox(height: 16),
              Text(provider.errorMessage ?? 'An error occurred', textAlign: TextAlign.center, style: const TextStyle(color: PatientColors.textMain)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: provider.retry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'My Complaints',
                style: GoogleFonts.manrope(
                    fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.push(RoutePaths.patientCreatePost),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search bar
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by title, hospital...',
              prefixIcon: const Icon(Icons.search, color: PatientColors.textMuted),
              filled: true,
              fillColor: PatientColors.cardElevated,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final isActive = _activeFilter == filter.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter.$2),
                    selected: isActive,
                    onSelected: (_) => setState(() => _activeFilter = filter.$1),
                    selectedColor: PatientColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: PatientColors.primary,
                    labelStyle: TextStyle(
                      color: isActive ? PatientColors.primary : PatientColors.textMuted,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No complaints found.',
                  style: TextStyle(color: PatientColors.textMuted),
                ),
              ),
            )
          else
            ...filtered.map((post) => _ComplaintRow(post)),
        ],
      ),
    );
  }
}

// ── Chat ─────────────────────────────────────────────────────────────────────

class _PatientChat extends StatelessWidget {
  const _PatientChat();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientUtilityProvider>();
    final conversations = provider.conversations;
    final isLoading = provider.isChatLoading;

    if (isLoading && conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conversations',
            style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          if (conversations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 40, color: PatientColors.textMuted),
                    SizedBox(height: 8),
                    Text(
                      'No active chats found.',
                      style: TextStyle(color: PatientColors.textMuted),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Start a chat from a complaint detail page.',
                      style: TextStyle(color: PatientColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ...conversations.map((chat) => _ChatRow(chat)),
        ],
      ),
    );
  }
}

// ── Notifications ─────────────────────────────────────────────────────────────

class _PatientNotifications extends StatelessWidget {
  const _PatientNotifications();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientUtilityProvider>();
    final notifications = provider.notifications;
    final isLoading = provider.isNotificationsLoading;

    if (isLoading && notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Notifications',
                style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (notifications.any((n) => !n.isRead))
                TextButton(
                  onPressed: () {
                    for (final n in notifications) {
                      if (!n.isRead) provider.markNotificationRead(n.id);
                    }
                  },
                  child: const Text('Mark all read'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No notifications found.',
                  style: TextStyle(color: PatientColors.textMuted),
                ),
              ),
            )
          else
            ...notifications.map(
              (notice) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: notice.isRead
                      ? Colors.transparent
                      : PatientColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: notice.isRead
                        ? PatientColors.cardBorder
                        : PatientColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: notice.isRead
                          ? PatientColors.cardElevated
                          : PatientColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      notice.isRead
                          ? Icons.notifications_none_outlined
                          : Icons.notifications_active,
                      color: notice.isRead ? PatientColors.textMuted : PatientColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    notice.title,
                    style: TextStyle(
                      fontWeight: notice.isRead ? FontWeight.normal : FontWeight.w800,
                      color: notice.isRead ? PatientColors.textMuted : PatientColors.textMain,
                    ),
                  ),
                  subtitle: Text(
                    notice.message,
                    style: TextStyle(
                      color: notice.isRead
                          ? PatientColors.textMuted
                          : PatientColors.textMain.withValues(alpha: 0.8),
                    ),
                  ),
                  trailing: Text(
                    _age(notice.createdAt),
                    style: const TextStyle(color: PatientColors.textMuted, fontSize: 12),
                  ),
                  onTap: () {
                    if (!notice.isRead) provider.markNotificationRead(notice.id);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Settings ─────────────────────────────────────────────────────────────────

class _PatientSettings extends StatefulWidget {
  const _PatientSettings();

  @override
  State<_PatientSettings> createState() => _PatientSettingsState();
}

class _PatientSettingsState extends State<_PatientSettings> {
  late TextEditingController _phoneController;
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();

  PatientSettingsData? _localSettings;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  bool _hasChanges(PatientSettingsData a, PatientSettingsData b) {
    return a.emailNotifications != b.emailNotifications ||
        a.complaintStatusUpdates != b.complaintStatusUpdates ||
        a.newMessages != b.newMessages ||
        a.authorityResponses != b.authorityResponses ||
        a.showInFeed != b.showInFeed ||
        a.anonymousPosting != b.anonymousPosting ||
        a.showResolvedPublicly != b.showResolvedPublicly ||
        a.hideProfile != b.hideProfile ||
        a.allowHospitalContact != b.allowHospitalContact ||
        a.allowEscalation != b.allowEscalation ||
        a.theme != b.theme ||
        (a.phoneNumber ?? '') != (b.phoneNumber ?? '');
  }

  Future<void> _saveSettings(PatientUtilityProvider provider) async {
    if (_localSettings == null) return;
    final dashboard = context.read<PatientDashboardProvider>();
    final auth = context.read<AuthProvider>();
    await provider.updateSettings(_localSettings!);
    if (mounted) {
      setState(() {
        _hasUnsavedChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
    dashboard.refresh();
    auth.refreshUser();
  }

  void _updateLocalSetting(PatientSettingsData providerSettings, PatientSettingsData updated) {
    setState(() {
      _localSettings = updated;
      _hasUnsavedChanges = _hasChanges(providerSettings, _localSettings!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientUtilityProvider>();
    final settings = provider.settings;

    if (provider.isSettingsLoading && settings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (settings == null) {
      return const Center(child: Text('Failed to load settings.'));
    }

    if (_localSettings == null) {
      _localSettings = settings;
      _phoneController.text = settings.phoneNumber ?? '';
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Column(
          children: [
            // ── Privacy ─────────────────────────────────
            _SettingsSection(
              icon: Icons.lock_outline,
              title: 'Privacy',
              children: [
                _ToggleTile(
                  title: 'Show complaints in public feed',
                  subtitle: 'Your complaints appear anonymously by default.',
                  value: _localSettings!.showInFeed,
                  onChanged: (v) => _updateLocalSetting(settings, _localSettings!.copyWith(showInFeed: v)),
                ),
                _ToggleTile(
                  title: 'Anonymous posting',
                  subtitle: 'Your name is never shown on complaints.',
                  value: _localSettings!.anonymousPosting,
                  onChanged: (v) => _updateLocalSetting(settings, _localSettings!.copyWith(anonymousPosting: v)),
                ),
                _ToggleTile(
                  title: 'Show resolved complaints publicly',
                  subtitle: 'Resolved complaints remain visible in the feed.',
                  value: _localSettings!.showResolvedPublicly,
                  onChanged: (v) => _updateLocalSetting(settings, _localSettings!.copyWith(showResolvedPublicly: v)),
                ),
                _ToggleTile(
                  title: 'Hide my profile',
                  subtitle: 'Hospitals and authorities cannot view your profile.',
                  value: _localSettings!.hideProfile,
                  onChanged: (v) => _updateLocalSetting(settings, _localSettings!.copyWith(hideProfile: v)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Notifications ────────────────────────────
            _SettingsSection(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              children: [
                _ToggleTile(
                  title: 'Email notifications',
                  subtitle: 'Receive updates via email.',
                  value: _localSettings!.emailNotifications,
                  onChanged: (v) => _updateLocalSetting(settings, _localSettings!.copyWith(emailNotifications: v)),
                ),
                _ToggleTile(
                  title: 'Complaint status updates',
                  subtitle: 'Get notified when your complaint status changes.',
                  value: _localSettings!.complaintStatusUpdates,
                  onChanged: (v) => _updateLocalSetting(settings, _localSettings!.copyWith(complaintStatusUpdates: v)),
                ),
                _ToggleTile(
                  title: 'New messages',
                  subtitle: 'Get notified when you receive a new chat message.',
                  value: _localSettings!.newMessages,
                  onChanged: (v) => _updateLocalSetting(settings, _localSettings!.copyWith(newMessages: v)),
                ),
                _ToggleTile(
                  title: 'Authority responses',
                  subtitle: 'Get notified when an authority responds.',
                  value: _localSettings!.authorityResponses,
                  onChanged: (v) => _updateLocalSetting(settings, _localSettings!.copyWith(authorityResponses: v)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Interactions ─────────────────────────────
            _SettingsSection(
              icon: Icons.handshake_outlined,
              title: 'Interactions',
              children: [
                _ToggleTile(
                  title: 'Allow hospital contact',
                  subtitle: 'Hospitals may message you about your complaints.',
                  value: _localSettings!.allowHospitalContact,
                  onChanged: (v) => _updateLocalSetting(settings, _localSettings!.copyWith(allowHospitalContact: v)),
                ),
                _ToggleTile(
                  title: 'Allow escalation',
                  subtitle: 'Allow your complaint to be escalated to authorities.',
                  value: _localSettings!.allowEscalation,
                  onChanged: (v) => _updateLocalSetting(settings, _localSettings!.copyWith(allowEscalation: v)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Contact ───────────────────────────────────
            _SettingsSection(
              icon: Icons.contact_phone_outlined,
              title: 'Contact',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Preferred contact number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (val) => _updateLocalSetting(settings, _localSettings!.copyWith(phoneNumber: val)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Security ──────────────────────────────────
            _SettingsSection(
              icon: Icons.security_outlined,
              title: 'Security',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Password',
                        style: GoogleFonts.manrope(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _oldPasswordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Current password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _newPasswordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New password',
                          prefixIcon: Icon(Icons.lock_reset_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            if (_oldPasswordCtrl.text.isNotEmpty &&
                                _newPasswordCtrl.text.isNotEmpty) {
                              final dashboard = context.read<PatientDashboardProvider>();
                              final auth = context.read<AuthProvider>();
                              await provider.changePassword(
                                _oldPasswordCtrl.text,
                                _newPasswordCtrl.text,
                              );
                              _oldPasswordCtrl.clear();
                              _newPasswordCtrl.clear();
                              dashboard.refresh();
                              auth.refreshUser();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Password updated successfully')),
                                );
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: PatientColors.primary),
                          ),
                          child: const Text('Update Password'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => provider.logoutAllDevices(),
                          icon: const Icon(Icons.logout, size: 18, color: PatientColors.medicalRed),
                          label: const Text(
                            'Logout from all devices',
                            style: TextStyle(color: PatientColors.medicalRed),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: PatientColors.medicalRed),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_hasUnsavedChanges) const SizedBox(height: 100), // padding for floating footer
          ],
        ),
        if (_hasUnsavedChanges)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PatientColors.cardElevated,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: PatientColors.medicalOrange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You have unsaved changes',
                      style: TextStyle(fontWeight: FontWeight.w600, color: PatientColors.textMain),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _localSettings = settings;
                        _phoneController.text = settings.phoneNumber ?? '';
                        _hasUnsavedChanges = false;
                      });
                    },
                    child: const Text('Cancel', style: TextStyle(color: PatientColors.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _saveSettings(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PatientColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _ComplaintRow extends StatelessWidget {
  const _ComplaintRow(this.post);
  final ComplaintPost post;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(RoutePaths.patientComplaintDetail(post.id)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PatientColors.cardElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: PatientColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_outlined, color: PatientColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${post.hospitalName} · ${post.category} · ${_age(post.createdAt)}',
                    style: const TextStyle(color: PatientColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusPill(status: post.status),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios, size: 14, color: PatientColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow(this.chat);
  final ChatConversation chat;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(RoutePaths.patientChatDetail(chat.id)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PatientColors.cardElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: PatientColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    (chat.name.isNotEmpty ? chat.name[0] : '?').toUpperCase(),
                    style: const TextStyle(color: PatientColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                if (chat.unreadCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: PatientColors.medicalRed,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${chat.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        chat.name,
                        style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: PatientColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          chat.role,
                          style: const TextStyle(fontSize: 10, color: PatientColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (chat.complaintTitle != null)
                    Text(
                      'Re: ${chat.complaintTitle}',
                      style: const TextStyle(fontSize: 11, color: PatientColors.primary, fontWeight: FontWeight.w500),
                    ),
                  Text(
                    chat.lastMessage.isNotEmpty ? chat.lastMessage : 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: PatientColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_age(chat.lastMessageAt), style: const TextStyle(color: PatientColors.textMuted, fontSize: 11)),
                const SizedBox(height: 4),
                const Icon(Icons.arrow_forward_ios, size: 14, color: PatientColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final ComplaintStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      ComplaintStatus.newComplaint => (const Color(0x1AFF9800), PatientColors.medicalOrange),
      ComplaintStatus.review => (const Color(0x1A2196F3), PatientColors.primary),
      ComplaintStatus.responded => (const Color(0x1A9C27B0), const Color(0xFF7B1FA2)),
      ComplaintStatus.resolved => (const Color(0x1A4CAF50), PatientColors.medicalTeal),
      ComplaintStatus.escalated => (const Color(0x1AF44336), PatientColors.medicalRed),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: fg, letterSpacing: 0.4),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.icon, required this.title, required this.children});
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PatientColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatientColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: PatientColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: PatientColors.textMain),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({required this.title, required this.subtitle, required this.value, required this.onChanged});
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: PatientColors.textMuted)),
      activeThumbColor: PatientColors.primary,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: PatientColors.cardElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PatientColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: PatientColors.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});
  final Map<String, String> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 620 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: columns == 4 ? 1.9 : 2.2,
          children: items.entries
              .map(
                (item) => _Card(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.key,
                        style: const TextStyle(
                            color: PatientColors.textMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.value,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PatientColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatientColors.cardBorder),
      ),
      child: child,
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _title(PatientUtilityPage page) => switch (page) {
      PatientUtilityPage.profile => 'Patient Profile',
      PatientUtilityPage.complaints => 'My Complaints',
      PatientUtilityPage.chat => 'Patient Chat',
      PatientUtilityPage.notifications => 'Notifications',
      PatientUtilityPage.settings => 'Settings',
    };

String _subtitle(PatientUtilityPage page) => switch (page) {
      PatientUtilityPage.profile =>
        'Your complaint activity and privacy profile.',
      PatientUtilityPage.complaints =>
        'Track, edit, and review your submitted complaints.',
      PatientUtilityPage.chat =>
        'Continue conversations with hospitals and support.',
      PatientUtilityPage.notifications =>
        'Hospital responses, status changes, and support replies.',
      PatientUtilityPage.settings =>
        'Privacy, notification, and contact preferences.',
    };

IconData _icon(PatientUtilityPage page) => switch (page) {
      PatientUtilityPage.profile => Icons.account_circle_outlined,
      PatientUtilityPage.complaints => Icons.assignment_outlined,
      PatientUtilityPage.chat => Icons.chat_bubble_outline,
      PatientUtilityPage.notifications => Icons.notifications_outlined,
      PatientUtilityPage.settings => Icons.settings_outlined,
    };

String _age(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  return '${diff.inMinutes}m ago';
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PatientColors.textMuted, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, color: PatientColors.textMain)),
        ],
      ),
    );
  }
}

void _showEditProfile(BuildContext context, PatientProfile profile, PatientUtilityProvider provider) {
  final firstNameController = TextEditingController(text: profile.firstName);
  final lastNameController = TextEditingController(text: profile.lastName);
  final phoneController = TextEditingController(text: profile.phoneNumber ?? '');

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: PatientColors.cardElevated,
      title: const Text('Edit Profile', style: TextStyle(color: PatientColors.textMain)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'First Name', labelStyle: TextStyle(color: PatientColors.textMuted)),
              style: const TextStyle(color: PatientColors.textMain),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name', labelStyle: TextStyle(color: PatientColors.textMuted)),
              style: const TextStyle(color: PatientColors.textMain),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number', labelStyle: TextStyle(color: PatientColors.textMuted)),
              style: const TextStyle(color: PatientColors.textMain),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: PatientColors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: PatientColors.primary),
          onPressed: () async {
            await provider.updateProfile(
              firstName: firstNameController.text.trim(),
              lastName: lastNameController.text.trim(),
              phoneNumber: phoneController.text.trim(),
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

void _showChangePassword(BuildContext context, PatientUtilityProvider provider) {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: PatientColors.cardElevated,
      title: const Text('Change Password', style: TextStyle(color: PatientColors.textMain)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Old Password', labelStyle: TextStyle(color: PatientColors.textMuted)),
              style: const TextStyle(color: PatientColors.textMain),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password', labelStyle: TextStyle(color: PatientColors.textMuted)),
              style: const TextStyle(color: PatientColors.textMain),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: PatientColors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: PatientColors.primary),
          onPressed: () async {
            await provider.changePassword(
              oldPasswordController.text,
              newPasswordController.text,
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Update', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
