import 'package:dio/dio.dart';
import 'package:medvoice_flutter/core/network/dio_client.dart';
import 'package:medvoice_flutter/core/network/endpoints.dart';
import 'package:medvoice_flutter/core/network/response_utils.dart';

class AdminRepository {
  AdminRepository({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  Future<Map<String, dynamic>> getSuperadminDashboard() async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.adminDashboard,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<Map<String, dynamic>> fetchUsers({
    String? search,
    String? role,
    String? status,
    int page = 1,
  }) async {
    await _client.init();
    final Map<String, dynamic> params = {
      if (search != null && search.isNotEmpty) 'search': search,
      if (role != null && role != 'all') 'role': role,
      if (status != null && status != 'all') 'status': status,
      'page': page,
    };
    final response = await _client.dio.get(
      Endpoints.adminUserManagement,
      queryParameters: params,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<Map<String, dynamic>> fetchUserDetail(int userId) async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.adminUserDetail(userId),
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<void> modifyUserStatus(int userId, String action, {String? reason}) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.adminModifyUserStatus(userId),
      data: {
        'action': action,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<Map<String, dynamic>> fetchEntityVerification({
    String? search,
    String? verification,
  }) async {
    await _client.init();
    final Map<String, dynamic> params = {
      if (search != null && search.isNotEmpty) 'search': search,
      if (verification != null && verification != 'all') 'verification': verification,
    };
    final response = await _client.dio.get(
      Endpoints.adminEntityVerification,
      queryParameters: params,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<Map<String, dynamic>> fetchEntityVerificationDetail(String entityType, int entityId) async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.adminEntityVerificationDetail(entityType, entityId),
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<void> verifyEntity(String entityType, int entityId, String action, {String? reason}) async {
    await _client.init();
    final url = action == 'approve' 
        ? Endpoints.adminVerifyEntityApprove(entityType, entityId)
        : Endpoints.adminVerifyEntityReject(entityType, entityId);
        
    await _client.dio.post(
      url,
      data: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<Map<String, dynamic>> fetchAuditLogs({
    String? search,
    String? action,
    String? date,
    String? role,
    int page = 1,
  }) async {
    await _client.init();
    final Map<String, dynamic> params = {
      if (search != null && search.isNotEmpty) 'search': search,
      if (action != null && action != 'all') 'action': action,
      if (date != null && date != 'all') 'date': date,
      if (role != null && role != 'all') 'role': role,
      'page': page,
    };
    final response = await _client.dio.get(
      Endpoints.adminAuditLogs,
      queryParameters: params,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<Map<String, dynamic>> fetchUserActivity(int userId) async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.adminUserActivity(userId),
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<void> performUserAction(int userId, String action) async {
    await _client.init();
    String endpoint;
    switch (action) {
      case 'freeze':
        endpoint = Endpoints.adminUserFreeze(userId);
        break;
      case 'unfreeze':
        endpoint = Endpoints.adminUserUnfreeze(userId);
        break;
      case 'block':
        endpoint = Endpoints.adminUserBlock(userId);
        break;
      case 'unblock':
        endpoint = Endpoints.adminUserUnblock(userId);
        break;
      case 'warn':
        endpoint = Endpoints.adminUserWarn(userId);
        break;
      default:
        throw Exception('Unknown action: $action');
    }
    
    await _client.dio.post(
      endpoint,
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<void> approveHospitalAppeal(int freezeId) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.adminApproveHospitalAppeal(freezeId),
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<void> rejectHospitalAppeal(int freezeId) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.adminRejectHospitalAppeal(freezeId),
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<void> executeUserAction(int userId, String action, {String? reason}) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.adminModifyUserStatus(userId),
      data: {
        'action': action,
        if (reason != null) 'reason': reason,
      },
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<Map<String, dynamic>> fetchSecurityAlerts({String? severity, String? resolved, int page = 1}) async {
    await _client.init();
    final params = <String, dynamic>{
      'page': page,
    };
    if (severity != null && severity != 'all') params['severity'] = severity;
    if (resolved != null && resolved != 'all') params['resolved'] = resolved;
    
    final response = await _client.dio.get(
      Endpoints.adminSecurityMonitoring,
      queryParameters: params,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<void> resolveSecurityAlert(int alertId) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.adminResolveSecurityAlert(alertId),
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<void> triggerSecurityScan() async {
    await _client.init();
    await _client.dio.post(
      Endpoints.adminTriggerSecurityScan,
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<Map<String, dynamic>> fetchSecuritySettings() async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.adminSecuritySettings,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<void> updateSecuritySettings(Map<String, dynamic> settings) async {
    await _client.init();
    await _client.dio.patch(
      Endpoints.adminSecuritySettings,
      data: settings,
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<Map<String, dynamic>> fetchCategories({String? search, int page = 1}) async {
    await _client.init();
    final params = <String, dynamic>{
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
    };
    final response = await _client.dio.get(
      Endpoints.adminCategories,
      queryParameters: params,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<void> addCategory(String name, String description) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.adminCategories,
      data: {
        'name': name,
        'description': description,
      },
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<void> deleteCategory(int categoryId) async {
    await _client.init();
    await _client.dio.delete(
      Endpoints.adminDeleteCategory(categoryId),
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<Map<String, dynamic>> fetchSupportTickets({String? status}) async {
    await _client.init();
    final params = <String, dynamic>{};
    if (status != null && status != 'all') {
      params['status'] = status;
    }
    final response = await _client.dio.get(
      Endpoints.adminSupportTickets,
      queryParameters: params,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<void> replyToSupportTicket(int ticketId, String reply) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.adminSupportTicketReply(ticketId),
      data: {'admin_reply': reply},
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<Map<String, dynamic>> fetchNotifications() async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.notifications,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<void> markNotificationRead(int notificationId) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.markNotificationRead(notificationId),
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.adminProfile,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }
}