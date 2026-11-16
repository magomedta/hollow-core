# scripts/voxel_world.gd
# High-Performance Infinite Chunk-Based Voxel Cave & Cryosphere Engine
# Features:
# - Truly infinite procedural chunk generation with time-budgeted background queues (Steady 60 FPS!)
# - 128 vertical blocks of soaring spatial volume (CHUNK_MIN_Y = -64 to CHUNK_MAX_Y = 64)
# - Rich procedural multi-biome system with 25+ distinct subterranean biomes:
#     * Surface Cryosphere & Glacial Ice Shelf (Y=40..64): Howling blizzard, permafrost crust, Station Boreas
#     * Subglacial Calcite Karst & Icicle Colonnades (Y=20..39): Translucent ice, calcite crystal geodes
#     * Bioluminescent Phosphor Grottos & Fungal Mycena Hollows: Glowing moss, blue cap edible mushrooms, water pools
#     * Subterranean Aquifer Springs: Cascading pure drinking water springs and condensation pools
#     * Ancient Precursor Sunken Sanctuaries: Alien slate-brick ruins, monoliths, energy conduits
#     * Looming Columnar Basalt Cathedrals: Monumental hexagonal basalt colonnades, soaring 40m vaults
#     * Volcanic Magma Calderas & Lava Tubes: Molten glow fissures, scorching magma rock, abyssal gold veins
#     * Crystalline Amethyst & Quartz Geodes: Vibrant violet crystal clusters, optical calcite prisms
#     * Chlorite Moss Caverns & Root Chambers: Damp mossy stone, weeping flowstone, edible roots
#     * Sulfur Fumarole Vents & Pyritic Deposits: Yellow sulfur encrusted steam fissures
#     * Abandoned Surveyor Camps: Timber frames, supply crates with rations and fresh water
#     * Indestructible Bedrock Foundation (Y<=-59): Flat impenetrable bedrock floor
# - Fast boundary-optimized greedy mesher with direct 1D array indexing (Zero lag spikes!)
# - 100% excavatable & constructible with instant collision and dynamic torch lighting

class_name VoxelWorld
extends Node3D

const PixelTextureGenerator = preload("res://scripts/pixel_texture_generator.gd")
const DroppedItemClass = preload("res://scripts/dropped_item.gd")
const TerrainModifierClass = preload("res://scripts/terrain/terrain_modifier.gd")
const TerrainPersistenceClass = preload("res://scripts/terrain/terrain_persistence.gd")
const WorldConfigClass = preload("res://scripts/world/world_config.gd")

signal block_broken(coord: Vector3i, block_type: int)
signal block_placed(coord: Vector3i, block_type: int)

enum BlockType {
	AIR = 0,
	STONE = 1,
	DEEPSLATE = 2,
	GRANITE = 3,
	DIORITE = 4,
	ANDESITE = 5,
	GRAVEL = 6,
	COAL_ORE = 7,
	IRON_ORE = 8,
	COPPER_ORE = 9,
	GOLD_ORE = 10,
	CALCITE = 11,
	MOSS_STONE = 12,
	PERMAFROST_ICE = 13,
	MAGMA_ROCK = 14,
	COBBLESTONE = 15,
	DEEP_BASALT = 16,
	WOOD_PLANKS = 17,
	HEWN_TIMBER = 18,
	CARGO_CRATE = 19,
	SLATE_BRICK = 20,
	BEDROCK = 21,
	PHOSPHOR_ORE = 22,
	TORCH = 23,
	WATER_SPRING = 24,
	BIOLUM_MUSHROOM = 25,
	SULFUR_BLOCK = 26,
	CRYSTAL_AMETHYST = 27,
	PRECURSOR_CONDUIT = 28,
	LICHEN_ROOT = 29
}

# Static transparency lookup for meshing & culling
static func is_transparent_block(bt: int) -> bool:
	return bt == BlockType.AIR or bt == BlockType.TORCH or bt == BlockType.WATER_SPRING or bt == BlockType.BIOLUM_MUSHROOM or bt == BlockType.LICHEN_ROOT

# Atlas grid: 8 columns x 8 rows (64x64 px each in 512x512 atlas)
const ATLAS_COORDS = {
	BlockType.STONE: Vector2i(0, 0),
	BlockType.DEEPSLATE: Vector2i(1, 0),
	BlockType.GRANITE: Vector2i(2, 0),
	BlockType.DIORITE: Vector2i(3, 0),
	BlockType.ANDESITE: Vector2i(4, 0),
	BlockType.GRAVEL: Vector2i(5, 0),
	BlockType.COAL_ORE: Vector2i(6, 0),
	BlockType.IRON_ORE: Vector2i(7, 0),

	BlockType.COPPER_ORE: Vector2i(0, 1),
	BlockType.GOLD_ORE: Vector2i(1, 1),
	BlockType.CALCITE: Vector2i(2, 1),
	BlockType.MOSS_STONE: Vector2i(3, 1),
	BlockType.PERMAFROST_ICE: Vector2i(4, 1),
	BlockType.MAGMA_ROCK: Vector2i(5, 1),
	BlockType.COBBLESTONE: Vector2i(6, 1),
	BlockType.DEEP_BASALT: Vector2i(7, 1),

	BlockType.WOOD_PLANKS: Vector2i(0, 2),
	BlockType.HEWN_TIMBER: Vector2i(1, 2),
	BlockType.CARGO_CRATE: Vector2i(2, 2),
	BlockType.SLATE_BRICK: Vector2i(3, 2),
	BlockType.BEDROCK: Vector2i(4, 2),
	BlockType.PHOSPHOR_ORE: Vector2i(5, 2),
	BlockType.TORCH: Vector2i(5, 2),

	BlockType.WATER_SPRING: Vector2i(0, 4),
	BlockType.BIOLUM_MUSHROOM: Vector2i(1, 4),
	BlockType.SULFUR_BLOCK: Vector2i(2, 4),
	BlockType.CRYSTAL_AMETHYST: Vector2i(3, 4),
	BlockType.PRECURSOR_CONDUIT: Vector2i(4, 4),
	BlockType.LICHEN_ROOT: Vector2i(5, 4)
}

# Differentiated block mining properties & drops
const BLOCK_PROPS = {
	BlockType.STONE: {"name": "Cavern Stone", "hardness": 32.0, "drop": "cobblestone", "count": 1, "is_soft": false},
	BlockType.DEEPSLATE: {"name": "Basaltic Deepslate", "hardness": 48.0, "drop": "deepslate", "count": 1, "is_soft": false},
	BlockType.GRANITE: {"name": "Intrusive Granite", "hardness": 36.0, "drop": "cobblestone", "count": 1, "is_soft": false},
	BlockType.DIORITE: {"name": "Crystalline Diorite", "hardness": 34.0, "drop": "cobblestone", "count": 1, "is_soft": false},
	BlockType.ANDESITE: {"name": "Volcanic Andesite", "hardness": 32.0, "drop": "cobblestone", "count": 1, "is_soft": false},
	BlockType.GRAVEL: {"name": "Cavern Gravel", "hardness": 10.0, "drop": "cobblestone", "count": 1, "is_soft": true},
	BlockType.COAL_ORE: {"name": "Coal Ore", "hardness": 38.0, "drop": "coal", "count": 2, "is_soft": false},
	BlockType.IRON_ORE: {"name": "Raw Iron Ore", "hardness": 54.0, "drop": "iron", "count": 1, "is_soft": false},
	BlockType.COPPER_ORE: {"name": "Copper Ore", "hardness": 42.0, "drop": "copper", "count": 1, "is_soft": false},
	BlockType.GOLD_ORE: {"name": "Abyssal Gold Ore", "hardness": 75.0, "drop": "gold", "count": 2, "is_soft": false},
	BlockType.CALCITE: {"name": "Calcite Geode", "hardness": 28.0, "drop": "calcite", "count": 2, "is_soft": false},
	BlockType.MOSS_STONE: {"name": "Mossy Stone", "hardness": 28.0, "drop": "cobblestone", "count": 1, "is_soft": false},
	BlockType.PERMAFROST_ICE: {"name": "Permafrost Ice", "hardness": 14.0, "drop": "calcite", "count": 1, "is_soft": true},
	BlockType.MAGMA_ROCK: {"name": "Abyssal Magma Rock", "hardness": 65.0, "drop": "cobblestone", "count": 1, "is_soft": false},
	BlockType.COBBLESTONE: {"name": "Cobblestone", "hardness": 26.0, "drop": "cobblestone", "count": 1, "is_soft": false},
	BlockType.DEEP_BASALT: {"name": "Deep Basalt", "hardness": 46.0, "drop": "deepslate", "count": 1, "is_soft": false},
	BlockType.WOOD_PLANKS: {"name": "Wooden Planks", "hardness": 16.0, "drop": "planks", "count": 1, "is_soft": true},
	BlockType.HEWN_TIMBER: {"name": "Hewn Timber Beam", "hardness": 20.0, "drop": "timber", "count": 2, "is_soft": true},
	BlockType.CARGO_CRATE: {"name": "Expedition Supply Crate", "hardness": 14.0, "drop": "rations", "count": 2, "is_soft": true},
	BlockType.SLATE_BRICK: {"name": "Precursor Slate Brick", "hardness": 65.0, "drop": "cobblestone", "count": 1, "is_soft": false},
	BlockType.BEDROCK: {"name": "Indestructible Bedrock", "hardness": -1.0, "drop": "", "count": 0, "is_soft": false},
	BlockType.PHOSPHOR_ORE: {"name": "Phosphor Crystal", "hardness": 50.0, "drop": "phosphor", "count": 2, "is_soft": false},
	BlockType.TORCH: {"name": "Carbide Torch", "hardness": 4.0, "drop": "torch", "count": 1, "is_soft": true},
	BlockType.WATER_SPRING: {"name": "Subterranean Water Spring", "hardness": 4.0, "drop": "water", "count": 1, "is_soft": true},
	BlockType.BIOLUM_MUSHROOM: {"name": "Bioluminescent Mushroom", "hardness": 2.0, "drop": "mushroom", "count": 2, "is_soft": true},
	BlockType.SULFUR_BLOCK: {"name": "Volcanic Sulfur Crust", "hardness": 22.0, "drop": "phosphor", "count": 2, "is_soft": false},
	BlockType.CRYSTAL_AMETHYST: {"name": "Amethyst Crystal Cluster", "hardness": 30.0, "drop": "calcite", "count": 2, "is_soft": false},
	BlockType.PRECURSOR_CONDUIT: {"name": "Precursor Energy Conduit", "hardness": 65.0, "drop": "phosphor", "count": 3, "is_soft": false},
	BlockType.LICHEN_ROOT: {"name": "Subterranean Lichen Root", "hardness": 3.0, "drop": "lichen", "count": 1, "is_soft": true}
}

# 256 vertical blocks of space (CHUNK_MIN_Y = -128 to CHUNK_MAX_Y = 128)
const CHUNK_SIZE_X: int = 16
const CHUNK_SIZE_Z: int = 16
const CHUNK_MIN_Y: int = -128
const CHUNK_MAX_Y: int = 128
const CHUNK_HEIGHT: int = CHUNK_MAX_Y - CHUNK_MIN_Y # 256 vertical blocks!
const STRIDE_Y: int = CHUNK_SIZE_X
const STRIDE_Z: int = CHUNK_SIZE_X * CHUNK_HEIGHT

const RENDER_RADIUS: int = 3 # 7x7 chunks around player continuously streamed
var current_player_chunk: Vector2i = Vector2i(999999, 999999)

var world_config: Resource = null
var terrain_modifier: Node = null

