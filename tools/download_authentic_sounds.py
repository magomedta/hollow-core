"""
Downloads authentic, high-quality audio files from open public repositories (Minetest CC0/LGPL, Kenney CC0, Wikimedia Commons CC0/CC-BY).
Saves directly into hollow_core/audio/.
"""
import os
import sys
import time
import urllib.request

sys.stdout.reconfigure(encoding='utf-8')

AUDIO_DIR = "hollow_core/audio"
os.makedirs(AUDIO_DIR, exist_ok=True)

HEADERS = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) HollowCoreAudio/1.0'}

SOUNDS = {
    # Footsteps (authentic stone and gravel foley)
    "footstep_stone_1.ogg": "https://raw.githubusercontent.com/minetest/minetest_game/master/mods/default/sounds/default_hard_footstep.1.ogg",
    "footstep_stone_2.ogg": "https://raw.githubusercontent.com/minetest/minetest_game/master/mods/default/sounds/default_hard_footstep.2.ogg",
    "footstep_stone_3.ogg": "https://raw.githubusercontent.com/minetest/minetest_game/master/mods/default/sounds/default_hard_footstep.3.ogg",
    "footstep_gravel_1.ogg": "https://raw.githubusercontent.com/minetest/minetest_game/master/mods/default/sounds/default_gravel_footstep.1.ogg",
    "footstep_gravel_2.ogg": "https://raw.githubusercontent.com/minetest/minetest_game/master/mods/default/sounds/default_gravel_footstep.2.ogg",
    "footstep_gravel_3.ogg": "https://raw.githubusercontent.com/minetest/minetest_game/master/mods/default/sounds/default_gravel_footstep.3.ogg",

    # Mining & Block destruction
    "pickaxe_stone_1.ogg": "https://raw.githubusercontent.com/minetest/minetest_game/master/mods/default/sounds/default_dig_cracky.1.ogg",
    "pickaxe_stone_2.ogg": "https://raw.githubusercontent.com/minetest/minetest_game/master/mods/default/sounds/default_dig_cracky.2.ogg",
    "pickaxe_stone_3.ogg": "https://raw.githubusercontent.com/minetest/minetest_game/master/mods/default/sounds/default_dig_cracky.3.ogg",
    "block_break_1.ogg": "https://raw.githubusercontent.com/minetest/minetest_game/master/mods/default/sounds/default_dug_node.1.ogg",
    "block_break_2.ogg": "https://raw.githubusercontent.com/minetest/minetest_game/master/mods/default/sounds/default_dug_node.2.ogg",
    "block_place.ogg": "https://raw.githubusercontent.com/minetest/minetest_game/master/mods/default/sounds/default_place_node_hard.1.ogg",

    # Movement & Interaction
    "jump.ogg": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-3D-Platformer/main/sounds/jump.ogg",
    "land.ogg": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-3D-Platformer/main/sounds/land.ogg",
    "item_pickup.ogg": "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-3D-Platformer/main/sounds/coin.ogg",
    "player_hurt.ogg": "https://raw.githubusercontent.com/minetest/minetest_game/master/mods/default/sounds/player_damage.ogg",
    "explosion.ogg": "https://raw.githubusercontent.com/minetest/minetest_game/master/mods/tnt/sounds/tnt_explode.ogg",

    # Lantern & UI mechanical clicks
    "lantern_click.ogg": "https://upload.wikimedia.org/wikipedia/commons/4/4b/Rusty_metal_door_clasp_02.ogg",

    # Horror Ambiance & Atmospheric Audio
    "cavern_wind.ogg": "https://upload.wikimedia.org/wikipedia/commons/2/2d/Howling_wind.ogg",
    "horror_drone.ogg": "https://upload.wikimedia.org/wikipedia/commons/c/c2/John_Bartmann_-_dark-basement-master.ogg",
    "heartbeat.ogg": "https://upload.wikimedia.org/wikipedia/commons/7/75/Heartbeat.ogg",

    # Monster cries / growls
    "monster_growl_1.ogg": "https://upload.wikimedia.org/wikipedia/commons/7/71/Monster_growls.ogg",
    "monster_growl_2.ogg": "https://upload.wikimedia.org/wikipedia/commons/3/36/Monster_growls_2.ogg"
}

def download_all():
    print(f"Downloading {len(SOUNDS)} authentic audio files into {AUDIO_DIR}...")
    success = 0
    for name, url in SOUNDS.items():
        dest = os.path.join(AUDIO_DIR, name)
        try:
            req = urllib.request.Request(url, headers=HEADERS)
            with urllib.request.urlopen(req, timeout=12) as resp:
                data = resp.read()
                with open(dest, "wb") as f:
                    f.write(data)
                print(f"  [OK] {name} ({len(data)} bytes)")
                success += 1
            time.sleep(0.3)
        except Exception as e:
            print(f"  [FAIL] {name} from {url}: {e}")

    print(f"Finished: {success}/{len(SOUNDS)} audio files downloaded.")

if __name__ == "__main__":
    download_all()
