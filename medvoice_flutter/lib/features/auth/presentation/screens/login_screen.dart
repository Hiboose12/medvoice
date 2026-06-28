import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/app/router/route_paths.dart';
import 'package:medvoice_flutter/core/theme/app_colors.dart';
import 'package:medvoice_flutter/core/theme/app_typography.dart';
import 'package:medvoice_flutter/features/auth/data/mock_auth_data.dart';
import 'package:medvoice_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:medvoice_flutter/features/auth/data/auth_repository.dart';
import 'package:medvoice_flutter/features/auth/presentation/widgets/auth_brand_panel.dart';
import 'package:medvoice_flutter/features/auth/presentation/widgets/auth_form_field.dart';
import 'package:medvoice_flutter/features/auth/presentation/widgets/medvoice_logo.dart';
import 'package:provider/provider.dart';

/// Mirrors `templates/accounts/login.html`.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    try {
      final success = await auth.login(
        usernameOrEmail: _usernameController.text,
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      if (success && auth.user != null) {
        context.replace(auth.user!.role.dashboardPath);
      }
    } on AccountFrozenException catch (e) {
      if (!mounted) return;
      context.go('/account-frozen', extra: e.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    return PopScope(
      canPop: !auth.hasEndedSession,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Row(
          children: [
            if (isWide)
              const Expanded(
                flex: 5,
                child: AuthBrandPanel(
                  icon: Icons.security,
                  title: 'Secure Platform for\nMedical Grievances',
                  subtitle:
                      'Connecting patients, hospitals, and authorities in a '
                      'transparent, unified ecosystem.',
                ),
              ),
            Expanded(
              flex: 7,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 96 : 32,
                      vertical: isWide ? 48 : 32,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 448),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const MedVoiceLogo(),
                            const SizedBox(height: 32),
                            Text(
                              'Sign In',
                              style: GoogleFonts.manrope(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Welcome back! Please enter your details.',
                              style: AppTypography.textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 32),
                            AuthFormField(
                              label: 'Email or Username',
                              controller: _usernameController,
                              hint: 'Enter your username or email',
                            ),
                            const SizedBox(height: 20),
                            AuthFormField(
                              label: 'Password',
                              controller: _passwordController,
                              hint: '••••••••',
                              obscureText: _obscurePassword,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final rememberControl = Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (v) => setState(
                                          () => _rememberMe = v ?? false,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Remember for 30 days',
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontSize: 14,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  ],
                                );
                                final forgotButton = TextButton(
                                  onPressed: () {},
                                  child: const Text('Forgot password?'),
                                );

                                if (constraints.maxWidth < 480) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      rememberControl,
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: forgotButton,
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: rememberControl),
                                    forgotButton,
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _submit,
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Sign In'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account?",
                                  style: AppTypography.textTheme.bodySmall
                                      ?.copyWith(fontSize: 14),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      context.push(RoutePaths.register),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.textPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                  ),
                                  child: const Text('Sign up'),
                                ),
                              ],
                            ),
                            if (auth.errorMessage != null) ...[
                              const SizedBox(height: 16),
                              AuthMessageBanner(message: auth.errorMessage!),
                            ],
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.infoBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.infoBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Demo accounts (password: ${MockAuthData.demoPassword})',
                                    style: AppTypography.textTheme.bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.authBlue700,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...MockAuthData.roleHints.entries.map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '${e.key.label}: ${e.value}',
                                        style:
                                            AppTypography.textTheme.bodySmall,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: isWide ? 96 : 32,
                    right: 32,
                    child: Text(
                      '© 2026 MedVoice Inc.',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.textDisabled,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
