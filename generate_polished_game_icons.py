# generate_polished_game_icons.py
# High-Fidelity Game-Developer Item Icon Generator for Hollow Core
# Renders 128x128 antialiased vector/PBR icons with rich shading and downsamples to 32x32 via Lanczos.

import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT_DIR = r"c:\Users\magom\Downloads\twitchst\hollow_core\textures"
os.makedirs(OUT_DIR, exist_ok=True)

CANVAS_SIZE = 128

def new_canvas():
    return Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))

def finalize_and_save(img, name):
    # Downsample using high-quality Lanczos antialiasing to crisp 32x32
    icon_32 = img.resize((32, 32), Image.Resampling.LANCZOS)
    out_path = os.path.join(OUT_DIR, f"icon_{name}.png")
    icon_32.save(out_path, "PNG")
    print(f"Generated polished icon_{name}.png (32x32)")

# 1. Prospector Pickaxe
def draw_pickaxe():
    im = new_canvas()
    draw = ImageDraw.Draw(im)
    
    # Handle: Dark ash wood with leather wrap (from (24, 104) to (76, 52))
    # Soft drop shadow
    draw.line([(27, 107), (79, 55)], fill=(15, 12, 10, 140), width=9)
    draw.line([(25, 105), (77, 53)], fill=(55, 38, 26, 255), width=7)
    draw.line([(24, 104), (76, 52)], fill=(110, 80, 55, 255), width=5)
    draw.line([(23, 103), (75, 51)], fill=(160, 125, 90, 255), width=2) # top highlight
    
    # Leather grip wrap lines
    for i in range(5):
        wx = 32 + i * 7
        wy = 96 - i * 7
        draw.line([(wx - 3, wy + 3), (wx + 3, wy - 3)], fill=(40, 25, 15, 255), width=2)
        
    # Brass ferrule / collar ring
    draw.polygon([(71, 57), (81, 47), (86, 52), (76, 62)], fill=(215, 168, 50, 255))
    draw.line([(72, 56), (82, 46)], fill=(255, 220, 110, 255), width=2)
    
    # Pick Head: Curved forged steel mattock with bevels
    head_poly = [
        (42, 22), (54, 25), (78, 38), (88, 44), (96, 56), (108, 76),
        (105, 78), (92, 60), (84, 52), (74, 46), (58, 36), (42, 28)
    ]
    # Drop shadow
    shadow_poly = [(x + 3, y + 3) for x, y in head_poly]
    draw.polygon(shadow_poly, fill=(10, 12, 16, 120))
    # Base dark steel
    draw.polygon(head_poly, fill=(65, 72, 85, 255))
    
    # Upper chamfer highlight
    top_bevel = [(42, 22), (54, 25), (78, 38), (88, 44), (96, 56), (108, 76)]
    draw.line(top_bevel, fill=(210, 222, 240, 255), width=3)
    # Razor pick tip specular flare
    draw.ellipse([(39, 19), (45, 25)], fill=(255, 255, 255, 255))
    draw.ellipse([(105, 73), (111, 79)], fill=(240, 245, 255, 255))
    
    finalize_and_save(im, "pickaxe")

# 2. Expedition Brass Lantern
def draw_lantern():
    im = new_canvas()
    draw = ImageDraw.Draw(im)
    
    # Top suspension loop
    draw.ellipse([(52, 12), (76, 36)], outline=(20, 15, 8, 140), width=6)
    draw.ellipse([(52, 12), (76, 36)], outline=(190, 145, 45, 255), width=5)
    draw.ellipse([(54, 14), (74, 34)], outline=(245, 210, 95, 255), width=2)
    
    # Top brass dome
    draw.chord([(42, 30), (86, 60)], 180, 360, fill=(185, 140, 40, 255), outline=(75, 52, 15, 255))
    draw.line([(44, 45), (84, 45)], fill=(250, 215, 110, 255), width=3)
    
    # Glass chamber with glowing kerosene mantle flame
    draw.rectangle([(44, 48), (84, 96)], fill=(30, 45, 60, 200), outline=(120, 90, 30, 255), width=3)
    
    # Inner flame glow
    flame_glow = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    fg_draw = ImageDraw.Draw(flame_glow)
    fg_draw.ellipse([(52, 60), (76, 88)], fill=(255, 180, 40, 230))
    fg_draw.ellipse([(58, 66), (70, 82)], fill=(255, 245, 180, 255))
    flame_glow = flame_glow.filter(ImageFilter.GaussianBlur(3))
    im.alpha_composite(flame_glow)
    
    # Outer brass protective cage bars
    draw.line([(45, 48), (45, 96)], fill=(215, 170, 50, 255), width=3)
    draw.line([(57, 48), (57, 96)], fill=(185, 140, 40, 255), width=2)
    draw.line([(71, 48), (71, 96)], fill=(185, 140, 40, 255), width=2)
    draw.line([(83, 48), (83, 96)], fill=(245, 205, 90, 255), width=3)
    
    # Base pedestal
    draw.rectangle([(38, 96), (90, 112)], fill=(165, 120, 35, 255), outline=(60, 42, 12, 255), width=2)
    draw.line([(40, 98), (88, 98)], fill=(245, 210, 95, 255), width=2)
    
    finalize_and_save(im, "lantern")

