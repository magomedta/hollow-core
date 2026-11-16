class_name CarbideTorch
extends Node3D

signal safe_zone_entered(body: Node3D)
signal safe_zone_exited(body: Node3D)
signal support_lost(world_position: Vector3)
signal ignited
signal extinguished

enum MountType {
	FLOOR,
	WALL,
	CEILING,
}

@export_group("Placement & Support")
@export_range(20.0, 35.0, 0.5) var wall_tilt_degrees: float = 27.5
@export_flags_3d_physics var support_collision_mask: int = 1
@export var auto_check_support_interval: float = 0.25
@export var drop_gravity: float = 14.0
@export var auto_free_on_detach: bool = false
@export var detach_lifetime: float = 6.0

@export_group("Carbide Illumination")
@export var flame_color: Color = Color(1.0, 0.72, 0.38)
@export_range(12.0, 14.0, 0.1) var light_range: float = 13.0
@export var base_light_energy: float = 2.4
@export var light_attenuation: float = 1.35
@export var flicker_intensity: float = 0.22
@export var flicker_speed: float = 1.0

@export_group("Lithoacoustics & Safe Zone")
@export var safe_zone_radius: float = 8.0
@export var tension_reduction_rate: float = 5.0
@export var crackle_volume_db: float = -16.0
@export var crackle_max_distance: float = 11.0
@export var player_group_name: StringName = &"player"

const TORCH_GROUP_NAME: StringName = &"carbide_torches"
const SLEEVE_HEIGHT: float = 0.42
const SLEEVE_RADIUS_BOTTOM: float = 0.032
const SLEEVE_RADIUS_TOP: float = 0.044
const WICK_HEIGHT: float = 0.065

var _mount_type: MountType = MountType.FLOOR
var _surface_normal: Vector3 = Vector3.UP
var _anchor_world_pos: Vector3 = Vector3.ZERO
var _support_collider_id: int = 0

var _is_lit: bool = true
var _is_detached: bool = false
var _drop_velocity: Vector3 = Vector3.ZERO
var _drop_spin_axis: Vector3 = Vector3.RIGHT
var _detach_timer: float = 0.0
var _support_check_timer: float = 0.0

var _flicker_time: float = 0.0
var _flicker_seed: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _body_root: Node3D
var _sleeve_mesh: MeshInstance3D
var _collar_mesh: MeshInstance3D
var _wick_mesh: MeshInstance3D
var _flame_pivot: Node3D
var _flame_mesh: MeshInstance3D
var _flame_core_mesh: MeshInstance3D
var _omni_light: OmniLight3D
var _sparks_particles: GPUParticles3D
var _smoke_particles: GPUParticles3D
var _crackle_player: AudioStreamPlayer3D
var _safe_zone_area: Area3D
var _safe_zone_shape: CollisionShape3D

var _bodies_in_safe_zone: Array[Node3D] = []


func _ready() -> void:
	add_to_group(TORCH_GROUP_NAME)
	_rng.randomize()
	_flicker_seed = _rng.randf_range(0.0, 256.0)
	_drop_spin_axis = Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-0.3, 0.3), _rng.randf_range(-1.0, 1.0)).normalized()
	if _drop_spin_axis.is_zero_approx():
		_drop_spin_axis = Vector3.RIGHT

	_build_visual_hierarchy()
	_build_lighting()
	_build_particles()
	_build_lithoacoustics()
	_build_safe_zone()

	if _anchor_world_pos == Vector3.ZERO and is_inside_tree():
		_anchor_world_pos = global_position

	_apply_lit_state()


func _process(delta: float) -> void:
	if _is_detached:
		_process_detached_fall(delta)
		return

	if not _is_lit:
		return

	_flicker_time += delta * flicker_speed
	_update_flame_flicker()
	_keep_flame_buoyant()


func _physics_process(delta: float) -> void:
	if _is_detached:
		return

	if auto_check_support_interval > 0.0:
		_support_check_timer += delta
		if _support_check_timer >= auto_check_support_interval:
			_support_check_timer = 0.0
			check_support()

	if _is_lit and not _bodies_in_safe_zone.is_empty():
		_apply_safe_zone_tension_relief(delta)


