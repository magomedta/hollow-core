"""
Comprehensive High-Detail Bespoke 256x256 Pixel-Art Texture Generator for ALL 11 Mobs.
Enforces multi-tone shading, gradient bands, dithering, and rich anatomical detailing.
"""
import os
import sys
import math
import random
from PIL import Image, ImageDraw

sys.stdout.reconfigure(encoding='utf-8')

TEX_DIR = "hollow_core/textures/mobs"
MODEL_DIR = "hollow_core/models"
os.makedirs(TEX_DIR, exist_ok=True)
os.makedirs(MODEL_DIR, exist_ok=True)

def create_pair():
    base = Image.new("RGBA", (256, 256), (0, 0, 0, 255))
    emit = Image.new("RGBA", (256, 256), (0, 0, 0, 255))
    return base, emit

def add_noise(draw, x0, y0, x1, y1, base_color, variation=12):
    # Dither noise for authentic game-dev pixel texture grain
    r0, g0, b0 = base_color[:3]
    for y in range(y0, y1, 2):
        for x in range(x0, x1, 2):
            v = random.randint(-variation, variation)
            col = (max(0, min(255, r0 + v)), max(0, min(255, g0 + v)), max(0, min(255, b0 + v)), 255)
            draw.rectangle([x, y, x+1, y+1], fill=col)

def save_texture_set(name, base, emit, model_names):
    base_path = os.path.join(TEX_DIR, f"tex_{name}.png")
    emit_path = os.path.join(TEX_DIR, f"tex_{name}_emit.png")
    base.save(base_path)
    emit.save(emit_path)

    for m in model_names:
        p1 = os.path.join(MODEL_DIR, m)
        p2 = os.path.join(MODEL_DIR, m.replace(".png", "_emit.png"))
        base.save(p1)
        emit.save(p2)
    print(f"  [SAVED] {name} -> {len(model_names)} model targets")

