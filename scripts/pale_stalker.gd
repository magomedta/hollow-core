extends CharacterBody3D

const MobDeathEffects = preload("res://scripts/mob_death_effects.gd")

signal lurker_screeched(pos: Vector3)

@export var max_health: float = 35.0
@export var current_health: float = 35.0
@export var crawl_speed: float = 2.4
@export var stalk_speed: float = 1.0
@export var attack_damage: float = 8.0

enum HorrorState {
	CEILING_PERCH,
	STALKING_SHADOWS,
	FROZEN_TERROR,
	FRENZIED_RUSH,
	DEAD
}

var current_state: HorrorState = HorrorState.STALKING_SHADOWS
var player_ref: CharacterBody3D
var model_root: Node3D
var twitch_timer: float = 0.0
var screech_timer: float = 0.0

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
	cap.radius = 0.4
	cap.height = 1.8
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	add_child(col)

func _load_model() -> void:
	model_root = Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)
	var glb = load("res://models/pale_lurker.glb")
	if glb:
		var inst = glb.instantiate()
		model_root.add_child(inst)
		var bespoke_mat = StandardMaterial3D.new()
		var img = Image.load_from_file("res://textures/mobs/tex_pale_lurker.png")
		if img:
			bespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
		bespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		bespoke_mat.emission_enabled = true
		var emit_img = Image.load_from_file("res://textures/mobs/tex_pale_lurker_emit.png")
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

func _physics_process(delta: float) -> void:
	if current_state == HorrorState.DEAD:
		return

	if not is_on_floor() and current_state != HorrorState.CEILING_PERCH:
		velocity.y -= 19.6 * delta

	# Horror Twitching / Jitter Animation
	twitch_timer += delta * 12.0
	if model_root and current_state != HorrorState.DEAD:
		model_root.rotation.z = sin(twitch_timer * 3.5) * 0.06
		model_root.rotation.x = cos(twitch_timer * 4.2) * 0.04

	if player_ref:
		var to_player = player_ref.global_position - global_position
		var dist = to_player.length()
		var dir_horiz = Vector3(to_player.x, 0, to_player.z).normalized()

		# Check if lantern light is directly revealing the lurker
		var illuminated_by_lantern = false
		if "lantern" in player_ref and player_ref.lantern and player_ref.lantern.is_lit:
			var cam = player_ref.camera if "camera" in player_ref else null
			if cam:
				var cam_fwd = -cam.global_transform.basis.z
				var to_lurker = (global_position + Vector3(0, 1.2, 0) - cam.global_position).normalized()
				if cam_fwd.dot(to_lurker) > 0.85 and dist < 16.0:
					illuminated_by_lantern = true

		match current_state:
			HorrorState.STALKING_SHADOWS:
				# Creeps just outside illumination radius (10-18m)
				if illuminated_by_lantern:
					# Caught in direct beam! Freeze in terror, neck twitches, then rush!
					current_state = HorrorState.FROZEN_TERROR
					screech_timer = 0.8
					lurker_screeched.emit(global_position)
				elif dist > 14.0:
					velocity.x = dir_horiz.x * stalk_speed
					velocity.z = dir_horiz.z * stalk_speed
					rotation.y = lerp_angle(rotation.y, atan2(-dir_horiz.x, -dir_horiz.z), delta * 4.0)
				else:
					velocity.x = move_toward(velocity.x, 0.0, delta * 3.0)
					velocity.z = move_toward(velocity.z, 0.0, delta * 3.0)

			HorrorState.FROZEN_TERROR:
				velocity.x = 0.0
				velocity.z = 0.0
				screech_timer -= delta
				rotation.y = lerp_angle(rotation.y, atan2(-dir_horiz.x, -dir_horiz.z), delta * 12.0)
				if screech_timer <= 0.0:
					current_state = HorrorState.FRENZIED_RUSH

			HorrorState.FRENZIED_RUSH:
				# Violent scuttling charge!
				velocity.x = dir_horiz.x * crawl_speed
				velocity.z = dir_horiz.z * crawl_speed
				rotation.y = lerp_angle(rotation.y, atan2(-dir_horiz.x, -dir_horiz.z), delta * 10.0)
				if dist < 1.6:
					if player_ref.has_method("take_damage"):
						player_ref.take_damage(attack_damage)
					# Retreat into shadows after strike
					current_state = HorrorState.STALKING_SHADOWS
					velocity = -dir_horiz * 5.0

	move_and_slide()

func take_damage(amount: float, _hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> void:
	current_health -= amount
	velocity += hit_normal * 4.0
	current_state = HorrorState.FRENZIED_RUSH # Retaliates violently
	if current_health <= 0.0:
		current_state = HorrorState.DEAD
		MobDeathEffects.play_death_effect(self, "lurker")
