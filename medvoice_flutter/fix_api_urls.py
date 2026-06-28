import re

file_path = r'c:\Users\VICTUS\OneDrive\Desktop\medvoice\MedVoice\medVoice\api\api_urls.py'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
for idx, line in enumerate(lines):
    if "api_views.feed_api" in line:
        continue
    if "api_views.submit_complaint_api" in line:
        continue
    new_lines.append(line)

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
print("Removed incorrect lines.")
