# hollow_core/capture_verification_screenshots.gd
# Captures in-game screenshots for visual verification
extends SceneTree

func _init() -> void:
	call_deferred("_run_capture")

func _run_capture() -> void:
	print("[SCREENSHOT] Initializing scene for visual verification...")
	var main_scene = load("res://scenes/main.tscn")
	assert(main_scene != null)
	var root_node = main_scene.instantiate()
	root.add_child(root_node)

	# Wait 15 frames for everything to settle
	for f in range(15):
		await process_frame

	var player = root_node.get_node_or_null("Player")
	var hud = root_node.get_node_or_null("HUD")
	var inv = root_node.get_node_or_null("Inventory")

	DirAccess.make_dir_absolute("user://screenshots")
	var out_dir = ProjectSettings.globalize_path("res://screenshots")
	DirAccess.make_dir_absolute(out_dir)

	# 1. Capture Normal Cavern View with HUD & Pickaxe
	await process_frame
	var img1 = root.get_texture().get_image()
	if img1 and not img1.is_empty():
		img1.save_png(out_dir + "/01_cavern_view_hud.png")
		print("Saved screenshot 1: ", out_dir + "/01_cavern_view_hud.png")

	# 2. Capture Viewmodel Wall Retraction (approach wall directly)
	if player:
		# Place player right up against solid stone wall at x=8.0, z=5.0
		player.set_active_slot(2) # Equip pickaxe to verify anti-clipping & wall tuck
		player.global_position = Vector3(7.60, 11.0, 5.0)
		player.neck.rotation_degrees = Vector3.ZERO
		player.camera.rotation_degrees = Vector3(0, -90, 0) # Face directly towards the wall (+X)
		for f in range(12):
			await process_frame
		var img2 = root.get_texture().get_image()
		if img2 and not img2.is_empty():
			img2.save_png(out_dir + "/02_viewmodel_wall_proximity_retraction.png")
			print("Saved screenshot 2: ", out_dir + "/02_viewmodel_wall_proximity_retraction.png")

	# 3. Capture Inventory Screen with Overhauled Polished Icons
	if player and player.inventory_system:
		var inv_sys = player.inventory_system
		inv_sys.set_open(true)
		for f in range(8):
			await process_frame
		var img3 = root.get_texture().get_image()
		if img3 and not img3.is_empty():
			img3.save_png(out_dir + "/03_inventory_polished_icons.png")
			print("Saved screenshot 3: ", out_dir + "/03_inventory_polished_icons.png")
		inv_sys.set_open(false)
		for f in range(3):
			await process_frame

	# 4. Capture 3D Blender Mobs (Chasm Stalker & Lithic Crawler)
	var enemies = root_node.get_node_or_null("Enemies")
	if player and enemies:
		var stalker = enemies.get_node_or_null("ChasmStalker_Corridor")
		if stalker:
			player.global_position = stalker.global_position + Vector3(0.0, 0.4, 2.2)
			player.camera.look_at(stalker.global_position + Vector3(0, 0.6, 0), Vector3.UP)
			for f in range(8):
				await process_frame
			var img_stalker = root.get_texture().get_image()
			if img_stalker and not img_stalker.is_empty():
				img_stalker.save_png(out_dir + "/05_blender_chasm_stalker.png")
				print("Saved screenshot 5: ", out_dir + "/05_blender_chasm_stalker.png")

		var crawler = enemies.get_node_or_null("LithicCrawler_Outpost")
		if crawler:
			player.global_position = crawler.global_position + Vector3(1.8, 0.5, 1.8)
			player.camera.look_at(crawler.global_position + Vector3(0, 0.3, 0), Vector3.UP)
			for f in range(8):
				await process_frame
			var img_crawler = root.get_texture().get_image()
			if img_crawler and not img_crawler.is_empty():
				img_crawler.save_png(out_dir + "/06_blender_lithic_crawler.png")
				print("Saved screenshot 6: ", out_dir + "/06_blender_lithic_crawler.png")

	# 4. Capture Subglacial Karst & Ceilings
	if player:
		player.global_position = Vector3(0.0, 24.5, 0.0)
		player.camera.rotation_degrees = Vector3(45, 0, 0) # Look up at ceiling drips
		for f in range(10):
			await process_frame
		var img4 = root.get_texture().get_image()
		if img4 and not img4.is_empty():
			img4.save_png(out_dir + "/04_subglacial_ceiling_water_drips.png")
			print("Saved screenshot 4: ", out_dir + "/04_subglacial_ceiling_water_drips.png")

	print("[SCREENSHOT] All visual verification screenshots captured successfully.")
	quit(0)
