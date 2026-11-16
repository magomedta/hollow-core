import os
import math
import numpy as np
from scipy.io import wavfile
import subprocess

SAMPLE_RATE = 44100
OUT_DIR = r"c:\Users\magom\Downloads\twitchst\hollow_core\audio\audiologs"
os.makedirs(OUT_DIR, exist_ok=True)

def apply_reverb(sig, sr=44100, delays=[0.08, 0.15, 0.28, 0.42, 0.65], decays=[0.55, 0.45, 0.35, 0.25, 0.15]):
    out = np.copy(sig)
    for d, c in zip(delays, decays):
        d_samples = int(d * sr)
        if d_samples < len(sig):
            out[d_samples:] += sig[:-d_samples] * c
    return out

def vinyl_noise(n_samples, sr=44100, crackle_prob=0.0008, hum_level=0.04):
    t = np.arange(n_samples) / sr
    # Low rumble & tape hiss
    hiss = np.random.normal(0, 0.015, n_samples)
    hum = hum_level * np.sin(2 * np.pi * 50.0 * t) + (hum_level * 0.4) * np.sin(2 * np.pi * 100.0 * t)
    
    # Scratches and pops
    pops = np.zeros(n_samples)
    rand_vals = np.random.rand(n_samples)
    mask = rand_vals < crackle_prob
    pops[mask] = np.random.uniform(-0.4, 0.4, np.sum(mask))
    # Pop decay filter
    pop_kernel = np.exp(-np.linspace(0, 10, int(sr * 0.005)))
    pops = np.convolve(pops, pop_kernel, mode='same')
    
    return hiss + hum + pops

def generate_footsteps(n_samples, times, sr=44100, is_water=False):
    sig = np.zeros(n_samples)
    dur = 0.18 if is_water else 0.12
    step_len = int(dur * sr)
    t = np.arange(step_len) / sr
    
    for st in times:
        idx = int(st * sr)
        if idx + step_len >= n_samples:
            continue
        
        # Thud + crunch
        thud = np.sin(2 * np.pi * np.random.uniform(70, 120) * t) * np.exp(-t * 30.0)
        crunch = np.random.normal(0, 0.3, step_len) * np.exp(-t * 25.0)
        
        if is_water:
            # Add high frequency water splash
            splash = np.sin(2 * np.pi * np.random.uniform(400, 1200) * t) * np.random.normal(0, 0.4, step_len) * np.exp(-t * 18.0)
            step_sound = (thud * 0.5 + crunch * 0.3 + splash * 0.5)
        else:
            step_sound = (thud * 0.6 + crunch * 0.4)
            
        sig[idx:idx + step_len] += step_sound * np.random.uniform(0.7, 1.0)
        
    return apply_reverb(sig, sr)

def generate_metallic_hit(n_samples, st, sr=44100, fundamental=160.0, intensity=1.0):
    sig = np.zeros(n_samples)
    dur = 1.8
    hit_len = int(dur * sr)
    t = np.arange(hit_len) / sr
    idx = int(st * sr)
    if idx + hit_len >= n_samples:
        return sig
        
    # Non-harmonic metallic partials
    partials = [1.0, 1.48, 2.14, 2.89, 4.12, 5.7]
    decay_rates = [4.0, 6.0, 9.0, 12.0, 16.0, 22.0]
    metal = np.zeros(hit_len)
    for p, d in zip(partials, decay_rates):
        metal += np.sin(2 * np.pi * (fundamental * p) * t) * np.exp(-t * d)
    
    # Impact transient
    transient = np.random.normal(0, 0.8, int(0.02 * sr)) * np.exp(-np.linspace(0, 10, int(0.02 * sr)))
    metal[:len(transient)] += transient
    
    sig[idx:idx + hit_len] = metal * intensity
    return apply_reverb(sig, sr, delays=[0.12, 0.25, 0.45], decays=[0.6, 0.4, 0.25])

