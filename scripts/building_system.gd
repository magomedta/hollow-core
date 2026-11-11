# scripts/building_system.gd
extends Node3D

const PixelTextureGenerator = preload("res://scripts/pixel_texture_generator.gd")

signal building_mode_changed(active: bool, build_type: int)
signal structure_placed(build_type: int, position: Vector3)

enum BuildType {
	NONE,
	SCAFFOLD,
	WALL_ANCHOR,
	BRIDGE,
	WORKBENCH
}

@export var max_reach_distance: float = 12.0

var current_type: BuildType = BuildType.NONE
var is_valid_placement: bool = false
var target_placement_transform: Transform3D = Transform3D.IDENTITY
var current_rotation_degrees: float = 0.0

# References
var player_camera: Camera3D
var player: CharacterBody3D
var structures_container: Node3D

# Hologram preview
var preview_node: Node3D
var holo_material: ShaderMaterial
var holo_color_valid: Color = Color(0.96, 0.76, 0.22, 0.85) # Warm Amber
var holo_color_invalid: Color = Color(0.95, 0.18, 0.12, 0.85) # Crimson

# Materials
var wood_material: StandardMaterial3D
var iron_material: StandardMaterial3D
var brass_material: StandardMaterial3D

# First-Person Arm holding Surveyor's Blueprint Projector
var fp_builder_arm: Node3D

func _ready() -> void:
	_init_materials()
	_setup_preview()
	_setup_fp_builder_arm()

func set_player(p_player: CharacterBody3D) -> void:
	player = p_player
	if player and "camera" in player:
		player_camera = player.camera

func set_structures_container(container: Node3D) -> void:
	structures_container = container

func _init_materials() -> void:
	holo_material = ShaderMaterial.new()
	holo_material.shader = load("res://shaders/hologram.gdshader")
	holo_material.set_shader_parameter("holo_color", holo_color_valid)

	wood_material = StandardMaterial3D.new()
	wood_material.albedo_texture = PixelTextureGenerator.get_wood_plank_texture()
	wood_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	wood_material.roughness = 0.85

	iron_material = StandardMaterial3D.new()
	iron_material.albedo_texture = PixelTextureGenerator.get_industrial_steel_texture()
	iron_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	iron_material.metallic = 0.80
	iron_material.roughness = 0.45

	brass_material = StandardMaterial3D.new()
	brass_material.albedo_texture = PixelTextureGenerator.get_lantern_brass_texture()
	brass_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	brass_material.metallic = 0.80
	brass_material.roughness = 0.40

func _setup_preview() -> void:
	preview_node = Node3D.new()
	preview_node.name = "HologramPreview"
	preview_node.top_level = true
	add_child(preview_node)
	preview_node.visible = false

func _setup_fp_builder_arm() -> void:
	fp_builder_arm = Node3D.new()
	fp_builder_arm.name = "FPBuilderArm"
	fp_builder_arm.position = Vector3(0.22, -0.18, -0.38)
	fp_builder_arm.rotation_degrees = Vector3(-4.0, 8.0, -3.0)
	add_child(fp_builder_arm)
	fp_builder_arm.visible = false

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
	arm_root.name = "BuilderArmRoot"
	arm_root.position = Vector3(0.06, -0.16, 0.14)
	arm_root.rotation_degrees = Vector3(40.0, 12.0, 0.0)
	fp_builder_arm.add_child(arm_root)

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

	# Curled fingers wrapping around projector handle
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

	# 4. Surveyor Blueprint Projector in hand
	var tool_mount = Node3D.new()
	tool_mount.name = "ProjectorMount"
	tool_mount.position = Vector3(0.0, 0.0, -0.36)
	tool_mount.rotation_degrees = Vector3(-40.0, -12.0, 0.0)
	arm_root.add_child(tool_mount)

	var projector_body = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.024
	cyl.bottom_radius = 0.028
	cyl.height = 0.18
	cyl.radial_segments = 8
	projector_body.mesh = cyl
	projector_body.material_override = brass_material
	projector_body.position = Vector3(0.0, 0.05, -0.04)
	projector_body.rotation_degrees = Vector3(70, 0, 0)
	tool_mount.add_child(projector_body)

	# Glowing amber projector lens
	var lens = MeshInstance3D.new()
	var lens_cyl = CylinderMesh.new()
	lens_cyl.top_radius = 0.018
	lens_cyl.bottom_radius = 0.018
	lens_cyl.height = 0.018
	lens.mesh = lens_cyl
	var lens_mat = StandardMaterial3D.new()
	lens_mat.albedo_color = Color(0.96, 0.76, 0.22)
	lens_mat.emission_enabled = true
	lens_mat.emission = Color(0.96, 0.76, 0.22)
	lens_mat.emission_energy_multiplier = 3.0
	lens.material_override = lens_mat
	lens.position = Vector3(0.0, 0.14, -0.08)
	lens.rotation_degrees = Vector3(70, 0, 0)
	tool_mount.add_child(lens)

