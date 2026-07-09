import os

def fix_svg(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    content = content.replace('stroke="currentColor"', 'stroke="#ebebda"')
    content = content.replace('stroke-width="2"', 'stroke-width="1.5"')
    with open(filepath, 'w') as f:
        f.write(content)

fix_svg('ui/icons/data.svg')
fix_svg('ui/icons/export.svg')
