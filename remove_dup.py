
import os

file_path = r'c:/Users/VICTUS/OneDrive/Desktop/python/MedVoice/medVoice/complaints/views.py'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the index of the line starting with "# Duplicate function removed"
idx = -1
for i, line in enumerate(lines):
    if "# Duplicate function removed" in line:
        idx = i
        break

if idx != -1:
    # Write back only up to that line, removing the duplicate function block at the end
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(lines[:idx])
    print(f"Truncated at line {idx+1}")
else:
    print("Target line not found")
