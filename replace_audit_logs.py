import sys

with open(r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medvoice_flutter\lib\features\operations\presentation\screens\operational_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

start_idx = -1
end_idx = -1
for i, l in enumerate(lines):
    if l.startswith('class _AuditLogsPage'):
        start_idx = i
    if l.startswith('class _SecurityMonitoringPage'):
        end_idx = i
        break

if start_idx != -1 and end_idx != -1:
    before = lines[:start_idx]
    after = lines[end_idx:]
    
    new_block = r"""class _AuditLogsPage extends StatefulWidget {
  const _AuditLogsPage();

  @override
  State<_AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<_AuditLogsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Map<dynamic, dynamic>? _selectedUser;
  Map<String, dynamic>? _userActivityData;
  bool _isLoadingActivity = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _searchUsers(String query) {
    context.read<AdminProvider>().loadUsers(search: query.isEmpty ? null : query);
  }

  Future<void> _loadUserActivity(Map<dynamic, dynamic> user) async {
    setState(() {
      _selectedUser = user;
      _isLoadingActivity = true;
    });
    final data = await context.read<AdminProvider>().fetchUserActivity(user['id']);
    if (mounted) {
      setState(() {
        _userActivityData = data;
        _isLoadingActivity = false;
      });
    }
  }

  void _showWarnDialog(int userId, String username) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFB923C).withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFB923C), size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text('Warn $username', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Send an official warning to this user.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 14),
          TextField(controller: controller, maxLines: 3, style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'Enter warning message...', filled: true, fillColor: AppColors.secondaryBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFB923C), foregroundColor: Colors.white),
            onPressed: () async { final msg = controller.text.trim(); if (msg.isEmpty) return; final nav = Navigator.of(ctx); final ok = await context.read<AdminProvider>().executeUserAction(userId, 'warn', reason: msg); if (ok) { _loadUserActivity(_selectedUser!); nav.pop(); } },
            child: const Text('Send Warning')),
        ],
      ),
    );
  }

  void _showFreezeDialog(int userId, String username) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.ac_unit_rounded, color: Colors.blue, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text("Freeze $username's Account", style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Temporarily disable this account.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 14),
          TextField(controller: controller, maxLines: 3, style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'Reason for freezing...', filled: true, fillColor: AppColors.secondaryBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () async { final nav = Navigator.of(ctx); final ok = await context.read<AdminProvider>().executeUserAction(userId, 'freeze', reason: controller.text.trim()); if (ok) { _loadUserActivity(_selectedUser!); nav.pop(); } },
            child: const Text('Freeze Account')),
        ],
      ),
    );
  }

  void _showBlockDialog(int userId, String username) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.block_rounded, color: AppColors.error, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text('Block $username Permanently', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Permanently ban this user.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 14),
          TextField(controller: controller, maxLines: 3, style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'Reason for blocking...', filled: true, fillColor: AppColors.secondaryBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async { final nav = Navigator.of(ctx); final ok = await context.read<AdminProvider>().executeUserAction(userId, 'block', reason: controller.text.trim()); if (ok) { _loadUserActivity(_selectedUser!); nav.pop(); } },
            child: const Text('Block User')),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'patient': return const Color(0xFF14B8A6);
      case 'hospital': return const Color(0xFF60A5FA);
      case 'authority': return const Color(0xFFA78BFA);
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();

    if (_selectedUser == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('User Activity Logs', style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Search and select a user to view their detailed activity timeline and audit logs.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search username, email, phone...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.secondaryBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryAccent)),
            ),
            onChanged: _searchUsers,
          ),
          const SizedBox(height: 20),
          if (adminProv.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.admin)))
          else if (adminProv.users.isEmpty)
            const Center(child: Text('No users found.', style: TextStyle(color: AppColors.textSecondary)))
          else
            Expanded(
              child: ListView.builder(
                itemCount: adminProv.users.length,
                itemBuilder: (ctx, i) {
                  final u = adminProv.users[i];
                  final role = u['role'] ?? '';
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(backgroundColor: _roleColor(role).withOpacity(0.2), child: Icon(Icons.person, color: _roleColor(role))),
                    title: Text(u['username'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: Text(u['email'] ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    shape: Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.5))),
                    onTap: () => _loadUserActivity(u),
                  );
                },
              ),
            ),
        ],
      );
    }

    final userId = _selectedUser!['id'] as int;
    final username = _selectedUser!['username'] as String? ?? '';
    final role = _selectedUser!['role'] as String? ?? '';
    final accStatus = _userActivityData?['user']?['account_status'] ?? _selectedUser!['account_status'] ?? 'active';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
              onPressed: () => setState(() { _selectedUser = null; _userActivityData = null; }),
            ),
            const Text('Activity Log', style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Text('Viewing activities for @$username', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ),
        const SizedBox(height: 20),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.warning_amber_rounded, size: 18),
                  label: const Text('Warn'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white),
                  onPressed: () => _showWarnDialog(userId, username),
                ),
                const SizedBox(width: 8),
                if (accStatus == 'active')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.ac_unit_rounded, size: 18),
                    label: const Text('Freeze'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                    onPressed: () => _showFreezeDialog(userId, username),
                  )
                else if (accStatus == 'frozen')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                    label: const Text('Reactivate'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
                    onPressed: () async { final ok = await context.read<AdminProvider>().executeUserAction(userId, 'unfreeze'); if (ok) _loadUserActivity(_selectedUser!); },
                  ),
                const SizedBox(width: 8),
                if (accStatus != 'blocked')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.block_rounded, size: 18),
                    label: const Text('Block'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                    onPressed: () => _showBlockDialog(userId, username),
                  )
                else
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                    label: const Text('Unblock'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
                    onPressed: () async { final ok = await context.read<AdminProvider>().executeUserAction(userId, 'unblock'); if (ok) _loadUserActivity(_selectedUser!); },
                  ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _roleColor(role).withOpacity(0.1), border: Border.all(color: _roleColor(role).withOpacity(0.3)), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Text(role.toUpperCase(), style: TextStyle(color: _roleColor(role), fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text('@$username', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        if (_isLoadingActivity)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.admin)))
        else if (_userActivityData != null) ...[
          if ((_userActivityData!['freeze_records'] as List?)?.isNotEmpty ?? false) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), border: Border(bottom: BorderSide(color: AppColors.border))),
                    child: Row(
                      children: const [
                        Icon(Icons.ac_unit_rounded, color: AppColors.error, size: 20),
                        SizedBox(width: 8),
                        Text('Hospital Freeze Records with Pending Appeals', style: TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: (_userActivityData!['freeze_records'] as List).map<Widget>((f) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.error.withOpacity(0.05), border: Border.all(color: AppColors.error.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: f['status'] == 'pending_review' ? Colors.orange.withOpacity(0.2) : AppColors.error.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                        child: Text(f['status_display'] ?? '', style: TextStyle(color: f['status'] == 'pending_review' ? Colors.orange : AppColors.error, fontSize: 10, fontWeight: FontWeight.w700)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Frozen by: ${f['frozen_by_role']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                  if (f['frozen_at'] != null)
                                    Text(f['frozen_at'].toString().split('T')[0], style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(f['reason'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          Container(
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.secondaryBackground, borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), border: Border(bottom: BorderSide(color: AppColors.border))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Timeline', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('${(_userActivityData!['activities'] as List).length} Activities', style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ],
                  ),
                ),
                if ((_userActivityData!['activities'] as List).isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.history_rounded, color: AppColors.textMuted, size: 40),
                          SizedBox(height: 12),
                          Text('No Activity Yet', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                          Text("This user hasn't performed any recorded activities.", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 15, top: 0, bottom: 0,
                          child: Container(width: 2, color: AppColors.border),
                        ),
                        Column(
                          children: (_userActivityData!['activities'] as List).map<Widget>((act) {
                            Color iconColor = AppColors.textSecondary;
                            Color bgColor = AppColors.secondaryBackground;
                            final type = act['type']?.toString() ?? '';
                            if (type == 'Complaint') { iconColor = AppColors.error; bgColor = AppColors.error.withOpacity(0.1); }
                            else if (type == 'Comment') { iconColor = Colors.blue; bgColor = Colors.blue.withOpacity(0.1); }
                            else if (type == 'Like') { iconColor = Colors.orange; bgColor = Colors.orange.withOpacity(0.1); }
                            else if (type == 'Response') { iconColor = Colors.teal; bgColor = Colors.teal.withOpacity(0.1); }
                            else if (type.contains('Warning')) { iconColor = const Color(0xFFEA580C); bgColor = const Color(0xFFEA580C).withOpacity(0.1); }
                            else if (type.contains('Freeze') || type.contains('Frozen')) { iconColor = AppColors.error; bgColor = AppColors.error.withOpacity(0.1); }
                            else if (type == 'Oversight') { iconColor = Colors.indigo; bgColor = Colors.indigo.withOpacity(0.1); }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 2)),
                                    child: Icon(IconData(0xe333, fontFamily: 'MaterialIcons'), color: iconColor, size: 16), // Simplified icon fallback
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(type.toUpperCase(), style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                                              if (act['timestamp'] != null)
                                                Text(act['timestamp'].toString().split('T')[0], style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(act['description'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
"""
    
    with open(r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medvoice_flutter\lib\features\operations\presentation\screens\operational_screen.dart', 'w', encoding='utf-8') as f:
        f.writelines(before)
        f.write(new_block)
        f.writelines(after)
    print("Replaced _AuditLogsPage with timeline view.")
else:
    print("Could not find function boundaries.")
