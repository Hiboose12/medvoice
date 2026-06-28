import 'package:dio/dio.dart';
import 'package:medvoice_flutter/core/network/dio_client.dart';
import 'package:medvoice_flutter/core/network/endpoints.dart';
import 'package:medvoice_flutter/core/network/response_utils.dart';
import 'package:medvoice_flutter/features/auth/domain/models/user_role.dart';
import 'package:medvoice_flutter/features/patient/domain/models/complaint_post.dart';
import 'package:medvoice_flutter/features/patient/domain/models/dashboard_stats.dart';
import 'package:medvoice_flutter/features/patient/domain/models/patient_models.dart';

/// Patient repository connecting to Django backend.
class PatientRepository {
  PatientRepository({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

Future<List<ComplaintPost>> getComplaintFeed({String? query}) async {
    await _client.init();
    
    final response = await _client.dio.get(
      Endpoints.apiFeed,
      queryParameters: query != null ? {'q': query} : null,
    );

    final data = response.data is List ? response.data as List : (response.data is Map ? (response.data as Map)['complaints'] as List? : null) ?? [];
    return data.map((json) => ComplaintPost.fromJson(json is Map<String, dynamic> ? json : Map<String, dynamic>.from(json as Map))).toList();
  }

  Future<DashboardStats> getDashboardStats() async {
    await _client.init();
    
    final response = await _client.dio.get(Endpoints.apiPatientDashboard);
    final data = response.data;
    
    return DashboardStats(
      totalComplaints: int.tryParse(data['total_complaints']?.toString() ?? '') ?? data['total_complaints'] as int? ?? 0,
      resolvedComplaints: int.tryParse(data['resolved_complaints']?.toString() ?? '') ?? data['resolved_complaints'] as int? ?? 0,
      pendingComplaints: int.tryParse(data['pending_complaints']?.toString() ?? '') ?? data['pending_complaints'] as int? ?? 0,
      recentActivity: (data['recent_activity'] as List<dynamic>? ?? [])
          .map((json) => ComplaintPost.fromJson(json is Map<String, dynamic> ? json : Map<String, dynamic>.from(json as Map)))
          .toList(),
      communityBillingCount: int.tryParse(data['community_billing_count']?.toString() ?? '') ?? data['community_billing_count'] as int? ?? 0,
      communityResolvedToday: int.tryParse(data['community_resolved_today']?.toString() ?? '') ?? data['community_resolved_today'] as int? ?? 0,
    );
  }

  Future<List<ComplaintPost>> getMyComplaints({String? status, String? search}) async {
    await _client.init();
    
    final Map<String, dynamic> params = {
      'status': status != null && status != 'all' ? status : null,
      'q': search,
    };
    params.removeWhere((key, value) => value == null);
    final response = await _client.dio.get(
      Endpoints.apiComplaints,
      queryParameters: params,
    );

    final data = response.data is List ? response.data as List : (response.data is Map ? (response.data as Map)['complaints'] as List? : null) ?? [];
    return data.map((json) => ComplaintPost.fromJson(json is Map<String, dynamic> ? json : Map<String, dynamic>.from(json as Map))).toList();
  }

  Future<ComplaintPost> getComplaintDetail(int complaintId) async {
    await _client.init();
    
    final response = await _client.dio.get(Endpoints.apiComplaintDetail(complaintId));
    return ComplaintPost.fromJson(response.data);
  }

  Future<void> uploadComplaint(FormData formData) async {
    await _client.init();
    
    await _client.dio.post(Endpoints.apiComplaints, data: formData);
  }

  Future<void> addComment(int complaintId, String content) async {
    await _client.init();
    
    await _client.dio.post(
      Endpoints.apiComplaintComments(complaintId),
      data: {'content': content},
    );
  }

  Future<void> toggleLike(int complaintId) async {
    await _client.init();
    
    await _client.dio.post(Endpoints.apiComplaintLike(complaintId));
  }

  Future<void> editComplaint(int complaintId, FormData formData) async {
    await _client.init();
    await _client.dio.put(Endpoints.editComplaint(complaintId), data: formData);
  }

  Future<void> deleteComplaint(int complaintId) async {
    await _client.init();
    await _client.dio.delete(Endpoints.deleteComplaint(complaintId));
  }

  Future<void> markComplaintResolved(int complaintId, String resolution) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.complaintResolve(complaintId),
      data: FormData.fromMap({'resolution': resolution}),
    );
  }

