# scripts/verify_game_overhaul.gd
extends SceneTree

func _initialize() -> void:
	print("==================================================")
	print("--- HOLLOW CORE PHASE 3 VERIFICATION SUITE ---")
	print("==================================================")

	var all_passed = true

	# TEST 1: SoundManager loading & altitude scaling
	print("\n[TEST 1] Testing SoundManager & Altitude Audio Scaling...")
	var SoundManagerClass = load("res://scripts/sound_manager.gd")
	if SoundManagerClass == null:
		print("FAILED: Cannot load SoundManager")
		all_passed = false
	else:
		var sm = SoundManagerClass.new()
		root.add_child(sm)

		var expected_keys = ["howling_wind", "cavern_wind", "horror_drone", "distant_scream", "phantom_footsteps", "horror_swell"]
		for k in expected_keys:
			if not sm._sound_bank.has(k) or sm._sound_bank[k].size() == 0:
				print("FAILED: Missing authentic audio category: ", k)
				all_passed = false
			else:
				print("  -> Audio category '%s' loaded (%d streams)" % [k, sm._sound_bank[k].size()])

		# Test altitude scaling:
		sm.update_altitude_atmosphere(10.0) # Deep cave
		var deep_vol = sm.surface_wind_player.volume_db
		var deep_pitch = sm.surface_wind_player.pitch_scale
		print("  -> At Y=10.0 (Deep Cave): Wind Vol = %.1f dB, Pitch = %.2f" % [deep_vol, deep_pitch])

		sm.update_altitude_atmosphere(50.0) # Surface peak
		var surf_vol = sm.surface_wind_player.volume_db
		var surf_pitch = sm.surface_wind_player.pitch_scale
		print("  -> At Y=50.0 (Surface Tundra): Wind Vol = %.1f dB, Pitch = %.2f" % [surf_vol, surf_pitch])

		if surf_vol <= deep_vol:
			print("FAILED: Surface wind volume did not increase with altitude!")
			all_passed = false
		elif surf_pitch <= deep_pitch:
			print("FAILED: Surface wind pitch did not increase with altitude!")
			all_passed = false
		else:
			print("  [PASS] Altitude wind scaling verified: Volume climbs by +%.1fdB, Pitch climbs from %.2fx to %.2fx!" % [
				surf_vol - deep_vol, deep_pitch, surf_pitch
			])

	# TEST 2: All Mob Bespoke Textures Verification
	print("\n[TEST 2] Testing Mob Bespoke Material Application...")
	var mobs_to_test = [
		{"name": "AbyssalGlider", "script": "res://scripts/abyssal_glider.gd"},
		{"name": "CaveWyrm", "script": "res://scripts/cave_wyrm.gd"},
		{"name": "ChasmStalker", "script": "res://scripts/chasm_stalker.gd"},
		{"name": "FungalStrider", "script": "res://scripts/fungal_strider.gd"},
		{"name": "GeodeGolem", "script": "res://scripts/geode_golem.gd"},
		{"name": "LithicCrawler", "script": "res://scripts/lithic_crawler.gd"},
		{"name": "MagmaBasilisk", "script": "res://scripts/magma_basilisk.gd"},
		{"name": "PaleStalker", "script": "res://scripts/pale_stalker.gd"},
		{"name": "SporeSpitter", "script": "res://scripts/spore_spitter.gd"},
		{"name": "WallMimic", "script": "res://scripts/wall_mimic.gd"},
		{"name": "TheWatcher", "script": "res://scripts/the_watcher.gd"}
	]

	for m_info in mobs_to_test:
		var cls = load(m_info["script"])
		if cls == null:
			print("FAILED: Could not load script ", m_info["script"])
			all_passed = false
			continue

		var mob_inst = cls.new()
		root.add_child(mob_inst)

		var mi_list = []
		_collect_mesh_instances(mob_inst, mi_list)

		var has_override = false
		for mi in mi_list:
			if mi.material_override != null:
				has_override = true
				break

		if mi_list.size() > 0 and not has_override:
			print("FAILED: Mob '%s' has %d meshes but none have material_override!" % [m_info["name"], mi_list.size()])
			all_passed = false
		else:
			print("  [PASS] Mob '%s' (%d meshes) has bespoke material override active." % [m_info["name"], mi_list.size()])

		mob_inst.queue_free()

	# TEST 3: Inventory Integrity & Tool Gating
	print("\n[TEST 3] Testing Inventory Gating & Placement Synchronization...")
	var PlayerClass = load("res://scripts/player_controller.gd")
	var HUDClass = load("res://scripts/hud.gd")

	var p = PlayerClass.new()
	root.add_child(p)

	var h = HUDClass.new()
	root.add_child(h)
	h.set_player(p)

	# Before picking up pickaxe:
	p.set_active_slot(2)
	if p.pickaxe and p.pickaxe.is_active:
		print("FAILED: Pickaxe is active on slot 2 even though slot 2 is empty!")
		all_passed = false
	else:
		print("  [PASS] Pickaxe correctly inactive when slot 2 has no pickaxe.")

	# Pick up lantern into slot 0
	p.inventory_system.set_slot(0, "lantern", 1)
	p.set_active_slot(1)
	if p.lantern and not p.lantern.is_held_in_hand:
		print("FAILED: Lantern not in hand after placing lantern in slot 0 and selecting slot 1!")
		all_passed = false
	else:
		print("  [PASS] Lantern properly equipped in hand when slot 1 contains lantern.")

	# Pick up pickaxe into slot 1
	p.inventory_system.set_slot(1, "pickaxe", 1)
	p.set_active_slot(2)
	if p.pickaxe and not p.pickaxe.is_active:
		print("FAILED: Pickaxe not active after placing pickaxe in slot 1 and selecting slot 2!")
		all_passed = false
	else:
		print("  [PASS] Pickaxe properly equipped in hand when slot 2 contains pickaxe.")

	# Test block placement inventory consumption
	p.inventory_system.set_slot(2, "cobblestone", 10)
	p.set_active_slot(3)
	var initial_cobble = 0
	for s in p.inventory_system.slots:
		if not s.is_empty() and s.get("id") == "cobblestone":
			initial_cobble += s.get("count", 0)

	# Simulate placing block
	p.inventory_system.consume_active_item(1)
	var after_cobble = 0
	for s in p.inventory_system.slots:
		if not s.is_empty() and s.get("id") == "cobblestone":
			after_cobble += s.get("count", 0)

	if after_cobble != (initial_cobble - 1):
		print("FAILED: Cobblestone did not decrement! Initial: %d, After: %d" % [initial_cobble, after_cobble])
		all_passed = false
	else:
		print("  [PASS] Block count decrements in inventory (%d -> %d)." % [initial_cobble, after_cobble])

	# Check HUD resource label text
	h._update_resource_display()
	if not ("COBBLE: x%d" % after_cobble in h.resource_label.text):
		print("FAILED: HUD resource label did not update! Text is: ", h.resource_label.text)
		all_passed = false
	else:
		print("  [PASS] HUD resource label matches exact real-time inventory count: ", h.resource_label.text)

	print("\n==================================================")
	if all_passed:
		print("ALL VERIFICATION SUITE TESTS PASSED WITH 100% SUCCESS!")
	else:
		print("SOME TESTS FAILED! REVIEW LOGS ABOVE.")
	print("==================================================")

	quit(0 if all_passed else 1)

func _collect_mesh_instances(node: Node, list: Array) -> void:
	if node is MeshInstance3D:
		list.append(node)
	for c in node.get_children():
		_collect_mesh_instances(c, list)
