# generate_new_biome_textures.py
import os
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

# 1. Water Spring Block (Subterranean crystal blue water texture)
def gen_water_spring():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_deep = np.array([18, 65, 125, 255])
    c_mid = np.array([28, 120, 195, 255])
    c_light = np.array([75, 185, 245, 255])
    c_crest = np.array([185, 240, 255, 255])

    for y in range(h):
        for x in range(w):
            wave1 = smooth_noise(x, y, 12.0, 4411)
            wave2 = smooth_noise(x + y * 0.5, y, 6.0, 4422)
            val = (wave1 * 0.6 + wave2 * 0.4)
            if val > 0.72:
                col = c_crest
            elif val > 0.48:
                col = c_light
            elif val > 0.28:
                col = c_mid
            else:
                col = c_deep
            img[y, x] = col
    save_image("water_spring", img)

# 2. Bioluminescent Mushroom Block (Cyan & indigo glowing fungal mycelium)
def gen_biolum_mushroom():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_mycelium = np.array([22, 32, 45, 255])
    c_spore_dark = np.array([15, 95, 125, 255])
    c_spore_bright = np.array([45, 215, 225, 255])
    c_glow_core = np.array([215, 255, 252, 255])

    for y in range(h):
        for x in range(w):
            n = smooth_noise(x, y, 7.0, 5511)
            micro = hash_noise(x, y, 5522)
            col = c_mycelium
            # Concentrated bioluminescent cap nodules
            if n > 0.58:
                if micro > 0.75:
                    col = c_glow_core
                elif micro > 0.35:
                    col = c_spore_bright
                else:
                    col = c_spore_dark
            img[y, x] = col
    save_image("biolum_mushroom", img)

# 3. Sulfur Fumarole Block (Volcanic sulfur crust & pyritic specks)
def gen_sulfur_block():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_ash_d = np.array([48, 44, 38, 255])
    c_sulf_d = np.array([165, 145, 28, 255])
    c_sulf_m = np.array([218, 195, 36, 255])
    c_sulf_l = np.array([255, 238, 75, 255])

    for y in range(h):
        for x in range(w):
            sn = smooth_noise(x, y, 8.0, 6611)
            micro = hash_noise(x, y, 6622)
            if sn > 0.65:
                col = c_sulf_l if micro > 0.5 else c_sulf_m
            elif sn > 0.35:
                col = c_sulf_m if micro > 0.4 else c_sulf_d
            else:
                col = c_ash_d
            img[y, x] = col
    save_image("sulfur_block", img)

# 4. Amethyst Crystal Block (Vibrant violet crystal facets)
def gen_crystal_amethyst():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_dark = np.array([65, 28, 92, 255])
    c_mid = np.array([125, 55, 168, 255])
    c_light = np.array([185, 95, 225, 255])
    c_spec = np.array([245, 215, 255, 255])

    for y in range(h):
        for x in range(w):
            gx = (x % 16) - 8
            gy = (y % 16) - 8
            dist = abs(gx) + abs(gy)
            n = hash_noise(x // 16, y // 16, 7711)
            if dist < 3 and n > 0.4:
                col = c_spec
            elif dist < 6:
                col = c_light
            elif dist < 10:
                col = c_mid
            else:
                col = c_dark
            img[y, x] = col
    save_image("crystal_amethyst", img)

# 5. Precursor Conduit (Alien harmonic etched slate with glowing runes)
def gen_precursor_conduit():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_slate = np.array([32, 36, 44, 255])
    c_slate_edge = np.array([55, 60, 72, 255])
    c_rune_glow = np.array([35, 215, 245, 255])
    c_rune_core = np.array([210, 255, 255, 255])

    for y in range(h):
        for x in range(w):
            is_edge = (x < 2 or x >= 62 or y < 2 or y >= 62)
            # Circuit geometric pattern
            is_conduit = (x == 31 or x == 32 or y == 31 or y == 32) or (abs(x - 32) == abs(y - 32) and abs(x - 32) < 20)
            if is_conduit:
                col = c_rune_core if hash_noise(x, y, 8811) > 0.4 else c_rune_glow
            elif is_edge:
                col = c_slate_edge
            else:
                col = c_slate
            img[y, x] = col
    save_image("precursor_conduit", img)

# 6. Lichen Root (Cave loam with edible golden-green roots)
def gen_lichen_root():
    w, h = 64, 64
    img = np.zeros((h, w, 4), dtype=float)
    c_rock = np.array([68, 72, 78, 255])
    c_moss = np.array([45, 105, 52, 255])
    c_root = np.array([175, 155, 62, 255])
    c_root_bright = np.array([225, 205, 95, 255])

    for y in range(h):
        for x in range(w):
            n = smooth_noise(x, y, 6.0, 9911)
            micro = hash_noise(x, y, 9922)
            if n > 0.65:
                col = c_root_bright if micro > 0.6 else c_root
            elif n > 0.35:
                col = c_moss
            else:
                col = c_rock
            img[y, x] = col
    save_image("lichen_root", img)

# Update Texture Atlas with Row 4
def update_atlas_with_row_4():
    atlas_path = os.path.join(OUT_DIR, "texture_atlas.png")
    if not os.path.exists(atlas_path):
        from generate_textures import gen_texture_atlas
        gen_texture_atlas()
    
    atlas_img = Image.open(atlas_path).convert("RGBA")
    atlas_arr = np.array(atlas_img)
    tile_size = 64

    row_4_tiles = {
        (4, 0): "water_spring",
        (4, 1): "biolum_mushroom",
        (4, 2): "sulfur_block",
        (4, 3): "crystal_amethyst",
        (4, 4): "precursor_conduit",
        (4, 5): "lichen_root"
    }

    for (row, col), name in row_4_tiles.items():
        t_path = os.path.join(OUT_DIR, name + ".png")
        if os.path.exists(t_path):
            t_img = Image.open(t_path).convert("RGBA").resize((tile_size, tile_size), Image.NEAREST)
            y_start = row * tile_size
            x_start = col * tile_size
            atlas_arr[y_start:y_start+tile_size, x_start:x_start+tile_size] = np.array(t_img)

    result_img = Image.fromarray(atlas_arr, mode='RGBA')
    result_img.save(atlas_path)
    print(f"Updated texture_atlas.png with Row 4 tiles!")

if __name__ == "__main__":
    print("Generating new biome textures...")
    gen_water_spring()
    gen_biolum_mushroom()
    gen_sulfur_block()
    gen_crystal_amethyst()
    gen_precursor_conduit()
    gen_lichen_root()
    update_atlas_with_row_4()
    print("Done!")
