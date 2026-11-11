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
var has_hit_in_current_swing: bool = false

var natural_pos: Vector3 = Vector3(0.24, -0.20, -0.38)
var natural_rot: Vector3 = Vector3(-12.0, 18.0, -6.0)
var current_sway_rot: Vector3 = Vector3.ZERO
var target_sway_rot: Vector3 = Vector3.ZERO

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

	var sleeve_mat = StandardMaterial3D.new()
	sleeve_mat.albedo_texture = PixelTextureGenerator.get_sleeve_texture()
	sleeve_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sleeve_mat.uv1_triplanar = true
	sleeve_mat.uv1_scale = Vector3(8.0, 8.0, 8.0)
	sleeve_mat.roughness = 0.88

	var glove_mat = StandardMaterial3D.new()
	glove_mat.albedo_texture = PixelTextureGenerator.get_glove_texture()
	glove_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	glove_mat.uv1_triplanar = true
	glove_mat.uv1_scale = Vector3(8.0, 8.0, 8.0)
	glove_mat.roughness = 0.82

	# ARM HIERARCHY: Articulated from shoulder/elbow off-screen to hand
	var arm_root = Node3D.new()
	arm_root.name = "PlayerArm"
	arm_root.position = Vector3(0.06, -0.16, 0.14)
	arm_root.rotation_degrees = Vector3(40.0, 12.0, 0.0)
	model_root.add_child(arm_root)

	# 1. Continuous Tapered Sleeve (extending off-screen)
	var sleeve = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.088, 0.088, 0.52)
	sleeve.mesh = s_box
	sleeve.material_override = sleeve_mat
	sleeve.position = Vector3(0.0, 0.0, -0.06)
	sleeve.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm_root.add_child(sleeve)

	# 2. Leather Wrist Cuff
	var cuff = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(0.092, 0.092, 0.05)
	cuff.mesh = c_box
	cuff.material_override = glove_mat
	cuff.position = Vector3(0.0, 0.0, -0.32)
	cuff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm_root.add_child(cuff)

	# 3. Gloved Hand (Palm + Curled Fingers)
	var hand = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.065, 0.060, 0.075)
	hand.mesh = h_box
	hand.material_override = glove_mat
	hand.position = Vector3(0.0, 0.0, -0.36)
	hand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm_root.add_child(hand)

	# Fingers wrapping securely around haft
	var fingers = MeshInstance3D.new()
	var f_box = BoxMesh.new()
	f_box.size = Vector3(0.038, 0.065, 0.065)
	fingers.mesh = f_box
	fingers.material_override = glove_mat
	fingers.position = Vector3(-0.024, -0.015, -0.36)
	fingers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm_root.add_child(fingers)

	# Thumb
	var thumb = MeshInstance3D.new()
	var th_box = BoxMesh.new()
	th_box.size = Vector3(0.026, 0.032, 0.036)
	thumb.mesh = th_box
	thumb.material_override = glove_mat
	thumb.position = Vector3(0.022, 0.022, -0.34)
	thumb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm_root.add_child(thumb)

	# 4. Pickaxe Haft & Head Assembly held firmly inside hand
	var tool_mount = Node3D.new()
	tool_mount.name = "ToolMount"
	tool_mount.position = Vector3(0.0, 0.0, -0.36)
	tool_mount.rotation_degrees = Vector3(-40.0, -12.0, 0.0)
	arm_root.add_child(tool_mount)

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

	# 5. Forged Head Assembly
	head_assembly = Node3D.new()
	head_assembly.position = Vector3(0, 0.38, 0)
	tool_mount.add_child(head_assembly)

	var collar = MeshInstance3D.new()
	var col_cyl = CylinderMesh.new()
	col_cyl.top_radius = 0.025
	col_cyl.bottom_radius = 0.027
	col_cyl.height = 0.065
	col_cyl.radial_segments = 8
	collar.mesh = col_cyl
	collar.material_override = aged_brass_mat
	head_assembly.add_child(collar)

	center_eye = MeshInstance3D.new()
	var eye_box = BoxMesh.new()
	eye_box.size = Vector3(0.046, 0.054, 0.075)
	center_eye.mesh = eye_box
	center_eye.material_override = forged_steel_mat
	center_eye.position = Vector3(0, 0.005, 0)
	head_assembly.add_child(center_eye)

	# Forward Digging Pick Beak - curved sharp forged steel pick point pointing DOWN and FORWARD into target (-Z)
	pick_beak = MeshInstance3D.new()
	var p1_box = BoxMesh.new()
	p1_box.size = Vector3(0.034, 0.038, 0.26)
	pick_beak.mesh = p1_box
	pick_beak.material_override = forged_steel_mat
	pick_beak.position = Vector3(0, -0.015, -0.13)
	pick_beak.rotation_degrees = Vector3(-14.0, 0, 0)
	head_assembly.add_child(pick_beak)

	# Rear Flat Rock Adze / Counter-Weight Chisel pointing BACKWARD (+Z)
	adze_blade = MeshInstance3D.new()
	var ab_box = BoxMesh.new()
	ab_box.size = Vector3(0.068, 0.020, 0.12)
	adze_blade.mesh = ab_box
	adze_blade.material_override = forged_steel_mat
	adze_blade.position = Vector3(0, 0.002, 0.10)
	adze_blade.rotation_degrees = Vector3(8.0, 0, 0)
	head_assembly.add_child(adze_blade)

