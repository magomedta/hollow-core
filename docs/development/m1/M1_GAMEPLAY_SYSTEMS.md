# HOLLOW CORE — MILESTONE 1 (M1) GAMEPLAY SYSTEMS
**Lead Gameplay Engineer & Technical Designer**  
**Godot Engine 4.7+ Forward+ (Vulkan 1.4, Windows 64-bit)**  
**Version:** 1.0  

---

## 1. DUAL-KEY INTERACTION & ITEM PICKUP FIX

### Root Cause Analysis of Previous Pickup Glitch:
1. **Raycast Physics Mask / Collision Object Types:** In Godot 4, `PhysicsRayQueryParameters3D` defaults `collide_with_areas = false` and `collide_with_bodies = true`. Because `DroppedItem` is an `Area3D`, the camera crosshair raycast passed completely through dropped items and hit the static voxel rock behind them.
2. **Keybinding Conflict:** Players accustomed to FPS/Survival games frequently pressed `F` to interact. In Hollow Core, `F` toggled the lantern, creating frustration when trying to collect items.

### Comprehensive Solution Implemented:
1. **Explicit Area3D Raycast Enablement:** Both `player_controller.gd` (`_handle_interaction_key`) and `hud.gd` (`_update_interaction_ray_prompt`) now explicitly configure:
   ```gdscript
   query.collide_with_areas = true
   query.collide_with_bodies = true
   ```
2. **Dual-Key Contextual Fallback:**
   - **`[E]` Key:** Primary interaction key. Operates documents, valves, chests, and picks up items directly or via 3.0m proximity fallback.
   - **`[F]` Key:** If the crosshair is directly aimed at an item, `F` performs an immediate collection pickup fallback. If not aimed at an item, `F` smoothly toggles the brass lantern.
3. **HUD Prompt Feedback:** The crosshair dynamically displays `[E] ПОДОБРАТЬ <ITEM_NAME> (X<COUNT>)` whenever an item is targeted.

---

## 2. BRASS LANTERN & FUEL ENGINE

### Mechanical Specifications:
- **Visual Structure:** Octagonal brass base pedestal, dark cast-iron reservoir, four cardinal protective cage posts, faceted tempered glass cylinder, and brass fuel filler cap.
- **Player-Facing Analog Dial:** A mechanical dial with an active red needle rotating from $-65^\circ$ (empty) to $+65^\circ$ (100% full).
- **Procedural Flame Shader:** Real-time flame oscillation with micro-flicker noise (`shaders/lantern_flame.gdshader`).
- **Kinematic First-Person Dynamics:**
  - Placed in the right hand with natural viewport offset (`Vector3(0.24, -0.18, -0.42)`).
  - Walk sway: vertical and horizontal sinusoidal bobbing scaled by player speed.
  - Sprint sway: accelerated oscillation with a defensive forward tilt.
  - Camera rotation inertia: lags behind rapid mouse turns and smoothly re-centers via exponential decay interpolation (`target_sway_rot.lerp(Vector3.ZERO, delta * 6.0)`).
- **Survival Fuel Economy:**
  - Burn rate: `0.35` units per second (~4.5 minutes of continuous full light per tank).
  - Refuel mechanic: Phosphor crystals or kerosene canisters restore fuel via `refuel(amount)`.
  - Paranormal flicker: Anomaly triggers call `flicker(duration)`, modulating omni and spot energy down to 12–55% of baseline.

---

## 3. SANDBOX BUILDING ELEMENT: METAL WALL ANCHOR

### Exploration Problem:
In the Echo Shaft, vertical drops of 15–20 meters and deep ravines block direct traversal. Jumping results in fatal fall damage.

### The Solution (`RockAnchor` & `AnchorPlacementComponent`):
1. **Selection:** Selecting an Anchor item activates placement mode.
2. **Holographic Preview:** A warm amber wireframe ring (`Color(1.0, 0.72, 0.20, 0.75)`) projects along the targeted rock surface normal. If the target is out of reach ($>3.8$m) or obstructed, it shifts to translucent red.
3. **Fastening:** Pressing RMB / Interaction drives a heavy steel expansion bolt into the rock face (`sm.play_sfx("pickaxe_stone", 0.85)`).
4. **Physical World Entity:** Spawns a `RockAnchor` static body with a forged steel ring and a 3.5-meter knotted hemp climbing rope.
5. **Traversal Utility:** Players can descend safely, climb back up by pressing `E`, or string bridging lines across crevasses.
6. **Persistence:** Anchor coordinates, normal vectors, and rotation are serialized and restored automatically upon loading.

---

## 4. RESOURCE GATHERING & PROGRESSION LOOP

```
[DISCOVERY] ──► [EXCAVATION] ──► [PROCESSING] ──► [APPLICATION]
Deep Caverns    Faceted Mining   Raw Minerals     Lantern Fuel & Anchors
```

1. **Phosphor Crystals (`BlockType.PHOSPHOR_ORE`):** Yields raw phosphor essence. Can be refined into lantern fuel or craftable carbide torches.
2. **Raw Iron Ore (`BlockType.IRON_ORE`):** Mined with pickaxe. Used to forge new steel wall anchors.
3. **Calcite Geodes (`BlockType.CALCITE`):** Translucent crystals used for optical reflectors.
4. **Survival Provisions:** Cargo crates and springs in Airlock 4 restore hydration and satiety.
