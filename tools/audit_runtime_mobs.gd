extends SceneTree

func _init():
	var mob_scripts = [
		"res://scripts/abyssal_glider.gd",
		"res://scripts/cave_wyrm.gd",
		"res://scripts/chasm_stalker.gd",
		"res://scripts/cryo_wisp.gd",
		"res://scripts/fungal_strider.gd",
		"res://scripts/geode_golem.gd",
		"res://scripts/lithic_crawler.gd",
		"res://scripts/magma_basilisk.gd",
		"res://scripts/pale_stalker.gd",
		"res://scripts/spore_spitter.gd",
		"res://scripts/wall_mimic.gd"
	]
	
	print("=== RUNTIME MOB VISUAL AUDIT ===")
	for script_path in mob_scripts:
		print("Checking: ", script_path)
		var script_res = load(script_path)
		if not script_res:
			print("FAIL TO LOAD SCRIPT: ", script_path)
			continue
		if not script_res.can_instantiate():
			print("CANNOT INSTANTIATE (compile error in script?): ", script_path)
			continue
		var mob = script_res.new()
		var script_name = script_path.get_file()
		print("\n>>> MOB: ", script_name)
		
		# Add to tree temporarily so _ready runs
		root.add_child(mob)
		if mob.has_method("_ready"):
			mob._ready()
		
		# Inspect all child meshes of mob
		_inspect_mob_meshes(mob, "")
		
		mob.queue_free()
	quit(0)

func _inspect_mob_meshes(node: Node, indent: String):
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node
		var mesh_info = "null"
		if mi.mesh:
			mesh_info = mi.mesh.get_class()
		var mat_info = "NONE"
		if mi.material_override:
			mat_info = _describe_mat(mi.material_override)
		elif mi.mesh and mi.mesh.get_surface_count() > 0:
			var surf_mats = []
			for s in range(mi.mesh.get_surface_count()):
				var sm = mi.get_surface_override_material(s)
				if not sm:
					sm = mi.mesh.surface_get_material(s)
				surf_mats.append(_describe_mat(sm))
			mat_info = ", ".join(surf_mats)
		print(indent + "  [Mesh] ", mi.name, " (", mesh_info, ") -> Mat: ", mat_info)
	for child in node.get_children():
		_inspect_mob_meshes(child, indent + "  ")

func _describe_mat(mat: Material) -> String:
	if mat == null:
		return "NULL_MAT"
	if mat is StandardMaterial3D:
		var sm: StandardMaterial3D = mat
		var tex = "no_tex"
		if sm.albedo_texture:
			tex = sm.albedo_texture.resource_path.get_file()
		var col = sm.albedo_color
		return "StdMat(tex=%s, col=(%.2f,%.2f,%.2f))" % [tex, col.r, col.g, col.b]
	return mat.get_class()
