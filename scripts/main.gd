extends Node3D

const VoxelWorldClass = preload("res://scripts/voxel_world.gd")
const PlayerControllerClass = preload("res://scripts/player_controller.gd")
const GameHUDClass = preload("res://scripts/hud.gd")
const ScreenshotHelperClass = preload("res://scripts/screenshot_helper.gd")
const ChasmStalkerClass = preload("res://scripts/chasm_stalker.gd")

var voxel_world: Node3D
var player: CharacterBody3D
var hud: CanvasLayer
var screenshot_helper: Node
var world_env: WorldEnvironment
var structures_container: Node3D
var enemies_container: Node3D

func _ready() -> void:
	print("[Hollow Core] Initializing Subterranean Sandbox Phase 2...")
	_setup_environment()
	_setup_cavern()
	_setup_structures_container()
	_setup_player()
	_setup_enemies()
	_setup_hud()
	_setup_screenshot_helper()
	print("[Hollow Core] Subterranean Chamber & Player Ready.")

func _setup_structures_container() -> void:
	structures_container = Node3D.new()
	structures_container.name = "PlacedStructures"
	add_child(structures_container)

func _setup_environment() -> void:
	world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"

	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.003, 0.004, 0.006, 1.0) # True subterranean pitch darkness

	# Subterranean cave illumination: Moody, dark, lantern and torches provide light!
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.10, 0.12, 0.16, 1.0)
	env.ambient_light_energy = 0.08 # Moody realistic cave darkness

	# Cinematic ACES tonemapper
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.15

	# Atmospheric Glow / Bioluminescence
	env.glow_enabled = true
	env.glow_intensity = 0.22
	env.glow_strength = 0.95
	env.glow_bloom = 0.04
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

	# Screen-space Ambient Occlusion
	env.ssao_enabled = true
	env.ssao_radius = 2.4
	env.ssao_intensity = 1.8

	# Real-time SDFGI
	env.sdfgi_enabled = true
	env.sdfgi_use_occlusion = true
	env.sdfgi_read_sky_light = false
	env.sdfgi_bounce_feedback = 0.65
	env.sdfgi_cascades = 4
	env.sdfgi_min_cell_size = 0.4
	env.sdfgi_energy = 1.5

	# Volumetric Fog catching lantern and torch rays
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.008
	env.volumetric_fog_albedo = Color(0.35, 0.44, 0.58, 1.0)
	env.volumetric_fog_emission = Color(0.01, 0.02, 0.03, 1.0)
	env.volumetric_fog_emission_energy = 0.20
	env.volumetric_fog_length = 90.0

	world_env.environment = env
	add_child(world_env)

func _setup_cavern() -> void:
	# Infinite Chunk-based Voxel Cave Engine (100% unified procedural terrain)
	voxel_world = VoxelWorldClass.new()
	voxel_world.name = "VoxelWorld"
	voxel_world.add_to_group("voxel_world")
	add_child(voxel_world)

func _setup_player() -> void:
	player = PlayerControllerClass.new()
	player.name = "Player"
	# Spawn securely on the staging deck floor (Y = 10, player at Y = 11.2) looking East down the main cavern shaft
	player.position = Vector3(0.0, 11.2, 0.0)
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

	# 1. Chasm Stalker prowling in the Eastern cavern corridor
	var stalker1 = ChasmStalkerClass.new()
	stalker1.name = "ChasmStalker_Corridor"
	stalker1.position = Vector3(20.0, 10.5, 0.0)
	stalker1.rotation_degrees = Vector3(0, -90.0, 0)
	enemies_container.add_child(stalker1)

	# 2. Chasm Stalker down in the Deepslate chasm
	var stalker2 = ChasmStalkerClass.new()
	stalker2.name = "ChasmStalker_Deep"
	stalker2.position = Vector3(14.0, -6.0, 12.0)
	enemies_container.add_child(stalker2)

func _setup_hud() -> void:
	hud = GameHUDClass.new()
	hud.name = "GameHUD"
	add_child(hud)
	hud.set_player(player)

func _setup_screenshot_helper() -> void:
	screenshot_helper = ScreenshotHelperClass.new()
	screenshot_helper.name = "ScreenshotHelper"
	screenshot_helper.player = player
	add_child(screenshot_helper)
