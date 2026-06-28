import re

def update_dashboard_page(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # The DashboardPage starts with:
    # class _DashboardPage extends StatelessWidget {
    # and ends right before class _ComplaintQueue extends StatelessWidget {
    
    start_str = "class _DashboardPage extends StatelessWidget {"
    start_idx = content.find(start_str)
    if start_idx == -1:
        print("Start not found!")
        return

    end_str = "class _ComplaintQueue extends StatelessWidget {"
    end_idx = content.find(end_str, start_idx)
    if end_idx == -1:
        print("End not found!")
        return
        
    old_dashboard = content[start_idx:end_idx]
    
    new_dashboard = """class _DashboardPage extends StatelessWidget {
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

    final cards = switch (config.role) {
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

"""
    
    new_content = content[:start_idx] + new_dashboard + "\n" + content[end_idx:]
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
        print("Updated operational_screen.dart")

update_dashboard_page(r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medvoice_flutter\lib\features\operations\presentation\screens\operational_screen.dart')