func set_build_type(type: BuildType) -> void:
	current_type = type
	_rebuild_preview_mesh()
	var is_active = (current_type != BuildType.NONE)
	preview_node.visible = is_active and is_valid_placement
	if fp_builder_arm:
		fp_builder_arm.visible = is_active
	building_mode_changed.emit(is_active, int(current_type))

func rotate_90() -> void:
	current_rotation_degrees = fmod(current_rotation_degrees + 90.0, 360.0)

func get_cost(type: BuildType) -> Dictionary:
	match type:
		BuildType.SCAFFOLD:
			return {"timber": 2}
		BuildType.WALL_ANCHOR:
			return {"iron": 1, "timber": 1}
		BuildType.BRIDGE:
			return {"timber": 3, "cobblestone": 1}
		BuildType.WORKBENCH:
			return {"timber": 4, "cobblestone": 2}
	return {}

func can_afford(type: BuildType) -> bool:
	if player == null:
		return false
	var cost = get_cost(type)
	for res in cost.keys():
		if not player.has_resource(res, cost[res]):
			return false
	return true

func _process(_delta: float) -> void:
	if current_type == BuildType.NONE or player_camera == null:
		if preview_node.visible:
			preview_node.visible = false
		if fp_builder_arm and fp_builder_arm.visible:
			fp_builder_arm.visible = false
		return

	if fp_builder_arm and not fp_builder_arm.visible:
		fp_builder_arm.visible = true

	_update_placement_raycast()

func _update_placement_raycast() -> void:
	var space = player_camera.get_world_3d().direct_space_state
	var origin = player_camera.global_position
	var forward = -player_camera.global_transform.basis.z
	var target = origin + forward * max_reach_distance

	var query = PhysicsRayQueryParameters3D.create(origin, target)
	query.collision_mask = 1 | 8 # World & Placed structures

	var hit = space.intersect_ray(query)
	var has_resources = can_afford(current_type)

	if hit:
		var hit_pos: Vector3 = hit.position
		var hit_norm: Vector3 = hit.normal

		match current_type:
			BuildType.WALL_ANCHOR:
				var is_wall = abs(hit_norm.y) < 0.65
				is_valid_placement = is_wall and has_resources
				var up = Vector3.UP if abs(hit_norm.dot(Vector3.UP)) < 0.9 else Vector3.FORWARD
				var anchor_basis = Basis.looking_at(-hit_norm, up)
				target_placement_transform = Transform3D(anchor_basis, hit_pos)

			BuildType.SCAFFOLD:
				var snapped_pos = hit_pos
				var rot_basis = Basis(Vector3.UP, deg_to_rad(current_rotation_degrees))

				# Snapping to adjacent scaffolds
				if structures_container:
					for child in structures_container.get_children():
						if child.is_in_group("scaffold_platform"):
							var d = child.global_position.distance_to(hit_pos)
							if d < 2.8:
								var diff = hit_pos - child.global_position
								var snap_offset = Vector3(
									round(diff.x / 2.0) * 2.0,
									round(diff.y / 0.5) * 0.5,
									round(diff.z / 2.0) * 2.0
								)
								if snap_offset.length() > 0.4:
									snapped_pos = child.global_position + snap_offset
									break

				is_valid_placement = has_resources
				target_placement_transform = Transform3D(rot_basis, snapped_pos + Vector3(0, 0.08, 0))

			BuildType.BRIDGE:
				var cam_yaw = player_camera.global_rotation.y + deg_to_rad(current_rotation_degrees)
				var bridge_basis = Basis(Vector3.UP, cam_yaw)
				is_valid_placement = has_resources
				target_placement_transform = Transform3D(bridge_basis, hit_pos + Vector3(0, 0.08, 0))

			BuildType.WORKBENCH:
				var cam_yaw = player_camera.global_rotation.y + deg_to_rad(current_rotation_degrees)
				var wb_basis = Basis(Vector3.UP, cam_yaw)
				is_valid_placement = has_resources and hit_norm.y > 0.6
				target_placement_transform = Transform3D(wb_basis, hit_pos + Vector3(0, 0.05, 0))

		preview_node.global_transform = target_placement_transform
		preview_node.visible = true
	else:
		# Secondary test: test straight down from forward reach point to snap preview onto terrain!
		var ground_target = origin + forward * 5.0 + Vector3.DOWN * 10.0
		var ground_query = PhysicsRayQueryParameters3D.create(origin + forward * 5.0, ground_target)
		ground_query.collision_mask = 1 | 8
		var ground_hit = space.intersect_ray(ground_query)
		if ground_hit:
			var hit_pos: Vector3 = ground_hit.position
			var rot_basis = Basis(Vector3.UP, deg_to_rad(current_rotation_degrees))
			is_valid_placement = has_resources
			target_placement_transform = Transform3D(rot_basis, hit_pos + Vector3(0, 0.08, 0))
			preview_node.global_transform = target_placement_transform
			preview_node.visible = true
		else:
			is_valid_placement = false
			preview_node.visible = false

	if holo_material:
		holo_material.set_shader_parameter("holo_color", holo_color_valid if is_valid_placement else holo_color_invalid)

