"""
Bespoke Hand-Crafted Pixel-Art Textures for Subterranean & Horror Mobs.
Resolution: 128x128 (matches in-game block pixel density perfectly).
Layout:
- Top-Left (X:0..64, Y:0..64): Head & Face (eyes, teeth, mandibles, snout)
- Top-Right (X:64..128, Y:0..64): Dorsal Body (spine, carapace plates, ribs)
- Bottom-Left (X:0..64, Y:64..128): Limbs & Joints (armored segments, claw tips, knees)
- Bottom-Right (X:64..128, Y:64..128): Underbelly / Special Features (crystals, wings, maws, runes)
"""
import os
import sys
import random
from PIL import Image, ImageDraw

OUT_DIR = "hollow_core/textures/mobs"
os.makedirs(OUT_DIR, exist_ok=True)

def create_texture_pair(name):
    base = Image.new("RGBA", (128, 128), (0, 0, 0, 255))
    emit = Image.new("RGBA", (128, 128), (0, 0, 0, 255))
    return base, emit

# 1. PALE LURKER (Horror: Emaciated sickly ghoul with needle claws and black eye sockets)
def make_pale_lurker():
    base, emit = create_texture_pair("pale_lurker")
    bdraw = ImageDraw.Draw(base)
    edraw = ImageDraw.Draw(emit)

    # Base sickly pale grey-green fleshy tone
    bdraw.rectangle([0, 0, 128, 128], fill=(168, 175, 170, 255))

    # --- TOP-LEFT: HEAD & GAUNT FACE (0..64, 0..64) ---
    # Sunken flesh shading
    for y in range(0, 64):
        shade = int(140 + y * 0.4)
        bdraw.line([(0, y), (64, y)], fill=(shade, shade+5, shade, 255))
    # Deep hollow black eye sockets (Eyeless horror!)
    bdraw.rectangle([14, 18, 28, 30], fill=(18, 14, 16, 255))
    bdraw.rectangle([36, 18, 50, 30], fill=(18, 14, 16, 255))
    # Faint unsettling pinpoint red reflection deep in the sockets
    edraw.rectangle([20, 24, 22, 26], fill=(255, 40, 30, 255))
    edraw.rectangle([42, 24, 44, 26], fill=(255, 40, 30, 255))
    # Gaping mouth with jagged needle-like bloody teeth
    bdraw.rectangle([16, 42, 48, 56], fill=(25, 8, 12, 255))
    for tx in range(18, 48, 4):
        bdraw.line([(tx, 42), (tx+1, 48)], fill=(230, 225, 210, 255), width=1) # Upper teeth
        bdraw.line([(tx+2, 56), (tx+1, 50)], fill=(230, 225, 210, 255), width=1) # Lower teeth
        bdraw.point([(tx, 48), (tx+2, 50)], fill=(160, 20, 20, 255)) # Blood staining

    # --- TOP-RIGHT: DORSAL SPINE & VISIBLE RIBS (64..128, 0..64) ---
    # Darker bruised spine channel
    bdraw.rectangle([64, 0, 128, 64], fill=(150, 155, 152, 255))
    bdraw.rectangle([92, 0, 100, 64], fill=(110, 105, 115, 255)) # Spinal furrow
    for y in range(4, 60, 8):
        # Vertebra knobs
        bdraw.rectangle([94, y, 98, y+4], fill=(220, 220, 215, 255))
        # Protruding bony ribs reaching outwards
        bdraw.line([(92, y+2), (72, y+5)], fill=(210, 210, 200, 255), width=2)
        bdraw.line([(100, y+2), (120, y+5)], fill=(210, 210, 200, 255), width=2)
        # Bruised shadow under ribs
        bdraw.line([(72, y+7), (92, y+4)], fill=(120, 110, 125, 255), width=1)
        bdraw.line([(100, y+4), (120, y+7)], fill=(120, 110, 125, 255), width=1)

    # --- BOTTOM-LEFT: LIMBS & NEEDLE CLAWS (0..64, 64..128) ---
    bdraw.rectangle([0, 64, 64, 128], fill=(160, 165, 162, 255))
    # Bony arm bones & dark bruised elbow joints
    bdraw.rectangle([24, 64, 40, 128], fill=(140, 142, 140, 255))
    bdraw.rectangle([20, 92, 44, 100], fill=(105, 95, 110, 255)) # Joint
    # Blackened necrotic needle claw tips
    for cx in range(8, 56, 8):
        bdraw.polygon([(cx, 120), (cx+3, 120), (cx+1, 128)], fill=(30, 28, 32, 255))
        bdraw.point([(cx+1, 128)], fill=(15, 15, 18, 255))

    # --- BOTTOM-RIGHT: STOMACH & TENDONS (64..128, 64..128) ---
    bdraw.rectangle([64, 64, 128, 128], fill=(145, 148, 145, 255))
    for y in range(68, 124, 6):
        bdraw.line([(70, y), (122, y)], fill=(130, 125, 135, 255), width=1) # Stretched tendons

    base.save(os.path.join(OUT_DIR, "tex_pale_lurker.png"))
    emit.save(os.path.join(OUT_DIR, "tex_pale_lurker_emit.png"))

