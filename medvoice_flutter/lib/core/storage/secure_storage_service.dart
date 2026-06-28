import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted key-value storage for session tokens and sensitive prefs.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final FlutterSecureStorage _storage;

  static const String sessionKey = 'session_id';
  static const String csrfKey = 'csrf_token';

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> clear() => _storage.deleteAll();

  Future<String?> get sessionId => read(sessionKey);
  Future<String?> get csrfToken => read(csrfKey);

  Future<void> saveSession({required String sessionId, String? csrfToken}) async {
    await write(SecureStorageService.sessionKey, sessionId);
    if (csrfToken != null) {
      await write(SecureStorageService.csrfKey, csrfToken);
    }
  }

  Future<void> clearSession() async {
    await delete(sessionKey);
    await delete(csrfKey);
    await delete('session_meta');
    await delete('auth_token');
  }
}
