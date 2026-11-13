import os
import math
from PIL import Image, ImageDraw

OUT_DIR = "hollow_core/textures"
os.makedirs(OUT_DIR, exist_ok=True)

SIZE = 64

def create_isometric_block(top_col, left_col, right_col, pattern="plain", ore_col=None):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Isometric vertices (64x64 bounding box, crisp voxel cube)
    # Center vertex: (32, 32)
    # Top vertex: (32, 8)
    # Top-Right: (56, 20)
    # Top-Left: (8, 20)
    # Bottom-Right: (56, 44)
    # Bottom-Left: (8, 44)
    # Bottom vertex: (32, 56)

    # Dark silhouette outline for contrast
    offset_pts = [
        (32, 6), (58, 19), (58, 46), (32, 59), (6, 46), (6, 19)
    ]
    draw.polygon(offset_pts, fill=(18, 22, 28, 240))

    # Top Face (Illuminated from above)
    top_pts = [(32, 8), (56, 20), (32, 32), (8, 20)]
    draw.polygon(top_pts, fill=top_col)

    # Left Face (Medium shade)
    left_pts = [(8, 20), (32, 32), (32, 56), (8, 44)]
    draw.polygon(left_pts, fill=left_col)

    # Right Face (Shadowed)
    right_pts = [(32, 32), (56, 20), (56, 44), (32, 56)]
    draw.polygon(right_pts, fill=right_col)

    # Internal patterns based on block type
    if pattern == "planks":
        # Horizontal plank lines and wood grain
        # Top face lines
        draw.line([(20, 14), (44, 26)], fill=(int(top_col[0]*0.75), int(top_col[1]*0.75), int(top_col[2]*0.75)), width=1)
        # Left face planks
        draw.line([(8, 28), (32, 40)], fill=(int(left_col[0]*0.72), int(left_col[1]*0.72), int(left_col[2]*0.72)), width=1)
        draw.line([(8, 36), (32, 48)], fill=(int(left_col[0]*0.72), int(left_col[1]*0.72), int(left_col[2]*0.72)), width=1)
        # Right face planks
        draw.line([(32, 40), (56, 28)], fill=(int(right_col[0]*0.72), int(right_col[1]*0.72), int(right_col[2]*0.72)), width=1)
        draw.line([(32, 48), (56, 36)], fill=(int(right_col[0]*0.72), int(right_col[1]*0.72), int(right_col[2]*0.72)), width=1)
        # Nail dots
        draw.point([(12, 26), (30, 35), (34, 35), (52, 26)], fill=(40, 30, 20, 255))

    elif pattern == "timber":
        # Hewn timber ring cross-section on top, vertical grain on sides
        draw.ellipse([(24, 15), (40, 25)], outline=(int(top_col[0]*0.7), int(top_col[1]*0.7), int(top_col[2]*0.7)), width=1)
        draw.point([(32, 20)], fill=(50, 35, 20, 255))
        # Side bark grooves
        draw.line([(16, 24), (16, 48)], fill=(int(left_col[0]*0.7), int(left_col[1]*0.7), int(left_col[2]*0.7)), width=1)
        draw.line([(24, 28), (24, 52)], fill=(int(left_col[0]*0.7), int(left_col[1]*0.7), int(left_col[2]*0.7)), width=1)
        draw.line([(40, 28), (40, 52)], fill=(int(right_col[0]*0.7), int(right_col[1]*0.7), int(right_col[2]*0.7)), width=1)
        draw.line([(48, 24), (48, 48)], fill=(int(right_col[0]*0.7), int(right_col[1]*0.7), int(right_col[2]*0.7)), width=1)

    elif pattern == "cobble":
        # Cobblestone mortar cracks
        mortar_top = (int(top_col[0]*0.6), int(top_col[1]*0.6), int(top_col[2]*0.6), 255)
        draw.line([(20, 16), (32, 24), (44, 18)], fill=mortar_top, width=1)
        draw.line([(26, 12), (28, 22)], fill=mortar_top, width=1)
        mortar_left = (int(left_col[0]*0.6), int(left_col[1]*0.6), int(left_col[2]*0.6), 255)
        draw.line([(12, 30), (22, 32), (20, 48)], fill=mortar_left, width=1)
        draw.line([(22, 32), (32, 42)], fill=mortar_left, width=1)
        mortar_right = (int(right_col[0]*0.6), int(right_col[1]*0.6), int(right_col[2]*0.6), 255)
        draw.line([(42, 30), (46, 42), (36, 48)], fill=mortar_right, width=1)
        draw.line([(32, 42), (46, 42)], fill=mortar_right, width=1)

    elif pattern == "crate":
        # Wooden cargo crate with steel reinforcement edges and cross brace
        bracket_col = (140, 150, 165, 255)
        # Top X brace
        draw.line([(14, 20), (50, 20)], fill=(70, 50, 30, 255), width=2)
        draw.line([(32, 11), (32, 29)], fill=(70, 50, 30, 255), width=2)
        # Left side cross-brace
        draw.line([(10, 23), (30, 53)], fill=(60, 42, 24, 255), width=2)
        # Right side cross-brace
        draw.line([(54, 23), (34, 53)], fill=(45, 30, 18, 255), width=2)
        # Metal corners
        draw.polygon([(32, 8), (36, 10), (32, 12), (28, 10)], fill=bracket_col)
        draw.polygon([(8, 20), (12, 22), (12, 27), (8, 25)], fill=bracket_col)
        draw.polygon([(56, 20), (52, 22), (52, 27), (56, 25)], fill=bracket_col)
        draw.polygon([(32, 56), (36, 54), (32, 52), (28, 54)], fill=bracket_col)

    elif pattern == "magma":
        # Magma rock glowing fissures
        glow1 = (255, 120, 20, 255)
        glow2 = (255, 220, 60, 255)
        draw.line([(24, 16), (32, 22), (40, 18)], fill=glow1, width=2)
        draw.line([(25, 16), (31, 22), (39, 18)], fill=glow2, width=1)
        draw.line([(16, 28), (24, 38), (18, 48)], fill=glow1, width=2)
        draw.line([(17, 28), (23, 38), (19, 48)], fill=glow2, width=1)
        draw.line([(40, 28), (44, 38), (36, 46)], fill=glow1, width=2)
        draw.line([(41, 28), (43, 38), (37, 46)], fill=glow2, width=1)

    elif pattern == "calcite":
        # Prismatic calcite crystal shards
        glint = (240, 245, 255, 255)
        draw.polygon([(26, 12), (34, 14), (38, 24), (30, 22)], fill=(210, 220, 240, 255))
        draw.line([(26, 12), (38, 24)], fill=glint, width=1)
        draw.polygon([(14, 28), (22, 26), (26, 42), (18, 44)], fill=(180, 195, 225, 255))
        draw.line([(14, 28), (26, 42)], fill=glint, width=1)
        draw.polygon([(38, 28), (46, 26), (50, 42), (42, 44)], fill=(150, 165, 195, 255))
        draw.line([(38, 28), (50, 42)], fill=glint, width=1)

    elif pattern == "ore" and ore_col:
        # Metallic ore specks embedded in stone
        for ox, oy in [(22, 16), (36, 18), (28, 26), (16, 32), (24, 44), (40, 34), (48, 42)]:
            draw.rectangle([(ox-1, oy-1), (ox+1, oy+1)], fill=ore_col)
            draw.point([(ox, oy)], fill=(min(255, ore_col[0]+60), min(255, ore_col[1]+60), min(255, ore_col[2]+60), 255))

    # Crisp top ridge highlights
    draw.line([(32, 8), (56, 20)], fill=(int(min(255, top_col[0]*1.3)), int(min(255, top_col[1]*1.3)), int(min(255, top_col[2]*1.3)), 200), width=1)
    draw.line([(32, 8), (8, 20)], fill=(int(min(255, top_col[0]*1.3)), int(min(255, top_col[1]*1.3)), int(min(255, top_col[2]*1.3)), 200), width=1)
    draw.line([(32, 32), (32, 56)], fill=(int(min(255, left_col[0]*1.2)), int(min(255, left_col[1]*1.2)), int(min(255, left_col[2]*1.2)), 160), width=1)

    return img


