// HospitalRepository handling hospital-related API calls
import 'package:dio/dio.dart';
import 'package:medvoice_flutter/core/network/dio_client.dart';
import 'package:medvoice_flutter/core/network/endpoints.dart';
import 'package:medvoice_flutter/core/network/response_utils.dart';
import 'package:medvoice_flutter/features/operations/domain/models/hospital_profile.dart';


class HospitalRepository {
  HospitalRepository({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  Future<Map<String, dynamic>> getDashboardStats() async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.apiHospitalDashboard,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<Map<String, dynamic>> getComplaints({String? status, String? search}) async {
    await _client.init();
    final params = <String, dynamic>{
      if (status != null && status != 'All') 'status': status.toLowerCase(),
      if (search != null && search.isNotEmpty) 'q': search,
    };
    final response = await _client.dio.get(
      Endpoints.apiHospitalComplaints,
      queryParameters: params,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<Map<String, dynamic>> getComplaintDetail(int id) async {
    await _client.init();
    final response = await _client.dio.get(
      '${Endpoints.hospitalComplaintDetail}$id/',
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<void> updateComplaintStatus(int id, String status) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.apiHospitalComplaintResolve(id),
      data: {'status': status.toLowerCase()},
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<void> respondToComplaint(int id, String message, {bool isPrivate = false}) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.apiHospitalComplaintRespond(id),
      data: {'message': message, 'is_private': isPrivate},
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<void> resolveComplaint(int id) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.apiHospitalComplaintResolve(id),
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<HospitalProfile> getProfile() async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.apiHospitalProfile,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return HospitalProfile.fromJson(toMap(response.data));
  }

  Future<Map<String, dynamic>> getNotifications() async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.apiHospitalNotifications,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<void> markNotificationRead(int id) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.apiHospitalMarkNotificationRead(id),
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.init();
    await _client.dio.post(
      Endpoints.hospitalChangePassword,
      data: {
        'old_password': currentPassword,
        'new_password1': newPassword,
        'new_password2': newPassword,
      },
      options: Options(
        headers: {'Accept': 'application/json'},
      ),
    );
  }

  Future<Map<String, dynamic>> getHospitalFeed() async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.hospitalFeed,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return toMap(response.data);
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.apiConversations,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    final data = toMap(response.data);
    final list = data['conversations'];
    if (list is List) {
      return list.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();
    }
    return [];
  }
}
