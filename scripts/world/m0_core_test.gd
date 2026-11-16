# scripts/world/m0_core_test.gd
extends Node3D

## M0 Core Milestone Test Environment
## Validates 256m vertical geology, organic mining, chunk persistence,
## and Lithic Echo acoustic memory in Godot 4.7+ Forward+.

const WorldConfigClass = preload("res://scripts/world/world_config.gd")
const VoxelWorldClass = preload("res://scripts/voxel_world.gd")
const PlayerControllerClass = preload("res://scripts/player_controller.gd")
const SoundManagerClass = preload("res://scripts/sound_manager.gd")
const SoundMemoryManagerClass = preload("res://scripts/audio/sound_memory_manager.gd")
const TerrainModifierClass = preload("res://scripts/terrain/terrain_modifier.gd")
const TerrainPersistenceClass = preload("res://scripts/terrain/terrain_persistence.gd")

var world_config: Resource
var sound_manager: Node
var sound_memory_manager: Node
var voxel_world: Node3D
var terrain_modifier: Node
var player: CharacterBody3D
var world_env: WorldEnvironment

# Diagnostic Overlay Controls
var diag_canvas: CanvasLayer
var diag_label: Label
var last_echo_info: String = "None yet"

func _ready() -> void:
	print("[M0 Test] Initializing Milestone 0 Core Verification Scene...")
	world_config = WorldConfigClass.get_default()

	_setup_audio()
	_setup_environment()
	_setup_world()
	_setup_player()
	_setup_diagnostic_hud()

	print("[M0 Test] M0 Core Scene Ready! Range: Y = %d .. %d (Height: %d)" % [
		world_config.min_world_y, world_config.max_world_y, world_config.get_chunk_height()
	])

func _setup_audio() -> void:
	sound_manager = SoundManagerClass.new()
	sound_manager.name = "SoundManager"
	add_child(sound_manager)

	sound_memory_manager = SoundMemoryManagerClass.new()
	sound_memory_manager.name = "SoundMemoryManager"
	add_child(sound_memory_manager)

	sound_memory_manager.lithic_echo_triggered.connect(func(ev, _pos, age):
		last_echo_info = "%s (%.1fs ago)" % [ev.event_type, age]
	)

func _setup_environment() -> void:
	world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"

	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.006, 0.008, 0.012, 1.0) # Deep cave obsidian black
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.18, 0.22, 0.30, 1.0)
	env.ambient_light_energy = 0.30 # Diegetic cave bounce
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.15
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = Color(0.14, 0.18, 0.22, 1.0)
	env.fog_density = 0.035
	env.fog_aerial_perspective = 0.5

	world_env.environment = env
	add_child(world_env)

func _setup_world() -> void:
	voxel_world = VoxelWorldClass.new()
	voxel_world.name = "VoxelWorld"
	voxel_world.world_config = world_config
	voxel_world.add_to_group("voxel_world")
	add_child(voxel_world)

	terrain_modifier = TerrainModifierClass.new(voxel_world, world_config)
	terrain_modifier.name = "TerrainModifier"
	add_child(terrain_modifier)
	voxel_world.terrain_modifier = terrain_modifier

	# Carve specialized M0 Showcase Geology in the immediate vicinity
	_carve_m0_showcase_geology()

func _carve_m0_showcase_geology() -> void:
	# 1. Monumental Hexagonal Basalt Column rising from Y = -20 up to Y = 25 at (0, 0)
	for gy in range(-20, 26):
		for dx in range(-2, 3):
			for dz in range(-2, 3):
				if abs(dx) + abs(dz) <= 3:
					voxel_world.set_block(dx, gy, dz, VoxelWorld.BlockType.DEEP_BASALT, false)

	# 2. Rich Mineral Deposit Vein at (X: 10..14, Y: 11..14, Z: 2..5)
	for mx in range(10, 14):
		for my in range(11, 14):
			for mz in range(2, 5):
				var ore_type = VoxelWorld.BlockType.IRON_ORE
				if (mx + my) % 3 == 0:
					ore_type = VoxelWorld.BlockType.PHOSPHOR_ORE
				elif (mx + mz) % 2 == 0:
					ore_type = VoxelWorld.BlockType.COPPER_ORE
				voxel_world.set_block(mx, my, mz, ore_type, false)

	# 3. Destructible Basalt Wall at X = -10 (Y: 10..15, Z: -3..3) blocking a secret cave
	for wy in range(10, 15):
		for wz in range(-3, 4):
			voxel_world.set_block(-10, wy, wz, VoxelWorld.BlockType.DEEP_BASALT, false)

	# 4. Deep Abyssal Chasm Drop at (X: 18..24, Z: -10..-4) plunging from Y = 10 down to Y = -60
	for cx in range(18, 25):
		for cz in range(-10, -3):
			for cy in range(-60, 11):
				voxel_world.set_block(cx, cy, cz, VoxelWorld.BlockType.AIR, false)

