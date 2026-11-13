# generate_refined_assets.py
import os
import math
import numpy as np
from PIL import Image

OUT_DIR = r"c:\Users\magom\Downloads\twitchst\hollow_core\textures"
os.makedirs(OUT_DIR, exist_ok=True)

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

def save_image(name, arr):
    img = Image.fromarray(arr.astype(np.uint8), mode='RGBA' if arr.shape[2] == 4 else 'RGB')
    p = os.path.join(OUT_DIR, name + ".png")
    img.save(p)
    print(f"Saved {name}.png ({img.size[0]}x{img.size[1]})")

# --- Refined Minimalist Ore Textures (64x64) ---
# Subtle, delicate, natural crystalline specks & thin mineral fissures embedded in host rock

def gen_calcite_crystal():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_rock_d = np.array([92, 94, 102, 255])
    c_rock_m = np.array([115, 117, 126, 255])
    c_rock_l = np.array([136, 140, 150, 255])

    # Delicate sparkling white/pale-gold crystal facets (NOT cartoon blobs!)
    c_calc_d = np.array([180, 185, 200, 255])
    c_calc_m = np.array([220, 225, 238, 255])
    c_calc_l = np.array([245, 248, 255, 255])
    c_calc_h = np.array([255, 255, 255, 255])

    clusters = [
        [(14, 16), (15, 16), (15, 17), (16, 17)],
        [(36, 14), (37, 14), (37, 15)],
        [(48, 22), (49, 22), (49, 23), (50, 23)],
        [(20, 36), (21, 36), (21, 37)],
        [(42, 42), (43, 42), (43, 43), (44, 43)],
        [(16, 52), (17, 52), (17, 53)],
        [(34, 56), (35, 56), (35, 57), (36, 57)]
    ]
    speck_map = set()
    for cl in clusters:
        for pt in cl:
            speck_map.add(pt)

    for y in range(h):
        for x in range(w):
            rn = smooth_noise(x, y, 6.0, 2323)
            micro = hash_noise(x, y, 2222)
            col = c_rock_l if rn > 0.6 else (c_rock_m if rn > 0.3 else c_rock_d)

            if (x, y) in speck_map:
                if micro > 0.75:
                    col = c_calc_h
                elif micro > 0.45:
                    col = c_calc_l
                elif micro > 0.20:
                    col = c_calc_m
                else:
                    col = c_calc_d
            img[y, x] = col
    save_image("calcite_crystal", img)

def gen_coal_ore():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_stone_d = np.array([102, 105, 112, 255])
    c_stone_m = np.array([124, 127, 136, 255])
    c_stone_l = np.array([144, 148, 158, 255])

    c_coal_d  = np.array([22, 22, 28, 255])
    c_coal_m  = np.array([36, 38, 46, 255])
    c_coal_l  = np.array([55, 58, 70, 255])
    c_coal_hi = np.array([78, 82, 96, 255])

    clusters = [
        [(12, 14), (13, 15), (14, 14)],
        [(28, 9), (29, 9), (29, 10)],
        [(45, 18), (46, 18), (46, 19)],
        [(8, 38), (9, 38), (9, 39)],
        [(22, 44), (23, 44), (23, 45)],
        [(38, 34), (39, 34), (39, 35)],
        [(52, 42), (53, 42), (53, 43)],
        [(16, 56), (17, 56)],
        [(42, 54), (43, 54), (43, 55)]
    ]
    speck_map = set()
    for cl in clusters:
        for pt in cl:
            speck_map.add(pt)

    for y in range(h):
        for x in range(w):
            stone_n = smooth_noise(x, y, 6.0, 1222)
            micro = hash_noise(x, y, 1233)
            col = c_stone_l if stone_n > 0.6 else (c_stone_m if stone_n > 0.3 else c_stone_d)

            if (x, y) in speck_map:
                if micro > 0.7:
                    col = c_coal_hi
                elif micro > 0.35:
                    col = c_coal_l
                elif micro > 0.15:
                    col = c_coal_m
                else:
                    col = c_coal_d
            img[y, x] = col
    save_image("coal_ore", img)

def gen_iron_ore():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_rock_d = np.array([92, 94, 102, 255])
    c_rock_m = np.array([115, 117, 126, 255])
    c_rock_l = np.array([136, 140, 150, 255])

    c_iron_d = np.array([140, 80, 50, 255])
    c_iron_m = np.array([195, 125, 78, 255])
    c_iron_l = np.array([235, 168, 110, 255])
    c_iron_h = np.array([255, 218, 168, 255])

    clusters = [
        [(15, 12), (16, 12), (16, 13)],
        [(36, 18), (37, 18), (37, 19)],
        [(50, 26), (51, 26), (51, 27)],
        [(10, 42), (11, 42), (11, 43)],
        [(28, 38), (29, 38), (29, 39)],
        [(46, 48), (47, 48), (47, 49)],
        [(24, 56), (25, 56), (25, 57)]
    ]
    speck_map = set()
    for cl in clusters:
        for pt in cl:
            speck_map.add(pt)

    for y in range(h):
        for x in range(w):
            rock_n = smooth_noise(x, y, 6.0, 2121)
            micro = hash_noise(x, y, 2020)
            col = c_rock_l if rock_n > 0.6 else (c_rock_m if rock_n > 0.3 else c_rock_d)

            if (x, y) in speck_map:
                if micro > 0.75:
                    col = c_iron_h
                elif micro > 0.40:
                    col = c_iron_l
                elif micro > 0.18:
                    col = c_iron_m
                else:
                    col = c_iron_d
            img[y, x] = col
    save_image("iron_ore", img)

