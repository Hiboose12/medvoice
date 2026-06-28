import 'package:flutter/material.dart';
import 'package:medvoice_flutter/core/network/dio_client.dart';
import 'package:medvoice_flutter/core/storage/secure_storage_service.dart';
import 'package:medvoice_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:medvoice_flutter/features/patient/data/patient_repository.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/community_feed_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/create_post_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/patient_dashboard_provider.dart';
import 'package:medvoice_flutter/features/patient/presentation/providers/patient_utility_provider.dart';
import 'package:medvoice_flutter/features/operations/data/hospital_repository.dart';
import 'package:medvoice_flutter/features/operations/presentation/providers/hospital_provider.dart';
import 'package:medvoice_flutter/features/operations/data/authority_repository.dart';
import 'package:medvoice_flutter/features/operations/presentation/providers/authority_provider.dart';
import 'package:medvoice_flutter/features/admin/data/admin_repository.dart';
import 'package:medvoice_flutter/features/admin/presentation/providers/admin_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Registers app-wide services and state via Provider.
class AppProviders {
  AppProviders._();

  static List<SingleChildWidget> build() {
    return [
      Provider<SecureStorageService>(
        create: (_) => SecureStorageService(),
      ),
      Provider<DioClient>(
        create: (_) => DioClient(),
      ),
      Provider<PatientRepository>(
        create: (_) => PatientRepository(),
      ),
      Provider<HospitalRepository>(
        create: (_) => HospitalRepository(),
      ),
      Provider<AuthorityRepository>(
        create: (_) => AuthorityRepository(),
      ),
      Provider<AdminRepository>(
        create: (_) => AdminRepository(),
      ),
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(),
      ),
      ChangeNotifierProxyProvider<PatientRepository, PatientDashboardProvider>(
        create: (context) => PatientDashboardProvider(
          repository: context.read<PatientRepository>(),
        ),
        update: (_, repository, provider) =>
            provider ?? PatientDashboardProvider(repository: repository),
      ),
      ChangeNotifierProxyProvider<PatientRepository, CommunityFeedProvider>(
        create: (context) => CommunityFeedProvider(
          repository: context.read<PatientRepository>(),
        ),
        update: (_, repository, provider) =>
            provider ?? CommunityFeedProvider(repository: repository),
      ),
      ChangeNotifierProxyProvider<PatientRepository, CreatePostProvider>(
        create: (context) => CreatePostProvider(
          repository: context.read<PatientRepository>(),
        ),
        update: (_, repository, provider) =>
            provider ?? CreatePostProvider(repository: repository),
      ),
      ChangeNotifierProxyProvider<PatientRepository, PatientUtilityProvider>(
        create: (context) => PatientUtilityProvider(
          repository: context.read<PatientRepository>(),
        ),
        update: (_, repository, provider) =>
            provider ?? PatientUtilityProvider(repository: repository),
      ),
      ChangeNotifierProxyProvider<HospitalRepository, HospitalProvider>(
        create: (context) => HospitalProvider(
          repository: context.read<HospitalRepository>(),
        ),
        update: (_, repository, provider) =>
            provider ?? HospitalProvider(repository: repository),
      ),
      ChangeNotifierProxyProvider<AuthorityRepository, AuthorityProvider>(
        create: (context) => AuthorityProvider(
          repository: context.read<AuthorityRepository>(),
        ),
        update: (_, repository, provider) =>
            provider ?? AuthorityProvider(repository: repository),
      ),
      ChangeNotifierProxyProvider<AdminRepository, AdminProvider>(
        create: (context) => AdminProvider(
          repository: context.read<AdminRepository>(),
        ),
        update: (_, repository, provider) =>
            provider ?? AdminProvider(repository: repository),
      ),
      ChangeNotifierProvider<ThemeModeNotifier>(
        create: (_) => ThemeModeNotifier(),
      ),
    ];
  }
}

/// Holds the active theme mode (light / dark / system).
class ThemeModeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }
}