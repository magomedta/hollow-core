extends Node3D

const VoxelWorldClass = preload("res://scripts/voxel_world.gd")
const PlayerControllerClass = preload("res://scripts/player_controller.gd")
const GameHUDClass = preload("res://scripts/hud.gd")
const ScreenshotHelperClass = preload("res://scripts/screenshot_helper.gd")
const SoundManagerClass = preload("res://scripts/sound_manager.gd")
const TheWatcherClass = preload("res://scripts/the_watcher.gd")

var sound_manager: Node
var voxel_world: Node3D
var player: CharacterBody3D
var hud: CanvasLayer
var screenshot_helper: Node
var world_env: WorldEnvironment
var structures_container: Node3D
var enemies_container: Node3D
var mob_spawn_timer: float = 0.0
const ScenarioManagerClass = preload("res://scripts/scenario_manager.gd")
var scenario_manager: Node3D

func _ready() -> void:
	print("[Hollow Core] Forwarding from main.tscn to M1 Vertical Slice (res://scenes/development/m1_vertical_slice.tscn)...")
	get_tree().change_scene_to_file("res://scenes/development/m1_vertical_slice.tscn")


func _setup_audio() -> void:
	sound_manager = SoundManagerClass.new()
	sound_manager.name = "SoundManager"
	add_child(sound_manager)

func _setup_structures_container() -> void:
	structures_container = Node3D.new()
	structures_container.name = "PlacedStructures"
	add_child(structures_container)

func _setup_environment() -> void:
	world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"

	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.005, 0.007, 0.010, 1.0) # Authentic deep cave pitch darkness

	# Subterranean cave illumination: realistic ambient bounce
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.24, 0.28, 0.36, 1.0)
	env.ambient_light_energy = 0.35 # Atmospheric ambient bounce revealing cave depth & rock contours

	# Cinematic ACES tonemapper
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.15

	# Atmospheric Glow / Bioluminescence
	env.glow_enabled = true
	env.glow_intensity = 0.20
	env.glow_strength = 0.95
	env.glow_bloom = 0.04
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

	# Screen-space Ambient Occlusion (contact shadows in rock crevices)
	env.ssao_enabled = true
	env.ssao_radius = 2.0
	env.ssao_intensity = 2.2
	env.ssao_power = 1.5

	# Screen-space Indirect Lighting (SSIL) - realistic real-time light bounce from lanterns and torches!
	env.ssil_enabled = true
	env.ssil_radius = 5.5
	env.ssil_intensity = 1.3
	env.ssil_sharpness = 0.8
	env.ssil_normal_rejection = 1.0

	# Atmospheric Subterranean Depth Fog (Classic Alpha Creepypasta Misty Fog Horizon)
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = Color(0.18, 0.22, 0.26, 1.0)
	env.fog_density = 0.038
	env.fog_aerial_perspective = 0.6
	env.fog_sky_affect = 0.0

	# Volumetric Fog catching warm torch and lantern rays
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.012
	env.volumetric_fog_albedo = Color(0.32, 0.38, 0.44, 1.0)
	env.volumetric_fog_emission = Color(0.015, 0.02, 0.025, 1.0)
	env.volumetric_fog_emission_energy = 0.15
	env.volumetric_fog_length = 80.0

	world_env.environment = env
	add_child(world_env)

	# Soft subterranean fill light so tunnels and cavern vaults have natural depth definition
	var cave_fill = DirectionalLight3D.new()
	cave_fill.name = "SubterraneanAmbientFill"
	cave_fill.light_color = Color(0.38, 0.45, 0.56)
	cave_fill.light_energy = 0.30
	cave_fill.rotation_degrees = Vector3(-55, 30, 0)
	cave_fill.shadow_enabled = false
	add_child(cave_fill)

func _setup_cavern() -> void:
	# Infinite Chunk-based Voxel Cave Engine (100% unified procedural terrain)
	voxel_world = VoxelWorldClass.new()
	voxel_world.name = "VoxelWorld"
	voxel_world.add_to_group("voxel_world")
	add_child(voxel_world)

func _setup_player() -> void:
	player = PlayerControllerClass.new()
	player.name = "Player"
	# Spawn cleanly at Y = 11.2 centered on block (0.5, 11.2, 0.5) looking East down corridor
	player.position = Vector3(0.5, 11.2, 0.5)
	player.rotation_degrees = Vector3(0, -90.0, 0)
	add_child(player)

	if "voxel_world" in player:
		player.voxel_world = voxel_world

	if player and "building_system" in player and player.building_system:
		player.building_system.set_structures_container(structures_container)

func _setup_enemies() -> void:
	enemies_container = Node3D.new()
	enemies_container.name = "Enemies"
	add_child(enemies_container)

	# In Hollow Core, generic combat mobs are completely removed.
	# The ONLY entity is "The Watcher" — an elusive psychological horror apparition
	# that observes the player silently from distant fog ridges and dissolves when approached.
	var watcher1 = TheWatcherClass.new()
	watcher1.name = "TheWatcher_FogHorizon"
	watcher1.position = Vector3(36.0, 13.5, 18.0)
	enemies_container.add_child(watcher1)

