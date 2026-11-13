# HOLLOW CORE — MILESTONE 1 (M1) LEVEL DESIGN
**Location:** «Шлюзовая Станция 4 и Шурф Эха» (Airlock Station 4 & Echo Shaft)  
**Lead Game Director & Senior Level Designer**  
**Godot Engine 4.7+ Forward+ (Vulkan 1.4, Windows 64-bit)**  
**Version:** 1.0  

---

## 1. OVERVIEW & SPATIAL PARAMETERS

«Шлюзовая Станция 4 и Шурф Эха» is the premiere vertical slice gameplay space for **Hollow Core**. It embodies the core design tenets of the project: physical rock excavation, solitary exploration, environmental archaeology, and psychological horror without cheap jumpscares.

- **Bounding Box:** $X \in [-35, +35]$, $Y \in [20, 65]$, $Z \in [-35, +35]$ ($70 \times 45 \times 70$ meters total volume).
- **Vertical Drop:** $45$ meters of continuous playable subterranean verticality.
- **Estimated Playtime:** 30–45 minutes for a thorough first exploration.
- **Biomes Traversed:**
  - *Surface Cryosphere & Subglacial Karst* ($Y \in [45, 60]$)
  - *Flooded Sump & Slate Bulkhead Galleries* ($Y \in [35, 45]$)
  - *Basalt Abyssal Basin & Echo Cavern* ($Y \in [20, 35]$)

---

## 2. THE 5-ZONE SPATIAL TOPOLOGY

```
[ZONE A: APPROACH TUNNEL] (Y=56..48)
  │  Sloping icy descent, depth marker, timber arches
  ▼
[ZONE B: AIRLOCK STATION 4] (Y=44..38)
  ├──► [ZONE D: ABANDONED CAMP] (Y=26..30)
  │      Tents, cots, radio beacon, safe refuge
  │
  ├──► [ZONE C: ECHO SHAFT] (Y=42..22)
  │      20m vertical chasm, mineral ledges, climbing anchors
  │
  └──► [ZONE E: LOWER DRAINED SUMP] (Y=28..32)
         Drainage valve access, EE-06 Safe, The Watcher apparition
```

### Zone A: Approach Tunnel (Descent from Ice Rift)
- **Coordinates:** $X \in [0, 10]$, $Y \in [46, 58]$, $Z \in [-4, 4]$
- **Atmosphere:** Howling icy draft from the surface rift above, transition from glistening permafrost ice into cold slate.
- **Environmental Clues:**
  - Timber roof shoring beams every 4 paces.
  - Severed heavy rubber power cables trailing down the tunnel.
  - Stenciled yellow enamel depth marker on slate: `ГОРИЗОНТ IV — ОТМЕТКА 48м`.
  - Expedition cargo crates with initial survival rations.

### Zone B: Airlock Station 4 (Primary Archaeological Hub)
- **Coordinates:** $X \in [10, 22]$, $Y \in [38, 45]$, $Z \in [-16, -4]$
- **Atmosphere:** Industrial, abandoned, damp masonry. Heavy riveted iron bulkhead frame with an arched opening.
- **Key Objects & Interactables:**
  - **Surveyor Workstation:** Weathered pine table with rusted calipers, spilled lamp oil canisters, and a brass lamp hanger.
  - **Dispatch Container (Document D-01):** Wall-mounted iron box with brass latch containing the 1894 Prokhorov shift log.
  - **Drainage Gate Valve Wheel:** Heavy red-lead painted iron handwheel controlling the drainage pump for Zone E.

### Zone C: Echo Shaft (The Resonant Abyss)
- **Coordinates:** $X \in [-15, 5]$, $Y \in [22, 44]$, $Z \in [-34, -14]$
- **Atmosphere:** A soaring 20-meter vertical cavern vault. Deep shadows, damp acoustic reverberation, distant water drops echoing across basalt faces.
- **Key Features & Mechanics:**
  - Cascading basalt ledges along the east wall ($Y = 32..35$).
  - A sheer 14-meter drop into the lower basalt floor ($Y = 22$).
  - Rich mineral veins embedded in rock: Iron Ore, Phosphor Crystals, Copper, and Calcite Geodes.
  - Requires placing high-tensile steel **RockAnchors** with hanging climbing ropes to rappel down or bridge crevasses.

### Zone D: Abandoned Expedition Camp (Safe Refuge)
- **Coordinates:** $X \in [-24, -8]$, $Y \in [25, 31]$, $Z \in [-4, 12]$
- **Atmosphere:** Natural sheltered cavern grotto. Warmer, dry ground with cobblestone paving.
- **Storytelling Details:**
  - Skeleton of two expedition canvas tents with hewn timber framing.
  - Iron cots with frozen wool blankets.
  - Morse radio transceiver on a workbench emitting faint static.
  - Cold enameled coffee mug resting next to an unfinished surveyor log.
  - A heavy timber supply door barricaded from the inside with deep scratch marks.
  - **Mechanic:** Registered as a **Safety Pocket** where Dread is purged and psychological anomalies (EV-01, EV-02) are strictly suppressed.

### Zone E: Lower Sump Collector & Culmination
- **Coordinates:** $X \in [12, 18]$, $Y \in [25, 32]$, $Z \in [-16, -8]$
- **Atmosphere:** Deep cistern beneath Airlock Station 4. Initially flooded; turning the drainage valve in Zone B purges the water.
- **Climax Content:**
  - **Easter Egg EE-06:** The Drowned Safe of Syndicate 104 with combination code `1-9-2-4`.
  - Unlocking reveals Syndicate gold tokens, a brass 11.4 Hz tuning fork, and the watertight lamp blueprint.
  - Unlocking triggers a 3-second lantern flicker and causes the distant silhouette of **The Watcher** to manifest on the high abyss ledge across the chasm ($X: -15, Y: 32, Z: -12$).
