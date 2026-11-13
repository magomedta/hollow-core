# generate_all_icons.py
import os
import numpy as np
from PIL import Image

OUT_DIR = r"c:\Users\magom\Downloads\twitchst\hollow_core\textures"
os.makedirs(OUT_DIR, exist_ok=True)

def save_icon(name, arr):
    img = Image.fromarray(arr.astype(np.uint8), mode='RGBA')
    p = os.path.join(OUT_DIR, "icon_" + name + ".png")
    img.save(p)
    print(f"Saved icon_{name}.png ({img.size[0]}x{img.size[1]})")

def create_canvas():
    return np.zeros((32, 32, 4), dtype=np.uint8)

# 1. Detailed Pickaxe (Steel pick head, brass ferrule, dark carved wood handle)
def gen_icon_pickaxe():
    c = create_canvas()
    # Ash wood handle diagonal from (5, 27) to (20, 12)
    handle_dark = [70, 48, 30, 255]
    handle_mid = [115, 82, 54, 255]
    handle_light = [155, 115, 78, 255]
    ferrule_gold = [218, 172, 52, 255]
    steel_dark = [72, 80, 94, 255]
    steel_mid = [135, 146, 165, 255]
    steel_light = [198, 208, 226, 255]
    steel_spec = [245, 250, 255, 255]

    # Handle line
    for i in range(18):
        x = 5 + i
        y = 27 - i
        c[y, x] = handle_mid
        if x > 5 and y < 27:
            c[y + 1, x - 1] = handle_dark
        if y > 10 and x < 25:
            c[y - 1, x + 1] = handle_light

    # Brass ferrule collar at (19, 13) to (21, 11)
    for dx in range(-1, 2):
        for dy in range(-1, 2):
            if abs(dx) + abs(dy) <= 2:
                c[12 + dy, 20 + dx] = ferrule_gold

    # Chiseled Pick Head curved arc from (13, 5) through (21, 11) to (27, 19)
    # Left pick point
    pick_pts = [
        (11, 4, steel_spec), (12, 4, steel_light), (13, 5, steel_mid),
        (14, 6, steel_mid), (15, 7, steel_mid), (16, 8, steel_light),
        (17, 8, steel_light), (18, 9, steel_mid), (19, 10, steel_mid),
        (20, 11, steel_mid), (21, 11, steel_dark), (22, 12, steel_mid),
        (23, 13, steel_mid), (24, 14, steel_light), (25, 16, steel_light),
        (26, 18, steel_mid), (27, 20, steel_dark), (28, 21, steel_spec),
        # Thickness
        (12, 5, steel_dark), (13, 6, steel_dark), (14, 7, steel_dark),
        (15, 8, steel_dark), (16, 9, steel_dark), (17, 9, steel_dark),
        (18, 10, steel_dark), (19, 11, steel_dark), (20, 12, steel_dark),
        (21, 12, steel_dark), (22, 13, steel_dark), (23, 14, steel_dark),
        (24, 15, steel_dark), (25, 17, steel_dark), (26, 19, steel_dark),
        # Highlight top edge
        (13, 4, steel_spec), (14, 5, steel_light), (15, 6, steel_light),
        (16, 7, steel_spec), (17, 7, steel_spec), (18, 8, steel_light),
        (19, 9, steel_light), (20, 10, steel_spec)
    ]
    for (px, py, col) in pick_pts:
        if 0 <= px < 32 and 0 <= py < 32:
            c[py, px] = col
    save_icon("pickaxe", c)

