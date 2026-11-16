# scripts/test_dense_inspection.gd
extends SceneTree

# Dense Autonomous Exploration & Photographic Visual Inspection Suite
# Captures 32 comprehensive vantage points covering every room, prop, corridor,
# and tool perspective across the entire vertical slice.

const M1Scene = preload("res://scenes/development/m1_vertical_slice.tscn")
const SCREENSHOT_DIR = "res://screenshots/dense_inspection"
const ARTIFACT_DIR = "C:/Users/magom/.gemini/antigravity/brain/0542bc81-f515-4a83-9026-0d1a0ef0a4de/dense_inspection"

var m1_node: Node3D = null
var player: CharacterBody3D = null
var current_shot_index: int = 0
var frame_wait: int = 0

var dense_waypoints: Array = [
	# --- ZONE A: CRASH SITE & DESCENT ---
	{
		"name": "01_crash_site_cage_interior",
		"pos": Vector3(0.0, 58.2, 0.0),
		"rot": Vector3(0, 180, 0),
		"neck_rot": Vector3(-5, 0, 0),
		"desc": "Inside crumpled TyazhMash elevator cage looking out",
		"item_id": "lantern"
	},
	{
		"name": "02_crash_site_exterior_crates",
		"pos": Vector3(-2.2, 58.2, 2.0),
		"rot": Vector3(0, 45, 0),
		"neck_rot": Vector3(-12, 0, 0),
		"desc": "Crash site exterior with severed cables and cargo crates",
		"item_id": "lantern"
	},
	{
		"name": "03_crash_site_audiolog_aud18",
		"pos": Vector3(1.2, 58.2, 0.2),
		"rot": Vector3(0, 45, 0),
		"neck_rot": Vector3(-45, 0, 0),
		"desc": "Looking down at AUD-18 cassette and DOC-08 on crate",
		"item_id": "lantern"
	},
	{
		"name": "04_approach_decline_entry",
		"pos": Vector3(0.5, 58.2, 0.0),
		"rot": Vector3(0, -90, 0),
		"neck_rot": Vector3(-15, 0, 0),
		"desc": "Entry portal of stepped mining decline looking down",
		"item_id": "lantern"
	},
	{
		"name": "05_approach_decline_midway",
		"pos": Vector3(4.5, 52.8, 0.0),
		"rot": Vector3(0, -90, 0),
		"neck_rot": Vector3(-12, 0, 0),
		"desc": "Midway down stone decline with oak timber arches",
		"item_id": "lantern"
	},
	{
		"name": "06_approach_decline_look_up",
		"pos": Vector3(8.0, 44.5, 0.0),
		"rot": Vector3(0, 90, 0),
		"neck_rot": Vector3(25, 0, 0),
		"desc": "Looking up the stepped decline towards crash cave",
		"item_id": "lantern"
	},

	# --- ZONE B: AIRLOCK STATION 4 ---
	{
		"name": "07_station4_entry_portal",
		"pos": Vector3(9.5, 41.5, 0.0),
		"rot": Vector3(0, -90, 0),
		"neck_rot": Vector3(-5, 0, 0),
		"desc": "Passing through Station 4 entry archway into the main chamber",
		"item_id": "lantern"
	},
	{
		"name": "08_station4_surveyor_desk_wide",
		"pos": Vector3(13.0, 40.5, -2.5),
		"rot": Vector3(0, 0, 0),
		"neck_rot": Vector3(-18, 0, 0),
		"desc": "Wide view of Surveyor Desk with stool, banker lamp, and D-01",
		"item_id": "lantern"
	},
	{
		"name": "09_station4_surveyor_desk_closeup",
		"pos": Vector3(13.0, 40.2, -4.5),
		"rot": Vector3(0, 0, 0),
		"neck_rot": Vector3(-35, 0, 0),
		"desc": "Close-up of open Journal D-01, red ribbon, AUD-01 tape, and lamp",
		"item_id": "lantern"
	},
	{
		"name": "10_station4_mechanic_bench",
		"pos": Vector3(14.5, 40.5, -1.0),
		"rot": Vector3(0, -35, 0),
		"neck_rot": Vector3(-15, 0, 0),
		"desc": "Mechanic workbench area with DOC-16 and tool crates",
		"item_id": "lantern"
	},
	{
		"name": "11_station4_admin_nook",
		"pos": Vector3(11.5, 40.5, -6.5),
		"rot": Vector3(0, 40, 0),
		"neck_rot": Vector3(-15, 0, 0),
		"desc": "Station Admin alcove with AUD-10 cassette",
		"item_id": "lantern"
	},
	{
		"name": "12_station4_trench_valve_closeup",
		"pos": Vector3(15.8, 40.5, -11.0),
		"rot": Vector3(0, -90, 0),
		"neck_rot": Vector3(-32, 0, 0),
		"desc": "Heavy industrial cast-iron drainage valve stand at trench wall",
		"item_id": "lantern"
	},
	{
		"name": "13_station4_sump_ladder_hatch",
		"pos": Vector3(16.5, 40.5, -10.0),
		"rot": Vector3(0, -135, 0),
		"neck_rot": Vector3(-45, 0, 0),
		"desc": "Looking down into drainage trench at yellow service ladder top",
		"item_id": "lantern"
	},
	{
		"name": "14_station4_west_bulkhead_arch",
		"pos": Vector3(12.5, 40.5, -12.5),
		"rot": Vector3(0, 90, 0),
		"neck_rot": Vector3(0, 0, 0),
		"desc": "West bulkhead archway leading towards Echo Shaft",
		"item_id": "lantern"
	},

	# --- ZONE C: ECHO SHAFT ---
	{
		"name": "15_echo_shaft_airlock_corridor",
		"pos": Vector3(8.5, 36.5, -13.5),
		"rot": Vector3(0, 90, 0),
		"neck_rot": Vector3(-10, 0, 0),
		"desc": "Descending the inclined stone gallery towards Echo Shaft",
		"item_id": "lantern"
	},
	{
		"name": "16_echo_shaft_balcony_overlook",
		"pos": Vector3(4.5, 35.0, -17.0),
		"rot": Vector3(0, 135, 0),
		"neck_rot": Vector3(-15, 0, 0),
		"desc": "Overlook balcony looking into 22m vertical chasm and depth fog",
		"item_id": "lantern"
	},
	{
		"name": "17_echo_shaft_suspension_bridge_start",
		"pos": Vector3(3.8, 34.2, -20.5),
		"rot": Vector3(0, 72, 0),
		"neck_rot": Vector3(-14, 0, 0),
		"desc": "Stepping onto suspension bridge looking down catenary cables to West Terrace",
		"item_id": "lantern"
	},
	{
		"name": "18_echo_shaft_suspension_bridge_center",
		"pos": Vector3(-2.0, 31.8, -22.2),
		"rot": Vector3(0, -110, 0),
		"neck_rot": Vector3(-15, 0, 0),
		"desc": "Center of suspension bridge looking at steel cables and railings",
		"item_id": "lantern"
	},
	{
		"name": "19_echo_shaft_watcher_ledge",
		"pos": Vector3(-5.0, 30.0, -23.0),
		"rot": Vector3(0, 45, 0),
		"neck_rot": Vector3(10, 0, 0),
		"desc": "Looking across chasm at the Watcher apparition ledge",
		"item_id": "lantern"
	},
	{
		"name": "20_echo_shaft_west_terrace",
		"pos": Vector3(-8.0, 29.0, -20.0),
		"rot": Vector3(0, 90, 0),
		"neck_rot": Vector3(-5, 0, 0),
		"desc": "West terrace landing leading into Abandoned Camp corridor",
		"item_id": "lantern"
	},

	# --- ZONE D: ABANDONED CAMP ---
	{
		"name": "21_camp_grotto_corridor",
		"pos": Vector3(-11.5, 27.8, -2.0),
		"rot": Vector3(0, 180, 0),
		"neck_rot": Vector3(-5, 0, 0),
		"desc": "Sheltered corridor opening into the geologist base camp",
		"item_id": "lantern"
	},
	{
		"name": "22_camp_wide_overview",
		"pos": Vector3(-15.0, 27.5, 0.5),
		"rot": Vector3(0, 180, 0),
		"neck_rot": Vector3(-8, 0, 0),
		"desc": "Wide panoramic view of expedition tent, campfire, and radio desk",
		"item_id": "lantern"
	},
	{
		"name": "23_camp_canvas_tent_closeup",
		"pos": Vector3(-13.5, 27.2, 6.0),
		"rot": Vector3(0, -90, 0),
		"neck_rot": Vector3(-12, 0, 0),
		"desc": "Low-poly canvas tent, camp cot, rolled blanket, and lantern",
		"item_id": "lantern"
	},
	{
		"name": "24_camp_radio_transceiver",
		"pos": Vector3(-16.5, 27.2, 5.5),
		"rot": Vector3(0, 0, 0),
		"neck_rot": Vector3(-25, 0, 0),
		"desc": "Radio desk, olive-drab transceiver, antenna, coffee mug, and AUD-03",
		"item_id": "lantern"
	},
	{
		"name": "25_camp_grotto_spring",
		"pos": Vector3(-19.0, 27.2, 8.0),
		"rot": Vector3(0, 45, 0),
		"neck_rot": Vector3(-20, 0, 0),
		"desc": "Subterranean karst spring and supply crate caches",
		"item_id": "lantern"
	},

	# --- ZONE E: LOWER SUMP ---
	{
		"name": "26_sump_climbing_ladder_mid",
		"pos": Vector3(18.0, 34.0, -12.0),
		"rot": Vector3(0, 90, 0),
		"neck_rot": Vector3(-35, 0, 0),
		"desc": "Mid-height on industrial service ladder looking down into sump",
		"item_id": "lantern"
	},
	{
		"name": "27_sump_floor_looking_up",
		"pos": Vector3(16.5, 29.5, -12.0),
		"rot": Vector3(0, 90, 0),
		"neck_rot": Vector3(55, 0, 0),
		"desc": "Standing on sump floor looking up 10m vertical service shaft",
		"item_id": "lantern"
	},
	{
		"name": "28_sump_drowned_safe_ee06",
		"pos": Vector3(15.0, 29.5, -9.5),
		"rot": Vector3(0, 0, 0),
		"neck_rot": Vector3(-35, 0, 0),
		"desc": "Syndicate EE-06 heavy safe embedded in drained sump floor",
		"item_id": "lantern"
	},
	{
		"name": "29_sump_pump_manifold",
		"pos": Vector3(17.0, 29.5, -10.5),
		"rot": Vector3(0, -90, 0),
		"neck_rot": Vector3(-20, 0, 0),
		"desc": "Cast iron drainage pump flange and AUD-13 cassette",
		"item_id": "lantern"
	},

	# --- VIEWMODELS & TOOLS ---
	{
		"name": "30_viewmodel_lantern_lit",
		"pos": Vector3(13.0, 40.5, -2.5),
		"rot": Vector3(0, 0, 0),
		"neck_rot": Vector3(0, 0, 0),
		"desc": "Holding glowing brass lantern in left hand",
		"item_id": "lantern"
	},
	{
		"name": "31_viewmodel_pickaxe_ready",
		"pos": Vector3(13.0, 40.5, -2.5),
		"rot": Vector3(0, 0, 0),
		"neck_rot": Vector3(0, 0, 0),
		"desc": "Holding forged steel mattock/pickaxe in right hand",
		"item_id": "pickaxe"
	},
	{
		"name": "32_mining_face_rock_closeup",
		"pos": Vector3(10.5, 40.5, -4.0),
		"rot": Vector3(0, 90, 0),
		"neck_rot": Vector3(-10, 0, 0),
		"desc": "Looking directly at quarry face with pickaxe ready to strike",
		"item_id": "pickaxe"
	}
]

