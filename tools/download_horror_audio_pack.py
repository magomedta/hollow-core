import urllib.request
import os
import time

AUDIO_DIR = "hollow_core/audio"
os.makedirs(AUDIO_DIR, exist_ok=True)

HEADERS = {
    'User-Agent': 'HollowCoreHorrorGame/1.0 (educational gamedev open source project; contact@hollowcore.org)'
}

DOWNLOAD_TARGETS = [
    {
        "filename": "howling_wind_blizzard.ogg",
        "url": "https://upload.wikimedia.org/wikipedia/commons/2/2d/Howling_wind.ogg"
    },
    {
        "filename": "creepy_ambience_drone.ogg",
        "url": "https://upload.wikimedia.org/wikipedia/commons/0/05/Daniel_Simion_-_Creepy_Background_Sound.ogg"
    },
    {
        "filename": "distant_scream_1.wav",
        "url": "https://upload.wikimedia.org/wikipedia/commons/d/dc/Scream-c.wav"
    },
    {
        "filename": "distant_scream_2.wav",
        "url": "https://upload.wikimedia.org/wikipedia/commons/7/73/Scream-d.wav"
    },
    {
        "filename": "distant_scream_3.wav",
        "url": "https://upload.wikimedia.org/wikipedia/commons/9/92/Scream-e.wav"
    },
    {
        "filename": "phantom_footsteps_creepy.wav",
        "url": "https://upload.wikimedia.org/wikipedia/commons/a/ad/Creepy_footsteps_and_screaming_and_growl.wav"
    },
    {
        "filename": "horror_swell.wav",
        "url": "https://upload.wikimedia.org/wikipedia/commons/4/4e/Horror_swell.wav"
    }
]

print("=== DOWNLOADING AUTHENTIC HORROR AUDIO ASSETS ===")
for item in DOWNLOAD_TARGETS:
    dest_path = os.path.join(AUDIO_DIR, item["filename"])
    if os.path.exists(dest_path) and os.path.getsize(dest_path) > 1000:
        print(f"[EXISTS] {item['filename']} ({os.path.getsize(dest_path)} bytes)")
        continue
    
    print(f"[FETCHING] {item['filename']} from {item['url']}...")
    try:
        req = urllib.request.Request(item["url"], headers=HEADERS)
        with urllib.request.urlopen(req, timeout=25) as resp:
            data = resp.read()
            with open(dest_path, "wb") as f:
                f.write(data)
            print(f"[SUCCESS] {item['filename']} -> {len(data)} bytes saved.")
        time.sleep(1.0)
    except Exception as e:
        print(f"[ERROR] Failed to download {item['filename']}: {e}")

print("=== AUDIO DOWNLOAD COMPLETE ===")
