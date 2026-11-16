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
	var iron_mat = StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.20, 0.22, 0.25, 1.0)
	iron_mat.metallic = 0.88
	iron_mat.roughness = 0.50

	var flange_mat = StandardMaterial3D.new()
	flange_mat.albedo_color = Color(0.16, 0.18, 0.20, 1.0)
	flange_mat.metallic = 0.90
	flange_mat.roughness = 0.45

	var brass_mat = StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.85, 0.70, 0.35, 1.0)
	brass_mat.metallic = 0.85
	brass_mat.roughness = 0.38

	# 1. Heavy Machinery Base Pedestal (Anchored into the trench floor at Y = -1.0)
	var pedestal = MeshInstance3D.new()
	var p_box = BoxMesh.new()
	p_box.size = Vector3(0.55, 0.45, 0.55)
	pedestal.mesh = p_box
	pedestal.material_override = flange_mat
	pedestal.position = Vector3(0, -0.80, 0)
	add_child(pedestal)

	# 2. Heavy Vertical Drainage Riser Pipe plunging into trench
	var v_pipe = MeshInstance3D.new()
	var v_cyl = CylinderMesh.new()
	v_cyl.top_radius = 0.12
	v_cyl.bottom_radius = 0.12
	v_cyl.height = 1.4
	v_cyl.radial_segments = 12
	v_pipe.mesh = v_cyl
	v_pipe.material_override = iron_mat
	v_pipe.position = Vector3(0, -0.15, 0)
	add_child(v_pipe)

	# Bottom and Mid Bolted Pipe Flanges
	for fy in [-0.55, -0.05]:
		var fl = MeshInstance3D.new()
		var f_cyl = CylinderMesh.new()
		f_cyl.top_radius = 0.20
		f_cyl.bottom_radius = 0.20
		f_cyl.height = 0.08
		f_cyl.radial_segments = 12
		fl.mesh = f_cyl
		fl.material_override = flange_mat
		fl.position = Vector3(0, fy, 0)
		add_child(fl)

		# 6 Hex Flange Bolts
		for b in range(6):
			var angle = b * (PI / 3.0)
			var bolt = MeshInstance3D.new()
			var b_cyl = CylinderMesh.new()
			b_cyl.top_radius = 0.018
			b_cyl.bottom_radius = 0.018
			b_cyl.height = 0.11
			b_cyl.radial_segments = 6
			bolt.mesh = b_cyl
			bolt.material_override = brass_mat
			bolt.position = Vector3(cos(angle) * 0.16, fy, sin(angle) * 0.16)
			add_child(bolt)

	# 3. Main Central Cast-Iron Valve Body (T-junction casing)
	var valve_body = MeshInstance3D.new()
	var vb_box = BoxMesh.new()
	vb_box.size = Vector3(0.34, 0.38, 0.34)
	valve_body.mesh = vb_box
	valve_body.material_override = iron_mat
	valve_body.position = Vector3(0, 0.15, 0)
	add_child(valve_body)

	# Horizontal manifold pipe running into wall (towards local -Z)
	var wall_pipe = MeshInstance3D.new()
	var wp_cyl = CylinderMesh.new()
	wp_cyl.top_radius = 0.12
	wp_cyl.bottom_radius = 0.12
	wp_cyl.height = 1.2
	wp_cyl.radial_segments = 12
	wall_pipe.mesh = wp_cyl
	wall_pipe.material_override = iron_mat
	wall_pipe.rotation_degrees = Vector3(90, 0, 0)
	wall_pipe.position = Vector3(0, 0.15, -0.6)
	add_child(wall_pipe)

	# Heavy Wall Flange collar
	var wall_flange = MeshInstance3D.new()
	var wf_cyl = CylinderMesh.new()
	wf_cyl.top_radius = 0.22
	wf_cyl.bottom_radius = 0.22
	wf_cyl.height = 0.10
	wf_cyl.radial_segments = 12
	wall_flange.mesh = wf_cyl
	wall_flange.material_override = flange_mat
	wall_flange.rotation_degrees = Vector3(90, 0, 0)
	wall_flange.position = Vector3(0, 0.15, -1.15)
	add_child(wall_flange)

	# 4. Top Bonnet, Stuffing Box & Antique Brass Pressure Gauge
	var bonnet = MeshInstance3D.new()
	var bn_cyl = CylinderMesh.new()
	bn_cyl.top_radius = 0.10
	bn_cyl.bottom_radius = 0.14
	bn_cyl.height = 0.22
	bn_cyl.radial_segments = 10
	bonnet.mesh = bn_cyl
	bonnet.material_override = iron_mat
	bonnet.position = Vector3(0, 0.42, 0)
	add_child(bonnet)

	# Threaded Spindle Stem
	var stem = MeshInstance3D.new()
	var st_cyl = CylinderMesh.new()
	st_cyl.top_radius = 0.035
	st_cyl.bottom_radius = 0.035
	st_cyl.height = 0.35
	st_cyl.radial_segments = 8
	stem.mesh = st_cyl
	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.70, 0.72, 0.75, 1.0)
	steel_mat.metallic = 0.95
	steel_mat.roughness = 0.25
	stem.mesh = st_cyl
	stem.material_override = steel_mat
	stem.position = Vector3(0, 0.58, 0)
	add_child(stem)

	# Pressure Gauge Assembly (standing proudly on top of bonnet)
	var gauge_dial = MeshInstance3D.new()
	var gd_cyl = CylinderMesh.new()
	gd_cyl.top_radius = 0.09
	gd_cyl.bottom_radius = 0.09
	gd_cyl.height = 0.04
	gd_cyl.radial_segments = 12
	gauge_dial.mesh = gd_cyl
	gauge_dial.material_override = brass_mat
	gauge_dial.rotation_degrees = Vector3(90, 0, 0)
	gauge_dial.position = Vector3(0, 0.74, 0.02)
	add_child(gauge_dial)

	var gauge_face = MeshInstance3D.new()
	var gf_cyl = CylinderMesh.new()
	gf_cyl.top_radius = 0.078
	gf_cyl.bottom_radius = 0.078
	gf_cyl.height = 0.005
	gf_cyl.radial_segments = 12
	gauge_face.mesh = gf_cyl
	var face_mat = StandardMaterial3D.new()
	face_mat.albedo_color = Color(0.92, 0.90, 0.82, 1.0) # Aged cream dial paper
	face_mat.roughness = 0.60
	gauge_face.material_override = face_mat
	gauge_face.rotation_degrees = Vector3(90, 0, 0)
	gauge_face.position = Vector3(0, 0.74, 0.042)
	add_child(gauge_face)

	var gauge_needle = MeshInstance3D.new()
	var gn_box = BoxMesh.new()
	gn_box.size = Vector3(0.006, 0.065, 0.003)
	gauge_needle.mesh = gn_box
	var needle_mat = StandardMaterial3D.new()
	needle_mat.albedo_color = Color(0.85, 0.15, 0.10, 1.0) # Red indicator needle
	gauge_needle.material_override = needle_mat
	gauge_needle.rotation_degrees = Vector3(0, 0, 35)
	gauge_needle.position = Vector3(0.015, 0.75, 0.045)
	add_child(gauge_needle)

	# 5. Heavy Cast-Iron Handwheel (Forward-facing toward the walkway at Z = +0.22)
	wheel_mesh = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.20
	torus.outer_radius = 0.28
	torus.rings = 16
	torus.ring_segments = 10
	wheel_mesh.mesh = torus

	var wheel_mat = StandardMaterial3D.new()
	wheel_mat.albedo_color = Color(0.68, 0.20, 0.14, 1.0) # Weathered red lead primer
	wheel_mat.metallic = 0.75
	wheel_mat.roughness = 0.45
	wheel_mesh.material_override = wheel_mat
	wheel_mesh.position = Vector3(0, 0.15, 0.22)
	add_child(wheel_mesh)

	# Brass Center Hub Cap
	var hub = MeshInstance3D.new()
	var h_cyl = CylinderMesh.new()
	h_cyl.top_radius = 0.05
	h_cyl.bottom_radius = 0.05
	h_cyl.height = 0.05
	h_cyl.radial_segments = 8
	hub.mesh = h_cyl
	hub.material_override = brass_mat
	hub.rotation_degrees = Vector3(90, 0, 0)
	hub.position = Vector3(0, 0.15, 0.22)
	add_child(hub)

	# 4 Heavy Tapered Spokes
	for a in [0.0, PI * 0.5]:
		var spoke = MeshInstance3D.new()
		var sp_cyl = CylinderMesh.new()
		sp_cyl.top_radius = 0.020
		sp_cyl.bottom_radius = 0.020
		sp_cyl.height = 0.52
		sp_cyl.radial_segments = 8
		spoke.mesh = sp_cyl
		spoke.material_override = wheel_mat
		spoke.rotation_degrees = Vector3(0, 0, rad_to_deg(a))
		wheel_mesh.add_child(spoke)

	# Solid Collision shape
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.65, 1.6, 0.65)
	col.shape = box
	col.position = Vector3(0, 0.10, 0.0)
	add_child(col)

func get_interaction_prompt() -> String:
	if is_turned:
		return "Маховик Дренажной Задвижки [ОТКРЫТ — ЗУМПФ ОСУШЕН]"
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
