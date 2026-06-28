enum UserRole {
  patient,
  hospital,
  authority,
  superadmin;

  String get label => switch (this) {
        UserRole.patient => 'Patient',
        UserRole.hospital => 'Hospital',
        UserRole.authority => 'Authority',
        UserRole.superadmin => 'Super Admin',
      };

  String get dashboardPath => switch (this) {
        UserRole.patient => '/patient/dashboard',
        UserRole.hospital => '/hospital/dashboard',
        UserRole.authority => '/authority/dashboard',
        UserRole.superadmin => '/admin/dashboard',
      };
}
