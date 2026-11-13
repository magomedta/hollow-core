# scripts/audio/sound_memory_manager.gd
class_name SoundMemoryManager
extends Node

## Foundation of "The Lithic Resonance" (Acoustic Memory of Stone).
## Records player physical acoustic events (footsteps, pickaxe hits, machinery)
## in a bounded ring buffer, selects eligible past events, and replays them
## with delayed echo, rock damping filters, and harmonic infrasound pulses.

const AcousticEventClass = preload("res://scripts/audio/acoustic_event.gd")

signal lithic_echo_triggered(event: RefCounted, replay_pos: Vector3, delay: float)
signal infrasound_pulse_emitted(intensity: float, harmonic_freq: float)

const MAX_RING_BUFFER: int = 128
const EVENT_EXPIRY_SECONDS: float = 120.0 # Events older than 2 minutes fade from the rock

var ring_buffer: Array[RefCounted] = []
var sound_manager: Node = null

# Autonomous Echo Selection Timers
var echo_check_timer: float = 0.0
var next_echo_check_interval: float = 12.0
var player_ref: Node3D = null

# Infrasound 11.4 Hz periodic pulse timer
var infrasound_timer: float = 0.0
var next_infrasound_interval: float = 45.0

# Dynamic Biome Reverberation Parameters
var current_reverb_time: float = 2.4
var current_reverb_damping: float = 0.4

func set_reverb_parameters(p_time: float, p_damping: float) -> void:
	current_reverb_time = p_time
	current_reverb_damping = p_damping

func _ready() -> void:
	add_to_group("sound_memory_manager")
	next_echo_check_interval = randf_range(10.0, 20.0)
	next_infrasound_interval = randf_range(40.0, 70.0)

	# Locate SoundManager
	sound_manager = get_tree().get_first_node_in_group("sound_manager")

func set_player(p_player: Node3D) -> void:
	player_ref = p_player

func _process(delta: float) -> void:
	var now = float(Time.get_ticks_msec()) / 1000.0

	# 1. Prune expired events periodically
	if ring_buffer.size() > 0 and (now - ring_buffer[0].timestamp) > EVENT_EXPIRY_SECONDS:
		ring_buffer.pop_front()

	# 2. Check for eligible Lithic Echo playback
	echo_check_timer += delta
	if echo_check_timer >= next_echo_check_interval:
		echo_check_timer = 0.0
		next_echo_check_interval = randf_range(14.0, 28.0)
		_attempt_lithic_echo_replay()

	# 3. Check for 11.4 Hz Sub-bass Lore Pulse
	infrasound_timer += delta
	if infrasound_timer >= next_infrasound_interval:
		infrasound_timer = 0.0
		next_infrasound_interval = randf_range(45.0, 90.0)
		_trigger_infrasound_resonance()

## Records a player action into the Lithic Memory buffer
func record_event(
	event_type: String,
	world_pos: Vector3,
	sound_id: String,
	intensity: float = 1.0,
	biome_name: String = "",
	lore_freq: float = 11.4,
	is_persistent: bool = false
) -> RefCounted:
	var ev = AcousticEventClass.new(event_type, world_pos, sound_id, intensity, biome_name, lore_freq)
	ev.is_persistent = is_persistent

	if ring_buffer.size() >= MAX_RING_BUFFER:
		ring_buffer.pop_front()

	ring_buffer.push_back(ev)
	return ev

## Evaluates past acoustic traces and triggers a delayed spatial echo
func _attempt_lithic_echo_replay() -> void:
	if ring_buffer.size() < 4 or player_ref == null:
		return

	var player_pos = player_ref.global_position
	var now = float(Time.get_ticks_msec()) / 1000.0

	# Candidate events: happened within 25m, between 4 and 45 seconds ago, replayed < 2 times
	var candidates: Array[RefCounted] = []
	for ev in ring_buffer:
		var age = now - ev.timestamp
		if age >= 3.5 and age <= 45.0 and ev.replay_count < 2:
			var d = player_pos.distance_to(ev.world_position)
			if d <= 30.0:
				candidates.push_back(ev)

	if candidates.is_empty():
		return

	# Pick an eligible acoustic event (favoring pickaxe hits and footsteps)
	var chosen_event = candidates[randi() % candidates.size()]
	chosen_event.replay_count += 1

	# Determine acoustic replay position:
	# If it was a step, offset it 2.5m behind the player or at the original point
	var replay_pos = chosen_event.world_position
	if chosen_event.event_type == "step":
		# Position echo behind player
		var forward = -player_ref.global_transform.basis.z
		replay_pos = player_pos - forward * randf_range(2.0, 4.5) + Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
	elif chosen_event.event_type == "pickaxe_hit":
		# Position echo slightly inside rock face
		replay_pos = chosen_event.world_position + Vector3(randf_range(-0.8, 0.8), randf_range(-0.5, 0.5), randf_range(-0.8, 0.8))

	var age_seconds = now - chosen_event.timestamp
	lithic_echo_triggered.emit(chosen_event, replay_pos, age_seconds)

	# Play through SoundManager
	_play_echo_audio(chosen_event, replay_pos)

func _play_echo_audio(ev: RefCounted, replay_pos: Vector3) -> void:
	if sound_manager == null or not is_instance_valid(sound_manager):
		sound_manager = get_tree().get_first_node_in_group("sound_manager")
		if sound_manager == null:
			return

	# Replay sound with attenuated volume (-4dB to -8dB) and slight pitch shift (rock dissipation)
	var sfx_name = ev.sound_id
	if sfx_name == "":
		sfx_name = "pickaxe_stone" if ev.event_type == "pickaxe_hit" else "footstep_stone"

	var p_scale = randf_range(0.92, 1.04)
	var vol_db = -6.0 * (1.0 - ev.intensity + 0.5)

	if sound_manager.has_method("play_sfx"):
		sound_manager.play_sfx(sfx_name, replay_pos, p_scale, vol_db)

func _trigger_infrasound_resonance() -> void:
	var harmonic = 114.0 # 10th harmonic audible sub-bass
	infrasound_pulse_emitted.emit(1.0, harmonic)

	# Trigger camera vibration / sub-bass shudder if player exists
	if player_ref and player_ref.has_method("apply_subterranean_shudder"):
		player_ref.apply_subterranean_shudder(0.35, 1.2)
