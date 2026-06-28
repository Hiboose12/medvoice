import json
import codecs

def fix_categories_page(target_file):
    with open(target_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # The bad insertion starts with: "class _CategoriesPage extends StatefulWidget {
    start_str = '"class _CategoriesPage extends StatefulWidget {'
    start_idx = content.find(start_str)
    
    if start_idx == -1:
        print("Bad start not found")
        return
        
    end_str = "class _PerformancePage extends StatelessWidget {"
    end_idx = content.find(end_str)
    if end_idx == -1:
        print("End class not found")
        return

    # Extract the bad string block
    bad_str = content[start_idx:end_idx]
    
    # We need to unescape it. It seems it might be a JSON encoded string.
    try:
        # Try to parse it as JSON string
        # It might have a trailing newline before end_idx, so let's strip whitespace
        cleaned = bad_str.strip()
        if cleaned.startswith('"') and cleaned.endswith('"'):
            good_str = json.loads(cleaned)
        else:
            # Maybe it just has literal \n and starts with "
            if cleaned.startswith('"'):
                cleaned = cleaned[1:]
            if cleaned.endswith('"'):
                cleaned = cleaned[:-1]
            good_str = codecs.decode(cleaned, 'unicode_escape')
    except Exception as e:
        print("Error unescaping:", e)
        # fallback unescape
        cleaned = bad_str.strip()
        if cleaned.startswith('"'):
            cleaned = cleaned[1:]
        if cleaned.endswith('"'):
            cleaned = cleaned[:-1]
        good_str = cleaned.replace('\\n', '\n').replace('\\"', '"')

    new_content = content[:start_idx] + good_str + "\n\n" + content[end_idx:]
    
    with open(target_file, 'w', encoding='utf-8') as f:
        f.write(new_content)
        print("Successfully fixed!")

fix_categories_page('lib/features/operations/presentation/screens/operational_screen.dart')