# 3. Carbide Wall Torch
def draw_torch():
    im = new_canvas()
    draw = ImageDraw.Draw(im)
    
    # Wood Stake shaft from (48, 64) to (64, 118)
    draw.line([(52, 66), (68, 120)], fill=(15, 12, 10, 130), width=9)
    draw.line([(50, 64), (66, 118)], fill=(85, 60, 40, 255), width=8)
    draw.line([(49, 64), (65, 118)], fill=(145, 105, 75, 255), width=2)
    
    # Iron mounting bracket
    draw.rectangle([(44, 60), (58, 72)], fill=(75, 82, 92, 255), outline=(40, 45, 52, 255), width=2)
    draw.line([(45, 61), (57, 61)], fill=(170, 185, 205, 255), width=2)
    
    # Blazing Torch Flame (Tear-drop combustion gradient)
    flame_layer = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    flame_draw = ImageDraw.Draw(flame_layer)
    flame_draw.polygon([(46, 62), (32, 42), (40, 22), (52, 10), (62, 22), (68, 44), (54, 62)], fill=(255, 95, 15, 240))
    flame_draw.polygon([(47, 58), (38, 42), (44, 28), (52, 18), (58, 30), (62, 44), (52, 58)], fill=(255, 185, 30, 255))
    flame_draw.ellipse([(46, 36), (56, 52)], fill=(255, 250, 190, 255))
    flame_layer = flame_layer.filter(ImageFilter.GaussianBlur(1.8))
    im.alpha_composite(flame_layer)
    
    finalize_and_save(im, "torch")

# 4. Hewn Timber Beam
def draw_timber():
    im = new_canvas()
    draw = ImageDraw.Draw(im)
    
    # Isometric Timber Beam
    # Top face
    draw.polygon([(36, 42), (64, 26), (92, 42), (64, 58)], fill=(140, 102, 68, 255), outline=(55, 38, 24, 255), width=2)
    # Left face
    draw.polygon([(36, 42), (64, 58), (64, 98), (36, 82)], fill=(95, 68, 45, 255), outline=(45, 30, 18, 255), width=2)
    # Right face
    draw.polygon([(64, 58), (92, 42), (92, 82), (64, 98)], fill=(65, 46, 30, 255), outline=(35, 22, 12, 255), width=2)
    
    # Annual growth rings on end face
    draw.ellipse([(52, 36), (76, 48)], outline=(115, 82, 54, 255), width=2)
    draw.ellipse([(58, 39), (70, 45)], outline=(95, 68, 45, 255), width=2)
    
    # Edge highlights
    draw.line([(64, 26), (92, 42), (64, 58), (36, 42)], fill=(185, 142, 98, 255), width=2)
    
    finalize_and_save(im, "timber")

# 5. Wooden Planks
def draw_planks():
    im = new_canvas()
    draw = ImageDraw.Draw(im)
    
    # Stack of two smooth finished cedar planks
    for p_idx, y_off in enumerate([54, 28]):
        # Top face
        draw.polygon([(28, y_off + 16), (64, y_off), (100, y_off + 16), (64, y_off + 32)], fill=(168, 125, 82, 255), outline=(60, 42, 25, 255), width=2)
        # Front-left face
        draw.polygon([(28, y_off + 16), (64, y_off + 32), (64, y_off + 44), (28, y_off + 28)], fill=(125, 90, 56, 255), outline=(45, 30, 18, 255), width=2)
        # Front-right face
        draw.polygon([(64, y_off + 32), (100, y_off + 16), (100, y_off + 28), (64, y_off + 44)], fill=(90, 62, 38, 255), outline=(35, 22, 12, 255), width=2)
        # Edge highlight
        draw.line([(28, y_off + 16), (64, y_off), (100, y_off + 16)], fill=(215, 172, 120, 255), width=2)
        # Rivet nails
        draw.ellipse([(44, y_off + 16), (48, y_off + 20)], fill=(50, 55, 62, 255))
        draw.ellipse([(80, y_off + 16), (84, y_off + 20)], fill=(50, 55, 62, 255))
        
    finalize_and_save(im, "planks")