# 2. Detailed Lantern (Brass cage, glowing flame, glass)
def gen_icon_lantern():
    c = create_canvas()
    brass_d = [118, 84, 24, 255]
    brass_m = [186, 142, 45, 255]
    brass_l = [238, 195, 82, 255]
    flame_c = [255, 250, 190, 255]
    flame_m = [255, 180, 50, 255]
    flame_d = [220, 95, 25, 255]
    glass_c = [140, 200, 230, 90]

    # Hanging ring on top (x=13..18, y=3..7)
    for x in range(13, 19):
        c[3, x] = brass_m
        c[7, x] = brass_m
    for y in range(4, 7):
        c[y, 13] = brass_d
        c[y, 18] = brass_l

    # Top cap dome (y=8..11, x=10..21)
    for y in range(8, 12):
        for x in range(16 - (y - 7) * 2, 16 + (y - 7) * 2):
            c[y, x] = brass_m
    for x in range(9, 23):
        c[11, x] = brass_l

    # Glass chamber & Cage frame (y=12..24, x=10..21)
    for y in range(12, 25):
        for x in range(10, 22):
            c[y, x] = glass_c
            # Vertical brass bars
            if x in [10, 14, 18, 21]:
                c[y, x] = brass_d if x == 10 else (brass_l if x == 21 else brass_m)

    # Glowing Flame in center (y=15..21, x=14..17)
    for y in range(15, 22):
        for x in range(14, 18):
            dist = abs(x - 15.5) + abs(y - 18)
            if dist < 1.2:
                c[y, x] = flame_c
            elif dist < 2.4:
                c[y, x] = flame_m
            else:
                c[y, x] = flame_d

    # Bottom fuel tank & base (y=25..29, x=9..22)
    for y in range(25, 29):
        for x in range(9, 23):
            c[y, x] = brass_m if y < 28 else brass_d
            if y == 25:
                c[y, x] = brass_l
    save_icon("lantern", c)

# 3. Detailed Wall Torch (Burning flame, ember embers, wood stick)
def gen_icon_torch():
    c = create_canvas()
    wood_d = [75, 48, 25, 255]
    wood_m = [120, 82, 45, 255]
    wood_l = [165, 120, 75, 255]
    char_d = [35, 30, 28, 255]
    fire_c = [255, 255, 210, 255]
    fire_y = [255, 205, 55, 255]
    fire_o = [245, 115, 25, 255]
    fire_r = [190, 45, 18, 255]

    # Diagonal stick from (7, 26) to (19, 14)
    for i in range(16):
        x = 7 + i
        y = 26 - i
        c[y, x] = wood_m
        c[y + 1, x] = wood_d
        c[y, x + 1] = wood_l

    # Wrapped head at (18, 15) to (22, 11)
    for dx in range(5):
        for dy in range(5):
            c[15 - dy, 18 + dx] = char_d if (dx + dy) % 2 == 0 else wood_d

    # Flame billow from (20, 10) to (27, 3)
    flame_pts = [
        (22, 9, fire_r), (21, 8, fire_o), (22, 8, fire_y), (23, 8, fire_c),
        (20, 7, fire_r), (21, 7, fire_o), (22, 7, fire_y), (23, 7, fire_c), (24, 7, fire_y),
        (21, 6, fire_o), (22, 6, fire_y), (23, 6, fire_c), (24, 6, fire_y), (25, 6, fire_o),
        (22, 5, fire_o), (23, 5, fire_y), (24, 5, fire_c), (25, 5, fire_y),
        (23, 4, fire_o), (24, 4, fire_y), (25, 4, fire_y),
        (24, 3, fire_o), (25, 3, fire_y),
        (26, 2, fire_o), (22, 3, fire_r)
    ]
    for (fx, fy, col) in flame_pts:
        if 0 <= fx < 32 and 0 <= fy < 32:
            c[fy, fx] = col
    save_icon("torch", c)

