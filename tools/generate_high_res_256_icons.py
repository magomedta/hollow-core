import os
import math
from PIL import Image, ImageDraw, ImageFilter

OUT_DIR = "hollow_core/textures"
os.makedirs(OUT_DIR, exist_ok=True)

SIZE = 256

def scale_pt(x, y):
    """Scales from 64-grid to 256-grid."""
    return (x * 4, y * 4)

def scale_pts(pts):
    return [scale_pt(x, y) for (x, y) in pts]

def create_isometric_block(top_col, left_col, right_col, pattern="plain", ore_col=None):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Isometric vertices for 256x256 bounding box
    # Center vertex: (128, 128)
    # Top vertex: (128, 32)
    # Top-Right: (224, 80)
    # Top-Left: (32, 80)
    # Bottom-Right: (224, 176)
    # Bottom-Left: (32, 176)
    # Bottom vertex: (128, 224)

    # Ambient drop shadow underneath
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    s_pts = [(128, 140), (230, 185), (128, 240), (26, 185)]
    sdraw.polygon(s_pts, fill=(0, 0, 0, 110))
    shadow = shadow.filter(ImageFilter.GaussianBlur(10))
    img.alpha_composite(shadow)

    # Outer dark chamfer silhouette
    offset_pts = [
        (128, 26), (230, 77), (230, 182), (128, 234), (26, 182), (26, 77)
    ]
    draw.polygon(offset_pts, fill=(15, 18, 22, 255))

    # Top Face (Illuminated from above)
    top_pts = [(128, 32), (224, 80), (128, 128), (32, 80)]
    draw.polygon(top_pts, fill=top_col)

    # Left Face (Medium shade)
    left_pts = [(32, 80), (128, 128), (128, 224), (32, 176)]
    draw.polygon(left_pts, fill=left_col)

    # Right Face (Shadowed)
    right_pts = [(128, 128), (224, 80), (224, 176), (128, 224)]
    draw.polygon(right_pts, fill=right_col)

    # High-detail pattern passes
    if pattern == "planks":
        # Horizontal timber planks with wood grain and dark chamfers
        for py in [48, 64, 80, 96, 112]:
            t1 = (128 + int((py - 32) * 1.0), py)
            t0 = (128 - int((py - 32) * 1.0), py)
        # Top face plank seams
        draw.line([(80, 56), (176, 104)], fill=(int(top_col[0]*0.72), int(top_col[1]*0.72), int(top_col[2]*0.72)), width=3)
        draw.line([(48, 72), (144, 120)], fill=(int(top_col[0]*0.72), int(top_col[1]*0.72), int(top_col[2]*0.72)), width=3)
        # Left face planks
        for ly in [112, 144, 176]:
            draw.line([(32, ly-32), (128, ly+16)], fill=(int(left_col[0]*0.70), int(left_col[1]*0.70), int(left_col[2]*0.70)), width=3)
        # Right face planks
        for ry in [112, 144, 176]:
            draw.line([(128, ry+16), (224, ry-32)], fill=(int(right_col[0]*0.70), int(right_col[1]*0.70), int(right_col[2]*0.70)), width=3)
        # Brass nail studs
        for nx, ny in [(48, 102), (116, 138), (140, 138), (208, 102), (48, 134), (116, 170), (140, 170), (208, 134)]:
            draw.ellipse([(nx-2, ny-2), (nx+2, ny+2)], fill=(210, 175, 70, 255), outline=(90, 70, 20, 255))

    elif pattern == "cobble":
        # Segmented stone bricks with rich mortar grooves
        m_top = (int(top_col[0]*0.55), int(top_col[1]*0.55), int(top_col[2]*0.55), 255)
        draw.line([(80, 64), (128, 96), (176, 72)], fill=m_top, width=4)
        draw.line([(104, 48), (112, 88)], fill=m_top, width=3)
        m_left = (int(left_col[0]*0.55), int(left_col[1]*0.55), int(left_col[2]*0.55), 255)
        draw.line([(48, 120), (88, 128), (80, 192)], fill=m_left, width=4)
        draw.line([(88, 128), (128, 168)], fill=m_left, width=3)
        m_right = (int(right_col[0]*0.55), int(right_col[1]*0.55), int(right_col[2]*0.55), 255)
        draw.line([(168, 120), (184, 168), (144, 192)], fill=m_right, width=4)
        draw.line([(128, 168), (184, 168)], fill=m_right, width=3)

    elif pattern == "crate":
        # Heavy reinforced expedition container with iron brackets
        iron_bracket = (150, 160, 175, 255)
        iron_dark = (50, 55, 65, 255)
        # Top diagonal brace
        draw.line([(56, 80), (200, 80)], fill=(65, 45, 25, 255), width=8)
        draw.line([(128, 44), (128, 116)], fill=(65, 45, 25, 255), width=8)
        # Left cross brace
        draw.line([(40, 92), (120, 212)], fill=(55, 38, 20, 255), width=8)
        # Right cross brace
        draw.line([(216, 92), (136, 212)], fill=(40, 26, 14, 255), width=8)
        # Corner iron brackets with rivets
        for bx, by in [(128, 32), (32, 80), (224, 80), (128, 224), (128, 128)]:
            draw.ellipse([(bx-10, by-10), (bx+10, by+10)], fill=iron_bracket, outline=iron_dark)
            draw.ellipse([(bx-3, by-3), (bx+3, by+3)], fill=(220, 230, 245, 255))

    elif pattern == "magma":
        glow_core = (255, 235, 120, 255)
        glow_outer = (255, 80, 10, 255)
        # Top fissure
        draw.line([(96, 64), (128, 88), (160, 72)], fill=glow_outer, width=8)
        draw.line([(96, 64), (128, 88), (160, 72)], fill=glow_core, width=3)
        # Left fissure
        draw.line([(64, 112), (96, 152), (72, 192)], fill=glow_outer, width=8)
        draw.line([(64, 112), (96, 152), (72, 192)], fill=glow_core, width=3)
        # Right fissure
        draw.line([(160, 112), (176, 152), (144, 184)], fill=glow_outer, width=8)
        draw.line([(160, 112), (176, 152), (144, 184)], fill=glow_core, width=3)

    elif pattern == "calcite":
        glint = (245, 250, 255, 255)
        draw.polygon([(104, 48), (136, 56), (152, 96), (120, 88)], fill=(215, 225, 245, 255))
        draw.line([(104, 48), (152, 96)], fill=glint, width=3)
        draw.polygon([(56, 112), (88, 104), (104, 168), (72, 176)], fill=(185, 200, 230, 255))
        draw.line([(56, 112), (104, 168)], fill=glint, width=3)
        draw.polygon([(152, 112), (184, 104), (200, 168), (168, 176)], fill=(155, 170, 200, 255))
        draw.line([(152, 112), (200, 168)], fill=glint, width=3)

    elif pattern == "ore" and ore_col:
        for ox, oy in [(88, 64), (144, 72), (112, 104), (64, 128), (96, 176), (160, 136), (192, 168)]:
            # Ore chunk
            draw.ellipse([(ox-8, oy-8), (ox+8, oy+8)], fill=(int(ore_col[0]*0.5), int(ore_col[1]*0.5), int(ore_col[2]*0.5), 255))
            draw.ellipse([(ox-6, oy-6), (ox+6, oy+6)], fill=ore_col)
            draw.ellipse([(ox-2, oy-4), (ox+3, oy+1)], fill=(min(255, ore_col[0]+70), min(255, ore_col[1]+70), min(255, ore_col[2]+70), 255))

    # Crisp top ridge highlights
    draw.line([(128, 32), (224, 80)], fill=(min(255, int(top_col[0]*1.35)), min(255, int(top_col[1]*1.35)), min(255, int(top_col[2]*1.35)), 220), width=3)
    draw.line([(128, 32), (32, 80)], fill=(min(255, int(top_col[0]*1.35)), min(255, int(top_col[1]*1.35)), min(255, int(top_col[2]*1.35)), 220), width=3)
    draw.line([(128, 128), (128, 224)], fill=(min(255, int(left_col[0]*1.25)), min(255, int(left_col[1]*1.25)), min(255, int(left_col[2]*1.25)), 180), width=3)

    return img

