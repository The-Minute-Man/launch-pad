import os
import re

svg_dir = 'ui/icons'

for filename in os.listdir(svg_dir):
    if not filename.endswith('.svg'):
        continue
    filepath = os.path.join(svg_dir, filename)
    with open(filepath, 'r') as f:
        content = f.read()
    
    # 1. Replace all stroke="currentColor" and stroke="#anyHex" (EXCEPT stroke="none") with stroke="#ebebda"
    # We will match stroke="#..." and stroke="currentColor"
    content = re.sub(r'stroke="currentColor"', 'stroke="#ebebda"', content)
    content = re.sub(r'stroke="#[0-9a-fA-F]+"', 'stroke="#ebebda"', content)
    
    # 2. Force stroke-width="1.5" anywhere it is defined (so we don't add it where it shouldn't be)
    content = re.sub(r'stroke-width="[0-9.]+"', 'stroke-width="1.5"', content)
    
    # 3. Fix the SVG header dimensions
    svg_header_match = re.search(r'<svg[^>]+>', content)
    if svg_header_match:
        header = svg_header_match.group(0)
        
        # Enforce width="128" and height="128"
        if 'width=' in header:
            header = re.sub(r'width="[^"]+"', 'width="128"', header)
        else:
            header = header.replace('<svg ', '<svg width="128" ')
            
        if 'height=' in header:
            header = re.sub(r'height="[^"]+"', 'height="128"', header)
        else:
            header = header.replace('<svg ', '<svg height="128" ')
            
        if 'viewBox' not in header:
            header = header.replace('<svg ', '<svg viewBox="0 0 24 24" ')
            
        content = content.replace(svg_header_match.group(0), header)
        
    with open(filepath, 'w') as f:
        f.write(content)
        
    print(f"Perfectly normalized {filename}")
