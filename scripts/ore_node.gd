# scripts/ore_node.gd
extends StaticBody3D

signal node_damaged(current_hp: float, max_hp: float)
signal node_destroyed(ore_type: int, position: Vector3)

enum OreType {
	PHOSPHOR,
	IRON,
	CALCITE
}

const DroppedItemClass = preload("res://scripts/dropped_item.gd")
const PixelTextureGenerator = preload("res://scripts/pixel_texture_generator.gd")

@export var ore_type: OreType = OreType.PHOSPHOR
@export var max_durability: float = 100.0
@export var yield_amount: int = 4

var current_durability: float = 100.0
var is_destroyed: bool = false

var host_mesh: MeshInstance3D
var mineral_group: Node3D
var glow_light: OmniLight3D
var collision_shape: CollisionShape3D
var crack_decal_mesh: MeshInstance3D

# Materials
var mineral_mat: Material
var rock_base_mat: StandardMaterial3D
var crack_mat: StandardMaterial3D

# Wobble / Impact response
var wobble_offset: Vector3 = Vector3.ZERO
var wobble_decay: float = 0.0

func _ready() -> void:
	collision_layer = 1 | 8 # Static world & Ore layer
	collision_mask = 0
	add_to_group("ore_node")

	current_durability = max_durability
	_setup_collision()
	_setup_visuals()
	_setup_crack_visual()

func _setup_collision() -> void:
	collision_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.6, 1.4, 1.6)
	collision_shape.shape = box
	collision_shape.position = Vector3(0, 0.45, 0)
	add_child(collision_shape)

func _setup_visuals() -> void:
	# Host rock base (Solidly grounded faceted hexagonal basalt socket)
	rock_base_mat = StandardMaterial3D.new()
	rock_base_mat.albedo_texture = PixelTextureGenerator.get_deep_basalt_texture()
	rock_base_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	rock_base_mat.roughness = 0.88
	rock_base_mat.metallic = 0.02

	host_mesh = MeshInstance3D.new()
	var base_cyl = CylinderMesh.new()
	base_cyl.top_radius = 0.85
	base_cyl.bottom_radius = 1.25
	base_cyl.height = 0.90
	base_cyl.radial_segments = 7
	host_mesh.mesh = base_cyl
	host_mesh.material_override = rock_base_mat
	host_mesh.position = Vector3(0, 0.15, 0)
	add_child(host_mesh)

	# Mineral Clusters
	mineral_group = Node3D.new()
	mineral_group.name = "MineralCluster"
	add_child(mineral_group)

	match ore_type:
		OreType.PHOSPHOR:
			_build_phosphor_visuals()
		OreType.IRON:
			_build_iron_visuals()
		OreType.CALCITE:
			_build_calcite_visuals()

func _setup_crack_visual() -> void:
	crack_mat = StandardMaterial3D.new()
	crack_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crack_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	crack_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	crack_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	crack_decal_mesh = MeshInstance3D.new()
	var qm = QuadMesh.new()
	qm.size = Vector2(1.2, 1.2)
	crack_decal_mesh.mesh = qm
	crack_decal_mesh.material_override = crack_mat
	crack_decal_mesh.position = Vector3(0, 0.5, 0.65)
	crack_decal_mesh.visible = false
	add_child(crack_decal_mesh)

func _build_phosphor_visuals() -> void:
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_texture = PixelTextureGenerator.get_phosphor_texture()
	p_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	p_mat.emission_enabled = true
	p_mat.emission_texture = PixelTextureGenerator.get_phosphor_texture()
	p_mat.emission_energy_multiplier = 2.4
	p_mat.roughness = 0.20
	p_mat.metallic = 0.10
	mineral_mat = p_mat

	# Cluster of crystalline needles protruding outward
	var rnd = RandomNumberGenerator.new()
	rnd.seed = hash(global_position) + 42

	for i in range(7):
		var crystal = MeshInstance3D.new()
		var prism = PrismMesh.new()
		var h = rnd.randf_range(0.6, 1.1)
		var w = rnd.randf_range(0.18, 0.28)
		prism.size = Vector3(w, h, w)
		crystal.mesh = prism
		crystal.material_override = mineral_mat

		var angle = (float(i) / 7.0) * TAU + rnd.randf_range(-0.2, 0.2)
		var r = rnd.randf_range(0.2, 0.45)
		crystal.position = Vector3(cos(angle) * r, 0.45 + rnd.randf_range(0.0, 0.25), sin(angle) * r)
		crystal.rotation_degrees = Vector3(rnd.randf_range(-25, 25), rnd.randf_range(0, 360), rnd.randf_range(-25, 25))
		mineral_group.add_child(crystal)

	# Dynamic soft cyan light source
	glow_light = OmniLight3D.new()
	glow_light.light_color = Color(0.15, 0.92, 0.98)
	glow_light.light_energy = 1.35
	glow_light.omni_range = 7.5
	glow_light.omni_attenuation = 1.2
	glow_light.shadow_enabled = true
	glow_light.position = Vector3(0, 0.75, 0)
	add_child(glow_light)

