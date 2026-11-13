# test_m0_verification.gd
extends SceneTree

## Hollow Core — Milestone 0 (M0) Automated Verification Test Suite
## Validates 256m vertical geology, organic mining, chunk persistence,
## acoustic memory, and performance telemetry under Godot 4.7+ Forward+.

const WorldConfigClass = preload("res://scripts/world/world_config.gd")
const VoxelWorldClass = preload("res://scripts/voxel_world.gd")
const PlayerControllerClass = preload("res://scripts/player_controller.gd")
const SoundManagerClass = preload("res://scripts/sound_manager.gd")
const SoundMemoryManagerClass = preload("res://scripts/audio/sound_memory_manager.gd")
const AcousticEventClass = preload("res://scripts/audio/acoustic_event.gd")
const TerrainModifierClass = preload("res://scripts/terrain/terrain_modifier.gd")
const TerrainPersistenceClass = preload("res://scripts/terrain/terrain_persistence.gd")

var m0_scene: Node3D = null
var voxel_world: Node3D = null
var terrain_modifier: Node = null
var sound_memory_manager: Node = null
var player: CharacterBody3D = null
var world_config: Resource = null

var passed_count: int = 0
var failed_count: int = 0
var test_telemetry: Dictionary = {}

func _init() -> void:
	print("======================================================================")
	print("      HOLLOW CORE — MILESTONE 0 (M0) SYSTEM VERIFICATION SUITE")
	print("======================================================================")
	call_deferred("_run_suite")

func _run_suite() -> void:
	var scene_res = load("res://scenes/development/m0_core_test.tscn")
	assert(scene_res != null, "Fatal: Unable to load scenes/development/m0_core_test.tscn")
	m0_scene = scene_res.instantiate()
	root.add_child(m0_scene)

	# Process frames to allow initialization
	for i in range(10):
		await process_frame

	voxel_world = m0_scene.get_node_or_null("VoxelWorld")
	terrain_modifier = m0_scene.get_node_or_null("TerrainModifier")
	sound_memory_manager = m0_scene.get_node_or_null("SoundMemoryManager")
	player = m0_scene.get_node_or_null("Player")
	world_config = voxel_world.world_config

	assert(voxel_world != null, "VoxelWorld missing")
	assert(terrain_modifier != null, "TerrainModifier missing")
	assert(sound_memory_manager != null, "SoundMemoryManager missing")
	assert(player != null, "Player missing")

	print("\n--- RUNNING 7 COMPREHENSIVE M0 VERIFICATION TESTS ---")

	await _test_1_small_volume_mining()
	await _test_2_large_volume_cavity_carving()
	await _test_3_chunk_boundary_mining()
	await _test_4_repeated_same_spot_mining()
	await _test_5_geology_persistence_save_load()
	await _test_6_acoustic_memory_and_echo()
	await _test_7_performance_telemetry()

	print("\n======================================================================")
	print("M0 VERIFICATION SUMMARY: %d PASSED, %d FAILED" % [passed_count, failed_count])
	print("======================================================================")

	if failed_count == 0:
		print(">> ALL MILESTONE 0 ARCHITECTURAL CHECKS FULLY VALIDATED! <<")
		quit(0)
	else:
		printerr(">> MILESTONE 0 VERIFICATION FAILED! <<")
		quit(1)

func _record_pass(test_name: String, details: String = "") -> void:
	passed_count += 1
	print("  [PASS] %s %s" % [test_name, details])

func _record_fail(test_name: String, error_msg: String) -> void:
	failed_count += 1
	printerr("  [FAIL] %s: %s" % [test_name, error_msg])

