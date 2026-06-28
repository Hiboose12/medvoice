import 'package:medvoice_flutter/features/auth/domain/models/mock_user.dart';
import 'package:medvoice_flutter/features/auth/domain/models/user_role.dart';

/// Mock credentials for UI prototyping — no backend calls.
abstract final class MockAuthData {
  static const List<MockUser> users = [
    MockUser(
      id: 1,
      username: 'johndoe',
      email: 'patient@demo.com',
      firstName: 'John',
      role: UserRole.patient,
    ),
    MockUser(
      id: 2,
      username: 'cityhospital',
      email: 'hospital@demo.com',
      firstName: 'City',
      role: UserRole.hospital,
    ),
    MockUser(
      id: 3,
      username: 'healthauth',
      email: 'authority@demo.com',
      firstName: 'District',
      role: UserRole.authority,
    ),
    MockUser(
      id: 4,
      username: 'superadmin',
      email: 'admin@demo.com',
      firstName: 'Admin',
      role: UserRole.superadmin,
    ),
  ];

  static const String demoPassword = 'demo123';

  static const Map<UserRole, String> roleHints = {
    UserRole.patient: 'patient@demo.com / johndoe',
    UserRole.hospital: 'hospital@demo.com / cityhospital',
    UserRole.authority: 'authority@demo.com / healthauth',
    UserRole.superadmin: 'admin@demo.com / superadmin',
  };
}