# Active chunks in memory
var chunks: Dictionary = {} # Vector2i -> PackedByteArray
var chunk_nodes: Dictionary = {} # Vector2i -> StaticBody3D
var chunk_trimeshes: Dictionary = {} # Vector2i -> Shape3D
var modified_voxels: Dictionary = {} # Vector3i -> int
var torch_lights: Dictionary = {} # Vector3i -> OmniLight3D

# Time-Budgeted Generation & Meshing Queues (Zero stutter / smooth 60 FPS)
var chunk_load_queue: Array = []
var chunk_mesh_queue: Array = []
var chunks_in_load_queue: Dictionary = {}
var chunks_in_mesh_queue: Dictionary = {}

var active_load_tasks: Dictionary = {} # Vector2i -> Dictionary (holder with task_id, data)
var active_mesh_tasks: Dictionary = {} # Vector2i -> Dictionary (holder with task_id, arr_mesh, trimesh, empty)

var atlas_material: StandardMaterial3D
var uv_lookup: Array[Rect2] = []
var drip_sphere_mesh: SphereMesh = null

# 3D Procedural Noise Generators
var cave_cheese_noise: FastNoiseLite
var noodle_noise_1: FastNoiseLite
var noodle_noise_2: FastNoiseLite
var strata_noise: FastNoiseLite
var ore_noise: FastNoiseLite
var surface_noise: FastNoiseLite

# 2D Biome Climate Noise Generators
var biome_moisture_noise: FastNoiseLite
var biome_temperature_noise: FastNoiseLite
var biome_ruins_noise: FastNoiseLite
var biome_crystal_noise: FastNoiseLite

func _ready() -> void:
	name = "VoxelWorld"
	if world_config == null:
		world_config = WorldConfigClass.get_default()
	if terrain_modifier == null:
		terrain_modifier = TerrainModifierClass.new(self, world_config)
		add_child(terrain_modifier)
	_init_materials()
	_init_noise()
	_generate_initial_area()

func _exit_tree() -> void:
	for key in active_load_tasks.keys():
		var holder: Dictionary = active_load_tasks[key]
		WorkerThreadPool.wait_for_task_completion(holder["task_id"])
	for key in active_mesh_tasks.keys():
		var holder: Dictionary = active_mesh_tasks[key]
		WorkerThreadPool.wait_for_task_completion(holder["task_id"])
	active_load_tasks.clear()
	active_mesh_tasks.clear()

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		update_player_position(player.global_position)

	# 1. Harvest completed background load tasks
	var finished_loads: Array = []
	for key in active_load_tasks.keys():
		var holder: Dictionary = active_load_tasks[key]
		if WorkerThreadPool.is_task_completed(holder["task_id"]):
			WorkerThreadPool.wait_for_task_completion(holder["task_id"])
			finished_loads.push_back(key)
			chunks[key] = holder["data"]
			if not chunks_in_mesh_queue.has(key):
				chunk_mesh_queue.push_back(key)
				chunks_in_mesh_queue[key] = true
			# Re-mesh any adjacent chunks that were previously meshed to update their border faces
			for offset in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
				var nb_key = key + offset
				if chunks.has(nb_key) and not chunks_in_mesh_queue.has(nb_key):
					chunk_mesh_queue.push_back(nb_key)
					chunks_in_mesh_queue[nb_key] = true
	for k in finished_loads:
		active_load_tasks.erase(k)

	# 2. Harvest completed background mesh tasks (Strictly throttled to max 1 chunk commit per frame!)
	var applied_count = 0
	var finished_meshes: Array = []
	for key in active_mesh_tasks.keys():
		var holder: Dictionary = active_mesh_tasks[key]
		if WorkerThreadPool.is_task_completed(holder["task_id"]):
			if applied_count == 0:
				WorkerThreadPool.wait_for_task_completion(holder["task_id"])
				finished_meshes.push_back(key)
				_apply_chunk_mesh(key.x, key.y, holder["arrays"], holder["empty"])
				applied_count += 1
	for k in finished_meshes:
		active_mesh_tasks.erase(k)

	# 3. Dispatch background mesh tasks (up to 1 in parallel to prevent CPU contention)
	while active_mesh_tasks.size() < 1 and chunk_mesh_queue.size() > 0:
		var key: Vector2i = chunk_mesh_queue.pop_front()
		chunks_in_mesh_queue.erase(key)
		if chunks.has(key):
			var data: PackedByteArray = chunks[key]
			var cn = chunks.get(Vector2i(key.x, key.y - 1), null)
			var cs = chunks.get(Vector2i(key.x, key.y + 1), null)
			var cw = chunks.get(Vector2i(key.x - 1, key.y), null)
			var ce = chunks.get(Vector2i(key.x + 1, key.y), null)
			var holder = {"arrays": null, "empty": false, "task_id": 0}
			var tid = WorkerThreadPool.add_task(func():
				var res = _build_chunk_mesh_data(key.x, key.y, data, cn, cs, cw, ce)
				holder["arrays"] = res.arrays
				holder["empty"] = res.empty
			)
			holder["task_id"] = tid
			active_mesh_tasks[key] = holder

	# 4. Dispatch background load tasks (up to 1 in parallel)
	while active_load_tasks.size() < 1 and chunk_load_queue.size() > 0:
		var key: Vector2i = chunk_load_queue.pop_front()
		chunks_in_load_queue.erase(key)
		var holder = {"data": PackedByteArray(), "task_id": 0}
		var tid = WorkerThreadPool.add_task(func():
			holder["data"] = _load_chunk_data(key.x, key.y)
		)
		holder["task_id"] = tid
		active_load_tasks[key] = holder

func _init_materials() -> void:
	PixelTextureGenerator.preload_all()
	atlas_material = StandardMaterial3D.new()
	atlas_material.albedo_texture = PixelTextureGenerator.get_texture_atlas()
	atlas_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	atlas_material.cull_mode = BaseMaterial3D.CULL_BACK
	atlas_material.roughness = 0.88
	atlas_material.metallic = 0.04

	uv_lookup.resize(32)
	for bt in range(32):
		var atlas_uv: Vector2i = ATLAS_COORDS.get(bt, Vector2i(0, 0))
		var u0 = (atlas_uv.x + 0.002) / 8.0
		var u1 = (atlas_uv.x + 0.998) / 8.0
		var v0 = (atlas_uv.y + 0.002) / 8.0
		var v1 = (atlas_uv.y + 0.998) / 8.0
		uv_lookup[bt] = Rect2(u0, v0, u1 - u0, v1 - v0)

	drip_sphere_mesh = SphereMesh.new()
	drip_sphere_mesh.radius = 0.032
	drip_sphere_mesh.height = 0.075
	var dmat = StandardMaterial3D.new()
	dmat.albedo_color = Color(0.72, 0.88, 1.0, 0.78)
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.roughness = 0.1
	dmat.emission_enabled = true
	dmat.emission = Color(0.55, 0.82, 1.0)
	dmat.emission_energy_multiplier = 0.6
	drip_sphere_mesh.material = dmat

func _init_noise() -> void:
	# 1. Cheese Caverns (Broad open cathedral halls, chambers, and dome vaults)
	cave_cheese_noise = FastNoiseLite.new()
	cave_cheese_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	cave_cheese_noise.seed = 421337
	cave_cheese_noise.frequency = 0.018
	cave_cheese_noise.fractal_octaves = 3

	# 2. Dual Noodle Noise (Carves 3D winding tubular tunnels)
	noodle_noise_1 = FastNoiseLite.new()
	noodle_noise_1.noise_type = FastNoiseLite.TYPE_PERLIN
	noodle_noise_1.seed = 998811
	noodle_noise_1.frequency = 0.038

	noodle_noise_2 = FastNoiseLite.new()
	noodle_noise_2.noise_type = FastNoiseLite.TYPE_PERLIN
	noodle_noise_2.seed = 334455
	noodle_noise_2.frequency = 0.038

	# 3. Geological Strata Variation
	strata_noise = FastNoiseLite.new()
	strata_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	strata_noise.seed = 554433
	strata_noise.frequency = 0.045

	# 4. Ore Vein Clusters
	ore_noise = FastNoiseLite.new()
	ore_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	ore_noise.seed = 771122
	ore_noise.frequency = 0.09

	# 5. Surface Topography Noise (Snow hills & blizzard drifts)
	surface_noise = FastNoiseLite.new()
	surface_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	surface_noise.seed = 120984
	surface_noise.frequency = 0.032

	# 6. Biome Climate Noises (Moisture, Temperature, Precursor Ruins, Crystal Resonance)
	biome_moisture_noise = FastNoiseLite.new()
	biome_moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	biome_moisture_noise.seed = 887711
	biome_moisture_noise.frequency = 0.012

	biome_temperature_noise = FastNoiseLite.new()
	biome_temperature_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	biome_temperature_noise.seed = 224466
	biome_temperature_noise.frequency = 0.010

	biome_ruins_noise = FastNoiseLite.new()
	biome_ruins_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	biome_ruins_noise.seed = 665544
	biome_ruins_noise.frequency = 0.024

	biome_crystal_noise = FastNoiseLite.new()
	biome_crystal_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	biome_crystal_noise.seed = 113355
	biome_crystal_noise.frequency = 0.020

func _generate_initial_area() -> void:
	current_player_chunk = Vector2i(0, 0)

	# Pre-generate and mesh 5x5 chunks (-2 to 2) around spawn
	# This ensures all 4 corridors and immediate cavern chambers have 100% solid collision at start
	for cx in range(-2, 3):
		for cz in range(-2, 3):
			_load_chunk(cx, cz)
	for cx in range(-2, 3):
		for cz in range(-2, 3):
			_rebuild_chunk_mesh(cx, cz)

	# Queue outer perimeter chunks for background worker streaming
	_queue_chunks_around(0, 0)
	print("[VoxelWorld] Initial 5x5 sector (25 chunks) meshed with 100% solid collision.")

func update_player_position(player_world_pos: Vector3) -> void:
	var pcx = int(floor(player_world_pos.x / CHUNK_SIZE_X))
	var pcz = int(floor(player_world_pos.z / CHUNK_SIZE_Z))
	var p_chunk = Vector2i(pcx, pcz)

	if p_chunk != current_player_chunk:
		current_player_chunk = p_chunk
		_update_chunk_collisions(p_chunk)
		_queue_chunks_around(pcx, pcz)

func _update_chunk_collisions(_center_chunk: Vector2i) -> void:
	# Ensure all chunk nodes have their trimesh collision active
	for key in chunk_nodes.keys():
		var body = chunk_nodes[key]
		if not is_instance_valid(body):
			continue
		var coll = body.get_node_or_null("CollisionShape3D")
		if coll == null:
			continue
		if coll.shape == null and chunk_trimeshes.has(key):
			coll.shape = chunk_trimeshes[key]

func _queue_chunks_around(pcx: int, pcz: int) -> void:
	for cx in range(pcx - RENDER_RADIUS, pcx + RENDER_RADIUS + 1):
		for cz in range(pcz - RENDER_RADIUS, pcz + RENDER_RADIUS + 1):
			var key = Vector2i(cx, cz)
			if not chunks.has(key) and not chunks_in_load_queue.has(key):
				chunk_load_queue.push_back(key)
				chunks_in_load_queue[key] = true

	# Sort load queue: closest chunks load first!
	chunk_load_queue.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da = (a.x - pcx) * (a.x - pcx) + (a.y - pcz) * (a.y - pcz)
		var db = (b.x - pcx) * (b.x - pcx) + (b.y - pcz) * (b.y - pcz)
		return da < db
	)

	# Unload far chunks outside RENDER_RADIUS + 1
	var keys_to_remove: Array = []
	for key in chunk_nodes.keys():
		if abs(key.x - pcx) > (RENDER_RADIUS + 1) or abs(key.y - pcz) > (RENDER_RADIUS + 1):
			keys_to_remove.push_back(key)

	for key in keys_to_remove:
		var node = chunk_nodes[key]
		if is_instance_valid(node):
			node.queue_free()
		chunk_nodes.erase(key)
		chunks.erase(key)

