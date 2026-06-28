import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medvoice_flutter/app/router/route_paths.dart';
import 'package:medvoice_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:medvoice_flutter/features/auth/presentation/screens/account_state_screen.dart';
import 'package:medvoice_flutter/features/auth/presentation/screens/account_frozen_screen.dart';
import 'package:medvoice_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:medvoice_flutter/features/auth/presentation/screens/register_screen.dart';
import 'package:medvoice_flutter/features/auth/presentation/screens/splash_screen.dart';
import 'package:medvoice_flutter/features/auth/presentation/screens/welcome_screen.dart';
import 'package:medvoice_flutter/features/operations/presentation/screens/operational_screen.dart';
import 'package:medvoice_flutter/features/patient/presentation/screens/chat_detail_screen.dart';
import 'package:medvoice_flutter/features/patient/presentation/screens/community_feed_screen.dart';
import 'package:medvoice_flutter/features/patient/presentation/screens/complaint_detail_screen.dart';
import 'package:medvoice_flutter/features/patient/presentation/screens/create_post_screen.dart';
import 'package:medvoice_flutter/features/patient/presentation/screens/ocr_processing_screen.dart';
import 'package:medvoice_flutter/features/patient/presentation/screens/ocr_upload_screen.dart';
import 'package:medvoice_flutter/features/patient/presentation/screens/ocr_verification_result_screen.dart';
import 'package:medvoice_flutter/features/patient/presentation/screens/patient_dashboard_screen.dart';
import 'package:medvoice_flutter/features/patient/presentation/screens/patient_support_screen.dart';
import 'package:medvoice_flutter/features/patient/presentation/screens/patient_utility_screen.dart';
import 'package:medvoice_flutter/features/patient/presentation/screens/support_chat_screen.dart';
import 'package:medvoice_flutter/features/patient/presentation/widgets/patient_shell.dart';

/// Central GoRouter configuration.
class AppRouter {
  AppRouter({
    required AuthProvider authProvider,
    GlobalKey<NavigatorState>? navigatorKey,
  }) : router = GoRouter(
          navigatorKey: navigatorKey ?? GlobalKey<NavigatorState>(),
          initialLocation: RoutePaths.splash,
          debugLogDiagnostics: true,
          refreshListenable: authProvider,
          routes: _routes,
          redirect: (context, state) => _redirect(authProvider, state),
        );

  final GoRouter router;

  static String? _redirect(AuthProvider auth, GoRouterState state) {
    final location = state.matchedLocation;

    final isPublicAuthRoute = {
      RoutePaths.splash,
      RoutePaths.welcome,
      RoutePaths.login,
      RoutePaths.register,
    }.contains(location);

    final isProtectedRoute = _isProtectedRoute(location);

    if (!auth.isAuthenticated && isProtectedRoute) {
      return RoutePaths.login;
    }

    if (auth.isAuthenticated && isPublicAuthRoute) {
      return auth.user!.role.dashboardPath;
    }

    if (auth.isAuthenticated && isProtectedRoute) {
      final userDashboard = auth.user!.role.dashboardPath;
      final allowedPrefix = _rolePrefixForDashboard(userDashboard);
      
      // Allow cross-role access to complaint details, chat details, and support chat detail
      final isBypassedRoute = RegExp(r'^/patient/(complaint|chat-detail|support)/\d+').hasMatch(location);
      
      if (!isBypassedRoute && allowedPrefix != null && !location.startsWith(allowedPrefix)) {
        return userDashboard;
      }
    }

    if (location == RoutePaths.root) {
      return RoutePaths.splash;
    }

    return null;
  }

  static bool _isProtectedRoute(String location) {
    return location.startsWith(RoutePaths.patient) ||
        location.startsWith(RoutePaths.hospital) ||
        location.startsWith(RoutePaths.authority) ||
        location.startsWith(RoutePaths.admin);
  }

