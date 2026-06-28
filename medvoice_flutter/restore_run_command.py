import json

def restore_from_run_command(transcript_path, target_file):
    output_text = None
    with open(transcript_path, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                data = json.loads(line)
                if data.get('type') == 'PLANNER_RESPONSE' and 'tool_calls' in data:
                    pass
                elif 'output' in data and 'Select-String "class _CategoriesPage" -Context 0,510' in data.get('output', ''):
                    # this might be the echo of the command
                    pass
                if 'output' in data and '> class _CategoriesPage extends StatefulWidget {' in data.get('output', ''):
                    output_text = data['output']
            except:
                pass

    if not output_text:
        # let's look for just the output that has the class
        with open(transcript_path, 'r', encoding='utf-8') as f:
            for line in f:
                try:
                    data = json.loads(line)
                    if 'output' in data and 'class _CategoriesPage extends StatefulWidget {' in data['output'] and 'class _PerformancePage' in data['output']:
                        output_text = data['output']
                except:
                    pass

    if not output_text:
        print("Could not find the output text")
        return

    # Extract lines between '> class _CategoriesPage' and 'class _PerformancePage' (or end of _CategoriesPageState)
    lines = output_text.split('\n')
    extracted = []
    started = False
    for l in lines:
        if l.startswith('> class _CategoriesPage extends StatefulWidget {') or l.startswith('class _CategoriesPage extends StatefulWidget {'):
            started = True
            extracted.append('class _CategoriesPage extends StatefulWidget {')
            continue
        if started:
            if l.startswith('class _PerformancePage'):
                break
            # Remove any leading '> ' if present (Select-String output)
            if l.startswith('> '):
                extracted.append(l[2:])
            else:
                extracted.append(l)

    # remove trailing empty lines
    while extracted and not extracted[-1].strip():
        extracted.pop()

    recovered_code = '\n'.join(extracted)

    with open(target_file, 'r', encoding='utf-8') as f:
        content = f.read()

    start_str = "class _CategoriesPage extends StatelessWidget {"
    start_idx = content.find(start_str)
    if start_idx == -1:
        print("Could not find start index in file")
        return
        
    end_str = "class _PerformancePage extends StatelessWidget {"
    end_idx = content.find(end_str)
    if end_idx == -1:
        print("Could not find end index in file")
        return

    new_content = content[:start_idx] + recovered_code + "\n\n" + content[end_idx:]

    with open(target_file, 'w', encoding='utf-8') as f:
        f.write(new_content)
        print("Successfully restored!")

restore_from_run_command('C:/Users/VICTUS/.gemini/antigravity-ide/brain/c2f00772-c418-4b37-8715-80fa14e05e9c/.system_generated/logs/transcript.jsonl', 'lib/features/operations/presentation/screens/operational_screen.dart')
