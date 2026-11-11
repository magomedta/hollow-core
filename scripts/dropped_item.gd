# scripts/dropped_item.gd
extends Area3D

enum ItemType {
	PHOSPHOR,
	IRON,
	CALCITE,
	TIMBER,
	COBBLESTONE
}

const PixelTextureGenerator = preload("res://scripts/pixel_texture_generator.gd")

@export var item_type: ItemType = ItemType.PHOSPHOR
@export var amount: int = 1

var velocity: Vector3 = Vector3.ZERO
var is_grounded: bool = false
var lifetime: float = 0.0
var max_lifetime: float = 300.0

var mesh_instance: MeshInstance3D
var item_light: OmniLight3D
var target_player: CharacterBody3D = null

func _ready() -> void:
	collision_layer = 4 # Item layer
	collision_mask = 1 | 2 # World & Player

	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 0.45
	col.shape = sphere
	add_child(col)

	_build_visuals()
	body_entered.connect(_on_body_entered)

	# Initial ejection velocity (small pop out of the mined rock)
	velocity = Vector3(
		randf_range(-1.4, 1.4),
		randf_range(2.2, 4.0),
		randf_range(-1.4, 1.4)
	)

func _build_visuals() -> void:
	mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.22, 0.22, 0.22)
	mesh_instance.mesh = box
	mesh_instance.rotation_degrees = Vector3(35, 45, 15)

	var mat = StandardMaterial3D.new()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

	match item_type:
		ItemType.PHOSPHOR:
			mat.albedo_texture = PixelTextureGenerator.get_phosphor_texture()
			mat.emission_enabled = true
			mat.emission_texture = PixelTextureGenerator.get_phosphor_texture()
			mat.emission_energy_multiplier = 2.4
			mat.roughness = 0.20
			mat.metallic = 0.10

			item_light = OmniLight3D.new()
			item_light.light_color = Color(0.15, 0.92, 1.0)
			item_light.light_energy = 0.90
			item_light.omni_range = 4.0
			add_child(item_light)

		ItemType.IRON:
			mat.albedo_texture = PixelTextureGenerator.get_iron_ore_texture()
			mat.metallic = 0.85
			mat.roughness = 0.35

		ItemType.CALCITE:
			mat.albedo_texture = PixelTextureGenerator.get_calcite_texture()
			mat.roughness = 0.25
			mat.metallic_specular = 0.70

		ItemType.TIMBER:
			mat.albedo_texture = PixelTextureGenerator.get_wood_plank_texture()
			mat.roughness = 0.85
			mat.metallic = 0.0

		ItemType.COBBLESTONE:
			mat.albedo_texture = PixelTextureGenerator.get_cobblestone_texture()
			mat.roughness = 0.90
			mat.metallic = 0.05

	mesh_instance.material_override = mat
	add_child(mesh_instance)

func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime > max_lifetime:
		queue_free()
		return

	# Idle spin and hover bobbing
	if mesh_instance:
		mesh_instance.rotate_y(delta * 2.4)
		mesh_instance.position.y = sin(lifetime * 3.5) * 0.04

	# If attracted to player
	if target_player and is_instance_valid(target_player):
		var dir = (target_player.global_position + Vector3(0, 0.9, 0)) - global_position
		var dist = dir.length()
		if dist < 0.95:
			_collect(target_player)
			return
		var speed = clamp(14.0 / max(dist, 0.1), 5.0, 20.0)
		global_position += dir.normalized() * speed * delta
		return

	# Fall physics
	if not is_grounded:
		velocity.y -= 14.0 * delta
		global_position += velocity * delta

		# Ground detection raycast
		var space = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.35, 0), global_position - Vector3(0, 0.25, 0))
		query.collision_mask = 1 # Static world
		var hit = space.intersect_ray(query)
		if hit:
			global_position.y = hit.position.y + 0.15
			velocity = Vector3.ZERO
			is_grounded = true

	# Magnetism detection: find player within 3.5m
	if target_player == null and get_tree().has_group("player"):
		var p = get_tree().get_first_node_in_group("player") as CharacterBody3D
		if p and global_position.distance_to(p.global_position) < 3.5:
			target_player = p

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.is_in_group("player"):
		_collect(body)

func _collect(p: CharacterBody3D) -> void:
	var res_key = "phosphor"
	match item_type:
		ItemType.PHOSPHOR: res_key = "phosphor"
		ItemType.IRON: res_key = "iron"
		ItemType.CALCITE: res_key = "calcite"
		ItemType.TIMBER: res_key = "timber"
		ItemType.COBBLESTONE: res_key = "cobblestone"

	if p.has_method("add_resource"):
		p.add_resource(res_key, amount)
	queue_free()
