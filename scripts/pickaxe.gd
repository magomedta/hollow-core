# scripts/pickaxe.gd
extends Node3D

const PixelTextureGenerator = preload("res://scripts/pixel_texture_generator.gd")

signal hit_landed(collider: Object, hit_point: Vector3, hit_normal: Vector3)

enum PickaxeTier {
	WOODEN = 1,
	STONE = 2,
	STEEL = 3
}

@export var tier: PickaxeTier = PickaxeTier.WOODEN
@export var damage: float = 30.0
@export var reach_distance: float = 3.8
@export var swing_speed: float = 2.6

var is_active: bool = false
var is_swinging: bool = false
var swing_timer: float = 0.0
var swing_cooldown_timer: float = 0.0
const SWING_COOLDOWN_DURATION: float = 0.04
var has_hit_in_current_swing: bool = false

var natural_pos: Vector3 = Vector3(0.24, -0.20, -0.40)
var natural_rot: Vector3 = Vector3(-6.0, 22.0, -12.0)
var current_sway_rot: Vector3 = Vector3.ZERO
var target_sway_rot: Vector3 = Vector3.ZERO
var wall_tuck_blend: float = 0.0

func set_wall_tuck(factor: float) -> void:
	wall_tuck_blend = clamp(factor, 0.0, 1.0)

# Mesh references
var model_root: Node3D
var player_camera: Camera3D
var head_assembly: Node3D
var center_eye: MeshInstance3D
var pick_beak: MeshInstance3D
var adze_blade: MeshInstance3D

func _ready() -> void:
	_construct_geologist_mattock()
	position = natural_pos
	rotation_degrees = natural_rot
	visible = is_active

func set_camera(cam: Camera3D) -> void:
	player_camera = cam

func set_tier(new_tier: PickaxeTier) -> void:
	tier = new_tier
	match tier:
		PickaxeTier.WOODEN:
			damage = 30.0
			swing_speed = 2.5
		PickaxeTier.STONE:
			damage = 55.0
			swing_speed = 2.9
		PickaxeTier.STEEL:
			damage = 90.0
			swing_speed = 3.4
	_update_tier_visuals()

func _update_tier_visuals() -> void:
	var head_mat: StandardMaterial3D
	match tier:
		PickaxeTier.WOODEN:
			head_mat = StandardMaterial3D.new()
			head_mat.albedo_texture = PixelTextureGenerator.get_hewn_timber_texture()
			head_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			head_mat.roughness = 0.90
		PickaxeTier.STONE:
			head_mat = StandardMaterial3D.new()
			head_mat.albedo_texture = PixelTextureGenerator.get_cobblestone_texture()
			head_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			head_mat.roughness = 0.85
		PickaxeTier.STEEL:
			head_mat = StandardMaterial3D.new()
			head_mat.albedo_texture = PixelTextureGenerator.get_industrial_steel_texture()
			head_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			head_mat.metallic = 0.85
			head_mat.roughness = 0.40

	if center_eye: center_eye.material_override = head_mat
	if pick_beak: pick_beak.material_override = head_mat
	if adze_blade: adze_blade.material_override = head_mat

func set_active(active: bool) -> void:
	is_active = active
	visible = is_active
	swing_cooldown_timer = 0.20 # Weapon swap cooldown prevents instant swing cancel
	if not is_active:
		is_swinging = false
		swing_timer = 0.0
		position = natural_pos
		rotation_degrees = natural_rot

