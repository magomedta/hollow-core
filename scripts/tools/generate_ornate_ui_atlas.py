# hollow_core/scripts/tools/generate_ornate_ui_atlas.py
"""
Generates high-resolution RGBA textures for Hollow Core matching the
Ornate Dark Steampunk / Gothic Filigree UI style specified in media_1794584154612_c29e3d32.jpg.
Creates:
1. ornate_frame_9slice.png (Main window frame with bronze filigree corners, steel borders, dark slate fill)
2. ornate_frame_light_9slice.png (Inner sub-container frame with notched corners)
3. ornate_header_plaque.png (Stepped trapezoidal title plate with brass tabs)
4. ornate_button_normal.png, hover.png, pressed.png (Framed metallic square buttons)
5. ornate_bar_frame_9slice.png (Segmented progress bar rail with bronze chevron endcaps)
6. pip_fill_amber.png, pip_fill_red.png, pip_fill_green.png, pip_fill_blue.png, pip_slot_empty.png
7. ornate_corner_bracket.png (Individual corner filigree accent)
"""

import os
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

OUTPUT_DIR = "hollow_core/textures/ui"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Palette Definitions
COLOR_BG_DARK = (10, 13, 19, 235)         # Deep abyssal slate fill
COLOR_BG_CONTAINER = (14, 18, 25, 245)    # Sub-container fill
COLOR_STEEL_DARK = (20, 28, 38, 255)      # Outer steel boundary
COLOR_STEEL_MID = (46, 75, 110, 255)      # Sapphire steel blue line
COLOR_STEEL_LIGHT = (72, 114, 160, 255)   # Metallic steel highlight
COLOR_BRONZE_DARK = (58, 39, 24, 255)     # Deep shadow bronze
COLOR_BRONZE_MID = (138, 103, 62, 255)    # Antique bronze body
COLOR_BRONZE_LIGHT = (202, 164, 110, 255) # Warm brass highlight
COLOR_BRONZE_GOLD = (238, 218, 176, 255)  # Specular edge chiseled gold

def draw_chiseled_corner(draw, x0, y0, x1, y1, flip_x=False, flip_y=False):
    """Draws an intricate geometric chiseled bronze corner bracket."""
    w = abs(x1 - x0)
    h = abs(y1 - y0)
    
    # We create a local image to draw the corner in canonical top-left, then transform
    corner_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cdraw = ImageDraw.Draw(corner_img)
    
    # Outer chiseled stepped bracket
    # Stepped outer boundary
    poly_outer = [
        (0, 0), (w - 2, 0), (w - 2, 8),
        (16, 8), (8, 16),
        (8, h - 2), (0, h - 2)
    ]
    cdraw.polygon(poly_outer, fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK)
    
    # Outer bevel highlight line
    cdraw.line([(1, 1), (w - 3, 1)], fill=COLOR_BRONZE_GOLD, width=1)
    cdraw.line([(1, 1), (1, h - 3)], fill=COLOR_BRONZE_GOLD, width=1)
    cdraw.line([(w - 2, 1), (w - 2, 7)], fill=COLOR_BRONZE_LIGHT, width=1)
    cdraw.line([(1, h - 2), (7, h - 2)], fill=COLOR_BRONZE_LIGHT, width=1)
    
    # Diagonal stepped corner chamfer
    cdraw.polygon([(0, 0), (12, 0), (0, 12)], fill=COLOR_BRONZE_GOLD)
    cdraw.polygon([(0, 0), (6, 0), (0, 6)], fill=COLOR_BRONZE_LIGHT)
    
    # Inner geometric filigree diamond & chevrons
    poly_filigree = [
        (10, 10), (18, 10), (22, 14), (22, 22), (14, 22), (10, 18)
    ]
    cdraw.polygon(poly_filigree, fill=COLOR_BRONZE_DARK, outline=COLOR_BRONZE_LIGHT)
    
    # Center diamond jewel/flange
    diamond = [(16, 12), (20, 16), (16, 20), (12, 16)]
    cdraw.polygon(diamond, fill=COLOR_BRONZE_GOLD, outline=COLOR_BRONZE_DARK)
    cdraw.point((16, 16), fill=(255, 255, 240, 255))
    
    # Corner stepped notches along arms
    cdraw.rectangle([w - 10, 2, w - 4, 6], fill=COLOR_BRONZE_GOLD, outline=COLOR_BRONZE_DARK)
    cdraw.rectangle([2, h - 10, 6, h - 4], fill=COLOR_BRONZE_GOLD, outline=COLOR_BRONZE_DARK)
    
    # Inner diagonal cross-strut
    cdraw.line([(18, 18), (w - 4, h - 4)], fill=COLOR_BRONZE_MID, width=2)
    cdraw.line([(18, 18), (w - 4, h - 4)], fill=COLOR_BRONZE_GOLD, width=1)
    
    # Apply flip if requested
    if flip_x:
        corner_img = corner_img.transpose(Image.FLIP_LEFT_RIGHT)
    if flip_y:
        corner_img = corner_img.transpose(Image.FLIP_TOP_BOTTOM)
        
    return corner_img