# 2. CHASM STALKER (Subterranean Apex Arachnid Predator)
def make_chasm_stalker():
    base, emit = create_texture_pair("chasm_stalker")
    bdraw = ImageDraw.Draw(base)
    edraw = ImageDraw.Draw(emit)

    # Base chitinous deepslate slate-grey
    bdraw.rectangle([0, 0, 128, 128], fill=(42, 46, 54, 255))

    # --- TOP-LEFT: HEAD & MULTI-EYE CLUSTERS (0..64, 0..64) ---
    # Chitin plate seams on head
    bdraw.polygon([(8, 8), (56, 8), (48, 56), (16, 56)], fill=(34, 38, 46, 255))
    bdraw.line([(32, 8), (32, 56)], fill=(20, 22, 28, 255), width=2)
    # 8 Glowing Bioluminescent Cyan Predator Eyes
    eye_pos = [(20, 22), (28, 18), (36, 18), (44, 22), (22, 30), (30, 26), (34, 26), (42, 30)]
    for (ex, ey) in eye_pos:
        bdraw.rectangle([ex-2, ey-2, ex+2, ey+2], fill=(10, 180, 210, 255))
        bdraw.point([(ex, ey)], fill=(220, 255, 255, 255))
        edraw.rectangle([ex-2, ey-2, ex+2, ey+2], fill=(0, 220, 255, 255))
        edraw.point([(ex, ey)], fill=(255, 255, 255, 255))
    # Serrated Mandible pincers at bottom of face
    for side, mx in [(-1, 20), (1, 44)]:
        bdraw.polygon([(mx, 46), (mx+side*6, 62), (mx-side*2, 60)], fill=(75, 82, 95, 255))
        bdraw.line([(mx+side*6, 62), (mx-side*2, 60)], fill=(180, 200, 215, 255), width=1) # Sharp edge

    # --- TOP-RIGHT: DORSAL CARAPACE & CHITIN SCUTES (64..128, 0..64) ---
    for seg in range(4):
        sy = seg * 16
        bdraw.rectangle([66, sy+1, 126, sy+14], fill=(48 + seg*4, 52 + seg*4, 62 + seg*4, 255))
        bdraw.line([(66, sy+15), (126, sy+15)], fill=(18, 20, 26, 255), width=2) # Plate gap
        # Bioluminescent warning stripes along the spine
        bdraw.rectangle([92, sy+4, 100, sy+10], fill=(0, 180, 220, 255))
        edraw.rectangle([92, sy+4, 100, sy+10], fill=(0, 230, 255, 255))

    # --- BOTTOM-LEFT: RAPTOR ARMS & LEGS (0..64, 64..128) ---
    bdraw.rectangle([0, 64, 64, 128], fill=(36, 40, 48, 255))
    # Segmented leg joints
    for y in range(68, 124, 14):
        bdraw.rectangle([8, y, 56, y+8], fill=(52, 58, 68, 255))
        bdraw.line([(8, y+9), (56, y+9)], fill=(15, 16, 22, 255), width=2)
    # Serrated Scythe Blade (Metallic edge)
    bdraw.line([(48, 68), (12, 124)], fill=(195, 210, 225, 255), width=3)
    bdraw.line([(50, 70), (14, 126)], fill=(240, 250, 255, 255), width=1)

    # --- BOTTOM-RIGHT: UNDERBELLY & RESPIRATORY GILLS (64..128, 64..128) ---
    bdraw.rectangle([64, 64, 128, 128], fill=(30, 32, 38, 255))
    for gy in range(70, 122, 8):
        bdraw.rectangle([74, gy, 118, gy+3], fill=(15, 16, 20, 255)) # Gill slit
        bdraw.point([(96, gy+1)], fill=(0, 200, 240, 255))
        edraw.point([(96, gy+1)], fill=(0, 240, 255, 255))

    base.save(os.path.join(OUT_DIR, "tex_chasm_stalker.png"))
    emit.save(os.path.join(OUT_DIR, "tex_chasm_stalker_emit.png"))

