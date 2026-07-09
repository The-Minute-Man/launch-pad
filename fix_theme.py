import sys

with open('ui/themes/Rajdhani.tres', 'r') as f:
    content = f.read()
    
if 'TooltipLabel' not in content:
    with open('ui/themes/Rajdhani.tres', 'a') as f:
        f.write('\nTooltipLabel/font_sizes/font_size = 18\nTooltipLabel/fonts/font = ExtResource("1_eoogs")\n')
