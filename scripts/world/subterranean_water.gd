# scripts/world/subterranean_water.gd
class_name SubterraneanWater
extends Node3D

## Physical Subterranean Water Body.
## Provides visual surface and physical Area3D trigger that slows player movement,
## triggers wading slosh audio, and modulates acoustic reflections.

@export var water_size: Vector3 = Vector3(10.0, 1.2, 10.0)
@export var water_color: Color = Color(0.04, 0.10, 0.16, 0.82)

var area: Area3D
var collision_shape: CollisionShape3D
var mesh_instance: MeshInstance3D

func _init(p_size: Vector3 = Vector3(10.0, 1.2, 10.0)) -> void:
	water_size = p_size

func _ready() -> void:
	_create_visual_mesh()
	_create_physical_trigger()

func _create_visual_mesh() -> void:
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "WaterSurface"

	var box = BoxMesh.new()
	box.size = water_size
	mesh_instance.mesh = box

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = water_color
	mat.roughness = 0.08
	mat.metallic = 0.15
	mat.refraction_enabled = true
	mat.refraction_scale = 0.02
	mesh_instance.material_override = mat

	add_child(mesh_instance)

func _create_physical_trigger() -> void:
	area = Area3D.new()
	area.name = "WaterArea"
	area.collision_layer = 0
	area.collision_mask = 2 # Player collision layer

	collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = water_size
	collision_shape.shape = box_shape
	area.add_child(collision_shape)

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("set_in_water"):
			body.set_in_water(true, global_position.y + water_size.y * 0.5)
		else:
			body.set("is_wading_in_water", true)

		# Splash sound
		var sm = get_tree().get_first_node_in_group("sound_manager")
		if sm and sm.has_method("play_sfx"):
			sm.play_sfx("footstep_stone", body.global_position, 0.85, -3.0)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("set_in_water"):
			body.set_in_water(false, 0.0)
		else:
			body.set("is_wading_in_water", false)