# 3. LITHIC CRAWLER (Basalt Crab with Amethyst Geode & Amber Sensor Eyes)
def make_lithic_crawler():
    base, emit = create_texture_pair("lithic_crawler")
    bdraw = ImageDraw.Draw(base)
    edraw = ImageDraw.Draw(emit)

    # Base basalt stone block texture
    bdraw.rectangle([0, 0, 128, 128], fill=(55, 58, 65, 255))

    # --- TOP-LEFT: HEAD & SENSOR EYES (0..64, 0..64) ---
    bdraw.rectangle([4, 4, 60, 60], fill=(45, 48, 55, 255))
    # Heavy stone brow ridge
    bdraw.rectangle([12, 14, 52, 22], fill=(70, 75, 85, 255))
    bdraw.line([(12, 23), (52, 23)], fill=(25, 26, 30, 255), width=2)
    # 2 Glowing Amber Sensor Eye Slits
    bdraw.rectangle([18, 26, 26, 32], fill=(255, 170, 20, 255))
    bdraw.rectangle([38, 26, 46, 32], fill=(255, 170, 20, 255))
    bdraw.point([(22, 29), (42, 29)], fill=(255, 240, 200, 255))
    edraw.rectangle([18, 26, 26, 32], fill=(255, 180, 20, 255))
    edraw.rectangle([38, 26, 46, 32], fill=(255, 180, 20, 255))
    edraw.point([(22, 29), (42, 29)], fill=(255, 255, 255, 255))
    # Crushing stone mouthparts
    bdraw.rectangle([20, 42, 44, 54], fill=(30, 32, 36, 255))
    bdraw.polygon([(22, 42), (28, 48), (22, 54)], fill=(120, 125, 135, 255))
    bdraw.polygon([(42, 42), (36, 48), (42, 54)], fill=(120, 125, 135, 255))

    # --- TOP-RIGHT: DORSAL BASALT SHELL & AMETHYST GEODE VEINS (64..128, 0..64) ---
    # Rock fractures
    bdraw.rectangle([64, 0, 128, 64], fill=(50, 52, 60, 255))
    for (px, py) in [(80, 12), (105, 20), (90, 45)]:
        # Amethyst crystalline cluster pattern
        bdraw.rectangle([px-10, py-10, px+10, py+10], fill=(130, 50, 180, 255))
        bdraw.rectangle([px-6, py-6, px+6, py+6], fill=(185, 90, 235, 255))
        bdraw.rectangle([px-2, py-2, px+2, py+2], fill=(240, 200, 255, 255))
        edraw.rectangle([px-6, py-6, px+6, py+6], fill=(190, 95, 245, 255))
        edraw.rectangle([px-2, py-2, px+2, py+2], fill=(255, 230, 255, 255))

    # --- BOTTOM-LEFT: HEAVY STONE CRAB LEGS (0..64, 64..128) ---
    bdraw.rectangle([0, 64, 64, 128], fill=(48, 50, 56, 255))
    # Basalt masonry block joints on legs
    for y in range(68, 120, 16):
        bdraw.rectangle([10, y, 54, y+10], fill=(62, 66, 75, 255))
        bdraw.line([(10, y+11), (54, y+11)], fill=(22, 24, 28, 255), width=2)
    # Foot ground claw
    bdraw.polygon([(20, 120), (44, 120), (32, 128)], fill=(32, 34, 38, 255))

    # --- BOTTOM-RIGHT: HEAVY PINCER CLAW (64..128, 64..128) ---
    bdraw.rectangle([64, 64, 128, 128], fill=(58, 62, 70, 255))
    # Basalt pincer teeth
    for ty in range(74, 118, 10):
        bdraw.polygon([(78, ty), (92, ty+5), (78, ty+10)], fill=(160, 165, 175, 255))
        bdraw.polygon([(114, ty), (100, ty+5), (114, ty+10)], fill=(160, 165, 175, 255))

    base.save(os.path.join(OUT_DIR, "tex_lithic_crawler.png"))
    emit.save(os.path.join(OUT_DIR, "tex_lithic_crawler_emit.png"))

