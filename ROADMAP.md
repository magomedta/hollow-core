# HOLLOW CORE (ПОЛАЯ ЗЕМЛЯ) — ARCHITECTURE & DEVELOPMENT ROADMAP

## Core Vision & Identity
**Hollow Core** is a subterranean first-person survival/building sandbox set in colossal, abyss-deep cavern systems (50–100+ meters high). 
The core gameplay tension revolves around **Light vs. Pitch Darkness**, vertical navigation, suspended modular building, and surviving deep underground terrors.

### Core Pillars
1. **Verticality & Colossal Scale**: Massive claustrophobic-yet-titanic subterranean chambers, abyssal drop-offs, suspended bridges, and monolithic basalt formations.
2. **Diegetic Light Mechanics**: Darkness is not merely low-visibility; it is an active hazard. Light repels certain terrors, attracts others, and reveals paths. Your brass & glass lantern requires fuel management.
3. **Restrained Human Game-Dev Aesthetic (Anti-AI-UI)**: Muted slate, deep obsidian, warm brass/amber (lantern), and pale cyan bioluminescence. No neon clutter, zero emoji-soup, sharp typography, and subtle diegetic gauges.
4. **Physicality & Tactility**: Camera sway, lantern bobbing with momentum, physics-driven light flickers, and crisp audio cues.

---

## Phased Development Roadmap

### Phase 1: Core Foundation & Atmospheric Exploration (CURRENT FOCUS)
- [x] **Engine & Project Scaffold**: Godot 4.7+ Forward+ Vulkan pipeline, configured for volumetric fog, physically-based rendering (PBR), and high dynamic range lighting.
- [x] **Colossal 3D Cavern Generator**:
  - Procedural/modular chamber generator with 3D noise-driven cavern walls, stalactites, stalagmites, basalt pillars, and vertical ledges (50–100m ceiling clearance).
  - Bioluminescent flora & fungus clusters emitting delicate cyan/azure glow to create visual depth in the pitch black.
  - Specular & normal mapped cavern rock shaders with wetness and crystal specks.
- [x] **First-Person Controller**:
  - Fluid movement (walk, sprint, jump, crouch) with acceleration and deceleration curves.
  - Diegetic head-bobbing and procedural lantern sway based on player velocity and mouse angular momentum.
- [x] **Dynamic Diegetic Lantern**:
  - Handheld brass-and-cage lantern with dynamic Omni/Spot light, shadow casting, subtle warm flame breathing, and toggle switch (`F` key).
  - Diegetic fuel consumption system and minimal brass fuel gauge.
- [x] **Atmospheric World Environment**:
  - Deep obsidian darkness (near-zero ambient light) pierced solely by the lantern and rare bioluminescence.
  - Volumetric Fog with scattering, light shaft piercing (god-rays), and ambient fungal dust particles.
- [x] **Anti-AI Diegetic HUD**:
  - Elegant, unobtrusive HUD: Depth indicator (`-1,420 m`), Lantern Oil gauge, Compass heading, and Reticle.
  - Restrained monochrome + amber accent aesthetic.

### Phase 2: Subterranean Mining, World Biomes & Exploration (COMPLETED)
- [x] **Voxel Destructible Terrain & 25+ Procedural Biomes**:
  - Direct 1D array indexing chunk mesher (~20x faster meshing, 0 frame drops).
  - Microsecond time budgeting (`Time.get_ticks_usec()`, 4ms slice) preventing chunk loading stutters.
  - 25+ distinct subterranean biomes across 5 vertical strata and 4 climate noises: Fungal Mycena Hollows, Crystalline Amethyst Grottos, Precursor Waystations, Sulfur Fumaroles, Magma Mantle, Glacial Cryosphere, etc.
  - Interactive resource blocks: Water Springs (canteen refill), Bioluminescent Glow-caps (edible food), Lichen Roots, Cargo Crates.
- [x] **Differentiated Tool & Hand Mining**:
  - Bare hands take 14 hits on hard rock/ore and yield rubble/cobblestone instead of valuable ores.
  - Pickaxes break blocks according to hardness and tier, yielding pure ores.
- [x] **Explorer Mobility & Jump Tuning**:
  - Jump velocity calibrated to 7.4 m/s (1.4m clearance, effortlessly leaping 1-block steps).
  - Balanced exploration speeds (walk: 3.8 m/s, sprint: 5.8 m/s).
- [x] **Diegetic HUD & Radial Selection Wheel**:
  - Real-time FPS counter and frame-time telemetry.
  - 8-slice circular radial selection wheel toggled with `Q` and navigable with mouse wheel or keys.
  - Dynamic in-world raycast prompts for drinking water, harvesting mushrooms, and opening crates.
  - 18 custom 32x32 RGBA pixel icons and visual-first inventory UI.

### Phase 3: The Bestiary & Articulated Fauna (COMPLETED)
- [x] **Chasm Stalker (Apex Cavern Predator)**:
  - Articulated multi-jointed leg anatomy (Femur, Tibia, Foot Claws) firmly planted on cavern floors (zero floating feet).
  - Bioluminescent visual sensors, chitin armor, and alternating quadruped stalk animation.
- [x] **Lithic Crawler (Rock-Mimicking Arthropod)**:
  - 6 articulated legs with grounded claws, animated in alternating tripod gait.
  - Dorsal crystalline nodules, subterranean scuttling behavior, and acoustic sensitivity.
- [x] **Cryo Wisp (Sub-Zero Atmospheric Entity)**:
  - Surface blizzard floating entity with particle tendrils and thermal aura.
- [x] **Subterranean Spawning System**:
  - Dynamic procedural spawner placing creatures naturally on solid cavern floors throughout the depth strata.
- [ ] **Tremor Borers**:
  - Colossal blind burrowers detected via seismic tremors and dust falling from the ceiling.
- [ ] **Sanity & Dread Mechanic**:
  - Heartbeat elevation and auditory hallucinations when lingering beyond light boundaries for extended periods.

### Phase 4: Environmental Lore, Mysteries & Audio
- [ ] **"The Great Descent" Expedition Logs**:
  - Abandoned surveyor camps, brass audiolog cylinders, oxidized brass markers, and geological journal scraps.
- [ ] **Precursor Monoliths & Geothermal Vents**:
  - Strange non-Euclidean basalt monuments humming at low frequencies.
  - Hazardous steam vents, sulfur geysers, and underground hot-spring pools.
- [ ] **Diegetic Soundscape**:
  - Realistic subterranean acoustic reverbs, distant echoes, water droplet splashes, cave winds, and mechanical lantern creaks.

### Phase 5: Steam Packaging, Optimization & Polish
- [ ] **Performance & Level of Detail (LOD)**:
  - Mesh LODs, occlusion culling, GPU instancing for stalactites and fungal spores.
  - Dynamic resolution scaling (FSR 2.2 / temporal anti-aliasing).
- [ ] **Steamworks Integration**:
  - Steam achievements, cloud saves, rich presence ("Exploring Chamber IX - Depth 2,100m").
- [ ] **Accessibility & Settings**:
  - Rebindable controls, FOV slider, sensitivity curves, gamma/hdr calibration, audio mix busses.
- [ ] **Release Packaging**:
  - Windows 64-bit standalone export, verification suite, and Steam depot preparation.
