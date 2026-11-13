# scripts/audio/acoustic_event.gd
class_name AcousticEvent
extends RefCounted

## Represents a discrete acoustic imprint in the Lithic Memory buffer.
## Tracks exact physical location, timestamp, frequency metadata and biome context.

var id: String = ""
var world_position: Vector3 = Vector3.ZERO
var event_type: String = "step" # "step", "pickaxe_hit", "machine", "infrasound_pulse"
var sound_id: String = ""
var timestamp: float = 0.0 # Time since engine startup in seconds
var intensity: float = 1.0 # 0.0 to 1.0
var lore_frequency_hz: float = 11.4 # Canonical lore carrier resonance
var audible_harmonic_hz: float = 114.0 # Audible 10th harmonic for subwoofers/headphones
var biome_name: String = "Basalt Abyssal Basin"
var is_persistent: bool = false
var replay_count: int = 0

func _init(
	p_type: String = "step",
	p_pos: Vector3 = Vector3.ZERO,
	p_sound: String = "",
	p_intensity: float = 1.0,
	p_biome: String = "",
	p_lore_freq: float = 11.4
) -> void:
	id = "echo_" + str(Time.get_ticks_msec()) + "_" + str(randi() % 1000)
	event_type = p_type
	world_position = p_pos
	sound_id = p_sound
	intensity = p_intensity
	biome_name = p_biome
	lore_frequency_hz = p_lore_freq
	audible_harmonic_hz = lore_frequency_hz * 10.0 # 114 Hz audible sub-bass
	timestamp = float(Time.get_ticks_msec()) / 1000.0
