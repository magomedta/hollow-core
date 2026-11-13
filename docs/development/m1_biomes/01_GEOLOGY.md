# HOLLOW CORE — M1 BIOME GEOLOGY SPECIFICATION
**Document ID:** `DOC-M1-BIO-01`

---

## 1. Geological Stratification & Bounds

The M1 Vertical Slice spans 62 meters of vertical depth, segmented into three distinct geological horizons:

| Biome ID | Russian Name | Vertical Range ($Y$) | Dominant Rock Type | Secondary Inclusions |
| :--- | :--- | :--- | :--- | :--- |
| `glacial_spires` | Ледниковые Шпили | $Y \in [44.0, 72.0]$ | `PERMAFROST_ICE` (13) | `CALCITE` (11), `STONE` (1) |
| `flooded_gates` | Затопленные Шлюзы | $Y \in [28.0, 46.0]$ | `SLATE_BRICK` (20) | `DEEP_BASALT` (16), `WOOD_PLANKS` (17) |
| `basaltic_abyssal` | Базальтовая Абиссаль | $Y \in [10.0, 44.0]$ | `DEEP_BASALT` (16) | `PHOSPHOR_ORE` (22), `COPPER_ORE` (9), `CALCITE` (11) |

---

## 2. Geological Formations by Zone

### 2.1 Zone A: Glacial Spires & Descent Crevasse
- Sloping 13-meter natural fissure descending from $Y = 56$ to $Y = 44$.
- Permafrost ice walls lining both flanks ($Z = -13$ and $Z = 3$).
- Alternating permafrost ice runs along the center walkway where ground friction drops to `0.38`.
- Hanging calcite icicles and stalactites suspended from the vaulted ceiling.
- Structural timber frames (`HEWN_TIMBER`) installed by earlier expeditions every 3 meters.

### 2.2 Zone B: Flooded Sluice Gates (Airlock Station 4)
- 19th-century industrial masonry chamber ($12 \times 7 \times 11\text{ m}$).
- Heavy slate-brick load-bearing portal bulkhead at $X = 10$.
- Recessed 2.8m-wide drainage canal carved into the slate floor ($X \in [15, 17], Z \in [-15, -6]$) submerged under 0.6m of dark industrial runoff.
- Cast-iron drainage valve wheel controlling sump drainage.

### 2.3 Zone C: Basaltic Abyssal Basin (Echo Shaft)
- Soaring 22-meter vertical chasm dropping from $Y = 44$ to $Y = 22$.
- Faceted hexagonal columnar basalt colonnades rising in stepped tiers ($Y = 22..33$).
- Natural mineral shelves and stepping terraces at $Y = 27$ and $Y = 33$.
- Cascading subterranean waterfall at $X = -10, Z = -33$ pouring into a deep basal plunge pool.
- Deep cliff alcoves housing amethyst geodes and phosphor veins.
