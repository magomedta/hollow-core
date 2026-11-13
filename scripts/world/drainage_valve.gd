# scripts/world/drainage_valve.gd
class_name DrainageValveProp
extends StaticBody3D

## Interactive heavy cast-iron gate valve wheel at Airlock Station 4.
## Turning the valve drains the lower sump collector, exposing EE-06 Safe.

signal valve_turned()

@export var is_turned: bool = false
var wheel_mesh: MeshInstance3D

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 1 | 8
	collision_mask = 0

	_construct_valve_mesh()

func _construct_valve_mesh() -> void:
	# Pipe mount
	var pipe = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.08
	cyl.bottom_radius = 0.08
	cyl.height = 0.35
	cyl.radial_segments = 8
	pipe.mesh = cyl

	var iron_mat = StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.22, 0.24, 0.26, 1.0)
	iron_mat.metallic = 0.85
	iron_mat.roughness = 0.60
	pipe.material_override = iron_mat
	pipe.rotation_degrees = Vector3(90, 0, 0)
	add_child(pipe)

	# Red-orange painted iron handwheel
	wheel_mesh = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.16
	torus.outer_radius = 0.24
	torus.rings = 12
	torus.ring_segments = 8
	wheel_mesh.mesh = torus

	var wheel_mat = StandardMaterial3D.new()
	wheel_mat.albedo_color = Color(0.65, 0.22, 0.15, 1.0) # Weathered red lead paint
	wheel_mat.metallic = 0.70
	wheel_mat.roughness = 0.50
	wheel_mesh.material_override = wheel_mat
	wheel_mesh.position = Vector3(0, 0, 0.20)
	add_child(wheel_mesh)

	# 4 spokes
	for a in [0.0, PI * 0.5]:
		var spoke = MeshInstance3D.new()
		var sp_cyl = CylinderMesh.new()
		sp_cyl.top_radius = 0.015
		sp_cyl.bottom_radius = 0.015
		sp_cyl.height = 0.44
		sp_cyl.radial_segments = 6
		spoke.mesh = sp_cyl
		spoke.material_override = wheel_mat
		spoke.rotation_degrees = Vector3(0, 0, rad_to_deg(a))
		wheel_mesh.add_child(spoke)

	# Collision shape
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.55, 0.55, 0.40)
	col.shape = box
	col.position = Vector3(0, 0, 0.10)
	add_child(col)

func get_interaction_prompt() -> String:
	if is_turned:
		return "Маховик Дренажной Задвижки [ОТКРЫТ]"
	return "Повернуть Маховик Дренажной Задвижки"

func interact(_player: CharacterBody3D) -> bool:
	if is_turned:
		return false

	is_turned = true
	var tw = create_tween()
	tw.tween_property(wheel_mesh, "rotation_degrees:z", 720.0, 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Play creaking iron valve sound and draining water roar
	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("pickaxe_stone", global_position, 0.6, 2.0)

	valve_turned.emit()
	return true
