# scripts/gameplay/rock_anchor.gd
class_name RockAnchor
extends StaticBody3D

## Industrial High-Tensile Steel Expansion Anchor for Subterranean Climbing & Bridging
## Driven directly into solid rock faces to anchor safety lines and traversal ropes.

@export var anchor_id: String = ""
var surface_normal: Vector3 = Vector3.UP
var rope_length: float = 3.5

var bolt_mesh: MeshInstance3D
var ring_mesh: MeshInstance3D
var rope_root: Node3D

func _init(p_normal: Vector3 = Vector3.UP, p_rope_len: float = 3.5) -> void:
	surface_normal = p_normal
	rope_length = p_rope_len
	anchor_id = "anchor_%d_%d" % [Time.get_ticks_msec(), randi() % 10000]

func _ready() -> void:
	add_to_group("placed_anchors")
	add_to_group("interactable")
	collision_layer = 1 | 8 # Static world + interactable
	collision_mask = 0

	_construct_visuals()

func _construct_visuals() -> void:
	# Steel anchor material
	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.28, 0.32, 0.38, 1.0)
	steel_mat.metallic = 0.85
	steel_mat.roughness = 0.35

	# Heavy forged eyelet ring
	ring_mesh = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.045
	torus.outer_radius = 0.080
	torus.ring_segments = 8
	torus.rings = 12
	ring_mesh.mesh = torus
	ring_mesh.material_override = steel_mat
	ring_mesh.position = Vector3(0, 0, 0.08)
	ring_mesh.rotation_degrees = Vector3(90, 0, 0)
	add_child(ring_mesh)

	# Expansion sleeve bolt embedded into rock
	bolt_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.024
	cyl.bottom_radius = 0.024
	cyl.height = 0.22
	cyl.radial_segments = 6
	bolt_mesh.mesh = cyl
	bolt_mesh.material_override = steel_mat
	bolt_mesh.position = Vector3(0, 0, -0.04)
	bolt_mesh.rotation_degrees = Vector3(90, 0, 0)
	add_child(bolt_mesh)

	# Collision box for anchor mount
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.24, 0.24, 0.20)
	col.shape = box
	col.position = Vector3(0, 0, 0.05)
	add_child(col)

	# Hanging synthetic hemp climbing rope
	_construct_hanging_rope()

func _construct_hanging_rope() -> void:
	rope_root = Node3D.new()
	rope_root.name = "ClimbingRope"
	add_child(rope_root)

	var rope_mat = StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.48, 0.40, 0.30, 1.0) # Weathered hemp
	rope_mat.roughness = 0.90

	var seg_count = int(ceil(rope_length / 0.5))
	for i in range(seg_count):
		var seg = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.018
		cyl.bottom_radius = 0.018
		cyl.height = 0.50
		cyl.radial_segments = 5
		seg.mesh = cyl
		seg.material_override = rope_mat
		seg.position = Vector3(0, -0.25 - (i * 0.48), 0.08)
		rope_root.add_child(seg)

		# Knot every 1 meter
		if i % 2 == 1:
			var knot = MeshInstance3D.new()
			var knot_sphere = SphereMesh.new()
			knot_sphere.radius = 0.035
			knot_sphere.height = 0.060
			knot.mesh = knot_sphere
			knot.material_override = rope_mat
			knot.position = Vector3(0, -0.48 - (i * 0.48), 0.08)
			rope_root.add_child(knot)

func get_interaction_prompt() -> String:
	return "Climb / Inspect Expansion Anchor"

func interact(player: CharacterBody3D) -> bool:
	# Subtle metallic tactile ring feedback
	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("pickaxe_stone", global_position, 1.4, -6.0)

	# Nudge player upwards if climbing
	if player and "velocity" in player:
		player.velocity.y = 4.5
	return true

## Persistence serialization
func serialize() -> Dictionary:
	return {
		"id": anchor_id,
		"pos_x": global_position.x,
		"pos_y": global_position.y,
		"pos_z": global_position.z,
		"norm_x": surface_normal.x,
		"norm_y": surface_normal.y,
		"norm_z": surface_normal.z,
		"rot_x": rotation.x,
		"rot_y": rotation.y,
		"rot_z": rotation.z,
		"rope_len": rope_length
	}

static func deserialize(data: Dictionary) -> StaticBody3D:
	var norm = Vector3(data.get("norm_x", 0), data.get("norm_y", 1), data.get("norm_z", 0))
	var rope_len = data.get("rope_len", 3.5)
	var anchor_script = load("res://scripts/gameplay/rock_anchor.gd")
	var anchor = anchor_script.new(norm, rope_len)
	anchor.anchor_id = data.get("id", "anchor_loaded")
	anchor.position = Vector3(data.get("pos_x", 0), data.get("pos_y", 0), data.get("pos_z", 0))
	anchor.rotation = Vector3(data.get("rot_x", 0), data.get("rot_y", 0), data.get("rot_z", 0))
	return anchor
