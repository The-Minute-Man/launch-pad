import os
import re

svg_dir = 'ui/icons'

for root, dirs, files in os.walk(svg_dir):
    for filename in files:
        if not filename.endswith('.svg'):
            continue
        filepath = os.path.join(root, filename)
        with open(filepath, 'r') as f:
            content = f.read()
    
        # 1. Replace all stroke="currentColor" and stroke="#anyHex" (EXCEPT stroke="none") with stroke="#ebebda"
        content = re.sub(r'stroke="currentColor"', 'stroke="#ebebda"', content)
        content = re.sub(r'stroke="#[0-9a-fA-F]+"', 'stroke="#ebebda"', content)
        
        # Replace fill="transparent" with fill="none" (Godot interprets transparent as black sometimes)
        content = content.replace('fill="transparent"', 'fill="none"')
        
        # Also ensure SVG header has fill="none" if it's not there, or at least replace black fill if present
        content = re.sub(r'fill="#000000"', 'fill="none"', content)
        content = re.sub(r'fill="black"', 'fill="none"', content)
        
        # 2. Adjust stroke-width based on viewBox size to maintain relative thickness
        viewbox_match = re.search(r'viewBox="0 0 ([0-9.]+) ([0-9.]+)"', content)
        scale = 1.0
        if viewbox_match:
            width = float(viewbox_match.group(1))
            scale = width / 24.0
        
        new_stroke_width = 1.5 * scale
        
        if 'stroke-width=' in content:
            content = re.sub(r'stroke-width="[0-9.]+"', f'stroke-width="{new_stroke_width:.1f}"', content)
        else:
            # If no stroke-width is defined anywhere, add it to the svg tag
            content = content.replace('<svg ', f'<svg stroke-width="{new_stroke_width:.1f}" ')
        
        # 3. Fix the SVG header dimensions
        svg_header_match = re.search(r'<svg[^>]+>', content)
        if svg_header_match:
            header = svg_header_match.group(0)
            
            # Enforce width="128" and height="128"
            if ' width=' in header:
                header = re.sub(r' width="[^"]+"', ' width="128"', header)
            else:
                header = header.replace('<svg ', '<svg width="128" ')
                
            if ' height=' in header:
                header = re.sub(r' height="[^"]+"', ' height="128"', header)
            else:
                header = header.replace('<svg ', '<svg height="128" ')
                
            if 'viewBox' not in header:
                header = header.replace('<svg ', '<svg viewBox="0 0 24 24" ')
                
            content = content.replace(svg_header_match.group(0), header)
            
        with open(filepath, 'w') as f:
            f.write(content)
            
        print(f"Perfectly normalized {filepath}")


