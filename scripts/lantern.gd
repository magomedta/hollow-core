# scripts/lantern.gd
extends Node3D

const PixelTextureGenerator = preload("res://scripts/pixel_texture_generator.gd")

signal fuel_changed(current_fuel: float, max_fuel: float)
signal lantern_toggled(is_on: bool)

@export var max_fuel: float = 100.0
@export var fuel_burn_rate: float = 0.35 # ~4.5 minutes per tank
@export var base_omni_energy: float = 1.80
@export var base_spot_energy: float = 2.20
@export var warm_color: Color = Color(1.0, 0.78, 0.44)

var current_fuel: float = 100.0
var is_lit: bool = true
var is_held_in_hand: bool = true
var flicker_timer: float = 0.0

func flicker(duration: float = 1.4) -> void:
	flicker_timer = duration

# Dynamic light & mesh references
var omni_light: OmniLight3D
var spot_light: SpotLight3D
var flame_mesh: MeshInstance3D
var gauge_needle: MeshInstance3D
var lantern_body_root: Node3D
var arm_root: Node3D

# Natural first-person viewport position in right hand
var natural_position: Vector3 = Vector3(0.24, -0.18, -0.42)
var natural_rotation: Vector3 = Vector3(-4.0, 12.0, -2.0)
var current_sway_rot: Vector3 = Vector3.ZERO
var target_sway_rot: Vector3 = Vector3.ZERO
var sway_bob_phase: float = 0.0
var wall_tuck_blend: float = 0.0

func set_wall_tuck(factor: float) -> void:
	wall_tuck_blend = clamp(factor, 0.0, 1.0)

func get_effective_natural_pos() -> Vector3:
	var tuck_offset = Vector3(-0.04 * wall_tuck_blend, -0.06 * wall_tuck_blend, 0.24 * wall_tuck_blend)
	return natural_position + tuck_offset

func get_effective_natural_rot() -> Vector3:
	var tuck_rot = Vector3(18.0 * wall_tuck_blend, 12.0 * wall_tuck_blend, -8.0 * wall_tuck_blend)
	return natural_rotation + tuck_rot

func _ready() -> void:
	_construct_lantern_hierarchy()
	position = natural_position
	rotation_degrees = natural_rotation
	fuel_changed.emit(current_fuel, max_fuel)
	lantern_toggled.emit(is_lit)

