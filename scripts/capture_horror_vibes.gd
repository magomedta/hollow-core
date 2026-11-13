# scripts/capture_horror_vibes.gd
# Captures high-fidelity in-engine screenshots of the horror creepypasta overhaul
extends SceneTree

var main_node: Node3D
var step: int = 0
var settle_frames: int = 75
var state: int = 0
var watcher_inst: Node3D

func _init() -> void:
	print("[HorrorCapture] Initializing Horror Atmosphere Showcase Capture...")
	var res = load("res://scenes/main.tscn")
	main_node = res.instantiate()
	root.add_child(main_node)

func _process(delta: float) -> bool:
	var player = main_node.player
	var enemies = main_node.enemies_container

	match state:
		0:
			match step:
				0:
					# Shot 1: The Watcher in the Fog (Mirroring User Reference Image!)
					print("[HorrorCapture] Shot 0: The Watcher on Distant Fog Horizon (Alpha Creepypasta)")
					if player:
						player.global_position = Vector3(25.0, 52.0, 15.0)
						player.velocity = Vector3.ZERO
						player.rotation_degrees = Vector3(0, 0.0, 0) # Face North towards -Z (The Watcher)
						if "neck" in player and player.neck:
							player.neck.rotation_degrees = Vector3(-3.0, 0, 0)
						if "lantern" in player and player.lantern:
							player.lantern.set_lit(false) # Natural Alpha fog daylight

					# Spawn The Watcher on the distant hill ridge (32m away)
					var watcher_class = load("res://scripts/the_watcher.gd")
					watcher_inst = watcher_class.new()
					watcher_inst.name = "ShowcaseWatcher"
					watcher_inst.position = Vector3(25.0, 52.0, -17.0)
					main_node.add_child(watcher_inst)

				1:
					# Clean up watcher from shot 0
					if watcher_inst and is_instance_valid(watcher_inst):
						watcher_inst.queue_free()

					# Shot 2: Herobrine's 2x2 Carved Mine Tunnel
					print("[HorrorCapture] Shot 1: The Mysterious 2x2 Carved Mine Tunnel")
					if player:
						player.global_position = Vector3(20.5, 11.2, -4.5)
						player.velocity = Vector3.ZERO
						player.rotation_degrees = Vector3(0, 0.0, 0) # Face South towards -Z
						if "neck" in player and player.neck:
							player.neck.rotation_degrees = Vector3(-6.0, 0, 0)
						if "lantern" in player and player.lantern:
							player.lantern.set_lit(true)

				2:
					# Shot 3: The Secret Occult Crypt Altar
					print("[HorrorCapture] Shot 2: Secret Occult Crypt Altar")
					if player:
						player.global_position = Vector3(20.5, 11.2, -34.0)
						player.velocity = Vector3.ZERO
						player.rotation_degrees = Vector3(0, 0.0, 0) # Face South into chamber
						if "neck" in player and player.neck:
							player.neck.rotation_degrees = Vector3(-8.0, 0, 0)
						if "lantern" in player and player.lantern:
							player.lantern.set_lit(true)

				3:
					# Shot 4: Bespoke Textured Chasm Stalker
					print("[HorrorCapture] Shot 3: Bespoke Textured Chasm Stalker")
					if player:
						player.global_position = Vector3(29.5, 8.5, 0.0)
						player.velocity = Vector3.ZERO
						player.rotation_degrees = Vector3(0, -90.0, 0) # Face East directly at stalker at X=32
						if "neck" in player and player.neck:
							player.neck.rotation_degrees = Vector3(0.0, 0, 0)
						if "lantern" in player and player.lantern:
							player.lantern.set_lit(true)

				4:
					# Shot 5: Low HP Blood Vignette & Dread Pulse
					print("[HorrorCapture] Shot 4: Low HP Dread Pulse & Subterranean Fog")
					if player:
						player.global_position = Vector3(45.0, 11.5, 5.0)
						player.velocity = Vector3.ZERO
						player.rotation_degrees = Vector3(0, -80.0, 0)
						player.current_health = 22.0 # Trigger critical heartbeat & crimson vignette
						if "neck" in player and player.neck:
							player.neck.rotation_degrees = Vector3(-10.0, 0, 0)
						if "lantern" in player and player.lantern:
							player.lantern.set_lit(true)

			settle_frames = 70
			state = 1

		1:
			if player:
				player.velocity = Vector3.ZERO
			settle_frames -= 1
			if settle_frames <= 0:
				state = 2

		2:
			match step:
				0: _save_image("horror_01_the_watcher_in_fog.png")
				1: _save_image("horror_02_herobrine_2x2_tunnel.png")
				2: _save_image("horror_03_occult_crypt_altar.png")
				3: _save_image("horror_04_chasm_stalker_textured.png")
				4: _save_image("horror_05_low_hp_dread_vignette.png")

			step += 1
			if step > 4:
				print("[HorrorCapture] All 5 horror showcase screenshots successfully captured!")
				quit(0)
				return true
			else:
				state = 0

	return false

func _save_image(file_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var viewport = root.get_viewport()
	var tex = viewport.get_texture()
	if tex == null:
		return
	var img = tex.get_image()
	if img:
		var dir = "res://screenshots"
		if not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
		var file_path = dir + "/" + file_name
		var err = img.save_png(file_path)
		if err == OK:
			print("[HorrorCapture] Saved: %s (%dx%d)" % [file_name, img.get_width(), img.get_height()])
