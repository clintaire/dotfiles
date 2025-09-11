#!/usr/bin/env python3
from PIL import Image, ImageDraw
import os

# Ayu colors
bg_color = (14, 20, 25)      # #0e1419
selection_color = (36, 51, 64)  # #243340
highlight_color = (241, 150, 24)  # #f19618

# Create selection images
def create_selection_image(width, height, filename):
    img = Image.new('RGBA', (width, height), (*selection_color, 180))
    draw = ImageDraw.Draw(img)
    
    # Add subtle border with highlight color
    draw.rectangle([0, 0, width-1, height-1], outline=(*highlight_color, 200), width=1)
    
    img.save(filename)

# Create the selection images
create_selection_image(1, 1, '/usr/share/grub/themes/ayu-custom/select_c.png')
create_selection_image(8, 1, '/usr/share/grub/themes/ayu-custom/select_w.png')
create_selection_image(1, 8, '/usr/share/grub/themes/ayu-custom/select_e.png')