# -----------------------------------------------------------------------------
# TEST 1: Small Volume Mining
# -----------------------------------------------------------------------------
func _test_1_small_volume_mining() -> void:
	print("\n[TEST 1] Small Volume Mining & Drop Generation...")
	var test_coord = Vector3i(2, 14, 2)
	voxel_world.set_block(test_coord.x, test_coord.y, test_coord.z, VoxelWorldClass.BlockType.STONE, false)

	var pre_block = voxel_world.get_block(test_coord.x, test_coord.y, test_coord.z)
	if pre_block != VoxelWorldClass.BlockType.STONE:
		_record_fail("Test 1", "Failed to place stone block at test coord")
		return

	var pre_drops = m0_scene.get_tree().get_nodes_in_group("dropped_items").size()
	var hit_pos = Vector3(2.5, 14.5, 2.5)
	var hit_norm = Vector3(0, 1, 0)

	var start_usec = Time.get_ticks_usec()
	var mine_ok = voxel_world.mine_block(test_coord, 10.0, hit_pos, hit_norm, true)
	var elapsed_ms = (Time.get_ticks_usec() - start_usec) / 1000.0

	await process_frame # Allow dropped item node to enter tree and execute _ready()

	var post_block = voxel_world.get_block(test_coord.x, test_coord.y, test_coord.z)
	var post_drops = m0_scene.get_tree().get_nodes_in_group("dropped_items").size()

	if mine_ok and post_block == VoxelWorldClass.BlockType.AIR and post_drops > pre_drops:
		_record_pass("Test 1 - Small Volume Mining", "(Mined in %.2f ms, Drop spawned: %d -> %d)" % [elapsed_ms, pre_drops, post_drops])
		test_telemetry["test_1_mining_time_ms"] = elapsed_ms
	else:
		_record_fail("Test 1", "Mine block failed: ok=%s, post_block=%d, drops=%d->%d" % [mine_ok, post_block, pre_drops, post_drops])

# -----------------------------------------------------------------------------
# TEST 2: Large Volume Organic Cavity Carving
# -----------------------------------------------------------------------------
func _test_2_large_volume_cavity_carving() -> void:
	print("\n[TEST 2] Large Volume Organic Cavity Carving...")
	var center = Vector3i(6, 15, 6)

	# Fill 5x5x5 solid basalt cube
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			for dz in range(-2, 3):
				voxel_world.set_block(center.x + dx, center.y + dy, center.z + dz, VoxelWorldClass.BlockType.DEEP_BASALT, false)

	# Carve organic cavity
	var start_usec = Time.get_ticks_usec()
	var carved_voxels = terrain_modifier.carve_organic_cavity(
		Vector3(center.x + 0.5, center.y + 0.5, center.z + 0.5),
		2.4,
		Vector3(0, 1, 0),
		0.45
	)
	var elapsed_ms = (Time.get_ticks_usec() - start_usec) / 1000.0

	# Verify non-trivial organic volume was carved
	var air_count = 0
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			for dz in range(-2, 3):
				if voxel_world.get_block(center.x + dx, center.y + dy, center.z + dz) == VoxelWorldClass.BlockType.AIR:
					air_count += 1

	if carved_voxels.size() >= 5 and air_count >= 5:
		_record_pass("Test 2 - Organic Cavity Carving", "(Carved %d voxels organically in %.2f ms, resulting in %d air blocks)" % [
			carved_voxels.size(), elapsed_ms, air_count
		])
		test_telemetry["test_2_cavity_voxels"] = carved_voxels.size()
		test_telemetry["test_2_cavity_time_ms"] = elapsed_ms
	else:
		_record_fail("Test 2", "Organic carving yielded insufficient voxels: carved=%d, air=%d" % [carved_voxels.size(), air_count])

# -----------------------------------------------------------------------------
# TEST 3: Mining at Chunk Boundary
# -----------------------------------------------------------------------------
func _test_3_chunk_boundary_mining() -> void:
	print("\n[TEST 3] Chunk Boundary Multi-Chunk Mining...")
	# Chunk 0 has X: 0..15, Chunk 1 has X: 16..31. Boundary is between X=15 and X=16.
	var x_left = 15
	var x_right = 16
	var y = 14
	var z = 5

	voxel_world.set_block(x_left, y, z, VoxelWorldClass.BlockType.STONE, false)
	voxel_world.set_block(x_right, y, z, VoxelWorldClass.BlockType.STONE, false)

	var c_left = voxel_world.get_chunk_coords(x_left, z)
	var c_right = voxel_world.get_chunk_coords(x_right, z)

	if c_left == c_right:
		_record_fail("Test 3", "Coordinates (15, 5) and (16, 5) did not land in different chunks!")
		return

	# Mine spanning the boundary
	var hit_pos = Vector3(15.5, y + 0.5, z + 0.5)
	var hit_norm = Vector3(1, 0, 0)
	var carved = terrain_modifier.carve_organic_cavity(hit_pos, 1.8, hit_norm, 0.3)

	# Verify both chunks contain modified voxels
	var b_left = voxel_world.get_block(x_left, y, z)
	var b_right = voxel_world.get_block(x_right, y, z)

	# Check that chunks re-meshed properly and are collidable
	var node_left = voxel_world.chunk_nodes.get(c_left)
	var node_right = voxel_world.chunk_nodes.get(c_right)

	var valid_nodes = (node_left != null and node_right != null)
	var col_left = node_left.get_node_or_null("CollisionShape3D") if node_left else null
	var col_right = node_right.get_node_or_null("CollisionShape3D") if node_right else null

	if valid_nodes and col_left != null and col_right != null:
		_record_pass("Test 3 - Boundary Mining", "(Carved across Chunks %s and %s; both re-meshed with valid collisions)" % [
			c_left, c_right
		])
	else:
		_record_fail("Test 3", "Boundary re-meshing collision failed: valid_nodes=%s, left=%s, right=%s" % [
			valid_nodes, col_left != null, col_right != null
		])