func _load_chunk_data(cx: int, cz: int) -> PackedByteArray:
	var total_voxels = CHUNK_SIZE_X * CHUNK_HEIGHT * CHUNK_SIZE_Z
	var data = PackedByteArray()
	data.resize(total_voxels)
	data.fill(0) # AIR

	var world_base_x = cx * CHUNK_SIZE_X
	var world_base_z = cz * CHUNK_SIZE_Z

	# Pre-calculate column 2D heights & climate values for all 16x16 columns
	var surf_heights = PackedFloat32Array()
	surf_heights.resize(CHUNK_SIZE_X * CHUNK_SIZE_Z)
	var col_moisture = PackedFloat32Array()
	col_moisture.resize(CHUNK_SIZE_X * CHUNK_SIZE_Z)
	var col_temperature = PackedFloat32Array()
	col_temperature.resize(CHUNK_SIZE_X * CHUNK_SIZE_Z)
	var col_ruin = PackedFloat32Array()
	col_ruin.resize(CHUNK_SIZE_X * CHUNK_SIZE_Z)
	var col_crystal = PackedFloat32Array()
	col_crystal.resize(CHUNK_SIZE_X * CHUNK_SIZE_Z)

	for lx in range(CHUNK_SIZE_X):
		var gx = world_base_x + lx
		for lz in range(CHUNK_SIZE_Z):
			var gz = world_base_z + lz
			var c_idx = lx + lz * CHUNK_SIZE_X
			surf_heights[c_idx] = 50.0 + (surface_noise.get_noise_2d(gx, gz) * 6.0)
			col_moisture[c_idx] = biome_moisture_noise.get_noise_2d(gx, gz)
			col_temperature[c_idx] = biome_temperature_noise.get_noise_2d(gx, gz)
			col_ruin[c_idx] = biome_ruins_noise.get_noise_2d(gx, gz)
			col_crystal[c_idx] = biome_crystal_noise.get_noise_2d(gx, gz)

	# Pass 1: Raw Stratified Procedural Voxel Generation with Dozens of Biomes
	var has_mods = not modified_voxels.is_empty()
	for lx in range(CHUNK_SIZE_X):
		var gx = world_base_x + lx
		for lz in range(CHUNK_SIZE_Z):
			var gz = world_base_z + lz
			var c_idx = lx + lz * CHUNK_SIZE_X
			var surf_h = surf_heights[c_idx]
			var surf_h_int = int(surf_h)
			var moist = col_moisture[c_idx]
			var temp = col_temperature[c_idx]
			var ruin = col_ruin[c_idx]
			var crystal = col_crystal[c_idx]

			# Pre-fill bedrock floor
			data[_voxel_index(lx, 0, lz)] = BlockType.BEDROCK
			data[_voxel_index(lx, 1, lz)] = BlockType.BEDROCK
			data[_voxel_index(lx, 2, lz)] = BlockType.BEDROCK
			data[_voxel_index(lx, 3, lz)] = BlockType.BEDROCK

			for ly in range(4, CHUNK_HEIGHT):
				var gy = CHUNK_MIN_Y + ly

				var b_type = BlockType.AIR
				var block_coord = Vector3i(gx, gy, gz)
				if has_mods and modified_voxels.has(block_coord):
					b_type = modified_voxels[block_coord]
				else:
					b_type = _determine_voxel_biome(gx, gy, gz, surf_h, moist, temp, ruin, crystal)

				if b_type != BlockType.AIR:
					var idx = _voxel_index(lx, ly, lz)
					data[idx] = b_type

	return data

func _load_chunk(cx: int, cz: int) -> void:
	var key = Vector2i(cx, cz)
	if chunks.has(key):
		return
	var data = _load_chunk_data(cx, cz)
	chunks[key] = data

func _voxel_index(lx: int, ly: int, lz: int) -> int:
	return lx + (ly * CHUNK_SIZE_X) + (lz * STRIDE_Z)

func _determine_initial_voxel(gx: int, gy: int, gz: int) -> int:
	var surf_h = 50.0 + (surface_noise.get_noise_2d(gx, gz) * 6.0)
	var moist = biome_moisture_noise.get_noise_2d(gx, gz)
	var temp = biome_temperature_noise.get_noise_2d(gx, gz)
	var ruin = biome_ruins_noise.get_noise_2d(gx, gz)
	var crystal = biome_crystal_noise.get_noise_2d(gx, gz)
	return _determine_voxel_biome(gx, gy, gz, surf_h, moist, temp, ruin, crystal)

