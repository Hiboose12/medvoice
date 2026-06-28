import 'package:medvoice_flutter/features/auth/domain/models/user_role.dart';

class MockUser {
  const MockUser({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.role,
    this.isApproved = true,
    this.accountStatus,
    this.lastLogin,
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final UserRole role;
  final bool isApproved;
  final String? accountStatus;
  final DateTime? lastLogin;
}
