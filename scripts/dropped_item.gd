# scripts/dropped_item.gd
class_name DroppedItem
extends Area3D

enum ItemType {
	PHOSPHOR,
	IRON,
	CALCITE,
	TIMBER,
	COBBLESTONE
}

const PixelTextureGenerator = preload("res://scripts/pixel_texture_generator.gd")

var item_type: Variant = "phosphor"
var item_id: String = "phosphor"
var amount: int = 1
var item_count: int:
	get: return amount
	set(val): amount = val

var velocity: Vector3 = Vector3.ZERO
var is_grounded: bool = false
var lifetime: float = 0.0
var max_lifetime: float = 300.0

var mesh_instance: MeshInstance3D
var item_light: OmniLight3D

func _ready() -> void:
	add_to_group("dropped_items")
	add_to_group("interactable")
	collision_layer = 4 | 8 # Item layer + Interactable prop layer
	collision_mask = 1 # Static world

	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 0.55
	col.shape = sphere
	add_child(col)

	_resolve_item_id()
	_build_visuals()

	# Initial ejection velocity (pop out of mined voxel)
	velocity = Vector3(
		randf_range(-1.2, 1.2),
		randf_range(2.0, 3.5),
		randf_range(-1.2, 1.2)
	)

func _resolve_item_id() -> void:
	if typeof(item_type) == TYPE_STRING:
		item_id = item_type
	elif typeof(item_type) == TYPE_INT:
		match item_type:
			ItemType.PHOSPHOR: item_id = "phosphor"
			ItemType.IRON: item_id = "iron"
			ItemType.CALCITE: item_id = "calcite"
			ItemType.TIMBER: item_id = "timber"
			ItemType.COBBLESTONE: item_id = "cobblestone"
			_: item_id = "cobblestone"

func _build_visuals() -> void:
	mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.28, 0.28, 0.28)
	mesh_instance.mesh = box
	mesh_instance.rotation_degrees = Vector3(35, 45, 15)

	var mat = StandardMaterial3D.new()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.albedo_texture = PixelTextureGenerator.get_item_icon(item_id)

	if item_id == "phosphor" or item_id == "mushroom" or item_id == "amethyst_shard" or item_id == "ancient_core":
		mat.emission_enabled = true
		mat.emission_texture = mat.albedo_texture
		mat.emission_energy_multiplier = 2.6
		mat.roughness = 0.20

		item_light = OmniLight3D.new()
		if item_id == "mushroom":
			item_light.light_color = Color(0.25, 0.92, 0.85)
		elif item_id == "amethyst_shard":
			item_light.light_color = Color(0.75, 0.35, 1.0)
		elif item_id == "ancient_core":
			item_light.light_color = Color(0.15, 0.90, 1.0)
		else:
			item_light.light_color = Color(0.20, 0.95, 0.90)
		item_light.light_energy = 0.85
		item_light.omni_range = 3.2
		add_child(item_light)
	elif item_id == "iron" or item_id == "gold" or item_id == "copper":
		mat.metallic = 0.85
		mat.roughness = 0.35
	else:
		mat.roughness = 0.80
		mat.metallic = 0.10

	mesh_instance.material_override = mat
	add_child(mesh_instance)

func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime > max_lifetime:
		queue_free()
		return

	# Idle spin and hover bobbing
	if mesh_instance:
		mesh_instance.rotate_y(delta * 2.2)
		mesh_instance.position.y = sin(lifetime * 3.2) * 0.04

	# Fall physics until grounded
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

func get_item_name() -> String:
	match item_id:
		"phosphor": return "Phosphor Crystal"
		"iron": return "Iron Ingot"
		"copper": return "Copper Ingot"
		"gold": return "Gold Ingot"
		"coal": return "Coal"
		"calcite": return "Calcite Crystal"
		"timber": return "Hewn Timber"
		"planks": return "Wood Planks"
		"cobblestone": return "Cobblestone"
		"mushroom": return "Biolum Mushroom"
		"lichen": return "Lichen Root"
		"amethyst_shard": return "Amethyst Shard"
		"flare": return "Signal Flare"
		"dynamite": return "Dynamite"
		"grappling_rope": return "Grappling Hook"
		"obsidian_blade": return "Obsidian Blade"
		"salve": return "Restorative Salve"
		"water": return "Glacial Water"
		"rations": return "Survival Rations"
		_: return item_id.capitalize()

func get_interaction_prompt() -> String:
	return "Pick up %s (x%d)" % [get_item_name(), amount]

func interact(p: CharacterBody3D) -> bool:
	_collect(p)
	return true

func _collect(p: CharacterBody3D) -> void:
	# Add to inventory
	var added = false
	if "inventory_system" in p and p.inventory_system:
		added = p.inventory_system.add_item(item_id, amount)
	elif p.has_method("add_resource"):
		p.add_resource(item_id, amount)
		added = true

	# Play satisfying brass chime pickup sound
	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("item_pickup", global_position)

	# Notify HUD
	var hud_node = get_tree().get_first_node_in_group("hud")
	if hud_node == null and "hud" in p:
		hud_node = p.hud
	if hud_node and hud_node.has_method("show_pickup_notice"):
		hud_node.show_pickup_notice(item_id, get_item_name(), amount)

	queue_free()