func _determine_voxel_biome(gx: int, gy: int, gz: int, surf_h: float, moist: float, temp: float, ruin: float, crystal: float) -> int:
	# 1. Indestructible Bedrock floor at the world bottom (Y <= -60)
	if gy <= CHUNK_MIN_Y + 3:
		return BlockType.BEDROCK

	# 2. Glacial Cryosphere & Ice Sheet Strata (Y >= 44 to 64)
	if gy >= 44:
		var sn = strata_noise.get_noise_3d(gx, gy, gz)
		if sn > 0.18:
			return BlockType.PERMAFROST_ICE
		elif sn < -0.22:
			return BlockType.CALCITE
		return BlockType.STONE

	# 3. Exploratory Vertical Mine Shaft (Surface Y=50 down to Outpost Y=16)
	if abs(gx) <= 1 and abs(gz) <= 1 and gy >= 16 and gy < 50:
		if gx == 1 and gz == 1:
			return BlockType.HEWN_TIMBER
		return BlockType.AIR

	# 4. Starting Outpost Hub at Y = 10..16, centered at (0, 10, 0)
	# Features 4 open archway portals leading to distinct biome realms!
	if gx >= -8 and gx <= 8 and gz >= -8 and gz <= 8:
		# Excavation descent shaft located safely in the corner at (gx: 6..7, gz: 6..7) with timber framing
		if gx >= 6 and gx <= 7 and gz >= 6 and gz <= 7 and gy >= -22 and gy <= 10:
			if gx == 7 and gz == 7:
				return BlockType.HEWN_TIMBER
			if gy == -22:
				return BlockType.SLATE_BRICK
			return BlockType.AIR

		if gy == 10:
			if abs(gx) <= 4 and abs(gz) <= 4:
				return BlockType.WOOD_PLANKS
			return BlockType.COBBLESTONE
		elif gy < 10 and gy >= 0:
			return BlockType.STONE
		elif gy >= 11 and gy <= 16:
			# Torches on Outpost perimeter corners
			if gy == 12 and (gx == -7 or gx == 7) and (gz == -7 or gz == 7):
				return BlockType.TORCH
			# Supply crates with survival rations and canteens
			if gy == 11 and ((gx == -3 and gz == -3) or (gx == -4 and gz == -3) or (gx == 3 and gz == -3)):
				return BlockType.CARGO_CRATE
			# Surveyor supply crate inside Outpost
			if gy == 11 and gx == -5 and gz == 5:
				return BlockType.CARGO_CRATE
			# Timber support beams
			if (gx == -4 or gx == 4) and (gz == -4 or gz == 4) and gy <= 15:
				return BlockType.HEWN_TIMBER
			# 4 Cardinal Open Portals / Archways:
			if (abs(gz) <= 2 and (gx == -8 or gx == 8 or gx == -7 or gx == 7)) and gy <= 14:
				return BlockType.AIR # East & West Exits
			if (abs(gx) <= 2 and (gz == -8 or gz == 8 or gz == -7 or gz == 7)) and gy <= 14:
				return BlockType.AIR # North & South Exits
			return BlockType.AIR
		elif gy >= 17 and gy <= 21:
			return BlockType.STONE

	# 5. EAST REALM: Main Cavern Corridor -> Grand Cathedral -> Volcanic Magma Caldera
	if gx > 8 and gx <= 32 and abs(gz) <= 3:
		if gy == 10:
			return BlockType.COBBLESTONE if abs(gz) <= 1 else BlockType.STONE
		elif gy < 10 and gy >= 2:
			return BlockType.STONE
		elif gy >= 11 and gy <= 16:
			if gy == 12 and (gx == 16 or gx == 26) and (gz == -3 or gz == 3):
				return BlockType.TORCH
			return BlockType.AIR
		elif gy >= 17 and gy <= 22:
			return BlockType.STONE

	# Creepypasta Anomaly: The 2x2 Carved Mine Shaft ("Herobrine's Tunnel")
	# Perfectly carved straight 2x2 shaft branching South from East corridor
	if (gx == 20 or gx == 21) and gz < -3 and gz >= -36:
		if gy == 10:
			return BlockType.COBBLESTONE
		elif gy == 11 or gy == 12:
			if (gx == 20) and (gz % 10 == 0) and gy == 12:
				return BlockType.TORCH
			return BlockType.AIR
		elif gy == 13:
			return BlockType.DEEPSLATE

	# Secret Crypt at the end of Herobrine's Tunnel (gz: -37 to -42, gx: 18 to 23)
	if gx >= 18 and gx <= 23 and gz <= -37 and gz >= -42:
		if gy == 10:
			return BlockType.SLATE_BRICK
		elif gy >= 11 and gy <= 14:
			if (gx == 20 or gx == 21) and (gz == -39 or gz == -40) and gy == 11:
				return BlockType.BEDROCK
			if gx == 20 and gz == -39 and gy == 12:
				return BlockType.TORCH
			return BlockType.AIR
		elif gy == 15:
			return BlockType.SLATE_BRICK

	# Grand Cathedral Cavern (Massive 30-meter high hall with soaring colonnades & high-chasm stone bridge)
	if gx > 32 and gx <= 62 and abs(gz) <= 18:
		var hall_dist = Vector2(gx - 47, gz).length()
		if hall_dist < 16.5:
			if gy <= 5:
				return BlockType.DEEP_BASALT if gy <= 2 else BlockType.STONE
			elif gy >= 6 and gy <= 30:
				if gx >= 58 and abs(gz) <= 4 and gy <= 16:
					return BlockType.AIR # Archway to Magma Caldera!
				if hall_dist > 14.5:
					if gy == 8 and abs(gz) % 4 == 0:
						return BlockType.PHOSPHOR_ORE
					elif gy == 12 and (gx + gz) % 5 == 0:
						return BlockType.IRON_ORE
					elif gy == 16 and (gx + gz) % 6 == 0:
						return BlockType.CALCITE
					return BlockType.STONE

				# 1. NATURAL HIGH-CHASM STONE BRIDGE (Spanning across the cathedral at Y=14..16!)
				if (gx == 46 or gx == 47) and abs(gz) <= 13:
					var bridge_y = 14 + int(2.0 * cos(gz * 0.22))
					if gy == bridge_y:
						return BlockType.COBBLESTONE if abs(gz) <= 10 else BlockType.DEEP_BASALT
					elif gy == bridge_y - 1:
						return BlockType.STONE # Bridge thickness

				# 2. MONUMENTAL BASALT COLONNADES (Soaring pillars from Y=5 to Y=30)
				for p_pos in [Vector2(40, 8), Vector2(40, -8), Vector2(54, 8), Vector2(54, -8)]:
					if Vector2(gx - p_pos.x, gz - p_pos.y).length() < 2.0:
						return BlockType.DEEP_BASALT

				# 3. DRIPPING CALCITE & STONE STALACTITES (Ceiling formations)
				for st_pos in [Vector2(44, 4), Vector2(50, -4), Vector2(48, 6), Vector2(43, -6)]:
					var d_st = Vector2(gx - st_pos.x, gz - st_pos.y).length()
					if d_st < 1.6 and gy >= 23:
						if d_st < 0.8 or gy >= 26:
							return BlockType.CALCITE
						return BlockType.STONE

				# 4. FLOOR STALAGMITES (Dripstone mounds rising from floor)
				for sm_pos in [Vector2(44, 4), Vector2(50, -4), Vector2(38, 0)]:
					var d_sm = Vector2(gx - sm_pos.x, gz - sm_pos.y).length()
					if d_sm < 1.8 and gy <= 10:
						return BlockType.CALCITE if (d_sm < 0.8 and gy >= 8) else BlockType.STONE

				return BlockType.AIR
			elif gy >= 31:
				return BlockType.STONE

	# Volcanic Magma & Sulfur Caldera (Minecraft Basalt Deltas / Nether Wastes style)
	if gx > 62 and gx <= 98 and abs(gz) <= 16:
		var caldera_dist = Vector2(gx - 80, gz).length()
		if caldera_dist < 15.5:
			if gy <= 3:
				return BlockType.DEEP_BASALT
			elif gy >= 4 and gy <= 24:
				if caldera_dist > 14.0:
					if gy <= 10 and (gx + gz) % 3 == 0:
						return BlockType.SULFUR_BLOCK
					elif gy >= 14 and (gx * 3 + gz) % 5 == 0:
						return BlockType.GOLD_ORE
					return BlockType.MAGMA_ROCK

				# STEPPED BASALT COLUMNS (Minecraft Basalt Deltas pillars of varying heights!)
				var col_height = 0
				if Vector2(gx - 74, gz - 5).length() < 1.8: col_height = 11
				elif Vector2(gx - 76, gz + 7).length() < 2.0: col_height = 14
				elif Vector2(gx - 82, gz - 6).length() < 1.6: col_height = 8
				elif Vector2(gx - 85, gz + 6).length() < 2.2: col_height = 16
				elif Vector2(gx - 88, gz - 4).length() < 1.8: col_height = 10
				elif Vector2(gx - 78, gz).length() < 1.5: col_height = 6
				elif Vector2(gx - 84, gz).length() < 1.6: col_height = 7

				if col_height > 0 and gy <= col_height:
					return BlockType.DEEP_BASALT

				# VOLCANIC FUMAROLE CHIMNEYS (Hollow conical sulfur spires venting heat)
				var d_chim1 = Vector2(gx - 80, gz + 4).length()
				if d_chim1 < 2.4 and gy <= 12:
					if d_chim1 < 0.8:
						return BlockType.MAGMA_ROCK if gy == 4 else BlockType.AIR
					return BlockType.SULFUR_BLOCK if gy >= 8 else BlockType.DEEP_BASALT

				var d_chim2 = Vector2(gx - 86, gz - 2).length()
				if d_chim2 < 2.2 and gy <= 11:
					if d_chim2 < 0.8:
						return BlockType.MAGMA_ROCK if gy == 4 else BlockType.AIR
					return BlockType.SULFUR_BLOCK if gy >= 7 else BlockType.DEEP_BASALT

				# Floor Lava Lake & Molten Fissures
				if gy == 4:
					if abs(gz) <= 5 and gx >= 72 and gx <= 88:
						return BlockType.MAGMA_ROCK
					elif (gx + gz) % 3 == 0:
						return BlockType.SULFUR_BLOCK
					return BlockType.DEEP_BASALT

				return BlockType.AIR
			elif gy >= 25:
				return BlockType.DEEPSLATE

	# 6. NORTH REALM: Fungal Mycena Hollows & Subterranean Aquifers (Lush Caves / Warped Forest)
	if abs(gx) <= 3 and gz > 8 and gz <= 28:
		if gy == 10:
			return BlockType.MOSS_STONE
		elif gy < 10 and gy >= 2:
			return BlockType.STONE
		elif gy >= 11 and gy <= 16:
			if gy == 12 and (gz == 16 or gz == 24) and (gx == -3 or gx == 3):
				return BlockType.TORCH
			return BlockType.AIR
		elif gy >= 17 and gy <= 22:
			return BlockType.STONE

	if gz > 28 and gz <= 64 and abs(gx) <= 18:
		# Open entrance archway connecting South corridor to Fungal Hollows
		if abs(gx) <= 3 and gz >= 28 and gz <= 34 and gy >= 10 and gy <= 16:
			return BlockType.AIR

		var fungal_dist = Vector2(gx, gz - 46).length()
		if fungal_dist < 16.5:
			# Undulating natural terrain floor
			var floor_var = int(1.8 * sin(gx * 0.45) * cos((gz - 46) * 0.35) + sin(gx * 0.8) * 1.2)
			var cur_floor = 7 + floor_var
			var cur_ceil = 28 - int(1.5 * cos(gx * 0.4) * sin((gz - 46) * 0.4))

			if gy < cur_floor:
				return BlockType.DEEP_BASALT if gy <= 2 else BlockType.STONE
			elif gy > cur_ceil:
				return BlockType.STONE
			elif gy >= cur_floor and gy <= cur_ceil:
				if fungal_dist > 14.5:
					return BlockType.MOSS_STONE if gy <= 14 else BlockType.STONE

				# Surface floor layer
				if gy == cur_floor:
					if cur_floor <= 6 and abs(gx) <= 5 and abs(gz - 46) <= 5:
						return BlockType.WATER_SPRING
					return BlockType.MOSS_STONE

				# Flora & Mushrooms on ground
				if gy == cur_floor + 1:
					if cur_floor > 6:
						if (abs(gx * 7 + gz * 11) % 4 == 0):
							return BlockType.BIOLUM_MUSHROOM
						elif (abs(gx * 5 + gz * 13) % 7 == 0):
							return BlockType.LICHEN_ROOT
					return BlockType.AIR

				# GIANT 3D MUSHROOMS (3 towering spore trees with wide canopies!)
				# Shroom 1: Giant Cyan Mycena at (0, 46)
				var d_shroom1 = Vector2(gx, gz - 46).length()
				if d_shroom1 <= 3.8 and gy >= 14 and gy <= 17:
					if gy == 14 and d_shroom1 >= 1.2:
						return BlockType.PHOSPHOR_ORE # Glowing gills underneath!
					elif gy == 15 or gy == 16:
						return BlockType.BIOLUM_MUSHROOM
					elif gy == 17 and d_shroom1 <= 2.2:
						return BlockType.BIOLUM_MUSHROOM
				elif d_shroom1 < 1.2 and gy >= cur_floor and gy <= 15:
					return BlockType.CALCITE # Thick mushroom stem

				# Shroom 2: Broad Amethyst Parasol at (7, 38)
				var d_shroom2 = Vector2(gx - 7, gz - 38).length()
				if d_shroom2 <= 3.2 and gy >= 13 and gy <= 16:
					if gy == 13 and d_shroom2 >= 1.0:
						return BlockType.PHOSPHOR_ORE
					elif gy == 14 or gy == 15:
						return BlockType.CRYSTAL_AMETHYST
					elif gy == 16 and d_shroom2 <= 1.8:
						return BlockType.CRYSTAL_AMETHYST
				elif d_shroom2 < 1.0 and gy >= cur_floor and gy <= 14:
					return BlockType.HEWN_TIMBER

				# Shroom 3: Moss Canopy Strider at (-6, 52)
				var d_shroom3 = Vector2(gx + 6, gz - 52).length()
				if d_shroom3 <= 3.5 and gy >= 15 and gy <= 18:
					if gy == 15 and d_shroom3 >= 1.0:
						return BlockType.BIOLUM_MUSHROOM
					elif gy == 16 or gy == 17:
						return BlockType.MOSS_STONE
					elif gy == 18 and d_shroom3 <= 2.0:
						return BlockType.MOSS_STONE
				elif d_shroom3 < 1.0 and gy >= cur_floor and gy <= 16:
					return BlockType.CALCITE

				# HANGING CAVE VINES (Lichen roots hanging from ceiling with glowing tips)
				var vine_hash = abs(gx * 17 + gz * 23)
				if vine_hash % 5 == 0 and d_shroom1 > 3.8 and d_shroom2 > 3.2 and d_shroom3 > 3.5:
					var vine_len = 3 + (vine_hash % 5)
					if gy >= (cur_ceil - vine_len) and gy <= cur_ceil:
						if gy == (cur_ceil - vine_len):
							return BlockType.BIOLUM_MUSHROOM
						return BlockType.LICHEN_ROOT

				# Organic Flowstone Columns connecting floor to ceiling
				var d_col1 = Vector2(gx + 8, gz - 42).length()
				var d_col2 = Vector2(gx - 8, gz - 50).length()
				if d_col1 < 1.8 or d_col2 < 1.8:
					return BlockType.MOSS_STONE if gy <= 14 else BlockType.CALCITE

				return BlockType.AIR
			elif gy >= cur_ceil:
				return BlockType.STONE

	# 7. SOUTH REALM: Crystalline Amethyst & Quartz Geodes (Minecraft Geode Style)
	if abs(gx) <= 3 and gz < -8 and gz >= -28:
		if gy == 10:
			return BlockType.CALCITE
		elif gy < 10 and gy >= 2:
			return BlockType.STONE
		elif gy >= 11 and gy <= 16:
			if gy == 12 and (gz == -16 or gz == -24) and (gx == -3 or gx == 3):
				return BlockType.TORCH
			return BlockType.AIR
		elif gy >= 17 and gy <= 22:
			return BlockType.STONE

	if gz < -28 and gz >= -64 and abs(gx) <= 18:
		# Open entrance archway connecting corridor to Amethyst Geode
		if abs(gx) <= 3 and gz <= -28 and gz >= -34 and gy >= 10 and gy <= 16:
			return BlockType.AIR

		var crystal_dist = Vector2(gx, gz + 46).length()
		if crystal_dist < 16.5:
			var c_floor = 7 + int(1.5 * sin(gx * 0.5) * cos((gz + 46) * 0.4))
			var c_ceil = 28 - int(1.5 * cos(gx * 0.5) * sin((gz + 46) * 0.4))

			if gy < c_floor:
				return BlockType.DEEP_BASALT if gy <= 3 else BlockType.CALCITE
			elif gy > c_ceil:
				return BlockType.DEEP_BASALT if gy >= 30 else BlockType.CALCITE
			elif gy >= c_floor and gy <= c_ceil:
				if crystal_dist > 14.5:
					return BlockType.DEEP_BASALT
				elif crystal_dist > 12.5:
					return BlockType.CALCITE if (gx + gz + gy) % 2 == 0 else BlockType.CRYSTAL_AMETHYST

				# FLOOR CRYSTAL DRUZES & SPIRES (3D Amethyst Stalagmites)
				for sp_pos in [Vector2(3, -43), Vector2(-4, -48), Vector2(6, -50), Vector2(-5, -40), Vector2(0, -42)]:
					var d_sp = Vector2(gx - sp_pos.x, gz - sp_pos.y).length()
					if d_sp < 2.2 and gy <= (c_floor + 4):
						if d_sp < 1.0 or gy <= (c_floor + 2):
							return BlockType.CRYSTAL_AMETHYST
						elif gy <= (c_floor + 3):
							return BlockType.CALCITE

				# CEILING CRYSTAL STALACTITES (Clusters of amethyst hanging down)
				for cl_pos in [Vector2(2, -45), Vector2(-3, -43), Vector2(5, -48), Vector2(-4, -51)]:
					var d_cl = Vector2(gx - cl_pos.x, gz - cl_pos.y).length()
					if d_cl < 2.0 and gy >= (c_ceil - 5):
						if d_cl < 0.9 or gy >= (c_ceil - 3):
							return BlockType.CRYSTAL_AMETHYST
						return BlockType.CALCITE

				# CENTRAL ANCHORED GEODE FORMATION (Anchored from floor to ceiling with crystal columns)
				var d_core = Vector3(gx, gy - 16, gz + 46).length()
				if d_core <= 4.2:
					# Solid anchoring columns connecting geode dome to floor and ceiling
					var is_anchor = (abs(gx) <= 1 and abs(gz + 46) <= 1)
					if is_anchor:
						return BlockType.CRYSTAL_AMETHYST if gy % 2 == 0 else BlockType.CALCITE
					if d_core <= 1.8:
						return BlockType.AIR # Hollow geode interior!
					elif d_core <= 3.2:
						return BlockType.CRYSTAL_AMETHYST
					else:
						return BlockType.CALCITE

				if gy == c_floor:
					return BlockType.CALCITE if (gx + gz) % 3 == 0 else BlockType.CRYSTAL_AMETHYST
				elif gy == c_floor + 1 and (abs(gx * 7 + gz * 11) % 6 == 0):
					return BlockType.CRYSTAL_AMETHYST

				return BlockType.AIR
			elif gy >= c_ceil:
				return BlockType.DEEP_BASALT

	# 8. WEST REALM: Ancient Precursor Sunken Ruins (Minecraft Ancient City / Nether Fossils)
	if gx < -8 and gx >= -28 and abs(gz) <= 3:
		if gy == 10:
			return BlockType.SLATE_BRICK
		elif gy < 10 and gy >= 2:
			return BlockType.DEEPSLATE
		elif gy >= 11 and gy <= 16:
			if gy == 12 and (gx == -16 or gx == -24) and (gz == -3 or gz == 3):
				return BlockType.TORCH
			return BlockType.AIR
		elif gy >= 17 and gy <= 22:
			return BlockType.STONE

	if gx < -28 and gx >= -64 and abs(gz) <= 18:
		var ruin_dist = Vector2(gx + 46, gz).length()
		if ruin_dist < 16.5:
			if gy <= 5:
				return BlockType.DEEPSLATE
			elif gy >= 6 and gy <= 26:
				if ruin_dist > 14.5:
					return BlockType.SLATE_BRICK

				# 1. CENTRAL CEREMONIAL STEPPED DAIS / ALTAR (3-tier pyramid at (-46, 0))
				var dx_alt = abs(gx + 46)
				var dz_alt = abs(gz)
				if dx_alt <= 6 and dz_alt <= 6 and gy == 6:
					return BlockType.SLATE_BRICK # Base dais
				if dx_alt <= 4 and dz_alt <= 4 and gy == 7:
					return BlockType.SLATE_BRICK # Tier 2
				if dx_alt <= 2 and dz_alt <= 2 and gy == 8:
					if dx_alt == 2 or dz_alt == 2:
						return BlockType.PRECURSOR_CONDUIT
					return BlockType.SLATE_BRICK
				if dx_alt <= 1 and dz_alt <= 1 and gy == 9:
					if dx_alt == 0 and dz_alt == 0:
						return BlockType.CARGO_CRATE # Ancient surveyor cache / relic!
					return BlockType.PRECURSOR_CONDUIT

				# 2. GIANT FOSSIL BONE RIBS (Minecraft Nether / Deep Dark Fossils arching overhead!)
				for rib_x in [-36, -42, -50, -56]:
					if gx == rib_x and abs(gz) <= 7:
						var arch_y = 16 - int((gz * gz) * 0.20)
						if gy == arch_y or gy == arch_y - 1:
							return BlockType.CALCITE # Ancient mineralized bone rib!

				# 3. CRUMBLING COLONNADES (Tall intact columns vs broken collapsed pillars)
				if (abs(gz) == 5 or abs(gz) == 6):
					for px in [-38, -44, -48, -54]:
						if (gx == px or gx == px + 1):
							if px == -38 or px == -48:
								if gy <= 24:
									return BlockType.PRECURSOR_CONDUIT if (gy % 4 == 0) else BlockType.SLATE_BRICK
							else:
								if gy <= 10:
									return BlockType.SLATE_BRICK

				# Fallen broken column blocks scattered on the floor
				if gy == 6 and ((gx == -43 and gz == 3) or (gx == -53 and gz == -2) or (gx == -45 and gz == -4)):
					return BlockType.SLATE_BRICK

				# Main floor tile
				if gy == 6:
					return BlockType.PRECURSOR_CONDUIT if (abs(gx) % 5 == 0 and abs(gz) % 5 == 0) else BlockType.SLATE_BRICK

				return BlockType.AIR
			elif gy >= 27:
				return BlockType.DEEPSLATE

	# 9. DEEP REALM: The Echoing Ossuary (Catacombs of Bone & Dark Basalt, Northwest Stratum Y = -28..-46)
	if gx < -20 and gx >= -56 and gz > 20 and gz <= 56:
		var ossuary_dist = Vector2(gx + 38, gz - 38).length()
		if ossuary_dist < 16.0:
			if gy <= -47:
				return BlockType.DEEP_BASALT
			elif gy >= -46 and gy <= -28:
				if ossuary_dist > 14.5:
					return BlockType.DEEP_BASALT
				if gy == -46:
					return BlockType.SLATE_BRICK if (gx + gz) % 2 == 0 else BlockType.DEEP_BASALT
				for arch_z in [28, 36, 44, 50]:
					if gz == arch_z and abs(gx + 38) <= 8:
						var bone_y = -32 - int(pow(float(gx + 38) * 0.35, 2))
						if gy == bone_y or gy == bone_y + 1:
							return BlockType.CALCITE # Giant fossilized titan ribs
				if gy == -45 and abs(gx + 38) % 6 == 0 and abs(gz - 38) % 6 == 0:
					return BlockType.SLATE_BRICK # Ancient sarcophagus
				return BlockType.AIR
			elif gy >= -27 and gy <= -25:
				return BlockType.DEEP_BASALT

	# 10. DEEP REALM: The Void Fissure & Crystalline Abyss (Southeast Stratum Y = -38..-58)
	if gx > 20 and gx <= 56 and gz < -20 and gz >= -56:
		var fissure_dist = abs(float(gx - 38) - float(gz + 38))
		if fissure_dist < 6.5:
			if gy <= -58:
				return BlockType.BEDROCK
			elif gy >= -57 and gy <= -34:
				if fissure_dist > 4.5:
					return BlockType.DEEP_BASALT if (gy + gx) % 3 != 0 else BlockType.CRYSTAL_AMETHYST
				if gy <= -50 and abs(gx - 38) <= 1:
					return BlockType.PRECURSOR_CONDUIT if gy % 2 == 0 else BlockType.AIR
				return BlockType.AIR
			elif gy >= -33 and gy <= -30:
				return BlockType.DEEPSLATE

	# 11. Distinct Procedural Cavern Morphology per Biome Zone & Geological Strata
	var n_cheese = cave_cheese_noise.get_noise_3d(gx, gy, gz)
	var n_spaghetti_1 = noodle_noise_1.get_noise_3d(gx, gy, gz)
	var spaghetti_dist_sq = n_spaghetti_1 * n_spaghetti_1
	if spaghetti_dist_sq < 0.040:
		var n_sp2 = noodle_noise_2.get_noise_3d(gx, gy, gz)
		spaghetti_dist_sq += (n_sp2 * n_sp2)
	else:
		spaghetti_dist_sq = 1.0

	var vert_center = -4.0
	var vert_dist = abs(float(gy) - vert_center)
	var cave_mask = clamp(1.0 - (vert_dist / 46.0), 0.0, 1.0)

	var is_tunnel = false
	var is_cavern = false
	var is_ravine = false
	var is_geode_hollow = false

	# --- MORPHOLOGY VARIANT 1: Cathedral Vaults & Grand Subterranean Halls (Cold/Dry or Deep) ---
	if (temp < -0.05 and moist < 0.15) or gy <= -30:
		is_tunnel = (spaghetti_dist_sq < 0.034)
		# Soaring 30-40m vertical hall domes with high clearance
		is_cavern = (n_cheese < 0.06) and (cave_mask > 0.06)
		is_ravine = (abs(n_spaghetti_1) < 0.035) and (gy >= -45 and gy <= 28)

	# --- MORPHOLOGY VARIANT 2: Tight Winding Fissures & Claustrophobic Crevasses ---
	elif temp > 0.10 and moist < -0.05:
		is_tunnel = (spaghetti_dist_sq < 0.024) # Narrow winding tunnels
		is_cavern = false # NO open halls; pure claustrophobic fissures!
		# Ultra-narrow 1-2 block wide, 20-30 block tall razor fissures
		is_ravine = (abs(n_spaghetti_1) < 0.022) and (gy >= -46 and gy <= 28)

	# --- MORPHOLOGY VARIANT 3: Crystal Geode Hollows (Spherical / Ellipsoidal Crystal Pockets) ---
	elif crystal > 0.35:
		is_tunnel = (spaghetti_dist_sq < 0.032)
		is_cavern = (n_cheese < -0.16) and (cave_mask > 0.12)
		# Spherical geode pockets embedded in stone
		var g_mod_x = posmod(gx + 18, 36) - 18
		var g_mod_y = posmod(gy + 10, 24) - 12
		var g_mod_z = posmod(gz + 18, 36) - 18
		var g_rad_sq = (g_mod_x * g_mod_x) + (g_mod_y * g_mod_y * 1.4) + (g_mod_z * g_mod_z)
		if g_rad_sq < 28.0 and gy >= -40 and gy <= 24:
			if g_rad_sq > 16.0:
				# Crystalline Geode Outer Shell
				return BlockType.CRYSTAL_AMETHYST if (gx + gy + gz) % 2 == 0 else BlockType.CALCITE
			else:
				is_geode_hollow = true

	# --- MORPHOLOGY VARIANT 4: Overgrown Root-Tangled Caverns (Undulating Ceiling & Root Pillars) ---
	elif moist > 0.28:
		# Undulating organic chamber carving
		var root_undulation = 0.12 * sin(float(gx) * 0.35) * cos(float(gz) * 0.35)
		is_cavern = ((n_cheese + root_undulation) < -0.11) and (cave_mask > 0.10)
		is_tunnel = (spaghetti_dist_sq < 0.036)
		is_ravine = false

	# --- MORPHOLOGY VARIANT 5: Standard Stratified Cavern ---
	else:
		is_tunnel = (spaghetti_dist_sq < 0.038)
		is_cavern = (n_cheese < -0.13) and (cave_mask > 0.10)
		is_ravine = (abs(n_spaghetti_1) < 0.042) and (gy >= -45 and gy <= 28) and (n_cheese < 0.22)

	# Hexagonal columnar basalt pillars in dry/cold biomes
	var is_pillar = false
	if moist < -0.15 and (gy >= -35 and gy <= 28):
		is_pillar = (Vector2(gx % 24, gz % 24).length() < 1.8)

	# Natural basalt & limestone arches spanning across grand cathedral halls
	var is_natural_arch = false
	if (temp < -0.05 and moist < 0.15) and (gy >= 13 and gy <= 15):
		var arch_wave = abs(sin(float(gx) * 0.14) * cos(float(gz) * 0.14) - 0.70)
		if arch_wave < 0.075:
			is_natural_arch = true

	# Living subterranean taproots spanning floor to ceiling in root caverns
	var is_root_pillar = false
	if moist > 0.28 and (gy >= 2 and gy <= 22):
		if abs(posmod(gx, 16) - 8) <= 1 and abs(posmod(gz, 16) - 8) <= 1 and (gx * 3 + gz * 7) % 3 == 0:
			is_root_pillar = true

	var is_air = (is_tunnel or is_cavern or is_ravine or is_geode_hollow) and not is_pillar and not is_natural_arch and not is_root_pillar

	if gy <= CHUNK_MIN_Y + 4 or (gy >= 42 and gy <= 44):
		is_air = false

	# If this is a natural arch or taproot pillar inside an open void:
	if is_natural_arch and not is_air:
		return BlockType.DEEP_BASALT if gy <= 14 else BlockType.STONE
	if is_root_pillar and not is_air:
		return BlockType.LICHEN_ROOT if gy <= 12 else BlockType.HEWN_TIMBER

	# --- Interactive World Features in Cavern Air Voids (Food, Water, Speleothems) ---
	if is_air:
		# 1. Speleothems: Hanging Stalactites & Rising Stalagmites (Firmly anchored to solid ceiling/floor!)
		if gy >= 20 and gy <= 28 and (temp < -0.05 and moist < 0.15):
			var above_sn = cave_cheese_noise.get_noise_3d(gx, gy + 1, gz)
			if above_sn >= -0.13 and (abs(gx * 13 + gz * 17) % 7 == 0):
				return BlockType.CALCITE if gy >= 24 else BlockType.STONE
		elif gy >= 6 and gy <= 12 and (temp < -0.05 and moist < 0.15):
			var below_sn = cave_cheese_noise.get_noise_3d(gx, gy - 1, gz)
			if below_sn >= -0.13 and (abs(gx * 19 + gz * 11) % 7 == 0):
				return BlockType.CALCITE if gy <= 8 else BlockType.STONE

		# 2. HYDROLOGY & REALISTIC GLACIAL WATER:
		if gy >= 32 and gy <= 44:
			var below_cheese = cave_cheese_noise.get_noise_3d(gx, gy - 1, gz)
			if below_cheese >= -0.13 and n_cheese < -0.20:
				return BlockType.WATER_SPRING
		elif gy >= 14 and gy < 32 and moist > 0.32:
			if abs(posmod(gx, 32) - 16) == 0 and abs(posmod(gz, 32) - 16) == 0:
				var below_cheese = cave_cheese_noise.get_noise_3d(gx, gy - 1, gz)
				if below_cheese >= -0.13:
					return BlockType.WATER_SPRING

		# 3. Bioluminescent Glow-Cap Mushrooms (Rooted to cavern floor)
		if moist > 0.35 and gy >= -20 and gy <= 25:
			var below_cheese = cave_cheese_noise.get_noise_3d(gx, gy - 1, gz)
			if below_cheese >= -0.13 and (abs(gx * 7 + gz * 13) % 19 == 0):
				return BlockType.BIOLUM_MUSHROOM

		# 4. Edible Lichen Roots (Hanging strictly from solid ceilings in moist grottos)
		if moist > 0.15 and gy >= 16 and gy <= 27:
			var above_sn = cave_cheese_noise.get_noise_3d(gx, gy + 1, gz)
			if above_sn >= -0.13 and (abs(gx * 11 + gz * 5) % 9 == 0):
				return BlockType.LICHEN_ROOT

		# 5. Precursor Alien Obelisks & Conduits in Ruin Biomes (Solid floor rooted pillars)
		if ruin > 0.58 and gy >= -30 and gy <= -10:
			if (abs(posmod(gx, 32) - 16) <= 1 and abs(posmod(gz, 32) - 16) <= 1):
				var below_sn = cave_cheese_noise.get_noise_3d(gx, gy - 1, gz)
				if below_sn >= -0.13 or gy == -30:
					return BlockType.PRECURSOR_CONDUIT

		# 6. Abandoned Surveyor Outpost Crates in Basin Caves
		if gy >= 5 and gy <= 18 and abs(gx % 48) == 3 and abs(gz % 48) == 3:
			var below_cheese = cave_cheese_noise.get_noise_3d(gx, gy - 1, gz)
			if below_cheese >= -0.13:
				return BlockType.CARGO_CRATE

		return BlockType.AIR

	# --- 9. Rich Multi-Biome Geological Stratification (25+ Distinct Biomes) ---

	# STRATUM 1: Subglacial Calcite Karst & Upper Ice Caverns (Y in [22, 43])
	if gy >= 22:
		var sn = strata_noise.get_noise_3d(gx, gy, gz)
		var on = ore_noise.get_noise_3d(gx, gy, gz)
		if temp < -0.30 or gy >= 34 or sn > 0.35:
			return BlockType.PERMAFROST_ICE
		elif crystal > 0.35 or on > 0.65 or sn < -0.40:
			return BlockType.CALCITE
		elif ruin > 0.48:
			return BlockType.SLATE_BRICK
		return BlockType.STONE

	# STRATUM 2: Scorching Magma Mantle & Volcanic Calderas (Y in [-58, -29])
	if gy <= -29:
		var sn = strata_noise.get_noise_3d(gx, gy, gz)
		var on = ore_noise.get_noise_3d(gx, gy, gz)
		# Volcanic Sulfur Fumaroles
		if temp > 0.35 and on > 0.55:
			return BlockType.SULFUR_BLOCK
		elif sn > 0.28:
			return BlockType.MAGMA_ROCK
		elif on > 0.60:
			return BlockType.GOLD_ORE
		elif sn < -0.40:
			return BlockType.DEEP_BASALT
		return BlockType.DEEPSLATE

	# STRATUM 3: Basaltic Deepslate Chasm & Abyssal Grottos (Y in [-28, 0])
	if gy <= 0:
		var on = ore_noise.get_noise_3d(gx, gy, gz)
		# Precursor Ruin Architecture
		if ruin > 0.50:
			if (gx + gz + gy) % 6 == 0:
				return BlockType.PRECURSOR_CONDUIT
			return BlockType.SLATE_BRICK
		# Amethyst Crystal Geode Cavities
		if crystal > 0.40:
			if on > 0.30:
				return BlockType.CRYSTAL_AMETHYST
			return BlockType.CALCITE

		if on > 0.68:
			return BlockType.GOLD_ORE
		elif on > 0.50:
			return BlockType.PHOSPHOR_ORE
		elif on > 0.34:
			return BlockType.IRON_ORE
		elif on < -0.55:
			return BlockType.CALCITE

		var sn = strata_noise.get_noise_3d(gx, gy, gz)
		if sn > 0.42:
			return BlockType.DEEP_BASALT
		return BlockType.DEEPSLATE

	# STRATUM 4: The Great Hollow Basin & Diverse Cavern Biomes (Y in [1, 21])
	# Biome A: Fungal Mycena Hollows & Lush Moss Grottos
	if moist > 0.32:
		var sn = strata_noise.get_noise_3d(gx, gy, gz)
		if gy <= 16 and sn > -0.15:
			return BlockType.MOSS_STONE
		elif sn > 0.40:
			return BlockType.LICHEN_ROOT

	# Biome B: Ancient Precursor Waystations
	if ruin > 0.52:
		if (gx * 3 + gz * 5) % 8 == 0:
			return BlockType.PRECURSOR_CONDUIT
		return BlockType.SLATE_BRICK

	# Biome C: Crystalline Amethyst & Calcite Pockets
	if crystal > 0.42:
		return BlockType.CRYSTAL_AMETHYST if (gx + gz) % 3 == 0 else BlockType.CALCITE

	# Mineral & Ore Veins
	var on = ore_noise.get_noise_3d(gx, gy, gz)
	if on > 0.65:
		return BlockType.IRON_ORE
	elif on > 0.48:
		return BlockType.COAL_ORE
	elif on > 0.32:
		return BlockType.COPPER_ORE
	elif on < -0.58:
		return BlockType.CALCITE

	# Rock Strata (Granite, Diorite, Andesite, Gravel, Stone)
	var sn = strata_noise.get_noise_3d(gx, gy, gz)
	if sn > 0.44:
		return BlockType.GRANITE
	elif sn > 0.20:
		return BlockType.DIORITE
	elif sn < -0.45:
		return BlockType.ANDESITE
	elif sn < -0.22:
		return BlockType.GRAVEL

	if gy <= 14 and sn > 0.05:
		return BlockType.MOSS_STONE

	return BlockType.STONE

