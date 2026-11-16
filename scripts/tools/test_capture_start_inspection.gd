# scripts/tools/test_capture_start_inspection.gd
extends SceneTree

const OUT_DIR = "C:/Users/magom/.gemini/antigravity/brain/0542bc81-f515-4a83-9026-0d1a0ef0a4de/start_inspection"

var main_scene: Node = null
var player: CharacterBody3D = null
var current_shot: int = 0
const SETTLE_FRAMES: int = 12
var settle_countdown: int = 0
var is_shot_configured: bool = false

var shots = [
	{
		"name": "01_crash_spawn_look_forward",
		"desc": "Spawn looking forward (+X) out of cage wreckage towards decline: tools on floor, amber light, zero clipping",
		"pos": Vector3(0.4, 57.0, 0.0),
		"rot": Vector3(-14.0, -90.0, 0.0),
		"item": 8 # Empty hands
	},
	{
		"name": "02_crash_look_at_cassette_aud18",
		"desc": "Looking at compact cassette AUD-18 sitting on supply crate with amber glow",
		"pos": Vector3(0.8, 57.1, 0.4),
		"rot": Vector3(-28.0, 90.0, 0.0),
		"item": 8
	},
	{
		"name": "03_approach_decline_entry",
		"desc": "Standing at decline gallery entrance looking down towards Station 4: solid rock walls, zero zebra stripes, timber arches",
		"pos": Vector3(1.2, 56.0, 0.0),
		"rot": Vector3(-18.0, -90.0, 0.0),
		"item": 8
	},
	{
		"name": "04_approach_decline_midway",
		"desc": "Midway down the wooden gangway stairs looking towards Station 4 portal: wooden steps, handrail, hanging lanterns",
		"pos": Vector3(4.0, 52.1, 0.0),
		"rot": Vector3(-18.0, -90.0, 0.0),
		"item": 8
	},
	{
		"name": "05_station4_entry_portal",
		"desc": "At foot of decline looking at Station 4 portal archway and illuminated plaque",
		"pos": Vector3(8.5, 42.9, 0.0),
		"rot": Vector3(2.0, -90.0, 0.0),
		"item": 8
	},
	{
		"name": "06_viewmodel_lantern_hand",
		"desc": "First-person view holding the brass lantern with the new low-poly faceted arm and leather glove",
		"pos": Vector3(3.0, 53.0, 0.0),
		"rot": Vector3(-10.0, -90.0, 0.0),
		"item": 7 # Lantern
	},
	{
		"name": "07_viewmodel_pickaxe_hand",
		"desc": "First-person view holding the surveyor pickaxe with the new low-poly faceted arm and leather glove",
		"pos": Vector3(3.0, 53.0, 0.0),
		"rot": Vector3(-10.0, -90.0, 0.0),
		"item": 5 # Pickaxe
	}
]

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	print("[StartInspection] Launching inspection runner...")
	var scene_res = load("res://scenes/development/m1_vertical_slice.tscn")
	main_scene = scene_res.instantiate()
	root.add_child(main_scene)
	process_frame.connect(_on_frame)

func _on_frame() -> void:
	if player == null:
		player = root.find_child("Player", true, false)
		if player == null:
			return

	if current_shot >= shots.size():
		print("[StartInspection] All %d inspection shots captured successfully!" % shots.size())
		quit(0)
		return

	var cfg = shots[current_shot]

	if not is_shot_configured:
		_setup_shot(cfg)
		is_shot_configured = true
		settle_countdown = SETTLE_FRAMES
		return

	settle_countdown -= 1
	if settle_countdown <= 0:
		_save_screenshot(cfg["name"])
		current_shot += 1
		is_shot_configured = false

func _setup_shot(cfg: Dictionary) -> void:
	print("[StartInspection] Setting up shot: %s (%s)" % [cfg["name"], cfg["desc"]])
	player.global_position = cfg["pos"]
	player.rotation_degrees = Vector3(0, cfg["rot"].y, 0)
	if player.neck:
		player.neck.rotation_degrees = Vector3(cfg["rot"].x, 0, 0)

	var slot = cfg.get("item", 8)

	# Ensure tools exist in player inventory
	if player.inventory_system:
		player.inventory_system.set_slot(6, "lantern", 1) # Slot 7
		player.inventory_system.set_slot(4, "pickaxe", 1) # Slot 5

	player.set_active_slot(slot)

	# Ensure lighting states
	if slot == 7 and player.lantern:
		player.lantern.set_hand_mode(true)
		player.lantern.set_lit(true)
		player.lantern.current_fuel = 95.0
	elif slot == 5 and player.pickaxe:
		player.pickaxe.set_active(true)
		if player.lantern:
			player.lantern.set_hand_mode(false)
			player.lantern.set_lit(true) # Harness light

func _save_screenshot(file_name: String) -> void:
	var img = root.get_viewport().get_texture().get_image()
	if img:
		var file_path = OUT_DIR + "/" + file_name + ".png"
		img.save_png(file_path)
		print("  -> Saved: %s (%dx%d)" % [file_path, img.get_width(), img.get_height()])