func start_swing() -> bool:
	if not is_active or is_swinging:
		return false
	is_swinging = true
	swing_timer = 0.0
	has_hit_in_current_swing = false
	return true

func _process(delta: float) -> void:
	if not is_active:
		return

	# Continuous mining: if LMB is held, swing repeatedly
	if not is_swinging and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		start_swing()

	if is_swinging:
		_process_swing(delta)
	else:
		current_sway_rot = current_sway_rot.lerp(target_sway_rot, delta * 8.0)
		rotation_degrees = natural_rot + current_sway_rot
		target_sway_rot = target_sway_rot.lerp(Vector3.ZERO, delta * 6.0)

func _process_swing(delta: float) -> void:
	swing_timer += delta * swing_speed
	var t = clamp(swing_timer, 0.0, 1.0)

	var windup_pos = Vector3(0.04, 0.06, 0.06)
	var windup_rot = Vector3(24.0, 8.0, 6.0)

	var strike_pos = Vector3(-0.11, -0.13, -0.18) # Thrusts down, forward into screen center
	var strike_rot = Vector3(-62.0, -22.0, -16.0) # Pitches forward (-X), rotates into rock face

	if t < 0.18:
		# 1. Wind-up: cock tool back and up
		var p = t / 0.18
		var ease_w = p * p
		position = natural_pos + windup_pos * ease_w
		rotation_degrees = natural_rot + windup_rot * ease_w
	elif t < 0.48:
		# 2. Downward & Forward Chop: forceful strike directly into rock
		var p = (t - 0.18) / 0.30
		var ease_s = p * p * (3.0 - 2.0 * p)
		position = natural_pos + windup_pos.lerp(strike_pos, ease_s)
		rotation_degrees = natural_rot + windup_rot.lerp(strike_rot, ease_s)

		if not has_hit_in_current_swing and p > 0.82:
			has_hit_in_current_swing = true
			_perform_mining_raycast()
	elif t < 0.65:
		# 3. Elastic Impact Shudder & Rebound off stone
		var p = (t - 0.48) / 0.17
		var shudder = sin(p * PI)
		var bounce_p = strike_pos + Vector3(0.02, 0.04, 0.04) * shudder
		var bounce_r = strike_rot + Vector3(12.0, 5.0, 3.0) * shudder
		position = natural_pos + bounce_p
		rotation_degrees = natural_rot + bounce_r
	else:
		# 4. Smooth ergonomic return to natural ready pose
		var p = (t - 0.65) / 0.35
		var ease_r = p * p * (3.0 - 2.0 * p)
		position = natural_pos + strike_pos.lerp(Vector3.ZERO, ease_r)
		rotation_degrees = natural_rot + strike_rot.lerp(Vector3.ZERO, ease_r)

	if swing_timer >= 1.0:
		is_swinging = false
		swing_timer = 0.0
		position = natural_pos
		rotation_degrees = natural_rot

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