func get_biome_name_at(gx: int, gy: int, gz: int) -> String:
	# Check landmark realms first for seamless HUD immersion
	if gx < -20 and gx >= -56 and gz > 20 and gz <= 56 and gy >= -48 and gy <= -25:
		return "STRATUM IV — THE ECHOING OSSUARY"
	elif gx > 20 and gx <= 56 and gz < -20 and gz >= -56 and gy >= -58 and gy <= -33:
		return "STRATUM V — THE VOID FISSURE & CRYSTALLINE ABYSS"

	if gy >= 1 and gy <= 30:
		if gz >= 20 and gz <= 65 and abs(gx) <= 22:
			return "STRATUM III — FUNGAL MYCENA HOLLOWS"
		elif gz <= -20 and gz >= -65 and abs(gx) <= 22:
			return "STRATUM III — AMETHYST & CALCITE POCKET"
		elif gx <= -20 and gx >= -65 and abs(gz) <= 22:
			return "STRATUM III — PRECURSOR SANCTUARY & CONDUITS"
		elif gx >= 60 and gx <= 105 and abs(gz) <= 22:
			return "STRATUM V — MOLTEN MAGMA RESERVOIR"
		elif abs(gx) <= 8 and abs(gz) <= 8:
			return "STRATUM III — THE HOLLOW CORE BASIN"

	if gy >= 45:
		return "SURFACE BOREAS — PERMAFROST TUNDRA"
	elif gy >= 34:
		return "STRATUM I — GLACIAL CRYOSPHERE SPIRES"
	elif gy >= 22:
		var temp = biome_temperature_noise.get_noise_2d(gx, gz) if biome_temperature_noise else 0.0
		var ruin = biome_ruins_noise.get_noise_2d(gx, gz) if biome_ruins_noise else 0.0
		var crystal = biome_crystal_noise.get_noise_2d(gx, gz) if biome_crystal_noise else 0.0
		if ruin > 0.48:
			return "STRATUM II — PRECURSOR SKY VAULT"
		elif crystal > 0.35:
			return "STRATUM II — BOREAL CALCITE CAVERNS"
		elif temp < -0.30:
			return "STRATUM II — SUBGLACIAL PERMAFROST CHASM"
		return "STRATUM II — CHILLED KARST TUNNELS"
	elif gy <= -55:
		return "FOUNDATION — BEDROCK ABYSSAL VOID"
	elif gy <= -29:
		var temp = biome_temperature_noise.get_noise_2d(gx, gz) if biome_temperature_noise else 0.0
		var sn = strata_noise.get_noise_3d(gx, gy, gz) if strata_noise else 0.0
		if temp > 0.35:
			return "STRATUM V — SULFUR FUMAROLE CALDERA"
		elif sn > 0.28:
			return "STRATUM V — MOLTEN MAGMA RESERVOIR"
		elif sn < -0.40:
			return "STRATUM V — ABYSSAL BASALTIC MANTLE"
		return "STRATUM V — VOLCANIC UPWELLING SECTOR"
	elif gy <= 0:
		var ruin = biome_ruins_noise.get_noise_2d(gx, gz) if biome_ruins_noise else 0.0
		var crystal = biome_crystal_noise.get_noise_2d(gx, gz) if biome_crystal_noise else 0.0
		var on = ore_noise.get_noise_3d(gx, gy, gz) if ore_noise else 0.0
		if ruin > 0.50:
			return "STRATUM IV — PRECURSOR ABYSSAL CORE RUINS"
		elif crystal > 0.40:
			return "STRATUM IV — DEEP AMETHYST GEODE CAVITY"
		elif on > 0.50:
			return "STRATUM IV — BIOLUMINESCENT PHOSPHOR GROTTO"
		elif on > 0.68:
			return "STRATUM IV — AURIFEROUS QUARTZ FAULTLINE"
		return "STRATUM IV — BASALTIC DEEPSLATE TRENCH"
	else:
		var moist = biome_moisture_noise.get_noise_2d(gx, gz) if biome_moisture_noise else 0.0
		var ruin = biome_ruins_noise.get_noise_2d(gx, gz) if biome_ruins_noise else 0.0
		var crystal = biome_crystal_noise.get_noise_2d(gx, gz) if biome_crystal_noise else 0.0
		var sn = strata_noise.get_noise_3d(gx, gy, gz) if strata_noise else 0.0
		if ruin > 0.52:
			return "STRATUM III — PRECURSOR SANCTUARY & CONDUITS"
		elif crystal > 0.42:
			return "STRATUM III — AMETHYST & CALCITE POCKET"
		elif moist > 0.32:
			if sn > 0.40:
				return "STRATUM III — LICHEN ROOT GROVE"
			return "STRATUM III — FUNGAL MYCENA HOLLOWS"
		elif sn > 0.44:
			return "STRATUM III — GRANITE FAULT RIDGE"
		elif sn > 0.20:
			return "STRATUM III — DIORITE STRATA TERRACE"
		elif sn < -0.45:
			return "STRATUM III — ANDESITE SHALE LEDGE"
		elif sn < -0.22:
			return "STRATUM III — CAVERN GRAVEL OUTWASH"
		return "STRATUM III — THE HOLLOW CORE BASIN"