func place_on_surface(hit_position: Vector3, surface_normal: Vector3, support_collider: Object = null) -> void:
	var normalized_normal: Vector3 = surface_normal.normalized()
	if normalized_normal.is_zero_approx():
		normalized_normal = Vector3.UP

	_surface_normal = normalized_normal
	_anchor_world_pos = hit_position
	_is_detached = false
	_drop_velocity = Vector3.ZERO

	if support_collider != null:
		_support_collider_id = support_collider.get_instance_id()
		if support_collider is Node:
			var support_node: Node = support_collider as Node
			if not support_node.tree_exiting.is_connected(_on_support_node_exiting):
				support_node.tree_exiting.connect(_on_support_node_exiting, CONNECT_ONE_SHOT)
	else:
		_support_collider_id = 0

	if _surface_normal.y > 0.7:
		_mount_type = MountType.FLOOR
	elif _surface_normal.y < -0.7:
		_mount_type = MountType.CEILING
	else:
		_mount_type = MountType.WALL

	if is_inside_tree():
		global_basis = _compute_mount_basis(_mount_type, _surface_normal)
		global_position = _compute_mount_position(_mount_type, hit_position, _surface_normal)
	else:
		basis = _compute_mount_basis(_mount_type, _surface_normal)
		position = _compute_mount_position(_mount_type, hit_position, _surface_normal)
	_keep_flame_buoyant()


func check_support() -> bool:
	if _is_detached or not is_inside_tree():
		return false

	if _support_collider_id != 0 and not is_instance_id_valid(_support_collider_id):
		_trigger_support_lost()
		return false

	var world_3d: World3D = get_world_3d()
	if world_3d == null:
		return true

	var space_state: PhysicsDirectSpaceState3D = world_3d.direct_space_state
	var ray_origin: Vector3 = _anchor_world_pos + _surface_normal * 0.08
	var ray_end: Vector3 = _anchor_world_pos - _surface_normal * 0.16

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_end,
		support_collision_mask
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var hit: Dictionary = space_state.intersect_ray(query)
	if hit.is_empty():
		_trigger_support_lost()
		return false

	if _support_collider_id != 0:
		var hit_collider: Object = hit.get("collider", null)
		if hit_collider == null or hit_collider.get_instance_id() != _support_collider_id:
			_trigger_support_lost()
			return false

	return true


func set_lit(lit: bool) -> void:
	if _is_lit == lit:
		return
	_is_lit = lit
	_apply_lit_state()
	if _is_lit:
		ignited.emit()
	else:
		extinguished.emit()


func is_lit() -> bool:
	return _is_lit and not _is_detached


func is_point_in_safe_zone(world_point: Vector3) -> bool:
	if not is_lit():
		return false
	return global_position.distance_squared_to(world_point) <= safe_zone_radius * safe_zone_radius


func get_tension_relief_factor(world_point: Vector3) -> float:
	if not is_lit():
		return 0.0
	var dist: float = global_position.distance_to(world_point)
	if dist >= safe_zone_radius:
		return 0.0
	var normalized: float = 1.0 - (dist / maxf(safe_zone_radius, 0.001))
	return clampf(normalized * normalized * (3.0 - 2.0 * normalized), 0.0, 1.0)


func get_mount_type() -> MountType:
	return _mount_type