def gen_copper_ore():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_stone_d = np.array([102, 105, 112, 255])
    c_stone_m = np.array([124, 127, 136, 255])
    c_stone_l = np.array([144, 148, 158, 255])

    c_cu_orange = np.array([215, 125, 75, 255])
    c_cu_bright = np.array([245, 160, 105, 255])
    c_cu_dark   = np.array([155, 85, 52, 255])
    c_verdigris = np.array([72, 168, 145, 255])
    c_vg_bright = np.array([105, 205, 180, 255])

    clusters = [
        [(18, 16), (19, 16), (19, 17)],
        [(42, 12), (43, 12), (43, 13)],
        [(12, 36), (13, 36), (13, 37)],
        [(32, 32), (33, 32), (33, 33)],
        [(52, 38), (53, 38), (53, 39)],
        [(22, 52), (23, 52), (23, 53)],
        [(44, 54), (45, 54), (45, 55)]
    ]
    speck_map = set()
    for cl in clusters:
        for pt in cl:
            speck_map.add(pt)

    for y in range(h):
        for x in range(w):
            stone_n = smooth_noise(x, y, 6.0, 1322)
            micro = hash_noise(x, y, 1333)
            col = c_stone_l if stone_n > 0.6 else (c_stone_m if stone_n > 0.3 else c_stone_d)

            if (x, y) in speck_map:
                if micro > 0.80:
                    col = c_cu_bright
                elif micro > 0.50:
                    col = c_cu_orange
                elif micro > 0.25:
                    col = c_vg_bright if micro > 0.38 else c_verdigris
                else:
                    col = c_cu_dark
            img[y, x] = col
    save_image("copper_ore", img)

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

    clusters = [
        [(14, 18), (15, 18), (15, 19)],
        [(38, 14), (39, 14)],
        [(52, 22), (53, 22), (53, 23)],
        [(22, 34), (23, 34)],
        [(44, 40), (45, 40), (45, 41)],
        [(16, 48), (17, 48)],
        [(34, 54), (35, 54), (35, 55)]
    ]
    speck_map = set()
    for cl in clusters:
        for pt in cl:
            speck_map.add(pt)

    for y in range(h):
        for x in range(w):
            slate_n = smooth_noise(x, y, 5.0, 1422)
            micro = hash_noise(x, y, 1433)
            col = c_slate_l if slate_n > 0.6 else (c_slate_m if slate_n > 0.3 else c_slate_d)

            if (x, y) in speck_map:
                if micro > 0.78:
                    col = c_gold_hi
                elif micro > 0.45:
                    col = c_gold_l
                elif micro > 0.20:
                    col = c_gold_m
                else:
                    col = c_gold_d
            img[y, x] = col
    save_image("gold_ore", img)

def gen_phosphor_ore():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_slate_d = np.array([36, 40, 48, 255])
    c_slate_m = np.array([52, 56, 66, 255])
    c_slate_l = np.array([70, 75, 86, 255])

    c_ph_dark = np.array([18, 95, 95, 255])
    c_ph_mid  = np.array([32, 175, 168, 255])
    c_ph_lite = np.array([78, 240, 218, 255])
    c_ph_core = np.array([195, 255, 245, 255])

    clusters = [
        [(16, 14), (17, 14), (17, 15)],
        [(44, 16), (45, 16), (45, 17)],
        [(26, 28), (27, 28), (27, 29)],
        [(48, 36), (49, 36), (49, 37)],
        [(12, 44), (13, 44), (13, 45)],
        [(34, 48), (35, 48), (35, 49)],
        [(20, 58), (21, 58)]
    ]
    speck_map = set()
    for cl in clusters:
        for pt in cl:
            speck_map.add(pt)

    for y in range(h):
        for x in range(w):
            slate_n = smooth_noise(x, y, 5.0, 1822)
            micro = hash_noise(x, y, 1833)
            col = c_slate_l if slate_n > 0.6 else (c_slate_m if slate_n > 0.3 else c_slate_d)

            if (x, y) in speck_map:
                if micro > 0.75:
                    col = c_ph_core
                elif micro > 0.45:
                    col = c_ph_lite
                elif micro > 0.20:
                    col = c_ph_mid
                else:
                    col = c_ph_dark
            img[y, x] = col
    save_image("phosphor_ore", img)

def update_texture_atlas():
    from generate_textures import gen_texture_atlas
    gen_texture_atlas()

if __name__ == "__main__":
    print("Regenerating subtle minimalist ores & calcite...")
    gen_calcite_crystal()
    gen_coal_ore()
    gen_iron_ore()
    gen_copper_ore()
    gen_gold_ore()
    gen_phosphor_ore()
    print("Re-baking texture atlas...")
    update_texture_atlas()
    print("Done!")
