import numpy as np
from PIL import Image

# Generate authentic weathered subterranean mine support timber
# 64x64 pixel art with rich dark oak grain, iron banding/bolts, and clean shading
size = 64
img = Image.new("RGBA", (size, size))
pixels = img.load()

# Base palette: rich seasoned dark timber
base_dark = np.array([48, 34, 24])
base_mid = np.array([68, 48, 34])
base_light = np.array([88, 62, 44])
base_highlight = np.array([108, 78, 56])

iron_dark = np.array([32, 34, 38])
iron_mid = np.array([55, 58, 64])
iron_highlight = np.array([85, 90, 100])

np.random.seed(42)

for y in range(size):
    for x in range(size):
        # Subtle vertical grain
        grain = np.sin(x * 0.4 + np.sin(y * 0.15) * 1.5) * 0.5 + 0.5
        noise = np.random.uniform(-0.08, 0.08)
        val = np.clip(grain * 0.6 + noise + 0.2, 0.0, 1.0)
        
        # Color gradient
        if val < 0.35:
            c = base_dark + (base_mid - base_dark) * (val / 0.35)
        elif val < 0.70:
            c = base_mid + (base_light - base_mid) * ((val - 0.35) / 0.35)
        else:
            c = base_light + (base_highlight - base_light) * ((val - 0.70) / 0.30)
            
        # Top and bottom end-grain / mortise joint lines
        if y < 2 or y >= 62 or x < 2 or x >= 62:
            c = c * 0.65
            
        # Iron reinforcement band at y = 30..33
        if 29 <= y <= 34:
            c = iron_mid
            if y == 29: c = iron_dark
            elif y == 30: c = iron_highlight
            elif y == 34: c = iron_dark
            # Rivet / bolt head at x = 16, 32, 48
            for rx in [16, 32, 48]:
                if abs(x - rx) <= 2 and abs(y - 32) <= 1:
                    c = iron_highlight if (x <= rx and y <= 32) else iron_dark
                    
        pixels[x, y] = (int(c[0]), int(c[1]), int(c[2]), 255)

img.save("c:/Users/magom/Downloads/twitchst/hollow_core/textures/hewn_timber.png")
print("Saved clean authentic hewn_timber.png!")
