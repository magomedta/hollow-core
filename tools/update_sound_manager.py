# tools/update_sound_manager.py
import sys

content = """# scripts/sound_manager.gd
class_name SoundManager
extends Node

## Authentic Audio Engine for Hollow Core
## Exclusively uses real, authentic audio recordings (CC0 / Public Domain / CC-BY from Minetest, Kenney, and Wikimedia).
## No procedural beep-boop synthesis.

var _sound_bank: Dictionary = {}
var _pool_3d: Array[AudioStreamPlayer3D] = []
var _pool_2d: Array[AudioStreamPlayer] = []
var _pool_3d_index: int = 0
var _pool_2d_index: int = 0

var surface_wind_player: AudioStreamPlayer
var ambient_wind_player: AudioStreamPlayer
var horror_drone_player: AudioStreamPlayer
var heartbeat_player: AudioStreamPlayer
var heartbeat_active: bool = false

# Atmospheric Periodic Soundscape Timers
var cave_stinger_timer: float = 0.0
var next_cave_stinger_delay: float = 45.0

var phantom_footsteps_timer: float = 0.0
var next_phantom_footsteps_delay: float = 38.0

var distant_scream_timer: float = 0.0
var next_distant_scream_delay: float = 52.0

func _init() -> void:
	_load_authentic_sound_bank()
	_build_pools()

func _ready() -> void:
	add_to_group("sound_manager")
	_start_atmospheric_ambience()
	next_cave_stinger_delay = randf_range(35.0, 65.0)
	next_phantom_footsteps_delay = randf_range(30.0, 55.0)
	next_distant_scream_delay = randf_range(45.0, 75.0)

func _process(delta: float) -> void:
	# 1. Periodic mysterious subterranean cave stinger (like classic Minecraft Alpha cave sounds)
	cave_stinger_timer += delta
	if cave_stinger_timer >= next_cave_stinger_delay:
		cave_stinger_timer = 0.0
		next_cave_stinger_delay = randf_range(40.0, 80.0)
		_trigger_subterranean_cave_stinger()

	# 2. Periodic phantom footsteps echoing right behind the player in the dark tunnels
	phantom_footsteps_timer += delta
	if phantom_footsteps_timer >= next_phantom_footsteps_delay:
		phantom_footsteps_timer = 0.0
		next_phantom_footsteps_delay = randf_range(32.0, 60.0)
		_trigger_phantom_footsteps()

	# 3. Periodic distant horrifying screams/wails echoing across deep cavern voids
	distant_scream_timer += delta
	if distant_scream_timer >= next_distant_scream_delay:
		distant_scream_timer = 0.0
		next_distant_scream_delay = randf_range(45.0, 85.0)
		_trigger_distant_scream()

func _load_authentic_sound_bank() -> void:
	# Load authentic audio recordings from res://audio/
	var files = {
		"footstep_stone": [
			"res://audio/footstep_stone_1.ogg",
			"res://audio/footstep_stone_2.ogg",
			"res://audio/footstep_stone_3.ogg"
		],
		"footstep_gravel": [
			"res://audio/footstep_gravel_1.ogg",
			"res://audio/footstep_gravel_2.ogg",
			"res://audio/footstep_gravel_3.ogg"
		],
		"pickaxe_stone": [
			"res://audio/pickaxe_stone_1.ogg",
			"res://audio/pickaxe_stone_2.ogg",
			"res://audio/pickaxe_stone_3.ogg"
		],
		"block_break": [
			"res://audio/block_break_1.ogg",
			"res://audio/block_break_2.ogg"
		],
		"block_place": [
			"res://audio/block_place.ogg"
		],
		"item_pickup": [
			"res://audio/item_pickup.ogg"
		],
		"jump": [
			"res://audio/jump.ogg"
		],
		"land": [
			"res://audio/land.ogg"
		],
		"player_hurt": [
			"res://audio/player_hurt.ogg"
		],
		"explosion": [
			"res://audio/explosion.ogg"
		],
		"lantern_click": [
			"res://audio/lantern_click.ogg"
		],
		"monster_growl": [
			"res://audio/monster_growl_1.ogg",
			"res://audio/monster_growl_2.ogg"
		],
		"cavern_wind": [
			"res://audio/cavern_wind.ogg"
		],
		"horror_drone": [
			"res://audio/horror_drone.ogg",
			"res://audio/creepy_ambience_drone.ogg"
		],
		"howling_wind": [
			"res://audio/howling_wind_blizzard.ogg"
		],
		"heartbeat": [
			"res://audio/heartbeat.ogg"
		],
		"distant_scream": [
			"res://audio/distant_scream_1.ogg",
			"res://audio/distant_scream_2.ogg",
			"res://audio/distant_scream_3.ogg"
		],
		"phantom_footsteps": [
			"res://audio/phantom_footsteps_creepy.ogg"
		],
		"horror_swell": [
			"res://audio/horror_swell.ogg"
		]
	}

	for sfx_key in files:
		var loaded_streams: Array[AudioStream] = []
		for path in files[sfx_key]:
			if FileAccess.file_exists(path):
				var stream = AudioStreamOggVorbis.load_from_file(path)
				if stream is AudioStream:
					loaded_streams.append(stream)
		if loaded_streams.size() > 0:
			_sound_bank[sfx_key] = loaded_streams

	print("[SoundManager] Loaded %d authentic audio categories." % _sound_bank.size())

func _build_pools() -> void:
	# 3D spatial sound players
	for i in range(16):
		var p3 = AudioStreamPlayer3D.new()
		p3.name = "AudioPool3D_%d" % i
		p3.max_distance = 42.0
		p3.unit_size = 6.0
		p3.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p3.bus = "Master"
		add_child(p3)
		_pool_3d.append(p3)

	# 2D non-spatial players (UI, player footsteps, inventory)
	for i in range(8):
		var p2 = AudioStreamPlayer.new()
		p2.name = "AudioPool2D_%d" % i
		p2.bus = "Master"
		add_child(p2)
		_pool_2d.append(p2)

	# Surface howling/whistling blizzard wind player (scales dynamically with altitude)
	surface_wind_player = AudioStreamPlayer.new()
	surface_wind_player.name = "SurfaceHowlingWind"
	surface_wind_player.volume_db = -55.0
	surface_wind_player.pitch_scale = 0.85
	surface_wind_player.bus = "Master"
	add_child(surface_wind_player)

	# Ambient cavern wind player (Eerie low cavern air circulation)
	ambient_wind_player = AudioStreamPlayer.new()
	ambient_wind_player.name = "AmbientCavernWind"
	ambient_wind_player.volume_db = -12.0
	ambient_wind_player.bus = "Master"
	add_child(ambient_wind_player)

	# Ambient horror drone player (Low subterranean dread drone)
	horror_drone_player = AudioStreamPlayer.new()
	horror_drone_player.name = "HorrorDronePlayer"
	horror_drone_player.volume_db = -16.0
	horror_drone_player.bus = "Master"
	add_child(horror_drone_player)

	# Heartbeat player
	heartbeat_player = AudioStreamPlayer.new()
	heartbeat_player.name = "HeartbeatPlayer"
	heartbeat_player.volume_db = -6.0
	heartbeat_player.bus = "Master"
	add_child(heartbeat_player)

func _start_atmospheric_ambience() -> void:
	if not is_inside_tree():
		return

	if _sound_bank.has("howling_wind") and _sound_bank["howling_wind"].size() > 0:
		var stream = _sound_bank["howling_wind"][0]
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		surface_wind_player.stream = stream
		surface_wind_player.play()

	if _sound_bank.has("cavern_wind") and _sound_bank["cavern_wind"].size() > 0:
		var stream = _sound_bank["cavern_wind"][0]
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		ambient_wind_player.stream = stream
		ambient_wind_player.play()

	if _sound_bank.has("horror_drone") and _sound_bank["horror_drone"].size() > 0:
		var stream = _sound_bank["horror_drone"][0]
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		horror_drone_player.stream = stream
		horror_drone_player.play()

## Dynamic altitude audio scaling:
## User requirement: "звук свиста должен увеличиваться при приблежении к верху"
## At Y <= 12 (deep caverns): Whistling wind is inaudible (-55dB), horror drone is prominent (-12dB).
## At Y >= 48 (mountain surface): Whistling wind is loud (+2dB) with high whistling pitch (1.22x), horror drone fades out (-38dB).
func update_altitude_atmosphere(player_y: float) -> void:
	var t = clamp((player_y - 12.0) / 36.0, 0.0, 1.0)
	if surface_wind_player:
		surface_wind_player.volume_db = lerp(-55.0, 2.0, t)
		surface_wind_player.pitch_scale = lerp(0.85, 1.22, t)

	if horror_drone_player:
		horror_drone_player.volume_db = lerp(-12.0, -38.0, t)

	if ambient_wind_player:
		ambient_wind_player.volume_db = lerp(-14.0, -26.0, t)

func _trigger_subterranean_cave_stinger() -> void:
	# Plays a terrifying spatial stinger in a random direction (echoing through cavern walls)
	var players = get_tree().get_nodes_in_group("player")
	var p_pos = players[0].global_position if players.size() > 0 else Vector3.ZERO
	var angle = randf() * TAU
	var dist = randf_range(18.0, 32.0)
	var pos = p_pos + Vector3(cos(angle) * dist, randf_range(-4.0, 8.0), sin(angle) * dist)
	
	if randf() > 0.5 and _sound_bank.has("monster_growl"):
		play_sfx("monster_growl", pos, 0.85, 2.0)
	else:
		play_sfx("explosion", pos, 0.55, -4.0)

func _trigger_phantom_footsteps() -> void:
	# Plays phantom footsteps 2.5m behind the player in deep tunnels
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var player = players[0]
	if player.global_position.y > 36.0:
		return # Only in eerie underground caverns

	var cam = player.get_node_or_null("Neck/Camera3D")
	var forward = -cam.global_transform.basis.z if cam else -player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	# Position slightly behind player
	var footstep_pos = player.global_position - forward * randf_range(2.0, 4.0)
	play_sfx("phantom_footsteps", footstep_pos, randf_range(0.95, 1.05), -2.0)

func _trigger_distant_scream() -> void:
	# Plays chilling distant human/creature wails echoing across rock shafts
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var player = players[0]
	var angle = randf() * TAU
	var dist = randf_range(28.0, 45.0)
	var scream_pos = player.global_position + Vector3(cos(angle) * dist, randf_range(4.0, 14.0), sin(angle) * dist)
	play_sfx("distant_scream", scream_pos, randf_range(0.9, 1.1), 1.5)

func play_sfx(sfx_name: String, world_pos: Vector3 = Vector3.ZERO, pitch_scale: float = 1.0, volume_offset_db: float = 0.0) -> void:
	if not is_inside_tree():
		return
	# Map legacy keys if called
	var key = sfx_name
	if key == "pickaxe_hit" or key == "pickaxe_ore":
		key = "pickaxe_stone"
	elif key == "ui_click":
		key = "lantern_click"
	elif key == "horror_sting" or key == "monster_bite" or key == "acid_spit":
		key = "monster_growl"

	if not _sound_bank.has(key) or _sound_bank[key].size() == 0:
		return

	var stream_list = _sound_bank[key]
	var stream = stream_list[randi() % stream_list.size()]
	var safe_pitch = max(0.1, pitch_scale)
	var randomized_pitch = safe_pitch * randf_range(0.93, 1.07)

	if world_pos != Vector3.ZERO:
		# Use 3D player pool
		var player_node = _pool_3d[_pool_3d_index]
		_pool_3d_index = (_pool_3d_index + 1) % _pool_3d.size()
		player_node.global_position = world_pos
		player_node.stream = stream
		player_node.pitch_scale = randomized_pitch
		player_node.volume_db = volume_offset_db
		player_node.play()
	else:
		# Use 2D non-spatial pool
		var player_node = _pool_2d[_pool_2d_index]
		_pool_2d_index = (_pool_2d_index + 1) % _pool_2d.size()
		player_node.stream = stream
		player_node.pitch_scale = randomized_pitch
		player_node.volume_db = volume_offset_db
		player_node.play()

# Convenience API helpers
func play_footstep(surface_type: String = "stone", world_pos: Vector3 = Vector3.ZERO) -> void:
	var key = "footstep_stone"
	if surface_type == "gravel" or surface_type == "dirt":
		key = "footstep_gravel"
	play_sfx(key, world_pos, 1.0, -4.0)

func play_pickaxe_hit(is_ore: bool = false, world_pos: Vector3 = Vector3.ZERO) -> void:
	var pitch = 1.15 if is_ore else 1.0
	play_sfx("pickaxe_stone", world_pos, pitch, 0.0)

func play_block_break(world_pos: Vector3 = Vector3.ZERO) -> void:
	play_sfx("block_break", world_pos, 1.0, 2.0)

func play_block_place(world_pos: Vector3 = Vector3.ZERO) -> void:
	play_sfx("block_place", world_pos, 1.0, 1.0)

func play_item_pickup() -> void:
	play_sfx("item_pickup", Vector3.ZERO, 1.0, 0.0)

func play_jump() -> void:
	play_sfx("jump", Vector3.ZERO, 1.0, -2.0)

func play_land(world_pos: Vector3 = Vector3.ZERO) -> void:
	play_sfx("land", world_pos, 1.0, 0.0)

func play_player_hurt() -> void:
	play_sfx("player_hurt", Vector3.ZERO, 1.0, 3.0)

func play_horror_swell() -> void:
	play_sfx("horror_swell", Vector3.ZERO, 1.0, 2.0)

func play_lantern_click() -> void:
	play_sfx("lantern_click", Vector3.ZERO, 1.2, -6.0)

func set_heartbeat(active: bool) -> void:
	if active == heartbeat_active or not is_inside_tree():
		return
	heartbeat_active = active
	if active:
		if _sound_bank.has("heartbeat") and _sound_bank["heartbeat"].size() > 0:
			var stream = _sound_bank["heartbeat"][0]
			if stream is AudioStreamOggVorbis:
				stream.loop = true
			heartbeat_player.stream = stream
			heartbeat_player.play()
	else:
		heartbeat_player.stop()
"""

with open("c:/Users/magom/Downloads/twitchst/hollow_core/scripts/sound_manager.gd", "w", encoding="utf-8") as f:
    f.write(content)

print("Updated sound_manager.gd successfully!")
