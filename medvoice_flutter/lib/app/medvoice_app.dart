import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medvoice_flutter/app/providers/app_providers.dart';
import 'package:medvoice_flutter/app/router/app_router.dart';
import 'package:medvoice_flutter/core/theme/app_theme.dart';
import 'package:medvoice_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Root application widget.
class MedVoiceApp extends StatefulWidget {
  const MedVoiceApp({super.key});

  @override
  State<MedVoiceApp> createState() => _MedVoiceAppState();
}

class _MedVoiceAppState extends State<MedVoiceApp> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.build(),
      child: Builder(
        builder: (context) {
          final auth = context.read<AuthProvider>();
          _router ??= AppRouter(authProvider: auth).router;

          return Consumer<ThemeModeNotifier>(
            builder: (context, themeNotifier, _) {
              return MaterialApp.router(
                title: 'MedVoice',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeNotifier.themeMode,
                routerConfig: _router!,
              );
            },
          );
        },
      ),
    );
  }
}
