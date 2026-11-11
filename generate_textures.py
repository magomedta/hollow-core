# generate_textures.py
# High-Detail 64x64 Retro Stylized Pixel Art Texture Generator
# Aesthetic: Minecraft / Delver / Valheim inspired handcrafted palettes,
# subtle tonal variations, crisp bevel highlights, and NO harsh Bayer dithering.

import os
import math
import numpy as np
from PIL import Image

OUT_DIR = r"c:\Users\magom\Downloads\twitchst\hollow_core\textures"
os.makedirs(OUT_DIR, exist_ok=True)

def clamp(v, low=0, high=255):
    return max(low, min(high, int(v)))

def save_image(name, arr):
    img = Image.fromarray(arr.astype(np.uint8), mode='RGBA' if arr.shape[2] == 4 else 'RGB')
    p = os.path.join(OUT_DIR, name + ".png")
    img.save(p)
    print(f"Saved {name}.png ({img.size[0]}x{img.size[1]})")

def hash_noise(x, y, seed=0):
    n = (x * 374761393 + y * 668265263 + seed * 1013904223) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0

def smooth_noise(x, y, scale=8.0, seed=0):
    gx = x / scale
    gy = y / scale
    x0, y0 = int(gx), int(gy)
    x1, y1 = x0 + 1, y0 + 1
    fx = gx - x0
    fy = gy - y0
    fx = fx * fx * (3.0 - 2.0 * fx)
    fy = fy * fy * (3.0 - 2.0 * fy)
    v00 = hash_noise(x0, y0, seed)
    v10 = hash_noise(x1, y0, seed)
    v01 = hash_noise(x0, y1, seed)
    v11 = hash_noise(x1, y1, seed)
    return (1.0 - fy) * ((1.0 - fx) * v00 + fx * v10) + fy * ((1.0 - fx) * v01 + fx * v11)

# 1. Deep Basalt: Dark Volcanic Strata with Fractured Hexagonal Joints
def gen_deep_basalt():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    # Palette: Crisp Chiseled Volcanic Basalt (Subterranean Minecraft-style slate)
    c_joint = np.array([28, 32, 40, 255])
    c_dark  = np.array([48, 54, 66, 255])
    c_base1 = np.array([68, 76, 90, 255])
    c_base2 = np.array([82, 90, 105, 255])
    c_light = np.array([102, 112, 128, 255])
    c_bevel = np.array([125, 136, 155, 255])

    for y in range(h):
        for x in range(w):
            # Staggered 16x16 stone blocks
            row = y // 16
            col_offset = 8 if (row % 2 == 1) else 0
            bx = (x + col_offset) % 16
            by = y % 16

            is_joint = (bx == 0 or by == 0)
            is_bevel_top = (by == 1 and bx > 0)
            is_bevel_left = (bx == 1 and by > 0)
            is_shade_bot = (by == 15 and bx > 0)
            is_shade_right = (bx == 15 and by > 0)

            n = smooth_noise(x, y, 6.0, 101)
            micro = hash_noise(x, y, 202)

            if is_joint:
                col_val = c_joint
            elif is_bevel_top or is_bevel_left:
                col_val = c_bevel if micro > 0.4 else c_light
            elif is_shade_bot or is_shade_right:
                col_val = c_dark
            else:
                if n > 0.65:
                    col_val = c_light if micro > 0.3 else c_base2
                elif n > 0.35:
                    col_val = c_base2 if micro > 0.4 else c_base1
                elif n < 0.20:
                    col_val = c_dark if micro > 0.3 else c_base1
                else:
                    col_val = c_base1
            img[y, x] = col_val
    save_image("deep_basalt", img)

# 2. Fractured Cobblestone Shale: Layered Rock Pieces with Distinct Mortar
def gen_cobblestone_shale():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_mortar = np.array([36, 40, 48, 255])
    c_dark   = np.array([68, 74, 86, 255])
    c_mid1   = np.array([92, 98, 112, 255])
    c_mid2   = np.array([112, 120, 134, 255])
    c_light  = np.array([135, 144, 158, 255])
    c_hi     = np.array([162, 172, 188, 255])

    # Distinct stones with jittered cells
    for y in range(h):
        for x in range(w):
            # 8x8 to 16x16 irregular stone blocks
            bx = (x + int(math.sin(y * 0.2) * 2.5)) % 16
            by = (y + int(math.cos(x * 0.2) * 2.5)) % 16
            is_mortar = (bx == 0 or by == 0 or (bx == 8 and by > 8) or (by == 8 and bx > 8))
            is_edge_hi = (bx == 1 or by == 1) and not is_mortar
            is_edge_sh = (bx == 15 or by == 15) and not is_mortar

            n = smooth_noise(x, y, 5.0, 303)
            micro = hash_noise(x, y, 404)

            if is_mortar:
                col = c_mortar
            elif is_edge_hi:
                col = c_hi if micro > 0.5 else c_light
            elif is_edge_sh:
                col = c_dark
            else:
                if n > 0.60:
                    col = c_light if micro > 0.4 else c_mid2
                elif n > 0.30:
                    col = c_mid2 if micro > 0.4 else c_mid1
                else:
                    col = c_mid1 if micro > 0.3 else c_dark
            img[y, x] = col
    save_image("cobblestone_shale", img)

