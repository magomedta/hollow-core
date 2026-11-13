# scripts/world/m1_level_manager.gd
class_name M1LevelManager
extends Node3D

## Level Manager for Milestone 1 (Vertical Slice):
## «Шлюзовая Станция 4 и Шурф Эха» (Airlock Station 4 & Echo Shaft).
## Coordinates 5 distinct geological zones:
## - Zone A: Approach Tunnel (Permafrost descent, depth marker, severed cables)
## - Zone B: Airlock Station 4 (Airlock portal, surveyor desk, D-01, drainage valve)
## - Zone C: Echo Shaft (20m vertical chasm, mineral veins, resonant rock faces)
## - Zone D: Abandoned Camp (Tents, cots, radio beacon, coffee mug, blocked door)
## - Zone E: Lower Sump & Culmination (Drained collector, EE-06 Safe, Watcher ledge)

const VoxelWorldClass = preload("res://scripts/voxel_world.gd")
const WorldConfigClass = preload("res://scripts/world/world_config.gd")
const DocumentD01Class = preload("res://scripts/narrative/document_d01.gd")
const EasterEgg06Class = preload("res://scripts/narrative/easter_egg_06.gd")
const DrainageValveClass = preload("res://scripts/world/drainage_valve.gd")
const RockAnchorClass = preload("res://scripts/gameplay/rock_anchor.gd")
const TheWatcherClass = preload("res://scripts/the_watcher.gd")
const SubterraneanWaterClass = preload("res://scripts/world/subterranean_water.gd")
const DocumentPropClass = preload("res://scripts/narrative/document_prop.gd")
const AudiologPropClass = preload("res://scripts/narrative/audiolog_prop.gd")
const EasterEggPropClass = preload("res://scripts/narrative/easter_egg_prop.gd")

var voxel_world: Node3D = null
var world_config: Resource = null
var props_container: Node3D = null

# Key Interactive Props
var doc_d01_prop: Node3D = null
var ee06_safe_prop: Node3D = null
var drainage_valve_prop: Node3D = null
var ambient_watcher: Node3D = null

func _init(p_voxel_world: Node3D = null, p_config: Resource = null) -> void:
	voxel_world = p_voxel_world
	world_config = p_config if p_config != null else WorldConfigClass.get_default()

func _ready() -> void:
	add_to_group("level_manager")
	props_container = Node3D.new()
	props_container.name = "M1Props"
	add_child(props_container)

## Builds and sculps the full 70x45x70m Vertical Slice geometry
func build_vertical_slice_world() -> void:
	if voxel_world == null:
		return

	print("[M1 Level] Sculpting 'Airlock Station 4 & Echo Shaft' geometry...")

	_carve_zone_a_approach()
	_carve_zone_b_airlock_station()
	_carve_zone_c_echo_shaft()
	_carve_zone_d_abandoned_camp()
	_carve_zone_e_lower_sump()
	_spawn_interactive_props()