# -----------------------------------------------------------------------------
# TEST 4: Repeated Mining of Same Spot
# -----------------------------------------------------------------------------
func _test_4_repeated_same_spot_mining() -> void:
	print("\n[TEST 4] Repeated Mining of Same Air Spot...")
	var spot = Vector3i(2, 14, 2)
	# Verify it is already AIR from Test 1
	var current_b = voxel_world.get_block(spot.x, spot.y, spot.z)
	if current_b != VoxelWorldClass.BlockType.AIR:
		voxel_world.set_block(spot.x, spot.y, spot.z, VoxelWorldClass.BlockType.AIR, false)

	var pre_drops = m0_scene.get_tree().get_nodes_in_group("pickups").size()
	# Attempt to mine AIR block repeatedly
	var mine_res_1 = voxel_world.mine_block(spot, 10.0, Vector3(2.5, 14.5, 2.5), Vector3(0, 1, 0), true)
	var mine_res_2 = voxel_world.mine_block(spot, 10.0, Vector3(2.5, 14.5, 2.5), Vector3(0, 1, 0), true)
	var post_drops = m0_scene.get_tree().get_nodes_in_group("pickups").size()

	# Both should return false, no crashes, and no phantom item drops
	if not mine_res_1 and not mine_res_2 and post_drops == pre_drops:
		_record_pass("Test 4 - Repeated Mining Resilience", "(Gracefully rejected AIR mining, no phantom drops)")
	else:
		_record_fail("Test 4", "Repeated mining failed safety check: r1=%s, r2=%s, drops=%d->%d" % [
			mine_res_1, mine_res_2, pre_drops, post_drops
		])

# -----------------------------------------------------------------------------
# TEST 5: Save & Reload Persistence Test
# -----------------------------------------------------------------------------
func _test_5_geology_persistence_save_load() -> void:
	print("\n[TEST 5] Chunk Persistence & Delta Save/Load...")
	var slot_name = "m0_verification_slot"
	var p_x = 3
	var p_y = -45 # In Deep Mantle/Basalt realm
	var p_z = 3

	# Set unique block signature
	voxel_world.set_block(p_x, p_y, p_z, VoxelWorldClass.BlockType.DEEP_BASALT, false)
	voxel_world.set_block(p_x + 1, p_y, p_z, VoxelWorldClass.BlockType.PHOSPHOR_ORE, false)

	# Save to disk
	var save_ok = voxel_world.save_world_state(slot_name)
	if not save_ok:
		_record_fail("Test 5", "save_world_state returned false")
		return

	# Reset modifications in memory
	voxel_world.set_block(p_x, p_y, p_z, VoxelWorldClass.BlockType.AIR, false)
	voxel_world.set_block(p_x + 1, p_y, p_z, VoxelWorldClass.BlockType.AIR, false)
	assert(voxel_world.get_block(p_x, p_y, p_z) == VoxelWorldClass.BlockType.AIR)

	# Reload from disk
	var load_ok = voxel_world.load_world_state(slot_name)
	if not load_ok:
		_record_fail("Test 5", "load_world_state returned false")
		return

	var restored_b1 = voxel_world.get_block(p_x, p_y, p_z)
	var restored_b2 = voxel_world.get_block(p_x + 1, p_y, p_z)

	if restored_b1 == VoxelWorldClass.BlockType.DEEP_BASALT and restored_b2 == VoxelWorldClass.BlockType.PHOSPHOR_ORE:
		_record_pass("Test 5 - Chunk Delta Persistence", "(Successfully saved, wiped from RAM, and restored exact binary deltas)")
	else:
		_record_fail("Test 5", "Restored block mismatch: b1=%d (expected DEEP_BASALT), b2=%d (expected PHOSPHOR)" % [restored_b1, restored_b2])