def draw_pickaxe():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Drop shadow
    for offset in [(1, 2), (2, 2)]:
        draw.line([(18+offset[0], 50+offset[1]), (46+offset[0], 22+offset[1])], fill=(0, 0, 0, 140), width=5)

    # Wooden handle (diagonal from 16, 52 to 46, 22)
    wood_shadow = (75, 45, 25, 255)
    wood_main = (145, 95, 55, 255)
    wood_hi = (185, 125, 75, 255)

    draw.line([(16, 52), (44, 24)], fill=wood_shadow, width=5)
    draw.line([(17, 51), (45, 23)], fill=wood_main, width=4)
    draw.line([(18, 50), (46, 22)], fill=wood_hi, width=2)

    # Leather handle wrap
    for wx, wy in [(20, 48), (24, 44), (28, 40)]:
        draw.line([(wx-2, wy+2), (wx+2, wy-2)], fill=(210, 160, 110, 255), width=2)

    # Steel Pickaxe Head (Arched heavy forged metal pick)
    # Head center socket at (46, 22)
    # Left pick point: (24, 12)
    # Right pick point: (54, 42)
    metal_dark = (45, 52, 60, 255)
    metal_mid = (115, 125, 140, 255)
    metal_light = (195, 205, 220, 255)
    metal_hi = (245, 250, 255, 255)

    pick_curve = [
        (20, 10), (30, 12), (40, 16), (46, 22), (52, 30), (56, 40)
    ]
    draw.line(pick_curve, fill=metal_dark, width=7)
    draw.line(pick_curve, fill=metal_mid, width=5)
    draw.line(pick_curve, fill=metal_light, width=3)
    draw.line([(22, 11), (32, 13), (42, 17), (48, 23)], fill=metal_hi, width=1)

    # Sharp points
    draw.polygon([(18, 9), (22, 8), (22, 13)], fill=metal_hi)
    draw.polygon([(56, 41), (58, 43), (53, 43)], fill=metal_hi)

    # Brass socket collar
    draw.ellipse([(43, 19), (49, 25)], fill=(215, 170, 60, 255), outline=(130, 95, 25, 255))
    return img


