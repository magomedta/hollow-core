extends Node

var target_screenshots: Array = [
	{
		"name": "screen_cavern_vista.png",
		"pos": Vector3(-30.5, 16.7, -9.5),
		"rot": Vector3(-6.0, -80.0, 0.0),
		"lantern": true,
		"slot": 1,
		"phase": 1,
		"desc": "Panoramic Cavern Vista from Expedition Outpost with Volumetric Fog, Diverse Rock Strata & Voxel Pillars"
	},
	{
		"name": "screen_diegetic_hud.png",
		"pos": Vector3(-30.5, 16.7, -9.5),
		"rot": Vector3(-6.0, -75.0, 0.0),
		"lantern": true,
		"slot": 1,
		"phase": 1,
		"desc": "Diegetic Anti-AI HUD with 8-slot Hotbar, Compass, Depth Gauge & Outpost Crates"
	},
	{
		"name": "screen_lantern_darkness.png",
		"pos": Vector3(0.0, 6.2, 8.0),
		"rot": Vector3(-4.0, 180.0, 0.0),
		"lantern": true,
		"slot": 1,
		"phase": 3,
		"desc": "Dynamic Brass Lantern illuminating the Deep Voxel Cavern & Mineral Strata"
	},
	{
		"name": "screen_lantern_off_abyss.png",
		"pos": Vector3(0.0, 6.2, 8.0),
		"rot": Vector3(-12.0, 180.0, 0.0),
		"lantern": false,
		"slot": 1,
		"phase": 3,
		"desc": "Pitch-Black Subterranean Darkness with Distant Bioluminescent Crystals and Glowing Ores"
	},
	{
		"name": "screen_geologist_pickaxe.png",
		"pos": Vector3(-30.5, 16.7, -9.5),
		"rot": Vector3(-10.0, -75.0, 0.0),
		"lantern": true,
		"slot": 2,
		"pick_tier": 3,
		"phase": 2,
		"desc": "First-Person Chiseled Steel Geologist Mattock Ready for Excavation"
	},
	{
		"name": "screen_scaffold_building.png",
		"pos": Vector3(-30.5, 16.7, -9.5),
		"rot": Vector3(-6.0, -80.0, 0.0),
		"lantern": true,
		"slot": 3,
		"phase": 2,
		"desc": "Tactile First-Person Building Mode with Torch / Scaffold Placement Preview"
	},
	{
		"name": "screen_precursor_ruins.png",
		"pos": Vector3(20.0, 11.5, 0.0),
		"rot": Vector3(-2.0, -90.0, 0.0),
		"lantern": true,
		"slot": 1,
		"phase": 5,
		"desc": "Ancient Precursor Archway Ruins Embedded in Deep Slate Strata"
	},
	{
		"name": "screen_stalker_encounter.png",
		"pos": Vector3(0.0, 6.2, 11.5),
		"rot": Vector3(-4.0, 180.0, 0.0),
		"lantern": true,
		"slot": 1,
		"phase": 4,
		"desc": "Terrifying Encounter with Chasm Stalker with Chitin Armor & Glowing Bioluminescent Eyes"
	}
]

var is_capturing: bool = false
var shot_index: int = 0
var frame_counter: int = 0
var capture_state: int = 0

var player: CharacterBody3D

func _ready() -> void:
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

			frame_counter = 25 # Settle time for volumetric fog accumulation & PBR lighting
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
