new_block = '''class _UsersPage extends StatefulWidget {
  const _UsersPage();

  @override
  State<_UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<_UsersPage> {
  String _search = '';
  String _role = 'all';
  String _status = 'all';
  final TextEditingController _searchCtrl = TextEditingController();

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

  void _refresh({int page = 1}) {
    context.read<AdminProvider>().loadUsers(
      search: _search.isEmpty ? null : _search,
      role: _role,
      status: _status,
      page: page,
    );
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
          const Text('Send an official warning. The user will receive a notification.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 14),
          const Text('Warning Message', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(controller: controller, maxLines: 3, style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'Enter warning message...', hintStyle: const TextStyle(color: AppColors.textMuted), filled: true, fillColor: AppColors.secondaryBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFB923C))))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFB923C), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async { final msg = controller.text.trim(); if (msg.isEmpty) return; final nav = Navigator.of(ctx); final ok = await context.read<AdminProvider>().executeUserAction(userId, 'warn', reason: msg); if (ok) { _refresh(); nav.pop(); } },
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
          Expanded(child: Text("Freeze $username account", style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Temporarily disable this account. The user will be logged out and must request reactivation.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 14),
          const Text('Reason for Freezing', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(controller: controller, maxLines: 3, style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'Reason for freezing...', hintStyle: const TextStyle(color: AppColors.textMuted), filled: true, fillColor: AppColors.secondaryBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async { final nav = Navigator.of(ctx); final ok = await context.read<AdminProvider>().executeUserAction(userId, 'freeze', reason: controller.text.trim()); if (ok) { _refresh(); nav.pop(); } },
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
          const Text('Permanently ban this user. Their content will be hidden from the public.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 14),
          const Text('Reason for Blocking', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(controller: controller, maxLines: 3, style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'Reason for blocking...', hintStyle: const TextStyle(color: AppColors.textMuted), filled: true, fillColor: AppColors.secondaryBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async { final nav = Navigator.of(ctx); final ok = await context.read<AdminProvider>().executeUserAction(userId, 'block', reason: controller.text.trim()); if (ok) { _refresh(); nav.pop(); } },
            child: const Text('Block Permanently')),
        ],
      ),
    );
  }

  void _showReactivationModal(int userId, String username, String reason) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFB923C).withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFFB923C), size: 20)),
          const SizedBox(width: 12),
          const Expanded(child: Text('Reactivation Request', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: TextSpan(style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), children: [
            const TextSpan(text: 'User '),
            TextSpan(text: username, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const TextSpan(text: ' has requested account reactivation.'),
          ])),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.secondaryBackground, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('REASON PROVIDED', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text(reason.isEmpty ? 'No reason provided.' : '"$reason"', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontStyle: FontStyle.italic)),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async { final nav = Navigator.of(ctx); final ok = await context.read<AdminProvider>().executeUserAction(userId, 'reactivate'); if (ok) { _refresh(); nav.pop(); } },
            child: const Text('Approve and Reactivate')),
        ],
      ),
    );
  }

  void _showActivity(int userId, String username) async {
    final data = await context.read<AdminProvider>().fetchUserActivity(userId);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.4, expand: false,
        builder: (_, sc) => Column(children: [
          Container(margin: const EdgeInsets.only(top: 10, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
            const Icon(Icons.history_rounded, color: AppColors.admin, size: 20),
            const SizedBox(width: 8),
            Text('Activity - $username', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          ])),
          const Divider(color: AppColors.border, height: 20),
          Expanded(child: data == null
            ? const Center(child: Text('Failed to load activity.', style: TextStyle(color: AppColors.textSecondary)))
            : ListView(controller: sc, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
                if ((data['activities'] as List?)?.isNotEmpty ?? false) ...[
                  const Text('RECENT ACTIVITY', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  ...((data['activities'] as List).take(10).map((a) => _ActivityTile(icon: Icons.touch_app_rounded, iconColor: AppColors.primary, title: a['action'] ?? '', subtitle: a['description'] ?? '', time: a['timestamp'] ?? ''))),
                  const SizedBox(height: 16),
                ],
                if ((data['past_actions'] as List?)?.isNotEmpty ?? false) ...[
                  const Text('ADMIN ACTIONS', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  ...((data['past_actions'] as List).take(10).map((a) => _ActivityTile(icon: Icons.admin_panel_settings_rounded, iconColor: AppColors.admin, title: '${a["action"] ?? ""} by ${a["admin"] ?? ""}', subtitle: a['description'] ?? '', time: a['timestamp'] ?? ''))),
                  const SizedBox(height: 16),
                ],
                if ((data['active_alerts'] as List?)?.isNotEmpty ?? false) ...[
                  const Text('ACTIVE ALERTS', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  ...((data['active_alerts'] as List).map((a) => _ActivityTile(icon: Icons.security_rounded, iconColor: AppColors.error, title: '${a["type"] ?? ""} - ${a["severity"] ?? ""}', subtitle: a['description'] ?? '', time: a['timestamp'] ?? ''))),
                  const SizedBox(height: 24),
                ],
              ])),
        ]),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'patient': return const Color(0xFF14B8A6);
      case 'hospital': return const Color(0xFF60A5FA);
      case 'authority': return const Color(0xFFA78BFA);
      default: return AppColors.admin;
    }
  }

  (Color, String) _statusInfo(Map<dynamic, dynamic> u) {
    final acc = (u['account_status'] ?? 'active') as String;
    final active = u['is_active'] as bool? ?? true;
    final reactivation = u['reactivation_requested'] as bool? ?? false;
    if (acc == 'frozen') return (Colors.blue, 'Frozen');
    if (acc == 'blocked') return (AppColors.error, 'Blocked');
    if (active) return (AppColors.success, 'Active');
    if (reactivation) return (const Color(0xFFFB923C), 'Requesting Activation');
    return (AppColors.textMuted, 'Disabled');
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try { final dt = DateTime.parse(iso).toLocal(); const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']; return '${m[dt.month-1]} ${dt.day}, ${dt.year}'; } catch (_) { return '-'; }
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final users = adminProv.users;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('User Management', style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      const Text('Manage platform users, verify roles, and monitor account security.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Column(children: [
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by username or email...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
              suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); _refresh(); }) : null,
              filled: true, fillColor: AppColors.secondaryBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryAccent)),
            ),
            onChanged: (v) { setState(() => _search = v); _refresh(); },
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Role:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _role, dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(filled: true, fillColor: AppColors.secondaryBackground, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border))),
                items: const [DropdownMenuItem(value: 'all', child: Text('All Roles')), DropdownMenuItem(value: 'patient', child: Text('Patient')), DropdownMenuItem(value: 'hospital', child: Text('Hospital')), DropdownMenuItem(value: 'authority', child: Text('Authority'))],
                onChanged: (v) { if (v != null) { setState(() => _role = v); _refresh(); } },
              ),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Status:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _status, dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(filled: true, fillColor: AppColors.secondaryBackground, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border))),
                items: const [DropdownMenuItem(value: 'all', child: Text('Any Status')), DropdownMenuItem(value: 'active', child: Text('Active')), DropdownMenuItem(value: 'disabled', child: Text('Disabled')), DropdownMenuItem(value: 'reactivation_requested', child: Text('Reactivation Requested'))],
                onChanged: (v) { if (v != null) { setState(() => _status = v); _refresh(); } },
              ),
            ])),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      if (adminProv.isLoading)
        const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.admin, strokeWidth: 2)))
      else if (users.isEmpty)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: const Center(child: Column(children: [Icon(Icons.people_outline_rounded, color: AppColors.textMuted, size: 40), SizedBox(height: 12), Text('No users found matching your criteria.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))])),
        )
      else
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppColors.secondaryBackground, borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(children: const [
                Expanded(flex: 4, child: Text('USERNAME', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1))),
                Expanded(flex: 2, child: Text('ROLE', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1))),
                Expanded(flex: 2, child: Text('STATUS', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1))),
                SizedBox(width: 60, child: Text('REPLIES', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('LAST LOGIN', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1))),
                SizedBox(width: 80, child: Text('ACTIONS', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1), textAlign: TextAlign.right)),
              ]),
            ),
            ...users.asMap().entries.map((entry) {
              final idx = entry.key;
              final u = entry.value as Map;
              final int userId = u['id'];
              final String username = u['username'] ?? '';
              final String firstName = u['first_name'] ?? '';
              final String displayName = firstName.isNotEmpty ? firstName : username;
              final String subLabel = firstName.isNotEmpty ? '@$username' : (u['email'] ?? '');
              final String role = u['role'] ?? '';
              final String accountStatus = u['account_status'] ?? 'active';
              final bool reactivationRequested = u['reactivation_requested'] as bool? ?? false;
              final String reactivationReason = u['reactivation_reason'] ?? '';
              final int replyCount = (u['reply_count'] ?? 0) as int;
              final String? photoUrl = u['photo_url'];
              final bool isLast = idx == users.length - 1;
              final (Color statusColor, String statusLabel) = _statusInfo(u);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.5)))),
                child: Row(children: [
                  Expanded(flex: 4, child: Row(children: [
                    Stack(children: [
                      Container(width: 36, height: 36,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.secondaryBackground, border: Border.all(color: AppColors.border),
                          image: photoUrl != null ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null),
                        child: photoUrl == null ? Icon(Icons.person_outline_rounded, color: _roleColor(role), size: 18) : null),
                      if (reactivationRequested)
                        Positioned(right: 0, top: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 1.5)))),
                    ]),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(displayName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                      Text(subLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 11), overflow: TextOverflow.ellipsis),
                    ])),
                  ])),
                  Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _roleColor(role).withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: _roleColor(role).withOpacity(0.3))),
                    child: Text(role.isEmpty ? '-' : (role[0].toUpperCase() + role.substring(1)), style: TextStyle(color: _roleColor(role), fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center)))),
                  Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.3))),
                    child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)))),
                  SizedBox(width: 60, child: Text('$replyCount', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text(_fmtDate(u['last_login'] as String?), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                  SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    GestureDetector(
                      onTap: () => _showActivity(userId, username),
                      child: Tooltip(message: 'View Activity', child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.history_rounded, color: Colors.blue, size: 16))),
                    ),
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
                      onSelected: (action) async {
                        if (action == 'warn') { _showWarnDialog(userId, username); }
                        else if (action == 'freeze') { _showFreezeDialog(userId, username); }
                        else if (action == 'unfreeze') { final ok = await context.read<AdminProvider>().executeUserAction(userId, 'unfreeze'); if (ok) _refresh(); }
                        else if (action == 'approve_reactivation') { final ok = await context.read<AdminProvider>().executeUserAction(userId, 'reactivate'); if (ok) _refresh(); }
                        else if (action == 'view_request') { _showReactivationModal(userId, username, reactivationReason); }
                        else if (action == 'block') { _showBlockDialog(userId, username); }
                        else if (action == 'unblock') { final ok = await context.read<AdminProvider>().executeUserAction(userId, 'unblock'); if (ok) _refresh(); }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'warn', child: Row(children: const [Icon(Icons.warning_amber_rounded, color: Color(0xFFFB923C), size: 16), SizedBox(width: 10), Text('Warn User', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))])),
                        if (accountStatus == 'active')
                          PopupMenuItem(value: 'freeze', child: Row(children: const [Icon(Icons.ac_unit_rounded, color: Colors.blue, size: 16), SizedBox(width: 10), Text('Freeze Account', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))])),
                        if (reactivationRequested) ...[
                          PopupMenuItem(value: 'approve_reactivation', child: Row(children: const [Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 16), SizedBox(width: 10), Text('Approve Request', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))])),
                          PopupMenuItem(value: 'view_request', child: Row(children: const [Icon(Icons.notifications_active_rounded, color: Color(0xFFFB923C), size: 16), SizedBox(width: 10), Text('View Request', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))])),
                        ],
                        if (accountStatus == 'frozen')
                          PopupMenuItem(value: 'unfreeze', child: Row(children: const [Icon(Icons.play_circle_outline_rounded, color: AppColors.success, size: 16), SizedBox(width: 10), Text('Reactivate', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))])),
                        if (accountStatus != 'blocked')
                          PopupMenuItem(value: 'block', child: Row(children: const [Icon(Icons.block_rounded, color: AppColors.error, size: 16), SizedBox(width: 10), Text('Block Permanently', style: TextStyle(color: AppColors.error, fontSize: 13))]))
                        else
                          PopupMenuItem(value: 'unblock', child: Row(children: const [Icon(Icons.play_circle_outline_rounded, color: AppColors.success, size: 16), SizedBox(width: 10), Text('Unblock / Reactivate', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))])),
                      ],
                    ),
                  ])),
                ]),
              );
            }),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppColors.secondaryBackground, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)), border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Showing ${adminProv.usersStartIndex} - ${adminProv.usersEndIndex} of ${adminProv.usersTotal} users', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Row(children: [
                  _PaginationBtn(label: 'Previous', enabled: adminProv.hasPreviousUsers, onTap: () => _refresh(page: adminProv.usersPage - 1)),
                  const SizedBox(width: 8),
                  _PaginationBtn(label: 'Next', enabled: adminProv.hasNextUsers, onTap: () => _refresh(page: adminProv.usersPage + 1)),
                ]),
              ]),
            ),
          ]),
        ),
    ]);
  }
}

'''

with open('lib/features/operations/presentation/screens/operational_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

before = lines[:3076]   # 0-indexed: lines 1..3076
after  = lines[3322:]   # 0-indexed: lines 3323..end (old class was lines 3077..3322)

combined = before + [new_block] + after
with open('lib/features/operations/presentation/screens/operational_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(combined)
print('SUCCESS: replaced _UsersPage (lines 3077-3322) with new implementation')
