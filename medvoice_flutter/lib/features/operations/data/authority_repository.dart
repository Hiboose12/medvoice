import 'package:dio/dio.dart';
import 'package:medvoice_flutter/core/network/dio_client.dart';
import 'package:medvoice_flutter/core/network/endpoints.dart';
import 'package:medvoice_flutter/core/network/response_utils.dart';

class AuthorityRepository {
  AuthorityRepository({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  Future<Map<String, dynamic>> getDashboardStats() async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.authorityDashboard,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<Map<String, dynamic>> getProfile() async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.authorityProfile,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    await _client.init();
    final response = await _client.dio.put(
      Endpoints.authorityProfile,
      data: data,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<List<dynamic>> getFeed() async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.authorityFeed,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    final data = response.data;
    if (data is Map && data.containsKey('results')) {
      return data['results'] as List<dynamic>;
    } else if (data is List) {
      return data;
    }
    return [];
  }

  Future<Map<String, dynamic>> getComplaints({
    String? status,
    String? severity,
    String? search,
  }) async {
    await _client.init();
    final Map<String, dynamic> params = {
      if (status != null && status != 'All') 'status': status.toLowerCase(),
      if (severity != null && severity != 'All') 'severity': severity.toLowerCase(),
      if (search != null && search.isNotEmpty) 'q': search,
    };
    final response = await _client.dio.get(
      Endpoints.authorityComplaints,
      queryParameters: params,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<Map<String, dynamic>> getEscalations() async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.authorityEscalations,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<Map<String, dynamic>> getHospitals({
    String? status,
    String? search,
  }) async {
    await _client.init();
    final Map<String, dynamic> params = {
      if (status != null && status != 'All') 'status': status.toLowerCase(),
      if (search != null && search.isNotEmpty) 'q': search,
    };
    final response = await _client.dio.get(
      Endpoints.authorityHospitals,
      queryParameters: params,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<Map<String, dynamic>> getWarnings() async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.authorityWarnings,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<Map<String, dynamic>> getNotifications() async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.authorityNotifications,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<Map<String, dynamic>> getSettings() async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.authoritySettings,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.authoritySettings,
      data: data,
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<void> issueWarning(int hospitalId, Map<String, dynamic> data) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.authorityIssueWarning(hospitalId),
      data: data,
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<void> freezeHospital(int hospitalId, Map<String, dynamic> data) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.authorityFreezeHospital(hospitalId),
      data: data,
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<void> unfreezeHospital(int hospitalId) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.authorityUnfreezeHospital(hospitalId),
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<void> markNotificationRead(int notificationId) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.authorityMarkNotificationRead(notificationId),
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<Map<String, dynamic>> getComplaintDetail(int complaintId) async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.authorityComplaintDetail(complaintId),
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<Map<String, dynamic>> getHospitalDetail(int hospitalId) async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.authorityHospitalDetail(hospitalId),
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }
}