func _setup_player() -> void:
	player = PlayerControllerClass.new()
	player.name = "Player"
	player.add_to_group("player")
	add_child(player)

	# Safe spawn position on a solid stone ledge
	player.global_position = Vector3(5.0, 12.0, 5.0)
	player.voxel_world = voxel_world

	# Connect sound memory recording to player footsteps and hits
	sound_memory_manager.set_player(player)
	player.acoustic_noise_emitted.connect(func(pos, rad, n_type):
		var sound_name = "footstep_stone" if n_type == "footstep" else "pickaxe_stone"
		sound_memory_manager.record_event(n_type, pos, sound_name, clamp(rad / 20.0, 0.2, 1.0))
	)

func _setup_diagnostic_hud() -> void:
	diag_canvas = CanvasLayer.new()
	diag_canvas.name = "DiagHUD"

	var panel = PanelContainer.new()
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size = Vector2(380, 240)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.09, 0.85) # Muted graphite slate
	style.border_color = Color(0.25, 0.32, 0.40, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	diag_label = Label.new()
	diag_label.add_theme_color_override("font_color", Color(0.85, 0.90, 0.95))
	diag_label.add_theme_font_size_override("font_size", 13)
	diag_label.text = "Initializing diagnostics..."

	panel.add_child(diag_label)
	diag_canvas.add_child(panel)
	add_child(diag_canvas)

func _process(_delta: float) -> void:
	_update_diagnostic_hud()
	_handle_save_load_input()

func _update_diagnostic_hud() -> void:
	if diag_label == null or player == null or voxel_world == null:
		return

	var pos = player.global_position
	var v_coord = world_config.world_to_voxel(pos)
	var c_coord = world_config.world_to_chunk_coord(pos)
	var biome_name = world_config.get_biome_at_height(v_coord.y)
	var fps = Engine.get_frames_per_second()
	var frame_ms = 1000.0 / max(1.0, float(fps))
	var loaded_chunks = voxel_world.chunks.size()
	var mod_count = voxel_world.modified_voxels.size()
	var echo_events = sound_memory_manager.ring_buffer.size()

	var text = "[ HOLLOW CORE — M0 DIAGNOSTICS ]\n"
	text += "COORDS: X: %4.1f | Y: %4.1f | Z: %4.1f\n" % [pos.x, pos.y, pos.z]
	text += "VOXEL : (%d, %d, %d)\n" % [v_coord.x, v_coord.y, v_coord.z]
	text += "CHUNK : (%d, %d)\n" % [c_coord.x, c_coord.y]
	text += "STRATUM: %s\n" % [biome_name]
	text += "HEIGHT : Y = %d .. %d (256m)\n" % [world_config.min_world_y, world_config.max_world_y]
	text += "CHUNKS : %d loaded | MODS: %d\n" % [loaded_chunks, mod_count]
	text += "ECHO BUF: %d events | LAST: %s\n" % [echo_events, last_echo_info]
	text += "FPS    : %d (%.2f ms)\n" % [fps, frame_ms]
	text += "KEYS   : F5 = Save Geology | F9 = Load Geology"

	diag_label.text = text

func _handle_save_load_input() -> void:
	if Input.is_action_just_pressed("ui_page_up") or Input.is_key_pressed(KEY_F5):
		var ok = voxel_world.save_world_state("m0_test_slot")
		print("[M0 Test] Quick-Saved geology state: ", ok)
	elif Input.is_action_just_pressed("ui_page_down") or Input.is_key_pressed(KEY_F9):
		var ok = voxel_world.load_world_state("m0_test_slot")
		print("[M0 Test] Quick-Loaded geology state: ", ok)
