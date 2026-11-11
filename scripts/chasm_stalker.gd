extends CharacterBody3D

const PixelTextureGenerator = preload("res://scripts/pixel_texture_generator.gd")

signal stalker_alerted(pos: Vector3)
signal stalker_died(pos: Vector3)

enum State {
	IDLE,
	PATROL,
	INVESTIGATE,
	CHASE,
	STUNNED,
	ATTACK,
	DEAD
}

@export var max_health: float = 90.0
@export var current_health: float = 90.0
@export var walk_speed: float = 2.4
@export var run_speed: float = 6.2
@export var attack_damage: float = 25.0
@export var attack_range: float = 2.2
@export var attack_cooldown: float = 1.4

var current_state: State = State.IDLE
var target_investigate_pos: Vector3 = Vector3.ZERO
var state_timer: float = 0.0
var attack_timer: float = 0.0
var stun_timer: float = 0.0

# References
var player_ref: CharacterBody3D
var model_root: Node3D
var head_node: Node3D
var sensory_crest: MeshInstance3D
var left_claw: Node3D
var right_claw: Node3D
var sensory_mat: StandardMaterial3D

# Animation phases
var walk_cycle: float = 0.0
var flinch_blend: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	_construct_chasm_stalker_mesh()
	_find_player()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
		if player_ref.has_signal("acoustic_noise_emitted"):
			player_ref.acoustic_noise_emitted.connect(_on_acoustic_noise_emitted)