func _construct_lantern_hierarchy() -> void:
	lantern_body_root = Node3D.new()
	lantern_body_root.name = "LanternBody"
	add_child(lantern_body_root)

	# 64x64 Stylized Materials
	var aged_brass = StandardMaterial3D.new()
	aged_brass.albedo_texture = PixelTextureGenerator.get_lantern_brass_texture()
	aged_brass.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	aged_brass.metallic = 0.82
	aged_brass.roughness = 0.38

	var dark_cast_iron = StandardMaterial3D.new()
	dark_cast_iron.albedo_texture = PixelTextureGenerator.get_industrial_steel_texture()
	dark_cast_iron.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	dark_cast_iron.metallic = 0.85
	dark_cast_iron.roughness = 0.48

	var tempered_glass = StandardMaterial3D.new()
	tempered_glass.albedo_texture = PixelTextureGenerator.get_lantern_glass_texture()
	tempered_glass.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	tempered_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tempered_glass.roughness = 0.12
	tempered_glass.metallic = 0.08
	tempered_glass.cull_mode = BaseMaterial3D.CULL_DISABLED

	var dial_face_mat = StandardMaterial3D.new()
	dial_face_mat.albedo_color = Color(0.92, 0.88, 0.78)
	dial_face_mat.roughness = 0.50

	var needle_mat = StandardMaterial3D.new()
	needle_mat.albedo_color = Color(0.85, 0.18, 0.12)

	var flame_shader_mat = ShaderMaterial.new()
	flame_shader_mat.shader = load("res://shaders/lantern_flame.gdshader")

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

	# 1. Octagonal Pedestal Base Plate
	var base_plate = MeshInstance3D.new()
	var bp_cyl = CylinderMesh.new()
	bp_cyl.top_radius = 0.054
	bp_cyl.bottom_radius = 0.060
	bp_cyl.height = 0.014
	bp_cyl.radial_segments = 8
	base_plate.mesh = bp_cyl
	base_plate.material_override = aged_brass
	base_plate.position = Vector3(0, -0.075, 0)
	lantern_body_root.add_child(base_plate)

	# 2. Octagonal Oil/Carbide Reservoir
	var reservoir = MeshInstance3D.new()
	var res_cyl = CylinderMesh.new()
	res_cyl.top_radius = 0.048
	res_cyl.bottom_radius = 0.052
	res_cyl.height = 0.026
	res_cyl.radial_segments = 8
	reservoir.mesh = res_cyl
	reservoir.material_override = dark_cast_iron
	reservoir.position = Vector3(0, -0.055, 0)
	lantern_body_root.add_child(reservoir)

	# Brass Fuel Filler Cap
	var filler_cap = MeshInstance3D.new()
	var fc_cyl = CylinderMesh.new()
	fc_cyl.top_radius = 0.009
	fc_cyl.bottom_radius = 0.009
	fc_cyl.height = 0.010
	fc_cyl.radial_segments = 6
	filler_cap.mesh = fc_cyl
	filler_cap.material_override = aged_brass
	filler_cap.position = Vector3(0.030, -0.040, 0.025)
	lantern_body_root.add_child(filler_cap)

	# 3. Analog Pressure / Fuel Gauge (Player-Facing)
	var gauge_root = Node3D.new()
	gauge_root.position = Vector3(0, -0.055, -0.050)
	gauge_root.rotation_degrees = Vector3(0, 180, 0)
	lantern_body_root.add_child(gauge_root)

	var gauge_bezel = MeshInstance3D.new()
	var gb_cyl = CylinderMesh.new()
	gb_cyl.top_radius = 0.013
	gb_cyl.bottom_radius = 0.013
	gb_cyl.height = 0.005
	gb_cyl.radial_segments = 8
	gauge_bezel.mesh = gb_cyl
	gauge_bezel.material_override = aged_brass
	gauge_bezel.rotation_degrees = Vector3(90, 0, 0)
	gauge_root.add_child(gauge_bezel)

	var gauge_dial = MeshInstance3D.new()
	var gd_box = BoxMesh.new()
	gd_box.size = Vector3(0.020, 0.020, 0.001)
	gauge_dial.mesh = gd_box
	gauge_dial.material_override = dial_face_mat
	gauge_dial.position = Vector3(0, 0, 0.003)
	gauge_root.add_child(gauge_dial)

	gauge_needle = MeshInstance3D.new()
	var gn_box = BoxMesh.new()
	gn_box.size = Vector3(0.002, 0.012, 0.002)
	gauge_needle.mesh = gn_box
	gauge_needle.material_override = needle_mat
	gauge_needle.position = Vector3(0, 0.003, 0.004)
	gauge_root.add_child(gauge_needle)

	# 4. Slender Protective Steel Cage Struts (4 Cardinal Posts)
	var strut_r = 0.046
	var strut_angles = [PI * 0.25, PI * 0.75, PI * 1.25, PI * 1.75]
	for a in strut_angles:
		var strut = MeshInstance3D.new()
		var s_cyl = CylinderMesh.new()
		s_cyl.top_radius = 0.0035
		s_cyl.bottom_radius = 0.0035
		s_cyl.height = 0.115
		s_cyl.radial_segments = 6
		strut.mesh = s_cyl
		strut.material_override = dark_cast_iron
		strut.position = Vector3(cos(a) * strut_r, 0.015, sin(a) * strut_r)
		lantern_body_root.add_child(strut)

	# 5. Faceted Octagonal Glass Chamber
	var glass = MeshInstance3D.new()
	var gl_cyl = CylinderMesh.new()
	gl_cyl.top_radius = 0.042
	gl_cyl.bottom_radius = 0.042
	gl_cyl.height = 0.108
	gl_cyl.radial_segments = 8
	glass.mesh = gl_cyl
	glass.material_override = tempered_glass
	glass.position = Vector3(0, 0.015, 0)
	lantern_body_root.add_child(glass)

	# 6. Brass Burner Collar & Glowing Mantle
	var burner = MeshInstance3D.new()
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 0.014
	b_cyl.bottom_radius = 0.018
	b_cyl.height = 0.018
	b_cyl.radial_segments = 8
	burner.mesh = b_cyl
	burner.material_override = aged_brass
	burner.position = Vector3(0, -0.032, 0)
	lantern_body_root.add_child(burner)

	# Glowing Teardrop Mantle Flame
	flame_mesh = MeshInstance3D.new()
	var f_sph = SphereMesh.new()
	f_sph.radius = 0.014
	f_sph.height = 0.034
	f_sph.radial_segments = 8
	f_sph.rings = 4
	flame_mesh.mesh = f_sph
	flame_mesh.material_override = flame_shader_mat
	flame_mesh.position = Vector3(0, 0.002, 0)
	lantern_body_root.add_child(flame_mesh)

	# 7. Stepped Octagonal Hood Cap
	var hood_tier1 = MeshInstance3D.new()
	var h1_cyl = CylinderMesh.new()
	h1_cyl.top_radius = 0.038
	h1_cyl.bottom_radius = 0.054
	h1_cyl.height = 0.018
	h1_cyl.radial_segments = 8
	hood_tier1.mesh = h1_cyl
	hood_tier1.material_override = aged_brass
	hood_tier1.position = Vector3(0, 0.076, 0)
	lantern_body_root.add_child(hood_tier1)

	var hood_tier2 = MeshInstance3D.new()
	var h2_cyl = CylinderMesh.new()
	h2_cyl.top_radius = 0.024
	h2_cyl.bottom_radius = 0.028
	h2_cyl.height = 0.016
	h2_cyl.radial_segments = 8
	hood_tier2.mesh = h2_cyl
	hood_tier2.material_override = dark_cast_iron
	hood_tier2.position = Vector3(0, 0.092, 0)
	lantern_body_root.add_child(hood_tier2)

	# Cast Brass Suspension Ring
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.008
	torus.outer_radius = 0.016
	torus.rings = 6
	torus.ring_segments = 8
	ring.mesh = torus
	ring.material_override = aged_brass
	ring.position = Vector3(0, 0.112, 0)
	ring.rotation_degrees = Vector3(0, 45, 90)
	lantern_body_root.add_child(ring)

	# 8. Arching Bail Wire Handle
	var bail = MeshInstance3D.new()
	var bail_torus = TorusMesh.new()
	bail_torus.inner_radius = 0.058
	bail_torus.outer_radius = 0.062
	bail_torus.rings = 6
	bail_torus.ring_segments = 8
	bail.mesh = bail_torus
	bail.material_override = dark_cast_iron
	bail.position = Vector3(0, 0.072, 0.018)
	bail.rotation_degrees = Vector3(32, 0, 0)
	bail.scale = Vector3(1.0, 1.2, 0.5)
	lantern_body_root.add_child(bail)

	# 9. CONTINUOUS FIRST-PERSON EXPLORER ARM & LEATHER GLOVED HAND
	arm_root = Node3D.new()
	arm_root.name = "LanternArm"
	arm_root.position = Vector3(0.015, 0.112, -0.01) # Anchored at suspension ring
	arm_root.rotation_degrees = Vector3(32.0, -18.0, 0.0) # Angled down-right toward off-screen shoulder
	lantern_body_root.add_child(arm_root)

	# Continuous Forearm Sleeve (solidly extends off-screen through bottom-right viewport)
	var sleeve = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.074, 0.074, 0.54)
	sleeve.mesh = s_box
	sleeve.material_override = sleeve_mat
	sleeve.position = Vector3(0.0, 0.0, 0.30)
	sleeve.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm_root.add_child(sleeve)

	# Reinforced Leather Wrist Cuff
	var cuff = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(0.078, 0.078, 0.045)
	cuff.mesh = c_box
	cuff.material_override = glove_mat
	cuff.position = Vector3(0.0, 0.0, 0.05)
	cuff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm_root.add_child(cuff)

	# Gloved Palm firmly holding the brass suspension ring
	var hand = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.054, 0.050, 0.060)
	hand.mesh = h_box
	hand.material_override = glove_mat
	hand.position = Vector3(0.0, 0.0, 0.0)
	hand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm_root.add_child(hand)

	# Curled Fingers wrapped around the ring
	var fingers = MeshInstance3D.new()
	var f_box = BoxMesh.new()
	f_box.size = Vector3(0.032, 0.038, 0.048)
	fingers.mesh = f_box
	fingers.material_override = glove_mat
	fingers.position = Vector3(-0.018, -0.012, -0.01)
	fingers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm_root.add_child(fingers)

	# Leather Thumb braced against top of ring
	var thumb = MeshInstance3D.new()
	var th_box = BoxMesh.new()
	th_box.size = Vector3(0.020, 0.024, 0.032)
	thumb.mesh = th_box
	thumb.material_override = glove_mat
	thumb.position = Vector3(0.018, 0.015, -0.01)
	thumb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm_root.add_child(thumb)

	# Disable self-shadow casting on all lantern body meshes to eliminate ugly shadow artifacts
	_disable_mesh_shadows(lantern_body_root)

	# 10. Dynamic Lights (Parented to this Node3D so they shine in both hand and harness modes)
	# Omni light provides smooth 360-degree illumination around player without harsh self-shadow cuts
	omni_light = OmniLight3D.new()
	omni_light.name = "LanternMantleLight"
	omni_light.light_color = warm_color
	omni_light.light_energy = 2.2
	omni_light.omni_range = 24.0 # Generous 24m radius for exploration
	omni_light.omni_attenuation = 1.0 # Smooth, physically believable linear falloff
	omni_light.shadow_enabled = false # Disabling shadows on hand light avoids screen-wide occlusion wedges
	omni_light.position = Vector3(0.0, 0.08, -0.12)
	add_child(omni_light)

	# Forward reflector beam illuminates tunnels in front of explorer
	spot_light = SpotLight3D.new()
	spot_light.name = "SurveyorReflectorBeam"
	spot_light.light_color = Color(1.0, 0.86, 0.55)
	spot_light.light_energy = 2.4
	spot_light.spot_range = 36.0 # Reaches into deep tunnel ahead
	spot_light.spot_angle = 50.0
	spot_light.spot_attenuation = 1.0
	spot_light.shadow_enabled = false
	spot_light.position = Vector3(0.0, 0.08, -0.16)
	spot_light.rotation_degrees = Vector3(-4.0, 0, 0)
	add_child(spot_light)