# 4. Detailed Timber (Heavy cross-cut log with bark & annual rings)
def gen_icon_timber():
    c = create_canvas()
    bark_d = [52, 36, 22, 255]
    bark_m = [84, 58, 36, 255]
    wood_d = [135, 96, 58, 255]
    wood_m = [172, 128, 82, 255]
    wood_l = [205, 162, 112, 255]

    for y in range(8, 24):
        for x in range(6, 26):
            # 3D isometric timber beam
            if x < 14: # Crosscut face
                dist = np.hypot(x - 10, y - 16)
                if dist > 5.5:
                    c[y, x] = bark_d
                elif int(dist) in [2, 4]:
                    c[y, x] = wood_d # Annual ring
                else:
                    c[y, x] = wood_m if dist > 1.5 else wood_l
            else: # Long bark trunk
                c[y, x] = bark_m if (y % 4 in [0, 1]) else bark_d
                if y == 8:
                    c[y, x] = [110, 78, 48, 255]
                elif y == 23:
                    c[y, x] = [40, 28, 18, 255]
    save_icon("timber", c)

# 5. Detailed Wooden Planks (Beveled boards with nail studs)
def gen_icon_planks():
    c = create_canvas()
    edge_d = [74, 50, 28, 255]
    plank_m = [156, 116, 72, 255]
    plank_l = [194, 152, 102, 255]
    nail = [60, 65, 75, 255]

    for y in range(6, 26):
        for x in range(6, 26):
            row = (y - 6) // 6 # 3 plank rows
            ry = (y - 6) % 6
            if ry == 0:
                c[y, x] = edge_d
            elif ry == 1:
                c[y, x] = plank_l
            elif ry == 5:
                c[y, x] = edge_d
            else:
                c[y, x] = plank_m

            # Seams & nails
            if (row == 0 and x == 18) or (row == 1 and x == 12) or (row == 2 and x == 20):
                c[y, x] = edge_d
            if x in [8, 23] and ry == 3:
                c[y, x] = nail
    save_icon("planks", c)

# 6. Detailed Cobblestone (Fractured stones with distinct mortar joints)
def gen_icon_cobblestone():
    c = create_canvas()
    mortar = [36, 40, 48, 255]
    stone_d = [68, 74, 86, 255]
    stone_m = [105, 112, 126, 255]
    stone_l = [148, 156, 172, 255]
    stone_hi = [182, 190, 206, 255]

    for y in range(6, 26):
        for x in range(6, 26):
            c[y, x] = stone_m
            # Mortar grid pattern
            if x == 6 or x == 25 or y == 6 or y == 25:
                c[y, x] = mortar
            elif y in [12, 19]:
                c[y, x] = mortar
            elif (y < 12 and x == 16) or (12 < y < 19 and x == 13) or (y > 19 and x == 18):
                c[y, x] = mortar
            elif (y in [7, 13, 20] and x > 6 and x < 25) or (x in [7, 14, 19]):
                c[y, x] = stone_hi
            elif (y in [11, 18, 24]) or (x in [12, 15, 24]):
                c[y, x] = stone_d
    save_icon("cobblestone", c)

# 7. Detailed Canteen (Metal flask with leather strap and water icon)
def gen_icon_canteen():
    c = create_canvas()
    cap_brass = [218, 172, 52, 255]
    tin_dark = [70, 78, 92, 255]
    tin_mid = [125, 138, 155, 255]
    tin_light = [185, 198, 215, 255]
    leather = [120, 68, 36, 255]
    water_blue = [45, 175, 245, 255]

    # Cap at top (y=4..7, x=14..17)
    for y in range(4, 8):
        for x in range(14, 18):
            c[y, x] = cap_brass

    # Oval Flask Body (y=8..26, x=8..23)
    for y in range(8, 27):
        for x in range(8, 24):
            dx = (x - 15.5) / 7.5
            dy = (y - 17.0) / 9.0
            if (dx * dx + dy * dy) <= 1.0:
                c[y, x] = tin_mid
                if dx < -0.4:
                    c[y, x] = tin_light # Specular highlight
                elif dx > 0.4:
                    c[y, x] = tin_dark

    # Leather strap crossing flask diagonally
    for i in range(14):
        x = 9 + i
        y = 10 + i
        if 0 <= y < 32 and 0 <= x < 32 and c[y, x, 3] > 0:
            c[y, x] = leather

    # Water droplet emblem in center
    droplet_pts = [(16, 16), (15, 17), (16, 17), (17, 17), (14, 18), (15, 18), (16, 18), (17, 18), (15, 19), (16, 19)]
    for (wx, wy) in droplet_pts:
        c[wy, wx] = water_blue
    save_icon("canteen", c)