func _construct_chasm_stalker_mesh() -> void:
	model_root = Node3D.new()
	model_root.name = "StalkerModel"
	add_child(model_root)

	# Chitinous faceted materials with 64x64 pixel texture
	var chitin_mat = StandardMaterial3D.new()
	chitin_mat.albedo_texture = PixelTextureGenerator.get_stalker_chitin_texture()
	chitin_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	chitin_mat.uv1_scale = Vector3(1.5, 1.5, 1.5)
	chitin_mat.roughness = 0.45
	chitin_mat.metallic = 0.25

	var carapace_ridge_mat = StandardMaterial3D.new()
	carapace_ridge_mat.albedo_texture = PixelTextureGenerator.get_stalker_chitin_texture()
	carapace_ridge_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	carapace_ridge_mat.roughness = 0.35
	carapace_ridge_mat.metallic = 0.40

	var claw_blade_mat = StandardMaterial3D.new()
	claw_blade_mat.albedo_color = Color(0.15, 0.18, 0.22)
	claw_blade_mat.metallic = 0.70
	claw_blade_mat.roughness = 0.25

	# Striking bioluminescent eye material (Visible from afar in pitch-black caves!)
	sensory_mat = StandardMaterial3D.new()
	sensory_mat.albedo_color = Color(0.15, 1.0, 0.85)
	sensory_mat.emission_enabled = true
	sensory_mat.emission = Color(0.20, 1.0, 0.88)
	sensory_mat.emission_energy_multiplier = 4.0

	# 1. Segmented Arched Thorax & Carapace
	var thorax = MeshInstance3D.new()
	var th_box = BoxMesh.new()
	th_box.size = Vector3(0.70, 0.55, 0.95)
	thorax.mesh = th_box
	thorax.material_override = chitin_mat
	thorax.position = Vector3(0, 1.05, 0)
	model_root.add_child(thorax)

	var abdomen = MeshInstance3D.new()
	var ab_box = BoxMesh.new()
	ab_box.size = Vector3(0.58, 0.48, 0.80)
	abdomen.mesh = ab_box
	abdomen.material_override = chitin_mat
	abdomen.position = Vector3(0, 0.95, 0.78)
	model_root.add_child(abdomen)

	# Dorsal armor ridges
	for i in range(4):
		var ridge = MeshInstance3D.new()
		var r_prism = PrismMesh.new()
		r_prism.size = Vector3(0.42, 0.24, 0.22)
		ridge.mesh = r_prism
		ridge.material_override = carapace_ridge_mat
		ridge.position = Vector3(0, 1.38, -0.32 + i * 0.32)
		model_root.add_child(ridge)

	# 2. Menacing Predatory Head with Glowing Eyes
	head_node = Node3D.new()
	head_node.name = "Head"
	head_node.position = Vector3(0, 1.15, -0.65)
	model_root.add_child(head_node)

	var cranium = MeshInstance3D.new()
	var cr_box = BoxMesh.new()
	cr_box.size = Vector3(0.45, 0.38, 0.52)
	cranium.mesh = cr_box
	cranium.material_override = chitin_mat
	cranium.position = Vector3(0, 0, -0.15)
	head_node.add_child(cranium)

	# Glowing Bioluminescent Multi-Eyes (Left, Right, Center pairs that pierce the dark)
	var eye_coords = [
		Vector3(-0.16, 0.08, -0.42),
		Vector3(0.16, 0.08, -0.42),
		Vector3(-0.12, 0.16, -0.38),
		Vector3(0.12, 0.16, -0.38)
	]
	for ec in eye_coords:
		var eye = MeshInstance3D.new()
		var e_box = BoxMesh.new()
		e_box.size = Vector3(0.08, 0.08, 0.06)
		eye.mesh = e_box
		eye.material_override = sensory_mat
		eye.position = ec
		head_node.add_child(eye)

	# Faint localized eye glow light
	var eye_light = OmniLight3D.new()
	eye_light.name = "EyeGlow"
	eye_light.light_color = Color(0.25, 1.0, 0.88)
	eye_light.light_energy = 1.2
	eye_light.omni_range = 3.5
	eye_light.position = Vector3(0, 0.1, -0.45)
	head_node.add_child(eye_light)

	# Acoustic sensory crest
	sensory_crest = MeshInstance3D.new()
	var sc_box = BoxMesh.new()
	sc_box.size = Vector3(0.28, 0.12, 0.38)
	sensory_crest.mesh = sc_box
	sensory_crest.material_override = sensory_mat
	sensory_crest.position = Vector3(0, 0.22, -0.12)
	head_node.add_child(sensory_crest)

	# Mandibles (Curved sharp pincers)
	for mx in [-0.15, 0.15]:
		var mandible = MeshInstance3D.new()
		var m_prism = PrismMesh.new()
		m_prism.size = Vector3(0.08, 0.32, 0.10)
		mandible.mesh = m_prism
		mandible.material_override = claw_blade_mat
		mandible.position = Vector3(mx, -0.16, -0.42)
		mandible.rotation_degrees = Vector3(80, 0, 20 if mx < 0 else -20)
		head_node.add_child(mandible)

	# 3. Scythe-Like Raptor Forelimbs (Left & Right)
	left_claw = _build_raptor_arm(-0.45, chitin_mat, claw_blade_mat)
	model_root.add_child(left_claw)

	right_claw = _build_raptor_arm(0.45, chitin_mat, claw_blade_mat)
	model_root.add_child(right_claw)

	# 4. Arched Hind Locomotion Legs (Articulated crawler stance)
	var leg_configs = [
		{"pos": Vector3(-0.42, 1.0, 0.15), "flip": -1.0},
		{"pos": Vector3(0.42, 1.0, 0.15), "flip": 1.0},
		{"pos": Vector3(-0.40, 0.95, 0.65), "flip": -1.0},
		{"pos": Vector3(0.40, 0.95, 0.65), "flip": 1.0}
	]
	for lc in leg_configs:
		var leg_root = Node3D.new()
		leg_root.position = lc["pos"]

		# Upper arched femur
		var femur = MeshInstance3D.new()
		var f_box = BoxMesh.new()
		f_box.size = Vector3(0.09, 0.65, 0.09)
		femur.mesh = f_box
		femur.material_override = chitin_mat
		femur.position = Vector3(0.20 * lc["flip"], 0.20, 0)
		femur.rotation_degrees = Vector3(0, 0, -42 * lc["flip"])
		leg_root.add_child(femur)

		# Lower tibia claw
		var tibia = MeshInstance3D.new()
		var t_box = BoxMesh.new()
		t_box.size = Vector3(0.07, 0.75, 0.07)
		tibia.mesh = t_box
		tibia.material_override = chitin_mat
		tibia.position = Vector3(0.38 * lc["flip"], -0.42, 0)
		tibia.rotation_degrees = Vector3(0, 0, 18 * lc["flip"])
		leg_root.add_child(tibia)

		model_root.add_child(leg_root)

	# Collision Shape (Capsule for CharacterBody3D)
	var col = CollisionShape3D.new()
	col.name = "Collision"
	var cap = CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.6
	col.shape = cap
	col.position = Vector3(0, 0.85, 0)
	add_child(col)