## Zone A: Glacial Cryosphere Descent to Station 4 (X: 0..12, Y: 44..58)
func _carve_zone_a_approach() -> void:
	# Clear wide, atmospheric sloping glacial tunnel from surface down to Station 4
	for step in range(13):
		var x = step
		var y = 56 - step # Slopes down from 56 to 44
		# Carve tunnel width from Z = -12 to Z = 2
		for z in range(-12, 3):
			for dy in range(1, 6):
				voxel_world.set_block(x, y + dy, z, VoxelWorld.BlockType.AIR, false)

		# Floor support: wooden planks, stone footing, and glistening permafrost ice runs
		for z in range(-12, 3):
			var fl_type = VoxelWorld.BlockType.WOOD_PLANKS if step % 2 == 0 else VoxelWorld.BlockType.STONE
			# Glacial ice patches on the walkway (steps 3..5 and 8..10)
			if (step >= 3 and step <= 5 and z >= -8 and z <= -4) or (step >= 8 and step <= 10 and z >= -6 and z <= -2):
				fl_type = VoxelWorld.BlockType.PERMAFROST_ICE
			voxel_world.set_block(x, y, z, fl_type, false)

		# Glacial Permafrost & Calcite Ice walls lining the tunnel
		for dy in range(1, 6):
			var ice_type = VoxelWorld.BlockType.PERMAFROST_ICE if (step + dy) % 3 != 0 else VoxelWorld.BlockType.CALCITE
			voxel_world.set_block(x, y + dy, -13, ice_type, false)
			voxel_world.set_block(x, y + dy, 3, ice_type, false)

		# Ceiling Permafrost with hanging Calcite icicles
		for z in range(-12, 3):
			voxel_world.set_block(x, y + 5, z, VoxelWorld.BlockType.PERMAFROST_ICE, false)
		if step % 3 == 1:
			voxel_world.set_block(x, y + 4, -10, VoxelWorld.BlockType.CALCITE, false)
			voxel_world.set_block(x, y + 4, -8, VoxelWorld.BlockType.CALCITE, false)
			voxel_world.set_block(x, y + 4, 0, VoxelWorld.BlockType.CALCITE, false)

		# Timber reinforcement arches every 3 steps
		if step % 3 == 0:
			for dy in range(1, 5):
				voxel_world.set_block(x, y + dy, -12, VoxelWorld.BlockType.HEWN_TIMBER, false)
				voxel_world.set_block(x, y + dy, 2, VoxelWorld.BlockType.HEWN_TIMBER, false)
			for z in range(-12, 3):
				voxel_world.set_block(x, y + 5, z, VoxelWorld.BlockType.HEWN_TIMBER, false)

	# Depth Marker Stencil on Wall at X = 8, Y = 50, Z = 2
	voxel_world.set_block(8, 50, 2, VoxelWorld.BlockType.SLATE_BRICK, false)

## Zone B: Airlock Station 4 (X: 10..22, Y: 38..45, Z: -5..-16)
func _carve_zone_b_airlock_station() -> void:
	# Hollow out the station chamber (12 x 7 x 11 meters)
	for x in range(10, 23):
		for y in range(39, 46):
			for z in range(-16, -4):
				voxel_world.set_block(x, y, z, VoxelWorld.BlockType.AIR, false)

	# Slate brick floor with central recessed drainage channel (X = 15..17, Z = -16..-5)
	for x in range(10, 23):
		for z in range(-16, -4):
			if (x >= 15 and x <= 17) and (z >= -15 and z <= -6):
				voxel_world.set_block(x, 37, z, VoxelWorld.BlockType.SLATE_BRICK, false)
				voxel_world.set_block(x, 38, z, VoxelWorld.BlockType.AIR, false) # Drainage trench
			else:
				voxel_world.set_block(x, 38, z, VoxelWorld.BlockType.SLATE_BRICK, false)

	# Heavy Portal Bulkhead Wall at X = 10 (entrance from Zone A)
	for y in range(39, 45):
		for z in range(-16, -4):
			if not (abs(z - (-10)) <= 1 and y <= 42):
				voxel_world.set_block(10, y, z, VoxelWorld.BlockType.SLATE_BRICK, false)

	# Workstation table & supply crates
	voxel_world.set_block(12, 39, -6, VoxelWorld.BlockType.CARGO_CRATE, false)
	voxel_world.set_block(13, 39, -6, VoxelWorld.BlockType.CARGO_CRATE, false)
	voxel_world.set_block(12, 39, -7, VoxelWorld.BlockType.WOOD_PLANKS, false)