func _compute_mount_basis(mount: MountType, normal: Vector3) -> Basis:
	match mount:
		MountType.FLOOR:
			var yaw_basis: Basis = Basis.IDENTITY
			if absf(normal.y) < 0.999:
				var right: Vector3 = normal.cross(Vector3.FORWARD).normalized()
				if right.is_zero_approx():
					right = Vector3.RIGHT
				var forward: Vector3 = right.cross(normal).normalized()
				yaw_basis = Basis(right, normal, forward).orthonormalized()
			return yaw_basis

		MountType.WALL:
			var horiz_normal: Vector3 = Vector3(normal.x, 0.0, normal.z).normalized()
			if horiz_normal.is_zero_approx():
				horiz_normal = Vector3.BACK

			var tilt_rad: float = deg_to_rad(wall_tilt_degrees)
			var up_dir: Vector3 = (Vector3.UP * cos(tilt_rad) + horiz_normal * sin(tilt_rad)).normalized()
			var tangent_x: Vector3 = Vector3.UP.cross(horiz_normal).normalized()
			if tangent_x.is_zero_approx():
				tangent_x = Vector3.RIGHT
			var forward_z: Vector3 = tangent_x.cross(up_dir).normalized()
			return Basis(tangent_x, up_dir, forward_z).orthonormalized()

		MountType.CEILING:
			return Basis(Vector3.RIGHT, Vector3.DOWN, Vector3.BACK).orthonormalized()

	return Basis.IDENTITY


func _compute_mount_position(mount: MountType, hit_position: Vector3, normal: Vector3) -> Vector3:
	match mount:
		MountType.FLOOR:
			return hit_position + normal * 0.01
		MountType.WALL:
			return hit_position + normal * 0.045 - Vector3(0.0, 0.04, 0.0)
		MountType.CEILING:
			return hit_position + normal * 0.02
	return hit_position


