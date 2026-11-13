# HOLLOW CORE — MILESTONE 1 (M1) TEST REPORT
**Quality Assurance & Test Engineering Lead**  
**Godot Engine 4.7+ Forward+ (Vulkan 1.4, Windows 64-bit)**  
**Version:** 1.0  
**Test Suite:** `test_m1_verification.gd`  
**Execution Timestamp:** 2026-11-12T20:09:51+05:00  

---

## 1. AUTOMATED TEST SUITE SUMMARY

| Metric | Result |
| :--- | :--- |
| **Total Automated Tests Executed** | 9 |
| **Tests Passed** | 9 (100%) |
| **Tests Failed** | 0 (0%) |
| **Engine Warnings / Script Errors** | 0 |
| **Final Exit Code** | `0` (Success) |

---

## 2. DETAILED TEST CASE RESULTS

### TEST 1: 5-Zone Vertical Slice Geometry & Routing Bounds
- **Objective:** Verify physical presence of all 5 level zones, floor collision, and height bounds.
- **Coordinates Tested:**
  - Zone A: Approach Tunnel floor ($X: 5, Y: 51, Z: 0$).
  - Zone B: Airlock Station 4 floor ($X: 15, Y: 38, Z: -10$).
  - Zone C: Echo Shaft chasm ($X: 0, Y: 22, Z: -25$).
  - Zone D: Abandoned Camp ($X: -16, Y: 25, Z: 4$).
  - Zone E: Lower Drained Sump ($X: 15, Y: 28, Z: -12$).
- **Result:** **PASS**. All 5 zones carved with solid collidable floors and valid air volumes.

### TEST 2: Brass Lantern & Fuel Component
- **Objective:** Verify lantern toggle with `F`, fuel consumption rate over time, refuel replenishment, and horror light flicker.
- **Measured Metrics:**
  - Fuel consumed during active burn: `5.00` units.
  - Refuel recovery: restored to `99.88%`.
  - Light flicker timer: `1.50` seconds.
- **Result:** **PASS**.

### TEST 3: Item Pickup Bug Fix (Area3D Raycast & Dual Key E/F)
- **Objective:** Verify that `query.collide_with_areas = true` allows crosshair raycast to hit `DroppedItem` directly and collect items into player inventory.
- **Result:** **PASS**. Raycast hit item directly (`true`), collected 4 Phosphor Crystals into inventory ($0 \to 4$).

### TEST 4: Metal Wall Anchor System (Sandbox Element)
- **Objective:** Verify anchor placement against rock face, normal orientation, hanging rope generation, and serialization.
- **Result:** **PASS**. Anchor fastened at $(4.5, 34.0, -22.0)$ with normal $(-1, 0, 0)$, 3.5m rope generated, data serialized.

### TEST 5: Document D-01 Inspection & Vintage Viewer
- **Objective:** Verify interaction with dispatch box in Airlock 4 opens `DocumentViewer` with authentic 1894 Prokhorov text and sets read flag.
- **Result:** **PASS**. Document opened, verified text match, read flag recorded, closed cleanly on `E`.

### TEST 6: Drainage Valve & Easter Egg EE-06 + The Watcher
- **Objective:** Verify turning drainage valve, unlocking EE-06 Safe (Code 1924), awarding 6 Syndicate Gold, and manifesting The Watcher across the chasm.
- **Result:** **PASS**. Valve rotated, Safe unlocked, 6 Gold awarded, Watcher manifested at $(-15.0, 32.0, -12.0)$ across abyss.

### TEST 7: Psychological Horror Anomalies EV-01 & EV-02
- **Objective:** Verify EV-01 triggers delayed footsteps $0.38$s after stopping; verify EV-02 echoes 4th strike $1.80$s after 3 pickaxe hits.
- **Result:** **PASS**. Both anomalies triggered at exact delays.

### TEST 8: Full Save & Load Persistence Round-Trip
- **Objective:** Verify saving and restoring voxel delta modifications, player position, placed anchors, and story flags across disk reload.
- **Result:** **PASS**. Carved basalt floor restored to `AIR`, player position restored to $(12.3, 38.5, -9.2)$, and all story flags verified.

### TEST 9: Performance Profiling & Hardware Budgets
- **Objective:** Verify static RAM $<2.2$ GB and frame times $<16.67$ ms (60+ FPS).
- **Result:** **PASS**. Static RAM: **257.89 MB** (88.5% below ceiling); Average Frame Time: **10.43 ms (~95.9 FPS)**.

---

## 3. VISUAL QUALITY GATE INSPECTION

Visual inspection screenshots captured via Forward+ Vulkan 1.4:
1. `screenshots/m1_01_approach_and_airlock.png` — Approach tunnel looking into Airlock Station 4 with brass lantern in hand.
2. `screenshots/m1_02_echo_shaft_chasm.png` — High ledge looking into the 20-meter vertical Echo Shaft abyss.
3. `screenshots/m1_03_document_d01_inspection.png` — In-game inspection of Document D-01 on aged parchment.

All 3 visual artifacts passed the Vision Quality Gate with zero graphical clipping, zero unnatural lighting artifacts, and full Anti-AI-UI adherence.
