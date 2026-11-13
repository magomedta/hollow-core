# scripts/world/world_config.gd
class_name WorldConfig
extends Resource

## Centralized Configuration for Hollow Core Vertical World & Procedural Geology
## Enforces the unified 256-meter vertical strata (Y = -128 .. +128)
## and provides robust coordinate conversions handling negative coordinates correctly.

@export_group("World Boundaries")
@export var min_world_y: int = -128
@export var max_world_y: int = 128
@export var voxel_scale: float = 1.0 # 1 voxel = 1.0 meter

@export_group("Chunk Geometry")
@export var chunk_size_x: int = 16
@export var chunk_size_z: int = 16
@export var world_seed: int = 1337
@export var load_distance: int = 3 # 7x7 chunks column streaming
@export var geometry_resolution: float = 1.0

@export_group("Strata Height Ranges")
@export var stratum_5_cryosphere_min: int = 80   # Y = 80 .. 128 (Cryosphere Spires)
@export var stratum_4_water_min: int = 25        # Y = 25 .. 80  (Flooded Sluices & Cascade)
@export var stratum_3_basalt_min: int = -30      # Y = -30 .. 25 (Basalt Abyssal & Mycena)
@export var stratum_2_syndicate_min: int = -85   # Y = -85 .. -30 (Syndicate 104 Mines & Keller-Weiss)
@export var stratum_1_caldera_min: int = -128    # Y = -128 .. -85 (Sulfur Caldera & Bedrock Void)

static var _default_instance: Resource = null

static func get_default() -> Resource:
	if _default_instance == null:
		var script_res = load("res://scripts/world/world_config.gd")
		_default_instance = script_res.new()
	return _default_instance

func get_chunk_height() -> int:
	return max_world_y - min_world_y # 256 blocks

func get_stride_z() -> int:
	return chunk_size_x * get_chunk_height() # 16 * 256 = 4096

func get_total_voxels_per_chunk() -> int:
	return chunk_size_x * get_chunk_height() * chunk_size_z # 16 * 256 * 16 = 65536 bytes

func is_valid_voxel_y(gy: int) -> bool:
	return gy >= min_world_y and gy < max_world_y

func world_to_voxel(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		int(floor(world_pos.x / voxel_scale)),
		int(floor(world_pos.y / voxel_scale)),
		int(floor(world_pos.z / voxel_scale))
	)

func voxel_to_world(voxel_coord: Vector3i) -> Vector3:
	return Vector3(
		(float(voxel_coord.x) + 0.5) * voxel_scale,
		(float(voxel_coord.y) + 0.5) * voxel_scale,
		(float(voxel_coord.z) + 0.5) * voxel_scale
	)

func world_to_chunk_coord(world_pos: Vector3) -> Vector2i:
	var vx = int(floor(world_pos.x / voxel_scale))
	var vz = int(floor(world_pos.z / voxel_scale))
	return voxel_to_chunk_coord(Vector3i(vx, 0, vz))

func voxel_to_chunk_coord(voxel_coord: Vector3i) -> Vector2i:
	return Vector2i(
		int(floor(float(voxel_coord.x) / float(chunk_size_x))),
		int(floor(float(voxel_coord.z) / float(chunk_size_z)))
	)

func get_local_voxel_coord(voxel_coord: Vector3i) -> Vector3i:
	var lx = posmod(voxel_coord.x, chunk_size_x)
	var ly = voxel_coord.y - min_world_y
	var lz = posmod(voxel_coord.z, chunk_size_z)
	return Vector3i(lx, ly, lz)

func get_biome_at_height(gy: int) -> String:
	if gy >= stratum_5_cryosphere_min:
		return "Glacial Cryosphere"
	elif gy >= stratum_4_water_min:
		return "Flooded Sluice Galleries"
	elif gy >= stratum_3_basalt_min:
		return "Basalt Abyssal Basin"
	elif gy >= stratum_2_syndicate_min:
		return "Industrial Syndicate Mines"
	else:
		if gy <= min_world_y + 4:
			return "The Bedrock Void"
		return "Sulfur Caldera & Magma Hearth"
