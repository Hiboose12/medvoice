import re

repo_path = r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medvoice_flutter\lib\features\admin\data\admin_repository.dart'
with open(repo_path, 'r', encoding='utf-8') as f:
    content = f.read()
    
content = content.replace("ApiConstants.adminUserActivity", "Endpoints.adminUserActivity")
content = content.replace("ApiConstants.adminUserFreeze", "Endpoints.adminUserFreeze")
content = content.replace("ApiConstants.adminUserUnfreeze", "Endpoints.adminUserUnfreeze")
content = content.replace("ApiConstants.adminUserBlock", "Endpoints.adminUserBlock")
content = content.replace("ApiConstants.adminUserUnblock", "Endpoints.adminUserUnblock")
content = content.replace("ApiConstants.adminUserWarn", "Endpoints.adminUserWarn")

with open(repo_path, 'w', encoding='utf-8') as f:
    f.write(content)

endpoints_path = r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medvoice_flutter\lib\core\network\endpoints.dart'
with open(endpoints_path, 'r', encoding='utf-8') as f:
    endpoints_content = f.read()

new_endpoints = """
  // User Actions
  static String adminUserActivity(int userId) => '/api/admin/users/$userId/activity/';
  static String adminUserFreeze(int userId) => '/api/admin/users/$userId/freeze/';
  static String adminUserUnfreeze(int userId) => '/api/admin/users/$userId/unfreeze/';
  static String adminUserBlock(int userId) => '/api/admin/users/$userId/block/';
  static String adminUserUnblock(int userId) => '/api/admin/users/$userId/unblock/';
  static String adminUserWarn(int userId) => '/api/admin/users/$userId/warn/';
"""

if "adminUserActivity" not in endpoints_content:
    # insert before the last closing brace
    idx = endpoints_content.rfind('}')
    endpoints_content = endpoints_content[:idx] + new_endpoints + endpoints_content[idx:]
    with open(endpoints_path, 'w', encoding='utf-8') as f:
        f.write(endpoints_content)

print("Fixed endpoints")