  Future<List<PatientNotification>> getNotifications() async {
    await _client.init();
    
    final response = await _client.dio.get(
      Endpoints.notifications,
      queryParameters: {'all': 1},
    );
    final List<dynamic> data = response.data['notifications'] ?? [];
    return data
        .map((json) => PatientNotification.fromJson(json is Map<String, dynamic> ? json : Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<void> markNotificationRead(int notificationId) async {
    await _client.init();
    await _client.dio.post(Endpoints.markNotificationRead(notificationId));
  }

  Future<List<String>> fetchCategories() async {
    await _client.init();
    final response = await _client.dio.get(Endpoints.publicCategories);
    final List<dynamic> data = response.data;
    return data.map((c) => c['name'] as String).toList();
  }

  Future<void> replyToNotification(int notificationId, String message) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.replyNotification(notificationId),
      data: FormData.fromMap({'reply_message': message}),
    );
  }

  Future<PatientProfile> getPatientProfile() async {
    await _client.init();
    final response = await _client.dio.get(Endpoints.apiUserProfile);
    return PatientProfile.fromJson(toMap(response.data));
  }

  Future<PatientSettingsData> getPatientSettings() async {
    await _client.init();
    final response = await _client.dio.get(Endpoints.patientSettings);
    return PatientSettingsData.fromJson(toMap(response.data));
  }

  Future<void> updatePatientSettings(PatientSettingsData settings) async {
    await _client.init();
    await _client.dio.post(Endpoints.patientSettings, data: settings.toJson());
  }

  Future<PatientComplaintOptions> getComplaintOptions() async {
    await _client.init();
    final response = await _client.dio.get(Endpoints.apiComplaintOptions);
    return PatientComplaintOptions.fromJson(toMap(response.data));
  }

  Future<List<ChatConversation>> getPatientConversations() async {
    await _client.init();
    final response = await _client.dio.get(Endpoints.patientChat);
    final List<dynamic> data = response.data['conversations'] ?? [];
    return data
        .map((json) => ChatConversation.fromJson(json is Map<String, dynamic> ? json : Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<List<ChatMessage>> getChatMessages(int conversationId) async {
    await _client.init();
    final response = await _client.dio.get(Endpoints.chatMessages(conversationId));
    final List<dynamic> data = response.data['messages'] ?? [];
    return data
        .map((json) => ChatMessage.fromJson(json is Map<String, dynamic> ? json : Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<void> sendChatMessage(int conversationId, String content) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.sendMessage(conversationId),
      data: FormData.fromMap({'content': content}),
    );
  }

  Future<ChatConversation> startComplaintChat(int complaintId) async {
    await _client.init();
    final response = await _client.dio.post(Endpoints.startComplaintChat(complaintId));
    return ChatConversation(
      id: response.data['conversation_id'] as int,
      name: 'Hospital',
      role: 'hospital',
      lastMessage: '',
      lastMessageAt: DateTime.now(),
      unreadCount: 0,
    );
  }

  Future<ChatConversation> startChat(int userId) async {
    await _client.init();
    final response = await _client.dio.post(Endpoints.startChat(userId));
    return ChatConversation(
      id: response.data['conversation_id'] as int,
      name: 'User',
      role: 'user',
      lastMessage: '',
      lastMessageAt: DateTime.now(),
      unreadCount: 0,
    );
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    await _client.init();
    await _client.dio.put(
      Endpoints.apiUserProfile,
      data: FormData.fromMap({
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
      }),
    );
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.changePassword,
      data: FormData.fromMap({
        'old_password': oldPassword,
        'new_password1': newPassword,
        'new_password2': newPassword,
      }),
    );
  }

  Future<void> logoutAllDevices() async {
    await _client.init();
    await _client.dio.post(Endpoints.logoutAllDevices);
  }

  Future<void> submitSupportTicket({
    required String subject,
    required String message,
  }) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.contactSupport,
      data: FormData.fromMap({'subject': subject, 'message': message}),
    );
  }

  Future<List<ChatConversation>> getConversations(UserRole role) async {
    await _client.init();
    final String endpoint = switch (role) {
      UserRole.patient => Endpoints.patientChat,
      UserRole.hospital => Endpoints.hospitalChat,
      UserRole.authority => Endpoints.authorityChat,
      _ => Endpoints.patientChat,
    };
    final response = await _client.dio.get(endpoint);
    final List<dynamic> data = response.data['conversations'] ?? [];
    return data
        .map((json) => ChatConversation.fromJson(json is Map<String, dynamic> ? json : Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<List<dynamic>> getSupportTickets() async {
    await _client.init();
    final response = await _client.dio.get(Endpoints.apiSupportTickets);
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getSupportTicketDetail(int id) async {
    await _client.init();
    final response = await _client.dio.get(Endpoints.apiSupportTicketDetail(id));
    return toMap(response.data);
  }

  Future<void> sendSupportTicketReply(int id, String message) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.apiSupportTicketDetail(id),
      data: {'message': message},
    );
  }
}
