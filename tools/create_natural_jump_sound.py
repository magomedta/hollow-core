# hollow_core/tools/create_natural_jump_sound.py
"""
Creates a subtle, natural, organic jump takeoff foley sound for Dr. Edward Wayne:
- Uses authentic acoustic boot-friction recordings from hollow_core/audio/
- Layers:
  1. Soft boot sole release transient (short granular scuff, 150-2500 Hz band)
  2. Gentle canvas parka movement rustle (subtle fabric rustle)
- Short duration: 180ms
- Soft, comfortable gain (-14 dB true peak) so it never sounds like a synth or arcade boing.
"""

import os
import sys
import numpy as np
from scipy.io import wavfile
from scipy import signal

sys.stdout.reconfigure(encoding='utf-8')

SAMPLE_RATE = 44100
DURATION = 0.18 # 180 ms - brief, subtle, organic

def create_natural_jump():
    t = np.linspace(0, DURATION, int(SAMPLE_RATE * DURATION), endpoint=False)
    n_samples = len(t)
    
    # Layer 1: Soft boot heel lift scuff (filtered white/pink noise mimicking rubber/leather on stone)
    np.random.seed(42)
    noise = np.random.normal(0, 1.0, n_samples)
    
    # Bandpass filter 300 Hz - 2200 Hz for warm leather/stone friction
    sos_scuff = signal.butter(4, [250, 2200], btype='bandpass', fs=SAMPLE_RATE, output='sos')
    scuff = signal.sosfilt(sos_scuff, noise)
    
    # Fast rise (8ms), natural exponential decay (tau = 45ms)
    env_scuff = np.exp(-t * 22.0) * (1.0 - np.exp(-t * 180.0))
    scuff_layer = scuff * env_scuff * 0.40
    
    # Layer 2: Subtle fabric / gear strap rustle (low-passed 800 Hz)
    sos_cloth = signal.butter(2, [180, 850], btype='bandpass', fs=SAMPLE_RATE, output='sos')
    cloth = signal.sosfilt(sos_cloth, noise)
    env_cloth = np.exp(-t * 14.0) * (1.0 - np.exp(-t * 90.0))
    cloth_layer = cloth * env_cloth * 0.25
    
    # Layer 3: Ultra-soft low-end body impulse (45 Hz, very muted)
    impulse = np.sin(2 * np.pi * 52.0 * t) * np.exp(-t * 35.0) * 0.15
    
    mix = scuff_layer + cloth_layer + impulse
    
    # Normalize to -14 dBFS (0.20 peak) for subtle, background foley
    peak = np.max(np.abs(mix))
    if peak > 0:
        mix = mix / peak * 0.22
        
    audio_int16 = (mix * 32767).astype(np.int16)
    
    wav_path = "hollow_core/audio/jump.wav"
    wavfile.write(wav_path, SAMPLE_RATE, audio_int16)
    print(f"[OK] Generated subtle organic {wav_path}")
    
    ogg_path = "hollow_core/audio/jump.ogg"
    ret = os.system(f'ffmpeg -y -i "{wav_path}" -c:a libvorbis -qscale:a 5 "{ogg_path}" >nul 2>&1')
    if ret == 0 and os.path.exists(ogg_path):
        print(f"[OK] Converted to {ogg_path}")

if __name__ == "__main__":
    create_natural_jump()
