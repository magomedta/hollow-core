extends Node

var target_screenshots: Array = [
	{
		"name": "ingame_01_outpost_hub.png",
		"pos": Vector3(0.5, 11.2, 0.5),
		"rot": Vector3(-4.0, -90.0, 0.0),
		"lantern": true,
		"slot": 1,
		"desc": "Starting Expedition Hub with Placed Scaffolding, Supplies & Lantern Light"
	},
	{
		"name": "ingame_02_glacial_cryosphere.png",
		"pos": Vector3(0.0, 52.0, 12.0),
		"rot": Vector3(-5.0, 0.0, 0.0),
		"lantern": true,
		"slot": 1,
		"desc": "Glacial Cryosphere (Y=52): Station Boreas Timber Outpost on Frozen Ice Shelf"
	},
	{
		"name": "ingame_03_fungal_mycena_hollows.png",
		"pos": Vector3(0.0, 11.2, 33.0),
		"rot": Vector3(-3.0, 180.0, 0.0),
		"lantern": true,
		"slot": 1,
		"desc": "Fungal Mycena Hollows (Z=33): Giant 3D Mushrooms, Hanging Spore Vines & Water Aquifer"
	},
	{
		"name": "ingame_04_amethyst_geode_cavity.png",
		"pos": Vector3(0.0, 11.2, -33.0),
		"rot": Vector3(-3.0, 0.0, 0.0),
		"lantern": true,
		"slot": 1,
		"desc": "Amethyst Geode Realm (Z=-33): 3D Amethyst Spires, Floating Geode Core & Calcite Mantle"
	},
	{
		"name": "ingame_05_precursor_sanctuary.png",
		"pos": Vector3(-31.0, 8.5, 0.0),
		"rot": Vector3(6.0, 90.0, 0.0),
		"lantern": true,
		"slot": 1,
		"desc": "Precursor Sanctuary (X=-31): Giant Fossil Bone Ribs, Stepped Pyramid Dais & Conduits"
	},
	{
		"name": "ingame_06_volcanic_magma_caldera.png",
		"pos": Vector3(67.0, 8.2, 0.0),
		"rot": Vector3(-4.0, -90.0, 0.0),
		"lantern": true,
		"slot": 1,
		"desc": "Volcanic Magma Caldera (X=67): Stepped Basalt Pillars, Lava Lake & Sulfur Chimneys"
	},
	{
		"name": "ingame_07_grand_cathedral_horror.png",
		"pos": Vector3(35.0, 11.2, 5.0),
		"rot": Vector3(6.0, -85.0, 0.0),
		"lantern": true,
		"slot": 1,
		"desc": "Grand Cathedral Abyss (X=35): High-Chasm Natural Stone Bridge & Soaring Colonnades"
	},
	{
		"name": "ingame_08_deep_bedrock_shaft.png",
		"pos": Vector3(0.0, -18.0, 0.0),
		"rot": Vector3(-25.0, -45.0, 0.0),
		"lantern": true,
		"slot": 1,
		"desc": "Deep Abyssal Shaft (Y=-18): Excavation Scaffolding & Deepslate Trench"
	}
]

var is_capturing: bool = false
var shot_index: int = 0
var frame_counter: int = 0
var capture_state: int = 0

var player: CharacterBody3D

func _ready() -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody3D
		if not player:
			player = get_node_or_null("../Player") as CharacterBody3D
	var args = OS.get_cmdline_args()
	for arg in args:
		if arg == "--auto-capture":
			start_capture_sequence()
			break

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_F12:
			capture_single_screenshot("user_capture_%d.png" % Time.get_unix_time_from_system())
		elif event.keycode == KEY_F11:
			start_capture_sequence()

func start_capture_sequence() -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody3D
		if not player:
			player = get_node_or_null("../Player") as CharacterBody3D
	is_capturing = true
	shot_index = 0
	capture_state = 1
	frame_counter = 0
	print("[ScreenshotHelper] Commencing automated capture sequence...")

func _process(_delta: float) -> void:
	if not is_capturing:
		return

	match capture_state:
		1:
			if shot_index >= target_screenshots.size():
				is_capturing = false
				capture_state = 0
				print("[ScreenshotHelper] All %d screenshots successfully captured!" % target_screenshots.size())
				var args = OS.get_cmdline_args()
				if "--auto-capture" in args or "--auto-quit" in args:
					get_tree().quit(0)
				return

			var shot = target_screenshots[shot_index]
			if player:
				player.global_position = shot["pos"]
				player.velocity = Vector3.ZERO
				player.rotation_degrees = Vector3(0, shot["rot"].y, 0)
				if "neck" in player and player.neck:
					player.neck.rotation_degrees = Vector3(shot["rot"].x, 0, 0)

				if shot.has("phase") and player.has_method("advance_progression_phase"):
					player.progression_phase = shot["phase"]
					if player.has_signal("progression_phase_changed"):
						player.progression_phase_changed.emit(player.progression_phase)

				if shot.has("pick_tier") and "pickaxe" in player and player.pickaxe:
					if player.pickaxe.has_method("set_tier"):
						player.pickaxe.set_tier(shot["pick_tier"])

				if shot.has("slot") and player.has_method("set_active_slot"):
					if shot["slot"] == 3 and "inventory" in player:
						player.inventory["timber"] = 6
					player.set_active_slot(shot["slot"])
				elif player.has_method("set_active_slot"):
					player.set_active_slot(1)

				if "lantern" in player and player.lantern:
					if player.lantern.has_method("set_lit"):
						player.lantern.set_lit(shot["lantern"])
					else:
						player.lantern.is_lit = shot["lantern"]
						if player.lantern.has_signal("lantern_toggled"):
							player.lantern.lantern_toggled.emit(shot["lantern"])

			frame_counter = 75 # Settle time for multi-threaded chunk meshing & lighting bounce
			capture_state = 2

		2:
			# Anchor player during settle time
			if player and shot_index < target_screenshots.size():
				var s = target_screenshots[shot_index]
				player.global_position = s["pos"]
				player.velocity = Vector3.ZERO

			frame_counter -= 1
			if frame_counter <= 0:
				capture_state = 3

		3:
			var shot = target_screenshots[shot_index]
			_save_image(shot["name"])
			shot_index += 1
			capture_state = 1

func _save_image(file_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("[ScreenshotHelper] Headless mode: skipped pixel read for %s" % file_name)
		return
	var viewport = get_viewport()
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
			print("[ScreenshotHelper] Captured: %s (%dx%d)" % [file_name, img.get_width(), img.get_height()])
		else:
			push_error("[ScreenshotHelper] Failed to save screenshot %s: code %d" % [file_name, err])

func capture_single_screenshot(file_name: String) -> void:
	_save_image(file_name)