func _build_iron_visuals() -> void:
	var i_mat = StandardMaterial3D.new()
	i_mat.albedo_texture = PixelTextureGenerator.get_iron_ore_texture()
	i_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	i_mat.metallic = 0.85
	i_mat.roughness = 0.35
	mineral_mat = i_mat

	var rnd = RandomNumberGenerator.new()
	rnd.seed = hash(global_position) + 99

	for i in range(8):
		var nodule = MeshInstance3D.new()
		var box = BoxMesh.new()
		var s = rnd.randf_range(0.22, 0.45)
		box.size = Vector3(s, s * 0.8, s)
		nodule.mesh = box
		nodule.material_override = mineral_mat

		var angle = (float(i) / 8.0) * TAU
		var r = rnd.randf_range(0.25, 0.55)
		nodule.position = Vector3(cos(angle) * r, 0.40 + rnd.randf_range(0.0, 0.25), sin(angle) * r)
		nodule.rotation_degrees = Vector3(rnd.randf_range(15, 65), rnd.randf_range(0, 360), rnd.randf_range(15, 65))
		mineral_group.add_child(nodule)

func _build_calcite_visuals() -> void:
	var c_mat = StandardMaterial3D.new()
	c_mat.albedo_texture = PixelTextureGenerator.get_calcite_texture()
	c_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	c_mat.roughness = 0.25
	c_mat.metallic_specular = 0.50
	mineral_mat = c_mat

	var rnd = RandomNumberGenerator.new()
	rnd.seed = hash(global_position) + 123

	for i in range(6):
		var spire = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.02
		cyl.bottom_radius = rnd.randf_range(0.12, 0.22)
		cyl.height = rnd.randf_range(0.8, 1.45)
		cyl.radial_segments = 6
		spire.mesh = cyl
		spire.material_override = mineral_mat

		var angle = (float(i) / 6.0) * TAU
		var r = rnd.randf_range(0.15, 0.4)
		spire.position = Vector3(cos(angle) * r, cyl.height * 0.50, sin(angle) * r)
		spire.rotation_degrees = Vector3(rnd.randf_range(-15, 15), rnd.randf_range(0, 360), rnd.randf_range(-15, 15))
		mineral_group.add_child(spire)

func _process(delta: float) -> void:
	# Light breathing for phosphor
	if ore_type == OreType.PHOSPHOR and glow_light and not is_destroyed:
		var pct = current_durability / max_durability
		glow_light.light_energy = (1.1 + sin(Time.get_ticks_msec() * 0.003) * 0.25) * pct

	# Decay impact wobble
	if wobble_decay > 0.0:
		wobble_decay -= delta * 12.0
		mineral_group.position = wobble_offset * sin(wobble_decay * 25.0)
		if wobble_decay <= 0.0:
			mineral_group.position = Vector3.ZERO

# Both mine() and take_hit() methods supported
func mine(damage: float, hit_point: Vector3, hit_normal: Vector3) -> void:
	take_hit(damage, hit_point, hit_normal)

func take_hit(damage: float, hit_point: Vector3, hit_normal: Vector3) -> void:
	if is_destroyed:
		return

	current_durability -= damage
	wobble_decay = 1.0
	wobble_offset = hit_normal * 0.06

	# Progressive fracture stage (1 to 5)
	var damage_ratio = 1.0 - clamp(current_durability / max_durability, 0.0, 1.0)
	var stage = clamp(int(damage_ratio * 5.0) + 1, 1, 5)

	if crack_decal_mesh and crack_mat:
		crack_mat.albedo_texture = PixelTextureGenerator.get_dig_crack_texture(stage)
		crack_decal_mesh.visible = true
		crack_decal_mesh.global_position = hit_point + hit_normal * 0.02
		var up = Vector3.UP if abs(hit_normal.y) < 0.9 else Vector3.FORWARD
		crack_decal_mesh.look_at(hit_point + hit_normal, up)

	# Chipping scale
	var health_ratio = clamp(current_durability / max_durability, 0.0, 1.0)
	if mineral_group:
		var s = 0.55 + 0.45 * health_ratio
		mineral_group.scale = Vector3(s, s, s)

	# Spawn hit impact particle burst
	_spawn_impact_particles(hit_point, hit_normal)

	node_damaged.emit(current_durability, max_durability)

	if current_durability <= 0.0:
		_destroy()

