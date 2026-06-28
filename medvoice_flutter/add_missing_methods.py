import re

file_path = r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medvoice_flutter\lib\features\admin\data\admin_repository.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

missing_methods = """
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

  Future<Map<String, dynamic>> fetchSecurityAlerts({String? severity, bool? resolved}) async {
    await _client.init();
    final params = <String, dynamic>{};
    if (severity != null && severity != 'all') params['severity'] = severity;
    if (resolved != null) params['resolved'] = resolved;
    
    final response = await _client.dio.get(
      Endpoints.adminSecurityMonitoring,
      queryParameters: params,
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return response.data as Map<String, dynamic>;
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
    return response.data as Map<String, dynamic>;
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
    return response.data as Map<String, dynamic>;
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
}"""

content = re.sub(r'}\s*$', missing_methods, content)
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Re-added missing methods to admin_repository.dart")
