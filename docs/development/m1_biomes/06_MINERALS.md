# HOLLOW CORE — M1 MINERAL VEINS & EXTRACTION SPECIFICATION
**Document ID:** `DOC-M1-BIO-06`

---

## 1. Subterranean Mineral Distribution

Minerals in Hollow Core are distributed in geologically authentic strata, encouraging vertical exploration:

| Mineral Node | Block ID | Primary Stratum | Depth ($Y$) | Extraction Utility |
| :--- | :--- | :--- | :--- | :--- |
| **Phosphor Ore** | 22 | Базальтовая Абиссаль | $Y \in [25, 33]$ | Chemical luminescent flares, lantern fuel refining |
| **Copper Ore** | 9 | Базальтовая Абиссаль | $Y \in [25, 32]$ | Structural wiring, brass fittings, anchors |
| **Iron Ore** | 8 | Basalt & Station 4 | $Y \in [26, 34]$ | Heavy picks, rock anchors, reinforce bulkheads |
| **Calcite Crystals**| 11 | Ледниковые Шпили | $Y \in [44, 56]$ | Optical lenses, filtration components |
| **Amethyst Geodes** | 27 | Abyssal Cliff Alcoves | $Y \in [31, 33]$ | Resonant acoustic amplifiers, lore artifacts |

---

## 2. Organic Mining Mechanics

- **Progressive Structural Fracture:** Striking a mineral block generates directional micro-fractures in real time (`bedrock_crack_mat` decal).
- **Physical Hardness & Yield:**
  - `CALCITE`: 2 pickaxe hits.
  - `COPPER_ORE`: 3 pickaxe hits.
  - `PHOSPHOR_ORE`: 3 pickaxe hits.
  - `IRON_ORE`: 4 pickaxe hits.
  - `DEEP_BASALT`: 5 pickaxe hits.
- **Acoustic Feedback:** Every pickaxe hit emits a spatial impulse into `SoundMemoryManager`, triggering acoustic resonance and potential EV-02 anomalies.
