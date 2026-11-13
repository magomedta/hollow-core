# scripts/lithic_crawler.gd
# Multi-Legged Subterranean Lithic Crawler
# Features:
# - Low-slung multi-legged arthropod that scuttles across cavern floors
# - Segmented rock carapace with articulated legs animated in natural tripod gait
# - Highly sensitive to acoustic vibrations: reacts to pickaxe mining strikes from up to 28m away!
# - Glowing amber sensor antennae that flicker and scan the darkness
# - Leap attack with clicking mandibles; takes damage from pickaxe strikes

class_name LithicCrawler
extends CharacterBody3D

const PixelTextureGenerator = preload("res://scripts/pixel_texture_generator.gd")
const MobDeathEffects = preload("res://scripts/mob_death_effects.gd")

signal crawler_alerted(pos: Vector3)
signal crawler_died(pos: Vector3)

enum State {
	IDLE,
	PATROL,
	INVESTIGATE,
	CHASE,
	ATTACK,
	FLEE,
	DEAD
}

@export var max_health: float = 35.0
@export var current_health: float = 35.0
@export var walk_speed: float = 1.4
@export var sprint_speed: float = 3.2
@export var attack_damage: float = 8.0
@export var attack_range: float = 1.8
@export var attack_cooldown: float = 1.6

var current_state: State = State.IDLE
var target_pos: Vector3 = Vector3.ZERO
var state_timer: float = 0.0
var attack_timer: float = 0.0
var flee_timer: float = 0.0

var player_ref: CharacterBody3D
var model_root: Node3D
var legs: Array[Node3D] = []
var crawler_knees: Array[Node3D] = []
var crawler_claws: Array[Node3D] = []
var mandibles_left: MeshInstance3D
var mandibles_right: MeshInstance3D
var sensor_eyes: MeshInstance3D
var eye_mat: StandardMaterial3D

var walk_cycle: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	_construct_crawler_mesh()
	_setup_collision()
	_find_player()

func _setup_collision() -> void:
	collision_layer = 4 # Enemy layer
	collision_mask = 1 # Collides with voxel terrain

	var coll = CollisionShape3D.new()
	coll.name = "CrawlerColl"
	var box = BoxShape3D.new()
	box.size = Vector3(0.9, 0.45, 1.1)
	coll.shape = box
	coll.position = Vector3(0, 0.25, 0)
	add_child(coll)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
		if player_ref.has_signal("acoustic_noise_emitted"):
			player_ref.acoustic_noise_emitted.connect(_on_acoustic_noise_emitted)

func _construct_crawler_mesh() -> void:
	model_root = Node3D.new()
	model_root.name = "CrawlerModel"
	add_child(model_root)

	var glb_res = load("res://models/lithic_crawler.glb")
	if glb_res:
		var glb_inst = glb_res.instantiate()
		glb_inst.name = "BlenderHighDetailMesh"
		model_root.add_child(glb_inst)
		
		var bespoke_mat = StandardMaterial3D.new()
		var img = Image.load_from_file("res://textures/mobs/tex_lithic_crawler.png")
		if img:
			bespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
		bespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		bespoke_mat.emission_enabled = true
		var emit_img = Image.load_from_file("res://textures/mobs/tex_lithic_crawler_emit.png")
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
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0

	attack_timer = max(0.0, attack_timer - delta)
	state_timer += delta

	if player_ref == null:
		_find_player()

	_update_ai_state(delta)
	_animate_legs(delta)
	move_and_slide()

