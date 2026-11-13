# scripts/world/biomes/biome_definition.gd
class_name BiomeDefinition
extends Resource

## Data container defining an ecological, geological, and atmospheric stratum.
## Utilized by BiomeManager for chunk generation, shader parameters,
## environmental lighting, acoustics, and player locomotion physics.

@export var id: String = "unknown"
@export var display_name: String = "Неизвестный горизонт"

# 3D Spatial Partitioning & Bounds
@export var min_height: float = -128.0
@export var max_height: float = 128.0
@export var spatial_bounds: AABB = AABB(Vector3(-100, -128, -100), Vector3(200, 256, 200))
@export var priority: int = 10
@export var blend_margin: float = 4.0 # Spatial transition thickness in meters

# Palette & Lighting Parameters
@export var ambient_color: Color = Color(0.15, 0.20, 0.25, 1.0)
@export var ambient_energy: float = 0.35
@export var fog_color: Color = Color(0.12, 0.16, 0.22, 1.0)
@export var fog_density: float = 0.020
@export var fog_aerial_perspective: float = 0.60

# Geology & Physical Surface
@export var dominant_block: int = 1 # VoxelWorld.BlockType.STONE
@export var secondary_blocks: Array[int] = []
@export var surface_friction: float = 1.0 # 0.35 on ice (slippery), 0.85 on wet rock
@export var water_level_y: float = -999.0 # Subterranean water table altitude

# Acoustics & Lithic Memory
@export var reverb_time: float = 2.4 # Seconds of reverberation decay
@export var reverb_damping: float = 0.4
@export var ambient_ambience_id: String = ""
@export var primary_footstep_sound: String = "footstep_stone"
@export var acoustic_absorption: float = 0.3

## Tests whether a 3D coordinate falls inside this biome's spatial boundary
func contains_point(pos: Vector3) -> bool:
	if pos.y < min_height or pos.y > max_height:
		return false
	return spatial_bounds.has_point(pos)

## Calculates continuous interpolation weight [0.0..1.0] taking blend_margin into account
func get_point_weight(pos: Vector3) -> float:
	if not contains_point(pos):
		# Check distance to bounds for blending
		var clamped_y = clamp(pos.y, min_height, max_height)
		var clamped_p = Vector3(
			clamp(pos.x, spatial_bounds.position.x, spatial_bounds.end.x),
			clamped_y,
			clamp(pos.z, spatial_bounds.position.z, spatial_bounds.end.z)
		)
		var dist = pos.distance_to(clamped_p)
		if dist >= blend_margin:
			return 0.0
		return 1.0 - (dist / blend_margin)

	# Inside bounds: check distance to nearest boundary
	var d_min_y = pos.y - min_height
	var d_max_y = max_height - pos.y
	var d_min_x = pos.x - spatial_bounds.position.x
	var d_max_x = spatial_bounds.end.x - pos.x
	var d_min_z = pos.z - spatial_bounds.position.z
	var d_max_z = spatial_bounds.end.z - pos.z

	var min_edge_dist = min(min(min(d_min_y, d_max_y), min(d_min_x, d_max_x)), min(d_min_z, d_max_z))
	if min_edge_dist < blend_margin:
		return clamp(min_edge_dist / blend_margin, 0.05, 1.0)

	return 1.0
