# hollow_core/scripts/tools/generate_sleek_minimal_ui.py
"""
High-End Minimalist Victorian / Industrial Expedition UI Asset Generator.
Inspired by Dishonored 2, Frostpunk, and Amnesia: The Bunker.
Eliminates heavy boxy panels; creates sleek, slender, floating diegetic HUD elements
with 4x supersampling and Lanczos anti-aliasing.
"""

import os
from PIL import Image, ImageDraw, ImageFilter

OUTPUT_DIR = "hollow_core/textures/ui_sleek"
os.makedirs(OUTPUT_DIR, exist_ok=True)

SCALE = 4  # 4x supersampling

# Refined Grounded Color Palette
COLOR_OBSIDIAN = (8, 11, 16, 235)
COLOR_GRAPHITE = (16, 22, 30, 245)
COLOR_STEEL_DARK = (28, 38, 52, 255)
COLOR_STEEL_HAIRLINE = (70, 95, 125, 220)
COLOR_STEEL_SPECULAR = (140, 180, 220, 255)
COLOR_BRASS_DARK = (60, 44, 26, 255)
COLOR_BRASS_ANTIQUE = (150, 115, 68, 255)
COLOR_BRASS_POLISHED = (215, 175, 110, 255)
COLOR_GOLD_SPECULAR = (255, 235, 190, 255)
COLOR_AMBER_GLOW = (245, 155, 35, 255)
COLOR_AMBER_BRIGHT = (255, 215, 95, 255)