func _construct_geologist_mattock() -> void:
	model_root = Node3D.new()
	model_root.name = "PickaxeModel"
	add_child(model_root)

	# 64x64 Stylized Materials
	var hickory_mat = StandardMaterial3D.new()
	hickory_mat.albedo_texture = PixelTextureGenerator.get_wood_plank_texture()
	hickory_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	hickory_mat.roughness = 0.85

	var worn_leather_mat = StandardMaterial3D.new()
	worn_leather_mat.albedo_texture = PixelTextureGenerator.get_cuff_texture()
	worn_leather_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	worn_leather_mat.roughness = 0.80

	var forged_steel_mat = StandardMaterial3D.new()
	forged_steel_mat.albedo_texture = PixelTextureGenerator.get_industrial_steel_texture()
	forged_steel_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	forged_steel_mat.metallic = 0.85
	forged_steel_mat.roughness = 0.45

	var aged_brass_mat = StandardMaterial3D.new()
	aged_brass_mat.albedo_texture = PixelTextureGenerator.get_lantern_brass_texture()
	aged_brass_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	aged_brass_mat.metallic = 0.80
	aged_brass_mat.roughness = 0.42

	# Clean low-poly materials (warm rich explorer aesthetic, no noisy triplanar!)
	var sleeve_mat_clean = StandardMaterial3D.new()
	sleeve_mat_clean.albedo_color = Color(0.20, 0.23, 0.26, 1.0) # Dark charcoal-slate explorer wool
	sleeve_mat_clean.roughness = 0.90

	var cuff_mat_clean = StandardMaterial3D.new()
	cuff_mat_clean.albedo_color = Color(0.24, 0.17, 0.12, 1.0) # Dark leather cuff
	cuff_mat_clean.roughness = 0.70

	var glove_mat_clean = StandardMaterial3D.new()
	glove_mat_clean.albedo_color = Color(0.48, 0.34, 0.22, 1.0) # Warm saddle brown leather
	glove_mat_clean.roughness = 0.65
	glove_mat_clean.metallic = 0.10

	var brass_trim = StandardMaterial3D.new()
	brass_trim.albedo_color = Color(0.85, 0.70, 0.35, 1.0)
	brass_trim.metallic = 0.85
	brass_trim.roughness = 0.35

	# ARM HIERARCHY: Articulated from shoulder/elbow off-screen to hand
	var arm_root = Node3D.new()
	arm_root.name = "PlayerArm"
	arm_root.position = Vector3(0.06, -0.16, 0.14)
	arm_root.rotation_degrees = Vector3(36.0, 10.0, 0.0)
	model_root.add_child(arm_root)

	var arm_scene = load("res://models/first_person_arm.glb")
	if arm_scene:
		var arm_inst = arm_scene.instantiate()
		arm_inst.name = "FirstPersonArmMesh"
		arm_inst.scale = Vector3(1.15, 1.15, 1.15)
		arm_inst.position = Vector3(0.0, 0.0, -0.34)
		arm_root.add_child(arm_inst)
	else:
		# Fallback arm
		var sleeve = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(0.075, 0.075, 0.45)
		sleeve.mesh = s_box
		sleeve.material_override = sleeve_mat_clean
		sleeve.position = Vector3(0.0, 0.0, -0.10)
		arm_root.add_child(sleeve)

		var hand = MeshInstance3D.new()
		var h_box = BoxMesh.new()
		h_box.size = Vector3(0.055, 0.050, 0.065)
		hand.mesh = h_box
		hand.material_override = glove_mat_clean
		hand.position = Vector3(0.0, 0.0, -0.34)
		arm_root.add_child(hand)

	# 4. Pickaxe Haft & Head Assembly held firmly inside hand
	var tool_data = build_tool_mesh(tier)
	var tool_mount = tool_data["root"]
	tool_mount.position = Vector3(0.0, 0.0, -0.34)
	tool_mount.rotation_degrees = Vector3(-40.0, -12.0, 0.0)
	arm_root.add_child(tool_mount)

	head_assembly = tool_data["head_assembly"]
	center_eye = tool_data["center_eye"]
	pick_beak = tool_data["pick_beak"]
	adze_blade = tool_data["adze_blade"]

