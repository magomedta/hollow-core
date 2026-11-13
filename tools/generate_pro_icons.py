# hollow_core/tools/generate_pro_icons.py
# High-Definition 64x64 RGBA Professional Game Icon Generator
# Uses PIL with multi-pass shading, directional speculars, ambient occlusion, and alpha transparency
from PIL import Image, ImageDraw, ImageFilter
import math
import os

ICON_SIZE = 64

def create_base_canvas():
    return Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))

def apply_subtle_glow(img, color=(255, 200, 100, 40), radius=3):
    glow = img.copy()
    glow = glow.filter(ImageFilter.GaussianBlur(radius))
    res = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    res.paste(glow, (0, 0), glow)
    res.paste(img, (0, 0), img)
    return res

def draw_beveled_cube(draw, cx, cy, w, h, top_col, left_col, right_col, border_col):
    # Isometric cube projection
    hw = w * 0.5
    hh = h * 0.28
    ch = h * 0.44
    
    # Points
    top_p = (cx, cy - hh - ch*0.5)
    left_p = (cx - hw, cy - ch*0.5)
    right_p = (cx + hw, cy - ch*0.5)
    center_p = (cx, cy - ch*0.5 + hh)
    bot_left_p = (cx - hw, cy + ch*0.5)
    bot_right_p = (cx + hw, cy + ch*0.5)
    bot_p = (cx, cy + ch*0.5 + hh)
    
    # Top face
    draw.polygon([top_p, right_p, center_p, left_p], fill=top_col, outline=border_col)
    # Left face
    draw.polygon([left_p, center_p, bot_p, bot_left_p], fill=left_col, outline=border_col)
    # Right face
    draw.polygon([center_p, right_p, bot_right_p, bot_p], fill=right_col, outline=border_col)

# --- ICON GENERATORS ---

def make_icon_lantern():
    im = create_base_canvas()
    d = ImageDraw.Draw(im)
    
    # Drop shadow
    d.ellipse([14, 50, 50, 60], fill=(0, 0, 0, 90))
    
    # Brass base tank
    d.rounded_rectangle([18, 42, 46, 52], radius=3, fill=(195, 150, 60), outline=(130, 95, 30), width=1)
    d.line([19, 44, 45, 44], fill=(235, 195, 110)) # Top highlight
    
    # Glass chimney with glowing flame inside
    d.rectangle([21, 24, 43, 42], fill=(40, 48, 55, 180), outline=(90, 80, 60), width=1)
    
    # Warm flame core
    d.ellipse([27, 28, 37, 39], fill=(255, 230, 140))
    d.ellipse([29, 31, 35, 37], fill=(255, 255, 220))
    
    # Iron cage bars
    d.line([22, 24, 22, 42], fill=(60, 65, 70), width=2)
    d.line([42, 24, 42, 42], fill=(60, 65, 70), width=2)
    d.line([32, 24, 32, 42], fill=(90, 95, 100), width=1)
    
    # Tiered Brass Hood & Cap
    d.polygon([(16, 24), (48, 24), (42, 16), (22, 16)], fill=(195, 150, 60), outline=(130, 95, 30))
    d.rectangle([28, 12, 36, 16], fill=(160, 120, 45), outline=(110, 80, 25))
    
    # Suspension loop
    d.ellipse([27, 4, 37, 13], outline=(220, 180, 80), width=2)
    
    return apply_subtle_glow(im, (255, 190, 80, 60), 2)

def make_icon_pickaxe():
    im = create_base_canvas()
    d = ImageDraw.Draw(im)
    
    # Diagonal pickaxe: handle runs bottom-left to top-right
    # Handle wood
    d.line([12, 52, 42, 22], fill=(110, 75, 40), width=5)
    d.line([13, 51, 41, 23], fill=(155, 110, 65), width=3)
    
    # Leather grip wrap
    for i in range(5):
        ox = 14 + i * 4
        oy = 50 - i * 4
        d.line([ox - 2, oy + 2, ox + 2, oy - 2], fill=(65, 42, 25), width=2)
        
    # Brass pommel & collar
    d.ellipse([9, 50, 15, 56], fill=(210, 165, 65), outline=(130, 95, 30))
    d.ellipse([38, 21, 45, 28], fill=(210, 165, 65), outline=(130, 95, 30))
    
    # Forged Steel Pickaxe Head
    # Chisel beak (curves up and right)
    d.polygon([(36, 26), (46, 14), (58, 8), (48, 20)], fill=(180, 190, 200), outline=(80, 90, 100))
    d.line([(46, 14), (58, 8)], fill=(240, 245, 255), width=2) # Edge glint
    
    # Rear Adze blade (curves down and left)
    d.polygon([(36, 26), (28, 20), (16, 22), (28, 28)], fill=(140, 150, 160), outline=(70, 75, 85))
    
    # Center eye
    d.rectangle([34, 18, 42, 26], fill=(120, 130, 140), outline=(60, 65, 75))
    d.line([35, 19, 41, 19], fill=(220, 230, 240))
    
    return im

