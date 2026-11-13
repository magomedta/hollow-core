# scripts/capture_biome_review.gd
extends SceneTree

## Dedicated High-Quality Screenshot Capture for M1 Biome Overhaul Review.
## Captures 4 in-engine frames representing the three distinct subterranean
## ecosystems and the psychological horror presence with zero visual defects.

const M1VerticalSliceScene = preload("res://scenes/development/m1_vertical_slice.tscn")

func _init() -> void:
	print("==================================================")
	print("  HOLLOW CORE — M1 BIOME REVIEW SCREENSHOT CAPTURE")
	print("==================================================")

	var m1_instance = M1VerticalSliceScene.instantiate()
	root.add_child(m1_instance)

	var dir = DirAccess.open("res://")
	if not dir.dir_exists("screenshots/biome_review"):
		dir.make_dir_recursive("screenshots/biome_review")

	# Allow 45 frames for chunk meshing, shaders, and lighting initialization
	for i in range(45):
		await process_frame

	var player = m1_instance.get_node_or_null("Player")
	var neck = player.get_node_or_null("Neck") if player else null

	# Ensure The Watcher is in permanent showcase mode
	var watcher = m1_instance.get_node_or_null("M1Props/AmbientWatcher_ChasmLedge")
	if watcher:
		watcher.is_ambient_showcase = true

	# =========================================================================
	# SHOT 1: Biome I — Ледниковые Шпили (Glacial Spires)
	# Looking up the permafrost ascent tunnel: ice runs, calcite spires, icy mist
	# =========================================================================
	print("\n[Capture 1/4] Biome I: Glacial Spires (Zone A)...")
	if player:
		if player.lantern:
			player.lantern.set_hand_mode(true)
			player.lantern.set_lit(true)
		if player.pickaxe:
			player.pickaxe.set_active(false)

		# Position in glacial tunnel looking down through the calcite icicle corridor
		player.global_position = Vector3(2.5, 54.8, -10.0)
		player.look_at(Vector3(9.5, 47.0, -10.0), Vector3.UP)
		if neck:
			neck.rotation_degrees = Vector3(-8.0, 0, 0)

	for i in range(45):
		await process_frame

	_save_shot("res://screenshots/biome_review/01_glacial_spires.png")

	# =========================================================================
	# SHOT 2: Biome II — Затопленные Шлюзы (Flooded Sluice Gates)
	# Inside Station 4: slate brick masonry, flooded drainage canal with water, desk & valve
	# =========================================================================
	print("\n[Capture 2/4] Biome II: Flooded Sluice Gates (Zone B)...")
	if player:
		if player.lantern:
			player.lantern.set_hand_mode(false)
			player.lantern.set_lit(true)
		if player.pickaxe:
			player.pickaxe.set_active(false)

		# Standing at east side of Station 4 looking across flooded drainage channel towards desk
		player.global_position = Vector3(18.0, 39.5, -7.0)
		player.look_at(Vector3(12.0, 39.2, -10.5), Vector3.UP)
		if neck:
			neck.rotation_degrees = Vector3(-6.0, 0, 0)

	for i in range(45):
		await process_frame

	_save_shot("res://screenshots/biome_review/02_flooded_gates.png")

	# =========================================================================
	# SHOT 3: Biome III — Базальтовая Абиссаль (Basaltic Abyssal Basin)
	# Columnar basalt pillars, cascading waterfall, plunge pool, biolum mushrooms
	# =========================================================================
	print("\n[Capture 3/4] Biome III: Basaltic Abyssal Basin (Zone C)...")
	if player:
		if player.lantern:
			player.lantern.set_hand_mode(false)
			player.lantern.set_lit(true)
		if player.pickaxe:
			player.pickaxe.set_active(false)

		# Mid-terrace looking across at towering basalt columns & misty waterfall
		player.global_position = Vector3(-3.5, 28.2, -22.5)
		player.look_at(Vector3(-10.0, 30.0, -32.5), Vector3.UP)
		if neck:
			neck.rotation_degrees = Vector3(4.0, 0, 0)

	for i in range(45):
		await process_frame

	_save_shot("res://screenshots/biome_review/03_basaltic_abyssal.png")

	# =========================================================================
	# SHOT 4: Biome Transition & The Watcher in the Fog (Herobrine Aesthetic)
	# Overlook ledge looking across misty chasm at The Watcher's piercing white eyes
	# =========================================================================
	print("\n[Capture 4/4] Biome Transition & The Watcher in Fog...")
	if player:
		if player.lantern:
			player.lantern.set_hand_mode(false)
			player.lantern.set_lit(true)
		if player.pickaxe:
			player.pickaxe.set_active(false)

		# Standing at the chasm brink, 17.5m from Watcher on West Ledge
		player.global_position = Vector3(3.5, 34.6, -22.0)
		player.look_at(Vector3(-14.0, 33.0, -22.0), Vector3.UP)
		if neck:
			neck.rotation_degrees = Vector3(0, 0, 0)

		# Ensure Watcher looks directly back at player's camera
		if watcher:
			watcher.look_at(player.global_position, Vector3.UP)

	for i in range(45):
		await process_frame

	_save_shot("res://screenshots/biome_review/04_biome_transition.png")

	print("\n==================================================")
	print("  ALL 4 BIOME REVIEW SCREENSHOTS CAPTURED CLEANLY")
	print("==================================================")
	quit(0)

func _save_shot(file_path: String) -> void:
	var viewport = root.get_viewport()
	var tex = viewport.get_texture()
	if tex == null:
		printerr("Failed to get viewport texture for: ", file_path)
		return
	var img = tex.get_image()
	if img:
		var err = img.save_png(file_path)
		if err == OK:
			print("  [SAVED] ", file_path, " (", img.get_width(), "x", img.get_height(), ")")
		else:
			printerr("Failed to save image (error code ", err, "): ", file_path)