## Builds the authentic geological pickaxe tool mesh hierarchy without arm/sleeve.
## Shared across player viewmodel and world pickup props for 100% visual fidelity.
static func build_tool_mesh(_p_tier: int = 1) -> Dictionary:
	var tool_mount = Node3D.new()
	tool_mount.name = "PickaxeToolMesh"

	# 64x64 Stylized Materials
	var hickory_mat = StandardMaterial3D.new()
	hickory_mat.albedo_texture = PixelTextureGenerator.get_wood_plank_texture()
	hickory_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	hickory_mat.roughness = 0.85

	var worn_leather_mat = StandardMaterial3D.new()
	worn_leather_mat.albedo_texture = PixelTextureGenerator.get_cuff_texture()
	worn_leather_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	worn_leather_mat.roughness = 0.80

	var forged_steel_mat = StandardMaterial3D.new()
	forged_steel_mat.albedo_texture = PixelTextureGenerator.get_industrial_steel_texture()
	forged_steel_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	forged_steel_mat.metallic = 0.85
	forged_steel_mat.roughness = 0.45

	var aged_brass_mat = StandardMaterial3D.new()
	aged_brass_mat.albedo_texture = PixelTextureGenerator.get_lantern_brass_texture()
	aged_brass_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	aged_brass_mat.metallic = 0.80
	aged_brass_mat.roughness = 0.42

	# Octagonal Hardwood Haft
	var handle = MeshInstance3D.new()
	var h_cyl = CylinderMesh.new()
	h_cyl.top_radius = 0.015
	h_cyl.bottom_radius = 0.019
	h_cyl.height = 0.62
	h_cyl.radial_segments = 8
	handle.mesh = h_cyl
	handle.material_override = hickory_mat
	handle.position = Vector3(0, 0.12, 0)
	tool_mount.add_child(handle)

	# Leather Grip
	var grip = MeshInstance3D.new()
	var g_cyl = CylinderMesh.new()
	g_cyl.top_radius = 0.021
	g_cyl.bottom_radius = 0.021
	g_cyl.height = 0.20
	g_cyl.radial_segments = 8
	grip.mesh = g_cyl
	grip.material_override = worn_leather_mat
	grip.position = Vector3(0, 0.0, 0)
	tool_mount.add_child(grip)

	# Pommel cap
	var pommel = MeshInstance3D.new()
	var p_cyl = CylinderMesh.new()
	p_cyl.top_radius = 0.024
	p_cyl.bottom_radius = 0.020
	p_cyl.height = 0.025
	p_cyl.radial_segments = 8
	pommel.mesh = p_cyl
	pommel.material_override = aged_brass_mat
	pommel.position = Vector3(0, -0.19, 0)
	tool_mount.add_child(pommel)

	# Forged Head Assembly
	var h_assembly = Node3D.new()
	h_assembly.name = "HeadAssembly"
	h_assembly.position = Vector3(0, 0.38, 0)
	tool_mount.add_child(h_assembly)

	var collar = MeshInstance3D.new()
	var col_cyl = CylinderMesh.new()
	col_cyl.top_radius = 0.025
	col_cyl.bottom_radius = 0.027
	col_cyl.height = 0.065
	col_cyl.radial_segments = 8
	collar.mesh = col_cyl
	collar.material_override = aged_brass_mat
	h_assembly.add_child(collar)

	var c_eye = MeshInstance3D.new()
	var eye_box = BoxMesh.new()
	eye_box.size = Vector3(0.046, 0.054, 0.075)
	c_eye.mesh = eye_box
	c_eye.material_override = forged_steel_mat
	c_eye.position = Vector3(0, 0.005, 0)
	h_assembly.add_child(c_eye)

	# Forward Digging Pick Beak - curved sharp forged steel pick point
	var p_beak = MeshInstance3D.new()
	var p1_box = BoxMesh.new()
	p1_box.size = Vector3(0.034, 0.038, 0.26)
	p_beak.mesh = p1_box
	p_beak.material_override = forged_steel_mat
	p_beak.position = Vector3(0, -0.015, -0.13)
	p_beak.rotation_degrees = Vector3(-14.0, 0, 0)
	h_assembly.add_child(p_beak)

	# Chisel point tip curving forward-down
	var tip = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.022, 0.024, 0.12)
	tip.mesh = t_box
	tip.material_override = forged_steel_mat
	tip.position = Vector3(0, -0.04, -0.22)
	tip.rotation_degrees = Vector3(-24.0, 0, 0)
	h_assembly.add_child(tip)

	# Rear Flat Rock Adze / Counter-Weight Chisel pointing BACKWARD (+Z)
	var a_blade = MeshInstance3D.new()
	var ab_box = BoxMesh.new()
	ab_box.size = Vector3(0.068, 0.020, 0.12)
	a_blade.mesh = ab_box
	a_blade.material_override = forged_steel_mat
	a_blade.position = Vector3(0, 0.002, 0.10)
	a_blade.rotation_degrees = Vector3(8.0, 0, 0)
	h_assembly.add_child(a_blade)

	return {
		"root": tool_mount,
		"head_assembly": h_assembly,
		"center_eye": c_eye,
		"pick_beak": p_beak,
		"tip": tip,
		"adze_blade": a_blade
	}

func start_swing() -> bool:
	if not is_active or is_swinging or swing_cooldown_timer > 0.0:
		return false
	is_swinging = true
	swing_timer = 0.0
	has_hit_in_current_swing = false
	return true

func get_effective_natural_pos() -> Vector3:
	var tuck_offset = Vector3(-0.05 * wall_tuck_blend, -0.06 * wall_tuck_blend, 0.28 * wall_tuck_blend)
	return natural_pos + tuck_offset

func get_effective_natural_rot() -> Vector3:
	var tuck_rot = Vector3(24.0 * wall_tuck_blend, -16.0 * wall_tuck_blend, 10.0 * wall_tuck_blend)
	return natural_rot + tuck_rot