# 6. Cavern Cobblestone
def draw_cobblestone():
    im = new_canvas()
    draw = ImageDraw.Draw(im)
    
    # Chiseled Basalt Block with 3D faceted faces
    # Drop shadow
    draw.polygon([(36, 46), (64, 30), (96, 46), (64, 106)], fill=(12, 14, 18, 130))
    # Top face
    draw.polygon([(32, 42), (64, 24), (96, 42), (64, 60)], fill=(120, 128, 138, 255), outline=(42, 46, 52, 255), width=2)
    # Left face
    draw.polygon([(32, 42), (64, 60), (64, 102), (32, 84)], fill=(85, 92, 102, 255), outline=(35, 38, 44, 255), width=2)
    # Right face
    draw.polygon([(64, 60), (96, 42), (96, 84), (64, 102)], fill=(55, 60, 68, 255), outline=(28, 30, 36, 255), width=2)
    
    # Internal fractures and mineral speckles
    draw.line([(48, 52), (58, 76)], fill=(30, 34, 40, 255), width=2)
    draw.line([(58, 76), (54, 92)], fill=(30, 34, 40, 255), width=2)
    draw.line([(72, 68), (86, 74)], fill=(25, 28, 34, 255), width=2)
    
    # Top specular rim
    draw.line([(32, 42), (64, 24), (96, 42)], fill=(185, 195, 210, 255), width=2)
    finalize_and_save(im, "cobblestone")

# 7. Field Surveyor Canteen
def draw_canteen():
    im = new_canvas()
    draw = ImageDraw.Draw(im)
    
    # Flask Body (rounded brushed brass / copper flask)
    # Drop shadow
    draw.ellipse([(36, 36), (92, 104)], fill=(10, 12, 15, 120))
    # Flask main body
    draw.ellipse([(34, 34), (90, 102)], fill=(185, 135, 45, 255), outline=(70, 50, 15, 255), width=3)
    # Specular curvature reflection
    draw.arc([(38, 38), (86, 98)], 200, 320, fill=(245, 215, 110, 255), width=3)
    
    # Leather retention harness band crossing center
    draw.line([(36, 68), (88, 68)], fill=(65, 42, 25, 255), width=6)
    draw.line([(36, 67), (88, 67)], fill=(110, 75, 45, 255), width=2)
    
    # Knurled brass screw cap on top
    draw.rectangle([(54, 18), (70, 34)], fill=(210, 165, 55, 255), outline=(75, 52, 15, 255), width=2)
    draw.line([(55, 20), (69, 20)], fill=(255, 230, 130, 255), width=2)
    
    finalize_and_save(im, "canteen")

# 8. Expedition Sealed Rations
def draw_rations():
    im = new_canvas()
    draw = ImageDraw.Draw(im)
    
    # Tin Ration Canister (oval / cylindrical sealed tin)
    draw.ellipse([(36, 32), (92, 58)], fill=(145, 152, 160, 255), outline=(50, 55, 62, 255), width=2)
    draw.rectangle([(36, 45), (92, 88)], fill=(115, 122, 130, 255), outline=(45, 50, 56, 255), width=2)
    draw.ellipse([(36, 75), (92, 101)], fill=(90, 96, 105, 255), outline=(40, 44, 50, 255), width=2)
    
    # Key pull-tab ring on lid
    draw.ellipse([(54, 40), (66, 50)], outline=(220, 228, 240, 255), width=2)
    draw.line([(66, 45), (74, 45)], fill=(220, 228, 240, 255), width=2)
    
    # Top specular rim
    draw.arc([(38, 34), (90, 56)], 180, 360, fill=(235, 242, 252, 255), width=2)
    
    finalize_and_save(im, "rations")

