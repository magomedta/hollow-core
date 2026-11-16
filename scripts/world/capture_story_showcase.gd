# scripts/world/capture_story_showcase.gd
extends SceneTree

const M1VerticalSliceScene = preload("res://scenes/development/m1_vertical_slice.tscn")

const ARTIFACT_DIR = "C:/Users/magom/.gemini/antigravity/brain/0542bc81-f515-4a83-9026-0d1a0ef0a4de/story_showcase/"

func _init() -> void:
	print("=====================================================================")
	print("[SHOWCASE] Starting Hollow Core Narrative & Story Visual Capture...")
	print("=====================================================================")

	var m1_instance = M1VerticalSliceScene.instantiate()
	root.add_child(m1_instance)

	var dir = DirAccess.open("res://")
	if not dir.dir_exists("screenshots/story_showcase"):
		dir.make_dir_recursive("screenshots/story_showcase")

	# Wait 40 frames for full geometry meshing, lighting, and ambient initialization
	for i in range(40):
		await process_frame

	var player = m1_instance.get_node_or_null("Player")
	var neck = player.get_node_or_null("Neck") if player else null

	# =========================================================================
	# SHOT 1: Crash Awakening & Empty Hands (TyazhMash-4 Wreckage, Glowing Lantern Prop)
	# =========================================================================
	print("[SHOWCASE] Capturing Shot 1: Crash Awakening at TyazhMash-4...")
	if player and m1_instance.scenario_manager and m1_instance.scenario_manager.lantern_prop:
		# Empty hands start
		player.set_active_slot(8)
		if player.ghost_block_mesh:
			player.ghost_block_mesh.visible = false
		if player.pickaxe:
			player.pickaxe.set_active(false)
		if player.lantern:
			player.lantern.set_hand_mode(false)
			player.lantern.set_lit(false)

		# Use exact player spawn orientation looking down the tunnel (+X)
		player.global_position = Vector3(0.4, 57.0, 0.0)
		player.rotation_degrees = Vector3(0, -90, 0)
		if neck:
			neck.rotation_degrees = Vector3(-14.0, 0, 0)

	for i in range(40):
		if player and player.ghost_block_mesh:
			player.ghost_block_mesh.visible = false
		await process_frame

	_save_shot("01_crash_awakening_empty_hands.png")

	# =========================================================================
	# SHOT 1B: Pickaxe Prop on Floor at Crash Site (Exact hand model on rubble)
	# =========================================================================
	print("[SHOWCASE] Capturing Shot 1B: Pickaxe Prop on Rubble Floor...")
	if player and m1_instance.scenario_manager and m1_instance.scenario_manager.pickaxe_prop:
		# Stand near pickaxe prop and look directly down at it on the floor
		player.set_active_slot(8)
		if player.ghost_block_mesh:
			player.ghost_block_mesh.visible = false
		var p_target = m1_instance.scenario_manager.pickaxe_prop.global_position
		player.global_position = Vector3(p_target.x - 1.0, 57.0, p_target.z)
		player.look_at(Vector3(p_target.x, 57.0, p_target.z), Vector3.UP)
		if neck:
			neck.look_at(p_target, Vector3.UP)

	for i in range(40):
		if player and player.ghost_block_mesh:
			player.ghost_block_mesh.visible = false
		await process_frame

	_save_shot("01b_crash_pickaxe_on_floor.png")

	# =========================================================================
	# SHOT 2: Glacial Approach Tunnel & Lit Lantern in Hand looking to Station 4
	# =========================================================================
	print("[SHOWCASE] Capturing Shot 2: Glacial Descent with Lit Lantern...")
	if player:
		# Lantern collected and held in hand, lit with warm flame
		if player.lantern:
			player.lantern.set_hand_mode(true)
			player.lantern.set_lit(true)
			player.lantern.current_fuel = 95.0
		if player.pickaxe:
			player.pickaxe.set_active(false)

		# Positioned in the glacial gallery looking down the tunnel with calcite icicles towards Station 4
		player.global_position = Vector3(6.0, 50.0, -2.0)
		player.look_at(Vector3(11.0, 44.0, -8.0), Vector3.UP)
		if neck:
			neck.rotation_degrees = Vector3(-8.0, 0, 0)

	for i in range(40):
		await process_frame

	_save_shot("02_glacial_approach_lantern_in_hand.png")

	# =========================================================================
	# SHOT 2B: Station 4 Drainage Valve & Trench (Anchored pipe & floor pedestal)
	# =========================================================================
	print("[SHOWCASE] Capturing Shot 2B: Station 4 Anchored Drainage Valve...")
	if player:
		# Standing in Station 4 near door looking across trench at the valve
		player.global_position = Vector3(13.5, 39.5, -9.5)
		player.look_at(Vector3(16.0, 39.0, -12.0), Vector3.UP)
		if neck:
			neck.rotation_degrees = Vector3(-16.0, 0, 0)

	for i in range(40):
		await process_frame

	_save_shot("02b_station4_anchored_drainage_valve.png")

	# =========================================================================
	# SHOT 3: Document D-01 Vintage Inspection (Prokhorov 1894 Journal)
	# =========================================================================
	print("[SHOWCASE] Capturing Shot 3: Document D-01 Inspection...")
	if player and m1_instance.document_viewer:
		# Standing right in front of the surveyor desk at Station 4
		player.global_position = Vector3(12.5, 39.5, -5.2)
		player.look_at(Vector3(12.5, 39.0, -6.5), Vector3.UP)
		if neck:
			neck.rotation_degrees = Vector3(-20.0, 0, 0)

		# Open Document D-01 in full inspection viewer with all 4 arguments
		m1_instance.document_viewer.show_document(
			"DOC-01",
			"ПОЛЕВОЙ ЖУРНАЛ ШУРФА №4 — СМЕНА ПРОХОРОВА (1894)",
			"14 ОКТЯБРЯ 1894 ГОДА — ГОРИЗОНТ 1420м — ШЛЮЗОВАЯ СТАНЦИЯ 4",
			"Водоотливной насос завода «Феникс» встал в третий раз за смену. Ледяная вода из трещины затапливает нижний приямок. Забойщик Смирнов клянётся, что в три часа ночи вода в зумпфе шла вспять, вверх по наклонному штреку.\n\nПри ударе кайлом по базальтовой жиле эхо возвращается не сразу, а с задержкой в три секунды, будто в глубине скалы кто-то отвечает тем же числом ударов. Приказал смене молчать.\n\nКлюч от дренажного байпаса оставил в сейфе конторы. Код замка — год закладки первого шурфа (1924).\n\n— Старший маркшейдер И. В. Прохоров"
		)

	for i in range(40):
		await process_frame

	_save_shot("03_document_d01_vintage_inspection.png")

	# Close document viewer
	if m1_instance.document_viewer and m1_instance.document_viewer.visible:
		m1_instance.document_viewer.hide_document()

	for i in range(15):
		await process_frame

	# =========================================================================
	# SHOT 4: Diegetic Field Journal (Quest Tracker & Narrative Systems [J])
	# =========================================================================
	print("[SHOWCASE] Capturing Shot 4: Diegetic Field Journal...")
	if m1_instance.field_journal:
		m1_instance.field_journal.open_journal()
		m1_instance.field_journal.switch_tab(0) # Quests tab

	for i in range(40):
		await process_frame

	_save_shot("04_diegetic_field_journal_quests.png")

	# Close field journal
	if m1_instance.field_journal and m1_instance.field_journal.is_open:
		m1_instance.field_journal.close_journal()

	for i in range(15):
		await process_frame

	# =========================================================================
	# SHOT 4B: Expedition Backpack & Field Workbench (Modal Window [TAB/E])
	# =========================================================================
	print("[SHOWCASE] Capturing Shot 4B: Expedition Backpack & Field Workbench...")
	if player and player.inventory_system:
		player.inventory_system.set_open(true)

	for i in range(40):
		await process_frame

	_save_shot("04b_expedition_backpack_workbench.png")

	if player and player.inventory_system:
		player.inventory_system.set_open(false)

	for i in range(15):
		await process_frame

	# =========================================================================
	# SHOT 5: Echo Shaft Chasm, Climbing Ropes & The Watcher in the Fog
	# =========================================================================
	print("[SHOWCASE] Capturing Shot 5: Echo Shaft & The Watcher...")
	if player:
		if player.lantern:
			player.lantern.set_hand_mode(false) # Harness mode: illuminates forwards
			player.lantern.set_lit(true)
		if player.pickaxe:
			player.pickaxe.set_active(true)

		# Standing on the eastern observation ledge (X=3.5, Y=34.8, Z=-20.0), looking across the 20m vertical chasm towards The Watcher at (-15.0, 32.5, -20.0)
		player.global_position = Vector3(3.5, 34.8, -20.0)
		player.look_at(Vector3(-15.0, 32.5, -20.0), Vector3.UP)
		if neck:
			neck.rotation_degrees = Vector3(0, 0, 0)

	for i in range(40):
		await process_frame

	_save_shot("05_echo_shaft_watcher_in_fog.png")

	# =========================================================================
	# SHOT 6: Drained Lower Sump (SEC-01), Cast-Iron Valve & Armored Safe EE-06
	# =========================================================================
	print("[SHOWCASE] Capturing Shot 6: Drained Sump & Safe EE-06...")
	if player:
		if player.lantern:
			player.lantern.set_hand_mode(true)
			player.lantern.set_lit(true)
		if player.pickaxe:
			player.pickaxe.set_active(false)

		# Positioned in the lower drained collector (Zone E / SEC-01), looking at the heavy safe EE-06 and bronze transmitter
		player.global_position = Vector3(15.5, 29.5, -10.5)
		player.look_at(Vector3(14.0, 28.6, -12.0), Vector3.UP)
		if neck:
			neck.rotation_degrees = Vector3(-20.0, 0, 0)

	for i in range(40):
		await process_frame

	_save_shot("06_drained_sump_safe_ee06.png")

	print("=====================================================================")
	print("[SHOWCASE] All 6 High-Fidelity In-Game Story Screenshots Captured!")
	print("=====================================================================")
	quit(0)

func _save_shot(filename: String) -> void:
	var vp_tex = root.get_texture()
	if vp_tex:
		var img = vp_tex.get_image()
		if img and not img.is_empty():
			var local_path = "res://screenshots/story_showcase/" + filename
			img.save_png(local_path)
			print("  [SAVED LOCAL] ", local_path)

			var artifact_path = ARTIFACT_DIR + filename
			img.save_png(artifact_path)
			print("  [SAVED ARTIFACT] ", artifact_path)
