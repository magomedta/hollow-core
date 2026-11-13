# scripts/cryo_wisp.gd
# Ethereal Surface Cryosphere & Glacial Ice Phantom
# Features:
# - Floats silently above permafrost snowdrifts and subglacial ice caves
# - Spectral cyan bioluminescent nucleus surrounded by orbiting crystalline frost rings
# - Dynamic cold mist emitter and pale azure omni-light
# - Silently stalks the explorer through blizzard fog; lunges with a hypothermic cryo-blast
# - Disperses when struck by pickaxe

class_name CryoWisp
extends CharacterBody3D

const MobDeathEffects = preload("res://scripts/mob_death_effects.gd")

signal wisp_dispersed(pos: Vector3)

enum State {
	DRIFT,
	STALK,
	LUNGE,
	DISPERSED
}

@export var max_health: float = 25.0
@export var current_health: float = 25.0
@export var drift_speed: float = 1.8
@export var lunge_speed: float = 3.8
@export var frost_damage: float = 7.0

var current_state: State = State.DRIFT
var player_ref: CharacterBody3D
var model_root: Node3D
var nucleus: MeshInstance3D
var ring_outer: MeshInstance3D
var ring_inner: MeshInstance3D
var frost_light: OmniLight3D
var mist_particles: CPUParticles3D

var float_phase: float = 0.0
var state_timer: float = 0.0
var lunge_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	_setup_collision()
	_construct_wisp_mesh()
	_find_player()

func _setup_collision() -> void:
	collision_layer = 4
	collision_mask = 1

	var coll = CollisionShape3D.new()
	coll.name = "WispColl"
	var sph = SphereShape3D.new()
	sph.radius = 0.65
	coll.shape = sph
	add_child(coll)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func _construct_wisp_mesh() -> void:
	model_root = Node3D.new()
	model_root.name = "WispModel"
	add_child(model_root)

	# High-Detail Blender 4.0 PBR 3D Model Instance with Bespoke 256x256 Pixel Texture
	var glb_res = load("res://models/cryo_wisp.glb")
	if glb_res:
		var glb_inst = glb_res.instantiate()
		glb_inst.name = "BlenderHighDetailMesh"
		model_root.add_child(glb_inst)
		
		var bespoke_mat = StandardMaterial3D.new()
		var img = Image.load_from_file("res://textures/mobs/tex_cryo_wisp.png")
		if img:
			bespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
		bespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		bespoke_mat.emission_enabled = true
		var emit_img = Image.load_from_file("res://textures/mobs/tex_cryo_wisp_emit.png")
		if emit_img:
			bespoke_mat.emission_texture = ImageTexture.create_from_image(emit_img)
		bespoke_mat.emission_energy_multiplier = 4.0
		_apply_material_recursive(glb_inst, bespoke_mat)
		
		# Cold Pale Cyan Light
		frost_light = OmniLight3D.new()
		frost_light.name = "FrostGlow"
		frost_light.light_color = Color(0.4, 0.85, 1.0)
		frost_light.light_energy = 2.2
		frost_light.omni_range = 6.0
		model_root.add_child(frost_light)
		return

func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node
		mi.material_override = mat
	for child in node.get_children():
		_apply_material_recursive(child, mat)

func _physics_process(delta: float) -> void:
	if current_state == State.DISPERSED:
		return

	float_phase += delta * 2.8
	state_timer += delta
	lunge_cooldown = max(0.0, lunge_cooldown - delta)

	# Sinusoidal vertical hover & ring orbit
	if model_root:
		model_root.position.y = sin(float_phase) * 0.18
	if ring_outer:
		ring_outer.rotation_degrees.x += 45.0 * delta
		ring_outer.rotation_degrees.y += 30.0 * delta
	if ring_inner:
		ring_inner.rotation_degrees.x -= 35.0 * delta
		ring_inner.rotation_degrees.z += 55.0 * delta

	if player_ref == null:
		_find_player()

	_update_ai(delta)
	move_and_slide()

func _update_ai(delta: float) -> void:
	if player_ref == null:
		return

	var to_player = player_ref.global_position - global_position
	var dist = to_player.length()

	match current_state:
		State.DRIFT:
			# Gentle wander around current spot
			var drift_dir = Vector3(cos(float_phase * 0.5), 0.1, sin(float_phase * 0.7)).normalized()
			velocity = velocity.lerp(drift_dir * drift_speed, 2.0 * delta)
			if dist < 18.0:
				current_state = State.STALK
				state_timer = 0.0

		State.STALK:
			# Hover toward player at head level (aim ~1.5m above player feet)
			var target_hover = player_ref.global_position + Vector3(0, 1.4, 0)
			var move_dir = (target_hover - global_position).normalized()
			velocity = velocity.lerp(move_dir * (drift_speed * 1.5), 3.0 * delta)

			if dist < 3.8 and lunge_cooldown <= 0.0:
				current_state = State.LUNGE
				state_timer = 0.0
			elif dist > 26.0:
				current_state = State.DRIFT

		State.LUNGE:
			# High-speed frost charge directly through player
			var lunge_target = player_ref.global_position + Vector3(0, 1.2, 0)
			var lunge_dir = (lunge_target - global_position).normalized()
			velocity = lunge_dir * lunge_speed

			if dist < 1.6 and state_timer < 0.6:
				if player_ref.has_method("take_damage"):
					player_ref.take_damage(frost_damage, global_position)
				if "core_temperature" in player_ref:
					player_ref.core_temperature = max(-30.0, player_ref.core_temperature - 12.0)

			if state_timer >= 0.8:
				lunge_cooldown = 2.4
				current_state = State.STALK
				state_timer = 0.0

func take_damage(amount: float, _from_pos: Vector3) -> void:
	current_health -= amount
	if current_health <= 0.0:
		_disperse()

func _disperse() -> void:
	current_state = State.DISPERSED
	wisp_dispersed.emit(global_position)
	if frost_light:
		frost_light.light_energy = 0.0
	if mist_particles:
		mist_particles.emitting = false
	MobDeathEffects.play_death_effect(self, "cryo")
