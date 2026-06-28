import re

file_path = r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medvoice_flutter\lib\features\operations\presentation\screens\operational_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

start_str = "class _AuditLogsPage extends StatefulWidget {"
end_str = "class _SecurityMonitoringPage extends StatefulWidget {"

start_idx = content.find(start_str)
end_idx = content.find(end_str)

if start_idx == -1 or end_idx == -1:
    print(f"Could not find bounds. start: {start_idx}, end: {end_idx}")
else:
    old_class = content[start_idx:end_idx]
    
    new_class = """class _AuditLogsPage extends StatefulWidget {
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
                  final id = u['id'] as int;
                  final name = u['username'] ?? '';
                  final role = u['role'] ?? '';
                  final status = u['account_status'] ?? 'active';

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

"""
    content = content.replace(old_class, new_class)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Patched screen successfully.")
