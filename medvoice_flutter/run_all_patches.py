import os
import subprocess

scripts = [
    'replace_dashboard.py',
    'replace_entity_verification.py',
    'patch_review_details.py',
    'fix_infinite_loading.py',
]

for script in scripts:
    if os.path.exists(script):
        print(f"Running {script}...")
        result = subprocess.run(['python', script], capture_output=True, text=True)
        print(result.stdout)
        if result.stderr:
            print("Error:", result.stderr)
    else:
        print(f"File not found: {script}")
