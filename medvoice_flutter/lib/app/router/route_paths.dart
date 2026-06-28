/// Canonical route path constants for GoRouter.
abstract final class RoutePaths {
  // Root
  static const String root = '/';

  // Auth
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String pendingApproval = '/pending-approval';
  static const String accountDisabled = '/account-disabled';
  static const String accountFrozen = '/account-frozen';

  // Patient shell
  static const String patient = '/patient';
  static const String patientDashboard = '$patient/dashboard';
  static const String patientFeed = '$patient/feed';
  static const String patientCreatePost = '$patient/create-post';
  static const String patientComplaints = '$patient/complaints';
  static const String patientChat = '$patient/chat';
  static const String patientProfile = '$patient/profile';
  static const String patientNotifications = '$patient/notifications';
  static const String patientSettings = '$patient/settings';
  static const String patientOcrUpload = '$patient/ocr-upload';
  static const String patientOcrProcessing = '$patient/ocr-processing';
  static const String patientOcrResult = '$patient/ocr-result';
  static const String patientSupport = '$patient/support';

  /// Dynamic route: /patient/complaint/:id
  static String patientComplaintDetail(int id) => '$patient/complaint/$id';
  static const String patientComplaintDetailPattern = '$patient/complaint/:id';

  /// Dynamic route: /patient/chat/:id
  static String patientChatDetail(int id) => '$patient/chat-detail/$id';
  static const String patientChatDetailPattern = '$patient/chat-detail/:id';

  // Hospital shell
  static const String hospital = '/hospital';
  static const String hospitalDashboard = '$hospital/dashboard';
  static const String hospitalComplaints = '$hospital/complaints';
  static const String hospitalFeed = '$hospital/feed';
  static const String hospitalChat = '$hospital/chat';
  static const String hospitalProfile = '$hospital/profile';
  static const String hospitalNotifications = '$hospital/notifications';
  static const String hospitalSettings = '$hospital/settings';

  // Authority shell
  static const String authority = '/authority';
  static const String authorityDashboard = '$authority/dashboard';
  static const String authorityComplaints = '$authority/complaints';
  static const String authorityEscalations = '$authority/escalations';
  static const String authorityHospitals = '$authority/hospitals';
  static const String authorityWarnings = '$authority/warnings';
  static const String authorityFeed = '$authority/feed';
  static const String authorityChat = '$authority/chat';
  static const String authorityProfile = '$authority/profile';
  static const String authorityNotifications = '$authority/notifications';
  static const String authoritySettings = '$authority/settings';
  static const String authorityRegulations = '$authority/regulations';

  // Admin shell
  static const String admin = '/admin';
  static const String adminDashboard = '$admin/dashboard';
  static const String adminApprovals = '$admin/approve-users';
  static const String adminUsers = '$admin/users';
  static const String adminCategories = '$admin/categories';
  static const String adminPerformance = '$admin/performance';
  static const String adminSupport = '$admin/support';
  static const String adminNotifications = '$admin/notifications';
  static const String adminProfile = '$admin/profile';
  static const String adminSettings = '$admin/settings';
  static const String adminUserManagement = '$admin/users';
  static const String adminEntityVerification = '$admin/verification';
  static const String adminAuditLogs = '$admin/audit-logs';
  static const String adminSecurityMonitoring = '$admin/security';
  static const String adminSecuritySettings = '$admin/security-settings';
}

