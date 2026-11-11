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

### Phase 2: Subterranean Mining & Vertical Building
- [ ] **Voxel/Destructible Terrain & Mineral Excavation**:
  - Digging/mining mechanics with pickaxe/borer tool.
  - Mineral node veins: Pyrite, Luminous Phosphor, Abyssal Iron, Obsidian glass.
- [ ] **Suspended Architecture & Modular Building**:
  - Snapping system for wooden/metal scaffolding, suspended rope bridges, platform anchors into cavern ceilings and vertical walls.
  - Pulley winches, climbing ropes, and vertical ascenders to scale 80m cliff faces.
  - Structural stability calculations (beams require anchors).

### Phase 3: The Bestiary & Light/Dark Dynamics
- [ ] **Shadow Stalkers**:
  - Creatures of pure obsidian darkness that track the player in shadows.
  - Aggressive in total darkness, blinded and staggered by direct high-intensity lantern beams.
- [ ] **Lantern Leeches**:
  - Bioluminescent pests that swarm active light sources and siphon fuel/oil if not swatted or evaded.
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