# 8. Detailed Field Rations (Expedition tin ration box with meal compartments)
def gen_icon_rations():
    c = create_canvas()
    tin_edge = [52, 58, 68, 255]
    tin_top = [112, 122, 136, 255]
    tin_hi = [175, 185, 200, 255]
    biscuit = [215, 175, 115, 255]
    meat = [165, 65, 55, 255]
    dried_fruit = [65, 135, 75, 255]

    for y in range(8, 25):
        for x in range(6, 26):
            if x in [6, 25] or y in [8, 24]:
                c[y, x] = tin_edge
            elif x == 7 or y == 9:
                c[y, x] = tin_hi
            else:
                c[y, x] = tin_top

            # Internal food compartments
            if 11 <= y <= 21 and 9 <= x <= 14:
                c[y, x] = biscuit if (x + y) % 3 != 0 else [180, 140, 85, 255]
            elif 11 <= y <= 21 and 17 <= x <= 22:
                c[y, x] = meat if y < 17 else dried_fruit
    save_icon("rations", c)

# 9. Detailed Calcite Geode (Brilliant multi-faceted sparkling crystal)
def gen_icon_calcite():
    c = create_canvas()
    rock_d = [65, 68, 76, 255]
    c_base = [170, 185, 205, 255]
    c_mid = [215, 230, 248, 255]
    c_hi = [245, 252, 255, 255]
    c_gold = [255, 235, 170, 255]

    # Rock crust ring
    for y in range(6, 27):
        for x in range(6, 27):
            dist = np.hypot(x - 16, y - 16)
            if 8.5 < dist <= 10.5:
                c[y, x] = rock_d

    # Sharp crystalline prisms
    crystals = [
        # Center main spire
        [(15, 9, c_hi), (16, 8, c_hi), (16, 9, c_mid), (15, 10, c_base), (16, 10, c_hi), (17, 10, c_mid),
         (15, 11, c_mid), (16, 11, c_hi), (17, 11, c_base), (16, 12, c_mid), (16, 13, c_base)],
        # Left cluster
        [(11, 14, c_hi), (12, 13, c_hi), (12, 14, c_mid), (13, 15, c_base), (11, 15, c_gold), (12, 15, c_hi)],
        # Right cluster
        [(20, 13, c_hi), (21, 14, c_hi), (20, 14, c_mid), (19, 15, c_base), (20, 15, c_gold), (21, 15, c_mid)],
        # Bottom clusters
        [(14, 18, c_mid), (15, 19, c_hi), (16, 18, c_mid), (17, 19, c_base), (16, 20, c_hi)]
    ]
    for group in crystals:
        for (cx, cy, col) in group:
            if 0 <= cx < 32 and 0 <= cy < 32:
                c[cy, cx] = col
    save_icon("calcite", c)

# 10. Detailed Phosphor (Glowing cyan luminescent mineral with aura)
def gen_icon_phosphor():
    c = create_canvas()
    aura = [35, 160, 170, 75]
    c_dark = [18, 95, 105, 255]
    c_mid = [42, 195, 190, 255]
    c_light = [115, 245, 235, 255]
    c_core = [225, 255, 252, 255]

    for y in range(4, 28):
        for x in range(4, 28):
            dist = np.hypot(x - 16, y - 16)
            if dist <= 11.0:
                c[y, x] = aura

    # Faceted crystal nodule
    for y in range(9, 24):
        for x in range(9, 24):
            dx = abs(x - 16)
            dy = abs(y - 16)
            if (dx + dy) <= 8:
                c[y, x] = c_mid
                if dx + dy <= 3:
                    c[y, x] = c_core
                elif x < 15 and y < 15:
                    c[y, x] = c_light
                elif x > 17 or y > 17:
                    c[y, x] = c_dark
    save_icon("phosphor", c)

