import re

file_path = r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medvoice_flutter\lib\features\admin\data\admin_repository.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# The first instance of fetchUserActivity starts with:
start_idx = content.find("Future<Map<String, dynamic>> fetchUserActivity")
if start_idx != -1:
    # Find the second instance
    second_idx = content.find("Future<Map<String, dynamic>> fetchUserActivity", start_idx + 10)
    
    if second_idx != -1:
        # We want to remove everything from start_idx to second_idx
        content = content[:start_idx] + content[second_idx:]
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print("Removed duplicate methods.")
    else:
        print("No duplicate found.")
else:
    print("Method not found.")
