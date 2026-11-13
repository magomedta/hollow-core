# HOLLOW CORE — MILESTONE 1 (M1) VISUAL DIRECTION
**Lead Art Director & Technical Artist**  
**Godot Engine 4.7+ Forward+ (Vulkan 1.4, Windows 64-bit)**  
**Version:** 1.0  

---

## 1. ARTISTIC IDENTITY: STYLIZED FACETED GEOLOGY

Hollow Core avoids generic photorealism and rejects low-effort block clones. The visual direction is **Stylized Faceted Geological Realism**:
- Sharp, crystalline rock cleavage planes and columnar basalt fractures.
- Hand-authored pixel textures (32x32 / 64x64) with nearest-neighbor texture filtering for tactile, retro-modern clarity.
- PBR materials with high roughness variation: dry powdery basalt (0.85 roughness) contrasted with weeping, mineral-slicked flowstone (0.15 roughness).

---

## 2. RESTRAINED COLOR PALETTE SPECIFICATION

```
+---------------------------------------------------------------------------------+
| COLOR NAME           | HEX / RGB               | APPLICATION                    |
+----------------------+-------------------------+--------------------------------+
| Obsidian Void        | #05070A (0.02,0.03,0.04)| Deep cave voids, darkness, shadows|
| Deep Basalt          | #323842 (0.20,0.22,0.26)| Primary cavern walls and floor |
| Cold Slate           | #54606E (0.33,0.38,0.43)| Precursor bricks, masonry      |
| Weathered Brass      | #C4A252 (0.77,0.64,0.32)| Lantern body, dials, safe locks|
| Warm Amber           | #FFA630 (1.00,0.65,0.19)| Lantern flame, HUD accent      |
| Pale Cyan            | #48C9B0 (0.28,0.79,0.69)| Distant phosphor lichen        |
+----------------------+-------------------------+--------------------------------+
```

**Anti-AI-UI Rule:** Strictly forbid clownish neon rainbow palettes. Muted graphite and slate form the entire base, with warm amber reserved strictly for the lantern and player focus.

---

## 3. LIGHTING, ATMOSPHERE & SHADOW ARCHITECTURE

### WorldEnvironment Configuration:
- **Background Mode:** Solid Background Color (`Color(0.005, 0.007, 0.010)`).
- **Ambient Light Source:** Color source with low bounce (`Color(0.12, 0.16, 0.22)`, energy `0.22`).
- **Tonemapper:** ACES Film Tonemapping (exposure `1.15`).
- **Atmospheric Fog:** Exponential distance fog (`Color(0.10, 0.13, 0.17)`, density `0.038`).
  - Ensures distant spaces fade into menacing silhouette shapes.
  - Limits visible draw distance to ~35 meters, creating psychological tension without popping.

### Dynamic Lantern Illumination:
- **OmniLight3D:** Close-range spherical illumination (`energy = 1.80`, range `12m`, warm golden tint `Color(1.0, 0.78, 0.44)`).
- **SpotLight3D:** Forward-projecting reflector beam (`energy = 2.40`, angle `50°`, range `36m`) cutting through the cave fog.
- **Faceted Shadows:** Dynamic shadows enabled only on the player's primary light, casting long, angular shadows off jagged rock columns.

---

## 4. DIEGETIC HUD SPECIFICATION (ANTI-AI-UI COMPLIANCE)

- **Container:** Dark graphite slate panel (`Color(0.03, 0.04, 0.06, 0.85)`) with subtle 1px border (`Color(0.20, 0.25, 0.32)`).
- **Typography:** Crisp monospace clean telemetry:
  - `ГОРИЗОНТ: 1420м // Y: 38.0м`
  - `КОМПАС: [ N 014° ]`
  - `ФОНАРЬ (ВКЛ): 100% ТОПЛИВО`
- **Zero Emojis, Zero Neon Glassmorphism:** All information reads like genuine field telemetry from 19th/20th-century subterranean exploratory equipment.