def make_icon_torch():
    im = create_base_canvas()
    d = ImageDraw.Draw(im)
    
    # Wooden shaft
    d.line([16, 52, 38, 26], fill=(100, 70, 35), width=6)
    d.line([17, 51, 37, 27], fill=(145, 105, 55), width=4)
    
    # Iron band
    d.line([32, 29, 39, 23], fill=(70, 75, 80), width=3)
    
    # Burning flame head
    d.polygon([(36, 24), (52, 12), (48, 8), (38, 14)], fill=(240, 120, 20))
    d.polygon([(38, 22), (50, 13), (46, 10), (40, 15)], fill=(255, 200, 40))
    d.polygon([(40, 20), (48, 14), (45, 12), (41, 16)], fill=(255, 255, 180))
    
    return apply_subtle_glow(im, (255, 160, 30, 80), 3)

def make_icon_timber():
    im = create_base_canvas()
    d = ImageDraw.Draw(im)
    draw_beveled_cube(d, 32, 32, 42, 40, (160, 115, 65), (115, 80, 42), (90, 60, 30), (60, 40, 20))
    # Tree rings on top
    d.ellipse([27, 16, 37, 24], outline=(130, 90, 50), width=1)
    d.ellipse([30, 18, 34, 22], fill=(110, 75, 40))
    return im

def make_icon_planks():
    im = create_base_canvas()
    d = ImageDraw.Draw(im)
    # 3 horizontal wooden planks
    for p in range(3):
        y = 12 + p * 14
        d.rounded_rectangle([10, y, 54, y + 11], radius=2, fill=(185, 135, 75), outline=(95, 65, 35), width=1)
        d.line([12, y + 2, 52, y + 2], fill=(215, 165, 105)) # top plank highlight
        d.line([12, y + 9, 52, y + 9], fill=(135, 95, 50)) # bottom plank shadow
        # Nail studs
        d.ellipse([14, y + 4, 16, y + 6], fill=(80, 85, 90))
        d.ellipse([48, y + 4, 50, y + 6], fill=(80, 85, 90))
    return im

def make_icon_cobblestone():
    im = create_base_canvas()
    d = ImageDraw.Draw(im)
    draw_beveled_cube(d, 32, 32, 42, 40, (160, 165, 170), (105, 110, 115), (75, 80, 85), (45, 50, 55))
    # Rock fractures
    d.line([24, 18, 36, 24], fill=(70, 75, 80), width=1)
    d.line([20, 28, 28, 38], fill=(50, 55, 60), width=1)
    d.line([38, 28, 44, 40], fill=(40, 45, 50), width=1)
    return im

def make_icon_iron_ore():
    im = create_base_canvas()
    d = ImageDraw.Draw(im)
    draw_beveled_cube(d, 32, 32, 42, 40, (110, 115, 120), (70, 75, 80), (50, 55, 60), (35, 40, 45))
    # Metallic raw iron flecks with specular glints
    iron_flecks = [(28, 18), (35, 22), (20, 32), (26, 42), (40, 34)]
    for fx, fy in iron_flecks:
        d.rounded_rectangle([fx, fy, fx + 5, fy + 4], radius=1, fill=(210, 175, 150), outline=(130, 95, 75))
        d.point((fx + 1, fy + 1), fill=(255, 235, 220))
    return im