## Zone C: Echo Shaft & Bioluminescent Chasm (X: -15..5, Y: 22..44, Z: -15..-34)
func _carve_zone_c_echo_shaft() -> void:
	# Immense 22m high vertical chasm dropping into the abyss
	for x in range(-15, 6):
		for z in range(-34, -14):
			for y in range(23, 44):
				voxel_world.set_block(x, y, z, VoxelWorld.BlockType.AIR, false)

	# Deep basalt floor with jagged fissures
	for x in range(-15, 6):
		for z in range(-34, -14):
			voxel_world.set_block(x, 22, z, VoxelWorld.BlockType.DEEP_BASALT, false)

	# High Overlook Ledge along East Wall (X = 2..5, Y = 33, Z = -32..-16)
	for z in range(-32, -16):
		for x in range(2, 6):
			voxel_world.set_block(x, 33, z, VoxelWorld.BlockType.DEEP_BASALT, false)

	# High Watcher Ledge along West Wall (X = -16..-12, Y = 32..33, Z = -26..-18)
	for z in range(-26, -17):
		for x in range(-16, -11):
			voxel_world.set_block(x, 32, z, VoxelWorld.BlockType.DEEP_BASALT, false)

	# Intermediate Mineral Terraces at Y = 27 (stepping stones & mineral shelves)
	for z in range(-30, -22):
		for x in range(-7, -2):
			voxel_world.set_block(x, 26, z, VoxelWorld.BlockType.DEEP_BASALT, false)

	# Bioluminescent Mushroom Colonies on Overlook Ledge & Mid-Terrace
	voxel_world.set_block(3, 34, -21, VoxelWorld.BlockType.BIOLUM_MUSHROOM, false)
	voxel_world.set_block(4, 34, -22, VoxelWorld.BlockType.BIOLUM_MUSHROOM, false)
	voxel_world.set_block(3, 34, -24, VoxelWorld.BlockType.BIOLUM_MUSHROOM, false)
	voxel_world.set_block(4, 34, -27, VoxelWorld.BlockType.BIOLUM_MUSHROOM, false)

	voxel_world.set_block(-5, 27, -24, VoxelWorld.BlockType.BIOLUM_MUSHROOM, false)
	voxel_world.set_block(-4, 27, -26, VoxelWorld.BlockType.BIOLUM_MUSHROOM, false)
	voxel_world.set_block(-6, 27, -27, VoxelWorld.BlockType.BIOLUM_MUSHROOM, false)

	voxel_world.set_block(0, 23, -22, VoxelWorld.BlockType.BIOLUM_MUSHROOM, false)
	voxel_world.set_block(-2, 23, -28, VoxelWorld.BlockType.BIOLUM_MUSHROOM, false)

	# Amethyst Geode Crystals in Deep Basalt Cliff Alcoves (Recessed away from player ledge)
	voxel_world.set_block(5, 31, -29, VoxelWorld.BlockType.CRYSTAL_AMETHYST, false)
	voxel_world.set_block(5, 32, -30, VoxelWorld.BlockType.CRYSTAL_AMETHYST, false)
	voxel_world.set_block(-15, 31, -29, VoxelWorld.BlockType.CRYSTAL_AMETHYST, false)

	# Phosphor Ore & Copper Ore Veins
	for vy in range(25, 33):
		voxel_world.set_block(5, vy, -25, VoxelWorld.BlockType.PHOSPHOR_ORE, false)
		voxel_world.set_block(5, vy + 1, -26, VoxelWorld.BlockType.IRON_ORE, false)
		voxel_world.set_block(-14, vy, -24, VoxelWorld.BlockType.COPPER_ORE, false)
		voxel_world.set_block(-14, vy + 1, -25, VoxelWorld.BlockType.CALCITE, false)

	# Hanging Calcite Stalactites from Chasm Roof (Y = 43 down to 40)
	for sx in [-4, 0, 3]:
		for sz in [-28, -22]:
			voxel_world.set_block(sx, 43, sz, VoxelWorld.BlockType.CALCITE, false)
			voxel_world.set_block(sx, 42, sz, VoxelWorld.BlockType.CALCITE, false)
			voxel_world.set_block(sx, 41, sz, VoxelWorld.BlockType.CALCITE, false)

	# Hanging Lichen Roots
	voxel_world.set_block(-2, 43, -25, VoxelWorld.BlockType.LICHEN_ROOT, false)
	voxel_world.set_block(-2, 42, -25, VoxelWorld.BlockType.LICHEN_ROOT, false)
	voxel_world.set_block(1, 43, -27, VoxelWorld.BlockType.LICHEN_ROOT, false)
	voxel_world.set_block(1, 42, -27, VoxelWorld.BlockType.LICHEN_ROOT, false)

	# Cascading Subterranean Waterfall
	for wy in range(23, 40):
		voxel_world.set_block(-10, wy, -33, VoxelWorld.BlockType.WATER_SPRING, false)

	# Columnar Hexagonal Basalt Formations rising from chasm floor
	# Hex Column Cluster 1 (X: -11..-9, Z: -22..-20, height Y: 22..30)
	for py in range(23, 31):
		voxel_world.set_block(-10, py, -21, VoxelWorld.BlockType.DEEP_BASALT, false)
		voxel_world.set_block(-11, py, -21, VoxelWorld.BlockType.DEEP_BASALT, false)
		voxel_world.set_block(-10, py, -22, VoxelWorld.BlockType.DEEP_BASALT, false)

	# Hex Column Cluster 2 (X: -6..-4, Z: -29..-27, height Y: 22..28)
	for py in range(23, 29):
		voxel_world.set_block(-5, py, -28, VoxelWorld.BlockType.DEEP_BASALT, false)
		voxel_world.set_block(-6, py, -28, VoxelWorld.BlockType.DEEP_BASALT, false)
		voxel_world.set_block(-5, py, -27, VoxelWorld.BlockType.DEEP_BASALT, false)

	# Hex Column Cluster 3 (Near Overlook Ledge, X: 1..2, Z: -24..-22, height Y: 22..32)
	for py in range(23, 33):
		voxel_world.set_block(1, py, -23, VoxelWorld.BlockType.DEEP_BASALT, false)
		voxel_world.set_block(0, py, -24, VoxelWorld.BlockType.DEEP_BASALT, false)

	# Waterfall Plunge Pool at chasm floor (X = -12..-8, Z = -34..-31)
	for wx in range(-12, -7):
		for wz in range(-34, -30):
			voxel_world.set_block(wx, 22, wz, VoxelWorld.BlockType.DEEP_BASALT, false)
			voxel_world.set_block(wx, 21, wz, VoxelWorld.BlockType.DEEP_BASALT, false)