func _update_ai_state(delta: float) -> void:
	if player_ref == null:
		return

	var to_player = player_ref.global_position - global_position
	var dist_to_player = to_player.length()

	match current_state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
			if dist_to_player < 14.0:
				current_state = State.CHASE
			elif state_timer > 3.0:
				state_timer = 0.0
				current_state = State.PATROL
				var rand_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
				target_pos = global_position + rand_dir * randf_range(4, 8)

		State.PATROL:
			var to_target = target_pos - global_position
			to_target.y = 0.0
			if to_target.length() < 0.8 or state_timer > 5.0:
				current_state = State.IDLE
				state_timer = 0.0
			else:
				var move_dir = to_target.normalized()
				velocity.x = move_dir.x * walk_speed
				velocity.z = move_dir.z * walk_speed
				_look_toward(global_position + move_dir, delta)

			if dist_to_player < 12.0:
				current_state = State.CHASE

		State.INVESTIGATE:
			var to_target = target_pos - global_position
			to_target.y = 0.0
			if to_target.length() < 1.2 or state_timer > 8.0:
				current_state = State.IDLE
				state_timer = 0.0
			else:
				var move_dir = to_target.normalized()
				velocity.x = move_dir.x * sprint_speed * 0.8
				velocity.z = move_dir.z * sprint_speed * 0.8
				_look_toward(global_position + move_dir, delta)

			if dist_to_player < 10.0:
				current_state = State.CHASE

		State.CHASE:
			var move_dir = to_player
			move_dir.y = 0.0
			move_dir = move_dir.normalized()
			velocity.x = move_dir.x * sprint_speed
			velocity.z = move_dir.z * sprint_speed
			_look_toward(global_position + move_dir, delta)

			if dist_to_player <= attack_range and attack_timer <= 0.0:
				current_state = State.ATTACK
				state_timer = 0.0
			elif dist_to_player > 22.0:
				current_state = State.IDLE
				state_timer = 0.0

		State.ATTACK:
			# Lunge forward and bite
			var move_dir = to_player
			move_dir.y = 0.0
			move_dir = move_dir.normalized()
			velocity.x = move_dir.x * (sprint_speed * 1.4)
			velocity.z = move_dir.z * (sprint_speed * 1.4)

			if state_timer < 0.25:
				if mandibles_left: mandibles_left.rotation_degrees.y = -45
				if mandibles_right: mandibles_right.rotation_degrees.y = 45
			elif state_timer < 0.50:
				# Snap shut
				if mandibles_left: mandibles_left.rotation_degrees.y = 10
				if mandibles_right: mandibles_right.rotation_degrees.y = -10
				if dist_to_player <= attack_range + 0.4:
					if player_ref.has_method("take_damage"):
						player_ref.take_damage(attack_damage, global_position)
			else:
				attack_timer = attack_cooldown
				current_state = State.CHASE
				state_timer = 0.0

		State.FLEE:
			flee_timer -= delta
			var away_dir = -to_player
			away_dir.y = 0.0
			away_dir = away_dir.normalized()
			velocity.x = away_dir.x * (sprint_speed * 1.2)
			velocity.z = away_dir.z * (sprint_speed * 1.2)
			_look_toward(global_position + away_dir, delta)
			if flee_timer <= 0.0:
				current_state = State.IDLE
				state_timer = 0.0

func _look_toward(target: Vector3, delta: float) -> void:
	var look_pos = Vector3(target.x, global_position.y, target.z)
	if global_position.distance_squared_to(look_pos) > 0.01:
		var target_xform = transform.looking_at(look_pos, Vector3.UP)
		transform.basis = transform.basis.slerp(target_xform.basis, 8.0 * delta)

func _animate_legs(delta: float) -> void:
	var horizontal_spd = Vector2(velocity.x, velocity.z).length()
	if horizontal_spd > 0.1:
		walk_cycle += delta * horizontal_spd * 6.5
		if model_root:
			model_root.position.y = abs(sin(walk_cycle * 2.0)) * 0.04
			model_root.rotation.z = sin(walk_cycle) * 0.04
		# Tripod gait animation across the 6 legs: 3 legs lift, 3 remain firmly planted
		for i in range(legs.size()):
			var leg = legs[i]
			if not is_instance_valid(leg):
				continue
			var phase_offset = (PI if (i % 2 == 1) else 0.0)
			var swing = sin(walk_cycle + phase_offset) * 16.0
			var knee_flex = max(0.0, cos(walk_cycle + phase_offset)) * 14.0
			leg.rotation_degrees.y = swing
			if i < crawler_knees.size() and is_instance_valid(crawler_knees[i]):
				crawler_knees[i].rotation_degrees.x = -knee_flex
			if i < crawler_claws.size() and is_instance_valid(crawler_claws[i]):
				crawler_claws[i].rotation_degrees.x = knee_flex * 0.7
	else:
		walk_cycle = 0.0
		if model_root:
			model_root.position.y = sin(state_timer * 2.2) * 0.015
			model_root.rotation.z = lerp(model_root.rotation.z, 0.0, delta * 6.0)
		for i in range(legs.size()):
			var leg = legs[i]
			if not is_instance_valid(leg):
				continue
			leg.rotation_degrees.y = move_toward(leg.rotation_degrees.y, 0.0, delta * 30.0)
			if i < crawler_knees.size() and is_instance_valid(crawler_knees[i]):
				crawler_knees[i].rotation_degrees.x = move_toward(crawler_knees[i].rotation_degrees.x, 0.0, delta * 30.0)
			if i < crawler_claws.size() and is_instance_valid(crawler_claws[i]):
				crawler_claws[i].rotation_degrees.x = move_toward(crawler_claws[i].rotation_degrees.x, 0.0, delta * 30.0)

func _on_acoustic_noise_emitted(origin: Vector3, radius: float, noise_type: String) -> void:
	# Pickaxe mining strikes produce vibrations through bedrock that crawlers feel!
	var dist = global_position.distance_to(origin)
	if dist <= radius and current_state != State.CHASE and current_state != State.ATTACK:
		target_pos = origin
		current_state = State.INVESTIGATE
		state_timer = 0.0
		crawler_alerted.emit(global_position)

func take_damage(amount: float, from_pos: Vector3) -> void:
	current_health -= amount
	# Flinch away
	current_state = State.FLEE
	flee_timer = 2.5
	if current_health <= 0.0:
		_die()

func _die() -> void:
	current_state = State.DEAD
	crawler_died.emit(global_position)
	MobDeathEffects.play_death_effect(self, "crawler")
