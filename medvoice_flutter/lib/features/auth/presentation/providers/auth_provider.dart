import 'package:flutter/foundation.dart';
import 'package:medvoice_flutter/core/storage/secure_storage_service.dart';
import 'package:medvoice_flutter/features/auth/data/auth_repository.dart';
import 'package:medvoice_flutter/features/auth/domain/models/mock_user.dart';
import 'package:medvoice_flutter/features/auth/domain/models/user_role.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository, SecureStorageService? storage})
      : _repository = repository ?? AuthRepository(),
        _storage = storage ?? SecureStorageService() {
    _attemptRestore();
  }

  final AuthRepository _repository;
  final SecureStorageService _storage;

  MockUser? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasEndedSession = false;
  bool _hasCompletedSplash = false;
  bool _isRestoring = true;

  MockUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get hasEndedSession => _hasEndedSession;
  bool get hasCompletedSplash => _hasCompletedSplash;
  bool get isRestoring => _isRestoring;

  Future<void> _attemptRestore() async {
    _isRestoring = true;
    notifyListeners();
    try {
      final user = await _repository.restoreSession(_storage);
      if (user != null) {
        _user = user;
        _hasEndedSession = false;
      }
    } catch (_) {
      await _storage.clearSession();
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> submitAppeal(int userId, String reason, {List<int>? evidenceBytes, String? evidenceFileName}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.submitAppeal(userId, reason, evidenceBytes: evidenceBytes, evidenceFileName: evidenceFileName);
    } catch (e) {
      _errorMessage = e.toString();
      throw Exception(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void completeSplash() {
    _hasCompletedSplash = true;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login({
    required String usernameOrEmail,
    required String password,
    bool rememberMe = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _repository.login(
        usernameOrEmail: usernameOrEmail,
        password: password,
        rememberMe: rememberMe,
      );
      // Pass the stored auth token from DioClient so session restore works on refresh
      final token = _repository.currentToken;
      await _repository.saveSessionMeta(_storage, _user!, token: token);
      _hasEndedSession = false;
      return true;
    } on AccountFrozenException {
      rethrow;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required UserRole role,
    required Map<String, String> formData,
    Map<String, String>? filePaths,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.register(role: role, formData: formData, filePaths: filePaths);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    try {
      final user = await _repository.restoreSession(_storage);
      if (user != null) {
        _user = user;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.logout();
    } finally {
      await _storage.clearSession();
      _user = null;
      _isLoading = false;
      _errorMessage = null;
      _hasEndedSession = true;
      notifyListeners();
    }
  }
}
