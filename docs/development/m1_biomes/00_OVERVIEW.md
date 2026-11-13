# HOLLOW CORE — M1 BIOME OVERHAUL: ARCHITECTURAL OVERVIEW
**Document ID:** `DOC-M1-BIO-00`
**Status:** Approved & Implemented
**Engine:** Godot 4.7+ (Forward+ / Vulkan)

---

## 1. Executive Summary

Milestone 1 (Vertical Slice «Шлюзовая Станция 4 и Шурф Эха») previously featured a monolithic underground cave environment. The **M1 Biome Overhaul** transforms this vertical slice into three distinct, living, and highly atmospheric subterranean ecosystems (strata):
1. **Biome I: Ледниковые Шпили (Glacial Spires)** — Upper cryosphere descent ($Y \in [44.0, 72.0]$).
2. **Biome II: Затопленные Шлюзы (Flooded Sluice Gates)** — Industrial masonry and drainage canal ($Y \in [28.0, 46.0]$).
3. **Biome III: Базальтовая Абиссаль (Basaltic Abyssal Basin)** — Colossal vertical chasm with columnar basalt ($Y \in [10.0, 44.0]$).

Each ecosystem possesses its own geology, physical surface friction, custom shaders, acoustic reverberation profile, lighting parameters, and environmental storytelling.

---

## 2. Zero-Mob Psychological Horror Identity

In strict accordance with the core vision of **Hollow Core** and user directives:
- **All generic enemy mob classes, dynamic spawners, and combat entities have been eradicated**.
- Combat is completely absent. The gameplay focuses exclusively on exploration, resource gathering, engineering, and deep psychological horror.
- The sole entity inhabiting the depths is **Наблюдатель (The Watcher / APP-01)**:
  - An elusive silhouette standing motionless in distant fog.
  - Features unshaded, piercing square white eyes that cut through darkness.
  - Never charges or bites; induces primal dread through silent observation and dissolves when approached or stared at directly.
  - Faithfully reproduces the classic Alpha liminal / creepypasta horror atmosphere.

---

## 3. Core Architecture Components

- `BiomeDefinition` (`scripts/world/biomes/biome_definition.gd`): Resource base class with 3D AABB containment and margin-based continuous interpolation.
- `BiomeManager` (`scripts/world/biomes/biome_manager.gd`): Global coordinator managing real-time stratum resolution, priority overrides, smooth fog/ambient lighting transitions, and acoustic reverberation updates.
- `SubterraneanWater` (`scripts/world/subterranean_water.gd`): Physical water volume with Area3D triggers, surface refraction, player wading slowdown (0.62x speed), and sloshing footstep acoustics.
- `AnomalyDirector` (`scripts/horror/anomaly_director.gd`): Independent manager of EV-01 (delayed footsteps) and EV-02 (4th strike resonance) with long cooldowns and refuge safety checks.
