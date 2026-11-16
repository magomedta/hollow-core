# scripts/world/m1_level_manager.gd
class_name M1LevelManager
extends Node3D

## Level Manager for Milestone 1 (Vertical Slice):
## «Шлюзовая Станция 4 и Шурф Эха» (Airlock Station 4 & Echo Shaft).
## Coordinates 5 fully interconnected geological zones with 100% solid enclosures:
## - Zone A: Approach Tunnel (Stepped glacial descent, crash cage wreckage, illuminated signage)
## - Zone B: Airlock Station 4 (Handcrafted surveyor desk, D-01, drainage valve, sump ladder)
## - Zone C: Echo Shaft (22m vertical chasm, walkable suspension bridge, hex columns, waterfall)
## - Zone D: Abandoned Camp (Sheltered grotto camp, canvas tents, radio transceiver, grotto spring)
## - Zone E: Lower Sump (Drained drainage sump, steel service ladder, EE-06 Safe, overflow culvert)
##
## ALL zones are connected via walkable passages with zero dead ends, zero pits, and zero void leaks.

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
var sump_water: Node3D = null
var surveyor_desk: Node3D = null

func _init(p_voxel_world: Node3D = null, p_config: Resource = null) -> void:
	voxel_world = p_voxel_world
	world_config = p_config if p_config != null else WorldConfigClass.get_default()
	props_container = Node3D.new()
	props_container.name = "M1Props"
	add_child(props_container)

func _ready() -> void:
	add_to_group("level_manager")
	if props_container == null:
		props_container = Node3D.new()
		props_container.name = "M1Props"
		add_child(props_container)

## Builds and sculps the full interconnected Vertical Slice world
func build_vertical_slice_world() -> void:
	if voxel_world == null:
		return

	print("[M1 Level] Sculpting 'Airlock Station 4 & Echo Shaft' geometry...")

	_build_hermetic_enclosing_shell()
	_carve_zone_a_approach()
	_carve_zone_b_airlock_station()
	_carve_zone_c_echo_shaft()
	_carve_zone_d_abandoned_camp()
	_carve_zone_e_lower_sump()
	_carve_interconnecting_corridors()
	_spawn_interactive_props()
	_build_architectural_structures()

## 0. Hermetic Shell: Fills outer world bounds with solid bedrock/stone so NO VOID is ever exposed
func _build_hermetic_enclosing_shell() -> void:
	for x in range(-32, 33):
		for z in range(-42, 21):
			for y in range(18, 22):
				voxel_world.set_block(x, y, z, VoxelWorld.BlockType.DEEP_BASALT, false)
			for y in range(60, 66):
				voxel_world.set_block(x, y, z, VoxelWorld.BlockType.STONE, false)

## Zone A: Glacial Cryosphere Descent to Station 4 (X: -4..10, Y: 38..58, Z: -4..4)
func _carve_zone_a_approach() -> void:
	# 1. Crash Site Cave (X: -5..2, Z: -5..5, Y: 56..62)
	for cx in range(-5, 3):
		for cz in range(-5, 6):
			for cy in range(57, 62):
				voxel_world.set_block(cx, cy, cz, VoxelWorld.BlockType.AIR, false)
			# Solid natural rock floor with rubble around wreckage
			for fy in range(45, 57):
				var f_mat = VoxelWorld.BlockType.COBBLESTONE if fy == 56 and abs(cx) <= 2 and abs(cz) <= 2 else VoxelWorld.BlockType.STONE
				voxel_world.set_block(cx, fy, cz, f_mat, false)
			# High vaulted ceiling
			voxel_world.set_block(cx, 62, cz, VoxelWorld.BlockType.STONE, false)
			voxel_world.set_block(cx, 63, cz, VoxelWorld.BlockType.STONE, false)

		# Enclosing rock walls around crash cave (Uniform solid weathered stone)
		for cy in range(56, 63):
			voxel_world.set_block(cx, cy, -5, VoxelWorld.BlockType.STONE, false)
			voxel_world.set_block(cx, cy, 5, VoxelWorld.BlockType.STONE, false)
	for cz in range(-5, 6):
		for cy in range(56, 63):
			voxel_world.set_block(-5, cy, cz, VoxelWorld.BlockType.STONE, false)

	# 2. Linear Stepped Mining Decline Gallery (X: 0..10, Z: -2..2)
	# Continuous 5m-wide gallery with smooth sightlines down to Station 4
	var step_y = [56, 55, 54, 53, 52, 51, 48, 45, 42, 40, 38]
	var step_ceil = [61, 61, 60, 59, 58, 57, 55, 53, 50, 48, 46]
	for step in range(step_y.size()):
		var x = step
		var fl_y = step_y[step]
		var c_y = step_ceil[step]
		for z in range(-2, 3):
			# Wide open vertical headroom from floor up to ceiling
			for y in range(fl_y + 1, c_y + 1):
				voxel_world.set_block(x, y, z, VoxelWorld.BlockType.AIR, false)

			# Solid stone stair step foundation
			for fy in range(30, fl_y + 1):
				var fl_mat = VoxelWorld.BlockType.SLATE_BRICK if step >= 6 and fy == fl_y else (VoxelWorld.BlockType.COBBLESTONE if fy == fl_y else VoxelWorld.BlockType.STONE)
				voxel_world.set_block(x, fy, z, fl_mat, false)

			# Solid stone ceiling — NO ICE in gallery ceiling
			voxel_world.set_block(x, c_y + 1, z, VoxelWorld.BlockType.STONE, false)
			voxel_world.set_block(x, c_y + 2, z, VoxelWorld.BlockType.STONE, false)

		# Side walls lining the decline: Solid continuous stone and slate brick.
		# NO zebra stripes! NO alternating horizontal bands!
		for wy in range(fl_y, c_y + 3):
			var w_mat = VoxelWorld.BlockType.STONE if step < 6 else VoxelWorld.BlockType.SLATE_BRICK
			voxel_world.set_block(x, wy, -3, w_mat, false)
			voxel_world.set_block(x, wy, 3, w_mat, false)

		# Structural Timber Arch Frames spaced cleanly every 3 steps (step 0, 3, 6, 9)
		if step % 3 == 0:
			for ty in range(fl_y + 1, c_y + 1):
				voxel_world.set_block(x, ty, -2, VoxelWorld.BlockType.HEWN_TIMBER, false)
				voxel_world.set_block(x, ty, 2, VoxelWorld.BlockType.HEWN_TIMBER, false)
			for z in range(-2, 3):
				voxel_world.set_block(x, c_y, z, VoxelWorld.BlockType.HEWN_TIMBER, false)

	# ПРИНУДИТЕЛЬНОЕ ЗАМУРОВЫВАНИЕ боковых стен декалайна — НИКАКОГО льда!
	for step in range(step_y.size()):
		var x = step
		var fl_y = step_y[step]
		var c_y = step_ceil[step]
		for wy in range(fl_y, c_y + 4):
			for wz_ext in range(-6, -2): # Слева от тоннеля
				var ext_mat = VoxelWorld.BlockType.SLATE_BRICK if (step >= 6 and wz_ext == -3) else VoxelWorld.BlockType.STONE
				voxel_world.set_block(x, wy, wz_ext, ext_mat, false)
			for wz_ext in range(3, 7): # Справа от тоннеля
				var ext_mat = VoxelWorld.BlockType.SLATE_BRICK if (step >= 6 and wz_ext == 3) else VoxelWorld.BlockType.STONE
				voxel_world.set_block(x, wy, wz_ext, ext_mat, false)
		# Потолок — забить STONE выше c_y, никакого льда!
		for wy in range(c_y + 1, c_y + 5):
			for wz in range(-3, 4):
				voxel_world.set_block(x, wy, wz, VoxelWorld.BlockType.STONE, false)

	# Crash Cave: заблокируй лёд в стенах crash cave:
	for cx in range(-5, 3):
		for cz in range(-5, 6):
			for wy in range(56, 65):
				# Потолок crash cave — только STONE
				if wy >= 62:
					voxel_world.set_block(cx, wy, cz, VoxelWorld.BlockType.STONE, false)