def draw_lantern():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Glow aura behind lantern
    glow_col = (255, 180, 50, 40)
    draw.ellipse([(14, 18), (50, 54)], fill=glow_col)

    # Hanging wire handle
    draw.arc([(22, 6), (42, 22)], 180, 360, fill=(190, 160, 90, 255), width=2)
    # Top brass cap & vent hood
    draw.rectangle([(28, 14), (36, 17)], fill=(225, 185, 75, 255), outline=(110, 80, 20, 255))
    draw.polygon([(24, 21), (40, 21), (36, 17), (28, 17)], fill=(210, 170, 60, 255))
    draw.line([(22, 22), (42, 22)], fill=(245, 215, 110, 255), width=2)

    # Glass chimney / chamber (22, 23 to 42, 43)
    draw.rectangle([(22, 23), (42, 43)], fill=(35, 45, 60, 180), outline=(140, 110, 40, 255))

    # Glowing flame & wick inside
    draw.ellipse([(28, 30), (36, 38)], fill=(255, 240, 150, 255))
    draw.ellipse([(30, 32), (34, 36)], fill=(255, 255, 240, 255))
    draw.line([(32, 38), (32, 42)], fill=(80, 40, 20, 255), width=2)

    # Protective brass cage bars
    draw.line([(27, 23), (27, 43)], fill=(210, 170, 60, 255), width=1)
    draw.line([(37, 23), (37, 43)], fill=(210, 170, 60, 255), width=1)

    # Heavy brass fuel reservoir base
    draw.rectangle([(20, 44), (44, 47)], fill=(230, 190, 80, 255), outline=(100, 70, 15, 255))
    draw.polygon([(20, 48), (44, 48), (46, 54), (18, 54)], fill=(195, 155, 50, 255), outline=(90, 65, 15, 255))
    draw.line([(18, 54), (46, 54)], fill=(120, 90, 25, 255), width=2)
    return img


