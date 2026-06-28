import 'package:medvoice_flutter/features/auth/domain/models/user_role.dart';

class Endpoints {
  // ------------------- Auth -------------------
  static const String login = '/api/v1/auth/login/';
  static String register(UserRole role) {
    if (role == UserRole.hospital) {
      return '/api/v1/auth/hospital/register/';
    } else if (role == UserRole.authority) {
      return '/api/v1/auth/authority/register/';
    }
    return '/api/v1/auth/patient/register/';
  }
  static const String validateEmail = '/ajax/validate-email/';
  static const String submitAppeal = '/api/v1/auth/appeal/';
  static const String logout = '/logout/';

  // ------------------- Patient -------------------
  static const String publicCategories = '/api/v1/categories/';
  static const String apiFeed = '/api/v1/feed/';
  static const String apiPatientDashboard = '/api/v1/patient/dashboard/';
  static const String apiComplaintOptions = '/api/v1/complaints/options/';
  static const String apiComplaints = '/api/v1/complaints/';
  static String apiComplaintDetail(int id) => '/api/v1/complaints/$id/';
  static String apiComplaintComments(int id) => '/api/v1/complaints/$id/comments/';
  static String apiComplaintLike(int id) => '/api/v1/complaints/$id/like/';
  static String editComplaint(int id) => '/api/v1/complaints/$id/';
  static String deleteComplaint(int id) => '/api/v1/complaints/$id/';
  static String complaintResolve(int id) => '/api/v1/complaints/$id/resolve/';
  static const String notifications = '/api/v1/notifications/';
  static String markNotificationRead(int id) => '/api/v1/notifications/$id/read/';
  static String replyNotification(int id) => '/api/v1/notifications/$id/reply/';
  static const String apiUserProfile = '/api/v1/users/me/';
  static const String patientSettings = '/api/v1/patient/settings/';
  static const String feed = '/api/v1/feed/';
  static const String patientChat = '/patient/chat/';
  static String chatMessages(int chatId) => '/api/v1/chat/messages/$chatId/';
  static String sendMessage(int chatId) => '/api/v1/chat/send/$chatId/';
  static String startComplaintChat(int complaintId) => '/api/v1/chat/start-complaint/$complaintId/';
  static String startChat(int userId) => '/chat/start/$userId/';
  static const String patientProfileUpdate = '/patient/profile/update/';

  // ------------------- Hospital -------------------
  static const String apiHospitalDashboard = '/api/v1/hospital/dashboard/';
  static const String hospitalComplaintDetail = '/api/v1/hospital/complaints/'; // + id + '/'
  static const String hospitalFeed = '/api/v1/feed/';
  static const String apiSupportTickets = '/api/v1/support/tickets/';
  static String apiSupportTicketDetail(int id) => '/api/v1/support/tickets/$id/';
  static const String apiHospitalComplaints = '/api/v1/hospital/complaints/';
  static String complaintStatusUpdate(int id) => '/api/v1/hospital/complaints/$id/status/';
  static String apiHospitalComplaintRespond(int id) => '/api/v1/hospital/complaints/$id/respond/';
  static String apiHospitalComplaintResolve(int id) => '/api/v1/hospital/complaints/$id/resolve/';
  static const String apiHospitalProfile = '/api/v1/hospital/profile/';
  static const String apiHospitalNotifications = '/api/v1/notifications/';
  static String apiHospitalMarkNotificationRead(int id) => '/api/v1/notifications/$id/read/';
  // ------------------- Additional Endpoints -------------------
  static const String logoutAllDevices = '/auth/logout-all/';
  static const String contactSupport = '/support/contact/';
  static const String hospitalChat = '/hospital/chat/';
  static const String hospitalChangePassword = '/api/change-password/';
  static const String authorityChat = '/authority/chat/';
  static const String apiHospitalFeed = '/api/v1/feed/';
  static const String apiConversations = '/api/v1/conversations/';