def generate_subterranean_drone(n_samples, sr=44100, freq=11.4):
    t = np.arange(n_samples) / sr
    # Low frequency rumble + slow beating
    drone = 0.3 * np.sin(2 * np.pi * freq * t)
    drone += 0.2 * np.sin(2 * np.pi * (freq * 2.0 + 0.3) * t)
    drone += 0.15 * np.sin(2 * np.pi * (freq * 3.0) * t) * (0.8 + 0.2 * np.sin(2 * np.pi * 0.15 * t))
    # Cavern wind noise (low pass filtered noise)
    noise = np.random.normal(0, 0.1, n_samples)
    wind_kernel = np.exp(-np.linspace(0, 8, int(sr * 0.05)))
    wind = np.convolve(noise, wind_kernel, mode='same') * (0.6 + 0.4 * np.sin(2 * np.pi * 0.08 * t))
    return drone + wind

def generate_heavy_breathing(n_samples, times, sr=44100, panic=False):
    sig = np.zeros(n_samples)
    for t_start in times:
        dur = 0.7 if panic else 1.2
        b_len = int(dur * sr)
        t = np.arange(b_len) / sr
        idx = int(t_start * sr)
        if idx + b_len >= n_samples:
            continue
        # Inhale: rising filtered noise
        inhale_len = int(b_len * 0.45)
        t_in = t[:inhale_len]
        env_in = np.sin(np.pi * t_in / t_in[-1]) ** 1.5
        noise_in = np.random.normal(0, 0.25, inhale_len) * env_in
        # Bandpass shaping for throat breath
        breath = np.zeros(b_len)
        breath[:inhale_len] = noise_in
        
        # Exhale: longer falling noise
        ex_len = b_len - inhale_len
        t_ex = np.arange(ex_len) / sr
        env_ex = np.sin(np.pi * t_ex / t_ex[-1]) ** 1.8
        noise_ex = np.random.normal(0, 0.35, ex_len) * env_ex
        breath[inhale_len:] = noise_ex
        
        sig[idx:idx + b_len] += breath * (1.2 if panic else 0.7)
    return sig

def generate_creature_howl(n_samples, st, dur=3.2, sr=44100):
    sig = np.zeros(n_samples)
    h_len = int(dur * sr)
    t = np.arange(h_len) / sr
    idx = int(st * sr)
    if idx + h_len >= n_samples:
        return sig
    # Distorted descending pitch glide with throat rasp
    f_start = 450.0
    f_end = 120.0
    freqs = f_start * (f_end / f_start) ** (t / dur)
    phase = 2 * np.pi * np.cumsum(freqs) / sr
    base_cry = np.sin(phase) + 0.4 * np.sin(2 * phase) + 0.2 * np.sin(3 * phase)
    # Rasp noise
    rasp = np.random.normal(0, 0.35, h_len) * np.sin(phase * 0.5)
    env = np.sin(np.pi * (t / dur)) ** 1.2
    cry = (base_cry * 0.6 + rasp * 0.4) * env
    sig[idx:idx + h_len] = cry
    return apply_reverb(sig, sr, delays=[0.25, 0.5, 0.85, 1.2], decays=[0.7, 0.5, 0.35, 0.2])