func _disable_mesh_shadows(node: Node) -> void:
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_mesh_shadows(child)

func set_hand_mode(in_hand: bool) -> void:
	is_held_in_hand = in_hand
	if is_held_in_hand:
		position = natural_position
		rotation_degrees = natural_rotation
		if lantern_body_root:
			lantern_body_root.visible = true
		if omni_light:
			omni_light.position = Vector3(0, 0.002, 0)
		if spot_light:
			spot_light.position = Vector3(0, 0.002, -0.06)
	else:
		# Explorer Belt/Harness Mode: lantern is clipped to explorer's gear
		# Model is hidden to keep view completely unobstructed and clean
		if lantern_body_root:
			lantern_body_root.visible = false
		position = Vector3(0.0, -0.22, -0.15)
		rotation_degrees = Vector3.ZERO
		if omni_light:
			omni_light.position = Vector3.ZERO
		if spot_light:
			spot_light.position = Vector3(0, 0, -0.05)

func toggle_lantern() -> void:
	if current_fuel <= 0.0 and not is_lit:
		return
	is_lit = not is_lit
	_update_lighting_state()
	lantern_toggled.emit(is_lit)
	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("lantern_click", global_position)

func set_lit(lit: bool) -> void:
	is_lit = lit
	_update_lighting_state()
	lantern_toggled.emit(is_lit)

