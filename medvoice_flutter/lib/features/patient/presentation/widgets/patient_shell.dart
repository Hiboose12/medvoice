import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/app/router/route_paths.dart';
import 'package:medvoice_flutter/core/theme/app_icons.dart';
import 'package:medvoice_flutter/core/theme/patient_colors.dart';
import 'package:medvoice_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:medvoice_flutter/features/auth/presentation/widgets/medvoice_logo.dart';
import 'package:provider/provider.dart';

class PatientShell extends StatelessWidget {
  const PatientShell({super.key, required this.child});

  final Widget child;

  void _showLogoutDialog(BuildContext context) {
    final shellContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: PatientColors.card,
        title: const Text('Logout', style: TextStyle(color: PatientColors.textMain)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: PatientColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await shellContext.read<AuthProvider>().logout();
              if (shellContext.mounted) {
                shellContext.replace(RoutePaths.login);
              }
            },
            child: const Text('Logout', style: TextStyle(color: PatientColors.medicalRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientColors.bgLight,
      appBar: AppBar(
        backgroundColor: PatientColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const MedVoiceLogo(
          iconColor: PatientColors.primary,
          compact: true,
        ),
        iconTheme: const IconThemeData(color: PatientColors.textMain),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.scan),
            tooltip: 'Scan Documents (OCR)',
            onPressed: () => context.push(RoutePaths.patientOcrUpload),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              if (GoRouterState.of(context).uri.path != RoutePaths.patientNotifications) {
                context.go(RoutePaths.patientNotifications);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: PatientColors.cardBorder),
        ),
      ),
      drawer: _PatientDrawer(currentPath: GoRouterState.of(context).uri.path),
      body: child,
    );
  }
}

class _PatientDrawer extends StatelessWidget {
  const _PatientDrawer({required this.currentPath});
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final initial = auth.user?.firstName.isNotEmpty == true
        ? auth.user!.firstName[0]
        : 'P';

    return Drawer(
      backgroundColor: PatientColors.card,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: PatientColors.cardElevated,
              border: Border(bottom: BorderSide(color: PatientColors.cardBorder)),
            ),
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: PatientColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    initial.toUpperCase(),
                    style: const TextStyle(
                      color: PatientColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
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
                        auth.user != null ? auth.user!.firstName : 'Patient',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: PatientColors.textMain,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Patient Portal',
                        style: TextStyle(
                          color: PatientColors.textMuted,
                          fontSize: 13,
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
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  path: RoutePaths.patientDashboard,
                  currentPath: currentPath,
                ),
                _DrawerItem(
                  icon: Icons.post_add_outlined,
                  label: 'Submit Complaint',
                  path: RoutePaths.patientCreatePost,
                  currentPath: currentPath,
                ),
                _DrawerItem(
                  icon: Icons.list_alt_outlined,
                  label: 'My Complaints',
                  path: RoutePaths.patientComplaints,
                  currentPath: currentPath,
                ),
                _DrawerItem(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chats',
                  path: RoutePaths.patientChat,
                  currentPath: currentPath,
                ),
                _DrawerItem(
                  icon: Icons.forum_outlined,
                  label: 'Public Feed',
                  path: RoutePaths.patientFeed,
                  currentPath: currentPath,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Divider(color: PatientColors.cardBorder, height: 1),
                ),
                _DrawerItem(
                  icon: Icons.account_circle_outlined,
                  label: 'Profile',
                  path: RoutePaths.patientProfile,
                  currentPath: currentPath,
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  path: RoutePaths.patientSettings,
                  currentPath: currentPath,
                ),
                _DrawerItem(
                  icon: Icons.support_agent_outlined,
                  label: 'Contact Support',
                  path: RoutePaths.patientSupport,
                  currentPath: currentPath,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
  });

  final IconData icon;
  final String label;
  final String path;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final isSelected = currentPath == path;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selectedTileColor: PatientColors.primary.withValues(alpha: 0.1),
        selected: isSelected,
        leading: Icon(
          icon,
          color: isSelected ? PatientColors.primary : PatientColors.textMuted,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? PatientColors.primary : PatientColors.textMain,
          ),
        ),
        onTap: () {
          if (!isSelected) {
            Navigator.pop(context); // Close drawer
            context.go(path);
          } else {
            Navigator.pop(context); // Just close drawer
          }
        },
      ),
    );
  }
}

extension PatientShellNavigation on BuildContext {
  void goPatientTab(int index) {
    switch (index) {
      case 0:
        go(RoutePaths.patientDashboard);
      case 1:
        go(RoutePaths.patientFeed);
      case 2:
        go(RoutePaths.patientCreatePost);
      case 3:
        go(RoutePaths.patientProfile);
    }
  }
}
