# scripts/test_autonomous_player.gd
extends SceneTree

# Autonomous Player Exploration & Visual Quality Gate Inspector
# Simulates a real player moving through all 5 zones of Milestone 1,
# capturing high-resolution in-game screenshots at critical vantage points.

const M1Scene = preload("res://scenes/development/m1_vertical_slice.tscn")
const SCREENSHOT_DIR = "res://screenshots/autonomous_gameplay"
const ARTIFACT_DIR = "C:/Users/magom/.gemini/antigravity/brain/0542bc81-f515-4a83-9026-0d1a0ef0a4de/autonomous_gameplay"

var m1_node: Node3D = null
var player: CharacterBody3D = null
var current_shot_index: int = 0
var frame_wait: int = 0

var exploration_waypoints: Array = [
	{
		"name": "01_lowpoly_arm_holding_lantern",
		"pos": Vector3(0.5, 57.2, 0.0),
		"rot": Vector3(0, -90, 0),
		"neck_rot": Vector3(-8, 0, 0),
		"desc": "First-Person view of new low-poly explorer arm and glowing brass lantern",
		"item_id": "lantern"
	},
	{
		"name": "02_lowpoly_arm_holding_pickaxe",
		"pos": Vector3(0.5, 57.2, 0.0),
		"rot": Vector3(0, -90, 0),
		"neck_rot": Vector3(-8, 0, 0),
		"desc": "First-Person view of new low-poly arm with leather glove holding forged steel pickaxe",
		"item_id": "pickaxe"
	},
	{
		"name": "03_mining_decline_staircase_sign",
		"pos": Vector3(4.0, 53.2, 0.0),
		"rot": Vector3(0, -90, 0),
		"neck_rot": Vector3(-12, 0, 0),
		"desc": "Stepped stone decline with timber arches and Station 4 illuminated sign",
		"item_id": "lantern"
	},
	{
		"name": "04_station4_lowpoly_surveyor_desk",
		"pos": Vector3(13.0, 40.2, -3.2),
		"rot": Vector3(0, 0, 0),
		"neck_rot": Vector3(-18, 0, 0),
		"desc": "Station 4 Surveyor Desk with 4 legs, D-01 open journal, banker lamp, and cassette AUD-01",
		"item_id": "lantern"
	},
	{
		"name": "05_station4_drainage_and_sump_ladder",
		"pos": Vector3(14.5, 40.2, -9.0),
		"rot": Vector3(0, -110, 0),
		"neck_rot": Vector3(-24, 0, 0),
		"desc": "Anchored drainage valve and industrial yellow service ladder in the trench",
		"item_id": "lantern"
	},
	{
		"name": "06_west_airlock_to_echo_shaft_sign",
		"pos": Vector3(12.0, 40.2, -14.0),
		"rot": Vector3(0, 90, 0),
		"neck_rot": Vector3(0, 0, 0),
		"desc": "West bulkhead door leading to Echo Shaft with illuminated stencil sign",
		"item_id": "lantern"
	},
	{
		"name": "07_echo_shaft_suspension_catwalk",
		"pos": Vector3(4.0, 34.4, -18.0),
		"rot": Vector3(0, 140, 0),
		"neck_rot": Vector3(-12, 0, 0),
		"desc": "Echo Shaft 22m chasm with walkable suspension catwalk and bioluminescence",
		"item_id": "lantern"
	},
	{
		"name": "08_abandoned_camp_grotto_fire",
		"pos": Vector3(-15.0, 26.5, 1.0),
		"rot": Vector3(0, 0, 0),
		"neck_rot": Vector3(-4, 0, 0),
		"desc": "Abandoned Camp grotto with campfire glow, canvas tents, and radio desk",
		"item_id": "lantern"
	},
	{
		"name": "09_lower_sump_safe_and_ladder_up",
		"pos": Vector3(15.0, 29.0, -12.0),
		"rot": Vector3(0, 60, 0),
		"neck_rot": Vector3(25, 0, 0),
		"desc": "Lower Sump floor with EE-06 safe and ladder leading back up to Station 4",
		"item_id": "lantern"
	}
]

func _init() -> void:
	print("=====================================================================")
	print("[AUTONOMOUS PLAYER] Starting Full Exploration & Visual Inspection...")
	print("=====================================================================")

	DirAccess.make_dir_recursive_absolute(SCREENSHOT_DIR)
	DirAccess.make_dir_recursive_absolute(ARTIFACT_DIR)

	m1_node = M1Scene.instantiate()
	root.add_child(m1_node)

	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	frame_wait += 1
	if frame_wait < 15:
		return

	if player == null:
		player = root.find_child("Player", true, false)
		if player == null:
			printerr("[AUTONOMOUS] Player not found in scene tree!")
			quit(1)
			return

		# Ensure player has both tools in inventory for testing!
		if player.inventory_system:
			player.inventory_system.add_item("lantern", 1)
			player.inventory_system.add_item("pickaxe", 1)

	if current_shot_index < exploration_waypoints.size():
		var wp = exploration_waypoints[current_shot_index]
		_apply_waypoint(wp)

		# Allow 6 frames for viewmodel animation and lighting to settle
		if frame_wait % 8 == 0:
			_capture_and_save(wp)
			current_shot_index += 1
	else:
		print("=====================================================================")
		print("[AUTONOMOUS PLAYER] All %d Waypoint Shots Captured Successfully!" % exploration_waypoints.size())
		print("=====================================================================")
		quit(0)

func _apply_waypoint(wp: Dictionary) -> void:
	player.global_position = wp["pos"]
	player.rotation_degrees = wp["rot"]
	if player.neck:
		player.neck.rotation_degrees = wp["neck_rot"]

	var item_id = wp.get("item_id", "lantern")
	if player.inventory_system:
		# Find slot holding the target item
		for slot_idx in range(8):
			if slot_idx < player.inventory_system.slots.size():
				var it = player.inventory_system.slots[slot_idx]
				if it is Dictionary and not it.is_empty() and it.get("id") == item_id:
					player.set_active_slot(slot_idx + 1)
					break

func _capture_and_save(wp: Dictionary) -> void:
	var img = root.get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		printerr("[AUTONOMOUS] Failed to capture viewport image for: ", wp["name"])
		return

	var local_path = "%s/%s.png" % [SCREENSHOT_DIR, wp["name"]]
	var artifact_path = "%s/%s.png" % [ARTIFACT_DIR, wp["name"]]

	img.save_png(local_path)
	img.save_png(artifact_path)

	print("[SAVED SHOT %d/%d] %s" % [
		current_shot_index + 1,
		exploration_waypoints.size(),
		wp["desc"]
	])
	print("  -> %s" % artifact_path)
