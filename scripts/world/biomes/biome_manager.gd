# scripts/world/biomes/biome_manager.gd
class_name BiomeManager
extends Node

## Central coordinator for subterranean biomes in Hollow Core.
## Manages 3D spatial partitioning, continuous environmental transitions,
## dynamic atmospheric blending (fog, ambient light), and acoustic profiles.

const BiomeDefinitionClass = preload("res://scripts/world/biomes/biome_definition.gd")

signal biome_changed(new_biome: Resource, old_biome: Resource)

@export var registered_biomes: Array[Resource] = []
@export var smooth_transition_speed: float = 2.5 # Lerp speed per second

var current_biome: Resource = null
var target_player: CharacterBody3D = null
var world_environment: WorldEnvironment = null
var sound_memory_manager: Node = null

# Fallback default biome if player leaves all designated zones
var default_biome: Resource = null

func _init() -> void:
	_create_default_biome()

func _ready() -> void:
	add_to_group("biome_manager")
	_load_standard_biomes()

func _create_default_biome() -> void:
	default_biome = BiomeDefinitionClass.new()
	default_biome.id = "deep_strata"
	default_biome.display_name = "Глубинные Недра"
	default_biome.min_height = -128.0
	default_biome.max_height = 128.0
	default_biome.spatial_bounds = AABB(Vector3(-500, -128, -500), Vector3(1000, 256, 1000))
	default_biome.priority = 0
	default_biome.ambient_color = Color(0.12, 0.15, 0.20, 1.0)
	default_biome.ambient_energy = 0.30
	default_biome.fog_color = Color(0.10, 0.12, 0.16, 1.0)
	default_biome.fog_density = 0.020
	default_biome.surface_friction = 0.90
	default_biome.reverb_time = 3.0

func _load_standard_biomes() -> void:
	var paths = [
		"res://resources/biomes/glacial_spires.tres",
		"res://resources/biomes/flooded_gates.tres",
		"res://resources/biomes/basaltic_abyssal.tres"
	]
	for p in paths:
		if ResourceLoader.exists(p):
			var res = load(p) as Resource
			if res != null and not registered_biomes.has(res):
				register_biome(res)

func register_biome(biome: Resource) -> void:
	if biome != null and not registered_biomes.has(biome):
		registered_biomes.append(biome)
		print("[BiomeManager] Registered biome: ", biome.id, " (", biome.display_name, ")")

## Resolves the active biome at the given 3D position based on bounds and priority
func get_biome_at(pos: Vector3) -> Resource:
	var best_biome: Resource = null
	var highest_priority: int = -9999
	var best_weight: float = -1.0

	for biome in registered_biomes:
		if biome.contains_point(pos):
			if biome.priority > highest_priority:
				highest_priority = biome.priority
				best_biome = biome
				best_weight = biome.get_point_weight(pos)
			elif biome.priority == highest_priority:
				var w = biome.get_point_weight(pos)
				if w > best_weight:
					best_biome = biome
					best_weight = w

	if best_biome != null:
		return best_biome

	# If slightly outside, find closest biome within blend margin
	for biome in registered_biomes:
		var w = biome.get_point_weight(pos)
		if w > 0.0:
			if biome.priority > highest_priority or (biome.priority == highest_priority and w > best_weight):
				highest_priority = biome.priority
				best_biome = biome
				best_weight = w

	return best_biome if best_biome != null else default_biome

func get_dominant_biome(pos: Vector3) -> Resource:
	return get_biome_at(pos)

## Calculates blended atmosphere parameters (color, density, light energy)
func get_blended_environment(pos: Vector3) -> Dictionary:
	var active_b = get_biome_at(pos)
	var active_weight = active_b.get_point_weight(pos)

	var target_ambient_col = active_b.ambient_color
	var target_ambient_nrg = active_b.ambient_energy
	var target_fog_col = active_b.fog_color
	var target_fog_dns = active_b.fog_density

	# If on the border with another biome, blend smoothly
	if active_weight < 0.99:
		for other in registered_biomes:
			if other != active_b:
				var other_w = other.get_point_weight(pos)
				if other_w > 0.0:
					var total_w = active_weight + other_w
					var t = other_w / max(total_w, 0.001)
					target_ambient_col = target_ambient_col.lerp(other.ambient_color, t)
					target_ambient_nrg = lerp(target_ambient_nrg, other.ambient_energy, t)
					target_fog_col = target_fog_col.lerp(other.fog_color, t)
					target_fog_dns = lerp(target_fog_dns, other.fog_density, t)
					break

	return {
		"ambient_color": target_ambient_col,
		"ambient_energy": target_ambient_nrg,
		"fog_color": target_fog_col,
		"fog_density": target_fog_dns,
		"reverb_time": active_b.reverb_time,
		"surface_friction": active_b.surface_friction
	}

func _process(delta: float) -> void:
	var check_pos = Vector3.ZERO
	if is_instance_valid(target_player):
		check_pos = target_player.global_position
	elif get_viewport().get_camera_3d() != null:
		check_pos = get_viewport().get_camera_3d().global_position
	else:
		return

	var new_b = get_biome_at(check_pos)
	if new_b != current_biome:
		var old_b = current_biome
		current_biome = new_b
		biome_changed.emit(new_b, old_b)
		print("[BiomeManager] Shifted into stratum: ", new_b.display_name, " (", new_b.id, ")")

	_update_environment_and_acoustics(check_pos, delta)

func _update_environment_and_acoustics(pos: Vector3, delta: float) -> void:
	if world_environment == null or world_environment.environment == null:
		# Attempt auto-discovery in scene tree
		world_environment = get_tree().get_first_node_in_group("world_environment") as WorldEnvironment
		if world_environment == null:
			var parent = get_parent()
			if parent != null and parent.has_node("WorldEnvironment"):
				world_environment = parent.get_node("WorldEnvironment") as WorldEnvironment

	if world_environment != null and world_environment.environment != null:
		var env = world_environment.environment
		var blend_params = get_blended_environment(pos)

		var t = clamp(delta * smooth_transition_speed, 0.0, 1.0)
		env.ambient_light_color = env.ambient_light_color.lerp(blend_params.ambient_color, t)
		env.ambient_light_energy = lerp(env.ambient_light_energy, blend_params.ambient_energy, t)
		env.fog_light_color = env.fog_light_color.lerp(blend_params.fog_color, t)
		env.fog_density = lerp(env.fog_density, blend_params.fog_density, t)

	if sound_memory_manager != null and current_biome != null:
		# Update acoustic reverb room size based on biome reverb time
		if sound_memory_manager.has_method("set_reverb_parameters"):
			sound_memory_manager.set_reverb_parameters(current_biome.reverb_time, current_biome.reverb_damping)