# 3. Mossy Damp Stone: Deep Cavern Stone with Glowing Teal/Green Lichen
def gen_mossy_stone():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_stone_d = np.array([32, 38, 42, 255])
    c_stone_m = np.array([48, 54, 60, 255])
    c_stone_l = np.array([66, 74, 82, 255])
    c_moss_d  = np.array([28, 62, 44, 255])
    c_moss_m  = np.array([44, 102, 68, 255])
    c_moss_l  = np.array([68, 148, 98, 255])
    c_moss_hi = np.array([102, 192, 134, 255])

    for y in range(h):
        for x in range(w):
            stone_n = smooth_noise(x, y, 7.0, 505)
            moss_n  = smooth_noise(x, y, 10.0, 606) + smooth_noise(x, y, 4.0, 707) * 0.4
            micro   = hash_noise(x, y, 808)

            if moss_n > 0.68:
                # Dense glowing lichen
                if micro > 0.70:
                    col = c_moss_hi
                elif micro > 0.35:
                    col = c_moss_l
                else:
                    col = c_moss_m
            elif moss_n > 0.48:
                # Sparse moss creep
                col = c_moss_m if micro > 0.5 else c_moss_d
            else:
                # Underlying basalt stone
                if stone_n > 0.65:
                    col = c_stone_l
                elif stone_n > 0.35:
                    col = c_stone_m
                else:
                    col = c_stone_d
            img[y, x] = col
    save_image("mossy_stone", img)

# 4. Slate Brick: Archaic Precursor Masonry with Inset Channels
def gen_slate_brick():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_joint = np.array([18, 20, 24, 255])
    c_dark  = np.array([34, 38, 44, 255])
    c_mid1  = np.array([52, 58, 68, 255])
    c_mid2  = np.array([66, 72, 84, 255])
    c_hi    = np.array([88, 96, 112, 255])
    c_rune  = np.array([55, 145, 175, 255]) # Faint cyan rune sheen

    for y in range(h):
        for x in range(w):
            # 32x16 large ashlar blocks
            row = y // 16
            col_offset = 16 if (row % 2 == 1) else 0
            bx = (x + col_offset) % 32
            by = y % 16

            is_joint = (bx == 0 or by == 0)
            is_top = (by == 1 and bx > 0)
            is_left = (bx == 1 and by > 0)
            is_bot = (by == 15 and bx > 0)
            is_right = (bx == 31 and by > 0)

            # Center geometric rune carving in select blocks
            is_rune = (row % 2 == 0) and ((bx >= 14 and bx <= 18 and by >= 6 and by <= 10) and (bx == 16 or by == 8))

            micro = hash_noise(x, y, 909)

            if is_joint:
                col = c_joint
            elif is_rune:
                col = c_rune
            elif is_top or is_left:
                col = c_hi if micro > 0.3 else c_mid2
            elif is_bot or is_right:
                col = c_dark
            else:
                col = c_mid2 if micro > 0.6 else c_mid1
            img[y, x] = col
    save_image("slate_brick", img)

# 5. Cavern Gravel & Loam: Natural Packed Cavern Earth with Mixed Pebbles (NO harsh chessboard!)
def gen_cavern_gravel():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_dirt_d = np.array([65, 55, 46, 255])
    c_dirt_m = np.array([88, 76, 65, 255])
    c_dirt_l = np.array([115, 100, 86, 255])
    c_peb_d  = np.array([85, 88, 96, 255])
    c_peb_l  = np.array([130, 138, 150, 255])
    c_peb_hi = np.array([168, 176, 190, 255])

    for y in range(h):
        for x in range(w):
            dirt_n = smooth_noise(x, y, 7.0, 1111)
            micro = hash_noise(x, y, 1212)
            # Irregular scattered pebbles (not a regular grid!)
            peb_n = smooth_noise(x, y, 3.2, 1313)

            if peb_n > 0.76:
                # Individual small round pebble
                if micro > 0.65:
                    col = c_peb_hi
                elif micro > 0.30:
                    col = c_peb_l
                else:
                    col = c_peb_d
            else:
                # Organic packed earth loam
                if dirt_n > 0.65:
                    col = c_dirt_l if micro > 0.4 else c_dirt_m
                elif dirt_n > 0.35:
                    col = c_dirt_m if micro > 0.3 else c_dirt_d
                else:
                    col = c_dirt_d
            img[y, x] = col
    save_image("cavern_gravel", img)

# 6. Wood Planks: Rich Warm Hewn Cedar Planks with Wrought Iron Nails
def gen_wood_planks():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_seam   = np.array([32, 20, 12, 255])
    c_dark   = np.array([92, 58, 36, 255])
    c_mid1   = np.array([136, 92, 58, 255])
    c_mid2   = np.array([122, 80, 48, 255])
    c_light  = np.array([158, 112, 74, 255])
    c_hi     = np.array([182, 134, 92, 255])
    c_nail   = np.array([44, 46, 52, 255])
    c_nail_h = np.array([95, 100, 110, 255])

    for y in range(h):
        for x in range(w):
            plank_h = 16
            plank_idx = y // plank_h
            py = y % plank_h
            end_x = 48 if (plank_idx % 2 == 0) else 16

            is_seam_h = (py == 0)
            is_seam_v = (x == end_x)
            is_nail = (py == 8 and (x == 4 or x == 60 or x == end_x - 4 or x == end_x + 4))
            is_nail_h = (py == 7 and (x == 4 or x == 60 or x == end_x - 4 or x == end_x + 4))

            micro = hash_noise(x, y, 1414)
            # Organic subtle wood grain running horizontally
            grain = math.sin(py * 1.6 + math.sin(x * 0.12) * 1.5)

            if is_seam_h or is_seam_v:
                col = c_seam
            elif is_nail:
                col = c_nail
            elif is_nail_h:
                col = c_nail_h
            elif py == 1 or x == end_x + 1:
                col = c_hi if micro > 0.4 else c_light
            elif py == plank_h - 1 or x == end_x - 1:
                col = c_dark
            else:
                base = c_mid1 if (plank_idx % 2 == 0) else c_mid2
                if grain > 0.6:
                    col = c_light if micro > 0.4 else base
                elif grain < -0.5:
                    col = c_dark if micro > 0.3 else base
                else:
                    col = base if micro > 0.25 else c_light
            img[y, x] = col
    save_image("wood_planks", img)

