import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/app/router/route_paths.dart';
import 'package:medvoice_flutter/core/theme/app_colors.dart';
import 'package:medvoice_flutter/features/auth/domain/models/user_role.dart';
import 'package:medvoice_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:medvoice_flutter/features/operations/presentation/providers/hospital_provider.dart';
import 'package:medvoice_flutter/features/operations/presentation/providers/authority_provider.dart';
import 'package:medvoice_flutter/features/admin/presentation/providers/admin_provider.dart';
import 'package:medvoice_flutter/features/auth/presentation/widgets/medvoice_logo.dart';
import 'package:medvoice_flutter/features/patient/data/patient_repository.dart';
import 'package:medvoice_flutter/features/patient/domain/models/complaint_post.dart';
import 'package:medvoice_flutter/features/operations/domain/models/hospital_models.dart';
import 'package:medvoice_flutter/features/patient/domain/models/complaint_status.dart';
import 'package:medvoice_flutter/features/patient/presentation/screens/community_feed_screen.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';



enum OperationalRole { hospital, authority, admin }

enum OperationalPage {
  dashboard,
  complaints,
  feed,
  reports,
  chat,
  profile,
  notifications,
  settings,
  escalations,
  hospitals,
  warnings,
  regulations,
  approvals,
  users,
  categories,
  performance,
  support,
  entityVerification,
  auditLogs,
  securityMonitoring,
  securitySettings,
}

class OperationalScreen extends StatefulWidget {
  const OperationalScreen({super.key, required this.role, required this.page});

  final OperationalRole role;
  final OperationalPage page;

  @override
  State<OperationalScreen> createState() => _OperationalScreenState();
}

class _OperationalScreenState extends State<OperationalScreen> {
  String _search = '';
  String _status = 'All';

  @override
  void initState() {
    super.initState();
    _loadOperationalData();
  }