def draw_pickaxe():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Ambient drop shadow
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.line([(72, 216), (196, 92)], fill=(0, 0, 0, 140), width=24)
    shadow = shadow.filter(ImageFilter.GaussianBlur(8))
    img.alpha_composite(shadow)

    # Handle (diagonal heavy hardwood shaft)
    wood_shadow = (70, 42, 22, 255)
    wood_main = (145, 95, 55, 255)
    wood_hi = (195, 135, 80, 255)
    draw.line([(64, 208), (184, 88)], fill=wood_shadow, width=22)
    draw.line([(66, 206), (186, 86)], fill=wood_main, width=16)
    draw.line([(68, 204), (188, 84)], fill=wood_hi, width=6)

    # Leather handle wraps with cross-lacing
    for i in range(5):
        wx = 80 + i * 18
        wy = 192 - i * 18
        draw.line([(wx-8, wy+8), (wx+8, wy-8)], fill=(215, 165, 110, 255), width=8)
        draw.line([(wx-6, wy+6), (wx+6, wy-6)], fill=(245, 195, 140, 255), width=4)

    # Forged steel pickaxe head (arched double-beveled beak)
    metal_dark = (35, 42, 50, 255)
    metal_mid = (115, 128, 145, 255)
    metal_light = (195, 210, 228, 255)
    metal_hi = (250, 252, 255, 255)

    pick_curve = [
        (80, 40), (120, 48), (160, 64), (188, 88), (212, 120), (228, 160)
    ]
    draw.line(pick_curve, fill=metal_dark, width=28)
    draw.line(pick_curve, fill=metal_mid, width=20)
    draw.line(pick_curve, fill=metal_light, width=12)
    draw.line([(88, 44), (128, 52), (168, 68), (196, 92)], fill=metal_hi, width=4)

    # Sharp beak points
    draw.polygon([(72, 36), (88, 32), (88, 52)], fill=metal_hi)
    draw.polygon([(228, 164), (236, 172), (216, 172)], fill=metal_hi)

    # Brass reinforcing socket ring with rivet
    draw.ellipse([(172, 72), (200, 100)], fill=(225, 180, 65, 255), outline=(130, 95, 25, 255), width=4)
    draw.ellipse([(182, 82), (190, 90)], fill=(255, 225, 120, 255))
    return img

