# scripts/tools/inspect_crash_site.gd
extends SceneTree

const M1Scene = preload("res://scenes/development/m1_vertical_slice.tscn")

func _init() -> void:
	var m1 = M1Scene.instantiate()
	root.add_child(m1)
	
	print("=== INSPECTING CRASH SITE GEOMETRY (ZONE A) ===")
	_dump_node(m1)
	quit(0)

func _dump_node(node: Node, depth: int = 0) -> void:
	if node is Node3D:
		var gp = node.global_position
		if gp.distance_to(Vector3(0, 57, 0)) < 15.0 or "Cage" in node.name or "Wreckage" in node.name or "base" in node.name:
			var extra = ""
			if node is MeshInstance3D and node.mesh:
				extra = " Mesh: %s (%s)" % [node.mesh.get_class(), str(node.mesh.get("size")) if node.mesh.get("size") != null else ""]
			print("%s- %s (%s) @ pos: %s%s" % ["  ".repeat(depth), node.name, node.get_class(), str(gp), extra])
	for child in node.get_children():
		_dump_node(child, depth + 1)