## Zone B: Airlock Station 4 (X: 10..24, Y: 38..46, Z: -16..3)
func _carve_zone_b_airlock_station() -> void:
	# Hollow out the station chamber interior (13 x 7 x 19 meters)
	for x in range(11, 24):
		for y in range(39, 46):
			for z in range(-16, 4):
				voxel_world.set_block(x, y, z, VoxelWorld.BlockType.AIR, false)

	# Full Slate Brick enclosing walls and ceiling (Hermetic double-thick masonry seal)
	for x in range(9, 26):
		for z in range(-18, 6):
			# Solid multi-layer ceiling (Y: 46..58)
			voxel_world.set_block(x, 46, z, VoxelWorld.BlockType.SLATE_BRICK, false)
			for by in range(47, 59):
				voxel_world.set_block(x, by, z, VoxelWorld.BlockType.STONE, false)
			# North wall at Z = -17 and -18
			for y in range(37, 47):
				voxel_world.set_block(x, y, -17, VoxelWorld.BlockType.SLATE_BRICK, false)
				voxel_world.set_block(x, y, -18, VoxelWorld.BlockType.STONE, false)
			# South wall at Z = 4 and 5
			for y in range(37, 47):
				voxel_world.set_block(x, y, 4, VoxelWorld.BlockType.SLATE_BRICK, false)
				voxel_world.set_block(x, y, 5, VoxelWorld.BlockType.STONE, false)

	# East wall at X = 24 and 25
	for y in range(37, 47):
		for z in range(-18, 6):
			voxel_world.set_block(24, y, z, VoxelWorld.BlockType.SLATE_BRICK, false)
			voxel_world.set_block(25, y, z, VoxelWorld.BlockType.STONE, false)

	# West bulkhead wall (double-thick masonry at X = 9 and X = 10 with seamless doorways)
	for wx in [9, 10]:
		for y in range(37, 47):
			for z in range(-18, 6):
				# Main entry doorway from Zone A at Z = -2..2, Y = 39..43 (Seamless connection!)
				if (z >= -2 and z <= 2) and (y >= 39 and y <= 43):
					voxel_world.set_block(wx, y, z, VoxelWorld.BlockType.AIR, false)
				# West exit doorway to Echo Shaft at Z = -15..-13, Y = 39..42
				elif (z >= -15 and z <= -13) and (y >= 39 and y <= 42):
					voxel_world.set_block(wx, y, z, VoxelWorld.BlockType.AIR, false)
				else:
					voxel_world.set_block(wx, y, z, VoxelWorld.BlockType.SLATE_BRICK, false)

	# Solid slate brick floor with recessed drainage channel at X: 16..18, Z: -14..-6
	for x in range(10, 24):
		for z in range(-16, 4):
			if (x >= 16 and x <= 18) and (z >= -14 and z <= -6):
				voxel_world.set_block(x, 37, z, VoxelWorld.BlockType.SLATE_BRICK, false)
				voxel_world.set_block(x, 38, z, VoxelWorld.BlockType.AIR, false) # Drainage trench
			else:
				voxel_world.set_block(x, 38, z, VoxelWorld.BlockType.SLATE_BRICK, false)
			# Solid foundation under floor
			for fy in range(26, 37):
				voxel_world.set_block(x, fy, z, VoxelWorld.BlockType.STONE, false)

	# Solid drainage pipe pedestal at X: 18..19, Z: -12..-10 for the valve mount
	for px in range(18, 20):
		for pz in range(-12, -9):
			voxel_world.set_block(px, 37, pz, VoxelWorld.BlockType.SLATE_BRICK, false)
			voxel_world.set_block(px, 38, pz, VoxelWorld.BlockType.SLATE_BRICK, false)

## Zone C: Echo Shaft & Bioluminescent Chasm (X: -16..6, Y: 22..45, Z: -36..-14)
func _carve_zone_c_echo_shaft() -> void:
	# Immense 22m vertical chasm
	for x in range(-16, 7):
		for z in range(-36, -13):
			for y in range(23, 44):
				voxel_world.set_block(x, y, z, VoxelWorld.BlockType.AIR, false)
			# Solid rock roof above chasm
			for cy in range(44, 56):
				voxel_world.set_block(x, cy, z, VoxelWorld.BlockType.STONE, false)

	# Deep basalt floor with jagged fissures
	for x in range(-16, 7):
		for z in range(-36, -13):
			voxel_world.set_block(x, 22, z, VoxelWorld.BlockType.DEEP_BASALT, false)
			for y in range(22, 45):
				voxel_world.set_block(-17, y, z, VoxelWorld.BlockType.DEEP_BASALT, false)
				voxel_world.set_block(7, y, z, VoxelWorld.BlockType.DEEP_BASALT, false)

	for x in range(-17, 8):
		for y in range(22, 45):
			voxel_world.set_block(x, y, -37, VoxelWorld.BlockType.DEEP_BASALT, false)
			voxel_world.set_block(x, y, -13, VoxelWorld.BlockType.DEEP_BASALT, false)

	# High Overlook Balcony along East Wall (X: 2..6, Y: 33, Z: -26..-15)
	for z in range(-26, -14):
		for x in range(2, 7):
			voxel_world.set_block(x, 33, z, VoxelWorld.BlockType.DEEP_BASALT, false)
			for by in range(22, 33):
				voxel_world.set_block(x, by, z, VoxelWorld.BlockType.DEEP_BASALT, false)

	# High Watcher Ledge along West Wall (X: -16..-11, Y: 32, Z: -26..-17)
	for z in range(-26, -16):
		for x in range(-16, -10):
			voxel_world.set_block(x, 32, z, VoxelWorld.BlockType.DEEP_BASALT, false)

	# Intermediate Mineral Terraces at Y = 27 (stepping stones & mineral shelves)
	for z in range(-30, -21):
		for x in range(-7, -1):
			voxel_world.set_block(x, 26, z, VoxelWorld.BlockType.DEEP_BASALT, false)

	# Basalt Hexagonal Columns rising from chasm floor to form a natural stepping path
	for py in range(23, 31):
		voxel_world.set_block(-10, py, -21, VoxelWorld.BlockType.DEEP_BASALT, false)
		voxel_world.set_block(-11, py, -21, VoxelWorld.BlockType.DEEP_BASALT, false)
		voxel_world.set_block(-10, py, -22, VoxelWorld.BlockType.DEEP_BASALT, false)

	for py in range(23, 29):
		voxel_world.set_block(-5, py, -28, VoxelWorld.BlockType.DEEP_BASALT, false)
		voxel_world.set_block(-6, py, -28, VoxelWorld.BlockType.DEEP_BASALT, false)

	for py in range(23, 34):
		voxel_world.set_block(1, py, -23, VoxelWorld.BlockType.DEEP_BASALT, false)
		voxel_world.set_block(0, py, -24, VoxelWorld.BlockType.DEEP_BASALT, false)

	# Bioluminescent Mushroom Colonies
	voxel_world.set_block(3, 34, -21, VoxelWorld.BlockType.BIOLUM_MUSHROOM, false)
	voxel_world.set_block(4, 34, -22, VoxelWorld.BlockType.BIOLUM_MUSHROOM, false)
	voxel_world.set_block(-5, 27, -24, VoxelWorld.BlockType.BIOLUM_MUSHROOM, false)

	# Cascading Subterranean Waterfall in Chasm Corner
	for wy in range(23, 40):
		voxel_world.set_block(-10, wy, -33, VoxelWorld.BlockType.WATER_SPRING, false)

	# Waterfall Plunge Pool at chasm floor (X: -13..-6, Z: -36..-30)
	for wx in range(-13, -6):
		for wz in range(-36, -30):
			voxel_world.set_block(wx, 22, wz, VoxelWorld.BlockType.DEEP_BASALT, false)
			voxel_world.set_block(wx, 21, wz, VoxelWorld.BlockType.DEEP_BASALT, false)

## Zone D: Abandoned Camp (X: -26..-8, Y: 25..32, Z: -4..14)
func _carve_zone_d_abandoned_camp() -> void:
	for x in range(-26, -6):
		for z in range(-5, 14):
			for y in range(26, 32):
				voxel_world.set_block(x, y, z, VoxelWorld.BlockType.AIR, false)
			for cy in range(32, 55):
				voxel_world.set_block(x, cy, z, VoxelWorld.BlockType.STONE, false)
			voxel_world.set_block(x, 25, z, VoxelWorld.BlockType.COBBLESTONE, false)
			for fy in range(18, 25):
				voxel_world.set_block(x, fy, z, VoxelWorld.BlockType.STONE, false)

	for y in range(25, 33):
		for z in range(-5, 14):
			voxel_world.set_block(-26, y, z, VoxelWorld.BlockType.STONE, false)
			voxel_world.set_block(-7, y, z, VoxelWorld.BlockType.STONE, false)
		for x in range(-26, -6):
			voxel_world.set_block(x, y, -5, VoxelWorld.BlockType.STONE, false)
			voxel_world.set_block(x, y, 14, VoxelWorld.BlockType.STONE, false)

	# Tent frames (Hewn Timber)
	for dy in range(1, 4):
		voxel_world.set_block(-18, 25 + dy, 4, VoxelWorld.BlockType.HEWN_TIMBER, false)
		voxel_world.set_block(-18, 25 + dy, 8, VoxelWorld.BlockType.HEWN_TIMBER, false)
		voxel_world.set_block(-14, 25 + dy, 4, VoxelWorld.BlockType.HEWN_TIMBER, false)
		voxel_world.set_block(-14, 25 + dy, 8, VoxelWorld.BlockType.HEWN_TIMBER, false)

	# Camp workbench
	voxel_world.set_block(-17, 26, 5, VoxelWorld.BlockType.CARGO_CRATE, false)
	voxel_world.set_block(-16, 26, 5, VoxelWorld.BlockType.CARGO_CRATE, false)
	voxel_world.set_block(-15, 26, 5, VoxelWorld.BlockType.WOOD_PLANKS, false)

	# Spring pool
	voxel_world.set_block(-22, 26, 10, VoxelWorld.BlockType.WATER_SPRING, false)

