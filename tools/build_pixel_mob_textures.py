"""
Builds cohesive, game-matching pixel-art mob textures using the actual block textures from hollow_core/textures/.
This ensures 100% aesthetic harmony between the mobs and the subterranean voxel world.
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFilter

sys.stdout.reconfigure(encoding='utf-8')

TEX_DIR = "hollow_core/textures"
OUT_DIR = "hollow_core/textures/mobs"
os.makedirs(OUT_DIR, exist_ok=True)

def load_block(name):
    path = os.path.join(TEX_DIR, name)
    if os.path.exists(path):
        return Image.open(path).convert("RGBA")
    raise FileNotFoundError(f"Missing block texture: {path}")

def make_mob_textures():
    print("Loading source game block textures...")
    basalt = load_block("deep_basalt.png")
    slate = load_block("deepslate_rock.png")
    slate_brick = load_block("slate_brick.png")
    magma = load_block("magma_rock.png")
    ice = load_block("permafrost_ice.png")
    calcite = load_block("calcite_crystal.png")
    mushroom = load_block("biolum_mushroom.png")
    amethyst = load_block("crystal_amethyst.png")
    conduit = load_block("precursor_conduit.png")
    gravel = load_block("cavern_gravel.png")
    shale = load_block("cobblestone_shale.png")
    sulfur = load_block("sulfur_block.png")
    lichen = load_block("lichen_root.png")
    phosphor = load_block("phosphor_ore.png")

    # Helper to tile and composite
    def compose_texture(base_img, overlay_img=None, mask=None, size=(256, 256)):
        canvas = Image.new("RGBA", size)
        bw, bh = base_img.size
        for x in range(0, size[0], bw):
            for y in range(0, size[1], bh):
                canvas.paste(base_img, (x, y))
        if overlay_img:
            ow, oh = overlay_img.size
            overlay_tiled = Image.new("RGBA", size)
            for x in range(0, size[0], ow):
                for y in range(0, size[1], oh):
                    overlay_tiled.paste(overlay_img, (x, y))
            if mask:
                canvas.paste(overlay_tiled, (0, 0), mask)
            else:
                canvas = Image.alpha_composite(canvas, overlay_tiled)
        return canvas

    # 1. Chasm Stalker: Deepslate chitin plates with bioluminescent phosphor cyan accents
    print("Generating Chasm Stalker textures...")
    stalker_base = compose_texture(slate, shale, size=(256, 256))
    # Add dark chitin carapace shading (pixelated bands)
    draw = ImageDraw.Draw(stalker_base)
    for y in range(0, 256, 16):
        draw.line([(0, y), (256, y)], fill=(20, 24, 30, 90), width=2)
    stalker_base.save(os.path.join(OUT_DIR, "tex_stalker_pixel.png"))

    stalker_emit = Image.new("RGBA", (256, 256), (0, 0, 0, 255))
    edraw = ImageDraw.Draw(stalker_emit)
    # Eye clusters and bioluminescent markings
    for (cx, cy) in [(64, 40), (80, 36), (96, 40), (160, 40), (176, 36), (192, 40)]:
        edraw.rectangle([cx-3, cy-3, cx+3, cy+3], fill=(40, 240, 255, 255))
        edraw.rectangle([cx-1, cy-1, cx+1, cy+1], fill=(220, 255, 255, 255))
    # Dorsal stripe
    for y in range(80, 220, 16):
        edraw.rectangle([124, y, 132, y+6], fill=(0, 210, 240, 255))
    stalker_emit.save(os.path.join(OUT_DIR, "tex_stalker_pixel_emit.png"))

    # 2. Lithic Crawler: Basalt stone crab with amethyst crystal cluster
    print("Generating Lithic Crawler textures...")
    crawler_base = compose_texture(basalt, size=(256, 256))
    # Stamp amethyst crystal patches onto top quadrants (where crystals sprout)
    for px, py in [(64, 64), (160, 64), (112, 112)]:
        crawler_base.paste(amethyst, (px, py), amethyst)
    crawler_base.save(os.path.join(OUT_DIR, "tex_crawler_pixel.png"))

    crawler_emit = Image.new("RGBA", (256, 256), (0, 0, 0, 255))
    cdraw = ImageDraw.Draw(crawler_emit)
    # Glowing amethyst crystal facets
    for px, py in [(64, 64), (160, 64), (112, 112)]:
        cdraw.rectangle([px+20, py+20, px+44, py+44], fill=(220, 120, 255, 255))
        cdraw.rectangle([px+28, py+28, px+36, py+36], fill=(255, 240, 255, 255))
    # Crawler glowing amber sensor pits
    cdraw.rectangle([116, 220, 124, 226], fill=(255, 180, 40, 255))
    cdraw.rectangle([132, 220, 140, 226], fill=(255, 180, 40, 255))
    crawler_emit.save(os.path.join(OUT_DIR, "tex_crawler_pixel_emit.png"))

    # 3. Cryo Wisp: Permafrost ice & calcite crystal
    print("Generating Cryo Wisp textures...")
    cryo_base = compose_texture(ice, calcite, size=(256, 256))
    cryo_base.save(os.path.join(OUT_DIR, "tex_cryo_pixel.png"))

    cryo_emit = Image.new("RGBA", (256, 256), (0, 0, 0, 255))
    wdraw = ImageDraw.Draw(cryo_emit)
    # Intense frost core glow
    for x in range(32, 224, 8):
        for y in range(32, 224, 8):
            dist = ((x-128)**2 + (y-128)**2)**0.5
            if dist < 80:
                glow = int(max(0, 255 - dist * 3))
                wdraw.rectangle([x, y, x+6, y+6], fill=(int(glow*0.7), glow, 255, 255))
    cryo_emit.save(os.path.join(OUT_DIR, "tex_cryo_pixel_emit.png"))

    # 4. Magma Basilisk: Deep basalt rock with molten magma cracks
    print("Generating Magma Basilisk textures...")
    magma_base = compose_texture(magma, size=(256, 256))
    magma_base.save(os.path.join(OUT_DIR, "tex_magma_pixel.png"))

    # Emission extracted directly from magma bright pixels
    magma_emit = Image.new("RGBA", (256, 256), (0, 0, 0, 255))
    m_pixels = magma_base.load()
    e_pixels = magma_emit.load()
    for x in range(256):
        for y in range(256):
            r, g, b, a = m_pixels[x, y]
            # If orange/yellow/red magma vein
            if r > 160 and g > 60 and b < 50:
                e_pixels[x, y] = (r, g, b, 255)
    # Basilisk eyes
    edraw = ImageDraw.Draw(magma_emit)
    edraw.rectangle([60, 30, 72, 40], fill=(255, 240, 50, 255))
    edraw.rectangle([184, 30, 196, 40], fill=(255, 240, 50, 255))
    magma_emit.save(os.path.join(OUT_DIR, "tex_magma_pixel_emit.png"))

    # 5. Fungal Strider: Bioluminescent mushroom (cap) & lichen roots (legs)
    print("Generating Fungal Strider textures...")
    # Cap uses deep indigo bioluminescent mushroom texture directly for perfect biome match
    strider_base = compose_texture(mushroom, size=(256, 256))
    strider_base.save(os.path.join(OUT_DIR, "tex_fungal_pixel.png"))

    fungal_emit = Image.new("RGBA", (256, 256), (0, 0, 0, 255))
    f_pixels = strider_base.load()
    fe_pixels = fungal_emit.load()
    for x in range(256):
        for y in range(256):
            r, g, b, a = f_pixels[x, y]
            # Cyan spore patches glow intensely
            if b > 120 and g > 110:
                fe_pixels[x, y] = (0, 240, 255, 255)
    fungal_emit.save(os.path.join(OUT_DIR, "tex_fungal_pixel_emit.png"))

    # 6. Geode Golem: Slate masonry bricks with ancient Precursor conduits
    print("Generating Geode Golem textures...")
    golem_base = compose_texture(slate_brick, size=(256, 256))
    # Stamp conduit lines across the bricks
    golem_base.paste(conduit, (0, 0), conduit)
    golem_base.paste(conduit, (128, 0), conduit)
    golem_base.paste(conduit, (0, 128), conduit)
    golem_base.paste(conduit, (128, 128), conduit)
    golem_base.save(os.path.join(OUT_DIR, "tex_golem_pixel.png"))

    golem_emit = Image.new("RGBA", (256, 256), (0, 0, 0, 255))
    gdraw = ImageDraw.Draw(golem_emit)
    # Precursor star rune glow (brilliant golden amber and cyan)
    for ox, oy in [(0, 0), (128, 0), (0, 128), (128, 128)]:
        # Central cross
        gdraw.line([(ox+32, oy), (ox+32, oy+64)], fill=(255, 200, 40, 255), width=3)
        gdraw.line([(ox, oy+32), (ox+64, oy+32)], fill=(255, 200, 40, 255), width=3)
        # Diagonals
        gdraw.line([(ox+10, oy+10), (ox+54, oy+54)], fill=(0, 240, 255, 255), width=2)
        gdraw.line([(ox+54, oy+10), (ox+10, oy+54)], fill=(0, 240, 255, 255), width=2)
        # Visor / Core
        gdraw.rectangle([ox+28, oy+28, ox+36, oy+36], fill=(255, 255, 255, 255))
    golem_emit.save(os.path.join(OUT_DIR, "tex_golem_pixel_emit.png"))

    # 7. NEW: Abyssal Glider (Пещерный Крылан): Shale cobblestone + dark basalt + leathery wing veins
    print("Generating Abyssal Glider textures...")
    glider_base = compose_texture(shale, basalt, size=(256, 256))
    gldraw = ImageDraw.Draw(glider_base)
    # Leathery wing struts and claws
    for x in [32, 64, 96, 160, 192, 224]:
        gldraw.line([(128, 40), (x, 240)], fill=(30, 32, 38, 180), width=4)
    glider_base.save(os.path.join(OUT_DIR, "tex_glider_pixel.png"))

    glider_emit = Image.new("RGBA", (256, 256), (0, 0, 0, 255))
    gledraw = ImageDraw.Draw(glider_emit)
    # Burning crimson/amber predatory bat eyes & echolocation vents
    gledraw.rectangle([116, 44, 122, 50], fill=(255, 60, 30, 255))
    gledraw.rectangle([134, 44, 140, 50], fill=(255, 60, 30, 255))
    glider_emit.save(os.path.join(OUT_DIR, "tex_glider_pixel_emit.png"))

    # 8. NEW: Deep Cave Wyrm (Пещерный Червь): Cavern gravel + deepslate armored segments
    print("Generating Deep Cave Wyrm textures...")
    wyrm_base = compose_texture(gravel, slate, size=(256, 256))
    wdraw = ImageDraw.Draw(wyrm_base)
    # Circular jaw / ringed scales
    for y in range(0, 256, 24):
        wdraw.rectangle([0, y, 256, y+4], fill=(15, 18, 22, 200))
        # Segment tooth notches
        for x in range(0, 256, 16):
            wdraw.polygon([(x, y+4), (x+8, y+14), (x+16, y+4)], fill=(180, 175, 160, 230))
    wyrm_base.save(os.path.join(OUT_DIR, "tex_wyrm_pixel.png"))

    wyrm_emit = Image.new("RGBA", (256, 256), (0, 0, 0, 255))
    wydraw = ImageDraw.Draw(wyrm_emit)
    # Bioluminescent sensory spots along the flank
    for y in range(12, 256, 32):
        wydraw.rectangle([40, y, 46, y+6], fill=(0, 255, 180, 255))
        wydraw.rectangle([210, y, 216, y+6], fill=(0, 255, 180, 255))
    wyrm_emit.save(os.path.join(OUT_DIR, "tex_wyrm_pixel_emit.png"))

    # 9. NEW: Acid Spore-Spitter (Кислотный Споровик): Sulfur block + lichen root + bio mushroom
    print("Generating Acid Spore-Spitter textures...")
    spitter_base = compose_texture(lichen, sulfur, size=(256, 256))
    spitter_base.save(os.path.join(OUT_DIR, "tex_spitter_pixel.png"))

    spitter_emit = Image.new("RGBA", (256, 256), (0, 0, 0, 255))
    spdraw = ImageDraw.Draw(spitter_emit)
    # Bright acidic yellow-green toxic pustules
    for (px, py, r) in [(80, 80, 14), (170, 75, 16), (128, 140, 20), (60, 170, 12), (190, 180, 15)]:
        spdraw.ellipse([px-r, py-r, px+r, py+r], fill=(220, 255, 20, 255))
        spdraw.ellipse([px-r//2, py-r//2, px+r//2, py+r//2], fill=(255, 255, 180, 255))
    spitter_emit.save(os.path.join(OUT_DIR, "tex_spitter_pixel_emit.png"))

    print("All 9 mob pixel-art texture pairs successfully generated and mapped to game blocks!")

if __name__ == "__main__":
    make_mob_textures()
