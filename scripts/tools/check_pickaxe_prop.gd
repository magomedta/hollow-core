extends SceneTree
const M1 = preload("res://scenes/development/m1_vertical_slice.tscn")
func _init():
	var m = M1.instantiate()
	root.add_child(m)
	for i in range(10):
		await process_frame
	var sm = m.get_node_or_null("ScenarioManager")
	if sm and sm.pickaxe_prop:
		print("PICKAXE PROP GLOBAL POS: ", sm.pickaxe_prop.global_position)
		print("PICKAXE PROP CHILDREN: ", sm.pickaxe_prop.get_child_count())
		for c in sm.pickaxe_prop.get_children():
			print("  CHILD: ", c.name, " (", c.get_class(), ")")
	quit(0)