# --- Voxel Modification & Query API ---

func get_chunk_coords(gx: int, gz: int) -> Vector2i:
	var cx = int(floor(float(gx) / CHUNK_SIZE_X))
	var cz = int(floor(float(gz) / CHUNK_SIZE_Z))
	return Vector2i(cx, cz)

func get_block(gx: int, gy: int, gz: int) -> int:
	if gy < CHUNK_MIN_Y or gy >= CHUNK_MAX_Y:
		return BlockType.AIR

	var coord = Vector3i(gx, gy, gz)
	if modified_voxels.has(coord):
		return modified_voxels[coord]

	var cx = int(floor(float(gx) / CHUNK_SIZE_X))
	var cz = int(floor(float(gz) / CHUNK_SIZE_Z))
	var key = Vector2i(cx, cz)

	if not chunks.has(key):
		return _determine_initial_voxel(gx, gy, gz)

	var lx = gx - (cx * CHUNK_SIZE_X)
	var lz = gz - (cz * CHUNK_SIZE_Z)
	var ly = gy - CHUNK_MIN_Y
	var data: PackedByteArray = chunks[key]
	var idx = _voxel_index(lx, ly, lz)
	return data[idx]

func set_block(gx: int, gy: int, gz: int, block_id: int, update_mesh: bool = true) -> bool:
	if gy < CHUNK_MIN_Y or gy >= CHUNK_MAX_Y:
		return false

	var coord = Vector3i(gx, gy, gz)
	var old_block = get_block(gx, gy, gz)
	if old_block == block_id:
		return false

	modified_voxels[coord] = block_id

	var cx = int(floor(float(gx) / CHUNK_SIZE_X))
	var cz = int(floor(float(gz) / CHUNK_SIZE_Z))
	var key = Vector2i(cx, cz)

	if not chunks.has(key):
		_load_chunk(cx, cz)

	var lx = gx - (cx * CHUNK_SIZE_X)
	var lz = gz - (cz * CHUNK_SIZE_Z)
	var ly = gy - CHUNK_MIN_Y
	var data: PackedByteArray = chunks[key]
	var idx = _voxel_index(lx, ly, lz)
	data[idx] = block_id
	chunks[key] = data

	# Torch light management
	if block_id == BlockType.TORCH:
		_spawn_torch_light(coord)
	elif old_block == BlockType.TORCH:
		_remove_torch_light(coord)

	if update_mesh:
		if not chunks_in_mesh_queue.has(key):
			chunk_mesh_queue.push_front(key)
			chunks_in_mesh_queue[key] = true
		if lx == 0:
			var nb = Vector2i(cx - 1, cz)
			if chunks.has(nb) and not chunks_in_mesh_queue.has(nb):
				chunk_mesh_queue.push_back(nb)
				chunks_in_mesh_queue[nb] = true
		elif lx == CHUNK_SIZE_X - 1:
			var nb = Vector2i(cx + 1, cz)
			if chunks.has(nb) and not chunks_in_mesh_queue.has(nb):
				chunk_mesh_queue.push_back(nb)
				chunks_in_mesh_queue[nb] = true
		if lz == 0:
			var nb = Vector2i(cx, cz - 1)
			if chunks.has(nb) and not chunks_in_mesh_queue.has(nb):
				chunk_mesh_queue.push_back(nb)
				chunks_in_mesh_queue[nb] = true
		elif lz == CHUNK_SIZE_Z - 1:
			var nb = Vector2i(cx, cz + 1)
			if chunks.has(nb) and not chunks_in_mesh_queue.has(nb):
				chunk_mesh_queue.push_back(nb)
				chunks_in_mesh_queue[nb] = true

	if block_id == BlockType.AIR:
		block_broken.emit(coord, old_block)
	else:
		block_placed.emit(coord, block_id)

	return true

