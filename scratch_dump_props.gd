extends SceneTree

func _init() -> void:
	var scene = load("res://scenes/development/m1_vertical_slice.tscn").instantiate()
	root.add_child(scene)
	create_timer(0.3).timeout.connect(func():
		var lm = root.find_child("M1LevelManager", true, false)
		if lm:
			print("M1LevelManager found!")
			var props = lm.find_child("M1Props", true, false)
			if props:
				print("M1Props has ", props.get_child_count(), " children:")
				for c in props.get_children():
					print("  - ", c.name, " pos=", c.position, " gpos=", c.global_position if c is Node3D else "N/A")
			else:
				print("M1Props NOT FOUND")
		quit(0)
	)
