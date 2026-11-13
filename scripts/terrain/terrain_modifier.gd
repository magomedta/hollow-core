# scripts/terrain/terrain_modifier.gd
class_name TerrainModifier
extends Node

const WorldConfigClass = preload("res://scripts/world/world_config.gd")

## Handles organic, faceted geological mining and cavity carving.
## Instead of creating rigid square holes, it carves natural fracture cavities
## with irregular rock facets and jagged crevices, updating only affected chunk meshes.

signal cavity_mined(carved_voxels: Array[Vector3i], hit_point: Vector3, hit_normal: Vector3)
signal mineral_mined(coord: Vector3i, block_type: int, drop_name: String, drop_count: int)

var voxel_world: Node3D
var world_config: Resource = null

func _init(p_voxel_world: Node3D = null, p_config: Resource = null) -> void:
	voxel_world = p_voxel_world
	if p_config != null:
		world_config = p_config
	else:
		world_config = WorldConfigClass.get_default()

func set_world(p_voxel_world: Node3D) -> void:
	voxel_world = p_voxel_world

## Convenience alias for organic multi-voxel cavity excavation
func carve_organic_cavity(center_or_hit: Vector3, radius: float = 1.8, normal: Vector3 = Vector3.UP, _irregularity: float = 0.4) -> Array[Vector3i]:
	return mine_cavity(center_or_hit, normal, radius, true)

## Carves an organic geological fracture cavity at the given hit point.
## radius: 0.8 for standard pickaxe strike, 1.6..2.5 for heavy strike or explosive blast.
func mine_cavity(hit_point: Vector3, hit_normal: Vector3, radius: float = 0.85, is_pickaxe: bool = true) -> Array[Vector3i]:
	if voxel_world == null:
		return []

	# The primary targeted voxel is offset slightly inward along -normal
	var center_pos = hit_point - hit_normal * 0.35
	var center_coord = world_config.world_to_voxel(center_pos)

	var carved: Array[Vector3i] = []
	var affected_chunks: Dictionary = {} # Vector2i -> bool

	var r_ceil = int(ceil(radius))
	var base_r_sq = radius * radius

	for dx in range(-r_ceil, r_ceil + 1):
		for dy in range(-r_ceil, r_ceil + 1):
			for dz in range(-r_ceil, r_ceil + 1):
				var target_coord = Vector3i(center_coord.x + dx, center_coord.y + dy, center_coord.z + dz)
				if not world_config.is_valid_voxel_y(target_coord.y):
					continue

				var b_type = voxel_world.get_block(target_coord.x, target_coord.y, target_coord.z)
				# Never destroy AIR or indestructible BEDROCK
				if b_type == 0 or b_type == 21: # BlockType.AIR or BEDROCK
					continue

				# Calculate distance from blast/impact center
				var v_center = world_config.voxel_to_world(target_coord)
				var dist_sq = (v_center - center_pos).length_squared()

				# Faceted noise perturbation to create natural rock cleavage planes
				var noise_val = _fracture_noise(target_coord.x, target_coord.y, target_coord.z)
				var effective_r_sq = base_r_sq * (0.80 + 0.40 * noise_val)

				# Primary target is always carved; surrounding voxels carve if within irregular threshold
				if (dx == 0 and dy == 0 and dz == 0) or dist_sq <= effective_r_sq:
					# Check block properties for drops
					_process_block_drop(target_coord, b_type, is_pickaxe)

					# Set to AIR without immediate mesh update (we batch-update at the end)
					voxel_world.set_block(target_coord.x, target_coord.y, target_coord.z, 0, false)
					carved.push_back(target_coord)

					# Track affected chunk
					var c_coord = world_config.voxel_to_chunk_coord(target_coord)
					affected_chunks[c_coord] = true

					# If block is on a chunk boundary, track adjacent chunk
					var local_coord = world_config.get_local_voxel_coord(target_coord)
					if local_coord.x == 0:
						affected_chunks[c_coord + Vector2i(-1, 0)] = true
					elif local_coord.x == world_config.chunk_size_x - 1:
						affected_chunks[c_coord + Vector2i(1, 0)] = true
					if local_coord.z == 0:
						affected_chunks[c_coord + Vector2i(0, -1)] = true
					elif local_coord.z == world_config.chunk_size_z - 1:
						affected_chunks[c_coord + Vector2i(0, 1)] = true

	# Batch queue re-mesh only for strictly affected chunks
	for c_key in affected_chunks.keys():
		if voxel_world.chunks.has(c_key):
			if not voxel_world.chunks_in_mesh_queue.has(c_key):
				voxel_world.chunk_mesh_queue.push_front(c_key)
				voxel_world.chunks_in_mesh_queue[c_key] = true

	if carved.size() > 0:
		cavity_mined.emit(carved, hit_point, hit_normal)

	return carved

func _fracture_noise(x: int, y: int, z: int) -> float:
	# High-performance pseudo-random hash producing values in [0.0, 1.0]
	var n = x * 374761393 + y * 668265263 + z * 1274126177
	n = (n ^ (n >> 13)) * 1103515245
	n = (n ^ (n >> 16))
	return float(n & 0xFFFF) / 65535.0

func _process_block_drop(coord: Vector3i, b_type: int, is_pickaxe: bool) -> void:
	if not "BLOCK_PROPS" in voxel_world:
		return

	var props = voxel_world.BLOCK_PROPS.get(b_type, {})
	var drop_name: String = props.get("drop", "cobblestone")
	var drop_qty: int = props.get("count", 1)
	var is_soft: bool = props.get("is_soft", false)

	if not is_pickaxe and not is_soft:
		if drop_name in ["iron", "copper", "gold", "calcite", "phosphor"]:
			drop_name = "cobblestone"
			drop_qty = 1

	if drop_name != "" and drop_qty > 0:
		mineral_mined.emit(coord, b_type, drop_name, drop_qty)
		var drop_pos = world_config.voxel_to_world(coord)
		if voxel_world.has_method("_spawn_dropped_item"):
			voxel_world._spawn_dropped_item(drop_pos, drop_name, drop_qty)
