import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/app/router/route_paths.dart';
import 'package:medvoice_flutter/core/theme/app_colors.dart';

enum AccountStatePage { pendingApproval, disabled, frozen }

class AccountStateScreen extends StatelessWidget {
  const AccountStateScreen({super.key, required this.page});

  final AccountStatePage page;

  @override
  Widget build(BuildContext context) {
    final details = _details(page);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: details.color.withValues(alpha: 0.1),
                      child: Icon(details.icon, color: details.color),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      details.title,
                      style: GoogleFonts.manrope(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      details.message,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    if (page != AccountStatePage.pendingApproval) ...[
                      const SizedBox(height: 20),
                      const TextField(
                        minLines: 4,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: 'Reactivation reason',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Attach evidence'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () => context.go(RoutePaths.login),
                          child: const Text('Back to Login'),
                        ),
                        const SizedBox(width: 12),
                        if (page != AccountStatePage.pendingApproval)
                          TextButton(
                            onPressed: () {},
                            child: const Text('Submit request'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

_AccountStateDetails _details(AccountStatePage page) {
  return switch (page) {
    AccountStatePage.pendingApproval => const _AccountStateDetails(
        title: 'Account Approval Pending',
        message:
            'Your hospital or authority account has been created and is waiting for superadmin document review. You will be able to access the dashboard after approval.',
        icon: Icons.hourglass_top_outlined,
        color: AppColors.warning,
      ),
    AccountStatePage.disabled => const _AccountStateDetails(
        title: 'Account Disabled',
        message:
            'This account is disabled. Send a reactivation request with context and supporting evidence for admin review.',
        icon: Icons.person_off_outlined,
        color: AppColors.error,
      ),
    AccountStatePage.frozen => const _AccountStateDetails(
        title: 'Account Frozen',
        message:
            'This account is frozen because of governance or authority action. Submit an explanation and evidence so the appeal can be reviewed.',
        icon: Icons.gavel_outlined,
        color: AppColors.admin,
      ),
  };
}

class _AccountStateDetails {
  const _AccountStateDetails({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
}
