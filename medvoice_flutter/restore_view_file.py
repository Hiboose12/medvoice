import json

def restore_from_view_file(transcript_path, target_file):
    lines_seen = {}
    with open(transcript_path, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                data = json.loads(line)
                if data.get('type') == 'VIEW_FILE' or data.get('type') == 'PLANNER_RESPONSE':
                    if 'output' in data and 'Showing lines ' in data['output']:
                        text = data['output']
                        for t_line in text.split('\n'):
                            # Format: <line_number>: <original_line>
                            # We might have \r at the end, so strip it from right
                            t_line = t_line.rstrip('\r\n')
                            parts = t_line.split(':', 1)
                            if len(parts) == 2 and parts[0].isdigit():
                                lno = int(parts[0])
                                content = parts[1]
                                if content.startswith(' '):
                                    content = content[1:]
                                lines_seen[lno] = content
            except:
                pass

    if not lines_seen:
        # maybe it's in content, not output?
        with open(transcript_path, 'r', encoding='utf-8') as f:
            for line in f:
                try:
                    data = json.loads(line)
                    if 'content' in data and 'Showing lines ' in data['content']:
                        text = data['content']
                        for t_line in text.split('\n'):
                            t_line = t_line.rstrip('\r\n')
                            parts = t_line.split(':', 1)
                            if len(parts) == 2 and parts[0].isdigit():
                                lno = int(parts[0])
                                content = parts[1]
                                if content.startswith(' '):
                                    content = content[1:]
                                lines_seen[lno] = content
                except:
                    pass

    if not lines_seen:
        print("No lines seen!")
        return

    # Let's collect lines 5502 to 6013
    recovered = []
    # Find the maximum line we have consecutively from 5502
    for i in range(5502, 6050):
        if i in lines_seen:
            recovered.append(lines_seen[i])
        else:
            break

    if not recovered:
        print("No recovered lines found!")
        return

    print(f"Recovered {len(recovered)} lines!")

    recovered_code = '\n'.join(recovered)
    # Ensure it ends correctly, it might just stop mid-code.
    # But wait, my view_file went up to 6000. It doesn't have the closing '  }\n}'!
    # I can append it manually.
    if not recovered_code.strip().endswith('}'):
        recovered_code += "\n                    ],\n                  ),\n              ],\n            ),\n          ),\n        ],\n      ),\n    );\n  }\n}"

    with open(target_file, 'r', encoding='utf-8') as f:
        content = f.read()

    start_str = "class _CategoriesPage extends StatelessWidget {"
    start_idx = content.find(start_str)
    if start_idx == -1:
        print("Could not find start index")
        return
        
    end_str = "class _PerformancePage extends StatelessWidget {"
    end_idx = content.find(end_str)
    if end_idx == -1:
        print("Could not find end index")
        return

    new_content = content[:start_idx] + recovered_code + "\n\n" + content[end_idx:]

    with open(target_file, 'w', encoding='utf-8') as f:
        f.write(new_content)
        print("Successfully restored from view_file logs!")

restore_from_view_file('C:/Users/VICTUS/.gemini/antigravity-ide/brain/c2f00772-c418-4b37-8715-80fa14e05e9c/.system_generated/logs/transcript.jsonl', 'lib/features/operations/presentation/screens/operational_screen.dart')
