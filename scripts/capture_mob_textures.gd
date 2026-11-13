# scripts/capture_mob_textures.gd
extends SceneTree

func _init() -> void:
	print("[MobCapture] Initializing Mob Texture Showcase Capture...")
	var res = load("res://scenes/main.tscn")
	var main_node = res.instantiate()
	root.add_child(main_node)
	call_deferred("_run_capture", main_node)

func _run_capture(main_node: Node3D) -> void:
	for f in range(25):
		await process_frame

	var player = main_node.player
	var enemies = main_node.enemies_container
	var out_dir = ProjectSettings.globalize_path("res://screenshots")

	# 1. Chasm Stalker
	var stalker = enemies.get_node_or_null("ChasmStalker_Corridor")
	if stalker and player:
		# Freeze stalker movement for clean beauty shot
		stalker.set_physics_process(false)
		player.set_active_slot(1)
		player.lantern.set_lit(true)
		player.global_position = stalker.global_position + Vector3(0.0, 0.3, 2.2)
		player.camera.look_at(stalker.global_position + Vector3(0, 0.5, 0), Vector3.UP)
		for f in range(15):
			await process_frame
		var img1 = root.get_viewport().get_texture().get_image()
		if img1:
			img1.save_png(out_dir + "/horror_04_chasm_stalker_closeup.png")
			print("[MobCapture] Saved: horror_04_chasm_stalker_closeup.png")

	# 2. Lithic Crawler
	var crawler = enemies.get_node_or_null("LithicCrawler_Outpost")
	if not crawler:
		# If not at outpost, check dynamic or spawn one for capture
		var crawler_class = load("res://scripts/lithic_crawler.gd")
		crawler = crawler_class.new()
		crawler.name = "ShowcaseCrawler"
		crawler.position = Vector3(10.0, 10.5, 0.0)
		enemies.add_child(crawler)

	if crawler and player:
		crawler.set_physics_process(false)
		player.global_position = crawler.global_position + Vector3(1.6, 0.4, 1.6)
		player.camera.look_at(crawler.global_position + Vector3(0, 0.3, 0), Vector3.UP)
		for f in range(15):
			await process_frame
		var img2 = root.get_viewport().get_texture().get_image()
		if img2:
			img2.save_png(out_dir + "/horror_06_lithic_crawler_closeup.png")
			print("[MobCapture] Saved: horror_06_lithic_crawler_closeup.png")

	print("[MobCapture] Done capturing mob closeups.")
	quit(0)