func _build_visual_hierarchy() -> void:
	if _body_root != null:
		return

	_body_root = Node3D.new()
	_body_root.name = &"TorchBody"
	add_child(_body_root)

	# Rusted forged casing (Syndicate 104 industrial aesthetic)
	var sleeve_mat: StandardMaterial3D = StandardMaterial3D.new()
	sleeve_mat.albedo_color = Color(0.24, 0.16, 0.12)
	sleeve_mat.metallic = 0.72
	sleeve_mat.roughness = 0.86

	var sleeve_cylinder: CylinderMesh = CylinderMesh.new()
	sleeve_cylinder.top_radius = SLEEVE_RADIUS_TOP
	sleeve_cylinder.bottom_radius = SLEEVE_RADIUS_BOTTOM
	sleeve_cylinder.height = SLEEVE_HEIGHT
	sleeve_cylinder.radial_segments = 10
	sleeve_cylinder.rings = 1

	_sleeve_mesh = MeshInstance3D.new()
	_sleeve_mesh.name = &"ForgedSleeve"
	_sleeve_mesh.mesh = sleeve_cylinder
	_sleeve_mesh.material_override = sleeve_mat
	_sleeve_mesh.position = Vector3(0.0, SLEEVE_HEIGHT * 0.5, 0.0)
	_body_root.add_child(_sleeve_mesh)

	# Iron clamping collar near the top of the sleeve
	var collar_mat: StandardMaterial3D = StandardMaterial3D.new()
	collar_mat.albedo_color = Color(0.14, 0.14, 0.15)
	collar_mat.metallic = 0.85
	collar_mat.roughness = 0.68

	var collar_cylinder: CylinderMesh = CylinderMesh.new()
	collar_cylinder.top_radius = SLEEVE_RADIUS_TOP * 1.18
	collar_cylinder.bottom_radius = SLEEVE_RADIUS_TOP * 1.18
	collar_cylinder.height = 0.055
	collar_cylinder.radial_segments = 10

	_collar_mesh = MeshInstance3D.new()
	_collar_mesh.name = &"IronCollar"
	_collar_mesh.mesh = collar_cylinder
	_collar_mesh.material_override = collar_mat
	_collar_mesh.position = Vector3(0.0, SLEEVE_HEIGHT - 0.045, 0.0)
	_body_root.add_child(_collar_mesh)

	# Pressed phosphorus carbide wick
	var wick_mat: StandardMaterial3D = StandardMaterial3D.new()
	wick_mat.albedo_color = Color(0.42, 0.36, 0.24)
	wick_mat.roughness = 0.92
	wick_mat.emission_enabled = true
	wick_mat.emission = Color(0.95, 0.45, 0.12)
	wick_mat.emission_energy_multiplier = 0.45

	var wick_cylinder: CylinderMesh = CylinderMesh.new()
	wick_cylinder.top_radius = SLEEVE_RADIUS_TOP * 0.52
	wick_cylinder.bottom_radius = SLEEVE_RADIUS_TOP * 0.72
	wick_cylinder.height = WICK_HEIGHT
	wick_cylinder.radial_segments = 8

	_wick_mesh = MeshInstance3D.new()
	_wick_mesh.name = &"PhosphorusWick"
	_wick_mesh.mesh = wick_cylinder
	_wick_mesh.material_override = wick_mat
	_wick_mesh.position = Vector3(0.0, SLEEVE_HEIGHT + WICK_HEIGHT * 0.42, 0.0)
	_body_root.add_child(_wick_mesh)

	# Procedural flame droplet (outer amber halo + bright core)
	_flame_pivot = Node3D.new()
	_flame_pivot.name = &"FlamePivot"
	_flame_pivot.position = Vector3(0.0, SLEEVE_HEIGHT + WICK_HEIGHT * 0.9, 0.0)
	_body_root.add_child(_flame_pivot)

	var outer_flame_mat: StandardMaterial3D = StandardMaterial3D.new()
	outer_flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outer_flame_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outer_flame_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	outer_flame_mat.albedo_color = Color(1.0, 0.56, 0.16, 0.85)
	outer_flame_mat.no_depth_test = false

	var flame_sphere: SphereMesh = SphereMesh.new()
	flame_sphere.radius = 0.048
	flame_sphere.height = 0.145
	flame_sphere.radial_segments = 10
	flame_sphere.rings = 6

	_flame_mesh = MeshInstance3D.new()
	_flame_mesh.name = &"FlameDroplet"
	_flame_mesh.mesh = flame_sphere
	_flame_mesh.material_override = outer_flame_mat
	_flame_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flame_mesh.position = Vector3(0.0, 0.045, 0.0)
	_flame_pivot.add_child(_flame_mesh)

	var core_flame_mat: StandardMaterial3D = StandardMaterial3D.new()
	core_flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_flame_mat.albedo_color = Color(1.0, 0.92, 0.65, 1.0)

	var core_sphere: SphereMesh = SphereMesh.new()
	core_sphere.radius = 0.025
	core_sphere.height = 0.085
	core_sphere.radial_segments = 8
	core_sphere.rings = 5

	_flame_core_mesh = MeshInstance3D.new()
	_flame_core_mesh.name = &"FlameCore"
	_flame_core_mesh.mesh = core_sphere
	_flame_core_mesh.material_override = core_flame_mat
	_flame_core_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flame_core_mesh.position = Vector3(0.0, 0.032, 0.0)
	_flame_pivot.add_child(_flame_core_mesh)


func _build_lighting() -> void:
	if _omni_light != null:
		return

	_omni_light = OmniLight3D.new()
	_omni_light.name = &"CarbideLight"
	_omni_light.light_color = flame_color
	_omni_light.light_energy = base_light_energy
	_omni_light.omni_range = light_range
	_omni_light.omni_attenuation = light_attenuation
	_omni_light.shadow_enabled = true
	_omni_light.shadow_bias = 0.06
	_omni_light.distance_fade_enabled = true
	_omni_light.distance_fade_begin = 28.0
	_omni_light.distance_fade_length = 8.0
	_omni_light.position = Vector3(0.0, 0.08, 0.0)
	_flame_pivot.add_child(_omni_light)


