import pyttsx3
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

engine = pyttsx3.init()
voices = engine.getProperty('voices')
ru_voice = None
for v in voices:
    if "RU" in v.id.upper() or "IRINA" in v.id.upper():
        ru_voice = v.id
        break

print("Found Russian voice:", ru_voice)
if ru_voice:
    engine.setProperty('voice', ru_voice)
    engine.setProperty('rate', 140) # Slower, dramatic pacing
    engine.setProperty('volume', 1.0)
    out_wav = "scratch_test_pyttsx3.wav"
    engine.save_to_file("Кто там в забое? Отзовись!", out_wav)
    engine.runAndWait()
    if os.path.exists(out_wav):
        print(f"[SUCCESS] pyttsx3 generated {out_wav}, size: {os.path.getsize(out_wav)} bytes!")
    else:
        print("[FAIL] File not found")
else:
    print("[FAIL] No Russian voice found")
