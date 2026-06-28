import re

def fix_imports(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove the inline import
    content = content.replace("import 'package:url_launcher/url_launcher.dart';\n", "")

    # Add to the top imports
    # Find the first import
    first_import_idx = content.find("import ")
    if first_import_idx != -1:
        new_import = "import 'package:url_launcher/url_launcher.dart';\n"
        content = content[:first_import_idx] + new_import + content[first_import_idx:]
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        print("Fixed imports.")

fix_imports(r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medvoice_flutter\lib\features\operations\presentation\screens\operational_screen.dart')
