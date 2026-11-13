extends SceneTree

func _init():
	print("Starting 120-frame runtime validation of Hollow Core...")
	var main_scene = load("res://scenes/main.tscn")
	if not main_scene:
		print("FAIL: Could not load main.tscn")
		quit(1)
		return
	var main = main_scene.instantiate()
	root.add_child(main)
	print("Main scene instantiated cleanly!")

	var frames = 0
	while frames < 120:
		await process_frame
		frames += 1
		if frames % 30 == 0:
			print("Processed frame ", frames, "/120")

	print("120-frame validation PASSED with ZERO crashes!")
	quit(0)
