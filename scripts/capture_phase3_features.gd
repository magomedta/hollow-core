extends SceneTree

var main_node: Node3D
var step: int = 0
var settle_frames: int = 70
var state: int = 0

func _init():
	print("[FeatureCapture] Initializing Feature Showcase Capture...")
	var res = load("res://scenes/main.tscn")
	main_node = res.instantiate()
	root.add_child(main_node)

func _process(delta: float) -> bool:
	var player = main_node.player
	var hud = main_node.hud
	var inv = player.inventory_system if player and "inventory_system" in player else null

	match state:
		0:
			# Setup current shot
			match step:
				0:
					# Shot 1: 256x256 Inventory with recipes & ornate frame
					print("[FeatureCapture] Setup Shot 0: Ornate 256x256 Inventory")
					if inv:
						inv.set_slot(0, "flare", 4)
						inv.set_slot(1, "dynamite", 2)
						inv.set_slot(2, "grappling_rope", 1)
						inv.set_slot(3, "obsidian_blade", 1)
						inv.set_slot(4, "amethyst_shard", 8)
						inv.set_slot(5, "salve", 3)
						inv.set_slot(6, "pickaxe", 1)
						inv.set_slot(7, "lantern", 1)
						inv.set_slot(8, "ancient_core", 1)
						inv.set_slot(9, "water", 2)
						inv.set_slot(10, "rations", 3)
						inv.set_slot(11, "mushroom", 6)
						inv.set_slot(12, "timber", 16)
						inv.set_slot(13, "cobblestone", 32)
						inv.set_open(true)

				1:
					# Shot 2: Abyssal Glider Articulated Wings in Cathedral
					print("[FeatureCapture] Setup Shot 1: Abyssal Glider Flying")
					if inv:
						inv.set_open(false)
					if player:
						player.global_position = Vector3(38.0, 11.2, 5.0)
						player.velocity = Vector3.ZERO
						player.rotation_degrees = Vector3(0, -90.0, 0)
						if "neck" in player and player.neck:
							player.neck.rotation_degrees = Vector3(32.0, 0, 0)
						if "lantern" in player and player.lantern:
							player.lantern.set_lit(true)

				2:
					# Shot 3: Item Pickup on [E]
					print("[FeatureCapture] Setup Shot 2: Item Pickup on [E]")
					if player:
						player.global_position = Vector3(0.5, 11.2, 0.5)
						player.velocity = Vector3.ZERO
						player.rotation_degrees = Vector3(0, -90.0, 0)
						if "neck" in player and player.neck:
							player.neck.rotation_degrees = Vector3(-25.0, 0, 0)
						if "lantern" in player and player.lantern:
							player.lantern.set_lit(true)

					# Spawn dropped item right under crosshair
					var di_class = load("res://scripts/dropped_item.gd")
					var di = di_class.new()
					di.item_type = "phosphor"
					di.amount = 2
					di.position = Vector3(2.2, 10.4, 0.5)
					main_node.add_child(di)

				3:
					# Shot 3: Pale Lurker Horror in deep corridor
					print("[FeatureCapture] Setup Shot 3: Pale Lurker Horror")
					if player:
						player.global_position = Vector3(20.0, 10.2, 0.0)
						player.velocity = Vector3.ZERO
						player.rotation_degrees = Vector3(0, -90.0, 0)
						if "neck" in player and player.neck:
							player.neck.rotation_degrees = Vector3(-4.0, 0, 0)
						if "lantern" in player and player.lantern:
							player.lantern.set_lit(true)

				4:
					# Shot 4: Subterranean Depth Fog Vista
					print("[FeatureCapture] Setup Shot 4: Cavern Depth Fog Vista")
					if player:
						player.global_position = Vector3(45.0, 11.5, 5.0)
						player.velocity = Vector3.ZERO
						player.rotation_degrees = Vector3(0, -75.0, 0)
						if "neck" in player and player.neck:
							player.neck.rotation_degrees = Vector3(-12.0, 0, 0)
						if "lantern" in player and player.lantern:
							player.lantern.set_lit(true)

			settle_frames = 65
			state = 1

		1:
			# Settle frames for rendering and camera positioning
			if player:
				player.velocity = Vector3.ZERO
			settle_frames -= 1
			if settle_frames <= 0:
				state = 2

		2:
			# Capture image
			match step:
				0: _save_image("feature_01_inventory_ornate_256.png")
				1: _save_image("feature_02_abyssal_glider_wings.png")
				2: _save_image("feature_03_item_pickup_prompt.png")
				3: _save_image("feature_04_horror_lurker.png")
				4: _save_image("feature_05_depth_fog_vista.png")

			step += 1
			if step > 4:
				print("[FeatureCapture] All 5 feature showcases successfully captured!")
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
			print("[FeatureCapture] Saved: %s (%dx%d)" % [file_name, img.get_width(), img.get_height()])