## Zone D: Abandoned Camp (X: -24..-8, Y: 25..31, Z: -4..12)
func _carve_zone_d_abandoned_camp() -> void:
	# Carve sheltered natural cave grotto
	for x in range(-24, -7):
		for z in range(-4, 13):
			for y in range(26, 32):
				voxel_world.set_block(x, y, z, VoxelWorld.BlockType.AIR, false)

	# Cobblestone and dirt floor
	for x in range(-24, -7):
		for z in range(-4, 13):
			voxel_world.set_block(x, 25, z, VoxelWorld.BlockType.COBBLESTONE, false)

	# Tent frames (Hewn Timber)
	for dy in range(1, 4):
		voxel_world.set_block(-18, 25 + dy, 4, VoxelWorld.BlockType.HEWN_TIMBER, false)
		voxel_world.set_block(-18, 25 + dy, 8, VoxelWorld.BlockType.HEWN_TIMBER, false)
		voxel_world.set_block(-14, 25 + dy, 4, VoxelWorld.BlockType.HEWN_TIMBER, false)
		voxel_world.set_block(-14, 25 + dy, 8, VoxelWorld.BlockType.HEWN_TIMBER, false)

	# Supply crates and workbench
	voxel_world.set_block(-17, 26, 5, VoxelWorld.BlockType.CARGO_CRATE, false)
	voxel_world.set_block(-16, 26, 5, VoxelWorld.BlockType.CARGO_CRATE, false)
	voxel_world.set_block(-15, 26, 5, VoxelWorld.BlockType.WOOD_PLANKS, false)

	# Water spring pool in corner of camp
	voxel_world.set_block(-22, 26, 10, VoxelWorld.BlockType.WATER_SPRING, false)

## Zone E: Lower Sump & Culmination (X: 12..18, Y: 25..31, Z: -8..-16)
func _carve_zone_e_lower_sump() -> void:
	# Vertical drop shaft from Station 4 floor (Y=38) down to Sump floor (Y=28)
	for x in range(13, 17):
		for z in range(-14, -10):
			for y in range(29, 39):
				voxel_world.set_block(x, y, z, VoxelWorld.BlockType.AIR, false)

	# Sump chamber floor
	for x in range(12, 19):
		for z in range(-16, -8):
			voxel_world.set_block(x, 28, z, VoxelWorld.BlockType.DEEP_BASALT, false)