## Zone E: Lower Sump & Culmination (X: 13..21, Y: 28..39, Z: -16..-8)
func _carve_zone_e_lower_sump() -> void:
	# Vertical service shaft from Station 4 floor (Y=38) down to Sump floor (Y=28)
	for x in range(15, 19):
		for z in range(-14, -10):
			for y in range(29, 39):
				voxel_world.set_block(x, y, z, VoxelWorld.BlockType.AIR, false)

	# Sump chamber floor and space
	for x in range(13, 21):
		for z in range(-16, -8):
			for y in range(29, 35):
				voxel_world.set_block(x, y, z, VoxelWorld.BlockType.AIR, false)
			voxel_world.set_block(x, 28, z, VoxelWorld.BlockType.DEEP_BASALT, false)
			for fy in range(18, 28):
				voxel_world.set_block(x, fy, z, VoxelWorld.BlockType.DEEP_BASALT, false)

	# Enclosing walls around sump
	for y in range(28, 39):
		for z in range(-17, -7):
			voxel_world.set_block(12, y, z, VoxelWorld.BlockType.SLATE_BRICK, false)
			voxel_world.set_block(21, y, z, VoxelWorld.BlockType.SLATE_BRICK, false)
		for x in range(12, 22):
			voxel_world.set_block(x, y, -17, VoxelWorld.BlockType.SLATE_BRICK, false)
			voxel_world.set_block(x, y, -7, VoxelWorld.BlockType.SLATE_BRICK, false)

## Interconnecting Corridors
func _carve_interconnecting_corridors() -> void:
	print("[M1 Level] Carving interconnecting corridors between zones...")

	# 1. Station 4 West Airlock to Echo Shaft Overlook (X: 6..10, Z: -15..-13)
	for x in range(6, 11):
		var y_mid = 34 + int((x - 6) * 0.8) # Gradual ramp
		for z in range(-15, -12):
			for dy in range(1, 5):
				voxel_world.set_block(x, y_mid + dy, z, VoxelWorld.BlockType.AIR, false)
			voxel_world.set_block(x, y_mid, z, VoxelWorld.BlockType.SLATE_BRICK, false)
			for fy in range(22, y_mid):
				voxel_world.set_block(x, fy, z, VoxelWorld.BlockType.STONE, false)
			voxel_world.set_block(x, y_mid + 5, z, VoxelWorld.BlockType.SLATE_BRICK, false)
		voxel_world.set_block(x, y_mid + 1, -16, VoxelWorld.BlockType.SLATE_BRICK, false)
		voxel_world.set_block(x, y_mid + 2, -16, VoxelWorld.BlockType.SLATE_BRICK, false)
		voxel_world.set_block(x, y_mid + 1, -12, VoxelWorld.BlockType.SLATE_BRICK, false)
		voxel_world.set_block(x, y_mid + 2, -12, VoxelWorld.BlockType.SLATE_BRICK, false)

	# 2. Echo Shaft West Terrace to Abandoned Camp (X: -14..-10, Z: -16..-4)
	for z in range(-16, -3):
		var y_fl = 26 if z >= -8 else 27
		for x in range(-13, -9):
			for dy in range(1, 5):
				voxel_world.set_block(x, y_fl + dy, z, VoxelWorld.BlockType.AIR, false)
			voxel_world.set_block(x, y_fl, z, VoxelWorld.BlockType.COBBLESTONE, false)
			for fy in range(18, y_fl):
				voxel_world.set_block(x, fy, z, VoxelWorld.BlockType.STONE, false)
			voxel_world.set_block(x, y_fl + 5, z, VoxelWorld.BlockType.STONE, false)
		for dy in range(0, 6):
			voxel_world.set_block(-14, y_fl + dy, z, VoxelWorld.BlockType.STONE, false)
			voxel_world.set_block(-9, y_fl + dy, z, VoxelWorld.BlockType.STONE, false)

