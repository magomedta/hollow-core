# HOLLOW CORE — M1 BIOME LIGHTING & VOLUMETRIC FOG SPECIFICATION
**Document ID:** `DOC-M1-BIO-03`

---

## 1. Environmental Lighting Stratification

Lighting in Hollow Core adheres strictly to the **Anti-AI-UI & Restraint Guidelines**: zero rainbow clutter, zero garish neon; instead, lighting is grounded, muted, and psychologically tense.

| Stratum / Biome | Ambient Light Color | Ambient Energy | Volumetric Fog Color | Fog Density | Tone Mapper Exposure |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Glacial Spires** | `Color(0.20, 0.26, 0.34)` (Pale Ice) | 0.35 | `Color(0.18, 0.22, 0.28)` | 0.024 | 1.15 |
| **Flooded Sluice Gates**| `Color(0.16, 0.14, 0.12)` (Warm Sepia)| 0.32 | `Color(0.14, 0.13, 0.12)` | 0.028 | 1.15 |
| **Basaltic Abyssal** | `Color(0.08, 0.09, 0.14)` (Deep Indigo)| 0.28 | `Color(0.06, 0.07, 0.10)` | 0.016 | 1.15 |

---

## 2. Dynamic Continuous Atmospheric Blending

The `BiomeManager` calculates smooth interpolations between strata using the `blend_margin` parameter (4.0 meters):
```gdscript
var t = clamp(delta * smooth_transition_speed, 0.0, 1.0)
env.ambient_light_color = env.ambient_light_color.lerp(blend_params.ambient_color, t)
env.ambient_light_energy = lerp(env.ambient_light_energy, blend_params.ambient_energy, t)
env.fog_light_color = env.fog_light_color.lerp(blend_params.fog_color, t)
env.fog_density = lerp(env.fog_density, blend_params.fog_density, t)
```
This guarantees that descending from the cold Glacial tunnel into Station 4 feels like a natural thermodynamic shift: frosty white mist gives way to dense, humid industrial vapor without sudden pop-in or color snapping.

---

## 3. Diegetic Point & Omni Lights

1. **Expedition Brass Lantern (Hand / Chest Harness):**
   - Color: `Color(1.0, 0.78, 0.44)` (Warm tungsten kerosene flame).
   - Energy: `1.8`, Range: `14.0m`. Attenuation: cubic decay with soft shadows.
2. **Station 4 Workstation Desk Lamp:**
   - Color: `Color(1.0, 0.82, 0.50)`.
   - Energy: `1.6`, Range: `8.0m`.
3. **Bioluminescent Mushroom Colonies (Echo Shaft):**
   - Color: `Color(0.18, 0.90, 0.82)` (Vibrant deep-cyan).
   - Energy: `1.3` (Ledge colony), `1.8` (Abyssal floor colony). Range: `9.0m` to `16.0m`.