def draw_torch():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Diagonal burning torch
    # Wood stick: (18, 52) to (36, 26)
    draw.line([(17, 53), (35, 27)], fill=(70, 45, 25, 255), width=6)
    draw.line([(18, 52), (36, 26)], fill=(140, 95, 55, 255), width=4)
    draw.line([(19, 51), (37, 25)], fill=(180, 125, 75, 255), width=2)

    # Carbide head wrap
    draw.rectangle([(34, 22), (42, 28)], fill=(50, 45, 45, 255), outline=(30, 25, 25, 255))

    # Bright burning flame
    draw.ellipse([(35, 8), (49, 24)], fill=(255, 100, 20, 220))
    draw.ellipse([(37, 11), (47, 21)], fill=(255, 190, 40, 240))
    draw.ellipse([(39, 14), (45, 19)], fill=(255, 255, 180, 255))

    # Sparks/embers
    draw.point([(48, 8), (44, 5), (51, 14), (36, 7)], fill=(255, 220, 100, 255))
    return img


def draw_canteen():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Strap
    draw.arc([(12, 10), (52, 50)], 190, 350, fill=(90, 60, 35, 255), width=2)
    # Brass cap & neck
    draw.rectangle([(29, 14), (35, 18)], fill=(215, 175, 65, 255), outline=(100, 75, 20, 255))
    draw.line([(28, 19), (36, 19)], fill=(130, 95, 25, 255), width=2)

    # Round canteen flask body
    draw.ellipse([(16, 20), (48, 52)], fill=(65, 85, 105, 255), outline=(35, 45, 55, 255))
    draw.ellipse([(18, 22), (46, 50)], fill=(95, 120, 145, 255))
    # Specular shine
    draw.arc([(20, 24), (44, 48)], 200, 280, fill=(190, 215, 240, 255), width=2)
    # Leather harness band
    draw.line([(17, 36), (47, 36)], fill=(110, 75, 45, 255), width=3)
    draw.line([(32, 21), (32, 51)], fill=(110, 75, 45, 255), width=3)
    return img


def draw_rations():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # MRE Survival Ration Pack (Olive drab / metallic sealed pouch)
    draw.rectangle([(16, 16), (48, 48)], fill=(60, 72, 55, 255), outline=(30, 38, 28, 255))
    draw.rectangle([(18, 18), (46, 46)], fill=(85, 102, 78, 255))
    # Seal ridges
    draw.line([(16, 20), (48, 20)], fill=(40, 50, 36, 255), width=1)
    draw.line([(16, 44), (48, 44)], fill=(40, 50, 36, 255), width=1)
    # Emergency Red Cross / Medical / Food Emblem
    draw.rectangle([(29, 27), (35, 37)], fill=(195, 45, 40, 255))
    draw.rectangle([(25, 30), (39, 34)], fill=(195, 45, 40, 255))
    draw.line([(18, 18), (46, 18)], fill=(140, 160, 130, 255), width=1)
    return img


def draw_journal():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Leather-bound book
    draw.rectangle([(16, 14), (48, 50)], fill=(80, 45, 30, 255), outline=(40, 20, 15, 255))
    draw.rectangle([(18, 16), (46, 48)], fill=(115, 65, 40, 255))
    # Pages trim
    draw.line([(47, 16), (47, 48)], fill=(235, 225, 195, 255), width=2)
    # Gold embossed surveyor emblem
    draw.ellipse([(28, 28), (36, 36)], outline=(225, 185, 75, 255), width=1)
    draw.line([(32, 26), (32, 38)], fill=(225, 185, 75, 255), width=1)
    draw.line([(26, 32), (38, 32)], fill=(225, 185, 75, 255), width=1)
    # Silk bookmark ribbon
    draw.line([(32, 48), (32, 54), (35, 52)], fill=(185, 40, 40, 255), width=2)
    return img


