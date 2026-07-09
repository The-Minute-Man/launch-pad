import sys

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    content = content.replace('parent="VBoxLayout/ContentMargin', 'parent="VBoxLayout/HBoxLayout/ContentMargin')
    with open(filepath, 'w') as f:
        f.write(content)
        
fix_file('scenes/project_screen.tscn')
fix_file('scenes/project_editor_screen.tscn')
