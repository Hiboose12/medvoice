import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:medvoice_flutter/core/network/api_exception.dart';
import 'package:medvoice_flutter/core/network/dio_client.dart';
import 'package:medvoice_flutter/core/network/endpoints.dart';
import 'package:medvoice_flutter/core/storage/secure_storage_service.dart';
import 'package:medvoice_flutter/features/auth/domain/models/mock_user.dart';
import 'package:medvoice_flutter/features/auth/domain/models/user_role.dart';

/// Remote authentication repository using Django session auth.
class AuthRepository {
  AuthRepository({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  /// Returns the current auth token stored in DioClient headers.
  String? get currentToken => _client.currentToken;

  Future<MockUser> login({
    required String usernameOrEmail,
    required String password,
    bool rememberMe = false,
  }) async {

    try {
      await _client.init();

      debugPrint("STEP A: START LOGIN");

      final response = await _client.dio.post(
        Endpoints.login,
        data: {
          'username': usernameOrEmail,
          'password': password,
          if (rememberMe) 'remember_me': 'on',
        },
        options: Options(
          headers: {'Accept': 'application/json'},
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) => status != null && status >= 200 && status < 400,
        ),
      );

      debugPrint("STEP B: LOGIN RESPONSE STATUS: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 302) {
        final responseData = response.data;
        if (responseData is Map) {
          final map = Map<String, dynamic>.from(responseData);
          // Prefer parsing user directly from the login response (avoids extra /me request)
          final token = map['token'] as String?;
          final userData = map['user'] != null ? Map<String, dynamic>.from(map['user'] as Map) : null;

          if (token != null) {
            // Store the token so subsequent API calls use Token Authentication
            _client.dio.options.headers['Authorization'] = 'Token $token';
            debugPrint("TOKEN SET: ${token.substring(0, 8)}...");
          }

          if (userData != null) {
            debugPrint("LOGIN SUCCESS (from response)");
            return _parseUser(userData);
          }
        }

        // Fallback: fetch user profile via session cookie
        try {
          debugPrint("STEP C: FALLBACK - FETCHING USER PROFILE");
          final user = await _fetchCurrentUser();
          debugPrint("LOGIN SUCCESS (from profile)");
          return user;
        } catch (e) {
          debugPrint("Profile fetch failed: $e");
        }
      }
      throw const AuthException('Invalid username or password.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 && e.response?.data is Map) {
        final data = Map<String, dynamic>.from(e.response!.data as Map);
        if (data['is_frozen'] == true && data['user_id'] != null) {
          throw AccountFrozenException(data['user_id'], data['error'] ?? 'Account frozen');
        }
      }
      throw AuthException(_mapError(e));
    }
  }

  MockUser _parseUser(Map<String, dynamic> data) {
    return MockUser(
      id: data['id'] ?? 0,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      firstName: data['first_name'] ?? data['username'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == (data['role'] ?? 'patient'),
        orElse: () => UserRole.patient,
      ),
      isApproved: data['is_approved'] ?? true,
      accountStatus: data['account_status'],
      lastLogin: data['last_login'] != null
          ? DateTime.tryParse(data['last_login'].toString())
          : null,
    );
  }

  Future<MockUser> _fetchCurrentUser() async {
    try {
      debugPrint("STEP D: ENTERED FETCH USER");
      await _client.init();
      debugPrint("FETCHING CURRENT USER");
      debugPrint("STEP E: BEFORE PROFILE API");
      final response = await _client.dio.get(Endpoints.apiUserProfile);
      debugPrint("STEP F: PROFILE RESPONSE RECEIVED");
      debugPrint("PROFILE STATUS: ${response.statusCode}");
      debugPrint("PROFILE DATA: ${response.data}");
      final data = response.data;
      if (data is! Map) {
        throw const AuthException('Failed to fetch user data');
      }

      return _parseUser(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      debugPrint("STEP G: PROFILE ERROR");
      debugPrint(e.toString());
      debugPrint("PROFILE ERROR: $e");
      throw AuthException('Failed to fetch user data');
    }
  }

  Future<MockUser?> restoreSession(SecureStorageService storage) async {
    final cookiesExist = await _hasSavedSessionCookie(storage);
    if (!cookiesExist) return null;

    try {
      await _client.init();
      // Restore the saved auth token so API calls work after page refresh
      final savedToken = await storage.read('auth_token');
      if (savedToken != null) {
        _client.dio.options.headers['Authorization'] = 'Token $savedToken';
        debugPrint('SESSION RESTORED: Token loaded from storage');
      }
      return await _fetchCurrentUser();
    } on AuthException {
      return null;
    }
  }

  Future<bool> _hasSavedSessionCookie(SecureStorageService storage) async {
    try {
      // We store session_meta after a successful login (not session_id),
      // so check for session_meta to know if there's a persisted session.
      final meta = await storage.read('session_meta');
      return meta != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> saveSessionMeta(SecureStorageService storage, MockUser user, {String? token}) async {
    final timestamp = DateTime.now().toIso8601String();
    await storage.write('session_meta', '${user.id}|${user.role.name}|$timestamp');
    if (token != null) {
      await storage.write('auth_token', token);
    }
  }

  Future<Map<String, String>?> getSessionMeta(SecureStorageService storage) async {
    final raw = await storage.read('session_meta');
    if (raw == null) return null;
    final parts = raw.split('|');
    if (parts.length < 3) return null;
    return {
      'userId': parts[0],
      'role': parts[1],
      'savedAt': parts.sublist(2).join('|'),
    };
  }

  Future<void> register({
    required UserRole role,
    required Map<String, String> formData,
    Map<String, String>? filePaths,
  }) async {
    try {
      await _client.init();

      final formDataObj = FormData();
      formDataObj.fields.add(MapEntry('role', role.name));
      
      for (final entry in formData.entries) {
        if (entry.value.isNotEmpty) {
          formDataObj.fields.add(MapEntry(entry.key, entry.value));
        }
      }

      if (filePaths != null) {
        for (final entry in filePaths.entries) {
          if (entry.value.isNotEmpty) {
            formDataObj.files.add(
              MapEntry(
                entry.key,
                await MultipartFile.fromFile(entry.value),
              ),
            );
          }
        }
      }

      debugPrint("--- REGISTRATION REQUEST ---");
      debugPrint("URL: ${_client.dio.options.baseUrl}${Endpoints.register(role)}");
      debugPrint("HEADERS: ${_client.dio.options.headers}");
      debugPrint("PAYLOAD: $formData");
      debugPrint("FILES: $filePaths");

      final response = await _client.dio.post(
        Endpoints.register(role), 
        data: formDataObj,
        options: Options(
          headers: {'Accept': 'application/json'},
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint("--- REGISTRATION RESPONSE ---");
      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("BODY: ${response.data}");

      if (response.statusCode == 400 || response.statusCode == 500) {
          final errorData = response.data;
          String errorMsg = "Registration failed. Please check your details.";
          if (errorData is Map) {
              if (errorData.containsKey('error')) {
                  final err = errorData['error'];
                  if (err is Map) {
                     // Extracting messages from Django form.errors.as_json()
                     errorMsg = err.entries.map((e) {
                         final field = e.key;
                         final List msgs = e.value as List;
                         final msgStr = msgs.map((m) => m['message'] ?? m.toString()).join(', ');
                         return "$field: $msgStr";
                     }).join('\n');
                  } else {
                     errorMsg = err.toString();
                  }
              }
          }
          throw AuthException(errorMsg);
      }
    } on DioException catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  Future<bool> validateEmail(String email) async {
    try {
      await _client.init();
      debugPrint("LOGIN ATTEMPT");
      debugPrint("BASE URL: ${_client.dio.options.baseUrl}");
      debugPrint("ENDPOINT: ${Endpoints.login}");
      final response = await _client.dio.post(
        Endpoints.validateEmail,
        data: {'email': email},
      );
      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("DATA: ${response.data}");
      return response.data['status'] == 'success';
    } on DioException {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _client.init();
      await _client.dio.get(Endpoints.logout);
      await _client.clearCookies();
    } catch (_) {
      await _client.clearCookies();
    }
  }

  Future<void> submitAppeal(int userId, String reason, {List<int>? evidenceBytes, String? evidenceFileName}) async {
    try {
      await _client.init();
      
      final formDataObj = FormData();
      formDataObj.fields.add(MapEntry('user_id', userId.toString()));
      formDataObj.fields.add(MapEntry('reason', reason));

      if (evidenceBytes != null && evidenceFileName != null) {
        formDataObj.files.add(
          MapEntry(
            'evidence',
            MultipartFile.fromBytes(evidenceBytes, filename: evidenceFileName),
          ),
        );
      }

      await _client.dio.post(
        Endpoints.submitAppeal,
        data: formDataObj,
        options: Options(headers: {'Accept': 'application/json'}),
      );
    } on DioException catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  String _mapError(DioException error) {
    if (error.response?.data is Map) {
      final data = Map<String, dynamic>.from(error.response!.data as Map);
      return data['error'] ?? data['message'] ?? 'Request failed';
    }
    if (error.error is ApiException) {
      return (error.error as ApiException).message;
    }
    return error.message ?? 'Unknown error';
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AccountFrozenException implements Exception {
  final int userId;
  final String message;
  const AccountFrozenException(this.userId, this.message);

  @override
  String toString() => message;
}
