# HOLLOW CORE — M1 BIOME MATERIALS & SURFACE SHADERS
**Document ID:** `DOC-M1-BIO-02`

---

## 1. Material Palette & Shader Properties

All materials are authored for Godot 4.7+ Forward+ Vulkan pipeline with full support for micro-specular highlights, roughness maps, and normal perturbation:

### 1.1 Permafrost Ice (`PERMAFROST_ICE` / Block ID 13)
- **Albedo:** Translucent pale cyan-grey (`Color(0.68, 0.82, 0.88, 1.0)`).
- **Roughness:** 0.12 (High specular reflection under lantern light).
- **Refraction:** Scale 0.03 for optical internal scattering.
- **Physical Friction:** `0.38` — causes realistic inertial slip during locomotion.

### 1.2 Slate Brick Masonry (`SLATE_BRICK` / Block ID 20)
- **Albedo:** Weathered dark graphite-slate with mortar seams.
- **Roughness:** 0.72.
- **Normal Detail:** Deep etched brick bounds with chipped edges.
- **Physical Friction:** `0.85` — firm footing with damp traction.

### 1.3 Deep Columnar Basalt (`DEEP_BASALT` / Block ID 16)
- **Albedo:** Dense obsidian charcoal (`Color(0.14, 0.14, 0.16, 1.0)`).
- **Roughness:** 0.88 (Matte crystalline rock matrix).
- **Acoustic Absorption:** `0.18` (High acoustic reflection, generating long reverb tails).
- **Physical Friction:** `0.95`.

### 1.4 Subterranean Water Surface (`SubterraneanWater`)
- **Shader:** Real-time alpha blend with screen-space refraction.
- **Color:** Dark industrial slate-blue (`Color(0.04, 0.10, 0.16, 0.82)`).
- **Roughness:** 0.08.
- **Physics Behavior:** Area3D layer 2 overlap, dampens player horizontal speed by 38% and scales jump velocity by 0.80x.

### 1.5 The Watcher Void Material & Emissive Eyes
- **Body:** Total absorption unlit charcoal (`Color(0.02, 0.02, 0.03, 1.0)`), roughness 0.95.
- **Eyes:** Pure `SHADING_MODE_UNSHADED` white (`Color(1.0, 1.0, 1.0)`), emission energy multiplier `16.0` — ignores fog decay and shadows to deliver that unforgettable Herobrine stare.
