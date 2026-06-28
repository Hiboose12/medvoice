import 'package:flutter/material.dart';
import 'package:medvoice_flutter/core/theme/app_colors.dart';
import 'package:medvoice_flutter/core/theme/app_typography.dart';
import 'package:medvoice_flutter/features/auth/domain/models/user_role.dart';

/// Role tabs from register.html (`Patient` / `Hospital` / `Authority`).
class RoleTabSelector extends StatelessWidget {
  const RoleTabSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;

  static const _roles = [
    UserRole.patient,
    UserRole.hospital,
    UserRole.authority,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _roles.map((role) {
          final isActive = role == selectedRole;
          return Expanded(
            child: GestureDetector(
              onTap: () => onRoleChanged(role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  role.label,
                  textAlign: TextAlign.center,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? AppColors.authBlue700
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
