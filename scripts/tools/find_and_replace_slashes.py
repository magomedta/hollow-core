# hollow_core/scripts/tools/find_and_replace_slashes.py
import os
import glob
import re

gd_files = glob.glob('hollow_core/scripts/**/*.gd', recursive=True) + glob.glob('hollow_core/*.gd')

replacements_count = 0
touched_files = set()

for path in gd_files:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # We want to replace " // " or " //" in user-facing UI text strings with " — "
    # But PRESERVE:
    # 1. "res://"
    # 2. "user://"
    # 3. "http://" and "https://"
    # 4. GDScript comments (e.g. # or // if any, though GDScript uses #)

    # Let's inspect line by line
    lines = content.split('\n')
    new_lines = []
    file_modified = False

    for line in lines:
        # Check if line contains a string literal with //
        if '//' in line and 'res://' not in line and 'user://' not in line and 'http://' not in line and 'https://' not in line:
            # Replace ' // ' in strings with ' — '
            new_line = line.replace(' // ', ' — ').replace(' //', ' — ').replace('// ', '— ')
            if new_line != line:
                file_modified = True
                replacements_count += 1
                new_lines.append(new_line)
                continue
        new_lines.append(line)

    if file_modified:
        with open(path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(new_lines))
        touched_files.add(path)

print(f"Replaced {replacements_count} occurrences of '//' across {len(touched_files)} files.")
for f in touched_files:
    print("  Modified:", f)
