extends StaticBody3D

const MobDeathEffects = preload("res://scripts/mob_death_effects.gd")

signal spitter_destroyed(pos: Vector3)

@export var max_health: float = 30.0
@export var current_health: float = 30.0
@export var spit_range: float = 16.0
@export var acid_damage: float = 6.0

var player_ref: CharacterBody3D
var model_root: Node3D
var spit_cooldown: float = 0.0
var anim_time: float = 0.0
var swell_charge: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	_setup_collision()
	_load_model()
	_find_player()

func _setup_collision() -> void:
	collision_layer = 4
	collision_mask = 1
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 0.8
	cyl.height = 1.8
	col.shape = cyl
	col.position = Vector3(0, 0.9, 0)
	add_child(col)

func _load_model() -> void:
	model_root = Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)
	var glb = load("res://models/spore_spitter.glb")
	if glb:
		var inst = glb.instantiate()
		model_root.add_child(inst)
		var bespoke_mat = StandardMaterial3D.new()
		var img = Image.load_from_file("res://textures/mobs/tex_spore_spitter.png")
		if img:
			bespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
		bespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		bespoke_mat.emission_enabled = true
		var emit_img = Image.load_from_file("res://textures/mobs/tex_spore_spitter_emit.png")
		if emit_img:
			bespoke_mat.emission_texture = ImageTexture.create_from_image(emit_img)
		bespoke_mat.emission_energy_multiplier = 3.5
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

func _process(delta: float) -> void:
	anim_time += delta
	if spit_cooldown > 0.0:
		spit_cooldown -= delta

	# Track player with nozzle
	if player_ref:
		var to_player = player_ref.global_position - global_position
		to_player.y = 0.0
		var dist = to_player.length()

		if dist <= spit_range:
			var target_rot = atan2(-to_player.x, -to_player.z)
			rotation.y = lerp_angle(rotation.y, target_rot, delta * 3.0)

			# Build up acid pressure when cooldown is nearing end
			if spit_cooldown < 0.6:
				swell_charge = move_toward(swell_charge, 1.0, delta * 2.5)
			else:
				swell_charge = move_toward(swell_charge, 0.0, delta * 4.0)

			if spit_cooldown <= 0.0:
				_spit_acid_burst()
		else:
			swell_charge = move_toward(swell_charge, 0.0, delta * 2.0)

	# PROCEDURAL BULB SWELL & RESPIRATION ANIMATION
	if model_root:
		var breath = sin(anim_time * 2.4) * 0.03
		var total_swell = swell_charge * 0.18 + breath
		model_root.scale = Vector3(1.0 + total_swell, 1.0 + total_swell * 1.2, 1.0 + total_swell)
		model_root.rotation.z = sin(anim_time * 1.8) * 0.03

func _spit_acid_burst() -> void:
	spit_cooldown = 2.8
	swell_charge = -0.3 # Sharp contraction recoil!

	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("acid_spit", global_position)

	# Spawn visual acid projectile
	_spawn_acid_glob()

func _spawn_acid_glob() -> void:
	if player_ref == null:
		return

	var to_player = (player_ref.global_position + Vector3(0, 1.0, 0)) - (global_position + Vector3(0, 1.6, 0))
	var dist = to_player.length()

	# Line-of-sight raycast check
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 1.6, 0), player_ref.global_position + Vector3(0, 1.0, 0), 1, [self])
	var hit = space.intersect_ray(query)

	# If clear line of sight, apply acid damage and corrosion effect
	if hit.is_empty():
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(acid_damage)

func take_damage(amount: float, hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> void:
	current_health -= amount
	# Spasm on impact
	if model_root:
		model_root.scale = Vector3(0.85, 0.85, 0.85)

	if current_health <= 0.0:
		spitter_destroyed.emit(global_position)
		MobDeathEffects.play_death_effect(self, "spitter")