func _build_raptor_arm(offset_x: float, armor_mat: Material, blade_mat: Material) -> Node3D:
	var arm_root = Node3D.new()
	arm_root.position = Vector3(offset_x, 0.85, -0.32)

	# Upper arm segment
	var upper = MeshInstance3D.new()
	var u_box = BoxMesh.new()
	u_box.size = Vector3(0.08, 0.45, 0.08)
	upper.mesh = u_box
	upper.material_override = armor_mat
	upper.position = Vector3(0, 0.15, -0.15)
	upper.rotation_degrees = Vector3(-45, 0, -18 if offset_x > 0 else 18)
	arm_root.add_child(upper)

	# Forearm & Scythe blade
	var scythe = MeshInstance3D.new()
	var s_prism = PrismMesh.new()
	s_prism.size = Vector3(0.05, 0.65, 0.12)
	scythe.mesh = s_prism
	scythe.material_override = blade_mat
	scythe.position = Vector3(0, -0.18, -0.38)
	scythe.rotation_degrees = Vector3(65, 0, 0)
	arm_root.add_child(scythe)

	return arm_root

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y -= 19.6 * delta

	attack_timer -= delta

	# Check photophobia: is player lantern shining directly into stalker face?
	_check_lantern_photophobia(delta)

	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.INVESTIGATE:
			_process_investigate(delta)
		State.CHASE:
			_process_chase(delta)
		State.STUNNED:
			_process_stunned(delta)
		State.ATTACK:
			_process_attack(delta)

	move_and_slide()
	_update_animation(delta)

func _process_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, walk_speed * delta * 5.0)
	velocity.z = move_toward(velocity.z, 0.0, walk_speed * delta * 5.0)

	state_timer -= delta
	if state_timer <= 0.0:
		state_timer = randf_range(3.0, 7.0)

	# If player gets too close, stalker's heat/vibration sensors trigger chase
	if player_ref:
		var dist = global_position.distance_to(player_ref.global_position)
		if dist < 6.5:
			_enter_chase()

func _process_investigate(delta: float) -> void:
	var to_target = (target_investigate_pos - global_position)
	to_target.y = 0.0
	var dist = to_target.length()

	if dist < 1.8:
		# Arrived at noise origin, found nothing, return to idle
		current_state = State.IDLE
		state_timer = 4.0
		return

	# Face towards sound location
	var dir = to_target.normalized()
	var target_yaw = atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, delta * 4.0)

	velocity.x = dir.x * walk_speed
	velocity.z = dir.z * walk_speed

	# Check proximity to player during investigation
	if player_ref and global_position.distance_to(player_ref.global_position) < 7.0:
		_enter_chase()

func _process_chase(delta: float) -> void:
	if player_ref == null:
		current_state = State.IDLE
		return

	var to_player = (player_ref.global_position - global_position)
	to_player.y = 0.0
	var dist = to_player.length()

	if dist <= attack_range and attack_timer <= 0.0:
		_enter_attack()
		return

	var dir = to_player.normalized()
	var target_yaw = atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, delta * 8.0)

	velocity.x = dir.x * run_speed
	velocity.z = dir.z * run_speed

	if dist > 35.0:
		# Player fled into distant darkness
		current_state = State.INVESTIGATE
		target_investigate_pos = player_ref.global_position