## Architectural Structures: Catwalks, Suspension Bridge, Service Ladders, Stencil Signs
func _build_architectural_structures() -> void:
	# A. Industrial Service Ladder inside Sump Shaft
	# Mounted to the East wall at X = 18.8, Z = -12.0 from Y = 28.5 to Y = 38.5
	var ladder_root = Node3D.new()
	ladder_root.name = "SumpServiceLadder"
	var iron_mat = StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.22, 0.24, 0.28, 1.0)
	iron_mat.metallic = 0.90
	iron_mat.roughness = 0.45

	var safety_yellow = StandardMaterial3D.new()
	safety_yellow.albedo_color = Color(0.95, 0.75, 0.15, 1.0)
	safety_yellow.roughness = 0.40

	# Side rails
	for rail_z in [-12.2, -11.8]:
		var rail = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.03
		cyl.bottom_radius = 0.03
		cyl.height = 10.4
		rail.mesh = cyl
		rail.material_override = safety_yellow
		rail.position = Vector3(18.8, 33.5, rail_z)
		ladder_root.add_child(rail)

	# Rungs every 0.35m
	for ry in range(29, 39):
		for frac in [0.0, 0.35, 0.70]:
			var rung_y = ry + frac
			if rung_y > 38.8:
				break
			var rung = MeshInstance3D.new()
			var r_cyl = CylinderMesh.new()
			r_cyl.top_radius = 0.02
			r_cyl.bottom_radius = 0.02
			r_cyl.height = 0.42
			rung.mesh = r_cyl
			rung.material_override = iron_mat
			rung.position = Vector3(18.8, rung_y, -12.0)
			rung.rotation_degrees = Vector3(90, 0, 0)
			ladder_root.add_child(rung)

	# Functional Climbable Area3D for service ladder
	var ladder_area = Area3D.new()
	ladder_area.name = "LadderArea"
	ladder_area.collision_layer = 8
	ladder_area.collision_mask = 2 # Player body
	var l_col = CollisionShape3D.new()
	var l_box = BoxShape3D.new()
	l_box.size = Vector3(1.2, 11.2, 1.2)
	l_col.shape = l_box
	ladder_area.position = Vector3(18.4, 33.5, -12.0)
	ladder_area.add_child(l_col)
	ladder_area.body_entered.connect(func(b):
		if b.has_method("set_on_ladder"):
			b.set_on_ladder(true)
	)
	ladder_area.body_exited.connect(func(b):
		if b.has_method("set_on_ladder"):
			b.set_on_ladder(false)
	)
	ladder_root.add_child(ladder_area)

	props_container.add_child(ladder_root)

	# B. Echo Shaft Heavy Suspension Bridge (Connecting Overlook Balcony to West Terrace!)
	# Spans from East Balcony (3.5, 33.0, -20.5) to West Terrace (-7.5, 27.5, -24.0)
	var catwalk_root = Node3D.new()
	catwalk_root.name = "EchoShaftCatwalk"
	props_container.add_child(catwalk_root)

	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.30, 0.20, 0.14, 1.0)
	wood_mat.roughness = 0.85

	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.25, 0.28, 0.32, 1.0)
	steel_mat.metallic = 0.92
	steel_mat.roughness = 0.38

	var brass_mat = StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.85, 0.70, 0.35, 1.0)
	brass_mat.metallic = 0.85
	brass_mat.roughness = 0.35

	# 1. Pylon Towers at East and West bridgeheads
	var towers_info = [
		{ "x": 3.6, "y": 33.0, "z": -20.5, "name": "EastTower" },
		{ "x": -7.5, "y": 27.5, "z": -24.0, "name": "WestTower" }
	]
	for ti in towers_info:
		var tower = Node3D.new()
		tower.name = ti["name"]
		tower.position = Vector3(ti["x"], ti["y"], ti["z"])
		catwalk_root.add_child(tower)

		# Vertical Timber Pylons on North and South sides
		for pz in [-1.0, 1.0]:
			var post = MeshInstance3D.new()
			var p_box = BoxMesh.new()
			p_box.size = Vector3(0.24, 3.8, 0.24)
			post.mesh = p_box
			post.material_override = wood_mat
			post.position = Vector3(0, 1.9, pz)
			tower.add_child(post)

		# Top Crossbeam connecting pylons
		var crossbeam = MeshInstance3D.new()
		var cb_box = BoxMesh.new()
		cb_box.size = Vector3(0.26, 0.22, 2.3)
		crossbeam.mesh = cb_box
		crossbeam.material_override = wood_mat
		crossbeam.position = Vector3(0, 3.7, 0)
		tower.add_child(crossbeam)

		# Forged Iron Strapping Plates
		for pz in [-1.0, 1.0]:
			var strap = MeshInstance3D.new()
			var st_box = BoxMesh.new()
			st_box.size = Vector3(0.28, 0.30, 0.28)
			strap.mesh = st_box
			strap.material_override = steel_mat
			strap.position = Vector3(0, 3.65, pz)
			tower.add_child(strap)

		# Hanging Brass Bulkhead Lantern with warm amber illumination
		var lantern_p = MeshInstance3D.new()
		var lp_cyl = CylinderMesh.new()
		lp_cyl.top_radius = 0.08
		lp_cyl.bottom_radius = 0.10
		lp_cyl.height = 0.24
		lp_cyl.radial_segments = 8
		lantern_p.mesh = lp_cyl
		lantern_p.material_override = brass_mat
		lantern_p.position = Vector3(0, 3.3, 0)
		tower.add_child(lantern_p)

		var b_light = OmniLight3D.new()
		b_light.light_color = Color(1.0, 0.82, 0.45)
		b_light.light_energy = 1.35
		b_light.omni_range = 9.5
		b_light.shadow_enabled = true
		b_light.position = Vector3(0, 3.1, 0)
		tower.add_child(b_light)

	# 2. Main Deck Planks, Stringers, Suspension Cables, Hangers, and Handrails
	var num_steps = 22
	var cable_points_north = []
	var cable_points_south = []

	for i in range(num_steps):
		var t = float(i) / float(num_steps - 1)
		var deck_pos = Vector3(
			lerp(3.5, -7.5, t),
			lerp(33.0, 27.5, t) - sin(t * PI) * 0.45,
			lerp(-20.5, -24.0, t)
		)

		# Deck Plank (1.7m wide across the bridge)
		var plank = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(0.55, 0.08, 1.7)
		plank.mesh = p_box
		plank.material_override = wood_mat
		plank.position = deck_pos
		catwalk_root.add_child(plank)

		# Static Collision for walking
		var body = StaticBody3D.new()
		var c_shape = CollisionShape3D.new()
		var b_shape = BoxShape3D.new()
		b_shape.size = Vector3(0.55, 0.10, 1.7)
		c_shape.shape = b_shape
		body.add_child(c_shape)
		body.position = deck_pos
		catwalk_root.add_child(body)

		# Under-Deck Longitudinal Stringer Beams (supporting the planks)
		for sz in [-0.75, 0.75]:
			var stringer = MeshInstance3D.new()
			var s_box = BoxMesh.new()
			s_box.size = Vector3(0.60, 0.12, 0.12)
			stringer.mesh = s_box
			stringer.material_override = wood_mat
			stringer.position = deck_pos + Vector3(0, -0.09, sz)
			catwalk_root.add_child(stringer)

		# Catenary Main Suspension Cable Height: swoops from tower top (Y + 3.6) down to Y + 1.2 at mid-span
		var cable_sag = 3.6 - sin(t * PI) * 2.3
		var cable_y = lerp(33.0, 27.5, t) + cable_sag
		var c_north = Vector3(deck_pos.x, cable_y, deck_pos.z - 0.95)
		var c_south = Vector3(deck_pos.x, cable_y, deck_pos.z + 0.95)
		cable_points_north.append(c_north)
		cable_points_south.append(c_south)

		# Vertical Steel Drop Wire Hangers every 2 steps
		if i % 2 == 0:
			for side in [-1, 1]:
				var c_pt = c_north if side == -1 else c_south
				var d_pt = deck_pos + Vector3(0, 0, side * 0.85)
				var h_len = c_pt.y - d_pt.y
				if h_len > 0.1:
					var hanger = MeshInstance3D.new()
					var h_cyl = CylinderMesh.new()
					h_cyl.top_radius = 0.012
					h_cyl.bottom_radius = 0.012
					h_cyl.height = h_len
					h_cyl.radial_segments = 6
					hanger.mesh = h_cyl
					hanger.material_override = steel_mat
					hanger.position = Vector3(deck_pos.x, d_pt.y + h_len * 0.5, c_pt.z)
					catwalk_root.add_child(hanger)

		# Guardrail Stanchion Posts every 2 steps
		if i % 2 == 0:
			for side in [-0.85, 0.85]:
				var stanchion = MeshInstance3D.new()
				var st_box = BoxMesh.new()
				st_box.size = Vector3(0.08, 1.05, 0.08)
				stanchion.mesh = st_box
				stanchion.material_override = wood_mat
				stanchion.position = deck_pos + Vector3(0, 0.52, side)
				catwalk_root.add_child(stanchion)

	# Continuous Cable & Handrail Segments
	for i in range(num_steps - 1):
		# North and South main suspension cables
		for side in [-1, 1]:
			var p1 = cable_points_north[i] if side == -1 else cable_points_south[i]
			var p2 = cable_points_north[i + 1] if side == -1 else cable_points_south[i + 1]
			var seg_vec = p2 - p1
			var seg_len = seg_vec.length()
			var cable_seg = MeshInstance3D.new()
			var c_cyl = CylinderMesh.new()
			c_cyl.top_radius = 0.022
			c_cyl.bottom_radius = 0.022
			c_cyl.height = seg_len
			c_cyl.radial_segments = 6
			cable_seg.mesh = c_cyl
			cable_seg.material_override = steel_mat
			cable_seg.position = p1 + seg_vec * 0.5
			catwalk_root.add_child(cable_seg)
			if seg_len > 0.001:
				cable_seg.look_at(p2, Vector3.UP)
				cable_seg.rotate_object_local(Vector3.RIGHT, PI * 0.5)

		# Double Safety Handrails (Waist height at Y + 0.95m and Knee height at Y + 0.50m)
		var d1 = Vector3(lerp(3.5, -7.5, float(i)/float(num_steps-1)), lerp(33.0, 27.5, float(i)/float(num_steps-1)) - sin((float(i)/float(num_steps-1)) * PI) * 0.45, lerp(-20.5, -24.0, float(i)/float(num_steps-1)))
		var d2 = Vector3(lerp(3.5, -7.5, float(i+1)/float(num_steps-1)), lerp(33.0, 27.5, float(i+1)/float(num_steps-1)) - sin((float(i+1)/float(num_steps-1)) * PI) * 0.45, lerp(-20.5, -24.0, float(i+1)/float(num_steps-1)))
		for side in [-0.85, 0.85]:
			for hy in [0.50, 0.95]:
				var r1 = d1 + Vector3(0, hy, side)
				var r2 = d2 + Vector3(0, hy, side)
				var r_vec = r2 - r1
				var r_len = r_vec.length()
				var rail_seg = MeshInstance3D.new()
				var r_cyl = CylinderMesh.new()
				r_cyl.top_radius = 0.018
				r_cyl.bottom_radius = 0.018
				r_cyl.height = r_len
				r_cyl.radial_segments = 6
				rail_seg.mesh = r_cyl
				rail_seg.material_override = wood_mat
				rail_seg.position = r1 + r_vec * 0.5
				catwalk_root.add_child(rail_seg)
				if r_len > 0.001:
					rail_seg.look_at(r2, Vector3.UP)
					rail_seg.rotate_object_local(Vector3.RIGHT, PI * 0.5)

	# C. Directional Signage Plaques (Firmly wall-mounted!)
	_create_stencil_sign(Vector3(9.5, 42.5, 0.0), Vector3(0, -90, 0), "ШЛЮЗОВАЯ СТАНЦИЯ 4")
	_create_stencil_sign(Vector3(10.2, 42.5, -14.0), Vector3(0, 90, 0), "ШУРФ ЭХА ➔")
	_create_stencil_sign(Vector3(5.8, 36.5, -13.5), Vector3(0, -90, 0), "ШУРФ ЭХА (1430м)")
	_create_stencil_sign(Vector3(-10.5, 29.5, -15.0), Vector3(0, 0, 0), "ЛАГЕРЬ ГЕОЛОГОВ ➔")

func _create_stencil_sign(pos: Vector3, rot: Vector3, text: String) -> void:
	var sign_node = Node3D.new()
	sign_node.position = pos
	sign_node.rotation_degrees = rot

	# Dark steel plate
	var plate = MeshInstance3D.new()
	var p_box = BoxMesh.new()
	p_box.size = Vector3(1.8, 0.45, 0.04)
	plate.mesh = p_box
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.12, 0.14, 0.16, 1.0)
	p_mat.metallic = 0.80
	p_mat.roughness = 0.50
	plate.material_override = p_mat
	sign_node.add_child(plate)

	# 3D Label
	var label = Label3D.new()
	label.text = text
	label.font_size = 32
	label.modulate = Color(0.95, 0.80, 0.35, 1.0) # Warm amber stencil
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	label.outline_size = 4
	label.position = Vector3(0, 0, 0.025)
	sign_node.add_child(label)

	# Small amber spotlight above sign
	var sign_light = OmniLight3D.new()
	sign_light.light_color = Color(1.0, 0.85, 0.45)
	sign_light.light_energy = 0.8
	sign_light.omni_range = 3.5
	sign_light.position = Vector3(0, 0.4, 0.3)
	sign_node.add_child(sign_light)

	props_container.add_child(sign_node)