# 9. Optical Calcite Geode Prism
def draw_calcite():
    im = new_canvas()
    draw = ImageDraw.Draw(im)
    
    # Rhombohedral optical calcite crystal prism
    # Drop shadow
    draw.polygon([(42, 26), (88, 34), (98, 76), (52, 106), (32, 66)], fill=(10, 15, 22, 130))
    # Top face
    draw.polygon([(40, 24), (86, 32), (64, 58), (28, 50)], fill=(235, 245, 255, 240), outline=(150, 180, 210, 255), width=2)
    # Front-left face
    draw.polygon([(28, 50), (64, 58), (52, 102), (18, 92)], fill=(195, 215, 235, 220), outline=(130, 160, 190, 255), width=2)
    # Front-right face
    draw.polygon([(64, 58), (86, 32), (96, 74), (52, 102)], fill=(160, 190, 220, 220), outline=(110, 140, 175, 255), width=2)
    
    # Internal rainbow birefringence / cleavage planes
    draw.line([(34, 48), (72, 78)], fill=(180, 230, 255, 200), width=2)
    draw.line([(48, 36), (82, 64)], fill=(255, 220, 240, 180), width=2)
    
    # Specular corner glint
    draw.ellipse([(61, 55), (67, 61)], fill=(255, 255, 255, 255))
    finalize_and_save(im, "calcite")

# 10. Bioluminescent Phosphor Shard
def draw_phosphor():
    im = new_canvas()
    
    # Ambient cyan glow aura
    glow_layer = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(glow_layer)
    g_draw.ellipse([(32, 24), (96, 104)], fill=(25, 220, 240, 140))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(8))
    im.alpha_composite(glow_layer)
    
    draw = ImageDraw.Draw(im)
    # Sharp faceted crystalline phosphor crystal
    poly_front = [(64, 16), (88, 52), (76, 108), (52, 112), (38, 64)]
    draw.polygon(poly_front, fill=(40, 210, 225, 240), outline=(120, 245, 255, 255), width=2)
    
    # Inner facets
    draw.polygon([(64, 16), (88, 52), (64, 76)], fill=(80, 235, 245, 255))
    draw.polygon([(64, 16), (38, 64), (64, 76)], fill=(30, 180, 200, 255))
    draw.polygon([(64, 76), (88, 52), (76, 108)], fill=(20, 160, 180, 255))
    draw.polygon([(64, 76), (38, 64), (52, 112)], fill=(50, 220, 235, 255))
    
    # Core specular glint
    draw.ellipse([(61, 73), (67, 79)], fill=(255, 255, 255, 255))
    finalize_and_save(im, "phosphor")

# 11. Forged Iron Ingot
def draw_iron():
    im = new_canvas()
    draw = ImageDraw.Draw(im)
    
    # Heavy Pig-Iron Bullion Ingot
    # Drop shadow
    draw.polygon([(28, 48), (64, 30), (104, 48), (64, 106)], fill=(10, 12, 16, 140))
    # Top face
    draw.polygon([(36, 42), (64, 28), (92, 42), (64, 56)], fill=(155, 165, 178, 255), outline=(55, 62, 72, 255), width=2)
    # Left face
    draw.polygon([(26, 72), (36, 42), (64, 56), (56, 92)], fill=(110, 118, 130, 255), outline=(45, 52, 60, 255), width=2)
    # Right face
    draw.polygon([(64, 56), (92, 42), (102, 72), (74, 92)], fill=(80, 88, 98, 255), outline=(35, 40, 48, 255), width=2)
    # Front face
    draw.polygon([(26, 72), (56, 92), (74, 92), (102, 72), (64, 56)], fill=(130, 140, 152, 255), outline=(50, 56, 65, 255), width=2)
    
    # Stamped Foundry Mark on top
    draw.rectangle([(56, 38), (72, 46)], fill=(90, 98, 108, 255))
    # Bevel highlight
    draw.line([(36, 42), (64, 28), (92, 42)], fill=(225, 235, 248, 255), width=3)
    
    finalize_and_save(im, "iron")

# 12. Abyssal Gold Ingot
def draw_gold():
    im = new_canvas()
    draw = ImageDraw.Draw(im)
    
    # Gleaming Subterranean Gold Bar
    # Drop shadow
    draw.polygon([(28, 48), (64, 30), (104, 48), (64, 106)], fill=(15, 12, 5, 140))
    # Top face
    draw.polygon([(36, 42), (64, 28), (92, 42), (64, 56)], fill=(255, 218, 75, 255), outline=(130, 95, 15, 255), width=2)
    # Left face
    draw.polygon([(26, 72), (36, 42), (64, 56), (56, 92)], fill=(215, 170, 40, 255), outline=(105, 75, 12, 255), width=2)
    # Right face
    draw.polygon([(64, 56), (92, 42), (102, 72), (74, 92)], fill=(165, 120, 25, 255), outline=(85, 58, 8, 255), width=2)
    # Front face
    draw.polygon([(26, 72), (56, 92), (74, 92), (102, 72), (64, 56)], fill=(235, 192, 55, 255), outline=(115, 82, 14, 255), width=2)
    
    # Specular rim flare
    draw.line([(36, 42), (64, 28), (92, 42)], fill=(255, 250, 185, 255), width=3)
    draw.ellipse([(60, 26), (68, 32)], fill=(255, 255, 240, 255))
    
    finalize_and_save(im, "gold")