## Spawns all interactive props, document boxes, and EE-06 safe
func _spawn_interactive_props() -> void:
	# 0. Crash Site of Cage «ТяжМаш-4» at Zone A (Approach tunnel)
	_build_tyazhmash_cage_wreckage()

	# In-world document DOC-08 (Flight manifest TyazhMash-4) at Crash Site
	var doc_d08 = DocumentPropClass.new()
	doc_d08.document_id = "DOC-08"
	doc_d08.name = "Document_DOC08_CrashSite"
	doc_d08.position = Vector3(1.8, 57.1, 0.8)
	props_container.add_child(doc_d08)

	# In-world audiolog AUD-18 (Edward's Olympus Day 1) at Crash Site
	var aud_18 = AudiologPropClass.new()
	aud_18.audio_tape_id = "AUD-18"
	aud_18.name = "Audiolog_AUD18_CrashSite"
	aud_18.position = Vector3(0.5, 57.1, -1.0)
	props_container.add_child(aud_18)

	# In-world audiolog AUD-09 (TyazhMash-4 crash moment) inside cage wreckage
	var aud_09 = AudiologPropClass.new()
	aud_09.audio_tape_id = "AUD-09"
	aud_09.name = "Audiolog_AUD09_CageInterior"
	aud_09.position = Vector3(0.0, 57.2, 0.0)
	props_container.add_child(aud_09)

	# 1. Document D-01 Box at Airlock Station 4
	doc_d01_prop = DocumentD01Class.new()
	doc_d01_prop.name = "Document_D01_Box"
	doc_d01_prop.position = Vector3(12.5, 39.4, -6.5)
	props_container.add_child(doc_d01_prop)

	# Additional narrative documents & audiologs at Airlock Station 4
	var aud_01 = AudiologPropClass.new()
	aud_01.audio_tape_id = "AUD-01"
	aud_01.name = "Audiolog_AUD01_Station4"
	aud_01.position = Vector3(13.2, 39.4, -6.5)
	props_container.add_child(aud_01)

	var doc_d03 = DocumentPropClass.new()
	doc_d03.document_id = "DOC-03"
	doc_d03.name = "Document_DOC03_Station4"
	doc_d03.position = Vector3(11.8, 39.4, -6.5)
	props_container.add_child(doc_d03)

	# DOC-16: Orion safe manual with 1924 code hint at Station 4 mechanic table
	var doc_d16 = DocumentPropClass.new()
	doc_d16.document_id = "DOC-16"
	doc_d16.name = "Document_DOC16_MechanicBench"
	doc_d16.position = Vector3(14.5, 39.4, -4.5)
	props_container.add_child(doc_d16)

	# AUD-10: Acoustic safety briefing tape at Station 4 admin rack
	var aud_10 = AudiologPropClass.new()
	aud_10.audio_tape_id = "AUD-10"
	aud_10.name = "Audiolog_AUD10_Station4Admin"
	aud_10.position = Vector3(10.5, 39.4, -8.0)
	props_container.add_child(aud_10)

	# 2. Drainage Valve Wheel at Station 4 (drains lower sump)
	drainage_valve_prop = DrainageValveClass.new()
	drainage_valve_prop.name = "DrainageValve_Station4"
	drainage_valve_prop.position = Vector3(16.2, 39.5, -12.0)
	drainage_valve_prop.rotation_degrees = Vector3(0, -90, 0)
	props_container.add_child(drainage_valve_prop)

	# 3. EE-06 Drowned Safe in Lower Sump
	ee06_safe_prop = EasterEgg06Class.new()
	ee06_safe_prop.name = "EE06_DrownedSafe"
	ee06_safe_prop.position = Vector3(14.0, 28.5, -12.0)
	props_container.add_child(ee06_safe_prop)

	# Sump narrative assets: Cape Silent intercept cassette & telegram
	var aud_07 = AudiologPropClass.new()
	aud_07.audio_tape_id = "AUD-07"
	aud_07.name = "Audiolog_AUD07_Sump"
	aud_07.position = Vector3(14.6, 28.6, -11.5)
	props_container.add_child(aud_07)

	var doc_d06 = DocumentPropClass.new()
	doc_d06.document_id = "DOC-06"
	doc_d06.name = "Document_DOC06_Sump"
	doc_d06.position = Vector3(13.4, 28.6, -12.5)
	props_container.add_child(doc_d06)

	# AUD-13: 1946 Sump pump accident tape near drainage flange
	var aud_13 = AudiologPropClass.new()
	aud_13.audio_tape_id = "AUD-13"
	aud_13.name = "Audiolog_AUD13_PumpFlange"
	aud_13.position = Vector3(16.5, 28.6, -10.0)
	props_container.add_child(aud_13)

	# Narrative props at Abandoned Camp (Zone D)
	var aud_03 = AudiologPropClass.new()
	aud_03.audio_tape_id = "AUD-03"
	aud_03.name = "Audiolog_AUD03_Camp"
	aud_03.position = Vector3(-16.0, 26.2, 5.0)
	props_container.add_child(aud_03)

	var doc_d09 = DocumentPropClass.new()
	doc_d09.document_id = "DOC-09"
	doc_d09.name = "Document_DOC09_Camp"
	doc_d09.position = Vector3(-17.2, 26.2, 5.0)
	props_container.add_child(doc_d09)

	# Physical Easter Eggs (EE-01..EE-05, EE-07..EE-09) placed in M1 geometry
	var egg_placements = [
		{ "id": "EE-01", "pos": Vector3(12.0, 42.0, -8.0) },
		{ "id": "EE-02", "pos": Vector3(-6.0, 40.0, 14.0) },
		{ "id": "EE-03", "pos": Vector3(18.0, 38.0, 2.0) },
		{ "id": "EE-04", "pos": Vector3(0.0, 44.0, -15.0) }, # Phosphor handprint (CH-04 clue 2!)
		{ "id": "EE-05", "pos": Vector3(24.0, 35.0, -10.0) },
		{ "id": "EE-07", "pos": Vector3(-12.0, 30.0, 5.0) },
		{ "id": "EE-08", "pos": Vector3(8.0, 28.0, -20.0) },
		{ "id": "EE-09", "pos": Vector3(-22.0, 25.0, 0.0) }
	]
	for ep in egg_placements:
		var egg_prop = EasterEggPropClass.new()
		egg_prop.easter_egg_id = ep["id"]
		egg_prop.name = "EasterEgg_%s" % ep["id"]
		egg_prop.position = ep["pos"]
		props_container.add_child(egg_prop)

	# 4. Starting Wall Anchor placed near Echo Shaft ledge (demonstrates climbing mechanics)
	var anchor_init = RockAnchorClass.new(Vector3(1, 0, 0), 4.0)
	anchor_init.name = "Sample_Expedition_Anchor"
	anchor_init.position = Vector3(3.2, 34.5, -20.0)
	props_container.add_child(anchor_init)

	# 5. Station 4 Surveyor Workstation Warm Overhead Lamp
	var station_light = OmniLight3D.new()
	station_light.name = "Station4_WorkstationLamp"
	station_light.position = Vector3(12.5, 41.2, -6.5)
	station_light.light_color = Color(1.0, 0.82, 0.50)
	station_light.light_energy = 1.6
	station_light.omni_range = 8.0
	station_light.shadow_enabled = true
	props_container.add_child(station_light)

	# 6. Bioluminescent Mushroom Colony Glow in Echo Shaft (Zone C)
	var bio_light1 = OmniLight3D.new()
	bio_light1.name = "BioMushroomGlow_Ledge"
	bio_light1.position = Vector3(3.5, 34.8, -22.5)
	bio_light1.light_color = Color(0.18, 0.90, 0.82) # Vibrant bioluminescent cyan
	bio_light1.light_energy = 1.3
	bio_light1.omni_range = 9.0
	bio_light1.shadow_enabled = true
	props_container.add_child(bio_light1)

	var bio_light2 = OmniLight3D.new()
	bio_light2.name = "BioMushroomGlow_Abyss"
	bio_light2.position = Vector3(-4.0, 24.5, -25.0)
	bio_light2.light_color = Color(0.12, 0.75, 0.80)
	bio_light2.light_energy = 1.8
	bio_light2.omni_range = 16.0
	bio_light2.shadow_enabled = false
	props_container.add_child(bio_light2)

	# 7. The Watcher standing on distant high ledge across the chasm (Herobrine in Fog horror)
	ambient_watcher = TheWatcherClass.new()
	ambient_watcher.name = "AmbientWatcher_ChasmLedge"
	ambient_watcher.position = Vector3(-14.0, 32.5, -22.0)
	ambient_watcher.is_ambient_showcase = true
	props_container.add_child(ambient_watcher)

	# 8. Subterranean Water Body 1: Airlock Station 4 Drainage Sluice Channel
	var water_sluice = SubterraneanWaterClass.new(Vector3(2.8, 0.7, 10.5))
	water_sluice.name = "Water_Station4_Sluice"
	water_sluice.position = Vector3(16.0, 37.6, -10.5)
	props_container.add_child(water_sluice)

	# 9. Subterranean Water Body 2: Basaltic Abyssal Waterfall Plunge Pool
	var water_plunge = SubterraneanWaterClass.new(Vector3(6.0, 1.2, 5.0))
	water_plunge.name = "Water_AbyssalPlungePool"
	water_plunge.position = Vector3(-10.0, 22.4, -32.0)
	props_container.add_child(water_plunge)

