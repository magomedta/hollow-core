extends SceneTree

func _init() -> void:
	var main_scene = load("res://scenes/main.tscn")
	var root_node = main_scene.instantiate()
	root.add_child(root_node)

	for i in range(15):
		await process_frame

	var player = root_node.get_node_or_null("Player")
	player.set_active_slot(2) # Pickaxe

	# Position player facing solid stone wall at x=8.0, z=5.0
	player.global_position = Vector3(7.60, 11.0, 5.0)
	player.neck.rotation_degrees = Vector3.ZERO
	player.camera.rotation_degrees = Vector3(0, -90, 0) # Face +X into wall at x=8.0

	for i in range(10):
		await process_frame

	var img = root.get_texture().get_image()
	if img:
		img.save_png("res://screenshots/test_pickaxe_wall.png")
		print("Saved test_pickaxe_wall.png")

	# Now trigger a swing against the wall
	player.pickaxe.swing()
	for i in range(5):
		await process_frame

	var img_swing = root.get_texture().get_image()
	if img_swing:
		img_swing.save_png("res://screenshots/test_pickaxe_swing_wall.png")
		print("Saved test_pickaxe_swing_wall.png")

	quit(0)