def draw_lantern():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Warm radiant volumetric aura
    aura = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    adraw = ImageDraw.Draw(aura)
    adraw.ellipse([(56, 72), (200, 216)], fill=(255, 190, 60, 75))
    adraw.ellipse([(76, 92), (180, 196)], fill=(255, 230, 120, 110))
    aura = aura.filter(ImageFilter.GaussianBlur(14))
    img.alpha_composite(aura)

    # Hanging wire bail handle
    draw.arc([(88, 24), (168, 88)], 180, 360, fill=(195, 165, 95, 255), width=8)

    # Top brass cap & fluted heat vent
    draw.rectangle([(112, 56), (144, 68)], fill=(230, 190, 80, 255), outline=(110, 80, 20, 255), width=3)
    draw.polygon([(96, 84), (160, 84), (144, 68), (112, 68)], fill=(215, 175, 65, 255), outline=(100, 75, 18, 255))
    draw.line([(88, 88), (168, 88)], fill=(250, 225, 120, 255), width=8)

    # Glass chimney chamber (88, 92 to 168, 172)
    draw.rectangle([(88, 92), (168, 172)], fill=(32, 42, 56, 180), outline=(140, 110, 40, 255), width=4)

    # Glowing flame & wick inside
    draw.ellipse([(112, 120), (144, 152)], fill=(255, 240, 160, 255))
    draw.ellipse([(120, 128), (136, 144)], fill=(255, 255, 245, 255))
    draw.line([(128, 152), (128, 168)], fill=(80, 40, 20, 255), width=6)

    # Protective brass cage bars
    draw.line([(108, 92), (108, 172)], fill=(215, 175, 65, 255), width=4)
    draw.line([(148, 92), (148, 172)], fill=(215, 175, 65, 255), width=4)

    # Heavy brass fuel reservoir base
    draw.rectangle([(80, 176), (176, 188)], fill=(235, 195, 85, 255), outline=(100, 70, 15, 255), width=3)
    draw.polygon([(80, 192), (176, 192), (184, 216), (72, 216)], fill=(200, 160, 55, 255), outline=(90, 65, 15, 255))
    draw.line([(72, 216), (184, 216)], fill=(130, 95, 25, 255), width=8)
    return img

