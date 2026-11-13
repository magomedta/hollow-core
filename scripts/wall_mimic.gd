extends CharacterBody3D

const MobDeathEffects = preload("res://scripts/mob_death_effects.gd")

signal mimic_awakened(pos: Vector3)
signal mimic_died(pos: Vector3)

@export var max_health: float = 35.0
@export var current_health: float = 35.0
@export var attack_damage: float = 7.0
@export var lunge_speed: float = 2.8

enum MimicState {
	DORMANT_CAMOUFLAGE,
	AWAKENING,
	PURSUIT,
	DEAD
}

var current_state: MimicState = MimicState.DORMANT_CAMOUFLAGE
var player_ref: CharacterBody3D
var model_root: Node3D
var anim_time: float = 0.0
var awaken_timer: float = 0.0
var attack_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	_setup_collision()
	_load_model()
	_find_player()

func _setup_collision() -> void:
	collision_layer = 4 | 1 # Enemy + World hit detection so pickaxe can strike it
	collision_mask = 1
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.1, 1.1, 1.1)
	col.shape = box
	col.position = Vector3(0, 0.5, 0)
	add_child(col)

func _load_model() -> void:
	model_root = Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)
	var glb = load("res://models/wall_mimic.glb")
	if glb:
		var inst = glb.instantiate()
		model_root.add_child(inst)
		var bespoke_mat = StandardMaterial3D.new()
		var img = Image.load_from_file("res://textures/mobs/tex_wall_mimic.png")
		if img:
			bespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
		bespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		bespoke_mat.emission_enabled = true
		var emit_img = Image.load_from_file("res://textures/mobs/tex_wall_mimic_emit.png")
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
	if current_state == MimicState.DEAD:
		return

	if not is_on_floor() and current_state == MimicState.PURSUIT:
		velocity.y -= 19.6 * delta

	anim_time += delta
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if player_ref:
		var to_player = player_ref.global_position - global_position
		var dist = to_player.length()

		match current_state:
			MimicState.DORMANT_CAMOUFLAGE:
				# Camouflaged on cavern rock. Awaken if player comes within 3.2m or illuminates with lantern!
				velocity = Vector3.ZERO
				if dist < 3.2:
					_awaken()

			MimicState.AWAKENING:
				# Thrashing awake with horror screech
				awaken_timer -= delta
				if model_root:
					model_root.rotation.x = sin(anim_time * 24.0) * 0.15
					model_root.rotation.z = cos(anim_time * 24.0) * 0.15
				if awaken_timer <= 0.0:
					current_state = MimicState.PURSUIT

			MimicState.PURSUIT:
				# Feral scampering attack towards player
				var dir = Vector3(to_player.x, 0, to_player.z).normalized()
				velocity.x = dir.x * lunge_speed
				velocity.z = dir.z * lunge_speed
				rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), delta * 8.0)

				# Maw gnashing animation
				if model_root:
					model_root.position.y = abs(sin(anim_time * 14.0)) * 0.10
					model_root.rotation.x = sin(anim_time * 14.0) * 0.20

				if dist < 1.8 and attack_cooldown <= 0.0:
					attack_cooldown = 1.4
					if player_ref.has_method("take_damage"):
						player_ref.take_damage(attack_damage)
					var sm = get_tree().get_first_node_in_group("sound_manager")
					if sm and sm.has_method("play_sfx"):
						sm.play_sfx("monster_bite", global_position)

	move_and_slide()

func _awaken() -> void:
	current_state = MimicState.AWAKENING
	awaken_timer = 0.55
	mimic_awakened.emit(global_position)
	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("horror_sting", global_position)

func take_damage(amount: float, hit_pos: Vector3 = Vector3.ZERO, hit_normal: Vector3 = Vector3.UP) -> void:
	if current_state == MimicState.DORMANT_CAMOUFLAGE:
		_awaken()

	current_health -= amount
	if current_health <= 0.0:
		current_state = MimicState.DEAD
		mimic_died.emit(global_position)
		MobDeathEffects.play_death_effect(self, "stalker")