func _build_tyazhmash_cage_wreckage() -> void:
	var wreckage = Node3D.new()
	wreckage.name = "TyazhMash_Cage_Wreckage"
	wreckage.position = Vector3(1.0, 56.5, 0.0)

	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.20, 0.22, 0.25, 1.0)
	steel_mat.metallic = 0.85
	steel_mat.roughness = 0.60

	# 4 crumpled upright beams
	for pos_offset in [Vector3(-1.1, 1.2, -1.1), Vector3(1.1, 1.1, -1.1), Vector3(-1.1, 1.3, 1.1), Vector3(1.1, 1.0, 1.1)]:
		var beam = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.06
		cyl.bottom_radius = 0.06
		cyl.height = 2.4
		cyl.radial_segments = 6
		beam.mesh = cyl
		beam.material_override = steel_mat
		beam.position = pos_offset
		beam.rotation_degrees = Vector3(randf_range(-10, 10), randf_range(-15, 15), randf_range(-12, 12))
		wreckage.add_child(beam)

	# Crushed cage roof plate
	var roof = MeshInstance3D.new()
	var r_box = BoxMesh.new()
	r_box.size = Vector3(2.4, 0.12, 2.4)
	roof.mesh = r_box
	roof.material_override = steel_mat
	roof.position = Vector3(0.1, 2.35, 0.0)
	roof.rotation_degrees = Vector3(8.0, 5.0, -10.0)
	wreckage.add_child(roof)

	# Severed hanging cable strands
	var cable_mat = StandardMaterial3D.new()
	cable_mat.albedo_color = Color(0.15, 0.16, 0.18, 1.0)
	cable_mat.metallic = 0.90
	for cx in [-0.4, 0.4]:
		var cable = MeshInstance3D.new()
		var c_cyl = CylinderMesh.new()
		c_cyl.top_radius = 0.02
		c_cyl.bottom_radius = 0.02
		c_cyl.height = 2.8
		cable.mesh = c_cyl
		cable.material_override = cable_mat
		cable.position = Vector3(cx, 3.8, 0.0)
		cable.rotation_degrees = Vector3(randf_range(-5, 5), 0, randf_range(-8, 8))
		wreckage.add_child(cable)

	# Flickering emergency lamp
	var emerg_light = OmniLight3D.new()
	emerg_light.name = "EmergencyAmberBeacon"
	emerg_light.position = Vector3(0.0, 2.1, 0.0)
	emerg_light.light_color = Color(1.0, 0.65, 0.25)
	emerg_light.light_energy = 0.8
	emerg_light.omni_range = 6.0
	wreckage.add_child(emerg_light)

	props_container.add_child(wreckage)
