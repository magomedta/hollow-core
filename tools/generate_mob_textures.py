# hollow_core/tools/generate_mob_textures.py
# High-Resolution PBR Texture Generator for Subterranean Mobs
from PIL import Image, ImageDraw, ImageFilter
import numpy as np
import math
import os

TEX_SIZE = 512

def create_noise_array(size, scale=16, octaves=4):
    np.random.seed(42)
    grid = np.zeros((size, size))
    for o in range(octaves):
        freq = 2 ** o
        amp = 1.0 / freq
        step = max(1, size // (scale * freq))
        small = np.random.rand(size // step + 2, size // step + 2)
        up = np.zeros((size, size))
        for y in range(size):
            for x in range(size):
                gx = x / step
                gy = y / step
                x0 = int(gx); y0 = int(gy)
                fx = gx - x0; fy = gy - y0
                v00 = small[y0, x0]
                v10 = small[y0, x0+1]
                v01 = small[y0+1, x0]
                v11 = small[y0+1, x0+1]
                v = (1-fx)*(1-fy)*v00 + fx*(1-fy)*v10 + (1-fx)*fy*v01 + fx*fy*v11
                up[y, x] = v
        grid += up * amp
    grid = (grid - grid.min()) / (grid.max() - grid.min() + 1e-5)
    return grid

def generate_textures(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    
    # 1. Chasm Stalker Chitin Texture (Deep obsidian chitin with organic growth lines)
    img_stalker = Image.new("RGBA", (TEX_SIZE, TEX_SIZE))
    d = ImageDraw.Draw(img_stalker)
    for y in range(TEX_SIZE):
        for x in range(TEX_SIZE):
            # Voronoi-like faceted chitin plates
            nx = (x % 64) - 32
            ny = (y % 64) - 32
            dist = math.sqrt(nx*nx + ny*ny) / 32.0
            edge = 1.0 - smoothstep(0.7, 0.95, dist)
            base_val = int(24 + edge * 28 + (math.sin(x*0.1) * math.cos(y*0.1)) * 8)
            img_stalker.putpixel((x, y), (base_val, int(base_val * 1.15), int(base_val * 1.3), 255))
            
    # Add scratch lines & shell ridges
    for i in range(30):
        sx = (i * 37) % TEX_SIZE
        sy = (i * 59) % TEX_SIZE
        d.line([sx, sy, sx + 25, sy + 15], fill=(70, 85, 95, 120), width=1)
        d.line([sx, sy+1, sx + 25, sy + 16], fill=(15, 18, 22, 180), width=1)
    img_stalker.save(os.path.join(out_dir, "tex_stalker_chitin.png"))
    
    # Stalker Emissive (Glowing cyan eye slits & bio veins)
    img_stalker_emit = Image.new("RGBA", (TEX_SIZE, TEX_SIZE), (0, 0, 0, 255))
    d_emit = ImageDraw.Draw(img_stalker_emit)
    for ey in range(6):
        ex = 120 + ey * 45
        d_emit.ellipse([ex, 240, ex + 28, 270], fill=(25, 255, 220, 255))
        d_emit.ellipse([ex + 6, 246, ex + 22, 264], fill=(180, 255, 245, 255))
    img_stalker_emit = img_stalker_emit.filter(ImageFilter.GaussianBlur(1))
    img_stalker_emit.save(os.path.join(out_dir, "tex_stalker_emit.png"))

    # 2. Lithic Crawler Basalt & Crystal Texture
    img_crawler = Image.new("RGBA", (TEX_SIZE, TEX_SIZE))
    for y in range(TEX_SIZE):
        for x in range(TEX_SIZE):
            grain = int((math.sin(x*0.25) * math.sin(y*0.25) + math.sin(x*0.05 + y*0.08)) * 16)
            base_r = max(20, min(100, 65 + grain))
            base_g = max(20, min(100, 70 + grain))
            base_b = max(20, min(110, 75 + grain))
            # Moss speckles
            if (x * 13 + y * 29) % 37 == 0:
                base_g += 25
                base_r -= 10
            img_crawler.putpixel((x, y), (base_r, base_g, base_b, 255))
    img_crawler.save(os.path.join(out_dir, "tex_crawler_stone.png"))

    # 3. Magma Basilisk Texture (Obsidian scales with molten lava fissures)
    img_magma = Image.new("RGBA", (TEX_SIZE, TEX_SIZE))
    img_magma_emit = Image.new("RGBA", (TEX_SIZE, TEX_SIZE), (0, 0, 0, 255))
    d_mag = ImageDraw.Draw(img_magma)
    d_mag_emit = ImageDraw.Draw(img_magma_emit)
    
    # Dark volcanic rock base
    for y in range(TEX_SIZE):
        for x in range(TEX_SIZE):
            v = int(25 + (math.sin(x*0.1) * math.cos(y*0.1)) * 10)
            img_magma.putpixel((x, y), (v + 5, v, v, 255))
            
    # Molten lava fissures
    for f in range(18):
        fx = (f * 43) % TEX_SIZE
        fy = (f * 67) % TEX_SIZE
        points = [(fx, fy), (fx + 30, fy + 20), (fx + 55, fy + 10), (fx + 85, fy + 45)]
        d_mag.line(points, fill=(255, 90, 10, 255), width=4)
        d_mag.line(points, fill=(255, 210, 50, 255), width=2)
        d_mag_emit.line(points, fill=(255, 120, 15, 255), width=4)
        d_mag_emit.line(points, fill=(255, 240, 80, 255), width=2)
        
    img_magma.save(os.path.join(out_dir, "tex_magma_skin.png"))
    img_magma_emit = img_magma_emit.filter(ImageFilter.GaussianBlur(2))
    img_magma_emit.save(os.path.join(out_dir, "tex_magma_emit.png"))

    # 4. Fungal Strider Texture (Mushroom cap, gills, fibrous root striations)
    img_fungal = Image.new("RGBA", (TEX_SIZE, TEX_SIZE))
    d_fun = ImageDraw.Draw(img_fungal)
    for y in range(TEX_SIZE):
        for x in range(TEX_SIZE):
            r = int(75 + math.sin(x*0.08) * 20)
            g = int(120 + math.cos(y*0.08) * 25)
            b = int(140 + math.sin((x+y)*0.06) * 30)
            img_fungal.putpixel((x, y), (r, g, b, 255))
    # Bioluminescent spore rings on cap
    for s in range(12):
        sx = 60 + (s * 38) % 400
        sy = 60 + (s * 47) % 400
        d_fun.ellipse([sx, sy, sx + 22, sy + 22], fill=(40, 230, 200, 200), outline=(200, 255, 240))
    img_fungal.save(os.path.join(out_dir, "tex_fungal_skin.png"))

    # 5. Geode Golem Texture (Carved precursor slate with golden glowing runes)
    img_golem = Image.new("RGBA", (TEX_SIZE, TEX_SIZE))
    img_golem_emit = Image.new("RGBA", (TEX_SIZE, TEX_SIZE), (0, 0, 0, 255))
    d_gol = ImageDraw.Draw(img_golem)
    d_gol_emit = ImageDraw.Draw(img_golem_emit)
    for y in range(TEX_SIZE):
        for x in range(TEX_SIZE):
            v = int(45 + (math.sin(x*0.12) * math.cos(y*0.12)) * 12)
            img_golem.putpixel((x, y), (v, v + 2, v + 6, 255))
    # Golden runic circuit lines
    rune_lines = [
        [(80, 80), (220, 80), (220, 180), (320, 180)],
        [(150, 260), (150, 380), (280, 380)],
        [(340, 100), (440, 100), (440, 300), (380, 360)]
    ]
    for r in rune_lines:
        d_gol.line(r, fill=(240, 185, 45, 255), width=3)
        d_gol_emit.line(r, fill=(255, 195, 55, 255), width=4)
        d_gol_emit.line(r, fill=(255, 245, 180, 255), width=2)
    img_golem.save(os.path.join(out_dir, "tex_golem_slate.png"))
    img_golem_emit = img_golem_emit.filter(ImageFilter.GaussianBlur(1))
    img_golem_emit.save(os.path.join(out_dir, "tex_golem_emit.png"))
    
    print(f"[TextureGen] All mob textures successfully generated in: {out_dir}")

def smoothstep(edge0, edge1, x):
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)

if __name__ == "__main__":
    out_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "textures", "mobs"))
    generate_textures(out_dir)