func _spawn_impact_particles(hit_pos: Vector3, normal: Vector3) -> void:
	var p = CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 18
	p.lifetime = 0.65
	p.direction = normal + Vector3(randf_range(-0.3, 0.3), randf_range(0.2, 0.5), randf_range(-0.3, 0.3))
	p.spread = 45.0
	p.initial_velocity_min = 2.5
	p.initial_velocity_max = 5.0
	p.gravity = Vector3(0, -9.8, 0)
	p.scale_amount_min = 0.03
	p.scale_amount_max = 0.08

	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(0.04, 0.04, 0.04)
	p.mesh = p_mesh

	var p_mat = StandardMaterial3D.new()
	match ore_type:
		OreType.PHOSPHOR:
			p_mat.albedo_color = Color(0.2, 0.95, 1.0)
			p_mat.emission_enabled = true
			p_mat.emission = Color(0.2, 0.95, 1.0)
			p_mat.emission_energy_multiplier = 3.0
		OreType.IRON:
			p_mat.albedo_color = Color(1.0, 0.7, 0.2)
			p_mat.emission_enabled = true
			p_mat.emission = Color(1.0, 0.6, 0.1)
			p_mat.emission_energy_multiplier = 2.0
		OreType.CALCITE:
			p_mat.albedo_color = Color(0.95, 0.95, 0.95)
			p_mat.roughness = 0.1
	p.material_override = p_mat

	get_parent().add_child(p)
	p.global_position = hit_pos
	p.restart()

	var timer = get_tree().create_timer(1.2)
	timer.timeout.connect(p.queue_free)

func _destroy() -> void:
	is_destroyed = true
	node_destroyed.emit(int(ore_type), global_position)

	if collision_shape:
		collision_shape.disabled = true
	if crack_decal_mesh:
		crack_decal_mesh.visible = false

	# Destruction burst
	_spawn_destruction_burst()

	# Spawn collectable dropped items
	_spawn_drops()

	# Dim light and hide visuals smoothly
	if glow_light:
		var tw = create_tween()
		tw.tween_property(glow_light, "light_energy", 0.0, 0.4)
	if mineral_group:
		var tw2 = create_tween()
		tw2.tween_property(mineral_group, "scale", Vector3.ZERO, 0.2)
	if host_mesh:
		var tw3 = create_tween()
		tw3.tween_property(host_mesh, "scale", Vector3.ZERO, 0.3)
		tw3.tween_callback(queue_free)
	else:
		queue_free()

func _spawn_destruction_burst() -> void:
	var p = CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 45
	p.lifetime = 1.2
	p.direction = Vector3(0, 1, 0)
	p.spread = 75.0
	p.initial_velocity_min = 3.5
	p.initial_velocity_max = 7.5
	p.gravity = Vector3(0, -9.8, 0)
	p.scale_amount_min = 0.05
	p.scale_amount_max = 0.15

	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(0.08, 0.08, 0.08)
	p.mesh = p_mesh

	var p_mat = StandardMaterial3D.new()
	match ore_type:
		OreType.PHOSPHOR:
			p_mat.albedo_color = Color(0.15, 0.92, 1.0)
			p_mat.emission_enabled = true
			p_mat.emission = Color(0.15, 0.95, 1.0)
			p_mat.emission_energy_multiplier = 3.5
		OreType.IRON:
			p_mat.albedo_color = Color(0.95, 0.65, 0.2)
			p_mat.metallic = 0.9
		OreType.CALCITE:
			p_mat.albedo_color = Color(0.95, 0.95, 0.92)
			p_mat.roughness = 0.1
	p.material_override = p_mat

	get_parent().add_child(p)
	p.global_position = global_position + Vector3(0, 0.5, 0)
	p.restart()

	var timer = get_tree().create_timer(1.8)
	timer.timeout.connect(p.queue_free)

func _spawn_drops() -> void:
	var item_type_enum: int = DroppedItemClass.ItemType.PHOSPHOR
	match ore_type:
		OreType.PHOSPHOR: item_type_enum = DroppedItemClass.ItemType.PHOSPHOR
		OreType.IRON: item_type_enum = DroppedItemClass.ItemType.IRON
		OreType.CALCITE: item_type_enum = DroppedItemClass.ItemType.CALCITE

	for i in range(yield_amount):
		var drop = DroppedItemClass.new()
		drop.item_type = item_type_enum
		drop.amount = 1
		get_parent().add_child(drop)
		drop.global_position = global_position + Vector3(
			randf_range(-0.35, 0.35),
			0.5 + randf_range(0.1, 0.4),
			randf_range(-0.35, 0.35)
		)