# 11. Detailed Iron Ingot (Chiseled metallic ingot with bevels)
def gen_icon_iron():
    c = create_canvas()
    iron_d = [82, 88, 100, 255]
    iron_m = [142, 152, 168, 255]
    iron_l = [198, 208, 222, 255]
    iron_hi = [242, 248, 255, 255]

    # Trapezoid 3D Ingot
    for y in range(10, 23):
        # Slope sides
        start_x = 7 + (y - 10) // 3
        end_x = 25 - (y - 10) // 3
        for x in range(start_x, end_x):
            c[y, x] = iron_m
            if y == 10:
                c[y, x] = iron_hi
            elif y == 11 or x == start_x:
                c[y, x] = iron_l
            elif y == 22 or x == end_x - 1:
                c[y, x] = iron_d
    save_icon("iron", c)

# 12. Detailed Gold Ingot (Rich lustrous golden bar)
def gen_icon_gold():
    c = create_canvas()
    gold_d = [175, 125, 20, 255]
    gold_m = [235, 185, 38, 255]
    gold_l = [255, 225, 88, 255]
    gold_hi = [255, 252, 185, 255]

    for y in range(10, 23):
        start_x = 7 + (y - 10) // 3
        end_x = 25 - (y - 10) // 3
        for x in range(start_x, end_x):
            c[y, x] = gold_m
            if y == 10:
                c[y, x] = gold_hi
            elif y == 11 or x == start_x:
                c[y, x] = gold_l
            elif y == 22 or x == end_x - 1:
                c[y, x] = gold_d
    save_icon("gold", c)

# 13. Detailed Field Journal (Leather book with brass lock & bookmark ribbon)
def gen_icon_journal():
    c = create_canvas()
    leather_d = [68, 38, 20, 255]
    leather_m = [115, 68, 36, 255]
    leather_l = [155, 96, 52, 255]
    page_edge = [218, 208, 185, 255]
    brass = [218, 172, 52, 255]
    ribbon = [185, 45, 35, 255]

    # Leather cover (y=6..26, x=7..25)
    for y in range(6, 27):
        for x in range(7, 26):
            c[y, x] = leather_m
            if x == 7 or y == 6:
                c[y, x] = leather_l
            elif x == 25 or y == 26:
                c[y, x] = leather_d
            # Spine groove
            if x == 10:
                c[y, x] = leather_d

    # Paper pages edge on right
    for y in range(7, 26):
        c[y, 24] = page_edge

    # Brass clasp in center right
    for y in range(14, 18):
        for x in range(21, 25):
            c[y, x] = brass

    # Crimson ribbon bookmark dangling from bottom
    for i in range(5):
        c[25 + i, 16] = ribbon
    save_icon("journal", c)

# 14. Detailed Bioluminescent Mushroom (Food & Water source!)
def gen_icon_mushroom():
    c = create_canvas()
    stem_d = [140, 160, 175, 255]
    stem_l = [200, 220, 235, 255]
    cap_d = [22, 105, 145, 255]
    cap_m = [45, 185, 215, 255]
    cap_l = [125, 245, 240, 255]
    spot_glow = [235, 255, 250, 255]

    # Slender curved stem (y=16..26, x=14..18)
    for y in range(16, 27):
        for x in range(14, 18):
            c[y, x] = stem_l if x == 14 else stem_d

    # Broad glowing fungal cap (y=7..16, x=7..25)
    for y in range(7, 17):
        for x in range(7, 25):
            dx = (x - 16.0) / 8.5
            dy = (y - 15.0) / 8.0
            if (dx * dx + dy * dy) <= 1.0 and y <= 16:
                c[y, x] = cap_m
                if dy < -0.4:
                    c[y, x] = cap_l
                elif dy > 0.1:
                    c[y, x] = cap_d

    # Bioluminescent spots on cap
    spots = [(12, 10), (16, 9), (20, 11), (14, 13), (18, 13)]
    for (sx, sy) in spots:
        c[sy, sx] = spot_glow
        c[sy, sx + 1] = spot_glow
    save_icon("mushroom", c)

