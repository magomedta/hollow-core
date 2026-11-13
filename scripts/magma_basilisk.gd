extends CharacterBody3D

const MobDeathEffects = preload("res://scripts/mob_death_effects.gd")

signal basilisk_died(pos: Vector3)

@export var max_health: float = 45.0
@export var current_health: float = 45.0
@export var move_speed: float = 2.2
@export var attack_damage: float = 8.0
@export var attack_range: float = 2.4

var player_ref: CharacterBody3D
var model_root: Node3D
var attack_cooldown: float = 0.0
var crawl_time: float = 0.0
var lunge_factor: float = 0.0

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
	box.size = Vector3(1.2, 0.7, 2.0)
	col.shape = box
	col.position = Vector3(0, 0.35, 0)
	add_child(col)

func _load_model() -> void:
	model_root = Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)
	var glb = load("res://models/magma_basilisk.glb")
	if glb:
		var inst = glb.instantiate()
		model_root.add_child(inst)
		var bespoke_mat = StandardMaterial3D.new()
		var img = Image.load_from_file("res://textures/mobs/tex_magma_basilisk.png")
		if img:
			bespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
		bespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		bespoke_mat.emission_enabled = true
		var emit_img = Image.load_from_file("res://textures/mobs/tex_magma_basilisk_emit.png")
		if emit_img:
			bespoke_mat.emission_texture = ImageTexture.create_from_image(emit_img)
		bespoke_mat.emission_energy_multiplier = 3.6
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
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	crawl_time += delta
	var horiz_speed = Vector2(velocity.x, velocity.z).length()

	if player_ref:
		var to_player = player_ref.global_position - global_position
		to_player.y = 0.0
		var dist = to_player.length()

		if dist < 20.0 and dist > attack_range:
			var dir = to_player.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
			rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), delta * 6.0)
			lunge_factor = move_toward(lunge_factor, 0.0, delta * 3.0)
		elif dist <= attack_range and attack_cooldown <= 0.0:
			velocity.x = 0.0
			velocity.z = 0.0
			_attack_player()
		else:
			velocity.x = move_toward(velocity.x, 0.0, delta * 5.0)
			velocity.z = move_toward(velocity.z, 0.0, delta * 5.0)
			lunge_factor = move_toward(lunge_factor, 0.0, delta * 3.0)

	# PROCEDURAL REPTILIAN SINUOUS MOTION
	if model_root:
		if lunge_factor > 0.0:
			model_root.rotation.x = -lunge_factor * 0.35
			model_root.position.z = -lunge_factor * 0.30
		elif horiz_speed > 0.1:
			var wave = sin(crawl_time * 8.5)
			model_root.rotation.y = wave * 0.18
			model_root.rotation.z = cos(crawl_time * 8.5) * 0.06
			model_root.position.y = abs(sin(crawl_time * 4.0)) * 0.04
		else:
			model_root.rotation.y = sin(crawl_time * 1.5) * 0.04
			model_root.rotation.z = 0.0
			model_root.position.y = sin(crawl_time * 2.0) * 0.015

	move_and_slide()

func _attack_player() -> void:
	attack_cooldown = 1.6
	lunge_factor = 1.0

	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("monster_bite", global_position)

	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(attack_damage)

func take_damage(amount: float, hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> void:
	current_health -= amount
	if model_root:
		model_root.rotation.y += randf_range(-0.3, 0.3)

	if current_health <= 0.0:
		basilisk_died.emit(global_position)
		MobDeathEffects.play_death_effect(self, "basilisk")