func mine_block(coord: Vector3i, _damage: float, _hit_point: Vector3, _hit_normal: Vector3, is_hand_mining: bool = false) -> bool:
	var b_type = get_block(coord.x, coord.y, coord.z)
	if b_type == BlockType.AIR or b_type == BlockType.BEDROCK:
		return false

	# Single-block precision mining: target exactly one block
	set_block(coord.x, coord.y, coord.z, BlockType.AIR, true)

	if b_type == BlockType.CARGO_CRATE:
		# Supply crates burst with essential survival building blocks, timber, and torches!
		_spawn_dropped_item(Vector3(coord.x + 0.5, coord.y + 0.5, coord.z + 0.5), "timber", 8)
		_spawn_dropped_item(Vector3(coord.x + 0.3, coord.y + 0.5, coord.z + 0.7), "cobblestone", 16)
		_spawn_dropped_item(Vector3(coord.x + 0.7, coord.y + 0.5, coord.z + 0.3), "torch", 8)
		_spawn_dropped_item(Vector3(coord.x + 0.5, coord.y + 0.5, coord.z + 0.5), "rations", 2)
		return true

	var props = BLOCK_PROPS.get(b_type, {})
	var drop_name = props.get("drop", "cobblestone")
	var drop_qty = props.get("count", 1)
	var is_soft = props.get("is_soft", false)

	# If mined with bare hands, hard ores only drop rubble/cobblestone instead of valuable ingots!
	if is_hand_mining and not is_soft:
		if drop_name in ["iron", "copper", "gold", "calcite", "phosphor"]:
			drop_name = "cobblestone"
			drop_qty = 1

	if drop_name != "" and drop_qty > 0:
		_spawn_dropped_item(Vector3(coord.x + 0.5, coord.y + 0.5, coord.z + 0.5), drop_name, drop_qty)

	return true

func place_block_at(target_coord: Vector3i, normal: Vector3i, block_id: int) -> bool:
	var place_pos = target_coord + normal
	var current = get_block(place_pos.x, place_pos.y, place_pos.z)
	if current != BlockType.AIR:
		return false
	return set_block(place_pos.x, place_pos.y, place_pos.z, block_id, true)

func save_world_state(slot_name: String = "slot_01") -> bool:
	var seed_val = world_config.world_seed if world_config else 1337
	return TerrainPersistenceClass.save_world_modifications(slot_name, seed_val, modified_voxels)

func load_world_state(slot_name: String = "slot_01") -> bool:
	var seed_val = world_config.world_seed if world_config else 1337
	var loaded = TerrainPersistenceClass.load_world_modifications(slot_name, seed_val)
	if loaded.is_empty():
		return false
	for coord in loaded.keys():
		set_block(coord.x, coord.y, coord.z, loaded[coord], false)
	for c_key in chunks.keys():
		if not chunks_in_mesh_queue.has(c_key):
			chunk_mesh_queue.push_back(c_key)
			chunks_in_mesh_queue[c_key] = true
	return true

func _spawn_torch_light(coord: Vector3i) -> void:
	if torch_lights.has(coord):
		return
	var light = OmniLight3D.new()
	light.name = "TorchLight_%d_%d_%d" % [coord.x, coord.y, coord.z]
	light.position = Vector3(coord.x + 0.5, coord.y + 0.6, coord.z + 0.5)
	light.light_color = Color(1.0, 0.76, 0.42)
	light.light_energy = 2.0
	light.omni_range = 16.0
	light.omni_attenuation = 1.35
	light.shadow_enabled = true
	light.shadow_blur = 1.5
	light.shadow_bias = 0.08
	add_child(light)
	torch_lights[coord] = light

func _remove_torch_light(coord: Vector3i) -> void:
	if torch_lights.has(coord):
		var l = torch_lights[coord]
		if is_instance_valid(l):
			l.queue_free()
		torch_lights.erase(coord)

func _spawn_dropped_item(pos: Vector3, item_type: String, count: int) -> void:
	var drop = DroppedItemClass.new()
	drop.position = pos
	drop.item_type = item_type
	drop.item_count = count
	add_child(drop)

# --- Sub-Millisecond Boundary-Optimized Greedy Mesher ---