# 4. MAGMA BASILISK (Volcanic Drake with glowing molten veins & reptilian slit eyes)
def make_magma_basilisk():
    base, emit = create_texture_pair("magma_basilisk")
    bdraw = ImageDraw.Draw(base)
    edraw = ImageDraw.Draw(emit)

    # Dark charred obsidian basalt base
    bdraw.rectangle([0, 0, 128, 128], fill=(28, 25, 28, 255))

    # --- TOP-LEFT: REPTILIAN HEAD & FIERY EYES (0..64, 0..64) ---
    bdraw.polygon([(12, 10), (52, 10), (44, 54), (20, 54)], fill=(35, 30, 32, 255))
    # Fiery Glowing Yellow Reptilian Slit Eyes
    for (ex, ey) in [(20, 24), (44, 24)]:
        bdraw.rectangle([ex-3, ey-4, ex+3, ey+4], fill=(255, 180, 10, 255))
        bdraw.line([(ex, ey-4), (ex, ey+4)], fill=(20, 10, 5, 255), width=2) # Slit pupil
        bdraw.point([(ex-1, ey)], fill=(255, 255, 150, 255))
        edraw.rectangle([ex-3, ey-4, ex+3, ey+4], fill=(255, 190, 10, 255))
        edraw.point([(ex-1, ey)], fill=(255, 255, 200, 255))
    # Razor fangs in jaw
    bdraw.rectangle([18, 44, 46, 54], fill=(45, 10, 5, 255))
    for fx in range(20, 46, 5):
        bdraw.polygon([(fx, 44), (fx+2, 50), (fx+4, 44)], fill=(235, 220, 180, 255))
    # Molten throat glow
    edraw.rectangle([24, 48, 40, 53], fill=(255, 100, 10, 255))

    # --- TOP-RIGHT: DORSAL SCALES & OBSIDIAN SPINES (64..128, 0..64) ---
    # Reptile scales with crackling orange magma veins
    bdraw.rectangle([64, 0, 128, 64], fill=(32, 28, 30, 255))
    for sy in range(4, 60, 10):
        # Magma fissure
        bdraw.line([(70, sy), (85, sy+3), (110, sy-2), (124, sy+4)], fill=(255, 90, 15, 255), width=2)
        bdraw.line([(70, sy), (85, sy+3), (110, sy-2), (124, sy+4)], fill=(255, 210, 40, 255), width=1)
        edraw.line([(70, sy), (85, sy+3), (110, sy-2), (124, sy+4)], fill=(255, 110, 20, 255), width=2)
        edraw.line([(70, sy), (85, sy+3), (110, sy-2), (124, sy+4)], fill=(255, 230, 60, 255), width=1)
        # Spine scale
        bdraw.polygon([(92, sy-3), (96, sy+5), (100, sy-3)], fill=(55, 48, 52, 255))

    # --- BOTTOM-LEFT: REPTILIAN LEGS & CLAWS (0..64, 64..128) ---
    bdraw.rectangle([0, 64, 64, 128], fill=(32, 28, 30, 255))
    # Muscular scale folds
    for y in range(70, 118, 12):
        bdraw.line([(10, y), (54, y)], fill=(48, 42, 45, 255), width=3)
    # Sharp obsidian claws
    for cx in [16, 28, 40]:
        bdraw.polygon([(cx, 118), (cx+4, 118), (cx+2, 127)], fill=(15, 12, 14, 255))
        bdraw.point([(cx+2, 127)], fill=(200, 70, 20, 255))

    # --- BOTTOM-RIGHT: LAVA UNDERBELLY SCUTES (64..128, 64..128) ---
    bdraw.rectangle([64, 64, 128, 128], fill=(42, 22, 18, 255))
    for by in range(68, 124, 8):
        bdraw.rectangle([72, by, 120, by+5], fill=(70, 30, 20, 255))
        bdraw.line([(72, by+2), (120, by+2)], fill=(255, 130, 20, 255), width=1)
        edraw.line([(72, by+2), (120, by+2)], fill=(255, 150, 20, 255), width=1)

    base.save(os.path.join(OUT_DIR, "tex_magma_basilisk.png"))
    emit.save(os.path.join(OUT_DIR, "tex_magma_basilisk_emit.png"))

