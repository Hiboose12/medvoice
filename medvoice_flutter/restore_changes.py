import json
import os

log_path = r'C:\Users\VICTUS\.gemini\antigravity-ide\brain\bf5f6aaf-2ca7-4fb5-8e7f-84d2d4e5e429\.system_generated\logs\transcript.jsonl'
file_path = r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medvoice_flutter\lib\features\operations\presentation\screens\operational_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

with open(log_path, 'r', encoding='utf-8') as f:
    for line in f:
        data = json.loads(line)
        if data.get('type') == 'PLANNER_RESPONSE':
            tool_calls = data.get('tool_calls', [])
            for call in tool_calls:
                if call['name'] in ['multi_replace_file_content', 'replace_file_content'] and 'operational_screen.dart' in call.get('args', {}).get('TargetFile', ''):
                    args = call['args']
                    if 'ReplacementChunks' in args:
                        try:
                            chunks = json.loads(args['ReplacementChunks'])
                        except:
                            chunks = args['ReplacementChunks']
                        for chunk in chunks:
                            target = chunk.get('TargetContent', '')
                            replacement = chunk.get('ReplacementContent', '')
                            if target in content:
                                content = content.replace(target, replacement)
                                print(f"Successfully applied chunk in step {data.get('step_index')}")
                            else:
                                print(f"Failed to apply chunk in step {data.get('step_index')} - Target not found")
                    elif 'TargetContent' in args:
                        target = args.get('TargetContent', '')
                        replacement = args.get('ReplacementContent', '')
                        if target in content:
                            content = content.replace(target, replacement)
                            print(f"Successfully applied replace in step {data.get('step_index')}")
                        else:
                            print(f"Failed to apply replace in step {data.get('step_index')} - Target not found")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