func refuel(amount: float) -> void:
	current_fuel = clamp(current_fuel + amount, 0.0, max_fuel)
	fuel_changed.emit(current_fuel, max_fuel)
	if current_fuel > 0.0 and not is_lit:
		is_lit = true
		_update_lighting_state()
		lantern_toggled.emit(is_lit)

func _update_lighting_state() -> void:
	var active = is_lit and (current_fuel > 0.0)
	if omni_light:
		omni_light.visible = active
	if spot_light:
		spot_light.visible = active
	if flame_mesh:
		flame_mesh.visible = active

func apply_camera_rotation_impulse(delta_mouse: Vector2) -> void:
	if not is_held_in_hand:
		return
	target_sway_rot.y = clamp(target_sway_rot.y + delta_mouse.x * 0.04, -8.0, 8.0)
	target_sway_rot.x = clamp(target_sway_rot.x - delta_mouse.y * 0.04, -6.0, 6.0)

func apply_movement_bob(velocity: Vector3, on_floor: bool, delta: float) -> void:
	if not is_held_in_hand:
		return
	var eff_pos = get_effective_natural_pos()
	var speed = Vector2(velocity.x, velocity.z).length()
	if on_floor and speed > 0.2:
		sway_bob_phase += delta * speed * 2.4
		var bob_y = sin(sway_bob_phase) * 0.012
		var bob_x = cos(sway_bob_phase * 0.5) * 0.008
		position = eff_pos + Vector3(bob_x, bob_y, 0)
	else:
		sway_bob_phase = 0.0
		position = position.lerp(eff_pos, delta * 6.0)