# 5. GEODE GOLEM (Ancient Precursor Guardian with Runes and Glowing Visor)
def make_geode_golem():
    base, emit = create_texture_pair("geode_golem")
    bdraw = ImageDraw.Draw(base)
    edraw = ImageDraw.Draw(emit)

    # Ancient chiseled slate masonry base
    bdraw.rectangle([0, 0, 128, 128], fill=(44, 48, 54, 255))

    # --- TOP-LEFT: MONOLITH HEAD & GLOWING EYE VISOR (0..64, 0..64) ---
    bdraw.rectangle([8, 8, 56, 56], fill=(52, 56, 64, 255))
    # Beveled stone edges
    bdraw.line([(8, 8), (56, 8)], fill=(75, 82, 92, 255), width=2)
    bdraw.line([(8, 8), (8, 56)], fill=(75, 82, 92, 255), width=2)
    bdraw.line([(56, 8), (56, 56)], fill=(25, 28, 32, 255), width=2)
    bdraw.line([(8, 56), (56, 56)], fill=(25, 28, 32, 255), width=2)
    # Brilliant Golden Precursor Eye Visor Slot
    bdraw.rectangle([14, 28, 50, 36], fill=(255, 195, 30, 255))
    bdraw.rectangle([24, 30, 40, 34], fill=(255, 255, 220, 255))
    edraw.rectangle([14, 28, 50, 36], fill=(255, 205, 40, 255))
    edraw.rectangle([24, 30, 40, 34], fill=(255, 255, 240, 255))

    # --- TOP-RIGHT: PRECURSOR CHEST & RUNIC CIRCUIT CORE (64..128, 0..64) ---
    bdraw.rectangle([64, 0, 128, 64], fill=(40, 44, 50, 255))
    # Chiseled slate brick pattern
    for by in range(0, 64, 16):
        bdraw.line([(64, by), (128, by)], fill=(22, 24, 28, 255), width=2)
    # Golden / Cyan Conduit Star Glyph in center of chest
    cx, cy = 96, 32
    # Cyan circuit lines
    bdraw.line([(cx-20, cy), (cx+20, cy)], fill=(0, 220, 255, 255), width=2)
    bdraw.line([(cx, cy-20), (cx, cy+20)], fill=(0, 220, 255, 255), width=2)
    bdraw.line([(cx-12, cy-12), (cx+12, cy+12)], fill=(0, 220, 255, 255), width=1)
    bdraw.line([(cx+12, cy-12), (cx-12, cy+12)], fill=(0, 220, 255, 255), width=1)
    edraw.line([(cx-20, cy), (cx+20, cy)], fill=(0, 240, 255, 255), width=2)
    edraw.line([(cx, cy-20), (cx, cy+20)], fill=(0, 240, 255, 255), width=2)
    edraw.line([(cx-12, cy-12), (cx+12, cy+12)], fill=(0, 240, 255, 255), width=1)
    edraw.line([(cx+12, cy-12), (cx-12, cy+12)], fill=(0, 240, 255, 255), width=1)
    # Golden core diamond
    bdraw.polygon([(cx, cy-6), (cx+6, cy), (cx, cy+6), (cx-6, cy)], fill=(255, 210, 40, 255))
    edraw.polygon([(cx, cy-6), (cx+6, cy), (cx, cy+6), (cx-6, cy)], fill=(255, 225, 60, 255))

    # --- BOTTOM-LEFT: STONE PILLAR LEGS (0..64, 64..128) ---
    bdraw.rectangle([0, 64, 64, 128], fill=(42, 46, 52, 255))
    for y in range(68, 124, 14):
        bdraw.rectangle([6, y, 58, y+10], fill=(50, 55, 62, 255))
        bdraw.line([(6, y+11), (58, y+11)], fill=(20, 22, 26, 255), width=2)
        # Ancient engraved hash mark
        bdraw.line([(32, y+2), (32, y+8)], fill=(0, 200, 240, 255), width=1)
        edraw.line([(32, y+2), (32, y+8)], fill=(0, 230, 255, 255), width=1)

    # --- BOTTOM-RIGHT: BOULDER FIST KNUCKLES (64..128, 64..128) ---
    bdraw.rectangle([64, 64, 128, 128], fill=(48, 52, 60, 255))
    for kx in range(70, 122, 14):
        bdraw.rectangle([kx, 76, kx+10, 116], fill=(65, 70, 80, 255))
        bdraw.line([(kx+11, 76), (kx+11, 116)], fill=(20, 22, 26, 255), width=2)

    base.save(os.path.join(OUT_DIR, "tex_geode_golem.png"))
    emit.save(os.path.join(OUT_DIR, "tex_geode_golem_emit.png"))