def draw_ingot(base_col, mid_col, light_col, hi_col):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Isometric metallic trapezoidal ingot
    # Top face
    draw.polygon([(20, 24), (44, 24), (40, 32), (24, 32)], fill=light_col)
    # Left front bevel
    draw.polygon([(14, 38), (20, 24), (24, 32), (18, 44)], fill=base_col)
    # Right front face
    draw.polygon([(24, 32), (40, 32), (46, 44), (18, 44)], fill=mid_col)
    # Right side bevel
    draw.polygon([(40, 32), (44, 24), (50, 38), (46, 44)], fill=base_col)

    # Specular shine lines
    draw.line([(21, 24), (43, 24)], fill=hi_col, width=1)
    draw.line([(24, 32), (40, 32)], fill=hi_col, width=1)
    return img


def draw_crystal(core_col, mid_col, hi_col):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Main crystal spire
    draw.polygon([(32, 10), (42, 26), (38, 48), (26, 48), (22, 26)], fill=mid_col)
    # Left lit facet
    draw.polygon([(32, 10), (22, 26), (26, 48), (32, 48), (32, 10)], fill=core_col)
    draw.line([(32, 10), (32, 48)], fill=hi_col, width=1)

    # Smaller flanking crystal spires
    draw.polygon([(20, 28), (26, 36), (24, 52), (16, 52), (14, 38)], fill=mid_col)
    draw.polygon([(44, 24), (50, 34), (48, 52), (40, 52), (38, 36)], fill=core_col)

    # Base rock bed
    draw.polygon([(14, 50), (50, 50), (46, 56), (18, 56)], fill=(50, 55, 65, 255))
    return img


def draw_mushroom():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Bioluminescent mushroom
    # Stem
    draw.polygon([(28, 32), (36, 32), (38, 52), (26, 52)], fill=(160, 200, 210, 255), outline=(80, 120, 130, 255))
    # Cap (glowing teal/cyan)
    draw.ellipse([(16, 18), (48, 36)], fill=(20, 180, 160, 255), outline=(10, 90, 80, 255))
    draw.arc([(18, 19), (46, 30)], 180, 360, fill=(90, 240, 220, 255), width=2)
    # Glowing dots
    for dx, dy in [(24, 24), (32, 22), (40, 25), (28, 28), (36, 28)]:
        draw.ellipse([(dx-2, dy-2), (dx+2, dy+2)], fill=(210, 255, 245, 255))
    return img


def draw_water():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Glass flask with clear meltwater
    draw.rectangle([(28, 14), (36, 20)], fill=(180, 190, 200, 200), outline=(100, 110, 120, 255))
    draw.ellipse([(18, 22), (46, 50)], fill=(40, 110, 180, 230), outline=(160, 200, 240, 255))
    draw.ellipse([(20, 26), (44, 48)], fill=(60, 150, 230, 240))
    draw.arc([(22, 28), (42, 44)], 190, 270, fill=(220, 245, 255, 255), width=2)
    return img


def draw_lichen():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Fibrous subterranean moss/lichen root clump with rich natural tones
    dark_shadow = (35, 55, 30, 255)
    root_col = (85, 135, 75, 255)
    mid_green = (120, 175, 105, 255)
    tip_col = (175, 235, 145, 255)
    glow_col = (220, 255, 195, 255)

    # Clump base node
    draw.ellipse([(22, 14), (42, 24)], fill=dark_shadow)
    draw.ellipse([(24, 16), (40, 22)], fill=root_col)

    for i in range(8):
        rx = 18 + i * 4
        # Root shadows
        draw.line([(rx+1, 18), (rx - 3 + (i%3)*4, 46 + (i%2)*6)], fill=dark_shadow, width=3)
        # Main root vine
        draw.line([(rx, 18), (rx - 4 + (i%3)*4, 46 + (i%2)*6)], fill=root_col, width=2)
        # Highlight streak
        draw.line([(rx-1, 20), (rx - 4 + (i%3)*3, 38)], fill=mid_green, width=1)
        # Glowing nutrient berry tips
        draw.ellipse([(rx - 6 + (i%3)*4, 44 + (i%2)*6), (rx - 2 + (i%3)*4, 48 + (i%2)*6)], fill=tip_col)
        draw.point([(rx - 4 + (i%3)*4, 46 + (i%2)*6)], fill=glow_col)
    return img
    return img


