import re

prov_path = r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medvoice_flutter\lib\features\admin\presentation\providers\admin_provider.dart'
with open(prov_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_methods = """
  Future<Map<String, dynamic>?> loadUserActivity(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _repository.fetchUserActivity(userId);
      return data;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> performUserAction(int userId, String action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.performUserAction(userId, action);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}"""

if "loadUserActivity" not in content:
    content = re.sub(r'}\s*$', new_methods, content)
    with open(prov_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Patched admin_provider.dart")