func _process(delta: float) -> void:
	if not is_active:
		return

	if swing_cooldown_timer > 0.0:
		swing_cooldown_timer -= delta

	# Continuous / rapid click mining
	var is_click = (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or (InputMap.has_action("attack") and (Input.is_action_pressed("attack") or Input.is_action_just_pressed("attack"))))
	if not is_swinging and swing_cooldown_timer <= 0.0 and is_click and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		start_swing()

	var eff_pos = get_effective_natural_pos()
	var eff_rot = get_effective_natural_rot()

	if is_swinging:
		_process_swing(delta)
	else:
		current_sway_rot = current_sway_rot.lerp(target_sway_rot, delta * 8.0)
		rotation_degrees = eff_rot + current_sway_rot
		position = position.lerp(eff_pos, delta * 12.0)
		target_sway_rot = target_sway_rot.lerp(Vector3.ZERO, delta * 6.0)

func _process_swing(delta: float) -> void:
	swing_timer += delta * swing_speed
	var t = clamp(swing_timer, 0.0, 1.0)
	var eff_pos = get_effective_natural_pos()
	var eff_rot = get_effective_natural_rot()

	# Ergonomic, punchy first-person pickaxe strike:
	# 1. Wind-up raises tool back and right
	var windup_pos = Vector3(0.06, 0.08, 0.08)
	var windup_rot = Vector3(22.0, -12.0, 20.0)

	# 2. Downward chopping arc drives the forged pick beak forward into center reticle
	var strike_pos = Vector3(-0.16, 0.04, -0.16)
	var strike_rot = Vector3(-26.0, 26.0, -28.0)

	if t < 0.18:
		# 1. Anticipation: cock pickaxe back and up
		var p = t / 0.18
		var ease_w = p * p
		position = eff_pos + windup_pos * ease_w
		rotation_degrees = eff_rot + windup_rot * ease_w
	elif t < 0.48:
		# 2. Powerful forward-downward chop plunging pick point into rock
		var p = (t - 0.18) / 0.30
		var ease_s = p * p * (3.0 - 2.0 * p)
		position = eff_pos + windup_pos.lerp(strike_pos, ease_s)
		rotation_degrees = eff_rot + windup_rot.lerp(strike_rot, ease_s)

		if not has_hit_in_current_swing and p > 0.82:
			has_hit_in_current_swing = true
			_perform_mining_raycast()
	elif t < 0.65:
		# 3. Tactile impact rebound off dense mineral rock
		var p = (t - 0.48) / 0.17
		var shudder = sin(p * PI)
		var bounce_p = strike_pos + Vector3(0.03, 0.04, 0.05) * shudder
		var bounce_r = strike_rot + Vector3(10.0, -8.0, 8.0) * shudder
		position = eff_pos + bounce_p
		rotation_degrees = eff_rot + bounce_r
	else:
		# 4. Smooth ergonomic return to ready stance
		var p = (t - 0.65) / 0.35
		var ease_r = p * p * (3.0 - 2.0 * p)
		position = eff_pos + strike_pos.lerp(Vector3.ZERO, ease_r)
		rotation_degrees = eff_rot + strike_rot.lerp(Vector3.ZERO, ease_r)

	if swing_timer >= 1.0:
		is_swinging = false
		swing_timer = 0.0
		swing_cooldown_timer = SWING_COOLDOWN_DURATION
		position = eff_pos
		rotation_degrees = eff_rot

func _perform_mining_raycast() -> void:
	if player_camera == null:
		return

	var space_state = get_world_3d().direct_space_state
	var from = player_camera.global_position
	var to = from - player_camera.global_transform.basis.z * reach_distance

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var hit = space_state.intersect_ray(query)
	if hit.is_empty():
		return

	var collider = hit["collider"]
	var hit_pos = hit["position"]
	var hit_norm = hit["normal"]

	# Emit signal to let player_controller dispatch damage and particles
	hit_landed.emit(collider, hit_pos, hit_norm)

func apply_camera_rotation_impulse(delta_mouse: Vector2) -> void:
	if not is_active or is_swinging:
		return
	target_sway_rot.y = clamp(target_sway_rot.y - delta_mouse.x * 0.05, -10.0, 10.0)
	target_sway_rot.x = clamp(target_sway_rot.x + delta_mouse.y * 0.05, -8.0, 8.0)

func apply_movement_bob(velocity: Vector3, on_floor: bool, delta: float) -> void:
	if not is_active or is_swinging:
		return
	var speed = Vector2(velocity.x, velocity.z).length()
	if on_floor and speed > 0.2:
		var bob_x = cos(Time.get_ticks_msec() * 0.008) * 0.010
		var bob_y = abs(sin(Time.get_ticks_msec() * 0.016)) * 0.012
		position = natural_pos + Vector3(bob_x, -bob_y, 0)
	else:
		position = position.lerp(natural_pos, delta * 8.0)
