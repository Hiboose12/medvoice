import 'package:flutter/foundation.dart';

/// Runtime configuration for the MedVoice Flutter client.
///
/// Values can be overridden at build time:
/// `flutter run --dart-define=BASE_URL=http://192.168.1.10:8000`
abstract final class EnvConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: kIsWeb ? 'http://localhost:8000' : 'http://192.168.1.38:8000',
  );

  static const String mediaUrl = '$baseUrl/media/';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const Duration chatPollInterval = Duration(seconds: 3);

  static const int maxUploadBytes = 20 * 1024 * 1024;
}
