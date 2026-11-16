import base64
import os
import sys
from google import genai

sys.stdout.reconfigure(encoding='utf-8')

client = genai.Client()

print("Testing Gemini 3.8 Flash TTS in Russian...")
try:
    interaction = client.interactions.create(
        model="gemini-3.8-flash-tts",
        input=[{
            "type": "user_input",
            "content": [{
                "type": "text",
                "text": "Кто там в забое? Отзовись!",
                "annotations": [{
                    "type": "speech_metadata",
                    "style": "tense, gravelly Russian miner, deep voice, heavy breathing",
                }],
            }],
        }],
        response_format={"type": "audio"},
        generation_config={
            "speech_config": [
                {"voice": "Fenrir"},
            ]
        },
    )

    if interaction.output_audio and interaction.output_audio.data:
        audio_bytes = base64.b64decode(interaction.output_audio.data)
        out_wav = "scratch_test_gemini_tts.wav"
        with open(out_wav, "wb") as f:
            f.write(audio_bytes)
        print(f"[SUCCESS] Generated {out_wav}, size: {len(audio_bytes)} bytes!")
    else:
        print("[FAIL] No audio data in output_audio")
except Exception as e:
    print(f"[ERROR] {e}")