## Spawns all interactive props, document boxes, and EE-06 safe
func _spawn_interactive_props() -> void:
	# 0. Crash Site of Cage «ТяжМаш-4» at Zone A
	_build_tyazhmash_cage_wreckage()
	_build_decline_gangway()

	var doc_d08 = DocumentPropClass.new()
	doc_d08.document_id = "DOC-08"
	doc_d08.name = "Document_DOC08_CrashSite"
	doc_d08.position = Vector3(1.8, 57.05, 0.8)
	props_container.add_child(doc_d08)

	# Low-poly supply crate under AUD-18 so it never floats
	var crate_mat = StandardMaterial3D.new()
	crate_mat.albedo_color = Color(0.32, 0.22, 0.14, 1.0)
	crate_mat.roughness = 0.85
	var crate_18 = MeshInstance3D.new()
	var c18_box = BoxMesh.new()
	c18_box.size = Vector3(0.60, 0.65, 0.60)
	crate_18.mesh = c18_box
	crate_18.material_override = crate_mat
	crate_18.position = Vector3(0.5, 56.675, -1.0)
	props_container.add_child(crate_18)

	var aud_18 = AudiologPropClass.new()
	aud_18.audio_tape_id = "AUD-18"
	aud_18.name = "Audiolog_AUD18_CrashSite"
	aud_18.position = Vector3(0.5, 57.01, -1.0)
	props_container.add_child(aud_18)

	var aud_09 = AudiologPropClass.new()
	aud_09.audio_tape_id = "AUD-09"
	aud_09.name = "Audiolog_AUD09_CageInterior"
	aud_09.position = Vector3(-1.0, 57.05, 0.0)
	props_container.add_child(aud_09)

	# 1. Handcrafted Low-Poly Surveyor Desk in Station 4 (Firmly planted on floor at Y=39.0)
	_build_surveyor_desk(Vector3(13.0, 39.0, -5.5))

	# Additional narrative documents & audiologs
	var aud_01 = AudiologPropClass.new()
	aud_01.audio_tape_id = "AUD-01"
	aud_01.name = "Audiolog_AUD01_Station4"
	aud_01.position = Vector3(13.55, 39.82, -5.50) # Sitting cleanly on desk tabletop!
	props_container.add_child(aud_01)

	var doc_d03 = DocumentPropClass.new()
	doc_d03.document_id = "DOC-03"
	doc_d03.name = "Document_DOC03_Station4"
	doc_d03.position = Vector3(12.45, 39.82, -5.35) # Sitting cleanly on desk tabletop!
	props_container.add_child(doc_d03)

	var doc_d16 = DocumentPropClass.new()
	doc_d16.document_id = "DOC-16"
	doc_d16.name = "Document_DOC16_MechanicBench"
	doc_d16.position = Vector3(14.5, 39.05, -3.5)
	props_container.add_child(doc_d16)

	var aud_10 = AudiologPropClass.new()
	aud_10.audio_tape_id = "AUD-10"
	aud_10.name = "Audiolog_AUD10_Station4Admin"
	aud_10.position = Vector3(10.5, 39.05, -8.0)
	props_container.add_child(aud_10)

	# 2. Drainage Valve Wheel at Station 4 (drains lower sump)
	# Mounted firmly to the trench wall/pedestal at X=18.5, Y=39.0, Z=-11.0
	drainage_valve_prop = DrainageValveClass.new()
	drainage_valve_prop.name = "DrainageValve_Station4"
	drainage_valve_prop.position = Vector3(18.5, 39.0, -11.0)
	drainage_valve_prop.rotation_degrees = Vector3(0, -90, 0)
	props_container.add_child(drainage_valve_prop)

	# 3. EE-06 Drowned Safe in Lower Sump (Embedded flush in floor slab at Y = 28.05)
	ee06_safe_prop = EasterEgg06Class.new()
	ee06_safe_prop.name = "EE06_DrownedSafe"
	ee06_safe_prop.position = Vector3(15.0, 28.05, -12.0)
	props_container.add_child(ee06_safe_prop)

	var aud_07 = AudiologPropClass.new()
	aud_07.audio_tape_id = "AUD-07"
	aud_07.name = "Audiolog_AUD07_Sump"
	aud_07.position = Vector3(15.6, 28.1, -11.5)
	props_container.add_child(aud_07)

	var doc_d06 = DocumentPropClass.new()
	doc_d06.document_id = "DOC-06"
	doc_d06.name = "Document_DOC06_Sump"
	doc_d06.position = Vector3(14.4, 28.1, -12.5)
	props_container.add_child(doc_d06)

	var aud_13 = AudiologPropClass.new()
	aud_13.audio_tape_id = "AUD-13"
	aud_13.name = "Audiolog_AUD13_PumpFlange"
	aud_13.position = Vector3(17.5, 28.1, -10.0)
	props_container.add_child(aud_13)

	# Handcrafted Low-Poly Abandoned Expedition Camp (Zone D)
	_build_expedition_camp()

	var aud_03 = AudiologPropClass.new()
	aud_03.audio_tape_id = "AUD-03"
	aud_03.name = "Audiolog_AUD03_Camp"
	aud_03.position = Vector3(-16.35, 26.80, 4.35) # Sitting cleanly on radio table!
	props_container.add_child(aud_03)

	var doc_d09 = DocumentPropClass.new()
	doc_d09.document_id = "DOC-09"
	doc_d09.name = "Document_DOC09_Camp"
	doc_d09.position = Vector3(-16.75, 26.80, 4.25) # Sitting cleanly on radio table!
	props_container.add_child(doc_d09)

	# Physical Easter Eggs (EE-01..EE-05, EE-07..EE-09) - Firmly grounded, NO floating!
	var egg_placements = [
		{ "id": "EE-01", "pos": Vector3(12.0, 40.15, -8.0) }, # Floor of Station 4 west alcove
		{ "id": "EE-02", "pos": Vector3(-6.0, 40.15, 14.0) },
		{ "id": "EE-03", "pos": Vector3(18.0, 40.15, 2.0) },  # Station 4 surveyor corner floor
		{ "id": "EE-04", "pos": Vector3(0.0, 44.15, -15.0) },
		{ "id": "EE-05", "pos": Vector3(24.0, 40.15, -10.0) },
		{ "id": "EE-07", "pos": Vector3(-19.0, 26.75, 8.5) }, # Securely resting on top of camp supply crate!
		{ "id": "EE-08", "pos": Vector3(4.0, 33.15, -20.0) },  # Echo Shaft east bridgehead landing
		{ "id": "EE-09", "pos": Vector3(-22.0, 26.15, 0.0) }  # Grounded on camp karst spring floor
	]
	for ep in egg_placements:
		var egg_prop = EasterEggPropClass.new()
		egg_prop.easter_egg_id = ep["id"]
		egg_prop.name = "EasterEgg_%s" % ep["id"]
		egg_prop.position = ep["pos"]
		props_container.add_child(egg_prop)

	# 4. Starting Wall Anchor placed near Echo Shaft ledge
	var anchor_init = RockAnchorClass.new(Vector3(1, 0, 0), 4.0)
	anchor_init.name = "Sample_Expedition_Anchor"
	anchor_init.position = Vector3(3.2, 34.5, -20.0)
	props_container.add_child(anchor_init)

	# 5. Station 4 Surveyor Workstation Warm Overhead Lamp
	var station_light = OmniLight3D.new()
	station_light.name = "Station4_WorkstationLamp"
	station_light.position = Vector3(13.0, 41.5, -5.5)
	station_light.light_color = Color(1.0, 0.85, 0.55)
	station_light.light_energy = 1.8
	station_light.omni_range = 10.0
	station_light.shadow_enabled = true
	props_container.add_child(station_light)

	# 6. Bioluminescent Mushroom Colony Glow in Echo Shaft
	var bio_light1 = OmniLight3D.new()
	bio_light1.name = "BioMushroomGlow_Ledge"
	bio_light1.position = Vector3(3.5, 34.8, -22.5)
	bio_light1.light_color = Color(0.18, 0.90, 0.82)
	bio_light1.light_energy = 1.4
	bio_light1.omni_range = 10.0
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

	# 7. Campfire Glow in Abandoned Camp
	var camp_light = OmniLight3D.new()
	camp_light.name = "CampfireGlow_ZoneD"
	camp_light.position = Vector3(-16.0, 27.0, 6.0)
	camp_light.light_color = Color(1.0, 0.65, 0.30)
	camp_light.light_energy = 1.5
	camp_light.omni_range = 10.0
	camp_light.shadow_enabled = true
	props_container.add_child(camp_light)

	# 8. The Watcher standing on distant high ledge across the chasm
	ambient_watcher = TheWatcherClass.new()
	ambient_watcher.name = "AmbientWatcher_ChasmLedge"
	ambient_watcher.position = Vector3(-14.0, 32.5, -22.0)
	ambient_watcher.is_ambient_showcase = true
	props_container.add_child(ambient_watcher)

	# 9. Subterranean Water Bodies
	var water_sluice = SubterraneanWaterClass.new(Vector3(2.8, 0.7, 9.5))
	water_sluice.name = "Water_Station4_Sluice"
	water_sluice.position = Vector3(17.0, 37.6, -10.0)
	props_container.add_child(water_sluice)

	sump_water = SubterraneanWaterClass.new(Vector3(6.0, 1.5, 7.0))
	sump_water.name = "Water_LowerSump"
	sump_water.position = Vector3(16.0, 29.2, -12.0)
	props_container.add_child(sump_water)

	var water_plunge = SubterraneanWaterClass.new(Vector3(6.0, 1.2, 5.0))
	water_plunge.name = "Water_AbyssalPlungePool"
	water_plunge.position = Vector3(-10.0, 22.4, -32.0)
	props_container.add_child(water_plunge)

