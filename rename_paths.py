import os

def replace_in_file(filepath, old_str, new_str):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    if old_str in content:
        content = content.replace(old_str, new_str)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk('.'):
    for file in files:
        if file.endswith('.tscn') or file.endswith('.gd') or file.endswith('.tres'):
            replace_in_file(os.path.join(root, file), 'res://ui/images/', 'res://ui/icons/')
