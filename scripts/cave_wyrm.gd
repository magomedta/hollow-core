extends CharacterBody3D

const MobDeathEffects = preload("res://scripts/mob_death_effects.gd")

signal wyrm_died(pos: Vector3)

@export var max_health: float = 45.0
@export var current_health: float = 45.0
@export var burrow_speed: float = 1.9
@export var bite_damage: float = 7.0

var player_ref: CharacterBody3D
var model_root: Node3D
var bite_cooldown: float = 0.0
var anim_time: float = 0.0
var rear_up_factor: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	_setup_collision()
	_load_model()
	_find_player()

func _setup_collision() -> void:
	collision_layer = 4
	collision_mask = 1
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.55
	cap.height = 2.8
	col.shape = cap
	col.position = Vector3(0, 0.4, 0)
	add_child(col)

func _load_model() -> void:
	model_root = Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)
	var glb = load("res://models/cave_wyrm.glb")
	if glb:
		var inst = glb.instantiate()
		model_root.add_child(inst)
		var bespoke_mat = StandardMaterial3D.new()
		var img = Image.load_from_file("res://textures/mobs/tex_cave_wyrm.png")
		if img:
			bespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
		bespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		bespoke_mat.emission_enabled = true
		var emit_img = Image.load_from_file("res://textures/mobs/tex_cave_wyrm_emit.png")
		if emit_img:
			bespoke_mat.emission_texture = ImageTexture.create_from_image(emit_img)
		bespoke_mat.emission_energy_multiplier = 3.0
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
	if bite_cooldown > 0.0:
		bite_cooldown -= delta

	anim_time += delta
	var horiz_speed = Vector2(velocity.x, velocity.z).length()

	if player_ref:
		var to_player = player_ref.global_position - global_position
		to_player.y = 0.0
		var dist = to_player.length()

		if dist < 22.0 and dist > 2.4:
			var dir = to_player.normalized()
			velocity.x = dir.x * burrow_speed
			velocity.z = dir.z * burrow_speed
			rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), delta * 5.0)
			rear_up_factor = move_toward(rear_up_factor, 0.0, delta * 3.0)
		elif dist <= 2.5:
			# Close range: rear up head and deliver crushing chomp!
			rear_up_factor = move_toward(rear_up_factor, 1.0, delta * 4.0)
			velocity.x = move_toward(velocity.x, 0.0, delta * 6.0)
			velocity.z = move_toward(velocity.z, 0.0, delta * 6.0)
			if bite_cooldown <= 0.0:
				bite_cooldown = 1.8
				if player_ref.has_method("take_damage"):
					player_ref.take_damage(bite_damage)
				var sm = get_tree().get_first_node_in_group("sound_manager")
				if sm and sm.has_method("play_sfx"):
					sm.play_sfx("monster_bite", global_position)
		else:
			velocity.x = move_toward(velocity.x, 0.0, delta * 4.0)
			velocity.z = move_toward(velocity.z, 0.0, delta * 4.0)
			rear_up_factor = move_toward(rear_up_factor, 0.0, delta * 2.0)

	# PROCEDURAL SERPENTINE MOTION
	if model_root:
		if horiz_speed > 0.1:
			var wave = sin(anim_time * 6.5)
			model_root.rotation.y = wave * 0.22
			model_root.rotation.z = cos(anim_time * 6.5) * 0.08
			model_root.position.y = abs(sin(anim_time * 4.0)) * 0.06
		else:
			model_root.rotation.y = sin(anim_time * 1.5) * 0.06
			model_root.rotation.z = 0.0
			model_root.position.y = sin(anim_time * 2.0) * 0.02

		# Cobra-like rearing posture when striking
		model_root.rotation.x = -rear_up_factor * 0.45

	move_and_slide()

func take_damage(amount: float, hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> void:
	current_health -= amount
	# Violent thrash flinch
	if model_root:
		model_root.rotation.y += randf_range(-0.4, 0.4)
		model_root.rotation.z += randf_range(-0.3, 0.3)

	if current_health <= 0.0:
		wyrm_died.emit(global_position)
		MobDeathEffects.play_death_effect(self, "crawler")
