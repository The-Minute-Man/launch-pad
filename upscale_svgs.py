import os
import re

svg_dir = 'ui/icons'

for filename in os.listdir(svg_dir):
    if not filename.endswith('.svg'):
        continue
    filepath = os.path.join(svg_dir, filename)
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Standardize the SVG header
    # We want width="128" height="128" viewBox="0 0 24 24" stroke="#ebebda" stroke-width="1.5" fill="none"
    
    svg_header_match = re.search(r'<svg[^>]+>', content)
    if svg_header_match:
        header = svg_header_match.group(0)
        
        # Replace existing stroke attributes globally in the whole SVG first just in case
        content = re.sub(r'stroke="[^"]+"', 'stroke="#ebebda"', content)
        content = re.sub(r'stroke-width="[^"]+"', 'stroke-width="1.5"', content)
        
        # Then strictly enforce the header
        # Because we already replaced stroke-width in content, the header match is outdated.
        # Let's re-match it.
        svg_header_match = re.search(r'<svg[^>]+>', content)
        header = svg_header_match.group(0)
        
        header = re.sub(r'width="[^"]+"', 'width="128"', header)
        header = re.sub(r'height="[^"]+"', 'height="128"', header)
        # Ensure they have viewBox
        if 'viewBox' not in header:
            header = header.replace('<svg ', '<svg viewBox="0 0 24 24" ')
        
        content = content.replace(svg_header_match.group(0), header)
        
    with open(filepath, 'w') as f:
        f.write(content)
        
    print(f"Upscaled and Normalized {filename}")