func _setup_hud() -> void:
	hud = GameHUDClass.new()
	hud.name = "GameHUD"
	add_child(hud)
	hud.set_player(player)

func _setup_scenario() -> void:
	scenario_manager = ScenarioManagerClass.new()
	scenario_manager.name = "ScenarioManager"
	scenario_manager.add_to_group("scenario_manager")
	add_child(scenario_manager)
	scenario_manager.setup(player, hud, voxel_world)

func _setup_screenshot_helper() -> void:
	screenshot_helper = ScreenshotHelperClass.new()
	screenshot_helper.name = "ScreenshotHelper"
	screenshot_helper.player = player
	add_child(screenshot_helper)

func _process(delta: float) -> void:
	_process_mob_spawning(delta)
	_process_altitude_atmosphere(delta)

func _process_altitude_atmosphere(delta: float) -> void:
	if player == null or world_env == null or world_env.environment == null:
		return
	var env = world_env.environment
	var py = player.global_position.y
	# Transition from pitch subterranean cave (Y <= 25) to glacial arctic night sky (Y >= 45)
	var t_surface = clamp((py - 25.0) / 25.0, 0.0, 1.0)
	var cave_bg = Color(0.005, 0.007, 0.010, 1.0)
	var surface_fog_bg = Color(0.68, 0.76, 0.85, 1.0) # Iconic Minecraft Alpha pale misty fog!
	var cave_fog_col = Color(0.18, 0.22, 0.26, 1.0)
	env.background_color = cave_bg.lerp(surface_fog_bg, t_surface)
	env.fog_light_color = cave_fog_col.lerp(surface_fog_bg, t_surface)
	env.fog_density = lerp(0.038, 0.032, t_surface)
	env.ambient_light_energy = lerp(0.35, 0.75, t_surface)
	env.volumetric_fog_density = lerp(0.005, 0.018, t_surface)

	if sound_manager and sound_manager.has_method("update_altitude_atmosphere"):
		sound_manager.update_altitude_atmosphere(py)

func _process_mob_spawning(delta: float) -> void:
	if player == null or enemies_container == null or voxel_world == null:
		return

	mob_spawn_timer += delta
	if mob_spawn_timer < 25.0: # Rebalanced spawn interval (was 1.5s!)
		return
	mob_spawn_timer = 0.0

	var p_pos = player.global_position

	# Safe zone: Outpost Hub is safe!
	if p_pos.distance_to(Vector3(0.5, 11.2, 0.5)) < 28.0:
		return

	# Despawn distant dynamic mobs (> 55m)
	var dynamic_count = 0
	for enemy in enemies_container.get_children():
		if is_instance_valid(enemy):
			if enemy.name.begins_with("DynamicMob_"):
				if enemy.global_position.distance_to(p_pos) > 55.0:
					enemy.queue_free()
				else:
					dynamic_count += 1

	if dynamic_count >= 3: # Max 3 dynamic mobs (was 10!)
		return

	# Search for a valid spawn location at safe distance
	for attempt in range(8):
		var angle = randf() * 2.0 * PI
		var dist = randf_range(26.0, 42.0) # Safe spawn distance (was 14.0!)
		var check_x = int(round(p_pos.x + cos(angle) * dist))
		var check_z = int(round(p_pos.z + sin(angle) * dist))
		var base_y = int(round(p_pos.y))

		var cx = int(floor(float(check_x) / 16.0))
		var cz = int(floor(float(check_z) / 16.0))
		# Crucial: only spawn on chunks with active collision body so mobs never fall into void!
		if not voxel_world.chunk_nodes.has(Vector2i(cx, cz)):
			continue

		# Search vertically for floor
		for dy in range(-12, 13):
			var cy = base_y + dy
			if cy < -58 or cy > 60: continue
			var b_floor = voxel_world.get_block(check_x, cy, check_z)
			var b_air1 = voxel_world.get_block(check_x, cy + 1, check_z)
			var b_air2 = voxel_world.get_block(check_x, cy + 2, check_z)

			if b_floor != VoxelWorldClass.BlockType.AIR and b_floor != VoxelWorldClass.BlockType.BEDROCK and b_air1 == VoxelWorldClass.BlockType.AIR and b_air2 == VoxelWorldClass.BlockType.AIR:
				var spawn_pos = Vector3(check_x + 0.5, cy + 1.05, check_z + 0.5)
				var new_mob: CharacterBody3D

				# Hollow Core is purely psychological horror — no generic combat mobs exist!
				# Only a rare distant Watcher apparition observing from the fog horizon (max 1 instance)
				var existing_watchers = get_tree().get_nodes_in_group("horror_entities")
				if existing_watchers.is_empty() and randf() < 0.20:
					var watcher = TheWatcherClass.new()
					watcher.name = "Watcher_%d" % Time.get_ticks_msec()
					watcher.position = spawn_pos
					enemies_container.add_child(watcher)
				return