func try_place() -> bool:
	if current_type == BuildType.NONE or not is_valid_placement:
		return false

	var cost = get_cost(current_type)
	for res in cost.keys():
		if not player.consume_resource(res, cost[res]):
			return false

	_spawn_physical_structure(current_type, target_placement_transform)
	return true

func _spawn_physical_structure(type: BuildType, xform: Transform3D) -> void:
	var structure = StaticBody3D.new()
	structure.collision_layer = 1
	structure.collision_mask = 0
	structure.global_transform = xform

	match type:
		BuildType.SCAFFOLD:
			_construct_scaffold_node(structure)
			structure.add_to_group("scaffold_platform")
		BuildType.WALL_ANCHOR:
			_construct_wall_anchor_node(structure)
			structure.add_to_group("wall_anchor")
		BuildType.BRIDGE:
			_construct_bridge_node(structure)
			structure.add_to_group("bridge_segment")
		BuildType.WORKBENCH:
			_construct_workbench_node(structure)
			structure.add_to_group("workbench")

	if structures_container:
		structures_container.add_child(structure)
	else:
		get_parent().add_child(structure)

	_spawn_placement_particles(xform.origin)
	structure_placed.emit(int(type), xform.origin)

func _construct_scaffold_node(body: StaticBody3D) -> void:
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2.0, 0.18, 2.0)
	col.shape = box
	col.position = Vector3(0, 0.09, 0)
	body.add_child(col)

	for i in range(5):
		var plank = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(1.94, 0.06, 0.36)
		plank.mesh = p_box
		plank.material_override = wood_material
		plank.position = Vector3(0, 0.15, -0.76 + i * 0.38)
		body.add_child(plank)

	for z_pos in [-0.75, 0.75]:
		var beam = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(1.98, 0.10, 0.12)
		beam.mesh = b_box
		beam.material_override = wood_material
		beam.position = Vector3(0, 0.05, z_pos)
		body.add_child(beam)

	for x in [-0.95, 0.95]:
		for z in [-0.95, 0.95]:
			var bracket = MeshInstance3D.new()
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(0.08, 0.16, 0.08)
			bracket.mesh = b_mesh
			bracket.material_override = iron_material
			bracket.position = Vector3(x, 0.08, z)
			body.add_child(bracket)