func _build_particles() -> void:
	if _sparks_particles == null:
		var sparks_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
		sparks_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		sparks_mat.emission_sphere_radius = 0.025
		sparks_mat.direction = Vector3.UP
		sparks_mat.spread = 32.0
		sparks_mat.initial_velocity_min = 0.25
		sparks_mat.initial_velocity_max = 0.75
		sparks_mat.gravity = Vector3(0.0, 0.65, 0.0)
		sparks_mat.damping_min = 0.6
		sparks_mat.damping_max = 1.4
		sparks_mat.scale_min = 0.6
		sparks_mat.scale_max = 1.25

		var spark_grad: Gradient = Gradient.new()
		spark_grad.set_color(0, Color(1.0, 0.88, 0.48, 1.0))
		spark_grad.add_point(0.55, Color(1.0, 0.45, 0.12, 0.9))
		spark_grad.set_color(spark_grad.get_point_count() - 1, Color(0.5, 0.12, 0.04, 0.0))
		var spark_grad_tex: GradientTexture1D = GradientTexture1D.new()
		spark_grad_tex.gradient = spark_grad
		sparks_mat.color_ramp = spark_grad_tex

		var spark_draw_mat: StandardMaterial3D = StandardMaterial3D.new()
		spark_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		spark_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		spark_draw_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		spark_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		spark_draw_mat.vertex_color_use_as_albedo = true

		var spark_quad: QuadMesh = QuadMesh.new()
		spark_quad.size = Vector2(0.022, 0.022)
		spark_quad.material = spark_draw_mat

		_sparks_particles = GPUParticles3D.new()
		_sparks_particles.name = &"CarbideSparks"
		_sparks_particles.amount = 14
		_sparks_particles.lifetime = 0.85
		_sparks_particles.randomness = 0.65
		_sparks_particles.local_coords = false
		_sparks_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_sparks_particles.process_material = sparks_mat
		_sparks_particles.draw_pass_1 = spark_quad
		_sparks_particles.position = Vector3(0.0, 0.05, 0.0)
		_flame_pivot.add_child(_sparks_particles)

	if _smoke_particles == null:
		var smoke_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
		smoke_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		smoke_mat.emission_sphere_radius = 0.02
		smoke_mat.direction = Vector3.UP
		smoke_mat.spread = 18.0
		smoke_mat.initial_velocity_min = 0.18
		smoke_mat.initial_velocity_max = 0.36
		smoke_mat.gravity = Vector3(0.0, 0.35, 0.0)
		smoke_mat.scale_min = 0.8
		smoke_mat.scale_max = 2.0

		var smoke_grad: Gradient = Gradient.new()
		smoke_grad.set_color(0, Color(0.28, 0.25, 0.22, 0.0))
		smoke_grad.add_point(0.2, Color(0.26, 0.24, 0.22, 0.24))
		smoke_grad.set_color(smoke_grad.get_point_count() - 1, Color(0.18, 0.18, 0.18, 0.0))
		var smoke_grad_tex: GradientTexture1D = GradientTexture1D.new()
		smoke_grad_tex.gradient = smoke_grad
		smoke_mat.color_ramp = smoke_grad_tex

		var smoke_draw_mat: StandardMaterial3D = StandardMaterial3D.new()
		smoke_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smoke_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smoke_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		smoke_draw_mat.vertex_color_use_as_albedo = true

		var smoke_quad: QuadMesh = QuadMesh.new()
		smoke_quad.size = Vector2(0.065, 0.065)
		smoke_quad.material = smoke_draw_mat

		_smoke_particles = GPUParticles3D.new()
		_smoke_particles.name = &"PhosphorusSmoke"
		_smoke_particles.amount = 10
		_smoke_particles.lifetime = 1.6
		_smoke_particles.randomness = 0.45
		_smoke_particles.local_coords = false
		_smoke_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_smoke_particles.process_material = smoke_mat
		_smoke_particles.draw_pass_1 = smoke_quad
		_smoke_particles.position = Vector3(0.0, 0.09, 0.0)
		_flame_pivot.add_child(_smoke_particles)


func _build_lithoacoustics() -> void:
	if _crackle_player != null:
		return

	_crackle_player = AudioStreamPlayer3D.new()
	_crackle_player.name = &"CarbideCrackleAudio"
	_crackle_player.stream = _generate_crackle_audio_stream()
	_crackle_player.volume_db = crackle_volume_db
	_crackle_player.max_distance = crackle_max_distance
	_crackle_player.unit_size = 2.0
	_crackle_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_crackle_player.bus = &"Master"
	_flame_pivot.add_child(_crackle_player)


