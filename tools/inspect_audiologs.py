import re
import json

with open("c:/Users/magom/Downloads/twitchst/hollow_core/scripts/narrative/audiolog_registry.gd", "r", encoding="utf-8") as f:
    text = f.read()

# Match entries
entries = re.findall(r'"(AUD-\d\d)":\s*\{([\s\S]*?)\n\t\},', text)
print(f"Total entries matched: {len(entries)}")
for aud_id, body in entries:
    title_m = re.search(r'"title":\s*"([^"]+)"', body)
    date_m = re.search(r'"date":\s*"([^"]+)"', body)
    loc_m = re.search(r'"location":\s*"([^"]+)"', body)
    trans_m = re.search(r'"transcript":\s*"([\s\S]*?)"\s*,', body)
    title = title_m.group(1) if title_m else ""
    date = date_m.group(1) if date_m else ""
    loc = loc_m.group(1) if loc_m else ""
    trans = trans_m.group(1) if trans_m else ""
    print(f"{aud_id} | {title} | {date} | {loc}")
    print(f"   Excerpt: {trans[:80]}...")
