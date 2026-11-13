extends CharacterBody3D

const MobDeathEffects = preload("res://scripts/mob_death_effects.gd")

signal golem_died(pos: Vector3)

@export var max_health: float = 75.0
@export var current_health: float = 75.0
@export var move_speed: float = 1.1
@export var attack_damage: float = 12.0
@export var slam_radius: float = 3.8

var player_ref: CharacterBody3D
var model_root: Node3D
var slam_cooldown: float = 0.0
var walk_cycle: float = 0.0
var slam_windup: float = 0.0
var is_slamming: bool = false

func _ready() -> void:
	add_to_group("enemies")
	_setup_collision()
	_load_model()
	_find_player()

func _setup_collision() -> void:
	collision_layer = 4
	collision_mask = 1
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.6, 2.5, 1.4)
	col.shape = box
	col.position = Vector3(0, 1.25, 0)
	add_child(col)

func _load_model() -> void:
	model_root = Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)
	var glb = load("res://models/geode_golem.glb")
	if glb:
		var inst = glb.instantiate()
		model_root.add_child(inst)
		var bespoke_mat = StandardMaterial3D.new()
		var img = Image.load_from_file("res://textures/mobs/tex_geode_golem.png")
		if img:
			bespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
		bespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		bespoke_mat.emission_enabled = true
		var emit_img = Image.load_from_file("res://textures/mobs/tex_geode_golem_emit.png")
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

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	if slam_cooldown > 0.0:
		slam_cooldown -= delta

	var horiz_speed = Vector2(velocity.x, velocity.z).length()

	if player_ref:
		var to_player = player_ref.global_position - global_position
		to_player.y = 0.0
		var dist = to_player.length()

		if not is_slamming:
			if dist < 24.0 and dist > 3.2:
				var dir = to_player.normalized()
				velocity.x = dir.x * move_speed
				velocity.z = dir.z * move_speed
				rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), delta * 3.0)
			elif dist <= 3.4 and slam_cooldown <= 0.0:
				velocity.x = 0.0
				velocity.z = 0.0
				_start_ground_slam()
			else:
				velocity.x = move_toward(velocity.x, 0.0, delta * 4.0)
				velocity.z = move_toward(velocity.z, 0.0, delta * 4.0)
		else:
			# Processing slam attack animation
			slam_windup += delta * 2.5
			if slam_windup >= 1.0:
				_execute_slam_impact()

	# PROCEDURAL LUMBERING LOCOMOTION ANIMATION
	if model_root:
		if is_slamming:
			if slam_windup < 0.6:
				# Rearing up high with fist raised
				model_root.rotation.x = lerp(model_root.rotation.x, -0.45, delta * 8.0)
				model_root.position.y = lerp(model_root.position.y, 0.35, delta * 8.0)
			else:
				# Violent downward ground slam
				model_root.rotation.x = lerp(model_root.rotation.x, 0.35, delta * 16.0)
				model_root.position.y = lerp(model_root.position.y, -0.15, delta * 16.0)
		elif horiz_speed > 0.1:
			walk_cycle += delta * 3.2
			# Heavy side-to-side weight transfer
			model_root.rotation.z = sin(walk_cycle) * 0.12
			model_root.rotation.x = cos(walk_cycle * 2.0) * 0.04
			model_root.position.y = abs(sin(walk_cycle)) * 0.12
		else:
			walk_cycle = 0.0
			model_root.rotation.z = lerp(model_root.rotation.z, 0.0, delta * 5.0)
			model_root.rotation.x = lerp(model_root.rotation.x, 0.0, delta * 5.0)
			model_root.position.y = lerp(model_root.position.y, 0.0, delta * 5.0)

	move_and_slide()

func _start_ground_slam() -> void:
	is_slamming = true
	slam_windup = 0.0

func _execute_slam_impact() -> void:
	is_slamming = false
	slam_windup = 0.0
	slam_cooldown = 3.2

	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("explosion", global_position)

	if player_ref:
		var dist = global_position.distance_to(player_ref.global_position)
		if dist <= slam_radius:
			if player_ref.has_method("take_damage"):
				player_ref.take_damage(attack_damage)
		# Cavern floor tremors
		if dist < 14.0 and "camera" in player_ref:
			# Shockwave shudder
			player_ref.velocity.y += 3.5

func take_damage(amount: float, hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> void:
	# Heavy stone armor absorbs damage
	current_health -= (amount * 0.75)
	if model_root:
		model_root.position.y -= 0.08

	if current_health <= 0.0:
		golem_died.emit(global_position)
		MobDeathEffects.play_death_effect(self, "golem")
