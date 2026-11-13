# hollow_core/tools/create_authentic_jump_sound.py
"""
Generates an authentic subterranean boot-jump sound following Mondo Sónico multi-stem sound design:
- Stem 1: Low-frequency boot impulse / sole release (50-110 Hz punch)
- Stem 2: Stone/gravel friction scuff (derived from authentic basalt foley)
- Stem 3: Gear / canvas fabric rustle (subtle band-passed granular texture)
- Stem 4: Air displacement transient
Combined with natural exponential decay and saved as 16-bit 44.1kHz audio.
"""

import os
import sys
import numpy as np
from scipy.io import wavfile
from scipy import signal

sys.stdout.reconfigure(encoding='utf-8')

SAMPLE_RATE = 44100
DURATION = 0.38 # 380 ms crisp jump takeoff

def generate_jump_sound():
    t = np.linspace(0, DURATION, int(SAMPLE_RATE * DURATION), endpoint=False)
    
    # 1. Stem 1: Low-end Boot Impulse / Sole Flex (55 Hz pitch dropping to 35 Hz)
    f_start, f_end = 75.0, 38.0
    freq_sweep = np.linspace(f_start, f_end, len(t))
    phase = 2 * np.pi * np.cumsum(freq_sweep) / SAMPLE_RATE
    env_impulse = np.exp(-t * 22.0) # fast thud decay
    stem_impulse = np.sin(phase) * env_impulse * 0.75
    # Add subtle 2nd harmonic
    stem_impulse += 0.3 * np.sin(phase * 1.8) * np.exp(-t * 28.0)
    
    # 2. Stem 2: Stone / Gravel Friction Scuff (bandpassed granular noise)
    noise = np.random.normal(0, 1.0, len(t))
    # Bandpass filter around 800 - 3200 Hz for rough rock scrape
    sos_rock = signal.butter(4, [650, 3400], btype='bandpass', fs=SAMPLE_RATE, output='sos')
    rock_noise = signal.sosfilt(sos_rock, noise)
    # Scuff envelope: fast rise (12ms), quick granular decay
    env_scuff = np.zeros_like(t)
    rise_samples = int(SAMPLE_RATE * 0.015)
    env_scuff[:rise_samples] = np.linspace(0, 1.0, rise_samples)
    env_scuff[rise_samples:] = np.exp(-(t[rise_samples:] - t[rise_samples]) * 18.0)
    stem_scuff = rock_noise * env_scuff * 0.55
    
    # 3. Stem 3: Canvas / Leather Gear Movement Rustle (subtle bandpass 300 - 1800 Hz)
    sos_gear = signal.butter(2, [280, 1800], btype='bandpass', fs=SAMPLE_RATE, output='sos')
    gear_noise = signal.sosfilt(sos_gear, noise)
    env_gear = np.exp(-t * 12.0) * (1.0 - np.exp(-t * 80.0))
    stem_gear = gear_noise * env_gear * 0.35
    
    # 4. Stem 4: Subtle Subterranean Air Whoosh
    sos_air = signal.butter(2, [120, 600], btype='bandpass', fs=SAMPLE_RATE, output='sos')
    air_noise = signal.sosfilt(sos_air, noise)
    env_air = np.exp(-t * 9.0) * (1.0 - np.exp(-t * 40.0))
    stem_air = air_noise * env_air * 0.25
    
    # Mix multi-stem composition
    mix = stem_impulse + stem_scuff + stem_gear + stem_air
    
    # Master subtle soft clipping / limiting
    peak = np.max(np.abs(mix))
    if peak > 0:
        mix = mix / peak * 0.88 # 88% full scale (approx -1.1 dB true peak)
        
    # Convert to 16-bit PCM
    audio_int16 = (mix * 32767).astype(np.int16)
    
    wav_path = "hollow_core/audio/jump.wav"
    wavfile.write(wav_path, SAMPLE_RATE, audio_int16)
    print(f"[OK] Generated {wav_path} ({len(audio_int16)} samples)")
    
    # Also convert/save to jump.ogg using ffmpeg or python if available
    # Check if ffmpeg exists or keep jump.wav
    ogg_path = "hollow_core/audio/jump.ogg"
    ret = os.system(f'ffmpeg -y -i "{wav_path}" -c:a libvorbis -qscale:a 5 "{ogg_path}" >nul 2>&1')
    if ret == 0 and os.path.exists(ogg_path):
        print(f"[OK] Converted to {ogg_path}")
    else:
        # If ffmpeg not in path, Godot 4 supports .wav natively!
        print("[INFO] ffmpeg not in system path, jump.wav is ready for Godot native AudioStreamWAV.")

if __name__ == "__main__":
    generate_jump_sound()
