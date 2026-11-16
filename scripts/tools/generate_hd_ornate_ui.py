# hollow_core/scripts/tools/generate_hd_ornate_ui.py
"""
High-Resolution (High-DPI / 4K-Ready) Victorian Gothic Steampunk UI Generator.
Inspired by Frostpunk, Sunless Skies, and Darkest Dungeon UI art.
Uses 4x supersampling with Lanczos filtering for pristine, razor-sharp anti-aliased assets:
- ornate_frame_hd.png (512x512)
- ornate_frame_light_hd.png (256x256)
- ornate_header_plaque_hd.png (512x80)
- ornate_button_hd_normal.png, hover.png, pressed.png (128x128)
- ornate_bar_frame_hd.png (512x56)
- pip_hd_amber.png, red.png, green.png, blue.png, empty.png (24x40)
"""

import os
import sys
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

OUTPUT_DIR = "hollow_core/textures/ui"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Master Palette (Restrained Victorian Gothic Steampunk)
COLOR_BG_DARK = (10, 14, 20, 240)          # Obsidian slate
COLOR_BG_LIGHT = (14, 19, 27, 245)         # Inner container
COLOR_STEEL_SHADOW = (18, 25, 35, 255)     # Deep border boundary
COLOR_STEEL_DEEP = (38, 56, 78, 255)       # Sapphire steel channel
COLOR_STEEL_MID = (58, 86, 118, 255)       # Steel blue highlight
COLOR_STEEL_BRIGHT = (110, 155, 200, 255)  # Specular steel bevel
COLOR_BRONZE_DARK = (52, 36, 22, 255)      # Deep shadow bronze
COLOR_BRONZE_MID = (130, 96, 56, 255)      # Antique weathered bronze
COLOR_BRONZE_LIGHT = (195, 155, 98, 255)   # Polished brass
COLOR_BRONZE_GOLD = (242, 218, 168, 255)   # Specular gold chisel line
COLOR_RIVET_GOLD = (255, 240, 200, 255)    # Brass rivet glint

SCALE = 4 # 4x supersampling factor

