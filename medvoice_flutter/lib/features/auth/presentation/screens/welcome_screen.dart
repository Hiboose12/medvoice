import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/app/router/route_paths.dart';
import 'package:medvoice_flutter/core/theme/app_colors.dart';
import 'package:medvoice_flutter/core/theme/app_typography.dart';
import 'package:medvoice_flutter/features/auth/presentation/widgets/medvoice_logo.dart';

/// Mirrors `templates/home.html` — hero + 3-step feature section.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildHero(context)),
            SliverToBoxAdapter(child: _buildSteps(context)),
            SliverToBoxAdapter(child: _buildFooter(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: MedVoiceLogo(showTagline: true),
          ),
          TextButton(
            onPressed: () => context.push(RoutePaths.login),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.marketingPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              'LOGIN / REGISTER',
              style: AppTypography.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 768;

    return Container(
      color: AppColors.marketingSurface,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    AppColors.marketingSurface,
                    AppColors.marketingSurface.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isWide ? 80 : 48,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: isWide ? 1 : 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WELCOME TO MEDVOICE',
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: AppColors.marketingSecondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.manrope(
                              fontSize: isWide ? 56 : 40,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              height: 1.1,
                            ),
                            children: const [
                              TextSpan(text: 'Platform for\n'),
                              TextSpan(
                                text: 'Medical Grievances',
                                style: TextStyle(
                                  color: AppColors.marketingPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'A unified ecosystem where patients raise issues, '
                          'hospitals resolve them, and authorities ensure '
                          'transparency. Your voice matters in healthcare.',
                          style: AppTypography.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 18,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ElevatedButton(
                              onPressed: () => context.push(RoutePaths.login),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.marketingSecondary,
                                minimumSize: const Size(0, 52),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: Text(
                                'RAISE AN ISSUE',
                                style: AppTypography.textTheme.labelLarge
                                    ?.copyWith(letterSpacing: 1),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () => context.push(RoutePaths.register),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 52),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                side: const BorderSide(
                                  color: AppColors.marketingSecondary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: Text(
                                'CREATE ACCOUNT',
                                style: AppTypography.textTheme.labelLarge
                                    ?.copyWith(
                                  color: AppColors.marketingSecondary,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isWide) ...[
                    const SizedBox(width: 48),
                    Expanded(
                      child: SvgPicture.asset(
                        'assets/images/hero_illustration.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteps(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 768;
    const steps = [
      _StepData(
        step: 'Step 01',
        title: 'Raise Issues',
        description:
            'Patients can log in to their dashboard and post detailed '
            'complaints regarding their medical experience. Every issue is tracked.',
        color: AppColors.marketingAccent,
        stepColor: Color(0xFF93C5FD),
      ),
      _StepData(
        step: 'Step 02',
        title: 'Resolve & Reply',
        description:
            'Hospitals receive notifications for complaints and must respond '
            'directly on the platform to resolve the user\'s issue promptly.',
        color: AppColors.marketingSecondary,
        stepColor: Color(0xFFBFDBFE),
      ),
      _StepData(
        step: 'Step 03',
        title: 'Monitor & Verify',
        description:
            'Regulatory authorities oversee the entire process, ensuring '
            'hospitals are responsive and resolving issues satisfactorily.',
        color: AppColors.marketingPrimary,
        stepColor: Color(0xFFDBEAFE),
      ),
    ];

    return Transform.translate(
      offset: const Offset(0, -40),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isWide
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: steps
                            .map((s) => Expanded(child: _StepCard(data: s)))
                            .toList(),
                      ),
                    )
                  : Column(
                      children: steps
                          .map((s) => _StepCard(data: s))
                          .toList(),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          const MedVoiceLogo(),
          const SizedBox(height: 24),
          Text(
            '© 2026 MedVoice. All rights reserved.\n'
            'Connecting Patients, Providers, and Authorities.',
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StepData {
  const _StepData({
    required this.step,
    required this.title,
    required this.description,
    required this.color,
    required this.stepColor,
  });

  final String step;
  final String title;
  final String description;
  final Color color;
  final Color stepColor;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.data});

  final _StepData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      color: data.color,
      child: _StepContent(
        step: data.step,
        title: data.title,
        description: data.description,
        stepColor: data.stepColor,
      ),
    );
  }
}

class _StepContent extends StatelessWidget {
  const _StepContent({
    required this.step,
    required this.title,
    required this.description,
    required this.stepColor,
  });

  final String step;
  final String title;
  final String description;
  final Color stepColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step.toUpperCase(),
          style: AppTypography.textTheme.labelSmall?.copyWith(
            color: stepColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