func _init() -> void:
	print("=====================================================================")
	print("[DENSE INSPECTION] Starting 32-Point Photographic Visual Audit...")
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
			printerr("[INSPECTION] Player node not found!")
			quit(1)
			return

		# Guarantee tools exist in inventory
		if player.inventory_system:
			player.inventory_system.add_item("lantern", 1)
			player.inventory_system.add_item("pickaxe", 1)

	if current_shot_index < dense_waypoints.size():
		var wp = dense_waypoints[current_shot_index]
		_apply_waypoint(wp)

		# 8 frames per shot for camera, lighting, and viewmodel to settle
		if frame_wait % 8 == 0:
			_capture_and_save(wp)
			current_shot_index += 1
	else:
		print("=====================================================================")
		print("[DENSE INSPECTION] All %d Photographic Shots Successfully Captured!" % dense_waypoints.size())
		print("=====================================================================")
		quit(0)

func _apply_waypoint(wp: Dictionary) -> void:
	player.global_position = wp["pos"]
	player.rotation_degrees = wp["rot"]
	if player.neck:
		player.neck.rotation_degrees = wp["neck_rot"]

	var item_id = wp.get("item_id", "lantern")
	if player.inventory_system:
		for slot_idx in range(8):
			if slot_idx < player.inventory_system.slots.size():
				var it = player.inventory_system.slots[slot_idx]
				if it is Dictionary and not it.is_empty() and it.get("id") == item_id:
					player.set_active_slot(slot_idx + 1)
					break

func _capture_and_save(wp: Dictionary) -> void:
	var img = root.get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		printerr("[INSPECTION] Failed to capture viewport for: ", wp["name"])
		return

	var local_path = "%s/%s.png" % [SCREENSHOT_DIR, wp["name"]]
	var artifact_path = "%s/%s.png" % [ARTIFACT_DIR, wp["name"]]

	img.save_png(local_path)
	img.save_png(artifact_path)

	print("[SHOT %02d/%02d] %s" % [
		current_shot_index + 1,
		dense_waypoints.size(),
		wp["desc"]
	])