def draw_flare():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Pyrotechnic red flare
    # Intense red aura at tip
    aura = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    adraw = ImageDraw.Draw(aura)
    adraw.ellipse([(130, 30), (230, 130)], fill=(255, 40, 30, 100))
    adraw.ellipse([(155, 55), (205, 105)], fill=(255, 200, 180, 180))
    aura = aura.filter(ImageFilter.GaussianBlur(12))
    img.alpha_composite(aura)

    # Flare body (cylinder at 45 degree angle)
    # Red weatherproof casing
    draw.line([(64, 192), (160, 96)], fill=(180, 25, 25, 255), width=26)
    draw.line([(68, 188), (164, 92)], fill=(230, 50, 45, 255), width=18)
    draw.line([(72, 184), (168, 88)], fill=(255, 110, 100, 255), width=6)

    # Metal igniter cap & ribbed grip
    draw.line([(56, 200), (80, 176)], fill=(60, 65, 75, 255), width=28)
    draw.line([(58, 198), (82, 174)], fill=(140, 150, 165, 255), width=20)
    for i in range(3):
        gx = 62 + i * 8
        gy = 194 - i * 8
        draw.line([(gx-6, gy-6), (gx+6, gy+6)], fill=(30, 35, 42, 255), width=3)

    # White-hot magnesium burning tip & flying sparks
    draw.ellipse([(156, 80), (180, 104)], fill=(255, 250, 240, 255))
    draw.ellipse([(162, 86), (174, 98)], fill=(255, 255, 255, 255))
    for sx, sy in [(188, 64), (204, 82), (168, 52), (196, 112), (218, 70)]:
        draw.ellipse([(sx-3, sy-3), (sx+3, sy+3)], fill=(255, 240, 160, 255))
    return img

def draw_dynamite():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Bundle of 3 red nitro sticks bound with brass tape
    # Back stick
    draw.line([(88, 72), (184, 168)], fill=(160, 25, 25, 255), width=28)
    # Left stick
    draw.line([(72, 96), (168, 192)], fill=(210, 40, 35, 255), width=28)
    draw.line([(74, 94), (170, 190)], fill=(245, 90, 80, 255), width=10)
    # Right stick
    draw.line([(104, 88), (200, 184)], fill=(190, 30, 30, 255), width=28)
    draw.line([(106, 86), (202, 182)], fill=(235, 75, 70, 255), width=10)

    # Brass / electrical binding straps
    for bx, by in [(100, 116), (156, 172)]:
        draw.line([(bx-24, by+24), (bx+24, by-24)], fill=(215, 175, 60, 255), width=12)
        draw.line([(bx-22, by+22), (bx+22, by-22)], fill=(250, 215, 110, 255), width=4)

    # Braided twine fuse curving up to spark
    draw.arc([(56, 32), (104, 80)], 45, 240, fill=(180, 160, 110, 255), width=6)
    # Sizzling spark at fuse tip
    draw.ellipse([(52, 28), (68, 44)], fill=(255, 230, 80, 255))
    draw.ellipse([(56, 32), (64, 40)], fill=(255, 255, 255, 255))
    for sp in [(44, 24), (72, 20), (60, 12), (38, 36)]:
        draw.point(sp, fill=(255, 240, 120, 255))
    return img