def draw_hd_corner(draw, w, h, flip_x=False, flip_y=False):
    """Draws a master Victorian chiseled bronze corner with multi-step filigree at 4x resolution."""
    c_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(c_img)

    # 1. Outer stepped L-flange with 45-deg corner chamfer
    chamfer = int(14 * SCALE)
    thick = int(12 * SCALE)
    poly_outer = [
        (0, 0), (w, 0), (w, thick),
        (thick + chamfer, thick),
        (thick, thick + chamfer),
        (thick, h), (0, h)
    ]
    cd.polygon(poly_outer, fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK)

    # 2. Beveled Gold Highlight Lines
    cd.line([(2, 2), (w - 2, 2)], fill=COLOR_BRONZE_GOLD, width=int(2 * SCALE))
    cd.line([(2, 2), (2, h - 2)], fill=COLOR_BRONZE_GOLD, width=int(2 * SCALE))
    cd.line([(w - 2, 2), (w - 2, thick - 2)], fill=COLOR_BRONZE_LIGHT, width=int(1.5 * SCALE))
    cd.line([(2, h - 2), (thick - 2, h - 2)], fill=COLOR_BRONZE_LIGHT, width=int(1.5 * SCALE))

    # Diagonal chamfer highlight
    cd.line([(thick + chamfer, thick), (thick, thick + chamfer)], fill=COLOR_BRONZE_GOLD, width=int(2 * SCALE))

    # 3. Corner Triangular Accent Piece
    tri_size = int(18 * SCALE)
    cd.polygon([(0, 0), (tri_size, 0), (0, tri_size)], fill=COLOR_BRONZE_LIGHT, outline=COLOR_BRONZE_DARK)
    cd.polygon([(0, 0), (tri_size // 2, 0), (0, tri_size // 2)], fill=COLOR_BRONZE_GOLD)

    # 4. Center Diamond Stud / Rivet
    cx = int(18 * SCALE)
    cy = int(18 * SCALE)
    dr = int(7 * SCALE)
    diamond = [(cx, cy - dr), (cx + dr, cy), (cx, cy + dr), (cx - dr, cy)]
    cd.polygon(diamond, fill=COLOR_BRONZE_GOLD, outline=COLOR_BRONZE_DARK)
    cd.polygon([(cx, cy - dr//2), (cx + dr//2, cy), (cx, cy + dr//2), (cx - dr//2, cy)], fill=COLOR_RIVET_GOLD)

    # 5. Stepped End Notches along arms
    notch_w = int(12 * SCALE)
    notch_h = int(6 * SCALE)
    cd.rectangle([w - notch_w - int(4*SCALE), int(2*SCALE), w - int(4*SCALE), int(2*SCALE) + notch_h],
                 fill=COLOR_BRONZE_GOLD, outline=COLOR_BRONZE_DARK)
    cd.rectangle([int(2*SCALE), h - notch_w - int(4*SCALE), int(2*SCALE) + notch_h, h - int(4*SCALE)],
                 fill=COLOR_BRONZE_GOLD, outline=COLOR_BRONZE_DARK)

    # 6. Diagonal filigree strut
    cd.line([(cx + int(4*SCALE), cy + int(4*SCALE)), (w - int(8*SCALE), h - int(8*SCALE))],
            fill=COLOR_BRONZE_GOLD, width=int(2 * SCALE))

    if flip_x:
        c_img = c_img.transpose(Image.FLIP_LEFT_RIGHT)
    if flip_y:
        c_img = c_img.transpose(Image.FLIP_TOP_BOTTOM)

    return c_img

def generate_ornate_frame_hd():
    """Generates the primary 512x512 High-DPI 9-slice frame with supersampled anti-aliasing."""
    out_size = 512
    s = out_size * SCALE # 2048x2048 supersampled canvas
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    margin = int(18 * SCALE)
    # 1. Dark obsidian slate body
    draw.rectangle([margin, margin, s - margin, s - margin], fill=COLOR_BG_DARK)

    # 2. Multi-tier beveled steel rails
    # Outer dark shadow boundary
    draw.rectangle([margin, margin, s - margin, s - margin], outline=COLOR_STEEL_SHADOW, width=int(3 * SCALE))
    # Deep sapphire channel
    draw.rectangle([margin + int(6*SCALE), margin + int(6*SCALE), s - margin - int(6*SCALE), s - margin - int(6*SCALE)],
                   outline=COLOR_STEEL_DEEP, width=int(4 * SCALE))
    # Specular light edge
    draw.rectangle([margin + int(10*SCALE), margin + int(10*SCALE), s - margin - int(10*SCALE), s - margin - int(10*SCALE)],
                   outline=COLOR_STEEL_BRIGHT, width=int(2 * SCALE))
    # Inner border line
    draw.rectangle([margin + int(14*SCALE), margin + int(14*SCALE), s - margin - int(14*SCALE), s - margin - int(14*SCALE)],
                   outline=COLOR_STEEL_SHADOW, width=int(2 * SCALE))

    # 3. Sculpted Bronze Corners (size: 96x96 at output -> 384x384 at 4x)
    cw, ch = int(90 * SCALE), int(90 * SCALE)
    tl = draw_hd_corner(draw, cw, ch, False, False)
    tr = draw_hd_corner(draw, cw, ch, True, False)
    bl = draw_hd_corner(draw, cw, ch, False, True)
    br = draw_hd_corner(draw, cw, ch, True, True)

    pos_off = int(6 * SCALE)
    img.paste(tl, (pos_off, pos_off), tl)
    img.paste(tr, (s - cw - pos_off, pos_off), tr)
    img.paste(bl, (pos_off, s - ch - pos_off), bl)
    img.paste(br, (s - cw - pos_off, s - ch - pos_off), br)

    # 4. Center edge decorative brass clips (Top, Bottom, Left, Right)
    clip_w = int(48 * SCALE)
    clip_h = int(14 * SCALE)
    # Top
    draw.rectangle([s//2 - clip_w//2, int(8*SCALE), s//2 + clip_w//2, int(8*SCALE) + clip_h],
                   fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK, width=int(2*SCALE))
    draw.line([(s//2 - clip_w//2 + int(4*SCALE), int(12*SCALE)), (s//2 + clip_w//2 - int(4*SCALE), int(12*SCALE))],
              fill=COLOR_BRONZE_GOLD, width=int(2*SCALE))
    # Bottom
    draw.rectangle([s//2 - clip_w//2, s - int(8*SCALE) - clip_h, s//2 + clip_w//2, s - int(8*SCALE)],
                   fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK, width=int(2*SCALE))
    draw.line([(s//2 - clip_w//2 + int(4*SCALE), s - int(12*SCALE)), (s//2 + clip_w//2 - int(4*SCALE), s - int(12*SCALE))],
              fill=COLOR_BRONZE_GOLD, width=int(2*SCALE))

    # Downsample with Lanczos filter for pristine anti-aliasing
    final_img = img.resize((out_size, out_size), Image.LANCZOS)
    path = os.path.join(OUTPUT_DIR, "ornate_frame_hd.png")
    final_img.save(path)
    print("Saved HD:", path)

def generate_ornate_frame_light_hd():
    """Generates the 256x256 High-DPI sub-container frame with notched corners."""
    out_size = 256
    s = out_size * SCALE
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    margin = int(10 * SCALE)
    draw.rectangle([margin, margin, s - margin, s - margin], fill=COLOR_BG_LIGHT)
    draw.rectangle([margin, margin, s - margin, s - margin], outline=COLOR_STEEL_SHADOW, width=int(2 * SCALE))
    draw.rectangle([margin + int(4*SCALE), margin + int(4*SCALE), s - margin - int(4*SCALE), s - margin - int(4*SCALE)],
                   outline=COLOR_STEEL_DEEP, width=int(3 * SCALE))

    # Notched corner brass bevels
    notch_s = int(24 * SCALE)
    def draw_notch(x, y, fx, fy):
        p1 = (x, y)
        p2 = (x + (-notch_s if fx else notch_s), y)
        p3 = (x, y + (-notch_s if fy else notch_s))
        draw.polygon([p1, p2, p3], fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK)
        draw.line([p1, p2], fill=COLOR_BRONZE_GOLD, width=int(2*SCALE))
        draw.line([p1, p3], fill=COLOR_BRONZE_GOLD, width=int(2*SCALE))

    draw_notch(margin + int(3*SCALE), margin + int(3*SCALE), False, False)
    draw_notch(s - margin - int(3*SCALE), margin + int(3*SCALE), True, False)
    draw_notch(margin + int(3*SCALE), s - margin - int(3*SCALE), False, True)
    draw_notch(s - margin - int(3*SCALE), s - margin - int(3*SCALE), True, True)

    final_img = img.resize((out_size, out_size), Image.LANCZOS)
    path = os.path.join(OUTPUT_DIR, "ornate_frame_light_hd.png")
    final_img.save(path)
    print("Saved HD:", path)

def generate_ornate_header_plaque_hd():
    """Generates the 512x80 High-DPI title plaque with sculpted Victorian flange endcaps."""
    ow, oh = 512, 80
    w, h = ow * SCALE, oh * SCALE
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    flange_w = int(54 * SCALE)
    chamfer = int(20 * SCALE)

    # Main trapezoidal slate plaque
    poly = [
        (flange_w, int(10*SCALE)),
        (w - flange_w, int(10*SCALE)),
        (w - flange_w + chamfer, int(26*SCALE)),
        (w - flange_w + chamfer, h - int(26*SCALE)),
        (w - flange_w, h - int(10*SCALE)),
        (flange_w, h - int(10*SCALE)),
        (flange_w - chamfer, h - int(26*SCALE)),
        (flange_w - chamfer, int(26*SCALE))
    ]
    draw.polygon(poly, fill=(8, 12, 18, 250), outline=COLOR_STEEL_SHADOW)
    draw.polygon(poly, outline=COLOR_STEEL_DEEP, width=int(3 * SCALE))

    # Inner specular line
    inner_poly = [
        (flange_w + int(8*SCALE), int(16*SCALE)),
        (w - flange_w - int(8*SCALE), int(16*SCALE)),
        (w - flange_w + chamfer - int(6*SCALE), int(28*SCALE)),
        (w - flange_w + chamfer - int(6*SCALE), h - int(28*SCALE)),
        (w - flange_w - int(8*SCALE), h - int(16*SCALE)),
        (flange_w + int(8*SCALE), h - int(16*SCALE)),
        (flange_w - chamfer + int(6*SCALE), h - int(28*SCALE)),
        (flange_w - chamfer + int(6*SCALE), int(28*SCALE))
    ]
    draw.polygon(inner_poly, outline=COLOR_STEEL_BRIGHT, width=int(2 * SCALE))

    # Left sculpted bronze flange bracket
    l_flange = [
        (int(10*SCALE), h//2),
        (flange_w - int(12*SCALE), int(10*SCALE)),
        (flange_w + int(6*SCALE), int(22*SCALE)),
        (flange_w - int(8*SCALE), h//2),
        (flange_w + int(6*SCALE), h - int(22*SCALE)),
        (flange_w - int(12*SCALE), h - int(10*SCALE))
    ]
    draw.polygon(l_flange, fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK)
    draw.line([(int(12*SCALE), h//2), (flange_w - int(14*SCALE), int(12*SCALE))], fill=COLOR_BRONZE_GOLD, width=int(2.5*SCALE))
    draw.line([(int(12*SCALE), h//2), (flange_w - int(14*SCALE), h - int(12*SCALE))], fill=COLOR_BRONZE_LIGHT, width=int(2.5*SCALE))
    # Diamond stud
    cdx = int(32 * SCALE)
    draw.polygon([(cdx, h//2 - int(8*SCALE)), (cdx + int(8*SCALE), h//2),
                  (cdx, h//2 + int(8*SCALE)), (cdx - int(8*SCALE), h//2)],
                 fill=COLOR_BRONZE_GOLD, outline=COLOR_BRONZE_DARK)

    # Right sculpted bronze flange bracket (mirror)
    r_flange = [
        (w - int(10*SCALE), h//2),
        (w - flange_w + int(12*SCALE), int(10*SCALE)),
        (w - flange_w - int(6*SCALE), int(22*SCALE)),
        (w - flange_w + int(8*SCALE), h//2),
        (w - flange_w - int(6*SCALE), h - int(22*SCALE)),
        (w - flange_w + int(12*SCALE), h - int(10*SCALE))
    ]
    draw.polygon(r_flange, fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK)
    draw.line([(w - int(12*SCALE), h//2), (w - flange_w + int(14*SCALE), int(12*SCALE))], fill=COLOR_BRONZE_GOLD, width=int(2.5*SCALE))
    draw.line([(w - int(12*SCALE), h//2), (w - flange_w + int(14*SCALE), h - int(12*SCALE))], fill=COLOR_BRONZE_LIGHT, width=int(2.5*SCALE))
    rcdx = w - int(32 * SCALE)
    draw.polygon([(rcdx, h//2 - int(8*SCALE)), (rcdx + int(8*SCALE), h//2),
                  (rcdx, h//2 + int(8*SCALE)), (rcdx - int(8*SCALE), h//2)],
                 fill=COLOR_BRONZE_GOLD, outline=COLOR_BRONZE_DARK)

    final_img = img.resize((ow, oh), Image.LANCZOS)
    path = os.path.join(OUTPUT_DIR, "ornate_header_plaque_hd.png")
    final_img.save(path)
    print("Saved HD:", path)

def generate_ornate_buttons_hd():
    """Generates 128x128 High-DPI framed buttons (normal, hover, pressed)."""
    ow = 128
    s = ow * SCALE
    states = {
        "normal": {
            "bg": (12, 16, 24, 250),
            "border": COLOR_STEEL_DEEP,
            "highlight": COLOR_STEEL_MID,
            "bronze": COLOR_BRONZE_MID,
            "gold": COLOR_BRONZE_GOLD
        },
        "hover": {
            "bg": (20, 30, 44, 255),
            "border": (65, 115, 175, 255),
            "highlight": COLOR_STEEL_BRIGHT,
            "bronze": COLOR_BRONZE_LIGHT,
            "gold": (255, 245, 215, 255)
        },
        "pressed": {
            "bg": (8, 10, 14, 255),
            "border": (30, 45, 65, 255),
            "highlight": COLOR_STEEL_DEEP,
            "bronze": COLOR_BRONZE_DARK,
            "gold": COLOR_BRONZE_MID
        }
    }

    for state_name, st in states.items():
        img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        m = int(6 * SCALE)
        draw.rectangle([m, m, s - m, s - m], fill=st["bg"], outline=COLOR_STEEL_SHADOW, width=int(2*SCALE))
        draw.rectangle([m + int(4*SCALE), m + int(4*SCALE), s - m - int(4*SCALE), s - m - int(4*SCALE)],
                       outline=st["border"], width=int(3*SCALE))
        # Top-left bevel specular highlight
        draw.line([(m + int(5*SCALE), m + int(5*SCALE)), (s - m - int(5*SCALE), m + int(5*SCALE))],
                  fill=st["highlight"], width=int(2*SCALE))
        draw.line([(m + int(5*SCALE), m + int(5*SCALE)), (m + int(5*SCALE), s - m - int(5*SCALE))],
                  fill=st["highlight"], width=int(2*SCALE))

        # 4 Corner bronze flanges with brass rivets
        c_size = int(18 * SCALE)
        corners = [
            (m, m), (s - m - c_size, m), (m, s - m - c_size), (s - m - c_size, s - m - c_size)
        ]
        for cx, cy in corners:
            draw.rectangle([cx, cy, cx + c_size, cy + c_size], fill=st["bronze"], outline=COLOR_BRONZE_DARK)
            # Center rivet
            rx, ry = cx + c_size//2, cy + c_size//2
            draw.ellipse([rx - int(3*SCALE), ry - int(3*SCALE), rx + int(3*SCALE), ry + int(3*SCALE)],
                         fill=st["gold"], outline=COLOR_BRONZE_DARK)

        final_img = img.resize((ow, ow), Image.LANCZOS)
        path = os.path.join(OUTPUT_DIR, f"ornate_button_hd_{state_name}.png")
        final_img.save(path)
        print("Saved HD:", path)

def generate_segmented_bar_hd():
    """Generates 512x56 High-DPI progress bar rail with bronze chevron endcaps and discrete pips."""
    ow, oh = 512, 56
    w, h = ow * SCALE, oh * SCALE
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cap_w = int(58 * SCALE)
    # Central recessed channel
    draw.rectangle([cap_w, int(6*SCALE), w - cap_w, h - int(6*SCALE)], fill=(6, 9, 14, 255), outline=COLOR_STEEL_SHADOW)
    # Double steel rails top and bottom
    draw.line([(cap_w, int(6*SCALE)), (w - cap_w, int(6*SCALE))], fill=COLOR_STEEL_DEEP, width=int(3*SCALE))
    draw.line([(cap_w, int(9*SCALE)), (w - cap_w, int(9*SCALE))], fill=COLOR_STEEL_BRIGHT, width=int(1.5*SCALE))
    draw.line([(cap_w, h - int(7*SCALE)), (w - cap_w, h - int(7*SCALE))], fill=COLOR_STEEL_DEEP, width=int(3*SCALE))
    draw.line([(cap_w, h - int(10*SCALE)), (w - cap_w, h - int(10*SCALE))], fill=COLOR_STEEL_SHADOW, width=int(1.5*SCALE))

    # Left Sculpted Bronze Chevron Endcap
    left_cap = [
        (int(10*SCALE), h//2),
        (cap_w - int(6*SCALE), int(4*SCALE)),
        (cap_w, int(14*SCALE)),
        (int(28*SCALE), h//2),
        (cap_w, h - int(14*SCALE)),
        (cap_w - int(6*SCALE), h - int(4*SCALE))
    ]
    draw.polygon(left_cap, fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK)
    draw.line([(int(12*SCALE), h//2), (cap_w - int(8*SCALE), int(6*SCALE))], fill=COLOR_BRONZE_GOLD, width=int(2.5*SCALE))
    draw.line([(int(12*SCALE), h//2), (cap_w - int(8*SCALE), h - int(6*SCALE))], fill=COLOR_BRONZE_LIGHT, width=int(2.5*SCALE))
    # Diamond accent inside cap
    dcx = int(24 * SCALE)
    draw.polygon([(dcx, h//2 - int(8*SCALE)), (dcx + int(8*SCALE), h//2),
                  (dcx, h//2 + int(8*SCALE)), (dcx - int(8*SCALE), h//2)],
                 fill=COLOR_BRONZE_GOLD, outline=COLOR_BRONZE_DARK)

    # Right Sculpted Bronze Chevron Endcap (mirror)
    right_cap = [
        (w - int(10*SCALE), h//2),
        (w - cap_w + int(6*SCALE), int(4*SCALE)),
        (w - cap_w, int(14*SCALE)),
        (w - int(28*SCALE), h//2),
        (w - cap_w, h - int(14*SCALE)),
        (w - cap_w + int(6*SCALE), h - int(4*SCALE))
    ]
    draw.polygon(right_cap, fill=COLOR_BRONZE_MID, outline=COLOR_BRONZE_DARK)
    draw.line([(w - int(12*SCALE), h//2), (w - cap_w + int(8*SCALE), int(6*SCALE))], fill=COLOR_BRONZE_GOLD, width=int(2.5*SCALE))
    draw.line([(w - int(12*SCALE), h//2), (w - cap_w + int(8*SCALE), h - int(6*SCALE))], fill=COLOR_BRONZE_LIGHT, width=int(2.5*SCALE))
    rdcx = w - int(24 * SCALE)
    draw.polygon([(rdcx, h//2 - int(8*SCALE)), (rdcx + int(8*SCALE), h//2),
                  (rdcx, h//2 + int(8*SCALE)), (rdcx - int(8*SCALE), h//2)],
                 fill=COLOR_BRONZE_GOLD, outline=COLOR_BRONZE_DARK)

    final_img = img.resize((ow, oh), Image.LANCZOS)
    path = os.path.join(OUTPUT_DIR, "ornate_bar_frame_hd.png")
    final_img.save(path)
    print("Saved HD:", path)

    # Pips: High-DPI (20x34)
    pw, ph = 20, 34
    spw, sph = pw * SCALE, ph * SCALE
    variants = {
        "amber": ((245, 155, 30, 255), (255, 215, 85, 255), (170, 95, 15, 255)),
        "red": ((230, 50, 45, 255), (255, 110, 100, 255), (150, 25, 25, 255)),
        "green": ((45, 195, 80, 255), (110, 245, 140, 255), (20, 120, 45, 255)),
        "blue": ((35, 140, 235, 255), (95, 195, 255, 255), (18, 85, 160, 255)),
        "empty": ((20, 26, 36, 255), (14, 18, 25, 255), (32, 42, 56, 255))
    }

    for vname, (fill_c, core_c, edge_c) in variants.items():
        pimg = Image.new("RGBA", (spw, sph), (0, 0, 0, 0))
        pdraw = ImageDraw.Draw(pimg)

        pdraw.rectangle([int(2*SCALE), int(2*SCALE), spw - int(2*SCALE), sph - int(2*SCALE)],
                        fill=fill_c, outline=edge_c, width=int(2*SCALE))
        pdraw.rectangle([int(5*SCALE), int(4*SCALE), spw - int(5*SCALE), sph - int(4*SCALE)],
                        fill=core_c)
        # Specular light highlight on top
        pdraw.line([(int(3*SCALE), int(3*SCALE)), (spw - int(3*SCALE), int(3*SCALE))],
                   fill=(255, 255, 255, 200 if vname != "empty" else 40), width=int(1.5*SCALE))

        p_final = pimg.resize((pw, ph), Image.LANCZOS)
        ppath = os.path.join(OUTPUT_DIR, f"pip_hd_{vname}.png")
        p_final.save(ppath)
        print("Saved HD:", ppath)

if __name__ == "__main__":
    generate_ornate_frame_hd()
    generate_ornate_frame_light_hd()
    generate_ornate_header_plaque_hd()
    generate_ornate_buttons_hd()
    generate_segmented_bar_hd()
    print("ALL HIGH-RESOLUTION ORNATE UI ASSETS GENERATED SUCCESSFULLY.")