# 7. Hewn Timber: Organic Log Bark with Vertical Furrows and Lichen
def gen_hewn_timber():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_furrow = np.array([36, 24, 16, 255])
    c_bark_d = np.array([72, 48, 32, 255])
    c_bark_m = np.array([104, 72, 48, 255])
    c_bark_l = np.array([136, 96, 66, 255])
    c_moss   = np.array([58, 98, 62, 255])

    for y in range(h):
        for x in range(w):
            # Vertical wavy bark ridges
            rx = (x + int(math.sin(y * 0.18) * 3.0)) % 16
            is_furrow = (rx == 0)
            is_hi = (rx == 1)
            is_sh = (rx == 15)

            micro = hash_noise(x, y, 1515)
            n = smooth_noise(x, y, 6.0, 1616)

            if is_furrow:
                col = c_furrow
            elif is_hi:
                col = c_bark_l if micro > 0.35 else c_bark_m
            elif is_sh:
                col = c_bark_d
            else:
                if n > 0.72 and micro > 0.5:
                    col = c_moss
                elif n > 0.45:
                    col = c_bark_m if micro > 0.3 else c_bark_l
                else:
                    col = c_bark_d if micro > 0.4 else c_bark_m
            img[y, x] = col
    save_image("hewn_timber", img)

# 8. Expedition Cargo Crate: Sturdy Wooden Slats with Wrought Iron Brackets & Stencil
def gen_cargo_crate():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_iron_d  = np.array([38, 42, 48, 255])
    c_iron_m  = np.array([58, 64, 74, 255])
    c_iron_l  = np.array([92, 102, 116, 255])
    c_rivet   = np.array([170, 185, 205, 255])
    c_wood_d  = np.array([84, 54, 32, 255])
    c_wood_m  = np.array([126, 84, 52, 255])
    c_wood_l  = np.array([156, 108, 68, 255])
    c_seam    = np.array([28, 18, 12, 255])
    c_stencil = np.array([220, 185, 60, 255]) # Yellow expedition stencil

    for y in range(h):
        for x in range(w):
            is_frame = (x < 7 or x >= 57 or y < 7 or y >= 57)
            is_frame_seam = (x == 6 or x == 57 or y == 6 or y == 57)
            # Diagonal cross brace
            is_diag = (abs(x - y) <= 2 and not is_frame)
            is_diag_sh = (x - y == 3 and not is_frame)
            is_diag_hi = (y - x == 3 and not is_frame)

            # Heavy corner iron bracket (12x12)
            cx = min(x, 63 - x)
            cy = min(y, 63 - y)
            is_bracket = (cx < 12 and cy < 12 and (cx < 6 or cy < 6))
            is_rivet = ((cx == 3 and cy == 3) or (cx == 3 and cy == 9) or (cx == 9 and cy == 3))

            micro = hash_noise(x, y, 1717)

            if is_bracket:
                if is_rivet:
                    col = c_rivet
                elif cx == 0 or cy == 0 or cx == 5 or cy == 5:
                    col = c_iron_d
                else:
                    col = c_iron_m if micro > 0.4 else c_iron_l
            elif is_frame_seam:
                col = c_seam
            elif is_frame:
                if x == 1 or y == 1:
                    col = c_wood_l
                elif x == 56 or y == 56:
                    col = c_wood_d
                else:
                    col = c_wood_m if micro > 0.3 else c_wood_l
            elif is_diag:
                col = c_wood_m if micro > 0.35 else c_wood_l
            elif is_diag_hi:
                col = c_wood_l
            elif is_diag_sh:
                col = c_wood_d
            else:
                # Inset wooden panel slats
                slat_py = (y - 7) % 12
                if slat_py == 0:
                    col = c_seam
                elif slat_py == 1:
                    col = c_wood_l
                else:
                    col = c_wood_m if micro > 0.3 else c_wood_d
            img[y, x] = col
    save_image("cargo_crate", img)

# 9. Phosphor Ore: Bioluminescent Azure Crystals embedded in Dark Basalt
def gen_phosphor_ore():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_rock_d = np.array([24, 26, 32, 255])
    c_rock_m = np.array([38, 42, 50, 255])
    c_rock_l = np.array([54, 58, 68, 255])
    c_crys_d = np.array([12, 85, 125, 255])
    c_crys_m = np.array([28, 175, 215, 255])
    c_crys_l = np.array([85, 235, 255, 255])
    c_crys_h = np.array([210, 250, 255, 255])

    centers = [(20, 22, 10), (44, 38, 12), (24, 48, 8), (42, 16, 7)]
    for y in range(h):
        for x in range(w):
            micro = hash_noise(x, y, 1818)
            in_crystal = False
            for cx, cy, rad in centers:
                d = math.hypot(x - cx, y - cy)
                if d < rad:
                    in_crystal = True
                    # Crystalline facet geometric shading
                    facet = (x - cx) * 0.7 + (y - cy) * 0.7
                    if d < rad * 0.35:
                        col = c_crys_h
                    elif facet < -1.5:
                        col = c_crys_l if micro > 0.3 else c_crys_m
                    elif facet > 1.5:
                        col = c_crys_d
                    else:
                        col = c_crys_m
                    break
            if not in_crystal:
                rock_n = smooth_noise(x, y, 6.0, 1919)
                col = c_rock_l if rock_n > 0.6 else (c_rock_m if rock_n > 0.3 else c_rock_d)
            img[y, x] = col
    save_image("phosphor_ore", img)