  // ------------------- Authority -------------------
  static const String authorityDashboard = '/api/v1/authority/dashboard/';
  static const String authorityComplaints = '/api/v1/authority/complaints/';
  static const String authorityEscalations = '/api/v1/authority/escalations/';
  static const String authorityHospitals = '/api/v1/authority/hospitals/';
  static const String authorityWarnings = '/api/v1/authority/warnings/';
  static const String authorityNotifications = '/api/v1/notifications/';
  static const String authoritySettings = '/api/v1/authority/settings/';
  static const String authorityProfile = '/api/v1/authority/profile/';
  static const String authorityFeed = '/api/v1/authority/feed/';
  static String authorityIssueWarning(int hospitalId) => '/api/v1/authority/hospitals/$hospitalId/warning/';
  static String authorityFreezeHospital(int hospitalId) => '/api/v1/authority/hospitals/$hospitalId/freeze/';
  static String authorityUnfreezeHospital(int hospitalId) => '/api/v1/authority/hospitals/$hospitalId/unfreeze/';
  static String authorityMarkNotificationRead(int notificationId) => '/api/v1/notifications/$notificationId/read/';
  static String authorityComplaintDetail(int complaintId) => '/api/v1/authority/complaints/$complaintId/';
  static String authorityHospitalDetail(int hospitalId) => '/api/v1/authority/hospitals/$hospitalId/';

  // ------------------- Admin -------------------
  static const String adminDashboard = '/api/v1/admin/dashboard/';
  static const String adminUserManagement = '/api/v1/admin/users/';
  static String adminUserDetail(int userId) => '/api/v1/admin/user/$userId/';
  static String adminModifyUserStatus(int userId) => '/api/v1/admin/user/$userId/status/';
  static const String adminEntityVerification = '/api/v1/superadmin/verification/';
  static String adminEntityVerificationDetail(String entityType, int entityId) => '/api/v1/superadmin/verification/$entityType/$entityId/';
  static String adminVerifyEntityApprove(String entityType, int entityId) => '/api/v1/superadmin/verification/$entityType/$entityId/approve/';
  static String adminVerifyEntityReject(String entityType, int entityId) => '/api/v1/superadmin/verification/$entityType/$entityId/reject/';
  static const String adminAuditLogs = '/api/v1/superadmin/audit-logs/';
  static String adminUserActivity(int userId) => '/api/v1/superadmin/users/$userId/activity/';
  static String adminUserFreeze(int userId) => '/api/v1/superadmin/users/$userId/freeze/';
  static String adminUserUnfreeze(int userId) => '/api/v1/superadmin/users/$userId/unfreeze/';
  static String adminUserBlock(int userId) => '/api/v1/superadmin/users/$userId/block/';
  static String adminUserUnblock(int userId) => '/api/v1/superadmin/users/$userId/unblock/';
  static String adminUserWarn(int userId) => '/api/v1/superadmin/users/$userId/warn/';
  static String adminUserReactivate(int userId) => '/api/v1/superadmin/users/$userId/reactivate/';
  static String adminApproveHospitalAppeal(int freezeId) => '/api/v1/superadmin/hospital-freeze/$freezeId/approve/';
  static String adminRejectHospitalAppeal(int freezeId) => '/api/v1/superadmin/hospital-freeze/$freezeId/reject/';
  static const String adminProfile = '/api/v1/admin/profile/';
  static const String adminSecurityMonitoring = '/api/v1/admin/security/monitoring/';
  static const String adminCategories = '/api/v1/admin/categories/';
  static String adminDeleteCategory(int categoryId) => '/api/v1/admin/categories/$categoryId/';
  static String adminResolveSecurityAlert(int alertId) => '/api/v1/admin/security/alert/$alertId/resolve/';
  static const String adminTriggerSecurityScan = '/api/v1/admin/security/scan/trigger/';
  static const String adminSecuritySettings = '/api/v1/admin/security/settings/';
  static const String adminSupportTickets = '/api/v1/admin/support/tickets/';
  static String adminSupportTicketReply(int id) => '/api/v1/admin/support/tickets/$id/reply/';

  // ------------------- Common -------------------
  static const String changePassword = '/change-password/';
}