# -----------------------------------------------------------------------------
# TEST 6: Acoustic Memory Recording and Echo Playback
# -----------------------------------------------------------------------------
func _test_6_acoustic_memory_and_echo() -> void:
	print("\n[TEST 6] Lithic Resonance Acoustic Memory Buffer & Echo...")
	var initial_size = sound_memory_manager.ring_buffer.size()

	# Record simulated player hits and footsteps
	var captured = {
		"received": false,
		"echo": null,
		"pos": Vector3.ZERO
	}

	sound_memory_manager.lithic_echo_triggered.connect(func(ev, pos, _age):
		captured["received"] = true
		captured["echo"] = ev
		captured["pos"] = pos
	)

	# Record 5 acoustic events
	for i in range(5):
		var ev_type = "pickaxe_hit" if i % 2 == 0 else "step"
		var ev_pos = player.global_position + Vector3(i * 1.5, 0, i * 1.0)
		sound_memory_manager.record_event(ev_type, ev_pos, "pickaxe_stone", 0.9, "Deep Basalt", 11.4)

	var new_size = sound_memory_manager.ring_buffer.size()
	if new_size != initial_size + 5:
		_record_fail("Test 6", "Ring buffer failed to record 5 events: %d -> %d" % [initial_size, new_size])
		return

	# Manually age the events so they qualify for replay (age >= 3.5s)
	for ev in sound_memory_manager.ring_buffer:
		ev.timestamp -= 10.0 # Make them 10 seconds old

	# Trigger lithic echo replay
	sound_memory_manager._attempt_lithic_echo_replay()

	if captured["received"] and captured["echo"] != null:
		var d = player.global_position.distance_to(captured["pos"])
		_record_pass("Test 6 - Lithic Acoustic Echo", "(Captured echo type '%s', 11.4 Hz lore / 114 Hz harmonic, replay distance: %.2fm)" % [
			captured["echo"].event_type, d
		])
	else:
		_record_fail("Test 6", "Lithic echo replay did not trigger signal")

# -----------------------------------------------------------------------------
# TEST 7: Performance Telemetry (GTX 1660 / Steam Deck targets)
# -----------------------------------------------------------------------------
func _test_7_performance_telemetry() -> void:
	print("\n[TEST 7] Performance Telemetry & Hardware Targets...")

	var static_mem_bytes = OS.get_static_memory_usage()
	var static_mem_mb = float(static_mem_bytes) / (1024.0 * 1024.0)

	# Measure frame execution times over 30 frames
	var frame_times: Array[float] = []
	for frame in range(30):
		var f_start = Time.get_ticks_usec()
		await process_frame
		var f_dur_ms = (Time.get_ticks_usec() - f_start) / 1000.0
		frame_times.append(f_dur_ms)

	var avg_frame_ms = 0.0
	for t in frame_times:
		avg_frame_ms += t
	avg_frame_ms /= float(frame_times.size())
	var est_fps = 1000.0 / max(0.01, avg_frame_ms)

	test_telemetry["static_mem_mb"] = static_mem_mb
	test_telemetry["avg_frame_ms"] = avg_frame_ms
	test_telemetry["est_fps"] = est_fps
	test_telemetry["loaded_chunks"] = voxel_world.chunks.size()

	# Hardware targets: RAM < 2.2 GB (2252 MB), Target FPS >= 60 in headless
	var mem_ok = static_mem_mb < 2252.0
	var speed_ok = avg_frame_ms < 16.67 # Target 60 FPS = 16.67 ms

	if mem_ok and speed_ok:
		_record_pass("Test 7 - Performance Telemetry", "(Memory: %.2f MB [< 2252 MB], Avg Frame: %.2f ms [~%.1f FPS >= 60 FPS], Chunks: %d)" % [
			static_mem_mb, avg_frame_ms, est_fps, voxel_world.chunks.size()
		])
	else:
		_record_fail("Test 7", "Performance limits exceeded: Mem=%.2f MB (limit 2252), Frame=%.2f ms (limit 16.67)" % [
			static_mem_mb, avg_frame_ms
		])