def generate_expedition_divider():
    """Generates a slender 360x8 etched brass hairline divider with center diamond."""
    ow, oh = 360, 8
    w, h = ow * SCALE, oh * SCALE
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cy = h // 2
    # Tapered brass hairline
    for x in range(w):
        # Fade at extreme ends
        dist_from_center = abs(x - w // 2) / (w // 2)
        alpha = int(255 * (1.0 - (dist_from_center ** 1.8)))
        if alpha < 0: alpha = 0
        
        # Hairline
        col = (COLOR_BRASS_ANTIQUE[0], COLOR_BRASS_ANTIQUE[1], COLOR_BRASS_ANTIQUE[2], alpha)
        draw.line([(x, cy), (x, cy + SCALE - 1)], fill=col)
        # Specular glint along upper edge
        spec_alpha = int(alpha * 0.7)
        spec_col = (COLOR_GOLD_SPECULAR[0], COLOR_GOLD_SPECULAR[1], COLOR_GOLD_SPECULAR[2], spec_alpha)
        draw.point((x, cy - 1), fill=spec_col)

    # Center Diamond Emblem
    cx = w // 2
    dr = int(4 * SCALE)
    diamond = [(cx, cy - dr), (cx + dr, cy), (cx, cy + dr), (cx - dr, cy)]
    draw.polygon(diamond, fill=COLOR_BRASS_POLISHED, outline=COLOR_BRASS_DARK)
    inner_diamond = [(cx, cy - dr//2), (cx + dr//2, cy), (cx, cy + dr//2), (cx - dr//2, cy)]
    draw.polygon(inner_diamond, fill=COLOR_GOLD_SPECULAR)

    # Micro side studs
    for s_off in [-int(18 * SCALE), int(18 * SCALE)]:
        draw.ellipse([cx + s_off - int(1.5*SCALE), cy - int(1.5*SCALE),
                      cx + s_off + int(1.5*SCALE), cy + int(1.5*SCALE)],
                     fill=COLOR_BRASS_POLISHED)

    final = img.resize((ow, oh), Image.LANCZOS)
    path = os.path.join(OUTPUT_DIR, "expedition_hud_divider.png")
    final.save(path)
    print("Saved:", path)

def generate_sleek_gauge_casing():
    """Generates a slender 280x14 gunmetal gauge rail with polished brass bezel."""
    ow, oh = 280, 14
    w, h = ow * SCALE, oh * SCALE
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Recessed dark graphite channel
    m = int(2 * SCALE)
    draw.rectangle([m, m, w - m, h - m], fill=(10, 14, 20, 245), outline=COLOR_STEEL_DARK, width=int(1.5 * SCALE))

    # 2. Outer hairline brass bezel
    draw.rectangle([m, m, w - m, h - m], outline=COLOR_BRASS_ANTIQUE, width=int(1 * SCALE))
    
    # 3. Top specular highlight
    draw.line([(m + int(2*SCALE), m + 1), (w - m - int(2*SCALE), m + 1)], fill=COLOR_BRASS_POLISHED, width=int(1*SCALE))
    
    # 4. Endcap notched accents
    cw = int(6 * SCALE)
    # Left cap
    draw.polygon([(m, m), (m + cw, m), (m, m + h - int(4*SCALE))], fill=COLOR_BRASS_POLISHED)
    # Right cap
    draw.polygon([(w - m, m), (w - m - cw, m), (w - m, m + h - int(4*SCALE))], fill=COLOR_BRASS_POLISHED)

    final = img.resize((ow, oh), Image.LANCZOS)
    path = os.path.join(OUTPUT_DIR, "sleek_gauge_casing.png")
    final.save(path)
    print("Saved:", path)

def generate_sleek_interaction_plate():
    """Generates a slender 480x36 translucent obsidian capsule with razor-thin brass hairline."""
    ow, oh = 480, 36
    w, h = ow * SCALE, oh * SCALE
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    chamfer = int(6 * SCALE)
    poly = [
        (chamfer, 0), (w - chamfer, 0),
        (w, chamfer), (w, h - chamfer),
        (w - chamfer, h), (chamfer, h),
        (0, h - chamfer), (0, chamfer)
    ]
    # Smoked obsidian glass
    draw.polygon(poly, fill=(10, 14, 20, 230))
    # Outer dark shadow line
    draw.polygon(poly, outline=COLOR_STEEL_DARK, width=int(2 * SCALE))
    # Inner antique brass hairline
    inner_poly = [
        (chamfer + int(2*SCALE), int(2*SCALE)),
        (w - chamfer - int(2*SCALE), int(2*SCALE)),
        (w - int(2*SCALE), chamfer + int(2*SCALE)),
        (w - int(2*SCALE), h - chamfer - int(2*SCALE)),
        (w - chamfer - int(2*SCALE), h - int(2*SCALE)),
        (chamfer + int(2*SCALE), h - int(2*SCALE)),
        (int(2*SCALE), h - chamfer - int(2*SCALE)),
        (int(2*SCALE), chamfer + int(2*SCALE))
    ]
    draw.polygon(inner_poly, outline=COLOR_BRASS_ANTIQUE, width=int(1.2 * SCALE))

    # Corner gold glints
    corner_glint_len = int(12 * SCALE)
    # Top-left
    draw.line([(chamfer, int(2*SCALE)), (chamfer + corner_glint_len, int(2*SCALE))], fill=COLOR_GOLD_SPECULAR, width=int(1.5*SCALE))
    draw.line([(int(2*SCALE), chamfer), (int(2*SCALE), chamfer + corner_glint_len)], fill=COLOR_GOLD_SPECULAR, width=int(1.5*SCALE))
    # Top-right
    draw.line([(w - chamfer - corner_glint_len, int(2*SCALE)), (w - chamfer, int(2*SCALE))], fill=COLOR_GOLD_SPECULAR, width=int(1.5*SCALE))
    draw.line([(w - int(2*SCALE), chamfer), (w - int(2*SCALE), chamfer + corner_glint_len)], fill=COLOR_GOLD_SPECULAR, width=int(1.5*SCALE))

    final = img.resize((ow, oh), Image.LANCZOS)
    path = os.path.join(OUTPUT_DIR, "sleek_interaction_plate.png")
    final.save(path)
    print("Saved:", path)

def generate_sleek_reticle():
    """Generates a refined 32x32 reticle with precision center dot and 4 subtle vernier ticks."""
    ow = 32
    w = ow * SCALE
    img = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    c = w // 2
    # Precision center dot (diameter 2px -> 8px at 4x)
    r = int(1.2 * SCALE)
    draw.ellipse([c - r, c - r, c + r, c + r], fill=COLOR_GOLD_SPECULAR)

    # 4 Subtle sapphire-steel vernier ticks
    tick_len = int(4 * SCALE)
    tick_gap = int(5 * SCALE)
    # Top
    draw.line([(c, c - tick_gap - tick_len), (c, c - tick_gap)], fill=COLOR_STEEL_SPECULAR, width=int(1.2*SCALE))
    # Bottom
    draw.line([(c, c + tick_gap), (c, c + tick_gap + tick_len)], fill=COLOR_STEEL_SPECULAR, width=int(1.2*SCALE))
    # Left
    draw.line([(c - tick_gap - tick_len, c), (c - tick_gap, c)], fill=COLOR_STEEL_SPECULAR, width=int(1.2*SCALE))
    # Right
    draw.line([(c + tick_gap, c), (c + tick_gap + tick_len, c)], fill=COLOR_STEEL_SPECULAR, width=int(1.2*SCALE))

    final = img.resize((ow, ow), Image.LANCZOS)
    path = os.path.join(OUTPUT_DIR, "sleek_reticle.png")
    final.save(path)
    print("Saved:", path)

def generate_sleek_reticle_interact():
    """Generates a 32x32 reticle state when looking at interactables (adds subtle brass focusing ring)."""
    ow = 32
    w = ow * SCALE
    img = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    c = w // 2
    # Focusing ring (radius 8px -> 32px at 4x)
    ring_r = int(7 * SCALE)
    draw.ellipse([c - ring_r, c - ring_r, c + ring_r, c + ring_r], outline=COLOR_BRASS_POLISHED, width=int(1.5*SCALE))

    # Center bright gold pip
    r = int(1.5 * SCALE)
    draw.ellipse([c - r, c - r, c + r, c + r], fill=COLOR_GOLD_SPECULAR)

    final = img.resize((ow, ow), Image.LANCZOS)
    path = os.path.join(OUTPUT_DIR, "sleek_reticle_interact.png")
    final.save(path)
    print("Saved:", path)

def generate_sleek_badge():
    """Generates a 128x28 dark graphite pill badge with brass hairline for hotkey tags."""
    ow, oh = 128, 28
    w, h = ow * SCALE, oh * SCALE
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    r = int(3 * SCALE)
    draw.rounded_rectangle([0, 0, w - 1, h - 1], radius=r, fill=(12, 16, 22, 235), outline=COLOR_BRASS_DARK, width=int(1.5*SCALE))
    draw.rounded_rectangle([int(2*SCALE), int(2*SCALE), w - 1 - int(2*SCALE), h - 1 - int(2*SCALE)],
                           radius=r - 1, outline=COLOR_BRASS_ANTIQUE, width=int(1*SCALE))

    final = img.resize((ow, oh), Image.LANCZOS)
    path = os.path.join(OUTPUT_DIR, "sleek_badge.png")
    final.save(path)
    print("Saved:", path)

if __name__ == "__main__":
    generate_expedition_divider()
    generate_sleek_gauge_casing()
    generate_sleek_interaction_plate()
    generate_sleek_reticle()
    generate_sleek_reticle_interact()
    generate_sleek_badge()
    print("ALL SLEEK MINIMALIST UI ASSETS GENERATED.")