# 10. Raw Iron Vein: Metallic Specular Bands across Cavern Stone
def gen_iron_ore():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_rock_d = np.array([34, 36, 42, 255])
    c_rock_m = np.array([48, 52, 60, 255])
    c_rock_l = np.array([66, 70, 80, 255])
    c_iron_d = np.array([115, 68, 36, 255])
    c_iron_m = np.array([185, 118, 58, 255])
    c_iron_l = np.array([225, 168, 92, 255])
    c_iron_h = np.array([255, 225, 165, 255])

    for y in range(h):
        for x in range(w):
            micro = hash_noise(x, y, 2020)
            # Vein path: undulating diagonal streaks
            v1 = abs(math.sin(x * 0.15 + y * 0.12) * 8.0 - (y % 20 - 10))
            v2 = abs(math.cos(x * 0.18 - y * 0.10) * 7.0 - ((x + y) % 28 - 14))
            is_vein = (v1 < 3.2 or v2 < 2.8)

            if is_vein:
                if micro > 0.75:
                    col = c_iron_h
                elif micro > 0.40:
                    col = c_iron_l
                elif micro > 0.18:
                    col = c_iron_m
                else:
                    col = c_iron_d
            else:
                rock_n = smooth_noise(x, y, 6.0, 2121)
                col = c_rock_l if rock_n > 0.6 else (c_rock_m if rock_n > 0.3 else c_rock_d)
            img[y, x] = col
    save_image("iron_ore", img)

# 11. Calcite Crystal: Translucent Amber/Gold Prisms
def gen_calcite_crystal():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_rock_d = np.array([30, 32, 38, 255])
    c_rock_m = np.array([46, 50, 58, 255])
    c_calc_d = np.array([155, 110, 42, 255])
    c_calc_m = np.array([215, 165, 68, 255])
    c_calc_l = np.array([248, 212, 115, 255])
    c_calc_h = np.array([255, 246, 195, 255])

    clusters = [(24, 24, 11), (42, 40, 12), (18, 44, 7)]
    for y in range(h):
        for x in range(w):
            micro = hash_noise(x, y, 2222)
            in_calc = False
            for cx, cy, rad in clusters:
                d = math.hypot(x - cx, y - cy)
                if d < rad:
                    in_calc = True
                    facet = (x - cx) - (y - cy)
                    if d < rad * 0.30:
                        col = c_calc_h
                    elif facet < -1.0:
                        col = c_calc_l if micro > 0.3 else c_calc_m
                    elif facet > 1.0:
                        col = c_calc_d
                    else:
                        col = c_calc_m
                    break
            if not in_calc:
                rn = smooth_noise(x, y, 6.0, 2323)
                col = c_rock_m if rn > 0.5 else c_rock_d
            img[y, x] = col
    save_image("calcite_crystal", img)

# 12. Industrial Steel: Heavy Forged Metal Plates with Rivets
def gen_industrial_steel():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_seam  = np.array([24, 26, 30, 255])
    c_dark  = np.array([48, 52, 60, 255])
    c_mid   = np.array([72, 78, 88, 255])
    c_light = np.array([98, 106, 120, 255])
    c_hi    = np.array([135, 145, 162, 255])
    c_rivet = np.array([180, 192, 215, 255])

    for y in range(h):
        for x in range(w):
            is_seam = (x == 0 or x == 32 or y == 0 or y == 32)
            px = x % 32
            py = y % 32
            is_riv = ((px == 4 and py == 4) or (px == 27 and py == 4) or (px == 4 and py == 27) or (px == 27 and py == 27))
            micro = hash_noise(x, y, 2424)

            if is_seam:
                col = c_seam
            elif is_riv:
                col = c_rivet
            elif px == 1 or py == 1:
                col = c_hi
            elif px == 31 or py == 31:
                col = c_dark
            else:
                col = c_mid if micro > 0.4 else c_light
            img[y, x] = col
    save_image("industrial_steel", img)

# 13. Antique Brass: Burnished Surveyor Brass with Patina & Rivets
def gen_antique_brass():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_patina = np.array([38, 48, 38, 255]) # Greenish verdigris
    c_dark   = np.array([88, 62, 24, 255])
    c_mid    = np.array([148, 108, 42, 255])
    c_light  = np.array([195, 152, 68, 255])
    c_hi     = np.array([238, 198, 105, 255])
    c_spec   = np.array([255, 235, 168, 255])

    for y in range(h):
        for x in range(w):
            micro = hash_noise(x, y, 2525)
            n = smooth_noise(x, y, 8.0, 2626)
            is_edge = (x < 2 or x >= 62 or y < 2 or y >= 62)

            if is_edge:
                col = c_dark if (x >= 62 or y >= 62) else c_hi
            elif n > 0.82 and micro > 0.6:
                col = c_patina
            elif n > 0.60:
                col = c_hi if micro > 0.4 else c_light
            elif n > 0.30:
                col = c_light if micro > 0.3 else c_mid
            else:
                col = c_mid if micro > 0.35 else c_dark
            img[y, x] = col
    save_image("antique_brass", img)