func _process(delta: float) -> void:
	# Horror / Paranormal light flicker
	if flicker_timer > 0.0:
		flicker_timer -= delta
		if omni_light and is_lit:
			omni_light.light_energy = base_omni_energy * randf_range(0.12, 0.55)
		if spot_light and is_lit:
			spot_light.light_energy = base_spot_energy * randf_range(0.12, 0.55)
	elif is_lit:
		if omni_light and omni_light.light_energy != base_omni_energy:
			omni_light.light_energy = base_omni_energy
		if spot_light and spot_light.light_energy != base_spot_energy:
			spot_light.light_energy = base_spot_energy

	# Fuel consumption
	if is_lit and fuel_burn_rate > 0.0:
		current_fuel = max(0.0, current_fuel - fuel_burn_rate * delta)
		fuel_changed.emit(current_fuel, max_fuel)
		if current_fuel <= 0.0:
			is_lit = false
			_update_lighting_state()
			lantern_toggled.emit(false)

	# Update gauge needle
	if gauge_needle:
		var fuel_ratio = current_fuel / max_fuel
		gauge_needle.rotation_degrees.z = lerp(-65.0, 65.0, fuel_ratio)

	if is_held_in_hand:
		var eff_pos = get_effective_natural_pos()
		var eff_rot = get_effective_natural_rot()
		current_sway_rot = current_sway_rot.lerp(target_sway_rot, delta * 8.0)
		rotation_degrees = eff_rot + current_sway_rot
		position = position.lerp(eff_pos, delta * 12.0)
		target_sway_rot = target_sway_rot.lerp(Vector3.ZERO, delta * 6.0)