# 6. FUNGAL STRIDER (Mycena Parasol Strider with Glowing Spore Discs)
def make_fungal_strider():
    base, emit = create_texture_pair("fungal_strider")
    bdraw = ImageDraw.Draw(base)
    edraw = ImageDraw.Draw(emit)

    # Deep indigo / navy mushroom flesh
    bdraw.rectangle([0, 0, 128, 128], fill=(22, 26, 38, 255))

    # --- TOP-LEFT: PARASOL CAP DOME & SPOTS (0..64, 0..64) ---
    bdraw.rectangle([0, 0, 64, 64], fill=(28, 32, 48, 255))
    # Bioluminescent cyan spore clusters
    spore_dots = [(14, 14), (32, 10), (50, 16), (20, 36), (42, 32), (16, 52), (36, 50), (52, 48)]
    for (sx, sy) in spore_dots:
        bdraw.rectangle([sx-3, sy-3, sx+3, sy+3], fill=(0, 180, 210, 255))
        bdraw.rectangle([sx-1, sy-1, sx+1, sy+1], fill=(210, 255, 255, 255))
        edraw.rectangle([sx-3, sy-3, sx+3, sy+3], fill=(0, 210, 240, 255))
        edraw.rectangle([sx-1, sy-1, sx+1, sy+1], fill=(255, 255, 255, 255))

    # --- TOP-RIGHT: RADIATING SPORE GILLS (64..128, 0..64) ---
    bdraw.rectangle([64, 0, 128, 64], fill=(16, 18, 28, 255))
    # Radiating gill lines with pulsing violet/cyan glow
    for x in range(68, 124, 4):
        bdraw.line([(x, 4), (96, 60)], fill=(40, 50, 75, 255), width=1)
        bdraw.point([(x, 12)], fill=(0, 200, 230, 255))
        edraw.point([(x, 12)], fill=(0, 240, 255, 255))

    # --- BOTTOM-LEFT: STILT LEGS (0..64, 64..128) ---
    bdraw.rectangle([0, 64, 64, 128], fill=(26, 30, 42, 255))
    for y in range(66, 126, 12):
        bdraw.line([(4, y), (60, y)], fill=(45, 52, 70, 255), width=2)
        bdraw.point([(32, y)], fill=(0, 220, 255, 255))
        edraw.point([(32, y)], fill=(0, 240, 255, 255))

    # --- BOTTOM-RIGHT: MYCELIUM ROOTS (64..128, 64..128) ---
    bdraw.rectangle([64, 64, 128, 128], fill=(20, 24, 34, 255))
    for root_x in range(70, 122, 10):
        bdraw.line([(root_x, 66), (root_x+4, 126)], fill=(65, 75, 95, 255), width=2)

    base.save(os.path.join(OUT_DIR, "tex_fungal_strider.png"))
    emit.save(os.path.join(OUT_DIR, "tex_fungal_strider_emit.png"))