# 1. CHASM STALKER
def gen_chasm_stalker():
    base, emit = create_pair()
    b, e = ImageDraw.Draw(base), ImageDraw.Draw(emit)
    add_noise(b, 0, 0, 256, 256, (32, 38, 48), 8)
    for y in range(0, 128):
        c = int(28 + y * 0.25)
        b.line([(0, y), (128, y)], fill=(c, c+6, c+16, 255))
    b.polygon([(64, 10), (20, 80), (108, 80)], fill=(48, 56, 72, 255))
    b.polygon([(64, 14), (30, 76), (98, 76)], fill=(58, 68, 86, 255))
    for ex, ey, sz in [(36, 48, 12), (76, 48, 12), (22, 64, 8), (94, 64, 8), (46, 32, 6), (70, 32, 6)]:
        b.ellipse([ex-sz-2, ey-sz-2, ex+sz+2, ey+sz+2], fill=(12, 16, 22, 255))
        b.ellipse([ex-sz, ey-sz, ex+sz, ey+sz], fill=(40, 220, 210, 255))
        b.ellipse([ex-sz//2, ey-sz//2, ex+sz//2, ey+sz//2], fill=(160, 255, 245, 255))
        e.ellipse([ex-sz, ey-sz, ex+sz, ey+sz], fill=(50, 240, 220, 255))
        e.ellipse([ex-sz//2, ey-sz//2, ex+sz//2, ey+sz//2], fill=(200, 255, 250, 255))
    b.polygon([(30, 96), (48, 124), (54, 96)], fill=(20, 24, 30, 255))
    b.polygon([(98, 96), (80, 124), (74, 96)], fill=(20, 24, 30, 255))
    for t in range(98, 122, 4):
        b.line([(34 + (t-98)//2, t), (42, t)], fill=(200, 210, 220, 255), width=2)
        b.line([(94 - (t-98)//2, t), (86, t)], fill=(200, 210, 220, 255), width=2)
    # Body plates & Scythes
    for row in range(0, 128, 16):
        b.rectangle([132, row, 252, row+14], fill=(40, 48, 62, 255))
        b.rectangle([136, row+2, 248, row+12], fill=(56, 68, 86, 255))
        b.ellipse([142, row+4, 148, row+10], fill=(20, 180, 170, 255))
        b.ellipse([236, row+4, 242, row+10], fill=(20, 180, 170, 255))
        e.ellipse([142, row+4, 148, row+10], fill=(30, 210, 200, 255))
        e.ellipse([236, row+4, 242, row+10], fill=(30, 210, 200, 255))
    for y in range(132, 250):
        t = (y - 132) / 118.0
        c = int(40 + t * 140)
        b.line([(20, y), (50, y)], fill=(c-15, c, c+10, 255), width=1)
        b.line([(50, y), (56, y)], fill=(220, 235, 245, 255), width=1)
    save_texture_set("chasm_stalker", base, emit, ["chasm_stalker_tex_stalker_pixel.png", "stalker_chitin.png", "tex_stalker_pixel.png"])

# 2. LITHIC CRAWLER
def gen_lithic_crawler():
    base, emit = create_pair()
    b, e = ImageDraw.Draw(base), ImageDraw.Draw(emit)
    add_noise(b, 0, 0, 256, 256, (38, 38, 44), 10)
    for y in range(0, 128):
        c = int(36 + y * 0.2)
        b.line([(0, y), (128, y)], fill=(c, c+2, c+6, 255))
    for ex, ey, sz in [(38, 50, 10), (74, 50, 10), (22, 42, 6), (90, 42, 6), (26, 64, 7), (86, 64, 7), (50, 34, 5), (62, 34, 5)]:
        b.ellipse([ex-sz-2, ey-sz-2, ex+sz+2, ey+sz+2], fill=(18, 14, 10, 255))
        b.ellipse([ex-sz, ey-sz, ex+sz, ey+sz], fill=(255, 150, 20, 255))
        b.ellipse([ex-sz//2, ey-sz//2, ex+sz//2, ey+sz//2], fill=(255, 230, 110, 255))
        e.ellipse([ex-sz, ey-sz, ex+sz, ey+sz], fill=(255, 160, 30, 255))
        e.ellipse([ex-sz//2, ey-sz//2, ex+sz//2, ey+sz//2], fill=(255, 240, 140, 255))
    b.polygon([(34, 90), (46, 124), (58, 90)], fill=(24, 24, 28, 255))
    b.polygon([(78, 90), (66, 124), (54, 90)], fill=(24, 24, 28, 255))
    for plate in range(0, 128, 20):
        b.rectangle([134, plate, 250, plate+17], fill=(48, 48, 56, 255))
        b.rectangle([138, plate+2, 246, plate+15], fill=(64, 64, 74, 255))
        b.line([(140, plate+8), (170, plate+12), (210, plate+6), (244, plate+10)], fill=(170, 70, 230, 255), width=2)
        e.line([(140, plate+8), (170, plate+12), (210, plate+6), (244, plate+10)], fill=(190, 90, 250, 255), width=2)
    save_texture_set("lithic_crawler", base, emit, ["lithic_crawler_tex_crawler_pixel.png", "tex_crawler_pixel.png"])

# 3. ABYSSAL GLIDER
def gen_abyssal_glider():
    base, emit = create_pair()
    b, e = ImageDraw.Draw(base), ImageDraw.Draw(emit)
    add_noise(b, 0, 0, 256, 256, (26, 20, 32), 8)
    for y in range(0, 128):
        c = int(24 + y * 0.18)
        b.line([(0, y), (128, y)], fill=(c+6, c, c+12, 255))
    b.polygon([(64, 16), (36, 110), (92, 110)], fill=(38, 30, 48, 255))
    b.polygon([(64, 24), (44, 104), (84, 104)], fill=(52, 42, 66, 255))
    for ex, ey, sz in [(42, 54, 11), (74, 54, 11), (58, 38, 6)]:
        b.ellipse([ex-sz-2, ey-sz-2, ex+sz+2, ey+sz+2], fill=(12, 4, 8, 255))
        b.ellipse([ex-sz, ey-sz, ex+sz, ey+sz], fill=(245, 30, 45, 255))
        b.ellipse([ex-sz//2, ey-sz//2, ex+sz//2, ey+sz//2], fill=(255, 180, 190, 255))
        e.ellipse([ex-sz, ey-sz, ex+sz, ey+sz], fill=(255, 40, 60, 255))
        e.ellipse([ex-sz//2, ey-sz//2, ex+sz//2, ey+sz//2], fill=(255, 210, 220, 255))
    b.rectangle([46, 88, 70, 116], fill=(16, 8, 14, 255))
    for fx in range(48, 68, 4):
        b.line([(fx, 88), (fx+1, 98)], fill=(235, 230, 225, 255), width=2)
        b.line([(fx+2, 114), (fx+1, 104)], fill=(235, 230, 225, 255), width=2)
    # Wing membrane veins
    for vy in range(0, 256, 20):
        b.line([(128, vy), (256, vy+16)], fill=(65, 50, 80, 255), width=3)
        b.line([(140, vy+4), (180, vy+12), (230, vy+8), (250, vy+16)], fill=(160, 30, 70, 255), width=2)
        e.line([(140, vy+4), (180, vy+12), (230, vy+8), (250, vy+16)], fill=(200, 40, 90, 255), width=1)
    save_texture_set("abyssal_glider", base, emit, ["abyssal_glider_tex_glider_pixel.png", "tex_glider_pixel.png"])

# 4. CAVE WYRM
def gen_cave_wyrm():
    base, emit = create_pair()
    b, e = ImageDraw.Draw(base), ImageDraw.Draw(emit)
    add_noise(b, 0, 0, 256, 256, (58, 36, 44), 10)
    b.ellipse([14, 14, 114, 114], fill=(26, 12, 18, 255))
    b.ellipse([30, 30, 98, 98], fill=(14, 6, 10, 255))
    for radius, count in [(46, 16), (32, 12), (18, 8)]:
        for i in range(count):
            ang = (i / float(count)) * 2.0 * math.pi
            tx = int(64 + radius * math.cos(ang))
            ty = int(64 + radius * math.sin(ang))
            b.polygon([(tx-3, ty-3), (tx+3, ty-3), (int(64 + (radius-8)*math.cos(ang)), int(64 + (radius-8)*math.sin(ang)))], fill=(240, 235, 220, 255))
    b.ellipse([54, 54, 74, 74], fill=(255, 80, 40, 255))
    e.ellipse([54, 54, 74, 74], fill=(255, 100, 50, 255))
    for seg in range(0, 256, 16):
        b.rectangle([132, seg, 252, seg+13], fill=(82, 50, 62, 255))
        b.rectangle([136, seg+2, 248, seg+11], fill=(100, 62, 76, 255))
        b.ellipse([142, seg+4, 150, seg+10], fill=(255, 140, 50, 255))
        b.ellipse([234, seg+4, 242, seg+10], fill=(255, 140, 50, 255))
        e.ellipse([142, seg+4, 150, seg+10], fill=(255, 160, 60, 255))
        e.ellipse([234, seg+4, 242, seg+10], fill=(255, 160, 60, 255))
    save_texture_set("cave_wyrm", base, emit, ["cave_wyrm_tex_wyrm_pixel.png", "tex_wyrm_pixel.png"])

# 5. GEODE GOLEM
def gen_geode_golem():
    base, emit = create_pair()
    b, e = ImageDraw.Draw(base), ImageDraw.Draw(emit)
    add_noise(b, 0, 0, 256, 256, (48, 50, 56), 12)
    b.rectangle([20, 24, 108, 104], fill=(58, 60, 68, 255))
    b.rectangle([24, 28, 104, 100], fill=(74, 76, 86, 255))
    b.rectangle([34, 52, 54, 60], fill=(220, 80, 255, 255))
    b.rectangle([68, 52, 88, 60], fill=(220, 80, 255, 255))
    b.line([(61, 40), (61, 76)], fill=(200, 60, 255, 255), width=3)
    e.rectangle([34, 52, 54, 60], fill=(240, 100, 255, 255))
    e.rectangle([68, 52, 88, 60], fill=(240, 100, 255, 255))
    e.line([(61, 40), (61, 76)], fill=(220, 80, 255, 255), width=3)
    for cy in range(12, 116, 24):
        b.polygon([(150, cy), (166, cy-18), (182, cy)], fill=(160, 50, 220, 255))
        b.polygon([(156, cy), (166, cy-14), (176, cy)], fill=(210, 110, 255, 255))
        e.polygon([(156, cy), (166, cy-14), (176, cy)], fill=(220, 120, 255, 255))
    for by in range(132, 250, 20):
        b.line([(20, by+8), (80, by+14), (150, by+6), (230, by+12)], fill=(180, 60, 240, 255), width=2)
        e.line([(20, by+8), (80, by+14), (150, by+6), (230, by+12)], fill=(210, 80, 255, 255), width=2)
    save_texture_set("geode_golem", base, emit, ["geode_golem_tex_golem_pixel.png", "tex_golem_pixel.png"])

# 6. SPORE SPITTER
def gen_spore_spitter():
    base, emit = create_pair()
    b, e = ImageDraw.Draw(base), ImageDraw.Draw(emit)
    add_noise(b, 0, 0, 256, 256, (52, 48, 38), 10)
    for y in range(0, 128):
        c = int(48 + y * 0.15)
        b.line([(0, y), (128, y)], fill=(c, c-4, c-12, 255))
    b.ellipse([24, 24, 104, 104], fill=(30, 38, 22, 255))
    b.ellipse([36, 36, 92, 92], fill=(20, 28, 14, 255))
    b.ellipse([46, 46, 82, 82], fill=(170, 255, 30, 255))
    b.ellipse([54, 54, 74, 74], fill=(230, 255, 120, 255))
    e.ellipse([46, 46, 82, 82], fill=(190, 255, 40, 255))
    e.ellipse([54, 54, 74, 74], fill=(240, 255, 140, 255))
    for ex, ey in [(18, 22), (102, 22), (18, 106), (102, 106)]:
        b.ellipse([ex-6, ey-6, ex+6, ey+6], fill=(20, 16, 12, 255))
        b.ellipse([ex-4, ey-4, ex+4, ey+4], fill=(255, 210, 40, 255))
        e.ellipse([ex-4, ey-4, ex+4, ey+4], fill=(255, 220, 60, 255))
    for sy in range(10, 246, 28):
        b.ellipse([140, sy, 244, sy+24], fill=(78, 72, 54, 255))
        b.ellipse([160, sy+6, 172, sy+16], fill=(160, 255, 40, 255))
        b.ellipse([210, sy+6, 222, sy+16], fill=(160, 255, 40, 255))
        e.ellipse([160, sy+6, 172, sy+16], fill=(180, 255, 60, 255))
        e.ellipse([210, sy+6, 222, sy+16], fill=(180, 255, 60, 255))
    save_texture_set("spore_spitter", base, emit, ["spore_spitter_tex_spitter_pixel.png", "tex_spitter_pixel.png"])

# 7. MAGMA BASILISK
def gen_magma_basilisk():
    base, emit = create_pair()
    b, e = ImageDraw.Draw(base), ImageDraw.Draw(emit)
    add_noise(b, 0, 0, 256, 256, (26, 22, 24), 8)
    for y in range(0, 128):
        c = int(24 + y * 0.12)
        b.line([(0, y), (128, y)], fill=(c+6, c, c+2, 255))
    for ex, ey in [(36, 46), (82, 46)]:
        b.ellipse([ex-12, ey-8, ex+12, ey+8], fill=(40, 8, 4, 255))
        b.ellipse([ex-10, ey-6, ex+10, ey+6], fill=(255, 80, 10, 255))
        b.ellipse([ex-6, ey-4, ex+6, ey+4], fill=(255, 230, 40, 255))
        b.line([(ex, ey-6), (ex, ey+6)], fill=(20, 4, 4, 255), width=2)
        e.ellipse([ex-10, ey-6, ex+10, ey+6], fill=(255, 90, 20, 255))
        e.ellipse([ex-6, ey-4, ex+6, ey+4], fill=(255, 240, 60, 255))
    b.polygon([(30, 80), (64, 120), (98, 80)], fill=(255, 50, 10, 255))
    b.polygon([(38, 84), (64, 114), (90, 84)], fill=(255, 200, 30, 255))
    e.polygon([(30, 80), (64, 120), (98, 80)], fill=(255, 60, 20, 255))
    e.polygon([(38, 84), (64, 114), (90, 84)], fill=(255, 220, 50, 255))
    for sy in range(0, 256, 16):
        b.rectangle([132, sy, 252, sy+14], fill=(46, 36, 38, 255))
        b.line([(134, sy+6), (170, sy+12), (210, sy+4), (250, sy+10)], fill=(255, 70, 10, 255), width=3)
        b.line([(134, sy+6), (170, sy+12), (210, sy+4), (250, sy+10)], fill=(255, 210, 40, 255), width=1)
        e.line([(134, sy+6), (170, sy+12), (210, sy+4), (250, sy+10)], fill=(255, 90, 20, 255), width=2)
        e.line([(134, sy+6), (170, sy+12), (210, sy+4), (250, sy+10)], fill=(255, 230, 60, 255), width=1)
    save_texture_set("magma_basilisk", base, emit, ["magma_basilisk_tex_magma_pixel.png", "tex_magma_pixel.png"])

# 8. PALE LURKER
def gen_pale_lurker():
    base, emit = create_pair()
    b, e = ImageDraw.Draw(base), ImageDraw.Draw(emit)
    add_noise(b, 0, 0, 256, 256, (170, 178, 172), 12)
    for y in range(0, 128):
        s = int(148 + y * 0.28)
        b.line([(0, y), (128, y)], fill=(s, s+6, s+3, 255))
    b.rectangle([24, 32, 54, 62], fill=(16, 12, 14, 255))
    b.rectangle([74, 32, 104, 62], fill=(16, 12, 14, 255))
    b.rectangle([36, 44, 42, 50], fill=(255, 40, 30, 255))
    b.rectangle([86, 44, 92, 50], fill=(255, 40, 30, 255))
    e.rectangle([36, 44, 42, 50], fill=(255, 50, 40, 255))
    e.rectangle([86, 44, 92, 50], fill=(255, 50, 40, 255))
    b.rectangle([30, 80, 98, 116], fill=(30, 10, 16, 255))
    for tx in range(34, 96, 6):
        b.line([(tx, 80), (tx+2, 94)], fill=(240, 235, 225, 255), width=2)
        b.line([(tx+3, 116), (tx+1, 102)], fill=(240, 235, 225, 255), width=2)
        b.point([(tx+1, 94), (tx+2, 102)], fill=(180, 20, 30, 255))
    b.rectangle([186, 0, 198, 128], fill=(120, 115, 125, 255))
    for ry in range(8, 120, 14):
        b.rectangle([188, ry, 196, ry+8], fill=(225, 228, 220, 255))
        b.line([(186, ry+4), (146, ry+10)], fill=(215, 218, 210, 255), width=3)
        b.line([(198, ry+4), (238, ry+10)], fill=(215, 218, 210, 255), width=3)
    save_texture_set("pale_lurker", base, emit, ["pale_lurker_tex_pale_lurker.png", "tex_pale_lurker.png"])

# 9. CRYO WISP
def gen_cryo_wisp():
    base, emit = create_pair()
    b, e = ImageDraw.Draw(base), ImageDraw.Draw(emit)
    add_noise(b, 0, 0, 256, 256, (140, 210, 245), 14)
    b.ellipse([32, 32, 224, 224], fill=(180, 235, 255, 255))
    b.ellipse([50, 50, 206, 206], fill=(215, 245, 255, 255))
    for ex, ey in [(80, 100), (176, 100)]:
        b.ellipse([ex-22, ey-16, ex+22, ey+16], fill=(40, 120, 180, 255))
        b.ellipse([ex-16, ey-12, ex+16, ey+12], fill=(100, 220, 255, 255))
        b.ellipse([ex-8, ey-6, ex+8, ey+6], fill=(240, 255, 255, 255))
        e.ellipse([ex-16, ey-12, ex+16, ey+12], fill=(120, 230, 255, 255))
        e.ellipse([ex-8, ey-6, ex+8, ey+6], fill=(255, 255, 255, 255))
    b.ellipse([100, 160, 156, 196], fill=(60, 140, 200, 255))
    b.ellipse([110, 168, 146, 188], fill=(160, 240, 255, 255))
    e.ellipse([110, 168, 146, 188], fill=(180, 250, 255, 255))
    for f in range(20, 240, 30):
        b.line([(f, 210), (f+12, 250)], fill=(200, 245, 255, 255), width=2)
    save_texture_set("cryo_wisp", base, emit, ["cryo_wisp_tex_cryo_pixel.png", "tex_cryo_pixel.png"])

# 10. FUNGAL STRIDER
def gen_fungal_strider():
    base, emit = create_pair()
    b, e = ImageDraw.Draw(base), ImageDraw.Draw(emit)
    add_noise(b, 0, 0, 256, 256, (38, 28, 56), 10)
    for y in range(0, 128):
        c = int(32 + y * 0.2)
        b.line([(0, y), (128, y)], fill=(c+10, c, c+24, 255))
    for cx in range(24, 236, 44):
        for cy in range(24, 236, 44):
            b.ellipse([cx-14, cy-14, cx+14, cy+14], fill=(70, 160, 240, 255))
            b.ellipse([cx-7, cy-7, cx+7, cy+7], fill=(180, 230, 255, 255))
            e.ellipse([cx-8, cy-8, cx+8, cy+8], fill=(90, 180, 255, 255))
            e.ellipse([cx-4, cy-4, cx+4, cy+4], fill=(200, 240, 255, 255))
    for ly in range(130, 250, 20):
        b.line([(20, ly), (236, ly)], fill=(55, 42, 75, 255), width=3)
    save_texture_set("fungal_strider", base, emit, ["fungal_strider_tex_fungal_pixel.png", "tex_fungal_pixel.png"])

# 11. WALL MIMIC
def gen_wall_mimic():
    base, emit = create_pair()
    b, e = ImageDraw.Draw(base), ImageDraw.Draw(emit)
    add_noise(b, 0, 0, 256, 256, (52, 54, 58), 12)
    for sy in range(16, 240, 28):
        b.line([(10, sy), (246, sy+8)], fill=(34, 36, 40, 255), width=3)
    b.ellipse([30, 70, 226, 186], fill=(22, 10, 18, 255))
    b.ellipse([40, 80, 216, 176], fill=(36, 14, 28, 255))
    for ex in range(54, 206, 22):
        b.ellipse([ex-9, 120, ex+9, 138], fill=(255, 210, 30, 255))
        b.ellipse([ex-4, 124, ex+4, 134], fill=(255, 245, 120, 255))
        b.line([(ex, 120), (ex, 138)], fill=(20, 4, 4, 255), width=2)
        e.ellipse([ex-8, 121, ex+8, 137], fill=(255, 220, 40, 255))
        e.ellipse([ex-4, 124, ex+4, 134], fill=(255, 250, 150, 255))
    save_texture_set("wall_mimic", base, emit, ["wall_mimic_tex_wall_mimic.png", "tex_wall_mimic.png"])

def main():
    print("Generating comprehensive bespoke 256x256 pixel art textures for all 11 mobs...")
    gen_chasm_stalker()
    gen_lithic_crawler()
    gen_abyssal_glider()
    gen_cave_wyrm()
    gen_geode_golem()
    gen_spore_spitter()
    gen_magma_basilisk()
    gen_pale_lurker()
    gen_cryo_wisp()
    gen_fungal_strider()
    gen_wall_mimic()
    print("ALL 11 BESPOKE MOB TEXTURE SETS GENERATED WITH HIGH COLOR DIVERSITY!")

if __name__ == "__main__":
    main()