func _generate_crackle_audio_stream() -> AudioStreamWAV:
	const SAMPLE_RATE: int = 22050
	const DURATION_SECONDS: float = 2.4
	var total_samples: int = int(SAMPLE_RATE * DURATION_SECONDS)

	var pcm_data: PackedByteArray = PackedByteArray()
	pcm_data.resize(total_samples * 2)

	var synth_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	synth_rng.seed = 104773 + int(_flicker_seed * 100.0)

	var brown_state: float = 0.0
	var pop_envelope: float = 0.0
	var hiss_lp: float = 0.0
	var fade_samples: int = int(SAMPLE_RATE * 0.06)

	for i: int in range(total_samples):
		var white: float = synth_rng.randf_range(-1.0, 1.0)
		brown_state = clampf(brown_state * 0.96 + white * 0.08, -1.0, 1.0)
		hiss_lp = hiss_lp * 0.72 + white * 0.28

		# Occasional carbide crackle micro-impulses
		if synth_rng.randf() < 0.0028:
			pop_envelope = synth_rng.randf_range(0.45, 0.95)
		else:
			pop_envelope *= 0.93

		var pop_signal: float = white * pop_envelope * 0.65
		var sample_val: float = brown_state * 0.24 + hiss_lp * 0.14 + pop_signal

		# Seamless loop crossfade envelope at edges
		if i < fade_samples:
			sample_val *= float(i) / float(fade_samples)
		elif i > total_samples - fade_samples:
			sample_val *= float(total_samples - i) / float(fade_samples)

		var int_sample: int = clampi(int(sample_val * 22000.0), -32767, 32767)
		pcm_data.encode_s16(i * 2, int_sample)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = total_samples
	wav.data = pcm_data
	return wav


func _build_safe_zone() -> void:
	if _safe_zone_area != null:
		return

	_safe_zone_area = Area3D.new()
	_safe_zone_area.name = &"LithoacousticSafeZone"
	_safe_zone_area.monitoring = true
	_safe_zone_area.monitorable = true

	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = safe_zone_radius

	_safe_zone_shape = CollisionShape3D.new()
	_safe_zone_shape.name = &"SafeZoneShape"
	_safe_zone_shape.shape = sphere
	_safe_zone_area.add_child(_safe_zone_shape)

	_safe_zone_area.body_entered.connect(_on_safe_zone_body_entered)
	_safe_zone_area.body_exited.connect(_on_safe_zone_body_exited)
	add_child(_safe_zone_area)


func _update_flame_flicker() -> void:
	var t: float = _flicker_time + _flicker_seed

	# Layered organic sine breathing + high-frequency carbide hiss shimmer
	var breath: float = sin(t * 2.1) * 0.45 + sin(t * 4.7 + 1.3) * 0.30
	var shimmer: float = sin(t * 13.7 + 0.7) * 0.15 + sin(t * 23.3 + 2.1) * 0.10
	var wave: float = breath + shimmer

	var energy_factor: float = clampf(1.0 + wave * flicker_intensity, 0.55, 1.45)
	_omni_light.light_energy = base_light_energy * energy_factor
	_omni_light.omni_range = light_range * (1.0 + wave * (flicker_intensity * 0.16))
	_omni_light.position = Vector3(
		sin(t * 9.3) * 0.008,
		0.08 + wave * 0.006,
		cos(t * 11.1) * 0.008
	)

	var flame_scale_y: float = clampf(1.0 + wave * 0.18, 0.78, 1.28)
	var flame_scale_xz: float = clampf(1.0 - wave * 0.08, 0.86, 1.16)
	_flame_mesh.scale = Vector3(flame_scale_xz, flame_scale_y, flame_scale_xz)
	_flame_core_mesh.scale = Vector3(flame_scale_xz, flame_scale_y * 0.95, flame_scale_xz)

	var wick_mat: StandardMaterial3D = _wick_mesh.material_override as StandardMaterial3D
	if wick_mat != null:
		wick_mat.emission_energy_multiplier = 0.35 + energy_factor * 0.25


