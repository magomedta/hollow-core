# HOLLOW CORE — MILESTONE 1 (M1) HORROR IMPLEMENTATION
**Psychological Horror Director & Sound Designer**  
**Godot Engine 4.7+ Forward+ (Vulkan 1.4, Windows 64-bit)**  
**Version:** 1.0  

---

## 1. THE SILENT DIRECTOR & DREAD PHILOSOPHY

The psychological horror of Hollow Core operates on two fundamental rules:
1. **Never Show the Numbers:** No sanity bars, skull icons, or warning banners. Fear is conveyed through perceptual uncertainty: *"Did I actually hear that, or was it an echo?"*
2. **Desensitization Prevention:** Constant scares fatigue the nervous system. The `AnomalyDirector` enforces 3- to 5-minute cooldowns between major psychoacoustic incidents and provides absolute silence in Safe Pockets.

---

## 2. ANOMALY EV-01: «ЗАПАЗДЫВАЮЩИЕ ШАГИ» (DELAYED FOOTSTEPS)

### Category:
Category 2 — Psychoacoustic Distortion.

### Trigger Logic:
- The player moves (walks or sprints) continuously for at least $3.2$ seconds outside safe refuges.
- The player comes to an abrupt halt (`velocity.length() < 0.2`).
- A delayed timer of **$0.38$ seconds (380 ms)** begins.

### Execution:
- Exactly 380 ms after the player stops, two heavy, distinct footsteps play on damp slate directly **2.4 meters behind the player's back**.
- The second footstep lands 280 ms after the first, slightly closer, then abruptly vanishes into dead silence.
- If the player spins around immediately, the tunnel is completely empty.

### Cooldown:
180 to 240 seconds.

---

## 3. ANOMALY EV-02: «ЧЕТВЕРТЫЙ УДАР» (THE FOURTH STRIKE)

### Category:
Category 2 — Lithic Acoustic Anomaly.

### Trigger Logic:
- The player strikes a solid rock face with the pickaxe exactly 3 consecutive times within $2.8$ seconds.
- The player pauses and stops striking.
- A delay timer of **$1.80$ seconds** begins.

### Execution:
- Exactly 1.8 seconds after the 3rd hit, a sharp, metallic/lithic strike echoes back from **1.2 meters deep inside the solid rock monolith** ahead.
- The sound is pitched down slightly (-4 semitones) with a ringing subterranean acoustic decay.
- If the player is standing within 8 meters, the camera experiences a subtle subterranean shudder (`apply_subterranean_shudder(0.20, 0.8)`).

### Cooldown:
220 to 310 seconds.

---

## 4. SAFETY POCKETS: THE PSYCHOLOGICAL VALUE OF REFUGE

The Abandoned Camp (Zone D) is registered as an active `SafeZone` with an AABB bounding volume:
- Inside this perimeter, all anomaly timers are suspended.
- The ambient audio cross-fades into the quiet crackle of embers and distant, rhythmic water drops.
- This creates contrast: the player relaxes, lowers their guard, and feels safe, making subsequent excursions into the dark Echo Shaft significantly more tense.

---

## 5. LITHIC RESONANCE: HISTORICAL SOUND TRAILS

In addition to EV-01 and EV-02, `SoundMemoryManager` continuously monitors player acoustic emissions:
- Player pickaxe impacts and running footsteps are recorded into a 128-event ring buffer.
- When traversing dead-end tunnels, candidate footsteps recorded 10 to 30 seconds prior are played back with rock damping attenuation (-6 dB) and spatial offset behind the player.
- The player's own past noise becomes the ghost that haunts them.