def generate_ornate_frame_9slice():
    """Generates the primary 128x128 9-slice frame with bronze corners and sapphire steel rails."""
    size = 128
    corner_size = 40
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 1. Dark abyssal slate background
    draw.rectangle([6, 6, size - 7, size - 7], fill=COLOR_BG_DARK)
    
    # 2. Double steel border rails
    # Outer steel rail
    draw.rectangle([6, 6, size - 7, size - 7], outline=COLOR_STEEL_DARK, width=1)
    # Vibrant sapphire blue steel channel
    draw.rectangle([9, 9, size - 10, size - 10], outline=COLOR_STEEL_MID, width=2)
    # Bright inner steel highlight rim
    draw.rectangle([11, 11, size - 12, size - 12], outline=COLOR_STEEL_LIGHT, width=1)
    # Inner border edge
    draw.rectangle([14, 14, size - 15, size - 15], outline=COLOR_STEEL_DARK, width=1)
    
    # 3. Bronze corner brackets on all 4 corners
    tl = draw_chiseled_corner(draw, 0, 0, corner_size, corner_size, False, False)
    tr = draw_chiseled_corner(draw, 0, 0, corner_size, corner_size, True, False)
    bl = draw_chiseled_corner(draw, 0, 0, corner_size, corner_size, False, True)
    br = draw_chiseled_corner(draw, 0, 0, corner_size, corner_size, True, True)
    
    img.paste(tl, (2, 2), tl)
    img.paste(tr, (size - corner_size - 2, 2), tr)
    img.paste(bl, (2, size - corner_size - 2), bl)
    img.paste(br, (size - corner_size - 2, size - corner_size - 2), br)
    
    # Center edge metal connector clips (top, bottom, left, right)
    # Top clip
    draw.rectangle([size//2 - 12, 4, size//2 + 12, 13], fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK)
    draw.line([(size//2 - 10, 6), (size//2 + 10, 6)], fill=COLOR_BRONZE_GOLD)
    # Bottom clip
    draw.rectangle([size//2 - 12, size - 14, size//2 + 12, size - 5], fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK)
    draw.line([(size//2 - 10, size - 7), (size//2 + 10, size - 7)], fill=COLOR_BRONZE_GOLD)
    # Left clip
    draw.rectangle([4, size//2 - 12, 13, size//2 + 12], fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK)
    draw.line([(6, size//2 - 10), (6, size//2 + 10)], fill=COLOR_BRONZE_GOLD)
    # Right clip
    draw.rectangle([size - 14, size//2 - 12, size - 5, size//2 + 12], fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK)
    draw.line([(size - 7, size//2 - 10), (size - 7, size//2 + 10)], fill=COLOR_BRONZE_GOLD)
    
    path = os.path.join(OUTPUT_DIR, "ornate_frame_9slice.png")
    img.save(path)
    print("Saved:", path)

def generate_ornate_frame_light_9slice():
    """Generates an inner sub-container 9-slice frame with notched corners."""
    size = 96
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    draw.rectangle([4, 4, size - 5, size - 5], fill=COLOR_BG_CONTAINER)
    # Outer dark edge
    draw.rectangle([4, 4, size - 5, size - 5], outline=COLOR_STEEL_DARK, width=1)
    # Inner steel blue border
    draw.rectangle([7, 7, size - 8, size - 8], outline=COLOR_STEEL_MID, width=1)
    
    # Notched corner bronze accents (size 12x12)
    def draw_corner_notch(x, y, fx, fy):
        p1 = (x, y)
        p2 = (x + (12 if not fx else -12), y)
        p3 = (x, y + (12 if not fy else -12))
        draw.polygon([p1, p2, p3], fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK)
        draw.line([p1, (x + (6 if not fx else -6), y)], fill=COLOR_BRONZE_GOLD)
        draw.line([p1, (x, y + (6 if not fy else -6))], fill=COLOR_BRONZE_GOLD)
        
    draw_corner_notch(5, 5, False, False)
    draw_corner_notch(size - 6, 5, True, False)
    draw_corner_notch(5, size - 6, False, True)
    draw_corner_notch(size - 6, size - 6, True, True)
    
    path = os.path.join(OUTPUT_DIR, "ornate_frame_light_9slice.png")
    img.save(path)
    print("Saved:", path)

def generate_ornate_header_plaque():
    """Generates the stepped trapezoidal title plaque with bronze flange brackets."""
    w, h = 256, 44
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Stepped trapezoid polygon
    poly = [
        (24, 6), (w - 25, 6),
        (w - 12, 18), (w - 12, h - 14),
        (w - 25, h - 6), (24, h - 6),
        (11, h - 14), (11, 18)
    ]
    draw.polygon(poly, fill=(8, 12, 18, 250), outline=COLOR_STEEL_DARK)
    
    # Inner sapphire border
    poly_inner = [
        (26, 9), (w - 27, 9),
        (w - 16, 20), (w - 16, h - 16),
        (w - 27, h - 9), (26, h - 9),
        (15, h - 16), (15, 20)
    ]
    draw.polygon(poly_inner, outline=COLOR_STEEL_MID, width=1)
    
    # Left bronze flange tab
    left_flange = [
        (4, 12), (18, 4), (24, 10), (16, 22), (24, 34), (18, 40), (4, 32), (10, 22)
    ]
    draw.polygon(left_flange, fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK)
    draw.line([(6, 14), (17, 6), (22, 11)], fill=COLOR_BRONZE_GOLD, width=1)
    draw.line([(6, 30), (17, 38), (22, 33)], fill=COLOR_BRONZE_GOLD, width=1)
    draw.point((13, 22), fill=COLOR_BRONZE_GOLD)
    
    # Right bronze flange tab (mirror)
    right_flange = [
        (w - 5, 12), (w - 19, 4), (w - 25, 10), (w - 17, 22), (w - 25, 34), (w - 19, 40), (w - 5, 32), (w - 11, 22)
    ]
    draw.polygon(right_flange, fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK)
    draw.line([(w - 7, 14), (w - 18, 6), (w - 23, 11)], fill=COLOR_BRONZE_GOLD, width=1)
    draw.line([(w - 7, 30), (w - 18, 38), (w - 23, 33)], fill=COLOR_BRONZE_GOLD, width=1)
    draw.point((w - 14, 22), fill=COLOR_BRONZE_GOLD)
    
    # Top & bottom central gold clips
    draw.rectangle([w//2 - 16, 3, w//2 + 16, 9], fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK)
    draw.line([(w//2 - 14, 5), (w//2 + 14, 5)], fill=COLOR_BRONZE_GOLD)
    draw.rectangle([w//2 - 16, h - 10, w//2 + 16, h - 4], fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK)
    draw.line([(w//2 - 14, h - 6), (w//2 + 14, h - 6)], fill=COLOR_BRONZE_GOLD)
    
    path = os.path.join(OUTPUT_DIR, "ornate_header_plaque.png")
    img.save(path)
    print("Saved:", path)

def generate_ornate_buttons():
    """Generates Normal, Hover, and Pressed states for framed square/rectangular buttons."""
    size = 48
    states = {
        "normal": {
            "bg": (12, 16, 22, 250),
            "border": COLOR_STEEL_MID,
            "highlight": COLOR_STEEL_LIGHT,
            "bronze": COLOR_BRONZE_MID,
            "gold": COLOR_BRONZE_GOLD,
            "glow": False
        },
        "hover": {
            "bg": (18, 24, 34, 255),
            "border": (70, 120, 180, 255),
            "highlight": (120, 175, 235, 255),
            "bronze": COLOR_BRONZE_LIGHT,
            "gold": (255, 240, 205, 255),
            "glow": True
        },
        "pressed": {
            "bg": (8, 10, 14, 255),
            "border": (35, 55, 80, 255),
            "highlight": (50, 80, 120, 255),
            "bronze": COLOR_BRONZE_DARK,
            "gold": COLOR_BRONZE_MID,
            "glow": False
        }
    }
    
    for state_name, s in states.items():
        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # Outer boundary
        draw.rectangle([2, 2, size - 3, size - 3], fill=s["bg"], outline=COLOR_STEEL_DARK)
        # Steel channel
        draw.rectangle([4, 4, size - 5, size - 5], outline=s["border"], width=1)
        # Top-left bevel highlight
        draw.line([(5, 5), (size - 6, 5)], fill=s["highlight"])
        draw.line([(5, 5), (5, size - 6)], fill=s["highlight"])
        # Inner recessed line
        draw.rectangle([7, 7, size - 8, size - 8], outline=COLOR_STEEL_DARK, width=1)
        
        # 4 Corner bronze pips / flanges (size 6x6)
        corners = [
            (2, 2), (size - 8, 2), (2, size - 8), (size - 8, size - 8)
        ]
        for cx, cy in corners:
            draw.rectangle([cx, cy, cx + 5, cy + 5], fill=s["bronze"], outline=COLOR_BRONZE_DARK)
            draw.point((cx + 1, cy + 1), fill=s["gold"])
            draw.point((cx + 2, cy + 2), fill=s["gold"])
            
        path = os.path.join(OUTPUT_DIR, f"ornate_button_{state_name}.png")
        img.save(path)
        print("Saved:", path)

def generate_segmented_bar_components():
    """Generates the progress bar channel rail with bronze chevron endcaps, and discrete pips."""
    # 1. Bar Rail Frame (256x32)
    w, h = 256, 32
    frame_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    fdraw = ImageDraw.Draw(frame_img)
    
    # Central dark recessed trench
    fdraw.rectangle([28, 4, w - 29, h - 5], fill=(6, 8, 12, 255), outline=COLOR_STEEL_DARK)
    # Double steel rails top and bottom
    fdraw.line([(28, 4), (w - 29, 4)], fill=COLOR_STEEL_MID, width=2)
    fdraw.line([(28, 6), (w - 29, 6)], fill=COLOR_STEEL_LIGHT, width=1)
    fdraw.line([(28, h - 5), (w - 29, h - 5)], fill=COLOR_STEEL_MID, width=2)
    fdraw.line([(28, h - 7), (w - 29, h - 7)], fill=COLOR_STEEL_DARK, width=1)
    
    # Left Bronze Chevron / Arrowhead Endcap
    left_cap = [
        (4, h//2), (26, 2), (28, 8), (14, h//2), (28, h - 9), (26, h - 3)
    ]
    fdraw.polygon(left_cap, fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK)
    fdraw.line([(5, h//2), (25, 4)], fill=COLOR_BRONZE_GOLD, width=1)
    fdraw.line([(5, h//2), (25, h - 5)], fill=COLOR_BRONZE_LIGHT, width=1)
    fdraw.polygon([(10, h//2 - 4), (18, h//2), (10, h//2 + 4)], fill=COLOR_BRONZE_GOLD, outline=COLOR_BRONZE_DARK)
    
    # Right Bronze Chevron / Arrowhead Endcap (mirror)
    right_cap = [
        (w - 5, h//2), (w - 27, 2), (w - 29, 8), (w - 15, h//2), (w - 29, h - 9), (w - 27, h - 3)
    ]
    fdraw.polygon(right_cap, fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK)
    fdraw.line([(w - 6, h//2), (w - 26, 4)], fill=COLOR_BRONZE_GOLD, width=1)
    fdraw.line([(w - 6, h//2), (w - 26, h - 5)], fill=COLOR_BRONZE_LIGHT, width=1)
    fdraw.polygon([(w - 11, h//2 - 4), (w - 19, h//2), (w - 11, h//2 + 4)], fill=COLOR_BRONZE_GOLD, outline=COLOR_BRONZE_DARK)
    
    frame_path = os.path.join(OUTPUT_DIR, "ornate_bar_frame_9slice.png")
    frame_img.save(frame_path)
    print("Saved:", frame_path)
    
    # 2. Discrete Pips (width: 10, height: 18)
    pw, ph = 10, 18
    pip_variants = {
        "amber": {
            "fill": (235, 140, 25, 255),
            "core": (255, 200, 70, 255),
            "edge": (160, 80, 10, 255),
            "glow": (255, 170, 40, 180)
        },
        "red": {
            "fill": (220, 45, 40, 255),
            "core": (255, 95, 90, 255),
            "edge": (140, 20, 20, 255),
            "glow": (255, 60, 50, 180)
        },
        "green": {
            "fill": (45, 180, 75, 255),
            "core": (100, 235, 130, 255),
            "edge": (20, 110, 40, 255),
            "glow": (60, 220, 90, 180)
        },
        "blue": {
            "fill": (30, 130, 225, 255),
            "core": (85, 185, 255, 255),
            "edge": (15, 75, 150, 255),
            "glow": (45, 150, 255, 180)
        },
        "empty": {
            "fill": (18, 24, 32, 255),
            "core": (12, 16, 22, 255),
            "edge": (28, 38, 50, 255),
            "glow": None
        }
    }
    
    for vname, vdata in pip_variants.items():
        pimg = Image.new("RGBA", (pw, ph), (0, 0, 0, 0))
        pdraw = ImageDraw.Draw(pimg)
        
        # Outer pip rectangle with beveled outline
        pdraw.rectangle([1, 1, pw - 2, ph - 2], fill=vdata["fill"], outline=vdata["edge"])
        # Inner vertical highlight bar
        pdraw.rectangle([3, 2, pw - 4, ph - 3], fill=vdata["core"])
        # Top specular highlight
        pdraw.line([(2, 2), (pw - 3, 2)], fill=(255, 255, 255, 160 if vdata["glow"] else 40))
        
        ppath = os.path.join(OUTPUT_DIR, f"pip_{vname}.png")
        pimg.save(ppath)
        print("Saved:", ppath)

def generate_ornate_corner_accent():
    """Generates an individual 64x64 ornate corner flourish for standalone decorating."""
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    corner = draw_chiseled_corner(draw, 0, 0, size - 4, size - 4, False, False)
    img.paste(corner, (2, 2), corner)
    path = os.path.join(OUTPUT_DIR, "ornate_corner_accent.png")
    img.save(path)
    print("Saved:", path)

if __name__ == "__main__":
    generate_ornate_frame_9slice()
    generate_ornate_frame_light_9slice()
    generate_ornate_header_plaque()
    generate_ornate_buttons()
    generate_segmented_bar_components()
    generate_ornate_corner_accent()
    print("ALL ORNATE UI TEXTURES GENERATED SUCCESSFULLY.")
