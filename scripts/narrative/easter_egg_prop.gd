# scripts/narrative/easter_egg_prop.gd
class_name EasterEggProp
extends "res://scripts/narrative/interactive_prop.gd"

## Universal Physical 3D In-World Easter Egg Prop for Hollow Core.
## Represents hidden objects, secret historical curiosities, and environmental storytelling.
## Integrates directly with SecretRegistry, NarrativeManager, and ClueChainRegistry.

const SecretRegistryClass = preload("res://scripts/narrative/secret_registry.gd")

@export var easter_egg_id: String = "EE-01"

var prop_visual_mesh: MeshInstance3D = null

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("secrets")
	collision_layer = 4 | 8 # Item layer + interactable
	collision_mask = 0

	var egg_data = SecretRegistryClass.get_easter_egg(easter_egg_id)
	var egg_name = egg_data.get("name", "Тайна " + easter_egg_id)
	prompt_message = "[E] ОСМОТРЕТЬ: %s" % egg_name.to_upper()
	is_one_shot = true
	sfx_on_interact = "item_pickup"

	_build_visuals()

	if get_node_or_null("CollisionShape3D") == null:
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(0.5, 0.5, 0.5)
		col.shape = box
		add_child(col)

func _build_visuals() -> void:
	prop_visual_mesh = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()

	match easter_egg_id:
		"EE-01": # Music box (wood with brass inlays)
			var box = BoxMesh.new()
			box.size = Vector3(0.35, 0.22, 0.25)
			prop_visual_mesh.mesh = box
			mat.albedo_color = Color(0.38, 0.22, 0.12, 1.0)
			mat.roughness = 0.6
		"EE-02": # Chess table (slate block with small markers)
			var box = BoxMesh.new()
			box.size = Vector3(0.40, 0.25, 0.40)
			prop_visual_mesh.mesh = box
			mat.albedo_color = Color(0.25, 0.27, 0.30, 1.0)
		"EE-03": # Canary cage (brass wire cylinder)
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.15
			cyl.bottom_radius = 0.15
			cyl.height = 0.35
			prop_visual_mesh.mesh = cyl
			mat.albedo_color = Color(0.72, 0.60, 0.25, 1.0)
			mat.metallic = 0.8
		"EE-04": # Ghostly handprint (luminescent cyan on basalt)
			var quad = QuadMesh.new()
			quad.size = Vector2(0.30, 0.35)
			prop_visual_mesh.mesh = quad
			mat.albedo_color = Color(0.20, 0.85, 0.75, 0.9)
			mat.emission_enabled = true
			mat.emission = Color(0.20, 0.85, 0.75)
			mat.emission_energy_multiplier = 2.0
		"EE-05": # Clock without hands (dark wooden octagonal case)
			var box = BoxMesh.new()
			box.size = Vector3(0.30, 0.45, 0.12)
			prop_visual_mesh.mesh = box
			mat.albedo_color = Color(0.28, 0.18, 0.10, 1.0)
		"EE-07": # Miner helmet #104 (dented oxidized copper)
			var sphere = SphereMesh.new()
			sphere.radius = 0.16
			sphere.height = 0.22
			prop_visual_mesh.mesh = sphere
			mat.albedo_color = Color(0.65, 0.42, 0.25, 1.0)
			mat.metallic = 0.7
		"EE-08": # Electric kettle on stove (nickel-plated)
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.12
			cyl.bottom_radius = 0.14
			cyl.height = 0.28
			prop_visual_mesh.mesh = cyl
			mat.albedo_color = Color(0.75, 0.78, 0.80, 1.0)
			mat.metallic = 0.85
		"EE-09": # Gramophone with broken shellac record
			var box = BoxMesh.new()
			box.size = Vector3(0.38, 0.20, 0.38)
			prop_visual_mesh.mesh = box
			mat.albedo_color = Color(0.30, 0.20, 0.15, 1.0)
		_: # Generic weathered artifact
			var box = BoxMesh.new()
			box.size = Vector3(0.30, 0.30, 0.30)
			prop_visual_mesh.mesh = box
			mat.albedo_color = Color(0.40, 0.45, 0.50, 1.0)

	prop_visual_mesh.material_override = mat
	add_child(prop_visual_mesh)

func get_interaction_prompt() -> String:
	var egg_data = SecretRegistryClass.get_easter_egg(easter_egg_id)
	return "Осмотреть: %s" % egg_data.get("name", easter_egg_id)

func _execute_interaction(_player: CharacterBody3D) -> void:
	var tree = get_tree() if is_inside_tree() else null
	if tree:
		var nm = tree.get_first_node_in_group("narrative_manager")
		if nm:
			if nm.has_method("register_secret"):
				nm.register_secret(easter_egg_id)

			# Clue chain connections
			if easter_egg_id == "EE-04" and nm.has_method("unlock_clue"):
				nm.unlock_clue("CH-04", 2) # Light handprint on basalt
			elif easter_egg_id == "EE-20" and nm.has_method("unlock_clue"):
				nm.unlock_clue("CH-03", 3) # Lithoacoustic phantom in EE-27

		var hud = tree.get_first_node_in_group("hud")
		if hud and hud.has_method("show_pickup_notice"):
			var egg_data = SecretRegistryClass.get_easter_egg(easter_egg_id)
			hud.show_pickup_notice(easter_egg_id, "СЕКРЕТ: " + egg_data.get("name", easter_egg_id), 1)