# 15. Subterranean Water Source Icon (Droplet / Spring)
def gen_icon_water():
    c = create_canvas()
    w_dark = [22, 95, 175, 255]
    w_mid = [45, 175, 245, 255]
    w_light = [145, 225, 255, 255]
    w_spec = [240, 252, 255, 255]

    # Droplet shape
    for y in range(5, 27):
        width = min(8.0, (y - 5) * 0.7) if y < 17 else np.sqrt(max(0.0, 64.0 - (y - 19) ** 2))
        for x in range(int(16 - width), int(16 + width + 1)):
            c[y, x] = w_mid
            if x < 15 and y > 12:
                c[y, x] = w_spec if (x == 13 and y in [15, 16]) else w_light
            elif x > 18 or y > 23:
                c[y, x] = w_dark
    save_icon("water", c)

# 16. Lichen Clump (Subterranean food root)
def gen_icon_lichen():
    c = create_canvas()
    l_dark = [35, 78, 45, 255]
    l_mid = [72, 145, 82, 255]
    l_light = [145, 215, 135, 255]
    l_gold = [215, 195, 65, 255]

    for y in range(8, 25):
        for x in range(8, 25):
            dist = np.hypot(x - 16, y - 16)
            if dist < 7.5:
                if (x * 7 + y * 13) % 5 == 0:
                    c[y, x] = l_gold
                elif (x + y) % 3 == 0:
                    c[y, x] = l_light
                elif (x + y) % 2 == 0:
                    c[y, x] = l_mid
                else:
                    c[y, x] = l_dark
    save_icon("lichen", c)

# 17. Copper Ore Ingot / Nugget
def gen_icon_copper():
    c = create_canvas()
    cu_d = [145, 75, 45, 255]
    cu_m = [215, 125, 75, 255]
    cu_l = [245, 165, 110, 255]
    cu_vg = [72, 168, 145, 255]

    for y in range(10, 23):
        start_x = 7 + (y - 10) // 3
        end_x = 25 - (y - 10) // 3
        for x in range(start_x, end_x):
            c[y, x] = cu_m
            if (x + y) % 7 == 0:
                c[y, x] = cu_vg
            elif y == 10 or x == start_x:
                c[y, x] = cu_l
            elif y == 22 or x == end_x - 1:
                c[y, x] = cu_d
    save_icon("copper", c)

# 18. Coal Ore / Lump
def gen_icon_coal():
    c = create_canvas()
    c_d = [22, 24, 28, 255]
    c_m = [45, 48, 56, 255]
    c_l = [78, 84, 96, 255]
    c_hi = [135, 142, 158, 255]

    for y in range(8, 24):
        for x in range(8, 24):
            dist = np.hypot(x - 16, y - 16)
            if dist <= 7.0:
                c[y, x] = c_m
                if x < 14 and y < 14:
                    c[y, x] = c_hi if (x == 12 and y == 12) else c_l
                elif x > 17 or y > 17:
                    c[y, x] = c_d
    save_icon("coal", c)

if __name__ == "__main__":
    print("Generating comprehensive suite of refined 32x32 pixel art item icons...")
    gen_icon_pickaxe()
    gen_icon_lantern()
    gen_icon_torch()
    gen_icon_timber()
    gen_icon_planks()
    gen_icon_cobblestone()
    gen_icon_canteen()
    gen_icon_rations()
    gen_icon_calcite()
    gen_icon_phosphor()
    gen_icon_iron()
    gen_icon_gold()
    gen_icon_journal()
    gen_icon_mushroom()
    gen_icon_water()
    gen_icon_lichen()
    gen_icon_copper()
    gen_icon_coal()
    print("All icons generated successfully!")
