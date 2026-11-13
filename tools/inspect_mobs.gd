extends SceneTree

func _init():
	var glbs = [
		"res://models/abyssal_glider.glb",
		"res://models/cave_wyrm.glb",
		"res://models/chasm_stalker.glb",
		"res://models/cryo_wisp.glb",
		"res://models/fungal_strider.glb",
		"res://models/geode_golem.glb",
		"res://models/lithic_crawler.glb",
		"res://models/magma_basilisk.glb",
		"res://models/pale_lurker.glb",
		"res://models/spore_spitter.glb",
		"res://models/wall_mimic.glb"
	]
	
	for path in glbs:
		var scene = load(path)
		if not scene:
			print("FAIL TO LOAD: ", path)
			continue
		var inst = scene.instantiate()
		print("=== GLB: ", path.get_file(), " ===")
		_inspect_node(inst, "  ")
		inst.queue_free()
	quit(0)

func _inspect_node(node: Node, indent: String):
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node
		print(indent, "MeshInstance3D: ", mi.name)
		if mi.material_override:
			_print_mat(mi.material_override, indent + "  [mat_override] ")
		if mi.mesh:
			for i in range(mi.mesh.get_surface_count()):
				var mat = mi.get_surface_override_material(i)
				if not mat:
					mat = mi.mesh.surface_get_material(i)
				_print_mat(mat, indent + "  [surf " + str(i) + "] ")
	for child in node.get_children():
		_inspect_node(child, indent + "  ")

func _print_mat(mat: Material, prefix: String):
	if mat == null:
		print(prefix, "NULL Material (UNTEXTURED!)")
	elif mat is StandardMaterial3D:
		var sm: StandardMaterial3D = mat
		var tex_name = "NONE"
		if sm.albedo_texture:
			tex_name = sm.albedo_texture.resource_path
		var emit_name = "NONE"
		if sm.emission_texture:
			emit_name = sm.emission_texture.resource_path
		print(prefix, "StandardMaterial3D: color=", sm.albedo_color, ", tex=", tex_name, ", emit=", sm.emission_enabled, ", emit_tex=", emit_name)
	elif mat is ORMMaterial3D:
		var om: ORMMaterial3D = mat
		var tex_name = "NONE"
		if om.albedo_texture:
			tex_name = om.albedo_texture.resource_path
		print(prefix, "ORMMaterial3D: color=", om.albedo_color, ", tex=", tex_name)
	else:
		print(prefix, "Other Material: ", mat.get_class())
