# scripts/minable_block.gd
class_name MinableBlock
extends StaticBody3D

signal block_damaged(current_hp: float, max_hp: float)
signal block_destroyed(position: Vector3)

const DroppedItemClass = preload("res://scripts/dropped_item.gd")
const PixelTextureGenerator = preload("res://scripts/pixel_texture_generator.gd")

@export var max_durability: float = 60.0
@export var drop_type: DroppedItemClass.ItemType = DroppedItemClass.ItemType.COBBLESTONE
@export var drop_amount: int = 2

var current_durability: float = 60.0
var is_destroyed: bool = false
var crack_decal_mesh: MeshInstance3D
var crack_mat: StandardMaterial3D

func _ready() -> void:
	collision_layer = 1 | 8 # World & Interactive layer
	collision_mask = 0
	current_durability = max_durability
	add_to_group("minable")

	_ensure_collision_shape()
	_setup_crack_visual()

func _ensure_collision_shape() -> void:
	for child in get_children():
		if child is CollisionShape3D:
			return

	# Auto-generate collision shape if missing
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.3, 1.1, 1.3)
	col.shape = box
	col.position = Vector3(0, 0.45, 0)
	add_child(col)

func _setup_crack_visual() -> void:
	crack_mat = StandardMaterial3D.new()
	crack_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crack_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	crack_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	crack_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	crack_decal_mesh = MeshInstance3D.new()
	var qm = QuadMesh.new()
	qm.size = Vector2(1.1, 1.1)
	crack_decal_mesh.mesh = qm
	crack_decal_mesh.material_override = crack_mat
	crack_decal_mesh.visible = false
	add_child(crack_decal_mesh)

func take_hit(damage: float, hit_point: Vector3, hit_normal: Vector3) -> void:
	mine(damage, hit_point, hit_normal)

func mine(damage: float, hit_point: Vector3, hit_normal: Vector3) -> void:
	if is_destroyed:
		return

	current_durability -= damage
	var damage_ratio = 1.0 - clamp(current_durability / max_durability, 0.0, 1.0)
	var stage = clamp(int(damage_ratio * 5.0) + 1, 1, 5)

	if crack_decal_mesh and crack_mat:
		crack_mat.albedo_texture = PixelTextureGenerator.get_dig_crack_texture(stage)
		crack_decal_mesh.visible = true
		crack_decal_mesh.global_position = hit_point + hit_normal * 0.03
		var up = Vector3.UP if abs(hit_normal.y) < 0.9 else Vector3.FORWARD
		crack_decal_mesh.look_at(hit_point + hit_normal, up)

	_spawn_hit_particles(hit_point, hit_normal)
	block_damaged.emit(current_durability, max_durability)

	if current_durability <= 0.0:
		_destroy()

func _spawn_hit_particles(hit_pos: Vector3, normal: Vector3) -> void:
	var p = CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = 16
	p.lifetime = 0.5
	p.direction = normal + Vector3(randf_range(-0.2, 0.2), 0.35, randf_range(-0.2, 0.2))
	p.spread = 45.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.5
	p.gravity = Vector3(0, -9.8, 0)
	p.scale_amount_min = 0.03
	p.scale_amount_max = 0.07

	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(0.04, 0.04, 0.04)
	p.mesh = p_mesh

	var mat = StandardMaterial3D.new()
	if drop_type == DroppedItemClass.ItemType.TIMBER:
		mat.albedo_color = Color(0.48, 0.32, 0.18)
	else:
		mat.albedo_color = Color(0.42, 0.44, 0.48)
	p.material_override = mat

	get_parent().add_child(p)
	p.global_position = hit_pos
	p.restart()

	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(p.queue_free)

func _destroy() -> void:
	is_destroyed = true
	block_destroyed.emit(global_position)

	if crack_decal_mesh:
		crack_decal_mesh.visible = false

	for i in range(drop_amount):
		var drop = DroppedItemClass.new()
		drop.item_type = drop_type
		drop.amount = 1
		get_parent().add_child(drop)
		drop.global_position = global_position + Vector3(
			randf_range(-0.35, 0.35),
			0.4 + randf_range(0.1, 0.3),
			randf_range(-0.35, 0.35)
		)

	queue_free()