func _construct_wall_anchor_node(body: StaticBody3D) -> void:
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.65, 0.12, 0.38)
	col.shape = box
	col.position = Vector3(0, 0.06, -0.18)
	body.add_child(col)

	var flange = MeshInstance3D.new()
	var f_box = BoxMesh.new()
	f_box.size = Vector3(0.32, 0.32, 0.04)
	flange.mesh = f_box
	flange.material_override = iron_material
	flange.position = Vector3(0, 0.06, 0.0)
	body.add_child(flange)

	var spike = MeshInstance3D.new()
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 0.02
	s_cyl.bottom_radius = 0.04
	s_cyl.height = 0.38
	s_cyl.radial_segments = 6
	spike.mesh = s_cyl
	spike.material_override = iron_material
	spike.position = Vector3(0, 0.06, -0.18)
	spike.rotation_degrees = Vector3(90, 0, 0)
	body.add_child(spike)

func _construct_bridge_node(body: StaticBody3D) -> void:
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.8, 0.22, 4.0)
	col.shape = box
	col.position = Vector3(0, 0.11, 0)
	body.add_child(col)

	for i in range(10):
		var plank = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(1.76, 0.06, 0.36)
		plank.mesh = p_box
		plank.material_override = wood_material
		plank.position = Vector3(0, 0.18, -1.75 + i * 0.39)
		body.add_child(plank)

	for x in [-0.78, 0.78]:
		var rail = MeshInstance3D.new()
		var r_box = BoxMesh.new()
		r_box.size = Vector3(0.08, 0.65, 3.96)
		rail.mesh = r_box
		rail.material_override = wood_material
		rail.position = Vector3(x, 0.48, 0)
		body.add_child(rail)

func _construct_workbench_node(body: StaticBody3D) -> void:
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.5, 0.9, 1.0)
	col.shape = box
	col.position = Vector3(0, 0.45, 0)
	body.add_child(col)

	var desk_top = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(1.48, 0.12, 0.98)
	desk_top.mesh = t_box
	desk_top.material_override = wood_material
	desk_top.position = Vector3(0, 0.84, 0)
	body.add_child(desk_top)

	for x in [-0.64, 0.64]:
		for z in [-0.40, 0.40]:
			var leg = MeshInstance3D.new()
			var l_box = BoxMesh.new()
			l_box.size = Vector3(0.12, 0.78, 0.12)
			leg.mesh = l_box
			leg.material_override = wood_material
			leg.position = Vector3(x, 0.39, z)
			body.add_child(leg)

func _rebuild_preview_mesh() -> void:
	for child in preview_node.get_children():
		child.queue_free()

	match current_type:
		BuildType.SCAFFOLD:
			var mi = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(2.0, 0.18, 2.0)
			mi.mesh = box
			mi.material_override = holo_material
			mi.position = Vector3(0, 0.09, 0)
			preview_node.add_child(mi)

		BuildType.WALL_ANCHOR:
			var mi = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(0.65, 0.12, 0.38)
			mi.mesh = box
			mi.material_override = holo_material
			mi.position = Vector3(0, 0.06, -0.18)
			preview_node.add_child(mi)

		BuildType.BRIDGE:
			var mi = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(1.8, 0.22, 4.0)
			mi.mesh = box
			mi.material_override = holo_material
			mi.position = Vector3(0, 0.11, 0)
			preview_node.add_child(mi)

		BuildType.WORKBENCH:
			var mi = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(1.5, 0.9, 1.0)
			mi.mesh = box
			mi.material_override = holo_material
			mi.position = Vector3(0, 0.45, 0)
			preview_node.add_child(mi)

func _spawn_placement_particles(pos: Vector3) -> void:
	var p = CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = 22
	p.lifetime = 0.6
	p.direction = Vector3(0, 1, 0)
	p.spread = 60.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.5
	p.gravity = Vector3(0, -9.8, 0)
	p.scale_amount_min = 0.04
	p.scale_amount_max = 0.09

	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(0.05, 0.05, 0.05)
	p.mesh = p_mesh

	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.96, 0.76, 0.22)
	p_mat.emission_enabled = true
	p_mat.emission = Color(0.96, 0.76, 0.22)
	p_mat.emission_energy_multiplier = 2.0
	p.material_override = p_mat

	get_parent().add_child(p)
	p.global_position = pos + Vector3(0, 0.2, 0)
	p.restart()

	var timer = get_tree().create_timer(1.2)
	timer.timeout.connect(p.queue_free)
