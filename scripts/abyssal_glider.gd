extends CharacterBody3D

const MobDeathEffects = preload("res://scripts/mob_death_effects.gd")

signal glider_died(pos: Vector3)
signal glider_screeched(pos: Vector3)

@export var max_health: float = 28.0
@export var current_health: float = 28.0
@export var cruise_speed: float = 2.8
@export var swoop_speed: float = 4.8
@export var attack_damage: float = 7.0

var player_ref: CharacterBody3D
var model_root: Node3D
var body_node: Node3D
var wing_l: Node3D
var wing_r: Node3D

enum FlightState {
	HOVER_ROOST,
	CIRCLING,
	SWOOP_ATTACK,
	PULL_UP
}

var current_state: FlightState = FlightState.HOVER_ROOST
var roost_pos: Vector3 = Vector3.ZERO
var anim_time: float = 0.0
var wing_phase: float = 0.0
var current_flap_rate: float = 4.5
var swoop_cooldown: float = 0.0
var screech_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	roost_pos = global_position
	_setup_collision()
	_load_model()
	_find_player()

func _setup_collision() -> void:
	collision_layer = 4
	collision_mask = 1
	var col = CollisionShape3D.new()
	var sph = SphereShape3D.new()
	sph.radius = 0.75
	col.shape = sph
	col.position = Vector3(0, 0.4, 0)
	add_child(col)

func _load_model() -> void:
	model_root = Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)

	var glb = load("res://models/abyssal_glider.glb")
	if glb:
		var inst = glb.instantiate()
		model_root.add_child(inst)
		_find_wing_nodes(inst)

		# Apply high-detail bespoke 256x256 pixel texture & glowing emission map
		var bespoke_mat = StandardMaterial3D.new()
		var img = Image.load_from_file("res://textures/mobs/tex_abyssal_glider.png")
		if img:
			bespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
		bespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		bespoke_mat.emission_enabled = true
		var emit_img = Image.load_from_file("res://textures/mobs/tex_abyssal_glider_emit.png")
		if emit_img:
			bespoke_mat.emission_texture = ImageTexture.create_from_image(emit_img)
		bespoke_mat.emission_energy_multiplier = 3.2
		_apply_material_recursive(inst, bespoke_mat)

func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node
		mi.material_override = mat
	for child in node.get_children():
		_apply_material_recursive(child, mat)

func _find_wing_nodes(node: Node) -> void:
	if node.name.begins_with("Wing_L") and node is Node3D:
		wing_l = node as Node3D
	elif node.name.begins_with("Wing_R") and node is Node3D:
		wing_r = node as Node3D
	elif node.name.begins_with("AbyssalGlider") and node is Node3D:
		body_node = node as Node3D

	for c in node.get_children():
		_find_wing_nodes(c)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func _physics_process(delta: float) -> void:
	if current_health <= 0.0:
		return

	if swoop_cooldown > 0.0:
		swoop_cooldown -= delta
	if screech_cooldown > 0.0:
		screech_cooldown -= delta

	anim_time += delta

	var target_pos = roost_pos
	var current_speed = cruise_speed
	var target_flap_rate = 4.5

	if player_ref:
		var to_player = player_ref.global_position - global_position
		var dist = to_player.length()

		match current_state:
			FlightState.HOVER_ROOST:
				target_pos = roost_pos + Vector3(sin(anim_time * 1.2) * 2.0, cos(anim_time * 1.5) * 0.8, cos(anim_time * 1.2) * 2.0)
				target_flap_rate = 4.0
				if dist < 20.0 and swoop_cooldown <= 0.0:
					current_state = FlightState.CIRCLING
					swoop_cooldown = 2.0

			FlightState.CIRCLING:
				var angle = anim_time * 1.8
				var orbit_offset = Vector3(cos(angle) * 8.0, 5.0, sin(angle) * 8.0)
				target_pos = player_ref.global_position + orbit_offset
				target_flap_rate = 6.0
				current_speed = cruise_speed * 1.15
				if swoop_cooldown <= 0.0 and dist < 16.0:
					current_state = FlightState.SWOOP_ATTACK
					if screech_cooldown <= 0.0:
						screech_cooldown = 4.5
						glider_screeched.emit(global_position)
						var sm = get_tree().get_first_node_in_group("sound_manager")
						if sm and sm.has_method("play_sfx"):
							sm.play_sfx("horror_sting", global_position)

			FlightState.SWOOP_ATTACK:
				target_pos = player_ref.global_position + Vector3(0, 0.8, 0)
				current_speed = swoop_speed
				target_flap_rate = 10.0
				if dist < 1.9:
					if player_ref.has_method("take_damage"):
						player_ref.take_damage(attack_damage)
					current_state = FlightState.PULL_UP
					swoop_cooldown = 4.0
				elif global_position.y < (player_ref.global_position.y + 0.3):
					current_state = FlightState.PULL_UP

			FlightState.PULL_UP:
				target_pos = roost_pos + Vector3(0, 3.0, 0)
				current_speed = cruise_speed * 1.3
				target_flap_rate = 7.5
				if global_position.y > (roost_pos.y - 2.0) or dist > 18.0:
					current_state = FlightState.HOVER_ROOST

	# Continuous accumulated wing phase (eliminates all flutter and snapping!)
	current_flap_rate = lerp(current_flap_rate, target_flap_rate, delta * 4.0)
	wing_phase += delta * current_flap_rate

	# Steering and Obstacle Avoidance Raycasts against Voxel Terrain
	var to_dest = target_pos - global_position
	var desired_dir = to_dest.normalized()
	var avoidance_force = _compute_obstacle_avoidance()
	var final_move_dir = (desired_dir + avoidance_force * 1.5).normalized()

	velocity = velocity.move_toward(final_move_dir * current_speed, delta * 12.0)

	# Aerodynamic Banking & Orientation
	var horiz_dir = Vector2(-velocity.x, -velocity.z)
	if horiz_dir.length_squared() > 0.01:
		var target_yaw = atan2(-velocity.x, -velocity.z)
		var yaw_diff = wrapf(target_yaw - rotation.y, -PI, PI)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * 5.0)

		var target_roll = clamp(-yaw_diff * 1.2, -0.55, 0.55)
		rotation.z = lerp(rotation.z, target_roll, delta * 5.0)

	var vert_ratio = clamp(velocity.y / max(current_speed, 1.0), -0.85, 0.85)
	rotation.x = lerp(rotation.x, -vert_ratio * 0.65, delta * 5.0)

	# ARTICULATED PROCEDURAL WING ANIMATION
	_animate_wings(wing_phase, current_state)

	move_and_slide()

	# Deflect against solid voxel surfaces so it glides along cavern walls rather than clipping
	if get_slide_collision_count() > 0:
		for i in range(get_slide_collision_count()):
			var col = get_slide_collision(i)
			velocity = velocity.slide(col.get_normal()) * 0.85