## Handcrafted Low-Poly Surveyor Desk
func _build_surveyor_desk(pos: Vector3) -> void:
	surveyor_desk = Node3D.new()
	surveyor_desk.name = "SurveyorDesk"
	surveyor_desk.position = pos

	var oak_mat = StandardMaterial3D.new()
	oak_mat.albedo_color = Color(0.28, 0.18, 0.12, 1.0)
	oak_mat.roughness = 0.75

	var brass_mat = StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.85, 0.70, 0.35, 1.0)
	brass_mat.metallic = 0.85
	brass_mat.roughness = 0.35

	# Heavy Tabletop (1.8m wide, 0.85m deep, 0.08m thick)
	var top = MeshInstance3D.new()
	var top_box = BoxMesh.new()
	top_box.size = Vector3(1.8, 0.08, 0.85)
	top.mesh = top_box
	top.material_override = oak_mat
	top.position = Vector3(0, 0.76, 0)
	surveyor_desk.add_child(top)

	# 4 Solid Turned Wooden Legs firmly planted on floor (Y = 0 to 0.72)
	for lx in [-0.80, 0.80]:
		for lz in [-0.34, 0.34]:
			var leg = MeshInstance3D.new()
			var leg_box = BoxMesh.new()
			leg_box.size = Vector3(0.08, 0.74, 0.08)
			leg.mesh = leg_box
			leg.material_override = oak_mat
			leg.position = Vector3(lx, 0.37, lz)
			surveyor_desk.add_child(leg)

	# Side Drawer Units
	for dx in [-0.55, 0.55]:
		var drawer = MeshInstance3D.new()
		var d_box = BoxMesh.new()
		d_box.size = Vector3(0.42, 0.45, 0.75)
		drawer.mesh = d_box
		drawer.material_override = oak_mat
		drawer.position = Vector3(dx, 0.48, 0)
		surveyor_desk.add_child(drawer)

		# Brass pull handles
		for hy in [0.38, 0.58]:
			var handle = MeshInstance3D.new()
			var h_box = BoxMesh.new()
			h_box.size = Vector3(0.12, 0.03, 0.02)
			handle.mesh = h_box
			handle.material_override = brass_mat
			handle.position = Vector3(dx, hy, 0.38)
			surveyor_desk.add_child(handle)

	# Static collision so player and items don't fall through desk
	var body = StaticBody3D.new()
	var c_shape = CollisionShape3D.new()
	var b_shape = BoxShape3D.new()
	b_shape.size = Vector3(1.8, 0.80, 0.85)
	c_shape.shape = b_shape
	c_shape.position = Vector3(0, 0.40, 0)
	body.add_child(c_shape)
	surveyor_desk.add_child(body)

	# Brass Banker's / Surveyor's Desk Lamp
	var lamp_root = Node3D.new()
	lamp_root.position = Vector3(-0.65, 0.80, -0.22)
	surveyor_desk.add_child(lamp_root)

	var lamp_base = MeshInstance3D.new()
	var lb_cyl = CylinderMesh.new()
	lb_cyl.top_radius = 0.08
	lb_cyl.bottom_radius = 0.09
	lb_cyl.height = 0.025
	lb_cyl.radial_segments = 8
	lamp_base.mesh = lb_cyl
	lamp_base.material_override = brass_mat
	lamp_root.add_child(lamp_base)

	var lamp_stem = MeshInstance3D.new()
	var ls_cyl = CylinderMesh.new()
	ls_cyl.top_radius = 0.015
	ls_cyl.bottom_radius = 0.015
	ls_cyl.height = 0.35
	lamp_stem.mesh = ls_cyl
	lamp_stem.material_override = brass_mat
	lamp_stem.position = Vector3(0, 0.18, 0)
	lamp_root.add_child(lamp_stem)

	var shade_mat = StandardMaterial3D.new()
	shade_mat.albedo_color = Color(0.12, 0.32, 0.22, 1.0) # Classic deep emerald enameled glass
	shade_mat.roughness = 0.25

	var lamp_shade = MeshInstance3D.new()
	var lsh_box = BoxMesh.new()
	lsh_box.size = Vector3(0.22, 0.08, 0.12)
	lamp_shade.mesh = lsh_box
	lamp_shade.material_override = shade_mat
	lamp_shade.position = Vector3(0, 0.35, 0.06)
	lamp_shade.rotation_degrees = Vector3(15.0, 0, 0)
	lamp_root.add_child(lamp_shade)

	# Cozy warm amber desk illumination directly over documents
	var desk_light = OmniLight3D.new()
	desk_light.name = "SurveyorDeskLampGlow"
	desk_light.light_color = Color(1.0, 0.82, 0.48)
	desk_light.light_energy = 1.35
	desk_light.omni_range = 5.2
	desk_light.position = Vector3(0, 0.32, 0.06)
	lamp_root.add_child(desk_light)

	# Low-Poly Surveyor's Stool
	var stool = Node3D.new()
	stool.position = Vector3(0, 0, 0.65)
	surveyor_desk.add_child(stool)

	var stool_seat = MeshInstance3D.new()
	var ss_cyl = CylinderMesh.new()
	ss_cyl.top_radius = 0.22
	ss_cyl.bottom_radius = 0.20
	ss_cyl.height = 0.05
	ss_cyl.radial_segments = 8
	stool_seat.mesh = ss_cyl
	stool_seat.material_override = oak_mat
	stool_seat.position = Vector3(0, 0.45, 0)
	stool.add_child(stool_seat)

	for sa in [PI * 0.25, PI * 0.75, PI * 1.25, PI * 1.75]:
		var s_leg = MeshInstance3D.new()
		var sl_cyl = CylinderMesh.new()
		sl_cyl.top_radius = 0.022
		sl_cyl.bottom_radius = 0.022
		sl_cyl.height = 0.44
		sl_cyl.radial_segments = 6
		s_leg.mesh = sl_cyl
		s_leg.material_override = oak_mat
		s_leg.position = Vector3(cos(sa) * 0.16, 0.22, sin(sa) * 0.16)
		stool.add_child(s_leg)

	# Rolled Geological Map Rolls on right desk corner
	var map_mat = StandardMaterial3D.new()
	map_mat.albedo_color = Color(0.88, 0.84, 0.72, 1.0)
	map_mat.roughness = 0.90

	for mz in [0.12, 0.22]:
		var map_roll = MeshInstance3D.new()
		var mr_cyl = CylinderMesh.new()
		mr_cyl.top_radius = 0.035
		mr_cyl.bottom_radius = 0.035
		mr_cyl.height = 0.55
		mr_cyl.radial_segments = 8
		map_roll.mesh = mr_cyl
		map_roll.material_override = map_mat
		map_roll.position = Vector3(0.68, 0.82, mz)
		map_roll.rotation_degrees = Vector3(0, 0, 90.0)
		surveyor_desk.add_child(map_roll)

	props_container.add_child(surveyor_desk)

	# Place Document D-01 Box on top of the desk
	doc_d01_prop = DocumentD01Class.new()
	doc_d01_prop.name = "Document_D01_Box"
	doc_d01_prop.position = Vector3(pos.x - 0.15, pos.y + 0.82, pos.z - 0.05)
	props_container.add_child(doc_d01_prop)

func _build_tyazhmash_cage_wreckage() -> void:
	var wreckage = Node3D.new()
	wreckage.name = "TyazhMash_Cage_Wreckage"
	wreckage.position = Vector3(-1.6, 57.0, 0.0)

	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.20, 0.22, 0.25, 1.0)
	steel_mat.metallic = 0.85
	steel_mat.roughness = 0.60

	# Low-profile floor plate safely behind player spawn
	var base_plate = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(1.8, 0.04, 2.0)
	base_plate.mesh = b_box
	base_plate.material_override = steel_mat
	base_plate.position = Vector3(-0.4, 0.02, 0)
	wreckage.add_child(base_plate)

	# Twisted side and rear cage pillars
	for pos_offset in [Vector3(-1.1, 1.2, -1.0), Vector3(-1.1, 1.2, 1.0), Vector3(0.4, 1.1, -1.0), Vector3(0.4, 1.0, 1.0)]:
		var beam = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.05
		cyl.bottom_radius = 0.05
		cyl.height = 2.4
		cyl.radial_segments = 6
		beam.mesh = cyl
		beam.material_override = steel_mat
		beam.position = pos_offset
		beam.rotation_degrees = Vector3(randf_range(-10, 10), randf_range(-15, 15), randf_range(-12, 12))
		wreckage.add_child(beam)

	# Crumpled rear mesh wall
	var rear_wall = MeshInstance3D.new()
	var rw_box = BoxMesh.new()
	rw_box.size = Vector3(0.04, 2.2, 1.9)
	rear_wall.mesh = rw_box
	rear_wall.material_override = steel_mat
	rear_wall.position = Vector3(-1.1, 1.1, 0.0)
	wreckage.add_child(rear_wall)

	# Bent upward roof (bent back away from camera to eliminate any clipping!)
	var roof = MeshInstance3D.new()
	var r_box = BoxMesh.new()
	r_box.size = Vector3(1.6, 0.06, 1.8)
	roof.mesh = r_box
	roof.material_override = steel_mat
	roof.position = Vector3(-0.5, 2.65, 0.0)
	roof.rotation_degrees = Vector3(-20.0, 0.0, 12.0)
	wreckage.add_child(roof)

	var cable_mat = StandardMaterial3D.new()
	cable_mat.albedo_color = Color(0.15, 0.16, 0.18, 1.0)
	cable_mat.metallic = 0.90
	for cx in [-0.5, 0.2]:
		var cable = MeshInstance3D.new()
		var c_cyl = CylinderMesh.new()
		c_cyl.top_radius = 0.015
		c_cyl.bottom_radius = 0.015
		c_cyl.height = 3.5
		cable.mesh = c_cyl
		cable.material_override = cable_mat
		cable.position = Vector3(cx, 4.0, 0.0)
		wreckage.add_child(cable)

	# High amber beacon casting warm light forward across the crash cavern
	var emerg_light = OmniLight3D.new()
	emerg_light.name = "EmergencyAmberBeacon"
	emerg_light.position = Vector3(0.2, 2.2, 0.0)
	emerg_light.light_color = Color(1.0, 0.68, 0.28)
	emerg_light.light_energy = 1.35
	emerg_light.omni_range = 9.0
	wreckage.add_child(emerg_light)

	props_container.add_child(wreckage)