  static String? _rolePrefixForDashboard(String dashboardPath) {
    if (dashboardPath.startsWith(RoutePaths.patient)) return RoutePaths.patient;
    if (dashboardPath.startsWith(RoutePaths.hospital)) return RoutePaths.hospital;
    if (dashboardPath.startsWith(RoutePaths.authority)) {
      return RoutePaths.authority;
    }
    if (dashboardPath.startsWith(RoutePaths.admin)) return RoutePaths.admin;
    return null;
  }

  static final List<RouteBase> _routes = [
    GoRoute(
      path: RoutePaths.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RoutePaths.welcome,
      name: 'welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: RoutePaths.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RoutePaths.register,
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: RoutePaths.pendingApproval,
      name: 'pendingApproval',
      builder: (context, state) => const AccountStateScreen(
        page: AccountStatePage.pendingApproval,
      ),
    ),
    GoRoute(
      path: RoutePaths.accountDisabled,
      name: 'accountDisabled',
      builder: (context, state) => const AccountStateScreen(
        page: AccountStatePage.disabled,
      ),
    ),
    GoRoute(
      path: RoutePaths.accountFrozen,
      name: 'accountFrozen',
      builder: (context, state) {
        final userId = state.extra as int?;
        return AccountFrozenScreen(userId: userId ?? 0);
      },
    ),

    GoRoute(
      path: RoutePaths.patient,
      redirect: (_, _) => RoutePaths.patientDashboard,
    ),

    // ── Patient shell (Sidebar Navigation) ─────────────────────────────────
    ShellRoute(
      builder: (context, state, child) {
        return PatientShell(child: child);
      },
      routes: [
        GoRoute(
          path: RoutePaths.patientDashboard,
          name: 'patientDashboard',
          builder: (context, state) => const PatientDashboardScreen(),
        ),
        GoRoute(
          path: RoutePaths.patientFeed,
          name: 'patientFeed',
          builder: (context, state) => const CommunityFeedScreen(),
        ),
        GoRoute(
          path: RoutePaths.patientCreatePost,
          name: 'patientCreatePost',
          builder: (context, state) => const CreatePostScreen(),
        ),
        GoRoute(
          path: RoutePaths.patientProfile,
          name: 'patientProfile',
          builder: (context, state) => const PatientUtilityScreen(
            page: PatientUtilityPage.profile,
          ),
        ),
        GoRoute(
          path: RoutePaths.patientComplaints,
          name: 'patientComplaints',
          builder: (context, state) => const PatientUtilityScreen(
            page: PatientUtilityPage.complaints,
          ),
        ),
        GoRoute(
          path: RoutePaths.patientChat,
          name: 'patientChat',
          builder: (context, state) => const PatientUtilityScreen(
            page: PatientUtilityPage.chat,
          ),
        ),
        GoRoute(
          path: RoutePaths.patientNotifications,
          name: 'patientNotifications',
          builder: (context, state) => const PatientUtilityScreen(
            page: PatientUtilityPage.notifications,
          ),
        ),
        GoRoute(
          path: RoutePaths.patientSettings,
          name: 'patientSettings',
          builder: (context, state) => const PatientUtilityScreen(
            page: PatientUtilityPage.settings,
          ),
        ),
        GoRoute(
          path: RoutePaths.patientSupport,
          name: 'patientSupport',
          builder: (context, state) => const PatientSupportScreen(),
        ),
      ],
    ),

    // Sub-screens that should cover the shell completely
    GoRoute(
      path: RoutePaths.patientOcrUpload,
      name: 'patientOcrUpload',
      builder: (context, state) => const OcrUploadScreen(),
    ),
    GoRoute(
      path: RoutePaths.patientOcrProcessing,
      name: 'patientOcrProcessing',
      builder: (context, state) => OcrProcessingScreen(
        result: state.uri.queryParameters['result'],
      ),
    ),
    GoRoute(
      path: RoutePaths.patientOcrResult,
      name: 'patientOcrResult',
      builder: (context, state) => OcrVerificationResultScreen(
        result: state.uri.queryParameters['result'],
      ),
    ),
    GoRoute(
      path: RoutePaths.patientComplaintDetailPattern,
      name: 'patientComplaintDetail',
      builder: (context, state) => ComplaintDetailScreen(
        complaintId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: RoutePaths.patientChatDetailPattern,
      name: 'patientChatDetail',
      builder: (context, state) => ChatDetailScreen(
        conversationId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/patient/support/:id',
      name: 'supportChatDetail',
      builder: (context, state) => SupportChatScreen(
        ticketId: int.parse(state.pathParameters['id']!),
      ),
    ),

    // ── Hospital shell ────────────────────────────────────────────────────
    GoRoute(
      path: RoutePaths.hospital,
      redirect: (_, state) {
        if (state.uri.path == RoutePaths.hospital) {
          return RoutePaths.hospitalDashboard;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: RoutePaths.hospitalDashboard.substring(RoutePaths.hospital.length + 1),
          name: 'hospitalDashboard',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.hospital,
            page: OperationalPage.dashboard,
          ),
        ),
        GoRoute(
          path: RoutePaths.hospitalComplaints.substring(RoutePaths.hospital.length + 1),
          name: 'hospitalComplaints',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.hospital,
            page: OperationalPage.complaints,
          ),
        ),
        GoRoute(
          path: RoutePaths.hospitalFeed.substring(RoutePaths.hospital.length + 1),
          name: 'hospitalFeed',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.hospital,
            page: OperationalPage.feed,
          ),
        ),
        GoRoute(
          path: RoutePaths.hospitalChat.substring(RoutePaths.hospital.length + 1),
          name: 'hospitalChat',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.hospital,
            page: OperationalPage.chat,
          ),
        ),
        GoRoute(
          path: RoutePaths.hospitalProfile.substring(RoutePaths.hospital.length + 1),
          name: 'hospitalProfile',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.hospital,
            page: OperationalPage.profile,
          ),
        ),
        GoRoute(
          path: RoutePaths.hospitalNotifications.substring(RoutePaths.hospital.length + 1),
          name: 'hospitalNotifications',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.hospital,
            page: OperationalPage.notifications,
          ),
        ),
        GoRoute(
          path: RoutePaths.hospitalSettings.substring(RoutePaths.hospital.length + 1),
          name: 'hospitalSettings',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.hospital,
            page: OperationalPage.settings,
          ),
        ),
      ],
    ),

    // ── Authority shell ───────────────────────────────────────────────────
    GoRoute(
      path: RoutePaths.authority,
      redirect: (_, state) {
        if (state.uri.path == RoutePaths.authority) {
          return RoutePaths.authorityDashboard;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: RoutePaths.authorityDashboard.substring(RoutePaths.authority.length + 1),
          name: 'authorityDashboard',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.authority,
            page: OperationalPage.dashboard,
          ),
        ),
        GoRoute(
          path: RoutePaths.authorityComplaints.substring(RoutePaths.authority.length + 1),
          name: 'authorityComplaints',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.authority,
            page: OperationalPage.complaints,
          ),
        ),
        GoRoute(
          path: RoutePaths.authorityEscalations.substring(RoutePaths.authority.length + 1),
          name: 'authorityEscalations',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.authority,
            page: OperationalPage.escalations,
          ),
        ),
        GoRoute(
          path: RoutePaths.authorityHospitals.substring(RoutePaths.authority.length + 1),
          name: 'authorityHospitals',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.authority,
            page: OperationalPage.hospitals,
          ),
        ),
        GoRoute(
          path: RoutePaths.authorityWarnings.substring(RoutePaths.authority.length + 1),
          name: 'authorityWarnings',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.authority,
            page: OperationalPage.warnings,
          ),
        ),
        GoRoute(
          path: RoutePaths.authorityFeed.substring(RoutePaths.authority.length + 1),
          name: 'authorityFeed',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.authority,
            page: OperationalPage.feed,
          ),
        ),
        GoRoute(
          path: RoutePaths.authorityChat.substring(RoutePaths.authority.length + 1),
          name: 'authorityChat',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.authority,
            page: OperationalPage.chat,
          ),
        ),
        GoRoute(
          path: RoutePaths.authorityProfile.substring(RoutePaths.authority.length + 1),
          name: 'authorityProfile',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.authority,
            page: OperationalPage.profile,
          ),
        ),
        GoRoute(
          path: RoutePaths.authorityNotifications.substring(RoutePaths.authority.length + 1),
          name: 'authorityNotifications',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.authority,
            page: OperationalPage.notifications,
          ),
        ),
        GoRoute(
          path: RoutePaths.authoritySettings.substring(RoutePaths.authority.length + 1),
          name: 'authoritySettings',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.authority,
            page: OperationalPage.settings,
          ),
        ),
        GoRoute(
          path: RoutePaths.authorityRegulations.substring(RoutePaths.authority.length + 1),
          name: 'authorityRegulations',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.authority,
            page: OperationalPage.regulations,
          ),
        ),
      ],
    ),

    // ── Admin shell ───────────────────────────────────────────────────────
    GoRoute(
      path: RoutePaths.admin,
      redirect: (_, state) {
        if (state.uri.path == RoutePaths.admin) {
          return RoutePaths.adminDashboard;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: RoutePaths.adminDashboard.substring(RoutePaths.admin.length + 1),
          name: 'adminDashboard',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.admin,
            page: OperationalPage.dashboard,
          ),
        ),
        GoRoute(
          path: RoutePaths.adminApprovals.substring(RoutePaths.admin.length + 1),
          name: 'adminApprovals',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.admin,
            page: OperationalPage.approvals,
          ),
        ),
        GoRoute(
          path: RoutePaths.adminUsers.substring(RoutePaths.admin.length + 1),
          name: 'adminUsers',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.admin,
            page: OperationalPage.users,
          ),
        ),
        GoRoute(
          path: RoutePaths.adminCategories.substring(RoutePaths.admin.length + 1),
          name: 'adminCategories',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.admin,
            page: OperationalPage.categories,
          ),
        ),
        GoRoute(
          path: RoutePaths.adminPerformance.substring(RoutePaths.admin.length + 1),
          name: 'adminPerformance',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.admin,
            page: OperationalPage.performance,
          ),
        ),
        GoRoute(
          path: RoutePaths.adminSupport.substring(RoutePaths.admin.length + 1),
          name: 'adminSupport',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.admin,
            page: OperationalPage.support,
          ),
        ),
        GoRoute(
          path: RoutePaths.adminNotifications.substring(RoutePaths.admin.length + 1),
          name: 'adminNotifications',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.admin,
            page: OperationalPage.notifications,
          ),
        ),
        GoRoute(
          path: RoutePaths.adminProfile.substring(RoutePaths.admin.length + 1),
          name: 'adminProfile',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.admin,
            page: OperationalPage.profile,
          ),
        ),
        GoRoute(
          path: RoutePaths.adminSettings.substring(RoutePaths.admin.length + 1),
          name: 'adminSettings',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.admin,
            page: OperationalPage.settings,
          ),
        ),
        GoRoute(
          path: RoutePaths.adminEntityVerification.substring(RoutePaths.admin.length + 1),
          name: 'adminEntityVerification',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.admin,
            page: OperationalPage.entityVerification,
          ),
        ),
        GoRoute(
          path: RoutePaths.adminAuditLogs.substring(RoutePaths.admin.length + 1),
          name: 'adminAuditLogs',
          builder: (context, state) => const OperationalScreen(
            role: OperationalRole.admin,
            page: OperationalPage.auditLogs,
          ),
        ),
      ],
    ),
  ];
}