def make_icon_gold_ore():
    im = create_base_canvas()
    d = ImageDraw.Draw(im)
    draw_beveled_cube(d, 32, 32, 42, 40, (85, 88, 92), (55, 58, 62), (38, 40, 44), (25, 28, 30))
    # Gleaming gold ore nuggets
    nuggets = [(27, 19), (34, 21), (18, 33), (25, 41), (41, 35)]
    for nx, ny in nuggets:
        d.rounded_rectangle([nx, ny, nx + 6, ny + 5], radius=2, fill=(255, 210, 40), outline=(170, 130, 20))
        d.point((nx + 1, ny + 1), fill=(255, 255, 200))
    return apply_subtle_glow(im, (255, 200, 30, 40), 2)

def make_icon_calcite():
    im = create_base_canvas()
    d = ImageDraw.Draw(im)
    # Prismatic calcite crystal cluster
    d.polygon([(32, 8), (42, 22), (38, 48), (26, 48), (22, 22)], fill=(230, 240, 248), outline=(150, 170, 190))
    d.polygon([(32, 8), (38, 48), (32, 50), (26, 48)], fill=(200, 215, 230))
    d.line([(32, 8), (32, 50)], fill=(255, 255, 255), width=2)
    # Secondary crystal left
    d.polygon([(20, 22), (28, 30), (24, 52), (16, 46)], fill=(185, 205, 225), outline=(120, 140, 160))
    # Secondary crystal right
    d.polygon([(44, 20), (48, 44), (38, 52), (36, 32)], fill=(170, 190, 215), outline=(110, 130, 150))
    return apply_subtle_glow(im, (180, 220, 255, 50), 2)

def make_icon_phosphor():
    im = create_base_canvas()
    d = ImageDraw.Draw(im)
    # Glowing teal phosphor gem
    d.polygon([(32, 8), (50, 24), (42, 54), (22, 54), (14, 24)], fill=(40, 220, 190), outline=(15, 120, 100))
    d.polygon([(32, 8), (42, 54), (22, 54)], fill=(80, 245, 215))
    d.polygon([(32, 14), (40, 26), (36, 46), (28, 46), (24, 26)], fill=(180, 255, 240))
    return apply_subtle_glow(im, (30, 240, 200, 100), 3)

def make_icon_water():
    im = create_base_canvas()
    d = ImageDraw.Draw(im)
    # Glass flask filled with pure crystal meltwater
    d.ellipse([16, 48, 48, 58], fill=(0, 0, 0, 70)) # drop shadow
    # Flask bottle body
    d.ellipse([16, 24, 48, 54], fill=(45, 55, 65, 180), outline=(130, 155, 175), width=1)
    # Water level inside
    d.ellipse([19, 32, 45, 51], fill=(70, 145, 185, 220))
    d.ellipse([21, 31, 43, 38], fill=(120, 195, 230))
    # Neck and Cork
    d.rectangle([28, 14, 36, 26], fill=(60, 75, 85, 200), outline=(130, 155, 175))
    d.rounded_rectangle([27, 8, 37, 15], radius=2, fill=(160, 115, 65), outline=(100, 70, 35))
    # Specular glass reflection
    d.arc([20, 27, 44, 49], 190, 260, fill=(255, 255, 255, 220), width=2)
    return apply_subtle_glow(im, (80, 180, 230, 60), 2)

def make_icon_canteen():
    im = create_base_canvas()
    d = ImageDraw.Draw(im)
    # Heavy surveyor steel flask
    d.rounded_rectangle([18, 18, 46, 54], radius=8, fill=(140, 150, 155), outline=(75, 80, 85), width=2)
    d.line([22, 22, 22, 50], fill=(210, 220, 225), width=2) # highlight
    # Leather harness band
    d.rectangle([18, 32, 46, 40], fill=(110, 75, 45), outline=(65, 40, 20))
    d.ellipse([30, 34, 34, 38], fill=(210, 170, 65)) # Brass badge
    # Screw cap
    d.rectangle([28, 10, 36, 18], fill=(95, 105, 110), outline=(55, 60, 65))
    return im

def make_icon_rations():
    im = create_base_canvas()
    d = ImageDraw.Draw(im)
    # Military survival ration tin
    draw_beveled_cube(d, 32, 34, 44, 32, (155, 130, 80), (105, 85, 50), (75, 60, 35), (45, 35, 20))
    # Red cross / ration marking
    d.line([30, 20, 34, 20], fill=(220, 50, 40), width=2)
    d.line([32, 18, 32, 22], fill=(220, 50, 40), width=2)
    return im

