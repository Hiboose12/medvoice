import re

file_path = r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medvoice_flutter\lib\features\admin\data\admin_repository.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_methods = """
  Future<Map<String, dynamic>> fetchUserActivity(int userId) async {
    await _client.init();
    final response = await _client.dio.get(
      Endpoints.adminUserActivity(userId),
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return response.data as Map<String, dynamic>;
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
}"""

content = re.sub(r'}\s*$', new_methods, content)
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Patched admin_repository.dart forcefully")
