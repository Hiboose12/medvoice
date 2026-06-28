import json
import re

def restore_categories_page(transcript_path, target_file):
    target_content = None
    with open(transcript_path, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                data = json.loads(line)
                if 'tool_calls' in data:
                    for tc in data['tool_calls']:
                        if tc['name'] == 'replace_file_content':
                            if 'TargetContent' in tc['args']:
                                target_content = tc['args']['TargetContent']
            except:
                pass
                
    if not target_content:
        print("TargetContent not found in transcript")
        return

    with open(target_file, 'r', encoding='utf-8') as f:
        content = f.read()

    start_str = "class _CategoriesPage extends StatefulWidget {"
    start_idx = content.find(start_str)
    if start_idx == -1:
        start_str = "class _CategoriesPage extends StatelessWidget {"
        start_idx = content.find(start_str)

    if start_idx == -1:
        print("Start class not found in target file")
        return
        
    end_str = "class _PerformancePage extends StatelessWidget {"
    end_idx = content.find(end_str)
    if end_idx == -1:
        print("End class not found in target file")
        return

    new_content = content[:start_idx] + target_content + "\n" + content[end_idx:]
    
    with open(target_file, 'w', encoding='utf-8') as f:
        f.write(new_content)
        print("CategoriesPage successfully restored from transcript!")

restore_categories_page('C:/Users/VICTUS/.gemini/antigravity-ide/brain/c2f00772-c418-4b37-8715-80fa14e05e9c/.system_generated/logs/transcript.jsonl', 'lib/features/operations/presentation/screens/operational_screen.dart')
