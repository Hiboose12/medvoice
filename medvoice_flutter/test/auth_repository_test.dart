import 'package:flutter_test/flutter_test.dart';
import 'package:medvoice_flutter/features/auth/data/auth_repository.dart';
import 'package:medvoice_flutter/features/auth/data/mock_auth_data.dart';

void main() {
  group('AuthRepository demo accounts', () {
    test('logs in every demo user by username and email', () async {
      final repository = AuthRepository();

      for (final demoUser in MockAuthData.users) {
        final usernameLogin = await repository.login(
          usernameOrEmail: demoUser.username,
          password: MockAuthData.demoPassword,
        );
        expect(usernameLogin.role, demoUser.role);

        final emailLogin = await repository.login(
          usernameOrEmail: demoUser.email,
          password: MockAuthData.demoPassword,
        );
        expect(emailLogin.role, demoUser.role);
      }
    });

    test('rejects a demo user with the wrong password', () async {
      final repository = AuthRepository();

      expect(
        () => repository.login(
          usernameOrEmail: MockAuthData.users.first.username,
          password: 'wrong-password',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
