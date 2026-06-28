import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medvoice_flutter/app/router/route_paths.dart';
import 'package:medvoice_flutter/core/theme/app_colors.dart';
import 'package:medvoice_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:medvoice_flutter/features/auth/presentation/widgets/medvoice_logo.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  Timer? _timer;
  bool _navigated = false;
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _authProvider = context.read<AuthProvider>();
    _startRestoration();
  }

  void _startRestoration() {
    if (!_authProvider.isRestoring) {
      _scheduleNavigation();
      return;
    }

    _authProvider.addListener(_onAuthRestored);
  }

  void _onAuthRestored() {
    if (!_authProvider.isRestoring && mounted) {
      _authProvider.removeListener(_onAuthRestored);
      _scheduleNavigation();
    }
  }

  void _scheduleNavigation() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 350), _navigate);
  }

  void _navigate() {
    if (_navigated) return;
    _navigated = true;
    if (!mounted) return;

    final target = _pickTarget(_authProvider);
    context.go(target);
  }

  String _pickTarget(AuthProvider auth) {
    if (auth.isAuthenticated && auth.user != null) {
      return auth.user!.role.dashboardPath;
    }
    return RoutePaths.welcome;
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_authProvider.isRestoring) {
      _authProvider.removeListener(_onAuthRestored);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.authPanelBlue,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const MedVoiceLogo(
                  iconColor: Colors.white,
                  textColor: Colors.white,
                ),
                const SizedBox(height: 24),
                Text(
                  'Medical Grievance Platform',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.authBlue200,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