def draw_grappling_rope():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Coiled hemp expedition rope with forged 3-prong steel grappling hook
    # Coiled rope loops
    rope_dark = (90, 65, 40, 255)
    rope_mid = (160, 125, 80, 255)
    rope_hi = (210, 175, 120, 255)

    for r in range(48, 88, 12):
        draw.arc([(128-r, 140-r//2), (128+r, 140+r//2)], 0, 360, fill=rope_dark, width=14)
        draw.arc([(128-r, 140-r//2), (128+r, 140+r//2)], 0, 360, fill=rope_mid, width=10)
        draw.arc([(128-r, 140-r//2), (128+r, 140+r//2)], 180, 360, fill=rope_hi, width=4)

    # Forged steel grappling hook
    steel_dark = (40, 48, 58, 255)
    steel_mid = (120, 135, 155, 255)
    steel_hi = (210, 225, 245, 255)

    # Hook shank
    draw.line([(128, 48), (128, 120)], fill=steel_dark, width=14)
    draw.line([(128, 48), (128, 120)], fill=steel_mid, width=10)
    draw.line([(126, 48), (126, 120)], fill=steel_hi, width=3)

    # Top attachment ring
    draw.ellipse([(116, 28), (140, 52)], outline=steel_dark, width=8)
    draw.ellipse([(118, 30), (138, 50)], outline=steel_hi, width=4)

    # Left & right curved talons
    draw.arc([(80, 80), (130, 130)], 90, 270, fill=steel_dark, width=12)
    draw.arc([(82, 82), (128, 128)], 90, 270, fill=steel_mid, width=8)
    draw.arc([(126, 80), (176, 130)], 270, 90, fill=steel_dark, width=12)
    draw.arc([(128, 82), (174, 128)], 270, 90, fill=steel_mid, width=8)

    # Sharp talon points
    draw.polygon([(80, 100), (72, 80), (92, 88)], fill=steel_hi)
    draw.polygon([(176, 100), (184, 80), (164, 88)], fill=steel_hi)
    return img

def draw_obsidian_blade():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Razor-sharp volcanic glass obsidian dagger
    # Dark shadow
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.line([(64, 204), (196, 72)], fill=(0, 0, 0, 140), width=18)
    shadow = shadow.filter(ImageFilter.GaussianBlur(8))
    img.alpha_composite(shadow)

    # Leather wrapped bone handle
    draw.line([(56, 208), (104, 160)], fill=(75, 45, 25, 255), width=20)
    draw.line([(58, 206), (106, 158)], fill=(140, 95, 55, 255), width=14)
    for i in range(4):
        hx = 64 + i * 12
        hy = 200 - i * 12
        draw.line([(hx-6, hy+6), (hx+6, hy-6)], fill=(215, 175, 110, 255), width=4)

    # Bone pommel & guard
    draw.ellipse([(44, 208), (64, 228)], fill=(210, 205, 190, 255), outline=(100, 95, 80, 255), width=3)
    draw.line([(92, 172), (116, 148)], fill=(180, 175, 160, 255), width=12)

    # Obsidian blade: deep pitch black with sharp purple-cyan refraction bevel
    blade_pts = [(104, 160), (124, 140), (208, 56), (196, 72), (140, 124)]
    draw.polygon([(104, 160), (196, 44), (160, 104)], fill=(18, 16, 24, 255))
    draw.polygon([(104, 160), (196, 44), (140, 130)], fill=(32, 28, 42, 255))

    # Razor sharp specular edge
    draw.line([(104, 160), (200, 48)], fill=(160, 130, 220, 255), width=3)
    draw.line([(104, 160), (198, 46)], fill=(255, 255, 255, 255), width=1)
    return img

def draw_amethyst_shard():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Violet glowing crystal cluster
    aura = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    adraw = ImageDraw.Draw(aura)
    adraw.ellipse([(64, 48), (192, 192)], fill=(170, 40, 255, 80))
    aura = aura.filter(ImageFilter.GaussianBlur(14))
    img.alpha_composite(aura)

    # Faceted crystal spires
    # Main central spire
    draw.polygon([(128, 40), (168, 104), (152, 192), (104, 192), (88, 104)], fill=(120, 30, 190, 255))
    draw.polygon([(128, 40), (88, 104), (104, 192), (128, 192), (128, 40)], fill=(180, 60, 255, 255))
    draw.line([(128, 40), (128, 192)], fill=(245, 215, 255, 255), width=4)

    # Left spire
    draw.polygon([(80, 112), (104, 144), (96, 208), (64, 208), (56, 152)], fill=(140, 40, 210, 255))
    draw.polygon([(80, 112), (56, 152), (64, 208), (80, 208)], fill=(200, 90, 255, 255))

    # Right spire
    draw.polygon([(176, 96), (200, 136), (192, 208), (160, 208), (152, 144)], fill=(100, 20, 170, 255))
    draw.polygon([(176, 96), (152, 144), (160, 208), (176, 208)], fill=(170, 50, 240, 255))

    # Dark basalt rock host
    draw.polygon([(56, 200), (200, 200), (184, 224), (72, 224)], fill=(45, 48, 56, 255), outline=(25, 28, 34, 255), width=3)
    return img

def draw_ancient_core():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Glowing Precursor relic polyhedron with cyan glyphs
    aura = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    adraw = ImageDraw.Draw(aura)
    adraw.ellipse([(56, 56), (200, 200)], fill=(0, 220, 255, 90))
    adraw.ellipse([(80, 80), (176, 176)], fill=(180, 255, 255, 130))
    aura = aura.filter(ImageFilter.GaussianBlur(14))
    img.alpha_composite(aura)

    # Polyhedron shell (dark metallic slate)
    draw.polygon([(128, 48), (204, 92), (204, 164), (128, 208), (52, 164), (52, 92)], fill=(24, 30, 38, 255), outline=(12, 16, 22, 255), width=4)
    # Inner glowing cyan core window
    draw.polygon([(128, 76), (180, 106), (180, 150), (128, 180), (76, 150), (76, 106)], fill=(0, 180, 220, 255))
    draw.polygon([(128, 92), (164, 112), (164, 144), (128, 164), (92, 144), (92, 112)], fill=(180, 255, 255, 255))

    # Ancient circuit conduits / etched runes
    draw.line([(128, 48), (128, 76)], fill=(0, 240, 255, 255), width=4)
    draw.line([(204, 92), (180, 106)], fill=(0, 240, 255, 255), width=4)
    draw.line([(204, 164), (180, 150)], fill=(0, 240, 255, 255), width=4)
    draw.line([(128, 208), (128, 180)], fill=(0, 240, 255, 255), width=4)
    draw.line([(52, 164), (76, 150)], fill=(0, 240, 255, 255), width=4)
    draw.line([(52, 92), (76, 106)], fill=(0, 240, 255, 255), width=4)
    return img

def draw_salve():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Subterranean herbal restorative balm ceramic jar
    # Ceramic jar body
    draw.ellipse([(64, 88), (192, 208)], fill=(65, 80, 70, 255), outline=(35, 45, 40, 255), width=4)
    draw.ellipse([(72, 96), (184, 200)], fill=(90, 110, 95, 255))
    # Specular shine
    draw.arc([(80, 104), (176, 192)], 190, 270, fill=(180, 210, 190, 255), width=8)

    # Brass screw lid
    draw.rectangle([(88, 64), (168, 88)], fill=(225, 185, 75, 255), outline=(110, 85, 25, 255), width=4)
    draw.line([(88, 76), (168, 76)], fill=(255, 225, 120, 255), width=4)

    # Healer emblem on front
    draw.rectangle([(120, 128), (136, 168)], fill=(230, 245, 235, 255))
    draw.rectangle([(108, 140), (148, 156)], fill=(230, 245, 235, 255))
    return img

def draw_canteen():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Leather shoulder strap
    draw.arc([(48, 40), (208, 200)], 190, 350, fill=(90, 60, 35, 255), width=8)
    # Brass cap & neck
    draw.rectangle([(116, 56), (140, 72)], fill=(220, 180, 70, 255), outline=(100, 75, 20, 255), width=3)
    draw.line([(112, 76), (144, 76)], fill=(130, 95, 25, 255), width=6)

    # Round canteen flask body
    draw.ellipse([(64, 80), (192, 208)], fill=(65, 85, 105, 255), outline=(35, 45, 55, 255), width=4)
    draw.ellipse([(72, 88), (184, 200)], fill=(95, 120, 145, 255))
    # Specular shine
    draw.arc([(80, 96), (176, 192)], 200, 280, fill=(190, 215, 240, 255), width=8)
    # Leather harness band
    draw.line([(68, 144), (188, 144)], fill=(110, 75, 45, 255), width=10)
    draw.line([(128, 84), (128, 204)], fill=(110, 75, 45, 255), width=10)
    return img

def draw_rations():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # MRE Survival Ration Pack
    draw.rectangle([(64, 64), (192, 192)], fill=(60, 72, 55, 255), outline=(30, 38, 28, 255), width=4)
    draw.rectangle([(72, 72), (184, 184)], fill=(85, 102, 78, 255))
    # Heat-seal crimp lines
    draw.line([(64, 80), (192, 80)], fill=(40, 50, 36, 255), width=4)
    draw.line([(64, 176), (192, 176)], fill=(40, 50, 36, 255), width=4)
    # Red cross
    draw.rectangle([(116, 108), (140, 148)], fill=(195, 45, 40, 255))
    draw.rectangle([(100, 120), (156, 136)], fill=(195, 45, 40, 255))
    return img

def draw_torch():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Diagonal burning torch
    draw.line([(72, 208), (144, 104)], fill=(70, 45, 25, 255), width=24)
    draw.line([(76, 204), (148, 100)], fill=(140, 95, 55, 255), width=16)
    draw.line([(80, 200), (152, 96)], fill=(185, 130, 80, 255), width=6)

    # Carbide iron cage wrap
    draw.rectangle([(136, 88), (168, 112)], fill=(50, 45, 45, 255), outline=(25, 22, 22, 255), width=4)

    # Bright burning flame
    draw.ellipse([(140, 32), (196, 96)], fill=(255, 100, 20, 220))
    draw.ellipse([(148, 44), (188, 84)], fill=(255, 190, 40, 240))
    draw.ellipse([(156, 56), (180, 76)], fill=(255, 255, 180, 255))
    for sx, sy in [(192, 32), (176, 20), (204, 56), (144, 28)]:
        draw.point((sx, sy), fill=(255, 225, 110, 255))
    return img

def draw_journal():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Leather-bound surveyor's field notebook
    draw.rectangle([(64, 56), (192, 200)], fill=(80, 45, 30, 255), outline=(40, 20, 15, 255), width=4)
    draw.rectangle([(72, 64), (184, 192)], fill=(115, 65, 40, 255))
    # Pages gold trim
    draw.line([(188, 64), (188, 192)], fill=(235, 225, 195, 255), width=6)
    # Embossed surveyor compass emblem
    draw.ellipse([(112, 112), (144, 144)], outline=(225, 185, 75, 255), width=4)
    draw.line([(128, 104), (128, 152)], fill=(225, 185, 75, 255), width=3)
    draw.line([(104, 128), (152, 128)], fill=(225, 185, 75, 255), width=3)
    # Red silk bookmark ribbon
    draw.line([(128, 192), (128, 216), (140, 208)], fill=(195, 40, 40, 255), width=6)
    return img

def draw_ingot(base_col, mid_col, light_col, hi_col):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Isometric trapezoidal metal ingot (256x256)
    draw.polygon([(80, 96), (176, 96), (160, 128), (96, 128)], fill=light_col)
    draw.polygon([(56, 152), (80, 96), (96, 128), (72, 176)], fill=base_col)
    draw.polygon([(96, 128), (160, 128), (184, 176), (72, 176)], fill=mid_col)
    draw.polygon([(160, 128), (176, 96), (200, 152), (184, 176)], fill=base_col)

    draw.line([(84, 96), (172, 96)], fill=hi_col, width=4)
    draw.line([(96, 128), (160, 128)], fill=hi_col, width=4)
    return img

def draw_crystal(core_col, mid_col, hi_col):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    aura = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    adraw = ImageDraw.Draw(aura)
    adraw.ellipse([(64, 40), (192, 192)], fill=(int(core_col[0]), int(core_col[1]), int(core_col[2]), 75))
    aura = aura.filter(ImageFilter.GaussianBlur(14))
    img.alpha_composite(aura)

    # Central crystal spire
    draw.polygon([(128, 40), (168, 104), (152, 192), (104, 192), (88, 104)], fill=mid_col)
    draw.polygon([(128, 40), (88, 104), (104, 192), (128, 192), (128, 40)], fill=core_col)
    draw.line([(128, 40), (128, 192)], fill=hi_col, width=4)

    # Flanking crystals
    draw.polygon([(80, 112), (104, 144), (96, 208), (64, 208), (56, 152)], fill=mid_col)
    draw.polygon([(176, 96), (200, 136), (192, 208), (160, 208), (152, 144)], fill=core_col)

    # Base rock bed
    draw.polygon([(56, 200), (200, 200), (184, 224), (72, 224)], fill=(50, 55, 65, 255), outline=(25, 28, 35, 255), width=3)
    return img

def draw_mushroom():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Glowing teal mycena mushroom
    aura = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    adraw = ImageDraw.Draw(aura)
    adraw.ellipse([(56, 64), (200, 156)], fill=(20, 200, 180, 80))
    aura = aura.filter(ImageFilter.GaussianBlur(14))
    img.alpha_composite(aura)

    # Stem
    draw.polygon([(112, 128), (144, 128), (152, 208), (104, 208)], fill=(160, 210, 220, 255), outline=(80, 125, 135, 255), width=4)
    # Cap
    draw.ellipse([(64, 72), (192, 144)], fill=(20, 185, 165, 255), outline=(10, 95, 85, 255), width=4)
    draw.arc([(72, 76), (184, 120)], 180, 360, fill=(90, 245, 225, 255), width=8)
    for dx, dy in [(96, 96), (128, 88), (160, 100), (112, 112), (144, 112)]:
        draw.ellipse([(dx-6, dy-6), (dx+6, dy+6)], fill=(215, 255, 245, 255))
    return img

def draw_water():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Crystal glass flask with glacial spring water
    draw.rectangle([(112, 56), (144, 80)], fill=(185, 200, 215, 200), outline=(100, 115, 130, 255), width=4)
    draw.ellipse([(72, 88), (184, 200)], fill=(40, 120, 195, 230), outline=(160, 205, 245, 255), width=4)
    draw.ellipse([(80, 104), (176, 192)], fill=(65, 160, 240, 240))
    draw.arc([(88, 112), (168, 176)], 190, 270, fill=(225, 250, 255, 255), width=8)
    return img

def draw_lichen():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    dark_shadow = (35, 55, 30, 255)
    root_col = (85, 140, 75, 255)
    mid_green = (125, 185, 110, 255)
    tip_col = (180, 240, 150, 255)
    glow_col = (225, 255, 200, 255)

    draw.ellipse([(88, 56), (168, 96)], fill=dark_shadow)
    draw.ellipse([(96, 64), (160, 88)], fill=root_col)

    for i in range(8):
        rx = 72 + i * 16
        draw.line([(rx+4, 72), (rx - 12 + (i%3)*16, 184 + (i%2)*24)], fill=dark_shadow, width=12)
        draw.line([(rx, 72), (rx - 16 + (i%3)*16, 184 + (i%2)*24)], fill=root_col, width=8)
        draw.line([(rx-4, 80), (rx - 16 + (i%3)*12, 152)], fill=mid_green, width=4)
        draw.ellipse([(rx - 24 + (i%3)*16, 176 + (i%2)*24), (rx - 8 + (i%3)*16, 192 + (i%2)*24)], fill=tip_col)
        draw.point([(rx - 16 + (i%3)*16, 184 + (i%2)*24)], fill=glow_col)
    return img


def main():
    print("Rendering 256x256 Ultra-Crisp Isometric Voxel Blocks and Tool Icons...")

    # Blocks dictionary
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
        "slate_brick": ((55, 60, 68, 255), (40, 44, 52, 255), (28, 30, 38, 255), "cobble", None),
        "packed_ice": ((195, 225, 245, 255), (160, 195, 225, 255), (130, 165, 200, 255), "calcite", None),
        "permafrost": ((135, 155, 175, 255), (105, 125, 145, 255), (75, 95, 115, 255), "plain", None),
        "amethyst_block": ((130, 50, 190, 255), (100, 35, 155, 255), (75, 25, 120, 255), "calcite", None),
        "sulfur_stone": ((180, 175, 70, 255), (145, 140, 50, 255), (110, 105, 35, 255), "plain", None),
    }

    for name, (t, l, r, pat, ore) in blocks.items():
        img = create_isometric_block(t, l, r, pat, ore)
        img.save(f"{OUT_DIR}/icon_{name}.png")

    # Items dictionary
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
        "flare": draw_flare(),
        "dynamite": draw_dynamite(),
        "grappling_rope": draw_grappling_rope(),
        "obsidian_blade": draw_obsidian_blade(),
        "amethyst_shard": draw_amethyst_shard(),
        "ancient_core": draw_ancient_core(),
        "salve": draw_salve(),
        "iron": draw_ingot((110, 120, 135, 255), (150, 160, 175, 255), (195, 205, 220, 255), (250, 255, 255, 255)),
        "copper": draw_ingot((130, 70, 40, 255), (180, 100, 55, 255), (225, 135, 80, 255), (255, 190, 140, 255)),
        "gold": draw_ingot((160, 120, 20, 255), (220, 170, 30, 255), (255, 215, 60, 255), (255, 255, 180, 255)),
        "phosphor": draw_crystal((20, 180, 160, 255), (40, 220, 195, 255), (180, 255, 240, 255)),
    }

    for name, img in items.items():
        img.save(f"{OUT_DIR}/icon_{name}.png")

    print(f"All 256x256 High-Res Isometric Icons Generated ({len(blocks) + len(items)} total) in {OUT_DIR}!")

if __name__ == "__main__":
    main()