func _keep_flame_buoyant() -> void:
	if _flame_pivot == null or not is_inside_tree():
		return
	# Flame always rises upward against world gravity regardless of wall tilt or ceiling suspension
	_flame_pivot.global_basis = Basis.IDENTITY


func _apply_lit_state() -> void:
	var active: bool = _is_lit and not _is_detached

	if _flame_pivot != null:
		_flame_mesh.visible = active
		_flame_core_mesh.visible = active
	if _omni_light != null:
		_omni_light.visible = active
	if _sparks_particles != null:
		_sparks_particles.emitting = active
	if _smoke_particles != null:
		_smoke_particles.emitting = active
	if _safe_zone_area != null:
		_safe_zone_area.monitoring = active
		_safe_zone_area.monitorable = active

	if _wick_mesh != null:
		var wick_mat: StandardMaterial3D = _wick_mesh.material_override as StandardMaterial3D
		if wick_mat != null:
			wick_mat.emission_enabled = active

	if _crackle_player != null:
		if active:
			if not _crackle_player.playing:
				_crackle_player.play(_rng.randf_range(0.0, 2.0))
		else:
			if _crackle_player.playing:
				_crackle_player.stop()

	if not active and not _bodies_in_safe_zone.is_empty():
		for body: Node3D in _bodies_in_safe_zone:
			if is_instance_valid(body):
				_notify_body_safe_zone(body, false)
				safe_zone_exited.emit(body)
		_bodies_in_safe_zone.clear()


func _apply_safe_zone_tension_relief(delta: float) -> void:
	var i: int = _bodies_in_safe_zone.size() - 1
	while i >= 0:
		var body: Node3D = _bodies_in_safe_zone[i]
		if not is_instance_valid(body):
			_bodies_in_safe_zone.remove_at(i)
			i -= 1
			continue

		var relief_factor: float = get_tension_relief_factor(body.global_position)
		if relief_factor > 0.0:
			var relief_amount: float = tension_reduction_rate * relief_factor * delta
			if body.has_method(&"reduce_tension"):
				body.call(&"reduce_tension", relief_amount)
			elif body.has_method(&"modify_tension"):
				body.call(&"modify_tension", -relief_amount)
		i -= 1


func _trigger_support_lost() -> void:
	if _is_detached:
		return

	_is_detached = true
	_is_lit = false
	_apply_lit_state()
	_drop_velocity = _surface_normal * 1.4 + Vector3(0.0, 1.2, 0.0)
	_detach_timer = 0.0

	support_lost.emit(global_position)

	if auto_free_on_detach:
		queue_free()


func _process_detached_fall(delta: float) -> void:
	_detach_timer += delta
	_drop_velocity.y -= drop_gravity * delta
	global_position += _drop_velocity * delta
	rotate_object_local(_drop_spin_axis, 5.5 * delta)

	if _detach_timer >= detach_lifetime:
		queue_free()


func _on_support_node_exiting() -> void:
	_trigger_support_lost()


func _on_safe_zone_body_entered(body: Node3D) -> void:
	if not is_lit() or body == null:
		return
	if not body.is_in_group(player_group_name) and not body.has_method(&"reduce_tension") and not body.has_method(&"modify_tension"):
		return
	if not _bodies_in_safe_zone.has(body):
		_bodies_in_safe_zone.append(body)
		_notify_body_safe_zone(body, true)
		safe_zone_entered.emit(body)


func _on_safe_zone_body_exited(body: Node3D) -> void:
	if body == null:
		return
	var idx: int = _bodies_in_safe_zone.find(body)
	if idx != -1:
		_bodies_in_safe_zone.remove_at(idx)
		_notify_body_safe_zone(body, false)
		safe_zone_exited.emit(body)


func _notify_body_safe_zone(body: Node3D, entered: bool) -> void:
	if body.has_method(&"set_torch_safe_zone_active"):
		body.call(&"set_torch_safe_zone_active", entered, self)