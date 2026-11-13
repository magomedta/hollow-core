import sys

path = 'hollow_core/scripts/voxel_world.gd'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Bare Herobrine Trees on Surface
target1 = '''\t\t\telif gy >= 56 and gy <= 62 and gx == 0 and gz == 0:
\t\t\t\treturn BlockType.SLATE_BRICK if gy < 62 else BlockType.TORCH
\t\treturn BlockType.AIR'''

repl1 = '''\t\t\telif gy >= 56 and gy <= 62 and gx == 0 and gz == 0:
\t\t\t\treturn BlockType.SLATE_BRICK if gy < 62 else BlockType.TORCH
\t\t# Surface Bare Herobrine Trees (Stripped trunks standing in the foggy expanse)
\t\tif gy >= int(surf_h) and gy <= int(surf_h) + 5:
\t\t\tif (abs(gx) % 14 == 3) and (abs(gz) % 15 == 5) and (abs(gx) > 8 or abs(gz) > 8):
\t\t\t\treturn BlockType.HEWN_TIMBER
\t\treturn BlockType.AIR'''

# 2. 2x2 Herobrine Tunnel & Hidden Occult Crypt
target2 = '''\t\telif gy >= 11 and gy <= 16:
\t\t\tif gy == 12 and (gx == 16 or gx == 26) and (gz == -3 or gz == 3):
\t\t\t\treturn BlockType.TORCH
\t\t\treturn BlockType.AIR
\t\telif gy >= 17 and gy <= 22:
\t\t\treturn BlockType.STONE'''

repl2 = '''\t\telif gy >= 11 and gy <= 16:
\t\t\tif gy == 12 and (gx == 16 or gx == 26) and (gz == -3 or gz == 3):
\t\t\t\treturn BlockType.TORCH
\t\t\treturn BlockType.AIR
\t\telif gy >= 17 and gy <= 22:
\t\t\treturn BlockType.STONE

\t# Creepypasta Anomaly: The 2x2 Carved Mine Shaft ("Herobrine's Tunnel")
\t# Perfectly carved straight 2x2 shaft branching South from East corridor
\tif (gx == 20 or gx == 21) and gz < -3 and gz >= -36:
\t\tif gy == 10:
\t\t\treturn BlockType.COBBLESTONE
\t\telif gy == 11 or gy == 12:
\t\t\tif (gx == 20) and (gz % 10 == 0) and gy == 12:
\t\t\t\treturn BlockType.TORCH
\t\t\treturn BlockType.AIR
\t\telif gy == 13:
\t\t\treturn BlockType.DEEPSLATE

\t# Secret Crypt at the end of Herobrine's Tunnel (gz: -37 to -42, gx: 18 to 23)
\tif gx >= 18 and gx <= 23 and gz <= -37 and gz >= -42:
\t\tif gy == 10:
\t\t\treturn BlockType.SLATE_BRICK
\t\telif gy >= 11 and gy <= 14:
\t\t\tif (gx == 20 or gx == 21) and (gz == -39 or gz == -40) and gy == 11:
\t\t\t\treturn BlockType.BEDROCK
\t\t\tif gx == 20 and gz == -39 and gy == 12:
\t\t\t\treturn BlockType.TORCH
\t\t\treturn BlockType.AIR
\t\telif gy == 15:
\t\t\treturn BlockType.SLATE_BRICK'''

assert target1 in content, "Target 1 not found!"
assert target2 in content, "Target 2 not found!"

content = content.replace(target1, repl1, 1)
content = content.replace(target2, repl2, 1)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"Applied creepypasta features cleanly! New line count: {len(content.splitlines())}")
