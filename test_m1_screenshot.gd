# test_m1_screenshot.gd
extends SceneTree

const M1VerticalSliceScene = preload("res://scenes/development/m1_vertical_slice.tscn")

func _init() -> void:
	print("[M1 Screenshot] Starting multi-perspective visual capture...")
	var m1_instance = M1VerticalSliceScene.instantiate()
	root.add_child(m1_instance)

	var dir = DirAccess.open("res://")
	if not dir.dir_exists("screenshots"):
		dir.make_dir("screenshots")

	# Wait 35 frames for full geometry meshing and lighting initialization
	for i in range(35):
		await process_frame

	var player = m1_instance.get_node_or_null("Player")
	var neck = player.get_node_or_null("Neck") if player else null

	# --- SHOT 1: Glacial Approach Tunnel looking into Airlock Station 4 with Brass Lantern in Hand ---
	if player:
		if player.pickaxe:
			player.pickaxe.set_active(false)
		if player.lantern:
			player.lantern.set_hand_mode(true)
			player.lantern.set_lit(true)

		# Positioned on descent ramp right before Station 4 portal (X=8.5), looking down through portal archway
		player.global_position = Vector3(8.5, 46.5, -10.0)
		player.look_at(Vector3(13.0, 41.5, -10.0), Vector3.UP)
		if neck:
			neck.rotation_degrees = Vector3.ZERO

	for i in range(40):
		await process_frame

	_save_viewport_shot("res://screenshots/m1_01_approach_and_airlock.png")

	# --- SHOT 2: Echo Shaft Chasm & Bioluminescent Ledges with The Watcher in the Fog ---
	if player:
		if player.lantern:
			player.lantern.set_hand_mode(false) # Harness mode: illuminates forward, pickaxe held in hand
			player.lantern.set_lit(true)
		if player.pickaxe:
			player.pickaxe.set_active(true)

		# Standing on overlook ledge looking across 20m abyss towards Watcher on West Ledge
		player.global_position = Vector3(2.8, 34.8, -17.0)
		player.look_at(Vector3(-14.0, 32.5, -22.0), Vector3.UP)
		if neck:
			neck.rotation_degrees = Vector3.ZERO

	for i in range(40):
		await process_frame

	_save_viewport_shot("res://screenshots/m1_02_echo_shaft_chasm.png")

	# --- SHOT 3: Document D-01 Reading Interface (Clean Inspection, Zero Tool Clipping) ---
	if player:
		# Standing right at the surveyor workstation desk in Station 4, looking down at the desk
		player.global_position = Vector3(12.5, 39.5, -5.2)
		player.rotation_degrees = Vector3(0, 0.0, 0)
		if neck:
			neck.rotation_degrees = Vector3(-25.0, 0, 0)
		var doc_prop = m1_instance.level_manager.doc_d01_prop if m1_instance.level_manager else null
		if doc_prop:
			doc_prop.interact(player)

	for i in range(40):
		await process_frame

	_save_viewport_shot("res://screenshots/m1_03_document_d01_inspection.png")

	# Close document before Shot 4
	if m1_instance.document_viewer and m1_instance.document_viewer.visible:
		m1_instance.document_viewer.hide_document()

	for i in range(15):
		await process_frame

	# --- SHOT 4: The Watcher in the Cavern Fog (Direct Homage to Minecraft Alpha Creepypasta) ---
	if player:
		if player.lantern:
			player.lantern.set_hand_mode(false)
			player.lantern.set_lit(true)
		if player.pickaxe:
			player.pickaxe.set_active(true)

		# Positioned on distant ledge (18m away, > 14m so Watcher NEVER vanishes!)
		player.global_position = Vector3(4.0, 34.5, -22.0)
		player.look_at(Vector3(-14.0, 32.8, -22.0), Vector3.UP)
		if neck:
			neck.rotation_degrees = Vector3.ZERO

	for i in range(40):
		await process_frame

	_save_viewport_shot("res://screenshots/m1_04_the_watcher_in_fog.png")

	print("[M1 Screenshot] All 4 visual verification captures completed!")
	quit(0)

func _save_viewport_shot(path: String) -> void:
	var vp_tex = root.get_texture()
	if vp_tex:
		var img = vp_tex.get_image()
		if img and not img.is_empty():
			img.save_png(path)
			print("[M1 Screenshot] Saved: ", path)