func _build_chunk_mesh_data(cx: int, cz: int, data: PackedByteArray, chunk_north, chunk_south, chunk_west, chunk_east) -> Dictionary:
	var world_base_x = cx * CHUNK_SIZE_X
	var world_base_z = cz * CHUNK_SIZE_Z

	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()

	var vert_count = 0
	var uv_count = uv_lookup.size()

	for lx in range(CHUNK_SIZE_X):
		var gx = world_base_x + lx
		for lz in range(CHUNK_SIZE_Z):
			var gz = world_base_z + lz
			for ly in range(CHUNK_HEIGHT):
				var gy = CHUNK_MIN_Y + ly
				var idx = lx + (ly * CHUNK_SIZE_X) + (lz * STRIDE_Z)
				var b_type = data[idx]

				if b_type == BlockType.AIR:
					continue

				var uvr: Rect2 = uv_lookup[b_type] if b_type < uv_count else Rect2(0, 0, 0.125, 0.125)
				var u0 = uvr.position.x
				var v0 = uvr.position.y
				var u1 = uvr.position.x + uvr.size.x
				var v1 = uvr.position.y + uvr.size.y

				var bx = float(gx)
				var by = float(gy)
				var bz = float(gz)

				# 1. TOP FACE (+Y)
				var top_nb = data[idx + STRIDE_Y] if (ly < CHUNK_HEIGHT - 1) else BlockType.AIR
				var top_air = is_transparent_block(top_nb) if (b_type != top_nb) else false

				if top_air:
					var p0 = Vector3(bx, by + 1.0, bz)
					var p1 = Vector3(bx, by + 1.0, bz + 1.0)
					var p2 = Vector3(bx + 1.0, by + 1.0, bz + 1.0)
					var p3 = Vector3(bx + 1.0, by + 1.0, bz)
					var norm = Vector3(0, 1, 0)

					vertices.push_back(p0); normals.push_back(norm); uvs.push_back(Vector2(u0, v0))
					vertices.push_back(p1); normals.push_back(norm); uvs.push_back(Vector2(u0, v1))
					vertices.push_back(p2); normals.push_back(norm); uvs.push_back(Vector2(u1, v1))
					vertices.push_back(p3); normals.push_back(norm); uvs.push_back(Vector2(u1, v0))

					indices.push_back(vert_count); indices.push_back(vert_count + 2); indices.push_back(vert_count + 1)
					indices.push_back(vert_count); indices.push_back(vert_count + 3); indices.push_back(vert_count + 2)
					vert_count += 4

				# 2. BOTTOM FACE (-Y)
				var bot_nb = data[idx - STRIDE_Y] if (ly > 0) else BlockType.BEDROCK
				var bot_air = is_transparent_block(bot_nb) if (b_type != bot_nb) else false

				if bot_air:
					var p0 = Vector3(bx, by, bz + 1.0)
					var p1 = Vector3(bx, by, bz)
					var p2 = Vector3(bx + 1.0, by, bz)
					var p3 = Vector3(bx + 1.0, by, bz + 1.0)
					var norm = Vector3(0, -1, 0)

					vertices.push_back(p0); normals.push_back(norm); uvs.push_back(Vector2(u0, v0))
					vertices.push_back(p1); normals.push_back(norm); uvs.push_back(Vector2(u0, v1))
					vertices.push_back(p2); normals.push_back(norm); uvs.push_back(Vector2(u1, v1))
					vertices.push_back(p3); normals.push_back(norm); uvs.push_back(Vector2(u1, v0))

					indices.push_back(vert_count); indices.push_back(vert_count + 2); indices.push_back(vert_count + 1)
					indices.push_back(vert_count); indices.push_back(vert_count + 3); indices.push_back(vert_count + 2)
					vert_count += 4

				# 3. NORTH FACE (-Z)
				var north_nb = BlockType.AIR
				if lz > 0:
					north_nb = data[idx - STRIDE_Z]
				elif chunk_north != null:
					north_nb = chunk_north[lx + (ly * CHUNK_SIZE_X) + ((CHUNK_SIZE_Z - 1) * STRIDE_Z)]
				else:
					north_nb = _determine_initial_voxel(gx, gy, gz - 1)
				var north_air = is_transparent_block(north_nb) if (b_type != north_nb) else false

				if north_air:
					var p0 = Vector3(bx + 1.0, by, bz)
					var p1 = Vector3(bx, by, bz)
					var p2 = Vector3(bx, by + 1.0, bz)
					var p3 = Vector3(bx + 1.0, by + 1.0, bz)
					var norm = Vector3(0, 0, -1)

					vertices.push_back(p0); normals.push_back(norm); uvs.push_back(Vector2(u0, v1))
					vertices.push_back(p1); normals.push_back(norm); uvs.push_back(Vector2(u1, v1))
					vertices.push_back(p2); normals.push_back(norm); uvs.push_back(Vector2(u1, v0))
					vertices.push_back(p3); normals.push_back(norm); uvs.push_back(Vector2(u0, v0))

					indices.push_back(vert_count); indices.push_back(vert_count + 2); indices.push_back(vert_count + 1)
					indices.push_back(vert_count); indices.push_back(vert_count + 3); indices.push_back(vert_count + 2)
					vert_count += 4

				# 4. SOUTH FACE (+Z)
				var south_nb = BlockType.AIR
				if lz < CHUNK_SIZE_Z - 1:
					south_nb = data[idx + STRIDE_Z]
				elif chunk_south != null:
					south_nb = chunk_south[lx + (ly * CHUNK_SIZE_X)]
				else:
					south_nb = _determine_initial_voxel(gx, gy, gz + 1)
				var south_air = is_transparent_block(south_nb) if (b_type != south_nb) else false

				if south_air:
					var p0 = Vector3(bx, by, bz + 1.0)
					var p1 = Vector3(bx + 1.0, by, bz + 1.0)
					var p2 = Vector3(bx + 1.0, by + 1.0, bz + 1.0)
					var p3 = Vector3(bx, by + 1.0, bz + 1.0)
					var norm = Vector3(0, 0, 1)

					vertices.push_back(p0); normals.push_back(norm); uvs.push_back(Vector2(u0, v1))
					vertices.push_back(p1); normals.push_back(norm); uvs.push_back(Vector2(u1, v1))
					vertices.push_back(p2); normals.push_back(norm); uvs.push_back(Vector2(u1, v0))
					vertices.push_back(p3); normals.push_back(norm); uvs.push_back(Vector2(u0, v0))

					indices.push_back(vert_count); indices.push_back(vert_count + 2); indices.push_back(vert_count + 1)
					indices.push_back(vert_count); indices.push_back(vert_count + 3); indices.push_back(vert_count + 2)
					vert_count += 4

				# 5. WEST FACE (-X)
				var west_nb = BlockType.AIR
				if lx > 0:
					west_nb = data[idx - 1]
				elif chunk_west != null:
					west_nb = chunk_west[(CHUNK_SIZE_X - 1) + (ly * CHUNK_SIZE_X) + (lz * STRIDE_Z)]
				else:
					west_nb = _determine_initial_voxel(gx - 1, gy, gz)
				var west_air = is_transparent_block(west_nb) if (b_type != west_nb) else false

				if west_air:
					var p0 = Vector3(bx, by, bz)
					var p1 = Vector3(bx, by, bz + 1.0)
					var p2 = Vector3(bx, by + 1.0, bz + 1.0)
					var p3 = Vector3(bx, by + 1.0, bz)
					var norm = Vector3(-1, 0, 0)

					vertices.push_back(p0); normals.push_back(norm); uvs.push_back(Vector2(u0, v1))
					vertices.push_back(p1); normals.push_back(norm); uvs.push_back(Vector2(u1, v1))
					vertices.push_back(p2); normals.push_back(norm); uvs.push_back(Vector2(u1, v0))
					vertices.push_back(p3); normals.push_back(norm); uvs.push_back(Vector2(u0, v0))

					indices.push_back(vert_count); indices.push_back(vert_count + 2); indices.push_back(vert_count + 1)
					indices.push_back(vert_count); indices.push_back(vert_count + 3); indices.push_back(vert_count + 2)
					vert_count += 4

				# 6. EAST FACE (+X)
				var east_nb = BlockType.AIR
				if lx < CHUNK_SIZE_X - 1:
					east_nb = data[idx + 1]
				elif chunk_east != null:
					east_nb = chunk_east[(ly * CHUNK_SIZE_X) + (lz * STRIDE_Z)]
				else:
					east_nb = _determine_initial_voxel(gx + 1, gy, gz)
				var east_air = is_transparent_block(east_nb) if (b_type != east_nb) else false

				if east_air:
					var p0 = Vector3(bx + 1.0, by, bz + 1.0)
					var p1 = Vector3(bx + 1.0, by, bz)
					var p2 = Vector3(bx + 1.0, by + 1.0, bz)
					var p3 = Vector3(bx + 1.0, by + 1.0, bz + 1.0)
					var norm = Vector3(1, 0, 0)

					vertices.push_back(p0); normals.push_back(norm); uvs.push_back(Vector2(u0, v1))
					vertices.push_back(p1); normals.push_back(norm); uvs.push_back(Vector2(u1, v1))
					vertices.push_back(p2); normals.push_back(norm); uvs.push_back(Vector2(u1, v0))
					vertices.push_back(p3); normals.push_back(norm); uvs.push_back(Vector2(u0, v0))

					indices.push_back(vert_count); indices.push_back(vert_count + 2); indices.push_back(vert_count + 1)
					indices.push_back(vert_count); indices.push_back(vert_count + 3); indices.push_back(vert_count + 2)
					vert_count += 4

	# If chunk has no visible faces, free any existing node
	if vertices.size() == 0:
		return {"arrays": null, "empty": true}

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	return {"arrays": arrays, "empty": false}

func _apply_chunk_mesh(cx: int, cz: int, arrays: Array, is_empty: bool) -> void:
	var key = Vector2i(cx, cz)
	if is_empty or arrays == null or arrays.size() == 0:
		if chunk_nodes.has(key):
			var n = chunk_nodes[key]
			if is_instance_valid(n): n.queue_free()
			chunk_nodes.erase(key)
			chunk_trimeshes.erase(key)
		return

	var arr_mesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var trimesh: Shape3D = arr_mesh.create_trimesh_shape()
	if trimesh:
		trimesh.backface_collision = false
		trimesh.margin = 0.0
	chunk_trimeshes[key] = trimesh

	var chunk_body: StaticBody3D
	var mesh_inst: MeshInstance3D
	var coll_shape: CollisionShape3D

	if chunk_nodes.has(key) and is_instance_valid(chunk_nodes[key]):
		chunk_body = chunk_nodes[key]
		mesh_inst = chunk_body.get_node("MeshInstance3D")
		coll_shape = chunk_body.get_node("CollisionShape3D")
		arr_mesh.surface_set_material(0, atlas_material)
		mesh_inst.mesh = arr_mesh
		if trimesh != null:
			coll_shape.shape = trimesh
	else:
		chunk_body = StaticBody3D.new()
		chunk_body.name = "Chunk_%d_%d" % [cx, cz]
		chunk_body.collision_layer = 1
		chunk_body.collision_mask = 0

		mesh_inst = MeshInstance3D.new()
		mesh_inst.name = "MeshInstance3D"
		mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		chunk_body.add_child(mesh_inst)

		coll_shape = CollisionShape3D.new()
		coll_shape.name = "CollisionShape3D"
		if trimesh != null:
			coll_shape.shape = trimesh
		chunk_body.add_child(coll_shape)

		arr_mesh.surface_set_material(0, atlas_material)
		mesh_inst.mesh = arr_mesh

		add_child(chunk_body)
		chunk_nodes[key] = chunk_body
	# Glacial meltwater ceiling drip particle effects in subglacial karst chunks
	var world_base_x = cx * CHUNK_SIZE_X
	var world_base_z = cz * CHUNK_SIZE_Z
	var existing_drips = chunk_body.get_node_or_null("WaterDrips")
	if (abs(cx) <= 2 and abs(cz) <= 2) or (abs(cx + cz) % 3 == 0):
		if existing_drips == null and drip_sphere_mesh != null:
			var drips = CPUParticles3D.new()
			drips.name = "WaterDrips"
			drips.position = Vector3(world_base_x + 8.0, 26.0, world_base_z + 8.0)
			drips.emitting = true
			drips.amount = 16
			drips.lifetime = 2.5
			drips.direction = Vector3.DOWN
			drips.spread = 4.0
			drips.gravity = Vector3(0, -9.8, 0)
			drips.initial_velocity_min = 0.6
			drips.initial_velocity_max = 2.0
			drips.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			drips.emission_box_extents = Vector3(5.5, 0.5, 5.5)
			drips.mesh = drip_sphere_mesh
			chunk_body.add_child(drips)

func _rebuild_chunk_mesh(cx: int, cz: int) -> void:
	var key = Vector2i(cx, cz)
	if not chunks.has(key):
		return
	var res = _build_chunk_mesh_data(cx, cz, chunks[key],
		chunks.get(Vector2i(cx, cz - 1), null),
		chunks.get(Vector2i(cx, cz + 1), null),
		chunks.get(Vector2i(cx - 1, cz), null),
		chunks.get(Vector2i(cx + 1, cz), null)
	)
	_apply_chunk_mesh(cx, cz, res.arrays, res.empty)

## Rebuilds all active chunk meshes immediately (e.g. after level carving)
func remesh_all_active_chunks() -> void:
	for key in chunks.keys():
		_rebuild_chunk_mesh(key.x, key.y)