# 14. Canvas Coat Sleeve: Speleologist Expedition Dark Slate Jacket
def gen_canvas_sleeve():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    # Refined expedition field coat palette (deep graphite/slate navy with warm accent stitching)
    c_stitch = np.array([22, 25, 30, 255])
    c_dark   = np.array([38, 44, 52, 255])
    c_mid1   = np.array([48, 56, 66, 255])
    c_mid2   = np.array([58, 68, 80, 255])
    c_light  = np.array([72, 84, 98, 255])
    c_thread = np.array([170, 150, 115, 255])
    c_cuff   = np.array([28, 32, 38, 255])

    for y in range(h):
        for x in range(w):
            micro = hash_noise(x, y, 2727)
            # Uniform 2x2 fine twill fabric weave
            twill = ((x // 2) + (y // 2)) % 2
            is_cuff_seam = (y == 12)
            is_cuff = (y < 12)
            is_vert_seam = (x == 20 or x == 44)
            is_stitch = (is_cuff_seam and (x % 4 == 0)) or (is_vert_seam and (y % 6 == 0))

            if is_stitch:
                col = c_thread
            elif is_cuff_seam or is_vert_seam:
                col = c_stitch
            elif is_cuff:
                col = c_cuff if micro > 0.4 else c_dark
            else:
                base = c_mid2 if twill == 0 else c_mid1
                if micro > 0.72:
                    col = c_light
                elif micro < 0.28:
                    col = c_dark
                else:
                    col = base
            img[y, x] = col
    save_image("canvas_sleeve", img)

# 15. Work Glove: Reinforced Saddle Leather Speleology Glove with Brass Rivets
def gen_work_glove():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_dark   = np.array([56, 38, 26, 255])
    c_mid1   = np.array([84, 58, 40, 255])
    c_mid2   = np.array([112, 78, 54, 255])
    c_light  = np.array([138, 98, 70, 255])
    c_seam   = np.array([38, 24, 16, 255])
    c_stitch = np.array([180, 155, 110, 255])
    c_brass  = np.array([218, 178, 80, 255])

    for y in range(h):
        for x in range(w):
            micro = hash_noise(x, y, 2828)
            grain = ((x ^ y) % 3)
            is_wrist_band = (y >= 52 and y <= 60)
            is_buckle = is_wrist_band and (x >= 28 and x <= 36) and (x == 28 or x == 36 or y == 52 or y == 60)
            is_rivet = (y == 24 and (x == 18 or x == 46))
            is_knuckle_seam = (y == 32)
            is_stitch = ((y == 51 or y == 61) and (x % 4 == 0)) or (is_knuckle_seam and (x % 3 == 0))

            if is_buckle or is_rivet:
                col = c_brass
            elif is_stitch:
                col = c_stitch
            elif is_knuckle_seam:
                col = c_seam
            elif is_wrist_band:
                col = c_dark if micro > 0.4 else c_mid1
            else:
                if grain == 0 and micro > 0.65:
                    col = c_light
                elif micro < 0.22:
                    col = c_dark
                elif micro > 0.55:
                    col = c_mid2
                else:
                    col = c_mid1
            img[y, x] = col
    save_image("work_glove", img)

# 16. Hazard Steel: Black & Yellow Subterranean Safety Striping
def gen_hazard_steel():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_black_d = np.array([28, 30, 34, 255])
    c_black_l = np.array([44, 46, 52, 255])
    c_yel_d   = np.array([175, 138, 24, 255])
    c_yel_l   = np.array([235, 192, 42, 255])

    for y in range(h):
        for x in range(w):
            micro = hash_noise(x, y, 2929)
            stripe = ((x + y) // 10) % 2
            if stripe == 0:
                col = c_black_l if micro > 0.5 else c_black_d
            else:
                col = c_yel_l if micro > 0.4 else c_yel_d
            img[y, x] = col
    save_image("hazard_steel", img)

# 17. Progressive Dig Cracks (Stages 1 through 5)
def gen_dig_cracks():
    w, h = 64, 64
    c_black = np.array([10, 10, 12, 245])
    c_white = np.array([240, 245, 255, 220])

    crack_branches = [
        [(32, 32), (30, 26), (28, 20), (24, 15), (20, 8), (16, 2)],
        [(32, 32), (36, 28), (42, 24), (48, 18), (56, 14)],
        [(32, 32), (38, 36), (46, 40), (52, 46), (60, 54)],
        [(32, 32), (30, 38), (28, 44), (22, 50), (14, 58)],
        [(32, 32), (24, 30), (18, 28), (10, 26), (2, 25)],
        [(32, 32), (40, 32), (48, 34), (58, 35)]
    ]

    for stage in range(1, 6):
        img = np.zeros((h, w, 4), dtype=float)
        # Stage 1: few central lines. Stage 5: sprawling shatter spiderweb
        max_branches = min(len(crack_branches), stage + 1)
        max_depth = int(stage * 1.2) + 2

        for bi in range(max_branches):
            branch = crack_branches[bi]
            limit = min(len(branch) - 1, max_depth)
            for seg in range(limit):
                p0 = branch[seg]
                p1 = branch[seg + 1]
                steps = max(abs(p1[0] - p0[0]), abs(p1[1] - p0[1])) * 2
                for st in range(steps + 1):
                    t = float(st) / max(1, steps)
                    cx = int(p0[0] + (p1[0] - p0[0]) * t)
                    cy = int(p0[1] + (p1[1] - p0[1]) * t)
                    if cx >= 0 and cx < w and cy >= 0 and cy < h:
                        img[cy, cx] = c_black
                        # White bevel highlight on crack edge
                        if cy + 1 < h and img[cy + 1, cx, 3] == 0:
                            img[cy + 1, cx] = c_white
        save_image(f"dig_crack_{stage}", img)

# 18. Natural Stone Rock: Classic Natural Cave Stone (Minecraft inspired clean gray grain)
def gen_stone_rock():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_dark  = np.array([92, 94, 102, 255])
    c_mid1  = np.array([115, 117, 126, 255])
    c_mid2  = np.array([132, 134, 144, 255])
    c_light = np.array([150, 153, 164, 255])
    c_bevel = np.array([168, 172, 184, 255])

    for y in range(h):
        for x in range(w):
            n = smooth_noise(x, y, 6.0, 711)
            micro = hash_noise(x, y, 722)
            n_grain = smooth_noise(x, y, 2.5, 733)
            val = n * 0.6 + n_grain * 0.4

            if val > 0.72:
                col = c_bevel if micro > 0.4 else c_light
            elif val > 0.48:
                col = c_light if micro > 0.5 else c_mid2
            elif val > 0.28:
                col = c_mid2 if micro > 0.4 else c_mid1
            else:
                col = c_mid1 if micro > 0.5 else c_dark
            img[y, x] = col
    save_image("stone_rock", img)

# 19. Deepslate Rock: Stratified Dark Basaltic Slate with Horizontal Cleavage
def gen_deepslate_rock():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_joint = np.array([22, 24, 30, 255])
    c_dark  = np.array([38, 40, 48, 255])
    c_mid1  = np.array([54, 58, 68, 255])
    c_mid2  = np.array([68, 72, 84, 255])
    c_light = np.array([86, 92, 105, 255])

    for y in range(h):
        for x in range(w):
            # Horizontal wavy cleavage bands
            wave_y = y + int(math.sin(x * 0.18) * 1.8)
            band = wave_y % 16
            is_joint = (band == 0 or band == 8)
            is_edge = (band == 1 or band == 9)

            n = smooth_noise(x, y, 5.0, 811)
            micro = hash_noise(x, y, 822)

            if is_joint:
                col = c_joint
            elif is_edge:
                col = c_light if micro > 0.4 else c_mid2
            else:
                if n > 0.6:
                    col = c_mid2 if micro > 0.3 else c_mid1
                elif n > 0.3:
                    col = c_mid1 if micro > 0.4 else c_dark
                else:
                    col = c_dark
            img[y, x] = col
    save_image("deepslate_rock", img)

# 20. Granite Rock: Pinkish/Terracotta Coarse Intrusive Rock
def gen_granite_rock():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_dark  = np.array([125, 82, 74, 255])
    c_mid1  = np.array([152, 104, 94, 255])
    c_mid2  = np.array([176, 122, 110, 255])
    c_light = np.array([198, 142, 128, 255])
    c_speck = np.array([72, 50, 46, 255]) # Dark biotite speckles

    for y in range(h):
        for x in range(w):
            n = smooth_noise(x, y, 4.5, 911)
            micro = hash_noise(x, y, 922)
            if micro > 0.92:
                col = c_speck
            elif n > 0.68:
                col = c_light if micro > 0.3 else c_mid2
            elif n > 0.38:
                col = c_mid2 if micro > 0.4 else c_mid1
            else:
                col = c_mid1 if micro > 0.4 else c_dark
            img[y, x] = col
    save_image("granite_rock", img)

# 21. Diorite Rock: Pale Salt-and-Pepper Speckled Crystalline Rock
def gen_diorite_rock():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_white = np.array([225, 228, 235, 255])
    c_light = np.array([196, 200, 208, 255])
    c_mid   = np.array([160, 164, 172, 255])
    c_dark  = np.array([118, 122, 130, 255])
    c_black = np.array([62, 65, 72, 255]) # Dark hornblende crystals

    for y in range(h):
        for x in range(w):
            n = smooth_noise(x, y, 5.0, 1011)
            micro = hash_noise(x, y, 1022)
            if micro > 0.88:
                col = c_black
            elif micro > 0.72:
                col = c_dark
            elif n > 0.65:
                col = c_white if micro > 0.3 else c_light
            elif n > 0.35:
                col = c_light if micro > 0.4 else c_mid
            else:
                col = c_mid
            img[y, x] = col
    save_image("diorite_rock", img)

# 22. Andesite Rock: Smooth Slate-Gray Neutral Volcanic Rock
def gen_andesite_rock():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_dark  = np.array([102, 105, 112, 255])
    c_mid1  = np.array([122, 126, 134, 255])
    c_mid2  = np.array([140, 144, 154, 255])
    c_light = np.array([160, 164, 175, 255])

    for y in range(h):
        for x in range(w):
            n = smooth_noise(x, y, 7.0, 1111)
            micro = hash_noise(x, y, 1122)
            if n > 0.65:
                col = c_light if micro > 0.4 else c_mid2
            elif n > 0.35:
                col = c_mid2 if micro > 0.3 else c_mid1
            else:
                col = c_mid1 if micro > 0.5 else c_dark
            img[y, x] = col
    save_image("andesite_rock", img)

# 23. Coal Ore: Stone with Anthracite Mineral Lumps
def gen_coal_ore():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_stone_d = np.array([102, 105, 112, 255])
    c_stone_m = np.array([124, 127, 136, 255])
    c_stone_l = np.array([144, 148, 158, 255])

    c_coal_d  = np.array([18, 18, 22, 255])
    c_coal_m  = np.array([34, 34, 40, 255])
    c_coal_l  = np.array([54, 56, 66, 255])
    c_coal_hi = np.array([85, 88, 102, 255])

    for y in range(h):
        for x in range(w):
            ore_n = smooth_noise(x, y, 4.2, 1211)
            stone_n = smooth_noise(x, y, 6.0, 1222)
            micro = hash_noise(x, y, 1233)

            # Scattered coal chunks
            if ore_n > 0.62:
                if micro > 0.75:
                    col = c_coal_hi
                elif micro > 0.40:
                    col = c_coal_l
                elif micro > 0.15:
                    col = c_coal_m
                else:
                    col = c_coal_d
            else:
                if stone_n > 0.6:
                    col = c_stone_l
                elif stone_n > 0.3:
                    col = c_stone_m
                else:
                    col = c_stone_d
            img[y, x] = col
    save_image("coal_ore", img)

# 24. Copper Ore: Stone with Turquoise Verdigris & Orange Copper Nuggets
def gen_copper_ore():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_stone_d = np.array([102, 105, 112, 255])
    c_stone_m = np.array([124, 127, 136, 255])
    c_stone_l = np.array([144, 148, 158, 255])

    c_cu_orange = np.array([215, 125, 75, 255])
    c_cu_bright = np.array([245, 155, 95, 255])
    c_cu_dark   = np.array([155, 85, 52, 255])
    c_verdigris = np.array([72, 168, 145, 255])
    c_vg_bright = np.array([105, 205, 180, 255])

    for y in range(h):
        for x in range(w):
            ore_n = smooth_noise(x, y, 4.0, 1311)
            stone_n = smooth_noise(x, y, 6.0, 1322)
            micro = hash_noise(x, y, 1333)

            if ore_n > 0.64:
                # Copper cluster with oxidation edge
                if micro > 0.82:
                    col = c_cu_bright
                elif micro > 0.50:
                    col = c_cu_orange
                elif micro > 0.25:
                    col = c_vg_bright if ore_n > 0.7 else c_verdigris
                else:
                    col = c_cu_dark
            else:
                col = c_stone_l if stone_n > 0.6 else (c_stone_m if stone_n > 0.3 else c_stone_d)
            img[y, x] = col
    save_image("copper_ore", img)

# 25. Gold Ore: Deepslate Base with Lustrous 24k Pyrite Flakes
def gen_gold_ore():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_slate_d = np.array([38, 40, 48, 255])
    c_slate_m = np.array([55, 58, 68, 255])
    c_slate_l = np.array([72, 76, 88, 255])

    c_gold_d  = np.array([195, 150, 28, 255])
    c_gold_m  = np.array([238, 195, 48, 255])
    c_gold_l  = np.array([255, 226, 92, 255])
    c_gold_hi = np.array([255, 248, 168, 255])

    for y in range(h):
        for x in range(w):
            ore_n = smooth_noise(x, y, 3.8, 1411)
            slate_n = smooth_noise(x, y, 5.0, 1422)
            micro = hash_noise(x, y, 1433)

            if ore_n > 0.66:
                if micro > 0.85:
                    col = c_gold_hi
                elif micro > 0.50:
                    col = c_gold_l
                elif micro > 0.25:
                    col = c_gold_m
                else:
                    col = c_gold_d
            else:
                col = c_slate_l if slate_n > 0.6 else (c_slate_m if slate_n > 0.3 else c_slate_d)
            img[y, x] = col
    save_image("gold_ore", img)

# 26. Permafrost Ice: Upper Stratum Glacial Ice with Crystalline Fractures
def gen_permafrost_ice():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_ice_d  = np.array([125, 175, 215, 240])
    c_ice_m  = np.array([160, 205, 238, 245])
    c_ice_l  = np.array([195, 230, 252, 255])
    c_ice_hi = np.array([235, 248, 255, 255])
    c_crack  = np.array([255, 255, 255, 255])

    for y in range(h):
        for x in range(w):
            n = smooth_noise(x, y, 8.0, 1511)
            micro = hash_noise(x, y, 1522)
            # Fracture lines
            fx = (x * 3 + y * 2) % 24
            is_crack = (fx == 0 and micro > 0.4)

            if is_crack:
                col = c_crack
            elif n > 0.68:
                col = c_ice_hi if micro > 0.4 else c_ice_l
            elif n > 0.38:
                col = c_ice_l if micro > 0.5 else c_ice_m
            else:
                col = c_ice_m if micro > 0.4 else c_ice_d
            img[y, x] = col
    save_image("permafrost_ice", img)

# 27. Magma Rock: Scorched Volcanic Basalt with Glowing Molten Fissures
def gen_magma_rock():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_crust_d = np.array([22, 18, 20, 255])
    c_crust_m = np.array([38, 32, 34, 255])
    c_lava_d  = np.array([185, 45, 15, 255])
    c_lava_m  = np.array([245, 95, 20, 255])
    c_lava_l  = np.array([255, 175, 35, 255])
    c_lava_hi = np.array([255, 235, 95, 255])

    for y in range(h):
        for x in range(w):
            lava_n = smooth_noise(x, y, 4.8, 1611)
            crust_n = smooth_noise(x, y, 7.0, 1622)
            micro = hash_noise(x, y, 1633)

            if lava_n > 0.65:
                # Glowing molten vein
                if micro > 0.75:
                    col = c_lava_hi
                elif micro > 0.45:
                    col = c_lava_l
                elif micro > 0.20:
                    col = c_lava_m
                else:
                    col = c_lava_d
            else:
                col = c_crust_m if crust_n > 0.5 else c_crust_d
            img[y, x] = col
    save_image("magma_rock", img)

# 28. Indestructible Bedrock: Dark Mottled Obsidian/Basalt
def gen_bedrock():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_void  = np.array([12, 12, 16, 255])
    c_dark  = np.array([24, 26, 32, 255])
    c_mid   = np.array([44, 46, 56, 255])
    c_light = np.array([68, 70, 84, 255])

    for y in range(h):
        for x in range(w):
            n1 = smooth_noise(x, y, 3.5, 1711)
            n2 = smooth_noise(x, y, 1.8, 1722)
            micro = hash_noise(x, y, 1733)
            val = n1 * 0.5 + n2 * 0.5

            if val > 0.72:
                col = c_light if micro > 0.5 else c_mid
            elif val > 0.45:
                col = c_mid if micro > 0.4 else c_dark
            elif val > 0.22:
                col = c_dark
            else:
                col = c_void
            img[y, x] = col
    save_image("bedrock", img)

# 29. Stalker Chitin: Armored Insectoid Plates with Bioluminescent Veins
def gen_stalker_chitin():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_groove = np.array([14, 16, 20, 255])
    c_dark   = np.array([28, 32, 40, 255])
    c_plate  = np.array([46, 52, 65, 255])
    c_bevel  = np.array([72, 82, 98, 255])
    c_bio    = np.array([45, 215, 195, 255]) # Cyan bio-luminescence
    c_bio_hi = np.array([120, 255, 240, 255])

    for y in range(h):
        for x in range(w):
            cell_y = y % 16
            cell_x = x % 16
            is_joint = (cell_y == 0 or cell_x == 0)
            is_edge = (cell_y == 1 or cell_x == 1)

            micro = hash_noise(x, y, 1811)
            bio_n = smooth_noise(x, y, 5.0, 1822)

            if is_joint:
                col = c_groove
            elif bio_n > 0.75:
                col = c_bio_hi if micro > 0.5 else c_bio
            elif is_edge:
                col = c_bevel if micro > 0.4 else c_plate
            else:
                col = c_plate if micro > 0.5 else c_dark
            img[y, x] = col
    save_image("stalker_chitin", img)

# 30. Unified 512x512 Texture Atlas: Compiles 64x64 tiles into an 8x8 grid
def gen_texture_atlas():
    atlas_dim = 512
    tile_size = 64
    atlas = np.zeros((atlas_dim, atlas_dim, 4), dtype=np.uint8)

    # 8x8 tile assignments (Row, Col)
    tile_map = {
        (0, 0): "stone_rock",
        (0, 1): "deepslate_rock",
        (0, 2): "granite_rock",
        (0, 3): "diorite_rock",
        (0, 4): "andesite_rock",
        (0, 5): "cavern_gravel",
        (0, 6): "coal_ore",
        (0, 7): "iron_ore",

        (1, 0): "copper_ore",
        (1, 1): "gold_ore",
        (1, 2): "calcite_crystal",
        (1, 3): "mossy_stone",
        (1, 4): "permafrost_ice",
        (1, 5): "magma_rock",
        (1, 6): "cobblestone_shale",
        (1, 7): "deep_basalt",

        (2, 0): "wood_planks",
        (2, 1): "hewn_timber",
        (2, 2): "cargo_crate",
        (2, 3): "slate_brick",
        (2, 4): "bedrock",
        (2, 5): "phosphor_ore",
        (2, 6): "stalker_chitin",
        (2, 7): "antique_brass",

        (3, 0): "industrial_steel",
        (3, 1): "hazard_steel",
        (3, 2): "dig_crack_1",
        (3, 3): "dig_crack_2",
        (3, 4): "dig_crack_3",
        (3, 5): "dig_crack_4",
        (3, 6): "dig_crack_5",
        (3, 7): "work_glove",
    }

    for (row, col), tex_name in tile_map.items():
        tex_path = os.path.join(OUT_DIR, tex_name + ".png")
        if os.path.exists(tex_path):
            img = Image.open(tex_path).convert("RGBA").resize((tile_size, tile_size), Image.NEAREST)
            arr = np.array(img)
            y_start = row * tile_size
            x_start = col * tile_size
            atlas[y_start:y_start+tile_size, x_start:x_start+tile_size] = arr
        else:
            print(f"[WARN] Atlas missing tile: {tex_name}")

    save_image("texture_atlas", atlas)

def main():
    print("Generating comprehensive 64x64 pixel art texture suite...")
    gen_deep_basalt()
    gen_cobblestone_shale()
    gen_mossy_stone()
    gen_slate_brick()
    gen_cavern_gravel()
    gen_wood_planks()
    gen_hewn_timber()
    gen_cargo_crate()
    gen_phosphor_ore()
    gen_iron_ore()
    gen_calcite_crystal()
    gen_industrial_steel()
    gen_antique_brass()
    gen_canvas_sleeve()
    gen_work_glove()
    gen_hazard_steel()
    gen_dig_cracks()

    # New Diverse Strata & Block Textures
    gen_stone_rock()
    gen_deepslate_rock()
    gen_granite_rock()
    gen_diorite_rock()
    gen_andesite_rock()
    gen_coal_ore()
    gen_copper_ore()
    gen_gold_ore()
    gen_permafrost_ice()
    gen_magma_rock()
    gen_bedrock()
    gen_stalker_chitin()

    # Unified 512x512 Texture Atlas
    gen_texture_atlas()
    print("All textures and unified texture atlas successfully created!")

if __name__ == "__main__":
    main()