def make_icon_mushroom():
    im = create_base_canvas()
    d = ImageDraw.Draw(im)
    # Bioluminescent cave mushroom
    d.ellipse([20, 52, 44, 58], fill=(0, 0, 0, 80)) # shadow
    # Slender stalk
    d.polygon([(29, 32), (35, 32), (36, 54), (28, 54)], fill=(180, 210, 220), outline=(100, 130, 140))
    # Glowing cap
    d.chord([12, 14, 52, 38], 180, 360, fill=(35, 160, 215), outline=(15, 90, 130))
    d.ellipse([14, 24, 50, 38], fill=(60, 195, 245), outline=(20, 110, 150))
    # Glowing spore dots
    for dot in [(24, 18), (32, 16), (40, 19), (28, 24), (36, 23)]:
        d.ellipse([dot[0], dot[1], dot[0] + 3, dot[1] + 3], fill=(210, 255, 255))
    return apply_subtle_glow(im, (30, 190, 240, 90), 3)

def make_icon_crate():
    im = create_base_canvas()
    d = ImageDraw.Draw(im)
    draw_beveled_cube(d, 32, 32, 42, 40, (175, 125, 70), (120, 85, 45), (85, 60, 30), (55, 35, 18))
    # Iron corner brackets
    d.rectangle([11, 24, 16, 29], fill=(50, 55, 60))
    d.rectangle([48, 24, 53, 29], fill=(50, 55, 60))
    d.rectangle([29, 44, 35, 49], fill=(50, 55, 60))
    return im

def make_icon_slate_brick():
    im = create_base_canvas()
    d = ImageDraw.Draw(im)
    draw_beveled_cube(d, 32, 32, 42, 40, (75, 80, 90), (48, 52, 60), (32, 35, 42), (20, 22, 28))
    # Glowing precursor runic glyph
    d.line([26, 20, 38, 20], fill=(255, 180, 40), width=1)
    d.line([32, 17, 32, 23], fill=(255, 180, 40), width=1)
    d.line([22, 32, 22, 42], fill=(255, 180, 40), width=1)
    d.line([42, 32, 42, 42], fill=(255, 180, 40), width=1)
    return apply_subtle_glow(im, (255, 180, 40, 40), 2)

def make_icon_bedrock():
    im = create_base_canvas()
    d = ImageDraw.Draw(im)
    draw_beveled_cube(d, 32, 32, 42, 40, (40, 42, 46), (24, 25, 28), (14, 15, 18), (8, 9, 10))
    d.line([18, 30, 28, 42], fill=(12, 13, 15), width=2)
    d.line([36, 28, 44, 38], fill=(12, 13, 15), width=2)
    return im

ICONS = {
    "icon_lantern.png": make_icon_lantern,
    "icon_pickaxe.png": make_icon_pickaxe,
    "icon_torch.png": make_icon_torch,
    "icon_timber.png": make_icon_timber,
    "icon_planks.png": make_icon_planks,
    "icon_cobblestone.png": make_icon_cobblestone,
    "icon_iron_ore.png": make_icon_iron_ore,
    "icon_gold_ore.png": make_icon_gold_ore,
    "icon_copper_ore.png": make_icon_iron_ore, # Shared palette with bronze
    "icon_calcite.png": make_icon_calcite,
    "icon_phosphor.png": make_icon_phosphor,
    "icon_water.png": make_icon_water,
    "icon_canteen.png": make_icon_canteen,
    "icon_rations.png": make_icon_rations,
    "icon_mushroom.png": make_icon_mushroom,
    "icon_crate.png": make_icon_crate,
    "icon_slate_brick.png": make_icon_slate_brick,
    "icon_bedrock.png": make_icon_bedrock,
}

if __name__ == "__main__":
    tex_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "textures"))
    os.makedirs(tex_dir, exist_ok=True)
    print(f"[IconGenerator] Generating {len(ICONS)} high-definition 64x64 item icons into: {tex_dir}")
    for filename, gen_func in ICONS.items():
        out_path = os.path.join(tex_dir, filename)
        img = gen_func()
        img.save(out_path, "PNG")
        print(f" -> Generated {filename} ({img.size[0]}x{img.size[1]} RGBA)")
    print("[IconGenerator] All HD icons generated successfully.")
