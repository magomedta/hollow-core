extends CharacterBody3D

const PixelTextureGenerator = preload("res://scripts/pixel_texture_generator.gd")
const MobDeathEffects = preload("res://scripts/mob_death_effects.gd")

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

@export var max_health: float = 40.0
@export var current_health: float = 40.0
@export var walk_speed: float = 1.4
@export var run_speed: float = 2.9
@export var attack_damage: float = 7.0
@export var attack_range: float = 2.2
@export var attack_cooldown: float = 1.8

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
var legs: Array[Node3D] = []
var tibias: Array[Node3D] = []
var feet: Array[Node3D] = []
var leg_base_positions: Array[Vector3] = []

# Animation phases
var walk_cycle: float = 0.0
var flinch_blend: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	_setup_collision()
	_construct_chasm_stalker_mesh()
	_find_player()

func _setup_collision() -> void:
	collision_layer = 4
	collision_mask = 1
	var col = CollisionShape3D.new()
	col.name = "Collision"
	var cap = CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.6
	col.shape = cap
	col.position = Vector3(0, 0.85, 0)
	add_child(col)

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

	var glb_res = load("res://models/chasm_stalker.glb")
	if glb_res:
		var glb_inst = glb_res.instantiate()
		glb_inst.name = "BlenderHighDetailMesh"
		model_root.add_child(glb_inst)
		
		var bespoke_mat = StandardMaterial3D.new()
		var img = Image.load_from_file("res://textures/mobs/tex_chasm_stalker.png")
		if img:
			bespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
		bespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		bespoke_mat.emission_enabled = true
		var emit_img = Image.load_from_file("res://textures/mobs/tex_chasm_stalker_emit.png")
		if emit_img:
			bespoke_mat.emission_texture = ImageTexture.create_from_image(emit_img)
		bespoke_mat.emission_energy_multiplier = 3.5
		
		_apply_material_recursive(glb_inst, bespoke_mat)

func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node
		mi.material_override = mat
	for child in node.get_children():
		_apply_material_recursive(child, mat)

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

func take_damage(amount: float, hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> void:
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
	stalker_died.emit(global_position)
	MobDeathEffects.play_death_effect(self, "stalker")

func _update_animation(delta: float) -> void:
	var horiz_speed = Vector2(velocity.x, velocity.z).length()
	if horiz_speed > 0.1:
		walk_cycle += delta * horiz_speed * 4.5
		if model_root:
			model_root.position.y = abs(sin(walk_cycle)) * 0.06
			model_root.rotation.z = sin(walk_cycle * 0.5) * 0.05
			model_root.rotation.x = cos(walk_cycle) * 0.03
		# Articulated alternating quadruped leg animation through hip, knee, and ankle joints
		for i in range(legs.size()):
			var leg = legs[i]
			if not is_instance_valid(leg): continue
			var phase = (PI if (i % 2 == 1) else 0.0)
			var swing = sin(walk_cycle + phase) * 18.0
			var knee_flex = max(0.0, cos(walk_cycle + phase)) * 16.0
			leg.rotation_degrees.x = swing
			if i < tibias.size() and is_instance_valid(tibias[i]):
				tibias[i].rotation_degrees.x = -knee_flex
			if i < feet.size() and is_instance_valid(feet[i]):
				feet[i].rotation_degrees.x = knee_flex * 0.6 - swing * 0.4
	else:
		walk_cycle = 0.0
		if model_root:
			model_root.position.y = sin(state_timer * 1.8) * 0.02
			model_root.rotation.z = lerp(model_root.rotation.z, 0.0, delta * 6.0)
			model_root.rotation.x = lerp(model_root.rotation.x, 0.0, delta * 6.0)
		for i in range(legs.size()):
			var leg = legs[i]
			if not is_instance_valid(leg): continue
			leg.rotation_degrees.x = move_toward(leg.rotation_degrees.x, 0.0, delta * 45.0)
			if i < tibias.size() and is_instance_valid(tibias[i]):
				tibias[i].rotation_degrees.x = move_toward(tibias[i].rotation_degrees.x, 0.0, delta * 45.0)
			if i < feet.size() and is_instance_valid(feet[i]):
				feet[i].rotation_degrees.x = move_toward(feet[i].rotation_degrees.x, 0.0, delta * 45.0)

	# Flinch recovery
	if flinch_blend > 0.0:
		flinch_blend = move_toward(flinch_blend, 0.0, delta * 3.5)
		if head_node:
			head_node.rotation_degrees.x = flinch_blend * 32.0