# 7. WALL MIMIC (Disguised Boulder with Gaping Fanged Maw & Tendrils)
def make_wall_mimic():
    base, emit = create_texture_pair("wall_mimic")
    bdraw = ImageDraw.Draw(base)
    edraw = ImageDraw.Draw(emit)

    # Base basalt stone grey
    bdraw.rectangle([0, 0, 128, 128], fill=(62, 60, 68, 255))
    # Rock noise & grain
    for _ in range(400):
        rx, ry = random.randint(0, 127), random.randint(0, 127)
        c = random.randint(45, 80)
        bdraw.point([(rx, ry)], fill=(c, c, int(c*1.08), 255))

    # --- TOP-LEFT: GAPING MAW & JAGGED MINERAL FANGS (0..64, 0..64) ---
    bdraw.rectangle([6, 6, 58, 58], fill=(20, 10, 15, 255)) # Dark maw void
    # Sinister yellow predatory slitted eyes
    for ex in (18, 46):
        bdraw.rectangle([ex-3, 14, ex+3, 22], fill=(255, 200, 30, 255))
        bdraw.line([(ex, 14), (ex, 22)], fill=(20, 10, 5, 255), width=2) # Slit pupil
        edraw.rectangle([ex-3, 14, ex+3, 22], fill=(255, 210, 40, 255))
        edraw.line([(ex, 14), (ex, 22)], fill=(0, 0, 0, 255), width=2)
    # Upper jagged stalactite teeth
    for tx in range(10, 54, 5):
        h = random.randint(8, 14)
        bdraw.polygon([(tx, 6), (tx+4, 6), (tx+2, 6+h)], fill=(215, 210, 195, 255))
        bdraw.point([(tx+2, 6+h)], fill=(180, 40, 40, 255)) # Blood/acid tip
    # Lower jagged teeth
    for tx in range(12, 52, 5):
        h = random.randint(8, 14)
        bdraw.polygon([(tx, 58), (tx+4, 58), (tx+2, 58-h)], fill=(215, 210, 195, 255))
        bdraw.point([(tx+2, 58-h)], fill=(180, 40, 40, 255))

    # --- TOP-RIGHT: CRACKED ROCK SHELL (64..128, 0..64) ---
    bdraw.rectangle([64, 0, 128, 64], fill=(70, 68, 76, 255))
    # Deep fracture cracks
    bdraw.line([(68, 10), (96, 32), (124, 20)], fill=(30, 28, 35, 255), width=2)
    bdraw.line([(96, 32), (105, 60)], fill=(30, 28, 35, 255), width=2)

    # --- BOTTOM-LEFT: PREHENSILE TENDRILS & HOOKS (0..64, 64..128) ---
    bdraw.rectangle([0, 64, 64, 128], fill=(90, 45, 65, 255)) # Fleshy purple
    for ty in range(70, 124, 10):
        bdraw.line([(8, ty), (56, ty)], fill=(130, 65, 95, 255), width=2)
        bdraw.polygon([(56, ty), (62, ty-3), (60, ty+3)], fill=(230, 220, 200, 255)) # Barbed hook

    # --- BOTTOM-RIGHT: BOULDER BASE (64..128, 64..128) ---
    bdraw.rectangle([64, 64, 128, 128], fill=(55, 54, 60, 255))

    base.save(os.path.join(OUT_DIR, "tex_wall_mimic.png"))
    emit.save(os.path.join(OUT_DIR, "tex_wall_mimic_emit.png"))

def main():
    print("--> Generating bespoke hand-crafted mob textures with anatomy, eyes & features...")
    make_pale_lurker()
    make_chasm_stalker()
    make_lithic_crawler()
    make_magma_basilisk()
    make_geode_golem()
    make_fungal_strider()
    make_wall_mimic()
    print("All bespoke mob texture maps successfully generated!")

if __name__ == "__main__":
    main()