# GENERATE ALL ICONS
print("Rendering 64x64 High-Res Isometric Voxel Blocks and Gear Icons...")

# 1. Blocks (3D Isometric Cubes)
blocks = {
    "cobblestone": ((135, 138, 142, 255), (100, 103, 108, 255), (75, 78, 82, 255), "cobble", None),
    "planks": ((195, 145, 95, 255), (155, 110, 70, 255), (115, 80, 50, 255), "planks", None),
    "timber": ((110, 75, 45, 255), (85, 55, 30, 255), (60, 40, 20, 255), "timber", None),
    "stone": ((145, 148, 152, 255), (115, 118, 122, 255), (85, 88, 92, 255), "plain", None),
    "deepslate": ((75, 78, 85, 255), (55, 58, 65, 255), (38, 40, 46, 255), "plain", None),
    "calcite": ((230, 235, 245, 255), (190, 200, 215, 255), (150, 160, 180, 255), "calcite", None),
    "magma": ((50, 35, 30, 255), (35, 25, 20, 255), (25, 15, 12, 255), "magma", None),
    "cargo_crate": ((160, 115, 75, 255), (125, 90, 55, 255), (95, 65, 40, 255), "crate", None),
    "coal": ((55, 55, 60, 255), (35, 35, 40, 255), (22, 22, 26, 255), "plain", None),
    "iron_ore": ((135, 138, 142, 255), (100, 103, 108, 255), (75, 78, 82, 255), "ore", (215, 175, 140, 255)),
    "copper_ore": ((135, 138, 142, 255), (100, 103, 108, 255), (75, 78, 82, 255), "ore", (220, 120, 70, 255)),
    "gold_ore": ((135, 138, 142, 255), (100, 103, 108, 255), (75, 78, 82, 255), "ore", (255, 215, 40, 255)),
    "phosphor_ore": ((75, 78, 85, 255), (55, 58, 65, 255), (38, 40, 46, 255), "ore", (30, 230, 200, 255)),
}

for name, (t, l, r, pat, ore) in blocks.items():
    img = create_isometric_block(t, l, r, pat, ore)
    img.save(f"{OUT_DIR}/icon_{name}.png")
    print(f" -> Saved icon_{name}.png (64x64)")

# 2. Items & Tools
items = {
    "pickaxe": draw_pickaxe(),
    "lantern": draw_lantern(),
    "torch": draw_torch(),
    "canteen": draw_canteen(),
    "rations": draw_rations(),
    "journal": draw_journal(),
    "mushroom": draw_mushroom(),
    "water": draw_water(),
    "lichen": draw_lichen(),
    "iron": draw_ingot((110, 120, 135, 255), (150, 160, 175, 255), (195, 205, 220, 255), (250, 255, 255, 255)),
    "copper": draw_ingot((130, 70, 40, 255), (180, 100, 55, 255), (225, 135, 80, 255), (255, 190, 140, 255)),
    "gold": draw_ingot((160, 120, 20, 255), (220, 170, 30, 255), (255, 215, 60, 255), (255, 255, 180, 255)),
    "phosphor": draw_crystal((20, 180, 160, 255), (40, 220, 195, 255), (180, 255, 240, 255)),
}

for name, img in items.items():
    img.save(f"{OUT_DIR}/icon_{name}.png")
    print(f" -> Saved icon_{name}.png (64x64)")

print("All 64x64 High-Res Isometric Block & Item Icons successfully generated!")