func _process_stunned(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, run_speed * delta * 4.0)
	velocity.z = move_toward(velocity.z, 0.0, run_speed * delta * 4.0)

	stun_timer -= delta
	if stun_timer <= 0.0:
		_enter_chase()

func _process_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, run_speed * delta * 6.0)
	velocity.z = move_toward(velocity.z, 0.0, run_speed * delta * 6.0)

	state_timer -= delta
	if state_timer <= 0.0:
		# Deliver strike
		if player_ref and global_position.distance_to(player_ref.global_position) <= attack_range + 0.8:
			if player_ref.has_method("take_damage"):
				player_ref.take_damage(attack_damage)
		attack_timer = attack_cooldown
		current_state = State.CHASE

func _enter_chase() -> void:
	current_state = State.CHASE
	if sensory_mat:
		sensory_mat.emission_energy_multiplier = 3.2
		sensory_mat.emission = Color(1.0, 0.15, 0.08)
	stalker_alerted.emit(global_position)

func _enter_attack() -> void:
	current_state = State.ATTACK
	state_timer = 0.35
	# Rapid scythe lunge animation
	if left_claw:
		left_claw.rotation_degrees.x = -45.0
	if right_claw:
		right_claw.rotation_degrees.x = 45.0

func _check_lantern_photophobia(_delta: float) -> void:
	if player_ref == null or current_state == State.DEAD or current_state == State.STUNNED:
		return

	if "lantern" in player_ref and player_ref.lantern and player_ref.lantern.is_lit:
		var lantern = player_ref.lantern
		var l_pos = lantern.global_position
		var l_forward = -player_ref.camera.global_transform.basis.z if "camera" in player_ref and player_ref.camera else -player_ref.global_transform.basis.z
		var to_stalker = (global_position + Vector3(0, 0.9, 0) - l_pos)
		var dist = to_stalker.length()

		if dist < 14.0:
			var dot = l_forward.dot(to_stalker.normalized())
			if dot > 0.82: # Inside the high-beam cone of the lantern
				# Flinch and stun
				current_state = State.STUNNED
				stun_timer = 1.8
				velocity = -to_stalker.normalized() * 3.5 # Recoil backward
				if sensory_mat:
					sensory_mat.emission_energy_multiplier = 0.4

func _on_acoustic_noise_emitted(origin: Vector3, radius: float, _noise_type: String) -> void:
	if current_state == State.DEAD or current_state == State.CHASE:
		return

	var dist = global_position.distance_to(origin)
	if dist <= radius:
		# Hear vibration! Turn and investigate
		target_investigate_pos = origin
		current_state = State.INVESTIGATE
		if sensory_mat:
			sensory_mat.emission_energy_multiplier = 2.2

func take_damage(amount: float, hit_pos: Vector3, hit_normal: Vector3) -> void:
	if current_state == State.DEAD:
		return

	current_health -= amount
	# Knockback
	velocity += hit_normal * 4.2
	flinch_blend = 1.0

	if current_health <= 0.0:
		_die()
	else:
		_enter_chase()

func _die() -> void:
	current_state = State.DEAD
	collision_layer = 0
	collision_mask = 1
	stalker_died.emit(global_position)

	if sensory_mat:
		sensory_mat.emission_energy_multiplier = 0.0

	# Collapse animation (ragdoll tilt)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(model_root, "rotation_degrees:z", 85.0, 0.45).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(model_root, "position:y", 0.15, 0.45)

func _update_animation(delta: float) -> void:
	var horiz_speed = Vector2(velocity.x, velocity.z).length()
	if horiz_speed > 0.1:
		walk_cycle += delta * horiz_speed * 4.5
		if model_root:
			model_root.position.y = abs(sin(walk_cycle)) * 0.08
	else:
		walk_cycle = 0.0
		if model_root:
			model_root.position.y = lerp(model_root.position.y, 0.0, delta * 6.0)

	# Flinch recovery
	if flinch_blend > 0.0:
		flinch_blend = move_toward(flinch_blend, 0.0, delta * 3.5)
		if head_node:
			head_node.rotation_degrees.x = flinch_blend * 32.0