  @override
  void didUpdateWidget(OperationalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page || oldWidget.role != widget.role) {
      _loadOperationalData();
    }
  }

  void _loadOperationalData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.role == OperationalRole.hospital) {
        final provider = context.read<HospitalProvider>();
        if (widget.page == OperationalPage.dashboard) {
          provider.loadDashboard();
        } else if (widget.page == OperationalPage.complaints) {
          provider.loadQueue(status: _status, search: _search);
        } else if (widget.page == OperationalPage.profile) {
          provider.loadProfile();
        } else if (widget.page == OperationalPage.notifications) {
          provider.loadNotifications();
        } else if (widget.page == OperationalPage.chat) {
          provider.loadConversations();
        }
      } else if (widget.role == OperationalRole.authority) {
        final provider = context.read<AuthorityProvider>();
        if (widget.page == OperationalPage.dashboard) {
          provider.loadDashboard();
        } else if (widget.page == OperationalPage.complaints) {
          provider.loadQueue(status: _status, search: _search);
        } else if (widget.page == OperationalPage.escalations) {
          provider.loadEscalations();
        } else if (widget.page == OperationalPage.hospitals) {
          provider.loadHospitals(status: _status, search: _search);
        } else if (widget.page == OperationalPage.warnings) {
          provider.loadWarnings();
        } else if (widget.page == OperationalPage.notifications) {
          provider.loadNotifications();
        } else if (widget.page == OperationalPage.settings) {
          provider.loadSettings();
        }
      } else if (widget.role == OperationalRole.admin) {
        final provider = context.read<AdminProvider>();
        if (widget.page == OperationalPage.dashboard) {
          provider.loadDashboard();
        }
      }
    });
  }

  void _showComplaintDetailsDialog(BuildContext context, dynamic record) {
    if (record is! ComplaintPost) {
      final String hospitalName = record is HospitalComplaint ? (record as HospitalComplaint).hospitalName : record.hospital.toString();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.secondaryBackground,
          title: Text(record.title, style: const TextStyle(color: AppColors.textPrimary)),
          content: Text('Detail review for $hospitalName is under development.', style: const TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    final complaint = record;
    final hospitalProvider = context.read<HospitalProvider>();
    final responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool isPrivateResponse = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.secondaryBackground,
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      complaint.title,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatusPill(
                            label: complaint.status.label,
                            color: _statusColor(complaint.status.label),
                          ),
                          _StatusPill(
                            label: complaint.severity.name.toUpperCase(),
                            color: complaint.severity == ComplaintSeverity.high
                                ? AppColors.error
                                : AppColors.success,
                          ),
                          if (complaint.evidenceUrl != null)
                            ActionChip(
                              backgroundColor: AppColors.surface,
                              avatar: const Icon(Icons.attach_file, size: 16, color: AppColors.primaryAccent),
                              label: const Text('View Evidence', style: TextStyle(color: AppColors.textPrimary)),
                              onPressed: () async {
                                final url = complaint.evidenceUrl!;
                                if (await canLaunchUrlString(url)) {
                                  await launchUrlString(url, mode: LaunchMode.externalApplication);
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Unable to open evidence link')),
                                    );
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Description',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        complaint.description,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 16),
                      Text(
                        'Resolution Workflow',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (widget.role == OperationalRole.hospital) ...[
                        Row(
                          children: [
                            const Text('Update Status: ', style: TextStyle(color: AppColors.textPrimary)),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              dropdownColor: AppColors.secondaryBackground,
                              value: complaint.status.value,
                              style: const TextStyle(color: AppColors.textPrimary),
                              items: [
                                const DropdownMenuItem(value: 'new', child: Text('New')),
                                const DropdownMenuItem(value: 'review', child: Text('Investigating/Review')),
                                const DropdownMenuItem(value: 'responded', child: Text('Responded')),
                                if (complaint.status.value == 'resolved')
                                  const DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                                const DropdownMenuItem(value: 'escalated', child: Text('Escalated')),
                              ],
                              onChanged: complaint.status.value == 'resolved'
                                  ? null
                                  : (newStatus) async {
                                      if (newStatus != null) {
                                        final navigator = Navigator.of(context);
                                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                                        final success = await hospitalProvider.updateStatus(complaint.id, newStatus);
                                        if (success) {
                                          hospitalProvider.loadQueue(status: _status, search: _search);
                                          hospitalProvider.loadDashboard();
                                          navigator.pop();
                                          scaffoldMessenger.showSnackBar(
                                            SnackBar(content: Text('Status updated to $newStatus')),
                                          );
                                        }
                                      }
                                    },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Submit Response:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: responseController,
                          maxLines: 3,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Enter official hospital explanation or resolution status details...',
                            hintStyle: TextStyle(color: AppColors.textMuted),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryAccent)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: isPrivateResponse,
                              activeColor: AppColors.primaryAccent,
                              onChanged: (val) {
                                setStateDialog(() {
                                  isPrivateResponse = val ?? false;
                                });
                              },
                            ),
                            const Text(
                              'Post privately (only visible to patient)',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.hospital,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final text = responseController.text.trim();
                            if (text.isNotEmpty) {
                              final navigator = Navigator.of(context);
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              final success = await hospitalProvider.respondToComplaint(
                                complaint.id,
                                text,
                                isPrivate: isPrivateResponse,
                              );
                              if (success) {
                                hospitalProvider.loadQueue(status: _status, search: _search);
                                hospitalProvider.loadDashboard();
                                navigator.pop();
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(isPrivateResponse
                                      ? 'Private response sent successfully!'
                                      : 'Public response posted successfully!'
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Post Response'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryAccent),
                            foregroundColor: AppColors.primaryAccent,
                          ),
                          onPressed: () async {
                            try {
                              final repo = PatientRepository();
                              final chat = await repo.startComplaintChat(complaint.id);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                context.push(RoutePaths.patientChatDetail(chat.id));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to start chat: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.chat_outlined, size: 18),
                          label: const Text('Chat with Patient'),
                        ),
                      ] else ...[
                        const Text(
                          'Read-only resolution view for health authorities. Oversight warnings can be issued via the Hospitals Tab.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final config = _roleConfig(widget.role);
    final pageTitle = _pageTitle(widget.page);
    final hospitalProvider = context.watch<HospitalProvider>();
    final authorityProvider = context.watch<AuthorityProvider>();

    final adminProvider = context.watch<AdminProvider>();

    final bool isDataLoading = widget.role == OperationalRole.hospital
        ? hospitalProvider.isLoading
        : (widget.role == OperationalRole.authority
            ? authorityProvider.isLoading
            : (widget.role == OperationalRole.admin
                ? adminProvider.isLoading
                : false));

    final visibleComplaints = widget.role == OperationalRole.hospital
        ? (widget.page == OperationalPage.dashboard
            ? hospitalProvider.recentComplaints
            : hospitalProvider.queueComplaints)
        : (widget.role == OperationalRole.authority
            ? (widget.page == OperationalPage.dashboard
                ? authorityProvider.recentEscalations
                : (widget.page == OperationalPage.escalations
                    ? authorityProvider.escalations
                    : authorityProvider.queueComplaints))
            : _filteredComplaints());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: MedVoiceLogo(
          iconColor: config.color,
          compact: true,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _go(config.notificationsPath),
            icon: const Icon(Icons.notifications_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: config.color.withValues(alpha: 0.12),
              child: Text(
                (auth.user?.firstName.isNotEmpty == true
                        ? auth.user!.firstName[0]
                        : config.initial)
                    .toUpperCase(),
                style: TextStyle(
                  color: config.color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      drawer: _RoleDrawer(
        config: config,
        activePath: GoRouterState.of(context).uri.path,
        onNavigate: _go,
      ),
      body: SafeArea(
        child: widget.page == OperationalPage.feed && widget.role == OperationalRole.hospital
          ? const CommunityFeedScreen()
          : RefreshIndicator(
          onRefresh: () async {
            if (widget.role == OperationalRole.hospital) {
              final provider = context.read<HospitalProvider>();
              if (widget.page == OperationalPage.dashboard) {
                await provider.loadDashboard();
              } else if (widget.page == OperationalPage.complaints) {
                await provider.loadQueue(status: _status, search: _search);
              }
            } else if (widget.role == OperationalRole.authority) {
              final provider = context.read<AuthorityProvider>();
              if (widget.page == OperationalPage.dashboard) {
                await provider.loadDashboard();
              } else if (widget.page == OperationalPage.complaints) {
                await provider.loadQueue(status: _status, search: _search);
              } else if (widget.page == OperationalPage.escalations) {
                await provider.loadEscalations();
              } else if (widget.page == OperationalPage.hospitals) {
                await provider.loadHospitals(status: _status, search: _search);
              } else if (widget.page == OperationalPage.warnings) {
                await provider.loadWarnings();
              } else if (widget.page == OperationalPage.notifications) {
                await provider.loadNotifications();
              } else if (widget.page == OperationalPage.settings) {
                await provider.loadSettings();
              }
            } else if (widget.role == OperationalRole.admin) {
              final provider = context.read<AdminProvider>();
              if (widget.page == OperationalPage.dashboard) {
                await provider.loadDashboard();
              }
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isDataLoading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(
                          color: config.color,
                          backgroundColor: AppColors.secondaryBackground,
                        ),
                      ),
                    _HeroHeader(
                      role: config.label,
                      title: pageTitle,
                      subtitle: _pageSubtitle(widget.role, widget.page),
                      color: config.color,
                    ),
                    const SizedBox(height: 20),
                    _buildPage(config, visibleComplaints),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_RoleConfig config, List<dynamic> complaints) {
    return switch (widget.page) {
      OperationalPage.dashboard => _DashboardPage(
          config: config,
          onOpenDetail: (rec) => _showComplaintDetailsDialog(context, rec),
        ),
      OperationalPage.complaints => _ComplaintQueue(
          complaints: complaints,
          status: _status,
          onStatusChanged: (value) {
            setState(() {
              _status = value;
            });
            if (widget.role == OperationalRole.hospital) {
              context.read<HospitalProvider>().loadQueue(status: value, search: _search);
            } else if (widget.role == OperationalRole.authority) {
              context.read<AuthorityProvider>().loadQueue(status: value, search: _search);
            }
          },
          search: _search,
          onSearchChanged: (value) {
            setState(() {
              _search = value;
            });
            if (widget.role == OperationalRole.hospital) {
              context.read<HospitalProvider>().loadQueue(status: _status, search: value);
            } else if (widget.role == OperationalRole.authority) {
              context.read<AuthorityProvider>().loadQueue(status: _status, search: value);
            }
          },
          role: widget.role,
          onOpenDetail: (rec) => _showComplaintDetailsDialog(context, rec),
        ),
      // Hospital feed = real community feed widget; others use internal list
      OperationalPage.feed => widget.role == OperationalRole.hospital
          ? const CommunityFeedScreen()
          : _ComplaintFeed(
              complaints: complaints,
              onOpenDetail: (rec) => _showComplaintDetailsDialog(context, rec),
            ),
      OperationalPage.reports => _ReportsPage(
          complaints: complaints,
          onOpenDetail: (rec) => _showComplaintDetailsDialog(context, rec),
        ),
      OperationalPage.chat => _ChatPage(role: config.label),
      OperationalPage.profile => _ProfilePage(role: widget.role),
      OperationalPage.notifications => _NotificationsPage(role: widget.role),
      OperationalPage.settings => _SettingsPage(config: config),
      OperationalPage.escalations => _EscalationsPage(
          complaints: complaints,
          onOpenDetail: (rec) => _showComplaintDetailsDialog(context, rec),
        ),
      OperationalPage.hospitals => const _HospitalsPage(),
      OperationalPage.warnings => const _WarningsPage(),
      OperationalPage.regulations => const _RegulationsPage(),
      OperationalPage.approvals => const _EntityVerificationPage(),
      OperationalPage.users => const _UsersPage(),
      OperationalPage.categories => const _CategoriesPage(),
      OperationalPage.performance => const _PerformancePage(),
      OperationalPage.support => const _SupportPage(),
      OperationalPage.entityVerification => const _EntityVerificationPage(),
      OperationalPage.auditLogs => const _AuditLogsPage(),
      OperationalPage.securityMonitoring => const _SecurityMonitoringPage(),
      OperationalPage.securitySettings => const _SecuritySettingsPage(),
    };
  }

  List<_ComplaintRecord> _filteredComplaints() {
    final query = _search.trim().toLowerCase();
    return _complaints.where((complaint) {
      final statusMatches = _status == 'All' || complaint.status == _status;
      final queryMatches =
          query.isEmpty ||
          complaint.title.toLowerCase().contains(query) ||
          complaint.hospital.toLowerCase().contains(query) ||
          complaint.category.toLowerCase().contains(query);
      if (!statusMatches || !queryMatches) return false;

      return switch (widget.role) {
        OperationalRole.hospital =>
          complaint.hospital == 'City Care Hospital' ||
              widget.page == OperationalPage.feed,
        OperationalRole.authority => true,
        OperationalRole.admin => true,
      };
    }).toList();
  }

  void _go(String path) {
    if (GoRouterState.of(context).uri.path == path) return;
    context.go(path);
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({required this.config, this.onOpenDetail});

  final _RoleConfig config;
  final ValueChanged<dynamic>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    if (config.role == OperationalRole.admin) {
      return _AdminDashboardPage(config: config);
    }

    final hospitalProvider = context.watch<HospitalProvider>();
    final authorityProvider = context.watch<AuthorityProvider>();

    final List<_Metric> cards = switch (config.role) {
      OperationalRole.hospital => [
          _Metric(
            'Total Complaints',
            hospitalProvider.totalComplaints.toString(),
            Icons.assignment_outlined,
            AppColors.infoBg,
          ),
          _Metric(
            'Open',
            hospitalProvider.openComplaints.toString(),
            Icons.pending_actions_outlined,
            AppColors.warningBg,
          ),
          _Metric(
            'Responded',
            hospitalProvider.respondedComplaints.toString(),
            Icons.reply_outlined,
            AppColors.successBg,
          ),
          _Metric(
            'Resolved',
            hospitalProvider.resolvedComplaints.toString(),
            Icons.verified_outlined,
            AppColors.successBg,
          ),
        ],
      OperationalRole.authority => [
          _Metric(
            'Jurisdiction Hospitals',
            authorityProvider.totalHospitals.toString(),
            Icons.local_hospital_outlined,
            AppColors.infoBg,
          ),
          _Metric(
            'Active Complaints',
            authorityProvider.activeComplaints.toString(),
            Icons.assignment_late_outlined,
            AppColors.warningBg,
          ),
          _Metric(
            'Escalations',
            authorityProvider.escalatedComplaints.toString(),
            Icons.priority_high_outlined,
            AppColors.errorBg,
          ),
          _Metric(
            'Frozen Hospitals',
            authorityProvider.frozenHospitalsCount.toString(),
            Icons.block_outlined,
            AppColors.surface,
          ),
        ],
      OperationalRole.admin => const [],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hospitalProvider.errorMessage != null)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                Text(
                  hospitalProvider.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: hospitalProvider.retryDashboard,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        if (config.role == OperationalRole.hospital && hospitalProvider.isFrozen)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'ACCOUNT FROZEN',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your hospital account has been frozen by the District Health Authority due to overdue complaint resolutions. Please submit an explanation in the Appeal tab.',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        _MetricGrid(metrics: cards, accent: config.color),
        const SizedBox(height: 20),
        _Section(
          title: switch (config.role) {
            OperationalRole.hospital => 'Recent complaints assigned to your hospital',
            OperationalRole.authority => 'Recent escalated cases',
            OperationalRole.admin => 'Platform governance queue',
          },
          child: _RecordList(
            onOpenDetail: onOpenDetail,
            records: switch (config.role) {
              OperationalRole.hospital => hospitalProvider.recentComplaints,
              OperationalRole.authority => authorityProvider.recentEscalations,
              OperationalRole.admin => _adminQueue,
            },
          ),
        ),
      ],
    );
  }
}

class _AdminDashboardPage extends StatefulWidget {
  const _AdminDashboardPage({required this.config});
  final _RoleConfig config;

  @override
  State<_AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<_AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final data = provider.dashboardData;

    if (provider.isLoading && data == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.admin),
        ),
      );
    }

    if (provider.errorMessage != null && data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(provider.errorMessage!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<AdminProvider>().loadDashboard(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final totalUsers = data?['total_users']?.toString() ?? '0';
    final pendingApprovals = data?['pending_approvals_count']?.toString() ?? '0';
    final totalComplaints = data?['total_complaints']?.toString() ?? '0';
    final activeInvestigations = data?['active_investigations']?.toString() ?? '0';
    
    final pendingProviderApprovals = (data?['pending_provider_approvals'] as List?) ?? [];
    final platformActivity = (data?['platform_activity'] as List?) ?? [];

    final cards = [
      _Metric(
        'Total Users',
        totalUsers,
        Icons.group_outlined,
        AppColors.infoBg,
      ),
      _Metric(
        'Pending Approvals',
        pendingApprovals,
        Icons.how_to_reg_outlined,
        AppColors.warningBg,
      ),
      _Metric(
        'Total Complaints',
        totalComplaints,
        Icons.assignment_outlined,
        AppColors.errorBg,
      ),
      _Metric(
        'Active Investigations',
        activeInvestigations,
        Icons.search_outlined,
        AppColors.surface,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGrid(metrics: cards, accent: widget.config.color),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _PendingApprovalsSection(approvals: pendingProviderApprovals),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: _PlatformActivitySection(activities: platformActivity),
                  ),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PendingApprovalsSection(approvals: pendingProviderApprovals),
                  const SizedBox(height: 24),
                  _PlatformActivitySection(activities: platformActivity),
                ],
              );
            }
          },
        ),
      ],
    );
  }
}

class _PendingApprovalsSection extends StatelessWidget {
  const _PendingApprovalsSection({required this.approvals});
  final List<dynamic> approvals;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pending Provider Approvals',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {}, // Could link to Users tab
                  child: const Text('View all', style: TextStyle(color: AppColors.admin)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.secondaryBackground,
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('USER', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('ROLE', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('DATE JOINED', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold))),
                SizedBox(width: 80, child: Text('ACTIONS', textAlign: TextAlign.right, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Body
          if (approvals.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text('No pending approvals at this time.', style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: approvals.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final item = approvals[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.secondaryBackground,
                              child: const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['username'] ?? '',
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          item['role'] ?? '',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          item['date_joined'] ?? '',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {}, // Could link to review
                            child: const Text('Review', style: TextStyle(color: AppColors.admin, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PlatformActivitySection extends StatelessWidget {
  const _PlatformActivitySection({required this.activities});
  final List<dynamic> activities;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform Activity',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No recent activity.', style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final act = activities[index];
                
                // Color mapping logic for dots based on action keywords
                Color dotColor = AppColors.admin;
                final titleStr = (act['title'] ?? '').toLowerCase();
                if (titleStr.contains('resolved')) dotColor = Colors.green;
                else if (titleStr.contains('escalat') || titleStr.contains('urgent')) dotColor = Colors.orange;
                else if (titleStr.contains('block') || titleStr.contains('deactivat')) dotColor = Colors.red;
                else if (titleStr.contains('backup')) dotColor = Colors.blue;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act['time_ago'] ?? '',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            act['title'] ?? '',
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            act['subtitle'] ?? '',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}


class _ComplaintQueue extends StatelessWidget {
  const _ComplaintQueue({
    required this.complaints,
    required this.status,
    required this.onStatusChanged,
    required this.search,
    required this.onSearchChanged,
    required this.role,
    this.onOpenDetail,
  });

  final List<dynamic> complaints;
  final String status;
  final ValueChanged<String> onStatusChanged;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final OperationalRole role;
  final ValueChanged<dynamic>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: role == OperationalRole.authority
          ? 'Jurisdiction complaints'
          : 'Complaint management',
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 720;
              final searchField = TextField(
                onChanged: onSearchChanged,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Search by complaint, hospital, or category',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryAccent)),
                ),
              );
              final statusFilter = DropdownButtonFormField<String>(
                dropdownColor: AppColors.secondaryBackground,
                initialValue: status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                items: [
                  'All',
                  'New',
                  'Review',
                  'Responded',
                  'Resolved',
                  'Escalated',
                ]
                    .map(
                      (item) => DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) => onStatusChanged(value ?? 'All'),
              );

              if (!wide) {
                return Column(
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    statusFilter,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 2, child: searchField),
                  const SizedBox(width: 12),
                  Expanded(child: statusFilter),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _RecordList(records: complaints, onOpenDetail: onOpenDetail, role: role),
        ],
      ),
    );
  }
}

class _ComplaintFeed extends StatelessWidget {
  const _ComplaintFeed({required this.complaints, this.onOpenDetail});

  final List<dynamic> complaints;
  final ValueChanged<dynamic>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return _RecordList(records: complaints, onOpenDetail: onOpenDetail);
  }
}

class _ReportsPage extends StatelessWidget {
  const _ReportsPage({required this.complaints, this.onOpenDetail});

  final List<dynamic> complaints;
  final ValueChanged<dynamic>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final resolvedCount = complaints.where((item) {
      if (item is ComplaintPost) {
        return item.status == ComplaintStatus.resolved;
      } else {
        return item.status == 'Resolved';
      }
    }).length;
    final totalCount = complaints.isEmpty ? 1 : complaints.length;

    final escalatedCount = complaints.where((item) {
      if (item is ComplaintPost) {
        return item.status == ComplaintStatus.escalated;
      } else {
        return item.escalated;
      }
    }).length;

    return Column(
      children: [
        _MetricGrid(
          accent: AppColors.hospital,
          metrics: [
            _Metric(
              'Resolution Rate',
              '${(resolvedCount / totalCount * 100).round()}%',
              Icons.trending_up_outlined,
              AppColors.successBg,
            ),
            _Metric(
              'Escalation Risk',
              '$escalatedCount cases',
              Icons.warning_amber_outlined,
              AppColors.warningBg,
            ),
            const _Metric(
              'CSV Export',
              'Ready',
              Icons.file_download_outlined,
              AppColors.infoBg,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Section(
          title: 'Report preview',
          child: _RecordList(records: complaints, onOpenDetail: onOpenDetail),
        ),
      ],
    );
  }
}

class _ChatPage extends StatefulWidget {
  const _ChatPage({required this.role});

  final String role;

  @override
  State<_ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<_ChatPage> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      // Use HospitalProvider conversations if hospital role, otherwise PatientRepository
      if (widget.role == 'Hospital') {
        await context.read<HospitalProvider>().loadConversations();
        if (mounted) {
          setState(() {
            _conversations = context.read<HospitalProvider>().conversations;
            _isLoading = false;
          });
        }
      } else {
        final repo = PatientRepository();
        final role = widget.role == 'Authority' ? UserRole.authority : UserRole.patient;
        final convos = await repo.getConversations(role);
        if (mounted) {
          setState(() {
            _conversations = convos.map((c) {
              return <String, dynamic>{
                'id': c.id,
                'other_user': {'username': c.name, 'first_name': c.name},
                'last_message': c.lastMessage,
                'last_message_at': c.lastMessageAt.toIso8601String(),
                'unread_count': 0,
              };
            }).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.trim().isEmpty) return _conversations;
    final q = _searchQuery.toLowerCase();
    return _conversations.where((c) {
      final name = (c['other_user']?['username'] ?? '').toString().toLowerCase();
      final msg = (c['last_message'] ?? '').toString().toLowerCase();
      return name.contains(q) || msg.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.role == 'Hospital' ? AppColors.hospital : AppColors.authority;
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary),
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search conversations…',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.secondaryBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: AppColors.primaryAccent)),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, color: AppColors.textSecondary, size: 48),
                const SizedBox(height: 12),
                const Text('Failed to load conversations', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _loadConversations, child: const Text('Retry')),
              ],
            ),
          )
        else if (_filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: accentColor.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text(
                  'No conversations yet',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chats with patients will appear here.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          )
        else
          RefreshIndicator(
            onRefresh: _loadConversations,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filtered.length,
              separatorBuilder: (_, index) => const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (context, index) {
                final convo = _filtered[index];
                final int id = convo['id'] as int? ?? 0;
                final String username = convo['other_user']?['username'] as String? ?? 'User';
                final String firstName = convo['other_user']?['first_name'] as String? ?? '';
                final String displayName = firstName.isNotEmpty ? firstName : username;
                final String preview = convo['last_message'] as String? ?? '';
                final int unread = convo['unread_count'] as int? ?? 0;
                final String rawTime = convo['last_message_at'] as String? ?? '';
                String timeLabel = '';
                if (rawTime.isNotEmpty) {
                  try {
                    final dt = DateTime.parse(rawTime).toLocal();
                    final now = DateTime.now();
                    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
                      timeLabel = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    } else {
                      timeLabel = '${dt.day}/${dt.month}';
                    }
                  } catch (_) {}
                }

                return InkWell(
                  onTap: () => context.push(RoutePaths.patientChatDetail(id)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: accentColor.withValues(alpha: 0.15),
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: GoogleFonts.manrope(
                                  fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                preview.isEmpty ? 'No messages yet' : preview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: unread > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              timeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: unread > 0 ? accentColor : AppColors.textMuted,
                                fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.normal,
                              ),
                            ),
                            if (unread > 0) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  unread > 99 ? '99+' : unread.toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}



class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage({required this.role});

  final OperationalRole role;

  @override
  Widget build(BuildContext context) {
    // Hospital: live notifications with mark-as-read
    if (role == OperationalRole.hospital) {
      final provider = context.watch<HospitalProvider>();
      final list = provider.notifications;
      if (provider.isLoadingNotifications) {
        return const Center(child: CircularProgressIndicator(color: AppColors.hospital));
      }
      return _Section(
        title: 'Notifications',
        child: list.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No notifications yet.', style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            : Column(
                children: list.map((item) {
                  final int id = (item['id'] as int?) ?? 0;
                  final String title = (item['title'] as String?) ?? 'Notification';
                  final String message = (item['message'] as String?) ?? '';
                  final bool isRead = (item['is_read'] as bool?) ?? true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.transparent : AppColors.hospital.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.hospital.withValues(alpha: 0.1),
                        child: Icon(
                          isRead ? Icons.notifications_none : Icons.notifications_active,
                          color: AppColors.hospital,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      trailing: !isRead
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.circle, size: 10, color: AppColors.hospital),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => context.read<HospitalProvider>().markNotificationAsRead(id),
                                  child: const Text(
                                    'Mark read',
                                    style: TextStyle(color: AppColors.hospital, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            )
                          : const Icon(Icons.check_circle_outline, size: 16, color: AppColors.textMuted),
                      onTap: () {
                        if (!isRead) {
                          context.read<HospitalProvider>().markNotificationAsRead(id);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
      );
    }

    // Authority: live notifications
    if (role == OperationalRole.authority) {
      final provider = context.watch<AuthorityProvider>();
      final list = provider.notifications;
      return _Section(
        title: 'Notifications',
        child: list.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No notifications.', style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            : Column(
                children: list.map((item) {
                  final int id = item['id'] ?? 0;
                  final String title = item['title'] ?? 'Notification';
                  final String message = item['message'] ?? '';
                  final bool isRead = item['is_read'] ?? true;
                  final String type = item['notification_type'] ?? 'info';
                  final IconData icon = type == 'warning'
                      ? Icons.warning_amber_outlined
                      : type == 'freeze'
                          ? Icons.block_outlined
                          : Icons.info_outline;
                  final Color color = type == 'warning'
                      ? AppColors.warning
                      : type == 'freeze'
                          ? AppColors.error
                          : AppColors.primaryAccent;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(icon, color: color),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    subtitle: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
                    trailing: !isRead
                        ? Icon(Icons.circle, size: 10, color: color)
                        : null,
                    onTap: () {
                      if (!isRead) context.read<AuthorityProvider>().markNotificationAsRead(id);
                    },
                  );
                }).toList(),
              ),
      );
    }

    // Admin: live notifications
    if (role == OperationalRole.admin) {
      return const _AdminNotificationsList();
    }

    return const SizedBox();
  }
}

class _AdminNotificationsList extends StatefulWidget {
  const _AdminNotificationsList();

  @override
  State<_AdminNotificationsList> createState() => _AdminNotificationsListState();
}

class _AdminNotificationsListState extends State<_AdminNotificationsList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadNotifications();
    });
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString);
      final month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1];
      final ampm = date.hour >= 12 ? 'PM' : 'AM';
      var hour = date.hour % 12;
      if (hour == 0) hour = 12;
      final minute = date.minute.toString().padLeft(2, '0');
      return '$month ${date.day}, ${date.year} · ${hour.toString().padLeft(2, '0')} $ampm';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final list = provider.notifications;
    
    if (provider.isLoadingNotifications) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent));
    }

    return _Section(
      title: 'Notifications',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Text(
              'System alerts and admin updates.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ),
          if (list.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Column(
                children: [
                  Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.divider),
                  SizedBox(height: 8),
                  Text('No notifications yet.', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          else
            Column(
              children: list.map((item) {
                final int id = item['id'] ?? 0;
                final String title = item['title'] ?? 'Notification';
                final String message = item['message'] ?? '';
                final bool isRead = item['is_read'] ?? true;
                final String createdAt = item['created_at'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.notifications, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(_formatDate(createdAt), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (!isRead)
                        OutlinedButton(
                          onPressed: () => context.read<AdminProvider>().markNotificationAsRead(id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text('Mark read', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _SettingsPage extends StatefulWidget {
  const _SettingsPage({required this.config});

  final _RoleConfig config;

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  final _responseController = TextEditingController();
  final _viewController = TextEditingController();
  final _warningController = TextEditingController();

  // Hospital password change
  final _currentPwdController = TextEditingController();
  final _newPwdController = TextEditingController();
  final _confirmPwdController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSavingPassword = false;

  @override
  void dispose() {
    _responseController.dispose();
    _viewController.dispose();
    _warningController.dispose();
    _currentPwdController.dispose();
    _newPwdController.dispose();
    _confirmPwdController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final current = _currentPwdController.text.trim();
    final newPwd = _newPwdController.text.trim();
    final confirm = _confirmPwdController.text.trim();
    if (current.isEmpty || newPwd.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all password fields.')),
      );
      return;
    }
    if (newPwd != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match.')),
      );
      return;
    }
    if (newPwd.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }
    setState(() => _isSavingPassword = true);
    final provider = context.read<HospitalProvider>();
    final scaffold = ScaffoldMessenger.of(context);
    final error = await provider.changePassword(
      currentPassword: current,
      newPassword: newPwd,
    );
    if (!mounted) return;
    setState(() => _isSavingPassword = false);
    if (error == null) {
      _currentPwdController.clear();
      _newPwdController.clear();
      _confirmPwdController.clear();
      scaffold.showSnackBar(
        const SnackBar(content: Text('Password changed successfully!')),
      );
    } else {
      scaffold.showSnackBar(
        SnackBar(content: Text('Failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.config.role == OperationalRole.hospital) {
      return _Section(
        title: 'Hospital Settings',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Preferences',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.hospital,
              value: true,
              onChanged: (_) {},
              title: const Text('Email notifications', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Receive complaint assignments and response alerts.', style: TextStyle(color: AppColors.textSecondary)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.hospital,
              value: true,
              onChanged: (_) {},
              title: const Text('Escalation alerts', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Notify me when a complaint is escalated.', style: TextStyle(color: AppColors.textSecondary)),
            ),
            const Divider(height: 28, color: AppColors.divider),
            Text(
              'Change Password',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Update your account password. You will remain logged in after changing.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _currentPwdController,
              obscureText: _obscureCurrent,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.hospital)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPwdController,
              obscureText: _obscureNew,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppColors.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.hospital)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPwdController,
              obscureText: _obscureConfirm,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppColors.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.hospital)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.hospital,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSavingPassword ? null : _changePassword,
                icon: _isSavingPassword
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.lock_reset, size: 18),
                label: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.config.role == OperationalRole.authority) {
      final provider = context.watch<AuthorityProvider>();
      
      // Initialize controller texts if not modified
      if (_responseController.text.isEmpty) {
        _responseController.text = provider.responseTimeThreshold.toString();
      }
      if (_viewController.text.isEmpty) {
        _viewController.text = provider.viewTimeThreshold.toString();
      }
      if (_warningController.text.isEmpty) {
        _warningController.text = provider.warningThreshold.toString();
      }

      return _Section(
        title: 'Oversight Settings',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alert Configurations',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primaryAccent,
              value: provider.emailNotifications,
              onChanged: (val) {
                provider.updateNotificationSettings(
                  val,
                  provider.escalationAlerts,
                  provider.warningAlerts,
                  provider.freezeAlerts,
                );
              },
              title: const Text('Email notifications', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Receive complaints, warning summaries, and support updates.', style: TextStyle(color: AppColors.textSecondary)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primaryAccent,
              value: provider.escalationAlerts,
              onChanged: (val) {
                provider.updateNotificationSettings(
                  provider.emailNotifications,
                  val,
                  provider.warningAlerts,
                  provider.freezeAlerts,
                );
              },
              title: const Text('Escalation alerts', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Notify me instantly when response thresholds are breached.', style: TextStyle(color: AppColors.textSecondary)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primaryAccent,
              value: provider.warningAlerts,
              onChanged: (val) {
                provider.updateNotificationSettings(
                  provider.emailNotifications,
                  provider.escalationAlerts,
                  val,
                  provider.freezeAlerts,
                );
              },
              title: const Text('Warning alerts', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Notify me when warnings are issued or details modified.', style: TextStyle(color: AppColors.textSecondary)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primaryAccent,
              value: provider.freezeAlerts,
              onChanged: (val) {
                provider.updateNotificationSettings(
                  provider.emailNotifications,
                  provider.escalationAlerts,
                  provider.warningAlerts,
                  val,
                );
              },
              title: const Text('Freeze alerts', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Notify me when automated warnings trigger hospital deactivation.', style: TextStyle(color: AppColors.textSecondary)),
            ),
            const Divider(height: 28, color: AppColors.divider),
            Text(
              'Oversight SLA Thresholds',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _responseController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Response threshold (hours)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintText: '48',
                prefixIcon: Icon(Icons.timer_outlined, color: AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryAccent)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _viewController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Hospital view threshold (hours)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintText: '24',
                prefixIcon: Icon(Icons.visibility_outlined, color: AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryAccent)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _warningController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Freeze Warning Limit',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintText: '3',
                prefixIcon: Icon(Icons.block_outlined, color: AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryAccent)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.authority,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final responseVal = int.tryParse(_responseController.text) ?? 48;
                final viewVal = int.tryParse(_viewController.text) ?? 24;
                final warningVal = int.tryParse(_warningController.text) ?? 3;
                final scaffold = ScaffoldMessenger.of(context);
                final success = await provider.updateThresholds(responseVal, viewVal, warningVal);
                if (success) {
                  scaffold.showSnackBar(
                    const SnackBar(content: Text('SLA Thresholds updated successfully!')),
                  );
                }
              },
              child: const Text('Save SLA Settings'),
            ),
          ],
        ),
      );
    }

    return _Section(
      title: 'Settings',
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: true,
            onChanged: (_) {},
            title: const Text('Email notifications', style: TextStyle(color: AppColors.textPrimary)),
            subtitle: const Text(
              'Receive complaint, warning, and support updates.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: widget.config.role != OperationalRole.hospital,
            onChanged: (_) {},
            title: const Text('Escalation alerts', style: TextStyle(color: AppColors.textPrimary)),
            subtitle: const Text(
              'Notify me when response thresholds are crossed.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const Divider(height: 28, color: AppColors.divider),
          const TextField(
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Response threshold in hours',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              hintText: '48',
              prefixIcon: Icon(Icons.timer_outlined, color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EscalationsPage extends StatelessWidget {
  const _EscalationsPage({required this.complaints, this.onOpenDetail});

  final List<dynamic> complaints;
  final ValueChanged<dynamic>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final escalatedComplaints = complaints.where((item) {
      if (item is ComplaintPost) {
        return item.status == ComplaintStatus.escalated;
      } else {
        return item.escalated;
      }
    }).toList();

    return _Section(
      title: 'Escalated complaints',
      child: _RecordList(
        records: escalatedComplaints,
        onOpenDetail: onOpenDetail,
      ),
    );
  }
}

class _HospitalsPage extends StatelessWidget {
  const _HospitalsPage();

  void _showWarningDialog(BuildContext context, int hospitalId) {
    final reasonController = TextEditingController();
    String warningType = 'Serious';
    final provider = context.read<AuthorityProvider>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.secondaryBackground,
              title: const Text('Issue Hospital Warning', style: TextStyle(color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select warning classification level:', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    dropdownColor: AppColors.secondaryBackground,
                    value: warningType,
                    style: const TextStyle(color: AppColors.textPrimary),
                    items: const [
                      DropdownMenuItem(value: 'Serious', child: Text('Serious Warning')),
                      DropdownMenuItem(value: 'Critical', child: Text('Critical Warning')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() {
                          warningType = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Oversight Violation Reason',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryAccent)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                  onPressed: () async {
                    final reason = reasonController.text.trim();
                    if (reason.isNotEmpty) {
                      final nav = Navigator.of(context);
                      final scaffold = ScaffoldMessenger.of(context);
                      final success = await provider.issueWarning(hospitalId, warningType, reason);
                      if (success) {
                        provider.loadHospitals();
                        nav.pop();
                        scaffold.showSnackBar(
                          const SnackBar(content: Text('Warning issued successfully!')),
                        );
                      }
                    }
                  },
                  child: const Text('Issue Warning', style: TextStyle(color: Colors.black)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFreezeDialog(BuildContext context, int hospitalId) {
    final descController = TextEditingController();
    String reason = 'Warning_limit';
    final provider = context.read<AuthorityProvider>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.secondaryBackground,
              title: const Text('Freeze Hospital Account', style: TextStyle(color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select freeze trigger classification:', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    dropdownColor: AppColors.secondaryBackground,
                    value: reason,
                    style: const TextStyle(color: AppColors.textPrimary),
                    items: const [
                      DropdownMenuItem(value: 'Warning_limit', child: Text('Warning Limit Exceeded')),
                      DropdownMenuItem(value: 'Overdue_complaint', child: Text('Overdue Escalation Response')),
                      DropdownMenuItem(value: 'Other', child: Text('Other Regulatory Inaction')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() {
                          reason = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Freeze Action Explanation',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryAccent)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  onPressed: () async {
                    final desc = descController.text.trim();
                    if (desc.isNotEmpty) {
                      final nav = Navigator.of(context);
                      final scaffold = ScaffoldMessenger.of(context);
                      final success = await provider.freezeHospital(hospitalId, reason, desc);
                      if (success) {
                        provider.loadHospitals();
                        nav.pop();
                        scaffold.showSnackBar(
                          const SnackBar(content: Text('Hospital deactivated / frozen successfully!')),
                        );
                      }
                    }
                  },
                  child: const Text('Freeze Account', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthorityProvider>();
    final hospitalsList = provider.hospitals;

    return _Section(
      title: 'Jurisdiction Oversight',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Approved hospitals registered inside your designated clinical district.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          hospitalsList.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No hospitals found.', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: hospitalsList.length,
                  itemBuilder: (context, index) {
                    final h = hospitalsList[index];
                    final int id = h['id'] ?? 0;
                    final String name = h['hospital_name'] ?? 'Hospital';
                    final String license = h['license_number'] ?? '';
                    final int warningsCount = h['active_warnings'] ?? 0;
                    final int complaintsCount = h['complaint_count'] ?? 0;
                    final bool isFrozen = h['is_frozen'] ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isFrozen ? AppColors.error : AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'License: $license',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              _StatusPill(
                                label: isFrozen ? 'FROZEN' : 'ACTIVE',
                                color: isFrozen ? AppColors.error : AppColors.success,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.assignment_outlined, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text('$complaintsCount Complaints', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              const SizedBox(width: 20),
                              Icon(Icons.warning_amber_outlined, size: 16, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Text('$warningsCount Warnings', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!isFrozen) ...[
                                TextButton.icon(
                                  onPressed: () => _showWarningDialog(context, id),
                                  icon: const Icon(Icons.warning_amber_outlined, size: 16, color: AppColors.warning),
                                  label: const Text('Warn', style: TextStyle(color: AppColors.warning)),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _showFreezeDialog(context, id),
                                  icon: const Icon(Icons.block_outlined, size: 16, color: AppColors.error),
                                  label: const Text('Freeze', style: TextStyle(color: AppColors.error)),
                                ),
                              ] else ...[
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    final scaffold = ScaffoldMessenger.of(context);
                                    final provider = context.read<AuthorityProvider>();
                                    final success = await provider.unfreezeHospital(id);
                                    if (success) {
                                      provider.loadHospitals();
                                      scaffold.showSnackBar(
                                        const SnackBar(content: Text('Hospital account unblocked/reactivated!')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.verified_outlined, size: 16),
                                  label: const Text('Unfreeze'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

class _WarningsPage extends StatelessWidget {
  const _WarningsPage();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthorityProvider>();
    final warningsList = provider.warnings;

    return _Section(
      title: 'Active warnings and freezes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historical log of regulatory oversight warnings issued under your clinical authority.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          warningsList.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No warning records logged.', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: warningsList.length,
                  itemBuilder: (context, index) {
                    final w = warningsList[index];
                    final String hospitalName = w['hospital_name'] ?? 'Hospital';
                    final String type = w['warning_type'] ?? 'serious';
                    final String reason = w['reason'] ?? '';
                    final bool isActive = w['is_active'] ?? true;
                    final DateTime date = DateTime.tryParse(w['created_at'] ?? '') ?? DateTime.now();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  hospitalName,
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                              ),
                              _StatusPill(
                                label: type.toUpperCase(),
                                color: type.toLowerCase() == 'critical' ? AppColors.error : AppColors.warning,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            reason,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatAge(date),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                              ),
                              _StatusPill(
                                label: isActive ? 'ACTIVE WARNING' : 'RESOLVED/PAST',
                                color: isActive ? AppColors.warning : AppColors.textMuted,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

class _RegulationsPage extends StatelessWidget {
  const _RegulationsPage();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Regulation checklist',
      child: Column(
        children: const [
          _ChecklistItem(
            'Respond to new complaints within configured threshold.',
          ),
          _ChecklistItem(
            'Review viewed-but-unanswered cases before auto-escalation.',
          ),
          _ChecklistItem('Issue documented warnings before freeze actions.'),
          _ChecklistItem('Record reactivation decisions and appeal evidence.'),
        ],
      ),
    );
  }
}

class _UsersPage extends StatefulWidget {
  const _UsersPage();

  @override
  State<_UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<_UsersPage> {
  String _search = '';
  String _role = 'all';
  String _status = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  void _refresh() {
    context.read<AdminProvider>().loadUsers(
      search: _search.isEmpty ? null : _search,
      role: _role,
      status: _status,
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    return _Section(
      title: 'User Management',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Search username, email, phone...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryAccent)),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _search = val;
                    });
                    _refresh();
                  },
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                dropdownColor: AppColors.secondaryBackground,
                value: _role,
                style: const TextStyle(color: AppColors.textPrimary),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Roles')),
                  DropdownMenuItem(value: 'patient', child: Text('Patient')),
                  DropdownMenuItem(value: 'hospital', child: Text('Hospital')),
                  DropdownMenuItem(value: 'authority', child: Text('Authority')),
                  DropdownMenuItem(value: 'superadmin', child: Text('Super Admin')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _role = val;
                    });
                    _refresh();
                  }
                },
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                dropdownColor: AppColors.secondaryBackground,
                value: _status,
                style: const TextStyle(color: AppColors.textPrimary),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Status')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'disabled', child: Text('Disabled')),
                  DropdownMenuItem(value: 'frozen', child: Text('Frozen')),
                  DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _status = val;
                    });
                    _refresh();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (adminProv.isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.admin))
          else if (adminProv.users.isEmpty)
            const Center(child: Text('No users found.', style: TextStyle(color: AppColors.textSecondary)))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                dataTextStyle: const TextStyle(color: AppColors.textSecondary),
                columns: const [
                  DataColumn(label: Text('Username')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: adminProv.users.map<DataRow>((u) {
                  final int userId = u['id'];
                  final String username = u['username'] ?? '';
                  final String email = u['email'] ?? '';
                  final String role = u['role'] ?? '';
                  final String accountStatus = u['account_status'] ?? 'active';
                  final bool isActive = u['is_active'] ?? true;
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(username)),
                      DataCell(Text(email)),
                      DataCell(Text(role.toUpperCase())),
                      DataCell(
                        _StatusPill(
                          label: accountStatus.toUpperCase(),
                          color: accountStatus == 'active'
                              ? AppColors.success
                              : accountStatus == 'frozen'
                                  ? AppColors.warning
                                  : AppColors.error,
                        ),
                      ),
                      DataCell(
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                          color: AppColors.secondaryBackground,
                          onSelected: (action) async {
                            if (action == 'toggle') {
                              final success = await context.read<AdminProvider>().modifyUserStatus(userId, 'toggle_active');
                              if (success) _refresh();
                            } else if (action == 'freeze') {
                              final success = await context.read<AdminProvider>().modifyUserStatus(userId, 'freeze');
                              if (success) _refresh();
                            } else if (action == 'unfreeze') {
                              final success = await context.read<AdminProvider>().modifyUserStatus(userId, 'unfreeze');
                              if (success) _refresh();
                            } else if (action == 'block') {
                              final success = await context.read<AdminProvider>().modifyUserStatus(userId, 'block');
                              if (success) _refresh();
                            } else if (action == 'unblock') {
                              final success = await context.read<AdminProvider>().modifyUserStatus(userId, 'unblock');
                              if (success) _refresh();
                            } else if (action == 'warn') {
                              _showWarnDialog(userId);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(isActive ? 'Disable User' : 'Enable User', style: const TextStyle(color: AppColors.textPrimary)),
                            ),
                            if (accountStatus != 'frozen')
                              const PopupMenuItem(
                                value: 'freeze',
                                child: Text('Freeze User', style: TextStyle(color: AppColors.textPrimary)),
                              ),
                            if (accountStatus == 'frozen')
                              const PopupMenuItem(
                                value: 'unfreeze',
                                child: Text('Unfreeze User', style: TextStyle(color: AppColors.textPrimary)),
                              ),
                            if (accountStatus != 'blocked')
                              const PopupMenuItem(
                                value: 'block',
                                child: Text('Block User', style: TextStyle(color: AppColors.textPrimary)),
                              ),
                            if (accountStatus == 'blocked')
                              const PopupMenuItem(
                                value: 'unblock',
                                child: Text('Unblock User', style: TextStyle(color: AppColors.textPrimary)),
                              ),
                            const PopupMenuItem(
                              value: 'warn',
                              child: Text('Warn User', style: TextStyle(color: AppColors.textPrimary)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _showWarnDialog(int userId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: const Text('Send Official Warning', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter reason for warning...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.admin),
            onPressed: () async {
              final reason = controller.text.trim();
              if (reason.isNotEmpty) {
                final nav = Navigator.of(ctx);
                final success = await context.read<AdminProvider>().modifyUserStatus(userId, 'warn', reason: reason);
                if (success) {
                  _refresh();
                  nav.pop();
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _EntityVerificationPage extends StatefulWidget {
  const _EntityVerificationPage();

  @override
  State<_EntityVerificationPage> createState() => _EntityVerificationPageState();
}

class _EntityVerificationPageState extends State<_EntityVerificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadEntityVerification();
    });
  }

  void _refresh() {
    context.read<AdminProvider>().loadEntityVerification();
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final pendingEntities = adminProv.pendingEntities;
    
    final totalPending = pendingEntities.length;
    final hospitalCount = pendingEntities.where((e) => e['entity_type'] == 'hospital').length;
    final authorityCount = pendingEntities.where((e) => e['entity_type'] == 'authority').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Verification Panel',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Review and approve Hospital Admins and Health Authorities.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: _StatCard(title: 'Total Pending', value: totalPending.toString(), color: AppColors.primary)),
            const SizedBox(width: 24),
            Expanded(child: _StatCard(title: 'Hospital Admins', value: hospitalCount.toString(), color: Colors.blue)),
            const SizedBox(width: 24),
            Expanded(child: _StatCard(title: 'Health Authorities', value: authorityCount.toString(), color: Colors.green)),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  'Pending Approvals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Container(
                color: AppColors.secondaryBackground,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Text('Applicant', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 1, child: Text('Role Request', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 1, child: Text('Applied Date', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 1, child: Text('Status', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13))),
                    SizedBox(width: 120, child: Text('Action', textAlign: TextAlign.right, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              if (adminProv.isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.admin)),
                )
              else if (pendingEntities.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('No entities pending verification.', style: TextStyle(color: AppColors.textSecondary))),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingEntities.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final item = pendingEntities[index];
                    final String name = item['name'] ?? item['username'] ?? '';
                    final String email = item['email'] ?? '';
                    final String type = item['entity_type'] ?? '';
                    final String dateJoined = item['date_joined'] ?? 'N/A';
                    final int entityId = item['id'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                                Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: type == 'hospital' ? Colors.blue.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: type == 'hospital' ? Colors.blue.withOpacity(0.3) : Colors.purple.withOpacity(0.3)),
                                ),
                                child: Text(
                                  type.substring(0, 1).toUpperCase() + type.substring(1),
                                  style: TextStyle(
                                    color: type == 'hospital' ? Colors.blue : Colors.purple,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              dateJoined.split('T')[0], // simplistic date format handling
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                ),
                                child: const Text(
                                  'Pending',
                                  style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => _ReviewDetailsPage(
                                        entityType: type,
                                        entityId: entityId,
                                        onRefresh: _refresh,
                                      ),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                child: const Text('View Details', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ReviewDetailsPage extends StatefulWidget {
  final String entityType;
  final int entityId;
  final VoidCallback onRefresh;

  const _ReviewDetailsPage({required this.entityType, required this.entityId, required this.onRefresh});

  @override
  State<_ReviewDetailsPage> createState() => _ReviewDetailsPageState();
}

class _ReviewDetailsPageState extends State<_ReviewDetailsPage> {
  final _reasonController = TextEditingController();
  late Future<Map<String, dynamic>?> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadDetails();
  }

  Future<Map<String, dynamic>?> _loadDetails() async {
    await Future.microtask(() {});
    if (!mounted) return null;
    return context.read<AdminProvider>().loadEntityVerificationDetail(widget.entityType, widget.entityId);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    
    String finalUrl = urlString;
    if (finalUrl.startsWith('/')) {
      finalUrl = 'http://127.0.0.1:8000$finalUrl';
    }
    
    final uri = Uri.tryParse(finalUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open document')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // DO NOT use context.watch here to avoid infinite rebuilds!
    final adminProv = context.read<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Review Details', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.admin));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Failed to load details.', style: TextStyle(color: AppColors.error)));
          }

          final data = snapshot.data!;
          final user = data['user'] ?? {};
          final verification = data['verification'] ?? {};
          
          final addressLine1 = user['address_line_1'] ?? '';
          final addressLine2 = user['address_line_2'] ?? '';
          final address = '$addressLine1 $addressLine2'.trim();

          final isApproved = data['is_approved'] == true;
          
          List<Map<String, dynamic>> documents = [];
          if (data['documents'] != null) {
             documents = List<Map<String, dynamic>>.from(data['documents']);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Text('Pending Approvals', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
                    const Text('Review Details', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _DetailSection(
                            title: 'Account Details',
                            fields: [
                              _DetailField('USERNAME', user['username'] ?? ''),
                              _DetailField('ROLE', widget.entityType.toUpperCase()),
                              _DetailField('EMAIL', user['email'] ?? ''),
                              _DetailField('PHONE', user['phone_number'] ?? '-'),
                              _DetailField('ADDRESS', address.isEmpty ? '-' : address, isFullWidth: true),
                              _DetailField('CITY', user['city'] ?? '-'),
                              _DetailField('STATE', user['state'] ?? '-'),
                              _DetailField('PINCODE', user['pincode'] ?? '-'),
                              _DetailField('REGISTERED', user['date_joined']?.split('T')[0] ?? '-'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _DetailSection(
                            title: widget.entityType == 'authority' ? 'Authority Details' : 'Hospital Details',
                            fields: widget.entityType == 'authority' ? [
                              _DetailField('AUTHORITY NAME', user['first_name'] ?? '-'),
                              _DetailField('AUTHORITY TYPE', verification['authority_type'] ?? '-'),
                              _DetailField('DEPARTMENT', verification['department'] ?? '-'),
                              _DetailField('JURISDICTION LEVEL', verification['jurisdiction_level'] ?? '-'),
                              _DetailField('JURISDICTION STATE', verification['jurisdiction_state'] ?? '-'),
                              _DetailField('JURISDICTION DISTRICT', verification['jurisdiction_district'] ?? '-'),
                              _DetailField('OFFICE ADDRESS', verification['office_address'] ?? '-', isFullWidth: true),
                            ] : [
                              _DetailField('HOSPITAL NAME', user['first_name'] ?? '-'),
                              _DetailField('REGISTRATION NUMBER', verification['registration_number'] ?? '-'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                const SizedBox(height: 16),
                                if (documents.isEmpty)
                                  const Text('No documents uploaded.', style: TextStyle(color: AppColors.textSecondary))
                                else
                                  ...documents.map((doc) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      onTap: () => _launchUrl(doc['url']),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppColors.border),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.description, color: Colors.blue, size: 20),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(doc['label'] ?? 'Document', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                                  const Text('Click to preview', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.open_in_new, color: AppColors.textSecondary, size: 16),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )).toList(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                const SizedBox(height: 16),
                                if (isApproved)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    color: Colors.green,
                                    child: const Center(child: Text('ALREADY APPROVED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                  )
                                else ...[
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                                    onPressed: () async {
                                      final success = await adminProv.verifyEntity(widget.entityType, widget.entityId, 'approve');
                                      if (success) {
                                        widget.onRefresh();
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _reasonController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText: 'Optional rejection reason',
                                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                                      filled: true,
                                      fillColor: AppColors.secondaryBackground,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                    ),
                                    style: const TextStyle(color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
                                    onPressed: () async {
                                      final success = await adminProv.verifyEntity(widget.entityType, widget.entityId, 'reject', reason: _reasonController.text);
                                      if (success) {
                                        widget.onRefresh();
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: const Text('Reject', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<_DetailField> fields;

  const _DetailSection({required this.title, required this.fields});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 24,
            children: fields.map((field) {
              return SizedBox(
                width: field.isFullWidth ? double.infinity : MediaQuery.of(context).size.width * 0.2, // Rough fraction for 2 columns
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(field.label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(field.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DetailField {
  final String label;
  final String value;
  final bool isFullWidth;

  _DetailField(this.label, this.value, {this.isFullWidth = false});
}


class _AuditLogsPage extends StatefulWidget {
  const _AuditLogsPage();

  @override
  State<_AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<_AuditLogsPage> {
  String _search = '';
  String _role = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  void _refresh() {
    context.read<AdminProvider>().loadUsers(
      search: _search.isEmpty ? null : _search,
      role: _role,
      status: 'all', // For audit logs, show all
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    return _Section(
      title: 'Audit Logs & User Activity',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Search username, email...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryAccent)),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _search = val;
                    });
                    _refresh();
                  },
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                dropdownColor: AppColors.secondaryBackground,
                value: _role,
                style: const TextStyle(color: AppColors.textPrimary),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Roles')),
                  DropdownMenuItem(value: 'patient', child: Text('Patient')),
                  DropdownMenuItem(value: 'hospital', child: Text('Hospital')),
                  DropdownMenuItem(value: 'authority', child: Text('Authority')),
                ],
                onChanged: (val) {
                  setState(() => _role = val!);
                  _refresh();
                },
                underline: const SizedBox(),
                icon: const Icon(Icons.filter_list, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (adminProv.isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.admin))
          else if (adminProv.users.isEmpty)
            const Center(child: Text('No users found.', style: TextStyle(color: AppColors.textSecondary)))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                dataTextStyle: const TextStyle(color: AppColors.textSecondary),
                columns: const [
                  DataColumn(label: Text('User')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: adminProv.users.map<DataRow>((u) {
                  final idStr = u['id']?.toString() ?? '0';
                  final id = int.tryParse(idStr) ?? 0;
                  final name = u['username']?.toString() ?? 'Unknown';
                  final role = u['role']?.toString() ?? '';
                  final status = u['account_status']?.toString() ?? 'active';

                  Color statusColor = Colors.green;
                  if (status == 'frozen' || status == 'suspended') statusColor = Colors.orange;
                  if (status == 'blocked' || status == 'banned') statusColor = Colors.red;

                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.surface,
                              child: const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 8),
                            Text(name, style: const TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(role.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textPrimary)),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      DataCell(
                        ElevatedButton.icon(
                          icon: const Icon(Icons.timeline, size: 14),
                          label: const Text('View Activity'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.admin,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _UserActivityPage(userId: id),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserActivityPage extends StatefulWidget {
  final int userId;
  const _UserActivityPage({required this.userId});

  @override
  State<_UserActivityPage> createState() => _UserActivityPageState();
}

class _UserActivityPageState extends State<_UserActivityPage> {
  late Future<Map<String, dynamic>?> _activityFuture;

  @override
  void initState() {
    super.initState();
    _activityFuture = _loadActivity();
  }

  Future<Map<String, dynamic>?> _loadActivity() async {
    await Future.microtask(() {});
    if (!mounted) return null;
    return context.read<AdminProvider>().loadUserActivity(widget.userId);
  }

  void _refresh() {
    setState(() {
      _activityFuture = _loadActivity();
    });
  }

  Future<void> _performAction(String actionName) async {
    final success = await context.read<AdminProvider>().performUserAction(widget.userId, actionName);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action $actionName executed successfully.')));
        _refresh();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to execute action.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('User Activity Logs', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _activityFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.admin));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Failed to load activity logs.', style: TextStyle(color: AppColors.error)));
          }

          final data = snapshot.data!;
          final user = data['user'] ?? {};
          final List activities = data['activities'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.secondaryBackground,
                        child: const Icon(Icons.person, size: 30, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['username'] ?? 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text('Role: ${(user['role'] ?? 'Unknown').toString().toUpperCase()}', style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      // Actions
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.ac_unit, size: 16),
                            label: const Text('Freeze'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                            onPressed: () => _performAction('freeze'),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.block, size: 16),
                            label: const Text('Block'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () => _performAction('block'),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.warning, size: 16),
                            label: const Text('Warn'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow.shade700, foregroundColor: Colors.white),
                            onPressed: () => _performAction('warn'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Activity Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                if (activities.isEmpty)
                  const Text('No activity found for this user.', style: TextStyle(color: AppColors.textSecondary))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final act = activities[index];
                      final type = act['type'] ?? 'Action';
                      final desc = act['description'] ?? '';
                      final timestamp = act['timestamp'] ?? '';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.history, color: AppColors.admin, size: 20),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(type, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Text(timestamp.toString().replaceAll('T', ' ').split('.')[0], style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SecurityMonitoringPage extends StatefulWidget {
  const _SecurityMonitoringPage();

  @override
  State<_SecurityMonitoringPage> createState() => _SecurityMonitoringPageState();
}

class _SecurityMonitoringPageState extends State<_SecurityMonitoringPage> {
  String _severity = 'all';
  String _resolved = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadSecurityAlerts();
    });
  }

  void _refresh() {
    context.read<AdminProvider>().loadSecurityAlerts(
      severity: _severity,
      resolved: _resolved,
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    return Column(
      children: [
        _MetricGrid(
          accent: AppColors.error,
          metrics: [
            _Metric(
              'Open Alerts',
              adminProv.openAlertsCount.toString(),
              Icons.gpp_maybe_outlined,
              AppColors.errorBg,
            ),
            _Metric(
              'Critical alerts',
              adminProv.criticalAlertsCount.toString(),
              Icons.warning_amber_outlined,
              AppColors.errorBg,
            ),
            _Metric(
              'Alerts (24h)',
              adminProv.recentAlertsCount24h.toString(),
              Icons.timer_outlined,
              AppColors.surface,
            ),
            _Metric(
              'Security Health',
              adminProv.criticalAlertsCount > 0 ? 'CRITICAL' : (adminProv.openAlertsCount > 0 ? 'WARNING' : 'HEALTHY'),
              Icons.shield_outlined,
              adminProv.criticalAlertsCount > 0
                  ? AppColors.errorBg
                  : (adminProv.openAlertsCount > 0 ? AppColors.warningBg : AppColors.successBg),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Section(
          title: 'Platform Security Alerts',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      DropdownButton<String>(
                        dropdownColor: AppColors.secondaryBackground,
                        value: _severity,
                        style: const TextStyle(color: AppColors.textPrimary),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Severities')),
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                          DropdownMenuItem(value: 'critical', child: Text('Critical')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _severity = val;
                            });
                            _refresh();
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        dropdownColor: AppColors.secondaryBackground,
                        value: _resolved,
                        style: const TextStyle(color: AppColors.textPrimary),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All States')),
                          DropdownMenuItem(value: 'open', child: Text('Open')),
                          DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _resolved = val;
                            });
                            _refresh();
                          }
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.security),
                        label: const Text('Initiate Security Scan'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.admin),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final success = await context.read<AdminProvider>().triggerSecurityScan();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(success ? 'Security scan initiated successfully!' : 'Failed to trigger scan.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (adminProv.isLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.admin))
              else if (adminProv.securityAlerts.isEmpty)
                const Center(child: Text('No security alerts recorded.', style: TextStyle(color: AppColors.textSecondary)))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: adminProv.securityAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = adminProv.securityAlerts[index];
                    final int alertId = alert['id'];
                    final String title = alert['title'] ?? '';
                    final String desc = alert['description'] ?? '';
                    final String severity = alert['severity'] ?? 'medium';
                    final String user = alert['user_username'] ?? 'System';
                    final String ip = alert['ip_address'] ?? 'N/A';
                    final bool isResolved = alert['is_resolved'] ?? false;
                    final timestamp = DateTime.tryParse(alert['timestamp'] ?? '') ?? DateTime.now();

                    final severityColor = severity == 'critical'
                        ? AppColors.error
                        : severity == 'high'
                            ? AppColors.error.withValues(alpha: 0.8)
                            : severity == 'medium'
                                ? AppColors.warning
                                : AppColors.success;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.gpp_maybe, color: severityColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 15),
                                ),
                              ),
                              _StatusPill(label: severity.toUpperCase(), color: severityColor),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(desc, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('Target User: $user  |  IP Address: $ip  |  Time: ${_formatAge(timestamp)}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!isResolved)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                                  onPressed: () async {
                                    final success = await context.read<AdminProvider>().resolveSecurityAlert(alertId);
                                    if (success) _refresh();
                                  },
                                  child: const Text('Mark Resolved'),
                                )
                              else
                                Row(
                                  children: [
                                    const Icon(Icons.verified, color: AppColors.success, size: 16),
                                    const SizedBox(width: 4),
                                    Text('Resolved by ${alert['resolved_by_username'] ?? 'Admin'}',
                                        style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecuritySettingsPage extends StatefulWidget {
  const _SecuritySettingsPage();

  @override
  State<_SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<_SecuritySettingsPage> {
  bool _twoFa = false;
  int _timeout = 1209600;
  int _attempts = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<AdminProvider>();
      await prov.loadSecuritySettings();
      setState(() {
        _twoFa = prov.twoFaEnabled;
        _timeout = prov.sessionTimeout;
        _attempts = prov.maxLoginAttempts;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    return _Section(
      title: 'Security Settings',
      child: adminProv.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.admin))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Enforce Multi-Factor Authentication (MFA/2FA)', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text('Force hospital and authority admins to verify OTP during login.', style: TextStyle(color: AppColors.textSecondary)),
                  value: _twoFa,
                  activeThumbColor: AppColors.admin,
                  onChanged: (val) {
                    setState(() {
                      _twoFa = val;
                    });
                  },
                ),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 12),
                const Text('Session Expiration Timeout (seconds)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Slider(
                  value: _timeout.toDouble(),
                  min: 60,
                  max: 2592000,
                  divisions: 100,
                  activeColor: AppColors.admin,
                  label: '${(_timeout / 3600).round()} hours',
                  onChanged: (val) {
                    setState(() {
                      _timeout = val.round();
                    });
                  },
                ),
                Text('Current expiration timeout: ${(_timeout / 3600).toStringAsFixed(1)} hours', style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 12),
                const Text('Max Allowed Failed Login Attempts', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButton<int>(
                  dropdownColor: AppColors.secondaryBackground,
                  value: _attempts,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('3 attempts')),
                    DropdownMenuItem(value: 5, child: Text('5 attempts')),
                    DropdownMenuItem(value: 10, child: Text('10 attempts')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _attempts = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.admin, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await context.read<AdminProvider>().updateSecuritySettings(
                              twoFaEnabled: _twoFa,
                              sessionTimeout: _timeout,
                              maxLoginAttempts: _attempts,
                            );
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(success ? 'Security policy settings saved successfully!' : 'Failed to update settings.')),
                          );
                        }
                      },
                      child: const Text('Save Policy Settings'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}


class _CategoriesPage extends StatefulWidget {
  const _CategoriesPage();

  @override
  State<_CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<_CategoriesPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addCategory() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    if (name.isEmpty) return;

    final success = await context.read<AdminProvider>().addCategory(name, desc);
    if (success && mounted) {
      _nameController.clear();
      _descController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category added successfully')));
      context.read<AdminProvider>().loadCategories(search: _searchQuery);
    }
  }

  void _deleteCategory(int id) async {
    final success = await context.read<AdminProvider>().deleteCategory(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted successfully')));
      context.read<AdminProvider>().loadCategories(search: _searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add New Category Section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category Name', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'e.g. Medical Negligence',
                            hintStyle: const TextStyle(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Description', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Brief description of when to use this category',
                            hintStyle: const TextStyle(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: adminProv.isLoading ? null : _addCategory,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Search Bar
        TextField(
          controller: _searchController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search categories...',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          ),
          onChanged: (val) {
            _searchQuery = val;
            context.read<AdminProvider>().loadCategories(search: val);
          },
        ),
        const SizedBox(height: 24),
        
        // Table Section
        _Section(
          title: 'Categories List',
          child: adminProv.isLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              : adminProv.categories.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No categories found', style: TextStyle(color: AppColors.textSecondary))))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingTextStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12),
                        dataTextStyle: const TextStyle(color: AppColors.textPrimary),
                        columns: const [
                          DataColumn(label: Text('CATEGORY NAME')),
                          DataColumn(label: Text('DESCRIPTION')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: adminProv.categories.map<DataRow>((cat) {
                          final idStr = cat['id']?.toString() ?? '0';
                          final id = int.tryParse(idStr) ?? 0;
                          final name = cat['name']?.toString() ?? 'Unknown';
                          final desc = cat['description']?.toString() ?? '';
                          final isActive = cat['is_active'] == true;

                          return DataRow(
                            cells: [
                              DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(SizedBox(
                                width: 300,
                                child: Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
                              )),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                TextButton(
                                  onPressed: () => _deleteCategory(id),
                                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _PerformancePage extends StatelessWidget {
  const _PerformancePage();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MetricGrid(
          accent: AppColors.admin,
          metrics: const [
            _Metric(
              'Avg Response',
              '18h',
              Icons.speed_outlined,
              AppColors.infoBg,
            ),
            _Metric(
              'Resolution SLA',
              '82%',
              Icons.verified_outlined,
              AppColors.successBg,
            ),
            _Metric(
              'AI Validation',
              '94%',
              Icons.psychology_outlined,
              AppColors.surface,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _Section(
          title: 'System metrics',
          child: _InfoTable(
            headers: ['Area', 'Signal', 'Status', 'Owner'],
            rows: [
              ['Complaint intake', 'Healthy', 'Online', 'Platform'],
              ['Notifications', 'Normal', 'Online', 'Platform'],
              ['Escalations', '11 pending', 'Watch', 'Authority'],
            ],
          ),
        ),
      ],
    );
  }
}

class _SupportPage extends StatefulWidget {
  const _SupportPage();

  @override
  State<_SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<_SupportPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadSupportTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final tickets = provider.supportTickets;
    final isLoading = provider.isLoading;
    final error = provider.errorMessage;

    return _Section(
      title: 'Support Requests',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Manage user inquiries and respond to help tickets.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          
          // Filter Row
          Row(
            children: [
              const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: provider.supportStatusFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Tickets')),
                  DropdownMenuItem(value: 'open', child: Text('Open')),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                ],
                onChanged: (val) {
                  if (val != null) provider.setSupportStatusFilter(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (isLoading && tickets.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (error != null && tickets.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Error: $error', style: const TextStyle(color: Colors.red))))
          else if (tickets.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No support tickets found.', style: TextStyle(color: AppColors.textSecondary)),
            ))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                return _TicketCard(ticket: tickets[index]);
              },
            ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatefulWidget {
  final Map<String, dynamic> ticket;
  const _TicketCard({required this.ticket});

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> {
  final _replyController = TextEditingController();
  bool _isReplying = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.month}/${date.day}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    final user = t['user'] as Map<String, dynamic>? ?? {};
    final username = user['username'] ?? 'User';
    final email = user['email'] ?? '';
    final subject = t['subject'] ?? 'No Subject';
    final message = t['message'] ?? '';
    final status = t['status'] ?? 'unknown';
    final adminReply = t['admin_reply'] ?? '';
    final patientReply = t['patient_reply'] as Map<String, dynamic>?;

    Color statusColor;
    Color statusBgColor;
    if (status == 'open') {
      statusColor = Colors.green[700]!;
      statusBgColor = Colors.green[100]!;
    } else if (status == 'responded' || (adminReply.isNotEmpty && patientReply == null)) {
      statusColor = Colors.blue[700]!;
      statusBgColor = Colors.blue[100]!;
    } else {
      statusColor = Colors.grey[700]!;
      statusBgColor = Colors.grey[200]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'U',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('$username · $email', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    if (t['created_at'] != null)
                      Text(_formatDate(t['created_at']), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Original Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(message),
          ),
          
          // Admin Reply
          if (adminReply.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.only(left: 24),
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Admin Reply:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(adminReply),
                ],
              ),
            ),
          ],
          
          // Patient Reply
          if (patientReply != null) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.only(left: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.green, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Patient Response:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 4),
                  Text(patientReply['message'] ?? ''),
                ],
              ),
            ),
          ],
          
          // Reply Form
          if (status == 'open') ...[
            const SizedBox(height: 16),
            const Text('Reply to User', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _replyController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Type your reply here...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _isReplying
                    ? null
                    : () async {
                        final text = _replyController.text.trim();
                        if (text.isEmpty) return;
                        
                        setState(() => _isReplying = true);
                        final success = await context.read<AdminProvider>().submitSupportReply(t['id'], text);
                        if (mounted) {
                          setState(() => _isReplying = false);
                          if (success) {
                            _replyController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply sent successfully!')));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send reply.')));
                          }
                        }
                      },
                child: _isReplying ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send Reply'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleDrawer extends StatelessWidget {
  const _RoleDrawer({
    required this.config,
    required this.activePath,
    required this.onNavigate,
  });

  final _RoleConfig config;
  final String activePath;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    // Resolve the hospital display name from provider if available
    String displayTitle;
    String displaySubtitle;
    if (config.role == OperationalRole.hospital) {
      final hospitalProvider = context.watch<HospitalProvider>();
      displayTitle = hospitalProvider.profile?.hospitalName.isNotEmpty == true
          ? hospitalProvider.profile!.hospitalName
          : context.watch<AuthProvider>().user?.firstName ?? 'Hospital';
      displaySubtitle = hospitalProvider.profile?.hospitalType.isNotEmpty == true
          ? '${hospitalProvider.profile!.hospitalType} · ${config.label}'
          : config.label;
    } else {
      displayTitle = config.displayName;
      displaySubtitle = config.label;
    }

    return Drawer(
      backgroundColor: AppColors.secondaryBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: config.color.withValues(alpha: 0.15),
                    child: Text(
                      displayTitle.isNotEmpty ? displayTitle[0].toUpperCase() : config.initial,
                      style: TextStyle(
                        color: config.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displaySubtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: config.navItems
                    .map(
                      (item) => ListTile(
                        selected: activePath == item.path,
                        selectedTileColor: config.color.withValues(alpha: 0.08),
                        leading: Icon(item.icon, color: activePath == item.path ? config.color : AppColors.textSecondary),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            color: activePath == item.path ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: activePath == item.path ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate(item.path);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            ListTile(
              leading: const Icon(Icons.logout_outlined, color: AppColors.textSecondary),
              title: const Text('Logout', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () async {
                final auth = context.read<AuthProvider>();
                final router = GoRouter.of(context);
                Navigator.pop(context);
                await auth.logout();
                router.replace(RoutePaths.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String role;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.health_and_safety_outlined, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics, required this.accent});

  final List<_Metric> metrics;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 940
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            mainAxisExtent: columns == 1 ? 78 : 112,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: metric.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(metric.icon, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          metric.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _RecordList extends StatelessWidget {
  const _RecordList({required this.records, this.onOpenDetail, this.role});

  final List<dynamic> records;
  final ValueChanged<dynamic>? onOpenDetail;
  final OperationalRole? role;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No records found.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: records.map((record) {
        if (record is _ComplaintRecord || record is ComplaintPost || record is HospitalComplaint) {
          return _ComplaintTile(record: record, onOpenDetail: onOpenDetail, role: role);
        }
        final item = record as _AdminQueueRecord;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(item.icon, color: item.color),
          title: Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          subtitle: Text(item.subtitle, style: const TextStyle(color: AppColors.textSecondary)),
          trailing: _StatusPill(label: item.status, color: item.color),
        );
      }).toList(),
    );
  }
}

class _ComplaintTile extends StatelessWidget {
  const _ComplaintTile({required this.record, this.onOpenDetail, this.role});

  final dynamic record;
  final ValueChanged<dynamic>? onOpenDetail;
  final OperationalRole? role;

  @override
  Widget build(BuildContext context) {
    final String title;
    final String hospital;
    final String category;
    final String statusLabel;
    final String severityLabel;
    final String ageText;
    final bool escalated;
    final Color statusColor;

    if (record is ComplaintPost) {
      final post = record as ComplaintPost;
      title = post.title;
      hospital = post.hospitalName;
      category = post.category;
      statusLabel = post.status.label;
      severityLabel = post.severity.label;
      ageText = _formatAge(post.createdAt);
      escalated = post.status == ComplaintStatus.escalated;
      statusColor = _statusColor(post.status.label);
    } else if (record is HospitalComplaint) {
      final comp = record as HospitalComplaint;
      title = comp.title;
      hospital = comp.hospitalName;
      category = comp.category;
      statusLabel = comp.status;
      severityLabel = comp.severity;
      ageText = _formatAge(comp.createdAt);
      escalated = comp.status.toLowerCase() == 'escalated';
      statusColor = _statusColor(comp.status);
    } else {
      final r = record;
      title = r.title;
      hospital = r.hospital;
      category = r.category;
      statusLabel = r.status;
      severityLabel = r.severity;
      ageText = r.age;
      escalated = r.escalated;
      statusColor = _statusColor(r.status);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.assignment_outlined, color: statusColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '$hospital - $category - $ageText',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusPill(label: statusLabel, color: statusColor),
                    _StatusPill(
                      label: severityLabel,
                      color: severityLabel == 'Critical' || severityLabel == 'High'
                          ? AppColors.error
                          : severityLabel == 'Medium'
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                    if (escalated)
                      const _StatusPill(
                        label: 'Escalated',
                        color: AppColors.error,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              // Hospital: navigate to full ComplaintDetailScreen
              if (role == OperationalRole.hospital && (record is ComplaintPost || record is HospitalComplaint)) {
                final int id = record is ComplaintPost ? (record as ComplaintPost).id : (record as HospitalComplaint).id;
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => _HospitalComplaintWrapper(complaintId: id),
                  ),
                );
              } else if (onOpenDetail != null) {
                onOpenDetail!(record);
              }
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

// Thin wrapper to navigate to the shared complaint detail screen, keeping hospital role context
class _HospitalComplaintWrapper extends StatelessWidget {
  const _HospitalComplaintWrapper({required this.complaintId});
  final int complaintId;
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Builder(builder: (ctx) {
            // Push and immediately replace with complaint detail
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ctx.go('/patient/complaint/$complaintId');
            });
            return const SizedBox.shrink();
          }),
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
        final columns = constraints.maxWidth > 620 ? 2 : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: columns == 1 ? 4.0 : 3.4,
          children: items.entries
              .map(
                (entry) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.textPrimary,
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

class _InfoTable extends StatelessWidget {
  const _InfoTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        dataTextStyle: const TextStyle(color: AppColors.textSecondary),
        columns: headers
            .map((header) => DataColumn(label: Text(header)))
            .toList(),
        rows: rows
            .map(
              (row) => DataRow(
                cells: row.map((cell) => DataCell(Text(cell))).toList(),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.check_circle_outline, color: AppColors.success),
      title: Text(text, style: const TextStyle(color: AppColors.textPrimary)),
    );
  }
}


class _RoleConfig {
  const _RoleConfig({
    required this.role,
    required this.label,
    required this.initial,
    required this.color,
    required this.icon,
    required this.displayName,
    required this.profileLine,
    required this.notificationsPath,
    required this.navItems,
    required this.profileFacts,
  });

  final OperationalRole role;
  final String label;
  final String initial;
  final Color color;
  final IconData icon;
  final String displayName;
  final String profileLine;
  final String notificationsPath;
  final List<_NavItem> navItems;
  final Map<String, String> profileFacts;
}

class _NavItem {
  const _NavItem(this.label, this.path, this.icon);

  final String label;
  final String path;
  final IconData icon;
}

class _Metric {
  const _Metric(this.label, this.value, this.icon, this.background);

  final String label;
  final String value;
  final IconData icon;
  final Color background;
}

class _ComplaintRecord {
  const _ComplaintRecord({
    required this.title,
    required this.hospital,
    required this.category,
    required this.status,
    required this.severity,
    required this.age,
    this.escalated = false,
  });

  final String title;
  final String hospital;
  final String category;
  final String status;
  final String severity;
  final String age;
  final bool escalated;
}

class _AdminQueueRecord {
  const _AdminQueueRecord(
    this.title,
    this.subtitle,
    this.status,
    this.icon,
    this.color,
  );

  final String title;
  final String subtitle;
  final String status;
  final IconData icon;
  final Color color;
}



class _Notice {
  const _Notice(
    this.title,
    this.message,
    this.icon,
    this.color, {
    this.unread = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final bool unread;
}

_RoleConfig _roleConfig(OperationalRole role) {
  return switch (role) {
    OperationalRole.hospital => const _RoleConfig(
      role: OperationalRole.hospital,
      label: 'Hospital',
      initial: 'H',
      color: AppColors.hospital,
      icon: Icons.local_hospital_outlined,
      displayName: 'City Care Hospital',
      profileLine: 'Approved provider - District North',
      notificationsPath: RoutePaths.hospitalNotifications,
      navItems: [
        _NavItem(
          'Dashboard',
          RoutePaths.hospitalDashboard,
          Icons.dashboard_outlined,
        ),
        _NavItem(
          'Complaints',
          RoutePaths.hospitalComplaints,
          Icons.assignment_outlined,
        ),
        _NavItem('Public Feed', RoutePaths.hospitalFeed, Icons.forum_outlined),
        _NavItem('Chat', RoutePaths.hospitalChat, Icons.chat_bubble_outline),
        _NavItem('Profile', RoutePaths.hospitalProfile, Icons.badge_outlined),
        _NavItem(
          'Notifications',
          RoutePaths.hospitalNotifications,
          Icons.notifications_outlined,
        ),
        _NavItem(
          'Settings',
          RoutePaths.hospitalSettings,
          Icons.settings_outlined,
        ),
      ],
      profileFacts: {
        'License': 'MV-HSP-2026-014',
        'Email': 'care@citycare.example',
        'Authority': 'District Health Authority',
        'Status': 'Approved',
      },
    ),
    OperationalRole.authority => const _RoleConfig(
      role: OperationalRole.authority,
      label: 'Authority',
      initial: 'A',
      color: AppColors.authority,
      icon: Icons.policy_outlined,
      displayName: 'District Health Authority',
      profileLine: 'Jurisdiction: North District',
      notificationsPath: RoutePaths.authorityNotifications,
      navItems: [
        _NavItem(
          'Dashboard',
          RoutePaths.authorityDashboard,
          Icons.dashboard_outlined,
        ),
        _NavItem(
          'Complaints',
          RoutePaths.authorityComplaints,
          Icons.assignment_late_outlined,
        ),
        _NavItem(
          'Escalations',
          RoutePaths.authorityEscalations,
          Icons.priority_high_outlined,
        ),
        _NavItem(
          'Hospitals',
          RoutePaths.authorityHospitals,
          Icons.local_hospital_outlined,
        ),
        _NavItem(
          'Warnings',
          RoutePaths.authorityWarnings,
          Icons.warning_amber_outlined,
        ),
        _NavItem('Public Feed', RoutePaths.authorityFeed, Icons.forum_outlined),
        _NavItem('Chat', RoutePaths.authorityChat, Icons.chat_bubble_outline),
        _NavItem('Profile', RoutePaths.authorityProfile, Icons.badge_outlined),
        _NavItem(
          'Notifications',
          RoutePaths.authorityNotifications,
          Icons.notifications_outlined,
        ),
        _NavItem(
          'Settings',
          RoutePaths.authoritySettings,
          Icons.settings_outlined,
        ),
        _NavItem(
          'Regulations',
          RoutePaths.authorityRegulations,
          Icons.rule_folder_outlined,
        ),
      ],
      profileFacts: {
        'Jurisdiction': 'North District',
        'Response Threshold': '48 hours',
        'Warning Threshold': '3 active warnings',
        'Status': 'Active',
      },
    ),
    OperationalRole.admin => const _RoleConfig(
      role: OperationalRole.admin,
      label: 'Super Admin',
      initial: 'S',
      color: AppColors.admin,
      icon: Icons.admin_panel_settings_outlined,
      displayName: 'MedVoice Governance',
      profileLine: 'Platform oversight and account governance',
      notificationsPath: RoutePaths.adminNotifications,
      navItems: [
        _NavItem(
          'Dashboard',
          RoutePaths.adminDashboard,
          Icons.dashboard_outlined,
        ),
        _NavItem(
          'Entity Verification',
          RoutePaths.adminEntityVerification,
          Icons.how_to_reg_outlined,
        ),
        _NavItem(
          'User Management',
          RoutePaths.adminUsers,
          Icons.group_outlined,
        ),
        _NavItem(
          'Audit Logs',
          RoutePaths.adminAuditLogs,
          Icons.analytics_outlined,
        ),
        _NavItem(
          'Security Monitoring',
          RoutePaths.adminSecurityMonitoring,
          Icons.gpp_maybe_outlined,
        ),
        _NavItem(
          'Security Settings',
          RoutePaths.adminSecuritySettings,
          Icons.security_outlined,
        ),
        _NavItem(
          'Categories',
          RoutePaths.adminCategories,
          Icons.category_outlined,
        ),
        _NavItem(
          'Performance',
          RoutePaths.adminPerformance,
          Icons.monitor_heart_outlined,
        ),
        _NavItem(
          'Support',
          RoutePaths.adminSupport,
          Icons.support_agent_outlined,
        ),
        _NavItem(
          'Notifications',
          RoutePaths.adminNotifications,
          Icons.notifications_outlined,
        ),
        _NavItem('Profile', RoutePaths.adminProfile, Icons.badge_outlined),
        _NavItem('Settings', RoutePaths.adminSettings, Icons.settings_outlined),
      ],
      profileFacts: {
        'Scope': 'Global platform',
        'Approvals': 'Hospital and authority users',
        'Security': 'Session and account controls',
        'Status': 'Active',
      },
    ),
  };
}

String _pageTitle(OperationalPage page) {
  return switch (page) {
    OperationalPage.dashboard => 'Dashboard',
    OperationalPage.complaints => 'Complaints',
    OperationalPage.feed => 'Community Feed',
    OperationalPage.reports => 'Reports',
    OperationalPage.chat => 'Chat',
    OperationalPage.profile => 'Profile',
    OperationalPage.notifications => 'Notifications',
    OperationalPage.settings => 'System Settings',
    OperationalPage.escalations => 'Escalated Complaints',
    OperationalPage.hospitals => 'Hospitals',
    OperationalPage.warnings => 'Warnings',
    OperationalPage.regulations => 'Regulations',
    OperationalPage.approvals => 'Approve Users',
    OperationalPage.users => 'Users',
    OperationalPage.categories => 'Categories',
    OperationalPage.performance => 'Performance',
    OperationalPage.support => 'Support',
    OperationalPage.entityVerification => 'Entity Verification',
    OperationalPage.auditLogs => 'Audit Logs',
    OperationalPage.securityMonitoring => 'Security Monitoring',
    OperationalPage.securitySettings => 'Security Settings',
  };
}

String _pageSubtitle(OperationalRole role, OperationalPage page) {
  if (page == OperationalPage.dashboard) {
    return switch (role) {
      OperationalRole.hospital =>
        'Track assigned complaints, responses, notifications, and freeze status.',
      OperationalRole.authority =>
        'Monitor jurisdiction hospitals, escalations, warnings, and oversight actions.',
      OperationalRole.admin =>
        'Govern approvals, user activity, support tickets, categories, and platform health.',
    };
  }
  return switch (page) {
    OperationalPage.complaints =>
      'Filter, review, and act on complaint records using the same states as Django.',
    OperationalPage.feed =>
      'Read public complaint activity across the MedVoice community.',
    OperationalPage.reports =>
      'Review complaint performance and export-ready summaries.',
    OperationalPage.chat =>
      'Continue patient, hospital, and authority conversations.',
    OperationalPage.profile =>
      'View verified account and jurisdiction details.',
    OperationalPage.notifications =>
      'Review alerts and mark important items as read.',
    OperationalPage.settings =>
      'Manage module preferences, alert thresholds, and security.',
    OperationalPage.escalations =>
      'Investigate overdue or unresolved complaints.',
    OperationalPage.hospitals =>
      'Manage hospitals in the authority jurisdiction.',
    OperationalPage.warnings =>
      'Issue and review warnings, freezes, and reactivation actions.',
    OperationalPage.regulations => 'Reference response and oversight rules.',
    OperationalPage.approvals =>
      'Review pending hospital and authority registrations.',
    OperationalPage.users =>
      'Audit patients, hospitals, authorities, and account status.',
    OperationalPage.categories =>
      'Maintain complaint categories used by patients.',
    OperationalPage.performance =>
      'Track operational and system health metrics.',
    OperationalPage.support =>
      'Respond to support tickets and patient replies.',
    OperationalPage.entityVerification => 'Review hospital and authority registration documents.',
    OperationalPage.auditLogs => 'Audit administrative operations and governance actions.',
    OperationalPage.securityMonitoring => 'Track suspicious activities, failed logins, and alerts.',
    OperationalPage.securitySettings => 'Manage platform security policy and access controls.',
    OperationalPage.dashboard => '',
  };
}

Color _statusColor(String status) {
  return switch (status) {
    'Resolved' => AppColors.success,
    'Responded' => AppColors.authBlue600,
    'Review' => AppColors.warning,
    'Escalated' => AppColors.error,
    _ => AppColors.textSecondary,
  };
}

const List<_ComplaintRecord> _complaints = [
  _ComplaintRecord(
    title: 'Delayed discharge paperwork',
    hospital: 'City Care Hospital',
    category: 'Administration',
    status: 'Review',
    severity: 'High',
    age: '3h ago',
  ),
  _ComplaintRecord(
    title: 'Billing mismatch after procedure',
    hospital: 'Metro General',
    category: 'Billing',
    status: 'Escalated',
    severity: 'Critical',
    age: '2d ago',
    escalated: true,
  ),
  _ComplaintRecord(
    title: 'Emergency desk response delay',
    hospital: 'City Care Hospital',
    category: 'Emergency Care',
    status: 'New',
    severity: 'Critical',
    age: '6h ago',
  ),
  _ComplaintRecord(
    title: 'Ward sanitation follow-up',
    hospital: 'Sunrise Medical',
    category: 'Sanitation',
    status: 'Responded',
    severity: 'Medium',
    age: '1d ago',
  ),
  _ComplaintRecord(
    title: 'Pharmacy queue mismanagement',
    hospital: 'City Care Hospital',
    category: 'Pharmacy',
    status: 'Resolved',
    severity: 'Medium',
    age: '4d ago',
  ),
  _ComplaintRecord(
    title: 'Unanswered lab report request',
    hospital: 'Metro General',
    category: 'Diagnostics',
    status: 'Escalated',
    severity: 'High',
    age: '3d ago',
    escalated: true,
  ),
];

const List<_AdminQueueRecord> _adminQueue = [
  _AdminQueueRecord(
    'Hospital approval pending',
    'Lakeside Hospital uploaded license and accreditation documents.',
    'Review',
    Icons.how_to_reg_outlined,
    AppColors.authBlue600,
  ),
  _AdminQueueRecord(
    'Support ticket awaiting reply',
    'Patient asked about complaint privacy and anonymous display.',
    'Open',
    Icons.support_agent_outlined,
    AppColors.warning,
  ),
  _AdminQueueRecord(
    'Freeze appeal received',
    'Metro General submitted evidence for account reactivation.',
    'Urgent',
    Icons.gavel_outlined,
    AppColors.error,
  ),
];





const List<_Notice> _adminNotifications = [
  _Notice(
    'Approval queue updated',
    'Three new users need verification.',
    Icons.how_to_reg_outlined,
    AppColors.authBlue600,
    unread: true,
  ),
  _Notice(
    'Support reply pending',
    'A patient replied to an admin support ticket.',
    Icons.support_agent_outlined,
    AppColors.warning,
  ),
  _Notice(
    'Account frozen',
    'A hospital account was frozen by authority action.',
    Icons.block_outlined,
    AppColors.error,
  ),
];

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _formatAge(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inDays > 365) {
    return '${(difference.inDays / 365).floor()}y ago';
  } else if (difference.inDays > 30) {
    return '${(difference.inDays / 30).floor()}mo ago';
  } else if (difference.inDays > 0) {
    return '${difference.inDays}d ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}h ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}m ago';
  } else {
    return 'just now';
  }
}

// Hospital Profile Page
class _ProfilePage extends StatelessWidget {
  const _ProfilePage({required this.role});

  final OperationalRole role;

  @override
  Widget build(BuildContext context) {
    if (role == OperationalRole.admin) {
      return const _AdminProfileView();
    }
    
    final provider = context.watch<HospitalProvider>();

    // Pull‑to‑refresh support
    return RefreshIndicator(
      onRefresh: () async => provider.loadProfile(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _Section(
            title: 'Hospital Profile',
            child: _buildProfileContent(provider),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(HospitalProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: provider.retryProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final profile = provider.profile;
    if (profile == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No profile data available.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final items = {
      'Hospital Name': profile.hospitalName,
      'Email': profile.email,
      'License Number': profile.licenseNumber,
      'Contact Number': profile.contactNumber,
      'Approval Status': profile.status,
      'Freeze Status': profile.status == 'frozen' ? 'Frozen' : 'Active',
    };

    return _InfoGrid(items: items);
  }
}

class _AdminProfileView extends StatefulWidget {
  const _AdminProfileView();

  @override
  State<_AdminProfileView> createState() => _AdminProfileViewState();
}

class _AdminProfileViewState extends State<_AdminProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadProfile();
    });
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      final month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1];
      final ampm = date.hour >= 12 ? 'PM' : 'AM';
      var hour = date.hour % 12;
      if (hour == 0) hour = 12;
      final minute = date.minute.toString().padLeft(2, '0');
      return '$month ${date.day.toString().padLeft(2, '0')}, ${date.year} ${hour.toString().padLeft(2, '0')}:$minute $ampm';
    } catch (_) {
      return isoString;
    }
  }

  String _formatDateOnly(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      final month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1];
      return '$month ${date.day.toString().padLeft(2, '0')}, ${date.year}';
    } catch (_) {
      return isoString;
    }
  }

  BoxDecoration _gradientDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final profileData = provider.profileData;

    return RefreshIndicator(
      onRefresh: () => provider.loadProfile(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs placeholder (Profile Overview)
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text('Profile Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            ),

            if (provider.isLoadingProfile && profileData == null)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.primaryAccent)))
            else if (provider.profileErrorMessage != null && profileData == null)
              Center(child: Text(provider.profileErrorMessage!, style: const TextStyle(color: Colors.redAccent)))
            else if (profileData != null)
              _buildContent(profileData),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>? ?? {};
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    final permissions = List<String>.from(data['permissions'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Profile Overview Card
        Container(
          decoration: _gradientDecoration(),
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.only(bottom: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 4),
                      color: Colors.white.withOpacity(0.1),
                      image: user['photo'] != null ? DecorationImage(image: NetworkImage(user['photo']), fit: BoxFit.cover) : null,
                    ),
                    child: user['photo'] == null ? const Icon(Icons.person, color: Colors.white, size: 40) : null,
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            (user['first_name']?.isNotEmpty == true || user['last_name']?.isNotEmpty == true) 
                                ? '${user['first_name']} ${user['last_name']}'.trim() 
                                : '${user['username']}',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: const Text('SUPER ADMIN', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${user['email']}', style: TextStyle(color: Colors.blue[200], fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.verified_user, color: Colors.greenAccent, size: 16),
                          const SizedBox(width: 4),
                          const Text('Full Platform Access', style: TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit, size: 18, color: Color(0xFF1E3A8A)),
                label: const Text('Edit Profile', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),

        const Text('System Activity Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),

        // 2. System Activity Overview
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Users', Icons.group, Colors.blue, '${stats['total_users']}', 'Active patients', Icons.trending_up)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Pending Approvals', Icons.pending_actions, Colors.amber, '${stats['pending_approvals']}', 'Requiring attention', null)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Total Complaints', Icons.report_problem, Colors.redAccent, '${stats['total_complaints']}', '${stats['urgent_complaints']} urgent flags', Icons.warning)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Investigations', Icons.search_off, Colors.indigoAccent, '-', 'Active investigations', null)),
          ],
        ),
        const SizedBox(height: 24),

        // 3. Account Information & Security
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: _gradientDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Account Information', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildAccountRow('LEGAL NAME', (user['first_name']?.isNotEmpty == true || user['last_name']?.isNotEmpty == true) ? '${user['first_name']} ${user['last_name']}'.trim() : 'Not set'),
                          _buildAccountRow('USERNAME', '${user['username']}'),
                          _buildAccountRow('EMAIL ADDRESS', '${user['email']}'),
                          _buildAccountRow('LAST LOGIN', _formatDate(user['last_login'])),
                          _buildAccountRow('CREATED DATE', _formatDateOnly(user['date_joined']), isLast: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Container(
                decoration: _gradientDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Security & Access', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.shield, color: Colors.greenAccent, size: 14),
                                SizedBox(width: 4),
                                Text('SECURE', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ENABLED PERMISSIONS', style: TextStyle(color: Colors.blue[200], fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: permissions.map((p) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Text(p, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                            )).toList(),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.key, color: Colors.blueAccent),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        Text('Last changed ${_formatDateOnly(user['last_login'])}', style: TextStyle(color: Colors.blue[200], fontSize: 10, fontStyle: FontStyle.italic)),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Change', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, IconData icon, Color color, String value, String subtitle, IconData? subtitleIcon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _gradientDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: Colors.blue[200], fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              if (subtitleIcon != null) ...[
                Icon(subtitleIcon, color: color, size: 14),
                const SizedBox(width: 4),
              ],
              Text(subtitle, style: TextStyle(color: subtitleIcon != null ? color : Colors.blue[200], fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: !isLast ? Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1), style: BorderStyle.solid)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.blue[200], fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: value == 'Not set' ? Colors.white.withOpacity(0.5) : Colors.white, fontSize: 14, fontWeight: FontWeight.w500, fontStyle: value == 'Not set' ? FontStyle.italic : null)),
        ],
      ),
    );
  }
}