def save_and_convert(name, audio_data, sr=44100):
    # Normalize with headroom
    max_val = np.max(np.abs(audio_data))
    if max_val > 0:
        audio_data = (audio_data / max_val) * 0.92
    wav_path = os.path.join(OUT_DIR, f"{name}.wav")
    ogg_path = os.path.join(OUT_DIR, f"{name}.ogg")
    
    # Save 16-bit PCM WAV
    wavfile.write(wav_path, sr, (audio_data * 32767).astype(np.int16))
    
    # Convert to OGG Vorbis with ffmpeg
    cmd = f'ffmpeg -y -i "{wav_path}" -c:a libvorbis -q:a 5 "{ogg_path}"'
    subprocess.run(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    if os.path.exists(wav_path):
        os.remove(wav_path)
    print(f"Generated {ogg_path} ({os.path.getsize(ogg_path)} bytes)")

# ====================================================================
# BUILD 9 CANONICAL MINECRAFT-STYLE HORROR DISCS
# ====================================================================

# 1. AUD-01: Шурф №4 — Затопление (Rising water, panicked sloshing, metallic buckling)
dur = 14.0
n = int(dur * SAMPLE_RATE)
sig = vinyl_noise(n) + generate_subterranean_drone(n, freq=11.4)
sig += generate_heavy_breathing(n, [1.0, 3.2, 5.5, 7.8, 9.2, 10.5, 11.8], panic=True)
water_steps = [2.0, 2.8, 3.5, 4.1, 4.7, 5.2, 5.7, 6.2, 6.6, 7.0, 7.4, 7.8, 8.2]
sig += generate_footsteps(n, water_steps, is_water=True)
sig += generate_metallic_hit(n, 5.8, fundamental=95.0, intensity=1.2) # Iron bulkhead buckled
sig += generate_metallic_hit(n, 8.5, fundamental=140.0, intensity=0.9)
# Rushing water roar at end
t = np.arange(n) / SAMPLE_RATE
water_rush = np.random.normal(0, 0.4, n) * (1.0 / (1.0 + np.exp(-(t - 9.0) * 1.5)))
sig += water_rush * 0.6
save_and_convert("AUD-01", sig)

# 2. AUD-02: Сейсмограмма 1894 (Mechanical ticking, 3 deliberate cavernous thuds... long pause... monstrous 4th thud)
dur = 15.0
n = int(dur * SAMPLE_RATE)
sig = vinyl_noise(n, crackle_prob=0.0012) + generate_subterranean_drone(n, freq=7.0)
# Seismograph clockwork ticking (0.5s intervals)
for tick_t in np.arange(0.5, 14.0, 0.5):
    idx = int(tick_t * SAMPLE_RATE)
    sig[idx:idx+int(0.01*SAMPLE_RATE)] += np.sin(2 * np.pi * 1800 * np.linspace(0, 0.01, int(0.01*SAMPLE_RATE))) * 0.15
# The 3 deliberate strikes from the rock (EV-02 canon)
sig += generate_metallic_hit(n, 2.5, fundamental=65.0, intensity=1.0)
sig += generate_metallic_hit(n, 4.2, fundamental=65.0, intensity=1.1)
sig += generate_metallic_hit(n, 5.9, fundamental=65.0, intensity=1.2)
# Silence & tension: 6.0 to 9.5s
# The horrific 4th thud answering from the abyss:
sig += generate_metallic_hit(n, 9.8, fundamental=42.0, intensity=1.8) # Earth-shaking
sig += generate_creature_howl(n, 10.2, dur=3.5) * 0.5
save_and_convert("AUD-02", sig)

# 3. AUD-03: Лагерь геологов — Последняя смена (Camp radio static, running steps, tent rip, 11.4Hz hum, dropped mic)
dur = 16.0
n = int(dur * SAMPLE_RATE)
sig = vinyl_noise(n) + generate_subterranean_drone(n, freq=11.4)
# Radio static burst
t = np.arange(n) / SAMPLE_RATE
radio_burst = np.random.normal(0, 0.3, n) * np.sin(2 * np.pi * 3200 * t) * (np.exp(-((t - 2.0) / 0.8)**2) + np.exp(-((t - 6.5) / 0.5)**2))
sig += radio_burst * 0.5
# Panicked running footsteps approaching
run_steps = [3.0, 3.4, 3.75, 4.1, 4.4, 4.7, 5.0, 5.25, 5.5, 5.75, 6.0, 6.2, 6.4]
sig += generate_footsteps(n, run_steps, is_water=False)
sig += generate_heavy_breathing(n, [3.2, 4.8, 6.2, 7.5, 8.8, 10.0], panic=True)
# Resonant 11.4 Hz psychic swell
swell = np.sin(2 * np.pi * 11.4 * t) * (1.0 / (1.0 + np.exp(-(t - 7.5) * 2.0)))
sig += swell * 0.8
# Violent mic drop impact at 11.2s
sig += generate_metallic_hit(n, 11.2, fundamental=210.0, intensity=1.5)
# Fading silence with deep hum
sig[int(11.5 * SAMPLE_RATE):] *= 0.35
save_and_convert("AUD-03", sig)

# 4. AUD-04: Эхолокация Шурфа Эха (Hammer strike on basalt, endless eerie cavern echo, answered by wall scuttling)
dur = 13.0
n = int(dur * SAMPLE_RATE)
sig = vinyl_noise(n) + generate_subterranean_drone(n, freq=14.0)
# Strike 1
sig += generate_metallic_hit(n, 1.5, fundamental=520.0, intensity=1.3)
# Strike 2
sig += generate_metallic_hit(n, 4.8, fundamental=520.0, intensity=1.3)
# Scuttling claws / rock chips cascading down chasm
scuttle_times = np.random.uniform(6.5, 10.5, 30)
sig += generate_footsteps(n, scuttle_times) * 0.4
# Low eerie presence breathing close to recorder
sig += generate_heavy_breathing(n, [7.2, 9.4, 11.0], panic=False) * 1.3
save_and_convert("AUD-04", sig)

# 5. AUD-06: Насосная станция «Феникс» (Heavy steam piston chug, metallic grind, catastrophic pressure blowout)
dur = 14.0
n = int(dur * SAMPLE_RATE)
sig = vinyl_noise(n)
# Rhythmic steam piston chugs (every 0.75s from 0 to 8s)
for chug_t in np.arange(0.5, 8.0, 0.75):
    idx = int(chug_t * SAMPLE_RATE)
    c_len = int(0.25 * SAMPLE_RATE)
    t_c = np.arange(c_len) / SAMPLE_RATE
    chug = np.sin(2 * np.pi * 55 * t_c) * np.exp(-t_c * 12.0) + np.random.normal(0, 0.25, c_len) * np.exp(-t_c * 18.0)
    sig[idx:idx + c_len] += chug * 0.9
# High pressure steam hiss building up
t = np.arange(n) / SAMPLE_RATE
steam = np.random.normal(0, 0.35, n) * (1.0 / (1.0 + np.exp(-(t - 6.0) * 1.8)))
sig += steam * 0.5
# Catastrophic blowout / shriek at 8.8s
sig += generate_metallic_hit(n, 8.8, fundamental=110.0, intensity=2.0)
sig += generate_metallic_hit(n, 9.0, fundamental=340.0, intensity=1.4)
# Steam dying out, dripping water
drips = [10.2, 10.8, 11.5, 12.1, 12.9]
sig += generate_footsteps(n, drips, is_water=True) * 0.3
save_and_convert("AUD-06", sig)

# 6. AUD-07: Сейф Синдиката — Мыс Безмолвия (Shortwave radio static, morse carrier chirp, deep abyss resonance)
dur = 15.0
n = int(dur * SAMPLE_RATE)
sig = vinyl_noise(n) + generate_subterranean_drone(n, freq=11.4)
t = np.arange(n) / SAMPLE_RATE
# Military carrier frequency & Morse code chirps
morse_t = [1.2, 1.5, 1.8, 2.4, 2.7, 3.5, 3.8, 4.1, 5.0, 5.3, 6.2, 6.5, 6.8]
for mt in morse_t:
    idx = int(mt * SAMPLE_RATE)
    m_len = int(0.12 * SAMPLE_RATE)
    t_m = np.arange(m_len) / SAMPLE_RATE
    sig[idx:idx + m_len] += np.sin(2 * np.pi * 880 * t_m) * 0.35
# Subterranean distortion sweep
sweep = np.sin(2 * np.pi * (200 + 150 * np.sin(2 * np.pi * 0.2 * t)) * t) * 0.15
sig += sweep
# Radio interference bursts
sig += np.random.normal(0, 0.4, n) * (np.sin(2 * np.pi * 0.4 * t) ** 4) * 0.3
# Faint distorted garble
sig += generate_creature_howl(n, 9.0, dur=4.0) * 0.25
save_and_convert("AUD-07", sig)

# 7. AUD-09: Крушение клети ТяжМаш-4 (Cable snapping gunshot, screaming fall through shaft, horrific metal impact)
dur = 13.0
n = int(dur * SAMPLE_RATE)
sig = vinyl_noise(n)
# Cable straining hum
t = np.arange(n) / SAMPLE_RATE
sig += np.sin(2 * np.pi * 220 * t) * np.exp(-t * 0.4) * 0.3
# Violent cable snap at 2.1s (like a cannon shot)
sig += generate_metallic_hit(n, 2.1, fundamental=80.0, intensity=2.5)
# Screaming freefall wind rushing past cage (2.2s to 6.5s)
fall_wind = np.random.normal(0, 0.5, n) * (1.0 / (1.0 + np.exp(-(t - 2.5) * 3.0))) * (1.0 / (1.0 + np.exp((t - 6.5) * 3.0)))
sig += fall_wind * 0.8
# Panicked gasp
sig += generate_heavy_breathing(n, [2.8, 4.2, 5.5], panic=True) * 1.5
# Massive impact at 6.6s
sig += generate_metallic_hit(n, 6.6, fundamental=50.0, intensity=3.0)
sig += generate_metallic_hit(n, 6.8, fundamental=120.0, intensity=2.0)
sig += generate_metallic_hit(n, 7.1, fundamental=240.0, intensity=1.5)
# Agonized breathing in dust & silence
sig += generate_heavy_breathing(n, [8.5, 10.2, 11.8], panic=True) * 0.8
save_and_convert("AUD-09", sig)

# 8. AUD-10: Инструктаж по безопасности (Rhythmic acoustic metronome at 11.4 bpm, psychic resonance feedback)
dur = 16.0
n = int(dur * SAMPLE_RATE)
sig = vinyl_noise(n) + generate_subterranean_drone(n, freq=11.4)
# Metronome clicking at 11.4 bpm (every ~0.95s)
for click_t in np.arange(0.8, 14.5, 0.95):
    idx = int(click_t * SAMPLE_RATE)
    c_len = int(0.015 * SAMPLE_RATE)
    t_c = np.arange(c_len) / SAMPLE_RATE
    sig[idx:idx + c_len] += np.sin(2 * np.pi * 1200 * t_c) * np.exp(-t_c * 300.0) * 0.3
# Rising dissonant harmonic tones (binaural beats causing unease)
t = np.arange(n) / SAMPLE_RATE
binaural = np.sin(2 * np.pi * 300 * t) * 0.15 + np.sin(2 * np.pi * 311.4 * t) * 0.15
sig += binaural * (t / dur)
# Unearthly whispering chorus in background
whisper = np.random.normal(0, 0.15, n) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.8 * t)) * (t / dur)
sig += whisper * 0.4
save_and_convert("AUD-10", sig)

