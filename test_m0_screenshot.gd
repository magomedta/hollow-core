# test_m0_screenshot.gd
extends SceneTree

func _init() -> void:
	print("[M0 Screenshot] Launching M0 scene for visual verification...")
	var m0_scene_res = load("res://scenes/development/m0_core_test.tscn")
	if not m0_scene_res:
		printerr("[M0 Screenshot] Failed to load scenes/development/m0_core_test.tscn")
		quit(1)
		return

	var m0_instance = m0_scene_res.instantiate()
	root.add_child(m0_instance)

	# Wait 20 frames for initial geometry
	for i in range(20):
		await process_frame

	var player = m0_instance.get_node_or_null("Player")
	if player:
		# Position player in the center of the Outpost archway looking out into the grand subterranean basalt cathedral
		player.global_position = Vector3(0.0, 11.0, 4.0)
		var cam = player.get_node_or_null("Head/Camera3D")
		if cam:
			cam.rotation_degrees = Vector3(-6.0, 180.0, 0.0)

	# Render for 30 more frames with updated camera perspective
	for i in range(30):
		await process_frame

	var dir = DirAccess.open("res://")
	if not dir.dir_exists("screenshots"):
		dir.make_dir("screenshots")

	var vp_tex = root.get_texture()
	if vp_tex:
		var img = vp_tex.get_image()
		if img and not img.is_empty():
			var out_path = "res://screenshots/m0_core_verification.png"
			var err = img.save_png(out_path)
			if err == OK:
				print("[M0 Screenshot] Successfully saved screenshot to: ", out_path)
			else:
				printerr("[M0 Screenshot] Failed to save png, err: ", err)
		else:
			printerr("[M0 Screenshot] Viewport image is empty")
	else:
		printerr("[M0 Screenshot] Could not get viewport texture")

	quit(0)
