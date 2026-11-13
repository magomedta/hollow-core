# HOLLOW CORE — M1 ACOUSTICS & LITHOACOUSTIC MEMORY
**Document ID:** `DOC-M1-BIO-04`

---

## 1. Subterranean Acoustic Stratification

Acoustics are core to both gameplay navigation and psychological dread:

| Biome ID | Reverb Decay Time | Damping Factor | Acoustic Absorption | Primary Footstep Sound |
| :--- | :--- | :--- | :--- | :--- |
| **Glacial Spires** | 1.8 seconds | 0.40 | 0.25 | Crisp high-pitch ice crunch (`pitch = 1.25`) |
| **Flooded Sluice Gates**| 2.8 seconds | 0.45 | 0.30 | Damp brick strike / Sloshing water wading (`pitch = 0.72`)|
| **Basaltic Abyssal** | 4.8 seconds | 0.35 | 0.18 | Deep resonant basalt reverberation (`pitch = 0.95`)|

---

## 2. Lithoacoustic Memory (`SoundMemoryManager`)

The rock remembers physical vibrations. Physical player actions are recorded into a circular ring buffer (`MAX_RING_BUFFER = 128`):
- **Footsteps (`step`):** Replayed 3.5 to 45 seconds later, spatially localized behind the player.
- **Pickaxe Hits (`pickaxe_hit`):** Replayed inside the rock wall with slight pitch dispersion.
- **Dynamic Reverb Integration:** When the player enters a new biome, `BiomeManager` immediately invokes `sound_memory_manager.set_reverb_parameters(reverb_time, damping)`, scaling the acoustic space dynamically.

---

## 3. Disentanglement of Psychological Micro-Anomalies

1. **EV-01: Запаздывающие Шаги (Delayed Footsteps)**
   - Managed strictly by `AnomalyDirector` (`EV01_MIN_COOLDOWN = 180s`).
   - Triggers when the player runs for $> 3.2\text{s}$ and suddenly halts.
   - After a 380ms silence, 2 heavy footsteps on stone occur 2.4 meters directly behind the player.
2. **EV-02: Четвёртый Удар Кирки (Fourth Strike Echo)**
   - Managed strictly by `AnomalyDirector` (`EV02_MIN_COOLDOWN = 220s`).
   - When the player strikes stone exactly 3 times consecutively, a sharp 4th strike rings out from deep inside the stone face 1.8 seconds later.
3. **APP-01: Наблюдатель на Краю Бездны (The Watcher at the Chasm Brink)**
   - Managed independently by `TheWatcher` / `M1LevelManager`.
   - Distinct entity apparition with piercing white eyes standing silently in the fog.