func _compute_obstacle_avoidance() -> Vector3:
	var space = get_world_3d().direct_space_state
	if space == null:
		return Vector3.ZERO

	var fwd = -global_transform.basis.z.normalized()
	var rgt = global_transform.basis.x.normalized()
	var up_v = global_transform.basis.y.normalized()

	var probe_dirs = [
		fwd * 3.5,
		(fwd + rgt * 0.7).normalized() * 2.8,
		(fwd - rgt * 0.7).normalized() * 2.8,
		(fwd + up_v * 0.7).normalized() * 2.5,
		(fwd - up_v * 0.7).normalized() * 2.5
	]

	var repulsion = Vector3.ZERO
	for p_dir in probe_dirs:
		var query = PhysicsRayQueryParameters3D.create(global_position, global_position + p_dir, 1, [self])
		var hit = space.intersect_ray(query)
		if hit:
			var hit_norm = hit.normal
			var dist = global_position.distance_to(hit.position)
			var weight = 1.0 - clamp(dist / p_dir.length(), 0.0, 1.0)
			repulsion += hit_norm * weight

	return repulsion.normalized()

func _animate_wings(phase: float, state: FlightState) -> void:
	if wing_l == null or wing_r == null:
		return

	if state == FlightState.SWOOP_ATTACK:
		# Streamlined dive: wings swept back
		var dive_flutter = sin(phase * 2.0) * deg_to_rad(4.0)
		wing_l.rotation.z = deg_to_rad(28.0) + dive_flutter
		wing_r.rotation.z = -deg_to_rad(28.0) - dive_flutter
		wing_l.rotation.y = deg_to_rad(32.0)
		wing_r.rotation.y = -deg_to_rad(32.0)
	else:
		# Smooth continuous trigonometric wave
		var flap_phase = sin(phase)
		var flap_angle = flap_phase * deg_to_rad(34.0)

		wing_l.rotation.z = flap_angle - deg_to_rad(6.0)
		wing_r.rotation.z = -flap_angle + deg_to_rad(6.0)

		var pitch_phase = cos(phase)
		wing_l.rotation.x = pitch_phase * deg_to_rad(12.0)
		wing_r.rotation.x = pitch_phase * deg_to_rad(12.0)

		wing_l.rotation.y = sin(phase + 0.4) * deg_to_rad(8.0)
		wing_r.rotation.y = -sin(phase + 0.4) * deg_to_rad(8.0)

	if body_node:
		body_node.position.y = sin(phase * 0.5) * 0.025

func take_damage(amount: float, hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> void:
	current_health -= amount
	if wing_l and wing_r:
		wing_l.rotation.z += deg_to_rad(25.0)
		wing_r.rotation.z -= deg_to_rad(25.0)

	if current_health <= 0.0:
		glider_died.emit(global_position)
		MobDeathEffects.play_death_effect(self, "stalker")
