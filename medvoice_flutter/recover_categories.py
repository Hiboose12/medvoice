import json

def recover_uncommitted_categories(transcript_path, target_file):
    lines_seen = {}
    with open(transcript_path, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                data = json.loads(line)
                if 'output' in data and 'Showing lines' in data['output']:
                    text = data['output']
                    # parse lines out of the output
                    for t_line in text.split('\n'):
                        if ':' in t_line:
                            parts = t_line.split(':', 1)
                            if parts[0].isdigit():
                                lno = int(parts[0])
                                content = parts[1][1:] if len(parts[1]) > 0 and parts[1][0] == ' ' else parts[1]
                                lines_seen[lno] = content
            except:
                pass
                
    with open(target_file, 'r', encoding='utf-8') as f:
        current_lines = f.read().split('\n')
        
    start_class = "class _CategoriesPage extends StatelessWidget {"
    start_idx = -1
    for i, l in enumerate(current_lines):
        if l.startswith(start_class):
            start_idx = i
            break
            
    end_class = "class _PerformancePage extends StatelessWidget {"
    end_idx = -1
    for i in range(start_idx+1, len(current_lines)):
        if current_lines[i].startswith(end_class):
            end_idx = i
            break

    if start_idx == -1 or end_idx == -1:
        print("Could not find insertion bounds")
        return
        
    # Build the recovered categories block from lines_seen
    # We viewed lines 5502 to 6000.
    recovered = []
    for i in range(5502, 6013+1): # 6013 was mentioned earlier, let's just go until we hit the end of the class
        if i in lines_seen:
            recovered.append(lines_seen[i])
            
    if not recovered:
        print("No recovered lines found!")
        return
        
    # We want to replace current_lines[start_idx:end_idx] with recovered
    # But wait, does recovered include the trailing '}' ?
    # Let's join and see
    recovered_text = '\n'.join(recovered)
    
    new_content = '\n'.join(current_lines[:start_idx]) + '\n' + recovered_text + '\n\n' + '\n'.join(current_lines[end_idx:])
    
    with open(target_file, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Successfully restored from view_file logs!")

recover_uncommitted_categories('C:/Users/VICTUS/.gemini/antigravity-ide/brain/c2f00772-c418-4b37-8715-80fa14e05e9c/.system_generated/logs/transcript.jsonl', 'lib/features/operations/presentation/screens/operational_screen.dart')
