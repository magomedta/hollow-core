import sys

path = 'hollow_core/scripts/voxel_world.gd'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

out = []
skip = False
for line in lines:
    if "Creepypasta Anomaly: The 2x2 Carved Mine Tunnel" in line:
        skip = True
    if skip:
        if "return BlockType.SLATE_BRICK" in line and len(out) > 0 and "Secret Crypt" in "".join(lines[max(0, len(out)-25):len(out)+5]):
            skip = False
            continue
        elif "Grand Cathedral Cavern" in line or "5. EAST REALM" in line or "6. WEST REALM" in line or "7. NORTH REALM" in line or "8. SOUTH REALM" in line:
            skip = False
            out.append(line)
            continue
        else:
            continue
    else:
        out.append(line)

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(out)

print("Voxel world cleaned up successfully.")
