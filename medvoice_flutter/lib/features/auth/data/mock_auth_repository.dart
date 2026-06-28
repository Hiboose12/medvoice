import 'package:medvoice_flutter/features/auth/data/mock_auth_data.dart';
import 'package:medvoice_flutter/features/auth/domain/models/mock_user.dart';
import 'package:medvoice_flutter/features/auth/domain/models/user_role.dart';

/// Simulates authentication with in-memory mock data.
class MockAuthRepository {
  Future<MockUser> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (password != MockAuthData.demoPassword) {
      throw const AuthException('Invalid username or password.');
    }

    final normalized = usernameOrEmail.trim().toLowerCase();
    final user = MockAuthData.users.where(
      (u) =>
          u.username.toLowerCase() == normalized ||
          u.email.toLowerCase() == normalized,
    );

    if (user.isEmpty) {
      throw const AuthException('Invalid username or password.');
    }

    return user.first;
  }

  Future<void> register({
    required UserRole role,
    required Map<String, String> formData,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    final email = formData['email']?.trim().toLowerCase();
    final username = formData['username']?.trim().toLowerCase();

    if (email == null || email.isEmpty || username == null || username.isEmpty) {
      throw const AuthException('Email and username are required.');
    }

    final exists = MockAuthData.users.any(
      (u) =>
          u.email.toLowerCase() == email ||
          u.username.toLowerCase() == username,
    );

    if (exists) {
      throw const AuthException('This email or username is already registered.');
    }

    final password = formData['password'];
    final confirm = formData['confirm_password'];
    if (password == null || confirm == null || password != confirm) {
      throw const AuthException('Passwords do not match.');
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