# 13. Surveyor Leather Journal
def draw_journal():
    im = new_canvas()
    draw = ImageDraw.Draw(im)
    
    # Leather Logbook cover
    draw.polygon([(32, 28), (88, 22), (98, 92), (40, 102)], fill=(75, 45, 25, 255), outline=(35, 20, 10, 255), width=2)
    # Page block edges (aged cream paper)
    draw.polygon([(40, 102), (98, 92), (102, 98), (44, 108)], fill=(235, 225, 195, 255), outline=(60, 45, 25, 255), width=1)
    
    # Brass corner clasps
    draw.polygon([(32, 28), (46, 27), (34, 42)], fill=(225, 180, 50, 255))
    draw.polygon([(40, 102), (54, 100), (42, 88)], fill=(225, 180, 50, 255))
    
    # Red satin bookmark ribbon
    draw.polygon([(64, 24), (68, 24), (66, 114), (60, 110)], fill=(195, 35, 30, 255))
    
    finalize_and_save(im, "journal")

# 14. Bioluminescent Mycena Mushroom
def draw_mushroom():
    im = new_canvas()
    draw = ImageDraw.Draw(im)
    
    # Stipe (stalk)
    draw.line([(64, 52), (62, 108)], fill=(18, 24, 30, 120), width=9)
    draw.line([(64, 52), (62, 108)], fill=(160, 215, 235, 255), width=7)
    draw.line([(63, 52), (61, 108)], fill=(230, 250, 255, 255), width=2)
    
    # Bioluminescent Cap (domed mushroom umbrella)
    cap_poly = [(32, 60), (44, 32), (64, 20), (84, 32), (96, 60), (64, 66)]
    # Glow layer
    g_layer = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(g_layer)
    g_draw.polygon(cap_poly, fill=(35, 190, 245, 220))
    g_layer = g_layer.filter(ImageFilter.GaussianBlur(5))
    im.alpha_composite(g_layer)
    
    draw.polygon(cap_poly, fill=(30, 160, 220, 255), outline=(120, 235, 255, 255), width=2)
    # Bioluminescent gill rim
    draw.arc([(32, 48), (96, 68)], 0, 180, fill=(180, 245, 255, 255), width=3)
    # Glowing spore dots
    for (sx, sy) in [(52, 34), (68, 30), (58, 44), (76, 46)]:
        draw.ellipse([(sx - 2, sy - 2), (sx + 2, sy + 2)], fill=(255, 255, 255, 255))
        
    finalize_and_save(im, "mushroom")

# 15. Pure Glacial Meltwater Flask
def draw_water():
    im = new_canvas()
    draw = ImageDraw.Draw(im)
    
    # Round bottom laboratory glass flask
    # Water fluid inside
    draw.ellipse([(38, 46), (90, 98)], fill=(45, 145, 225, 200))
    draw.chord([(38, 46), (90, 98)], 0, 180, fill=(25, 115, 195, 240))
    
    # Glass flask outline
    draw.ellipse([(36, 44), (92, 100)], outline=(180, 220, 245, 255), width=3)
    # Flask neck
    draw.rectangle([(56, 18), (72, 48)], fill=(120, 180, 225, 80), outline=(180, 220, 245, 255), width=3)
    draw.ellipse([(52, 15), (76, 21)], fill=(210, 235, 255, 255))
    
    # Meniscus and specular liquid arc
    draw.arc([(42, 54), (86, 74)], 0, 180, fill=(230, 250, 255, 255), width=3)
    draw.ellipse([(44, 58), (50, 68)], fill=(255, 255, 255, 255))
    
    finalize_and_save(im, "water")