# 9. AUD-18: Эдвард Вейн — Горизонт 1414м (Boots crunching on ice, lantern rattling, flare striking, distant cry)
dur = 16.0
n = int(dur * SAMPLE_RATE)
sig = vinyl_noise(n) + generate_subterranean_drone(n, freq=14.0)
# Crunching footsteps on glacial permafrost
ice_steps = [1.2, 2.0, 2.7, 3.5, 4.2, 5.0, 5.8, 8.5, 9.2, 10.0, 10.8]
sig += generate_footsteps(n, ice_steps, is_water=False) * 0.8
# Lantern brass rattling with each step
for st in ice_steps:
    idx = int(st * SAMPLE_RATE) + int(0.05 * SAMPLE_RATE)
    if idx + int(0.1 * SAMPLE_RATE) < n:
        sig[idx:idx + int(0.1 * SAMPLE_RATE)] += np.sin(2 * np.pi * 2400 * np.linspace(0, 0.1, int(0.1 * SAMPLE_RATE))) * np.exp(-np.linspace(0, 20, int(0.1 * SAMPLE_RATE))) * 0.08
# Flare striker scraping and hissing at 6.2s (FZZZZZ)
f_idx = int(6.2 * SAMPLE_RATE)
f_len = int(3.5 * SAMPLE_RATE)
t_f = np.arange(f_len) / SAMPLE_RATE
flare = np.random.normal(0, 0.4, f_len) * np.exp(-t_f * 0.4)
sig[f_idx:f_idx + f_len] += flare * 0.7
# Distant unnatural cry echoing across the icy void at 11.5s
sig += generate_creature_howl(n, 11.5, dur=3.8) * 0.7
# Heavy ragged breathing
sig += generate_heavy_breathing(n, [1.5, 3.8, 6.0, 8.2, 11.0, 13.2], panic=False)
save_and_convert("AUD-18", sig)

print("All 9 Minecraft-style horror discs generated successfully!")
