# HOLLOW CORE — M1 BIOME SPATIAL BOUNDS & SEAMLESS TRANSITIONS
**Document ID:** `DOC-M1-BIO-08`

---

## 1. 3D Spatial Partitioning (AABB + Priority)

Subterranean vertical slices cannot rely on simple 1D altitude thresholds because chambers at the same vertical height often belong to completely different biomes (e.g., Station 4 industrial masonry at $Y = 39$ vs. Echo Shaft natural abyss at $Y = 39$).

### 1.1 Registered Biome Bounds

```gdscript
# Glacial Spires: High cryosphere tunnel
spatial_bounds = AABB(Vector3(-30, 44, -14), Vector3(60, 28, 55))
priority = 10

# Flooded Sluice Gates: Station 4 industrial chamber
spatial_bounds = AABB(Vector3(6, 28, -20), Vector3(20, 18, 26))
priority = 20 # Overrides surrounding deeper strata

# Basaltic Abyssal: Vast chasm and lower terraces
spatial_bounds = AABB(Vector3(-32, 10, -42), Vector3(38, 34, 34))
priority = 15
```

---

## 2. Continuous Margin Blending (`blend_margin = 4.0m`)

To eliminate sharp visual seams:
1. `BiomeDefinition.get_point_weight(pos)` computes the Euclidean distance to the nearest boundary edge.
2. Across a 4-meter margin, weights blend smoothly from 0.0 to 1.0.
3. `BiomeManager.get_blended_environment(pos)` interpolates:
   - Fog density and fog light scattering color.
   - Ambient light color and energy bounce.
   - Acoustic reverberation decay time.
   - Ground friction and movement dampening.

Result: Walking across the threshold from the icy gallery into Station 4 produces a natural, gradual environmental transition with zero pop-in.