func _build_decline_gangway() -> void:
	var gangway = Node3D.new()
	gangway.name = "ApproachDeclineGangway"

	var oak_mat = StandardMaterial3D.new()
	oak_mat.albedo_color = Color(0.28, 0.18, 0.12, 1.0)
	oak_mat.roughness = 0.85

	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.22, 0.24, 0.27, 1.0)
	steel_mat.metallic = 0.85
	steel_mat.roughness = 0.50

	# 1. Continuous smooth walking ramp static body from X=5 (Y=52) to X=10 (Y=39)
	# This guarantees smooth, effortless walking up and down without sudden drops
	var ramp_body = StaticBody3D.new()
	ramp_body.name = "GangwayRampCollision"
	var ramp_col = CollisionShape3D.new()
	var ramp_box = BoxShape3D.new()
	# Distance from (5.0, 52.0) to (10.0, 39.0): dx = 5.0, dy = -13.0, length = 13.93
	ramp_box.size = Vector3(14.0, 0.20, 3.6)
	ramp_col.shape = ramp_box
	ramp_col.position = Vector3(7.5, 45.5, 0.0)
	var ramp_angle = atan2(-13.0, 5.0) # -68.9 degrees
	ramp_col.rotation = Vector3(0, 0, ramp_angle)
	ramp_body.add_child(ramp_col)
	gangway.add_child(ramp_body)

	# 2. Wooden Stair Treads along the ramp
	var num_treads = 14
	for i in range(num_treads):
		var t = float(i) / float(num_treads - 1)
		var tx = lerp(5.0, 10.0, t)
		var ty = lerp(51.8, 38.8, t)

		var tread = MeshInstance3D.new()
		var tr_box = BoxMesh.new()
		tr_box.size = Vector3(0.35, 0.08, 3.4)
		tread.mesh = tr_box
		tread.material_override = oak_mat
		tread.position = Vector3(tx, ty, 0.0)
		gangway.add_child(tread)

	# 3. Wooden Safety Handrails along left and right sides
	for rz in [-1.75, 1.75]:
		for i in range(num_treads):
			if i % 3 == 0:
				var t = float(i) / float(num_treads - 1)
				var post = MeshInstance3D.new()
				var p_cyl = CylinderMesh.new()
				p_cyl.top_radius = 0.04
				p_cyl.bottom_radius = 0.04
				p_cyl.height = 1.0
				p_cyl.radial_segments = 6
				post.mesh = p_cyl
				post.material_override = oak_mat
				post.position = Vector3(lerp(5.0, 10.0, t), lerp(51.8, 38.8, t) + 0.5, rz)
				gangway.add_child(post)

	# 4. Ladder Trigger Area along the steep section (so W/S effortlessly climbs)
	var ladder_area = Area3D.new()
	ladder_area.name = "GangwayLadderArea"
	ladder_area.add_to_group("ladder")
	var l_col = CollisionShape3D.new()
	var l_box = BoxShape3D.new()
	l_box.size = Vector3(6.0, 14.0, 3.8)
	l_col.shape = l_box
	l_col.position = Vector3(7.5, 45.5, 0.0)
	ladder_area.add_child(l_col)

	ladder_area.body_entered.connect(func(body):
		if body.has_method("set_on_ladder"):
			body.set_on_ladder(true)
	)
	ladder_area.body_exited.connect(func(body):
		if body.has_method("set_on_ladder"):
			body.set_on_ladder(false)
	)
	gangway.add_child(ladder_area)

	# 5. Hanging Amber Lanterns illuminating the decline
	for lx in [2.5, 6.0, 9.2]:
		var ly = 55.0 if lx < 4.0 else (48.5 if lx < 8.0 else 41.5)
		var lantern_glow = OmniLight3D.new()
		lantern_glow.light_color = Color(1.0, 0.78, 0.42)
		lantern_glow.light_energy = 1.2
		lantern_glow.omni_range = 8.5
		lantern_glow.position = Vector3(lx, ly, 0.0)
		gangway.add_child(lantern_glow)

	# 6. Station 4 Illuminated Portal Header Plaque
	var plaque_root = Node3D.new()
	plaque_root.position = Vector3(9.8, 43.6, 0.0)
	plaque_root.rotation_degrees = Vector3(0, -90, 0)
	gangway.add_child(plaque_root)

	var plaque_mesh = MeshInstance3D.new()
	var pm_box = BoxMesh.new()
	pm_box.size = Vector3(2.6, 0.45, 0.06)
	plaque_mesh.mesh = pm_box
	plaque_mesh.material_override = steel_mat
	plaque_root.add_child(plaque_mesh)

	var label_3d = Label3D.new()
	label_3d.text = "ШЛЮЗОВАЯ СТАНЦИЯ 4 — ГОРИЗОНТ 1420м"
	label_3d.font_size = 32
	label_3d.modulate = Color(1.0, 0.85, 0.45)
	label_3d.outline_modulate = Color(0.1, 0.08, 0.05)
	label_3d.outline_size = 4
	label_3d.position = Vector3(0, 0, 0.04)
	plaque_root.add_child(label_3d)

	props_container.add_child(gangway)

