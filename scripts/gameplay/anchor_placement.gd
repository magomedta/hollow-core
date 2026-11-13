# scripts/gameplay/anchor_placement.gd
class_name AnchorPlacementComponent
extends Node3D

## Handles raycast projection, ghost preview wireframe, and physical
## fastening of RockAnchors onto subterranean rock surfaces.

const RockAnchorClass = preload("res://scripts/gameplay/rock_anchor.gd")

signal anchor_placed(anchor: Node3D, world_pos: Vector3, normal: Vector3)

var player_ref: CharacterBody3D = null
var is_placement_active: bool = false
var ghost_mesh: MeshInstance3D = null
var current_target_valid: bool = false
var current_hit_pos: Vector3 = Vector3.ZERO
var current_hit_normal: Vector3 = Vector3.UP

func _ready() -> void:
	_create_ghost_preview()
	set_process(false)

func set_player(p_player: CharacterBody3D) -> void:
	player_ref = p_player

func _create_ghost_preview() -> void:
	ghost_mesh = MeshInstance3D.new()
	ghost_mesh.name = "AnchorGhostPreview"

	var ring = TorusMesh.new()
	ring.inner_radius = 0.045
	ring.outer_radius = 0.080
	ghost_mesh.mesh = ring

	var ghost_mat = StandardMaterial3D.new()
	ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost_mat.albedo_color = Color(1.0, 0.72, 0.20, 0.65) # Warm amber holographic ghost
	ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ghost_mesh.material_override = ghost_mat

	add_child(ghost_mesh)
	ghost_mesh.visible = false

func start_placement() -> void:
	is_placement_active = true
	if ghost_mesh:
		ghost_mesh.visible = true
	set_process(true)

func stop_placement() -> void:
	is_placement_active = false
	if ghost_mesh:
		ghost_mesh.visible = false
	set_process(false)

func _process(_delta: float) -> void:
	if not is_placement_active or player_ref == null:
		return

	var cam = player_ref.get_node_or_null("Head/Camera3D")
	if cam == null:
		cam = player_ref.camera if "camera" in player_ref else null
	if cam == null:
		return

	var space = get_world_3d().direct_space_state
	var origin = cam.global_position
	var forward = -cam.global_transform.basis.z
	var end = origin + forward * 3.8

	var query = PhysicsRayQueryParameters3D.create(origin, end, 1, [player_ref])
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit = space.intersect_ray(query)

	if hit and hit.normal.length_squared() > 0.1:
		current_target_valid = true
		current_hit_pos = hit.position
		current_hit_normal = hit.normal

		ghost_mesh.global_position = current_hit_pos + current_hit_normal * 0.04
		# Orient ghost along normal
		if abs(current_hit_normal.y) < 0.99:
			ghost_mesh.look_at(current_hit_pos + current_hit_normal, Vector3.UP)
		else:
			ghost_mesh.look_at(current_hit_pos + current_hit_normal, Vector3.FORWARD)

		var mat = ghost_mesh.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(1.0, 0.72, 0.20, 0.75) # Valid amber
	else:
		current_target_valid = false
		var mat = ghost_mesh.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(0.85, 0.20, 0.20, 0.35) # Invalid red

## Places a rock anchor at the current aimed location
func place_anchor(parent_container: Node3D = null) -> Node3D:
	if not current_target_valid:
		return null

	var container = parent_container
	if container == null:
		container = get_tree().current_scene

	var anchor = RockAnchorClass.new(current_hit_normal, 3.5)
	container.add_child(anchor)
	anchor.global_position = current_hit_pos

	if abs(current_hit_normal.y) < 0.99:
		anchor.look_at(current_hit_pos + current_hit_normal, Vector3.UP)
	else:
		anchor.look_at(current_hit_pos + current_hit_normal, Vector3.FORWARD)

	# Sound feedback
	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("pickaxe_stone", current_hit_pos, 0.85, 2.0)

	anchor_placed.emit(anchor, current_hit_pos, current_hit_normal)
	return anchor