# 16. Subterranean Lichen Roots
def draw_lichen():
    im = new_canvas()
    draw = ImageDraw.Draw(im)
    
    # Tangled fibrous edible taproots (organic branching curves)
    draw.line([(64, 18), (62, 54), (54, 82), (48, 112)], fill=(95, 75, 45, 255), width=5)
    draw.line([(62, 54), (74, 86), (82, 116)], fill=(85, 68, 40, 255), width=4)
    draw.line([(54, 82), (64, 104)], fill=(110, 88, 52, 255), width=3)
    draw.line([(62, 38), (44, 68), (38, 96)], fill=(80, 62, 36, 255), width=3)
    
    # Pale green edible nodules / tips
    for (nx, ny) in [(48, 112), (82, 116), (64, 104), (38, 96), (56, 84)]:
        draw.ellipse([(nx - 4, ny - 4), (nx + 4, ny + 4)], fill=(125, 175, 85, 255), outline=(60, 95, 40, 255))
        draw.point((nx, ny), fill=(210, 245, 170, 255))
        
    finalize_and_save(im, "lichen")

# 17. Raw Copper Ingot
def draw_copper():
    im = new_canvas()
    draw = ImageDraw.Draw(im)
    
    # Reddish-Bronze Ingot with oxidized patina accents
    # Drop shadow
    draw.polygon([(28, 48), (64, 30), (104, 48), (64, 106)], fill=(15, 10, 8, 140))
    # Top face
    draw.polygon([(36, 42), (64, 28), (92, 42), (64, 56)], fill=(215, 115, 70, 255), outline=(110, 50, 25, 255), width=2)
    # Left face
    draw.polygon([(26, 72), (36, 42), (64, 56), (56, 92)], fill=(175, 85, 45, 255), outline=(90, 40, 18, 255), width=2)
    # Right face
    draw.polygon([(64, 56), (92, 42), (102, 72), (74, 92)], fill=(135, 62, 32, 255), outline=(70, 30, 12, 255), width=2)
    # Front face
    draw.polygon([(26, 72), (56, 92), (74, 92), (102, 72), (64, 56)], fill=(195, 98, 55, 255), outline=(100, 45, 20, 255), width=2)
    
    # Verdigris green oxidized patina
    draw.line([(56, 40), (66, 34)], fill=(65, 170, 130, 255), width=3)
    # Specular rim
    draw.line([(36, 42), (64, 28), (92, 42)], fill=(255, 185, 145, 255), width=3)
    
    finalize_and_save(im, "copper")

# 18. Anthracite Coal Lump
def draw_coal():
    im = new_canvas()
    draw = ImageDraw.Draw(im)
    
    # Chiseled Anthracite lump with conchoidal glass-like fractures
    poly_coal = [(32, 54), (46, 30), (74, 24), (96, 44), (98, 76), (78, 102), (48, 104), (28, 80)]
    draw.polygon([(x + 4, y + 4) for x, y in poly_coal], fill=(8, 10, 12, 140))
    draw.polygon(poly_coal, fill=(38, 42, 48, 255), outline=(15, 18, 22, 255), width=2)
    
    # Facets
    draw.polygon([(32, 54), (46, 30), (66, 58)], fill=(55, 60, 68, 255))
    draw.polygon([(46, 30), (74, 24), (82, 54), (66, 58)], fill=(45, 50, 56, 255))
    draw.polygon([(74, 24), (96, 44), (82, 54)], fill=(65, 72, 82, 255))
    draw.polygon([(66, 58), (82, 54), (98, 76), (72, 82)], fill=(28, 32, 36, 255))
    draw.polygon([(32, 54), (66, 58), (72, 82), (48, 104), (28, 80)], fill=(42, 46, 52, 255))
    
    # Obsidian vitreous sheen lines
    draw.line([(46, 30), (66, 58)], fill=(160, 175, 195, 255), width=2)
    draw.line([(74, 24), (96, 44)], fill=(185, 198, 220, 255), width=2)
    draw.ellipse([(64, 56), (68, 60)], fill=(255, 255, 255, 255))
    
    finalize_and_save(im, "coal")

if __name__ == "__main__":
    print("=== GENERATING PROFESSIONAL GAME-DEVELOPER ITEM ICONS ===")
    draw_pickaxe()
    draw_lantern()
    draw_torch()
    draw_timber()
    draw_planks()
    draw_cobblestone()
    draw_canteen()
    draw_rations()
    draw_calcite()
    draw_phosphor()
    draw_iron()
    draw_gold()
    draw_journal()
    draw_mushroom()
    draw_water()
    draw_lichen()
    draw_copper()
    draw_coal()
    print("=== ALL 18 ICONS GENERATED SUCCESSFULLY ===")