## Handcrafted Low-Poly Abandoned Expedition Camp (Zone D)
func _build_expedition_camp() -> void:
	var camp_root = Node3D.new()
	camp_root.name = "AbandonedExpeditionCamp"
	camp_root.position = Vector3(0, 0, 0)

	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.28, 0.18, 0.12, 1.0)
	wood_mat.roughness = 0.80

	var canvas_mat = StandardMaterial3D.new()
	canvas_mat.albedo_color = Color(0.72, 0.68, 0.58, 1.0) # Weatherproof cream expedition canvas
	canvas_mat.roughness = 0.90
	canvas_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.20, 0.22, 0.25, 1.0)
	steel_mat.metallic = 0.85
	steel_mat.roughness = 0.45

	var brass_mat = StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.85, 0.70, 0.35, 1.0)
	brass_mat.metallic = 0.85
	brass_mat.roughness = 0.35

	# 1. Canvas A-Frame Expedition Tent at X = -16.0, Z = 6.0
	var tent = Node3D.new()
	tent.name = "CanvasExpeditionTent"
	tent.position = Vector3(-16.0, 26.0, 6.0)
	camp_root.add_child(tent)

	# Timber A-frame ridgepole
	var ridgepole = MeshInstance3D.new()
	var rp_cyl = CylinderMesh.new()
	rp_cyl.top_radius = 0.045
	rp_cyl.bottom_radius = 0.045
	rp_cyl.height = 3.6
	rp_cyl.radial_segments = 6
	ridgepole.mesh = rp_cyl
	ridgepole.material_override = wood_mat
	ridgepole.rotation_degrees = Vector3(90, 0, 0)
	ridgepole.position = Vector3(0, 2.2, 0)
	tent.add_child(ridgepole)

	# Triangular A-Frame end poles (front and rear)
	for z_end in [-1.7, 1.7]:
		for x_side in [-1.0, 1.0]:
			var pole = MeshInstance3D.new()
			var p_cyl = CylinderMesh.new()
			p_cyl.top_radius = 0.035
			p_cyl.bottom_radius = 0.035
			p_cyl.height = 2.6
			p_cyl.radial_segments = 6
			pole.mesh = p_cyl
			pole.material_override = wood_mat
			pole.position = Vector3(x_side * 0.75, 1.1, z_end)
			pole.rotation_degrees = Vector3(0, 0, -x_side * 34.0)
			tent.add_child(pole)

	# Sloping Heavy Canvas Roof Panels (East and West sides)
	for x_side in [-1.0, 1.0]:
		var panel = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(2.5, 0.03, 3.4)
		panel.mesh = p_box
		panel.material_override = canvas_mat
		panel.position = Vector3(x_side * 0.82, 1.15, 0)
		panel.rotation_degrees = Vector3(0, 0, -x_side * 56.0)
		tent.add_child(panel)

	# Interior Folding Expedition Cot
	var cot = MeshInstance3D.new()
	var cot_box = BoxMesh.new()
	cot_box.size = Vector3(0.75, 0.35, 1.9)
	cot.mesh = cot_box
	var cot_mat = StandardMaterial3D.new()
	cot_mat.albedo_color = Color(0.38, 0.42, 0.34, 1.0) # Olive drab canvas
	cot_mat.roughness = 0.85
	cot.material_override = cot_mat
	cot.position = Vector3(0.15, 0.18, 0.0)
	tent.add_child(cot)

	# Rolled Woolen Blanket on cot
	var blanket = MeshInstance3D.new()
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 0.10
	b_cyl.bottom_radius = 0.10
	b_cyl.height = 0.65
	b_cyl.radial_segments = 8
	blanket.mesh = b_cyl
	var blk_mat = StandardMaterial3D.new()
	blk_mat.albedo_color = Color(0.55, 0.22, 0.18, 1.0) # Dark crimson wool roll
	blk_mat.roughness = 0.90
	blanket.material_override = blk_mat
	blanket.rotation_degrees = Vector3(0, 90, 0)
	blanket.position = Vector3(0.15, 0.42, -0.65)
	tent.add_child(blanket)

	# Small amber storm lantern inside tent
	var tent_light = OmniLight3D.new()
	tent_light.light_color = Color(1.0, 0.80, 0.45)
	tent_light.light_energy = 0.9
	tent_light.omni_range = 5.0
	tent_light.position = Vector3(0, 1.8, 0)
	tent.add_child(tent_light)

	# 2. Communications & Field Radio Desk at X = -16.5, Z = 4.2
	var desk = Node3D.new()
	desk.name = "CampRadioDesk"
	desk.position = Vector3(-16.5, 26.0, 4.2)
	camp_root.add_child(desk)

	var desk_top = MeshInstance3D.new()
	var dt_box = BoxMesh.new()
	dt_box.size = Vector3(1.5, 0.08, 0.75)
	desk_top.mesh = dt_box
	desk_top.material_override = wood_mat
	desk_top.position = Vector3(0, 0.72, 0)
	desk.add_child(desk_top)

	# 4 Desk Legs
	for lx in [-0.65, 0.65]:
		for lz in [-0.28, 0.28]:
			var d_leg = MeshInstance3D.new()
			var dl_box = BoxMesh.new()
			dl_box.size = Vector3(0.08, 0.70, 0.08)
			d_leg.mesh = dl_box
			d_leg.material_override = wood_mat
			d_leg.position = Vector3(lx, 0.35, lz)
			desk.add_child(d_leg)

	# Vintage Field Radio Transceiver Box (sitting on desk)
	var radio = Node3D.new()
	radio.position = Vector3(-0.35, 0.76, -0.08)
	desk.add_child(radio)

	var radio_box = MeshInstance3D.new()
	var rb_box = BoxMesh.new()
	rb_box.size = Vector3(0.48, 0.32, 0.34)
	radio_box.mesh = rb_box
	var radio_mat = StandardMaterial3D.new()
	radio_mat.albedo_color = Color(0.24, 0.28, 0.22, 1.0) # Military olive-drab steel
	radio_mat.metallic = 0.75
	radio_mat.roughness = 0.50
	radio_box.material_override = radio_mat
	radio_box.position = Vector3(0, 0.16, 0)
	radio.add_child(radio_box)

	# Dual Brass Frequency Dials
	for dx in [-0.12, 0.12]:
		var dial = MeshInstance3D.new()
		var d_cyl = CylinderMesh.new()
		d_cyl.top_radius = 0.045
		d_cyl.bottom_radius = 0.045
		d_cyl.height = 0.03
		d_cyl.radial_segments = 8
		dial.mesh = d_cyl
		dial.material_override = brass_mat
		dial.rotation_degrees = Vector3(90, 0, 0)
		dial.position = Vector3(dx, 0.22, 0.18)
		radio.add_child(dial)

	# Wire Whip Antenna
	var antenna = MeshInstance3D.new()
	var a_cyl = CylinderMesh.new()
	a_cyl.top_radius = 0.008
	a_cyl.bottom_radius = 0.012
	a_cyl.height = 1.1
	antenna.mesh = a_cyl
	antenna.material_override = steel_mat
	antenna.position = Vector3(0.20, 0.85, -0.12)
	antenna.rotation_degrees = Vector3(-8.0, 0, 12.0)
	radio.add_child(antenna)

	# Enamel Coffee Mug with dark blue rim
	var mug = MeshInstance3D.new()
	var m_cyl = CylinderMesh.new()
	m_cyl.top_radius = 0.045
	m_cyl.bottom_radius = 0.042
	m_cyl.height = 0.09
	m_cyl.radial_segments = 8
	mug.mesh = m_cyl
	var mug_mat = StandardMaterial3D.new()
	mug_mat.albedo_color = Color(0.92, 0.94, 0.96, 1.0)
	mug_mat.roughness = 0.30
	mug.material_override = mug_mat
	mug.position = Vector3(0.42, 0.805, 0.15)
	desk.add_child(mug)

	# Wooden Camp Stool
	var camp_stool = MeshInstance3D.new()
	var cs_box = BoxMesh.new()
	cs_box.size = Vector3(0.38, 0.42, 0.34)
	camp_stool.mesh = cs_box
	camp_stool.material_override = wood_mat
	camp_stool.position = Vector3(0, 0.21, 0.65)
	desk.add_child(camp_stool)

	# 3. Circular Fieldstone Campfire Pit at X = -13.0, Z = 8.5
	var fire_pit = Node3D.new()
	fire_pit.name = "CampfirePit"
	fire_pit.position = Vector3(-13.0, 26.0, 8.5)
	camp_root.add_child(fire_pit)

	var stone_mat = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.42, 0.44, 0.48, 1.0)
	stone_mat.roughness = 0.90

	# 10 Fieldstones in circle
	for i in range(10):
		var ang = i * (PI * 2.0 / 10.0)
		var rock = MeshInstance3D.new()
		var r_box = BoxMesh.new()
		r_box.size = Vector3(0.22, 0.16, 0.22)
		rock.mesh = r_box
		rock.material_override = stone_mat
		rock.position = Vector3(cos(ang) * 0.75, 0.08, sin(ang) * 0.75)
		rock.rotation_degrees = Vector3(randf_range(-15, 15), randf_range(0, 360), randf_range(-15, 15))
		fire_pit.add_child(rock)

	# Glowing Ember Bed in center
	var ember = MeshInstance3D.new()
	var e_cyl = CylinderMesh.new()
	e_cyl.top_radius = 0.55
	e_cyl.bottom_radius = 0.55
	e_cyl.height = 0.06
	e_cyl.radial_segments = 8
	ember.mesh = e_cyl
	var ember_mat = StandardMaterial3D.new()
	ember_mat.albedo_color = Color(0.12, 0.08, 0.06, 1.0)
	ember_mat.emission_enabled = true
	ember_mat.emission = Color(1.0, 0.35, 0.08, 1.0)
	ember_mat.emission_energy_multiplier = 1.6
	ember.material_override = ember_mat
	ember.position = Vector3(0, 0.03, 0)
	fire_pit.add_child(ember)

	# Charred Firewood Logs
	var log_mat = StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.15, 0.12, 0.10, 1.0)
	log_mat.roughness = 0.95
	for la in [0.2, 1.2, 2.2]:
		var log_m = MeshInstance3D.new()
		var l_cyl = CylinderMesh.new()
		l_cyl.top_radius = 0.05
		l_cyl.bottom_radius = 0.05
		l_cyl.height = 0.70
		l_cyl.radial_segments = 6
		log_m.mesh = l_cyl
		log_m.material_override = log_mat
		log_m.rotation_degrees = Vector3(15, rad_to_deg(la), 0)
		log_m.position = Vector3(cos(la) * 0.12, 0.09, sin(la) * 0.12)
		fire_pit.add_child(log_m)

	# Iron Cooking Tripod with Cast-Iron Kettle
	for ta in [0.0, PI * 0.67, PI * 1.33]:
		var t_leg = MeshInstance3D.new()
		var tl_cyl = CylinderMesh.new()
		tl_cyl.top_radius = 0.015
		tl_cyl.bottom_radius = 0.015
		tl_cyl.height = 1.6
		tl_cyl.radial_segments = 6
		t_leg.mesh = tl_cyl
		t_leg.material_override = steel_mat
		t_leg.position = Vector3(cos(ta) * 0.38, 0.75, sin(ta) * 0.38)
		t_leg.rotation_degrees = Vector3(sin(ta) * 18.0, 0, -cos(ta) * 18.0)
		fire_pit.add_child(t_leg)

	# Cast Iron Kettle hanging from center
	var kettle = MeshInstance3D.new()
	var k_sph = SphereMesh.new()
	k_sph.radius = 0.12
	k_sph.height = 0.22
	kettle.mesh = k_sph
	kettle.material_override = steel_mat
	kettle.position = Vector3(0, 0.48, 0)
	fire_pit.add_child(kettle)

	# 4. Supply Crates & Red Steel Jerrycans at X = -19.0, Z = 8.5
	for cz in [0.0, 0.85]:
		var crate = MeshInstance3D.new()
		var cr_box = BoxMesh.new()
		cr_box.size = Vector3(0.70, 0.70, 0.70)
		crate.mesh = cr_box
		crate.material_override = wood_mat
		crate.position = Vector3(-19.0, 26.35, 8.5 + cz)
		camp_root.add_child(crate)

	# Red Steel Jerrycan
	var jerrycan = MeshInstance3D.new()
	var j_box = BoxMesh.new()
	j_box.size = Vector3(0.24, 0.45, 0.35)
	jerrycan.mesh = j_box
	var jerry_mat = StandardMaterial3D.new()
	jerry_mat.albedo_color = Color(0.68, 0.18, 0.12, 1.0) # Weathered red lead paint
	jerry_mat.metallic = 0.75
	jerry_mat.roughness = 0.45
	jerrycan.material_override = jerry_mat
	jerrycan.position = Vector3(-18.3, 26.225, 9.2)
	camp_root.add_child(jerrycan)

	props_container.add_child(camp_root)
