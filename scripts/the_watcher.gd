# scripts/the_watcher.gd
class_name TheWatcher
extends Node3D

## The Watcher in the Fog (Classic Alpha Creepypasta Horror Entity)
## Inspired by the legendary Herobrine mythos and liminal fog horror:
## - Spawns silently at the edge of render distance / fog horizon.
## - Stands motionless, staring directly at the player with piercing white square eyes.
## - Causes nearby light sources to flicker and low horror drones to swell.
## - Dissolves into fog when approached too closely or looked at for too long.
## - Never attacks like a generic mob; it induces pure psychological dread.

signal watcher_apparition_event(event_id: String, world_pos: Vector3)

var player_ref: CharacterBody3D
var model_root: Node3D
var eye_left: MeshInstance3D
var eye_right: MeshInstance3D
var is_ambient_showcase: bool = false

var observe_time: float = 0.0
var vanish_timer: float = 0.0
var is_vanishing: bool = false
var player_was_looking: bool = false
var look_duration: float = 0.0

func _init() -> void:
	_construct_silhouette()

func _ready() -> void:
	add_to_group("horror_entities")
	_find_player()
	watcher_apparition_event.emit("APP-01", global_position)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func _construct_silhouette() -> void:
	model_root = Node3D.new()
	model_root.name = "WatcherSilhouette"
	add_child(model_root)

	# Pure obsidian void silhouette material (absorbs light)
	var void_mat = StandardMaterial3D.new()
	void_mat.albedo_color = Color(0.02, 0.02, 0.03, 1.0)
	void_mat.roughness = 0.95
	void_mat.metallic = 0.0

	# Iconic Piercing White Emissive Eyes (Visible through dense fog from afar!)
	var white_eye_mat = StandardMaterial3D.new()
	white_eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white_eye_mat.albedo_color = Color(1.0, 1.0, 1.0)
	white_eye_mat.emission_enabled = true
	white_eye_mat.emission = Color(1.0, 1.0, 1.0)
	white_eye_mat.emission_energy_multiplier = 16.0 # Blinding white glow through fog

	# 1. Torso
	var torso = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.55, 0.85, 0.30)
	torso.mesh = t_box
	torso.material_override = void_mat
	torso.position = Vector3(0, 1.35, 0)
	model_root.add_child(torso)

	# 2. Head
	var head = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.44, 0.44, 0.44)
	head.mesh = h_box
	head.material_override = void_mat
	head.position = Vector3(0, 2.05, 0)
	model_root.add_child(head)

	# 3. Two Piercing White Square Eyes (Herobrine style)
	eye_left = MeshInstance3D.new()
	var e_box_l = BoxMesh.new()
	e_box_l.size = Vector3(0.10, 0.10, 0.04)
	eye_left.mesh = e_box_l
	eye_left.material_override = white_eye_mat
	eye_left.position = Vector3(-0.11, 2.08, -0.23)
	model_root.add_child(eye_left)

	eye_right = MeshInstance3D.new()
	var e_box_r = BoxMesh.new()
	e_box_r.size = Vector3(0.10, 0.10, 0.04)
	eye_right.mesh = e_box_r
	eye_right.material_override = white_eye_mat
	eye_right.position = Vector3(0.11, 2.08, -0.23)
	model_root.add_child(eye_right)

	# 4. Slender Arms
	for sx in [-0.38, 0.38]:
		var arm = MeshInstance3D.new()
		var a_box = BoxMesh.new()
		a_box.size = Vector3(0.18, 0.85, 0.18)
		arm.mesh = a_box
		arm.material_override = void_mat
		arm.position = Vector3(sx, 1.35, 0)
		model_root.add_child(arm)

	# 5. Legs
	for lx in [-0.15, 0.15]:
		var leg = MeshInstance3D.new()
		var l_box = BoxMesh.new()
		l_box.size = Vector3(0.20, 0.95, 0.20)
		leg.mesh = l_box
		leg.material_override = void_mat
		leg.position = Vector3(lx, 0.48, 0)
		model_root.add_child(leg)

func _process(delta: float) -> void:
	if is_vanishing:
		vanish_timer += delta
		model_root.scale = model_root.scale.lerp(Vector3.ZERO, delta * 6.0)
		if eye_left:
			eye_left.scale = eye_left.scale.lerp(Vector3.ZERO, delta * 8.0)
		if eye_right:
			eye_right.scale = eye_right.scale.lerp(Vector3.ZERO, delta * 8.0)
		if vanish_timer >= 0.8:
			queue_free()
		return

	if not player_ref:
		_find_player()
		return

	var to_player = player_ref.global_position - global_position
	var dist = to_player.length()

	# Stare directly into the player's soul
	rotation.y = atan2(-to_player.x, -to_player.z)

	# Subtle eerie head tilt
	observe_time += delta
	if model_root:
		model_root.rotation.z = sin(observe_time * 0.8) * 0.04

	if not is_ambient_showcase:
		# Check if player is looking at the Watcher
		var is_player_looking = _is_player_looking_at_me()
		if is_player_looking:
			look_duration += delta
			# If stared at directly for > 2.5 seconds, vanish into the fog
			if look_duration >= 2.5:
				_vanish()
				return
		else:
			if look_duration > 0.5:
				# Player looked at the entity and then looked away -> INSTANT VANISH!
				_vanish()
				return
			look_duration = 0.0

		# If player gets too close (< 14 meters), vanish
		if dist < 14.0:
			_vanish()
			return

		# If player runs too far away (> 55 meters), despawn silently
		if dist > 55.0:
			queue_free()

func _is_player_looking_at_me() -> bool:
	if not player_ref or not ("camera" in player_ref) or not player_ref.camera:
		return false
	var cam: Camera3D = player_ref.camera
	var cam_forward = -cam.global_transform.basis.z.normalized()
	var to_me = (global_position - cam.global_position).normalized()
	var dot = cam_forward.dot(to_me)
	return dot > 0.82 # Looking roughly in this 35-degree cone

func _vanish() -> void:
	if is_vanishing:
		return
	is_vanishing = true
	vanish_timer = 0.0
	watcher_apparition_event.emit("APP-01_VANISHED", global_position)

	# Play subtle distant horror stinger
	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("horror_drone", global_position, 1.0, 4.0)

	# Cause player lantern to flicker if nearby
	if player_ref and "lantern" in player_ref and player_ref.lantern:
		if player_ref.lantern.has_method("flicker"):
			player_ref.lantern.flicker()
