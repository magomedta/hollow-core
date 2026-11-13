# scripts/audio/audio_story_synthesizer.gd
class_name AudioStorySynthesizer
extends RefCounted

## Procedural Sound Synthesizer for Hollow Core Minecraft Disc 11-style Audiologs.
## Synthesizes authentic low-frequency sub-bass carriers (11.4 Hz, 7.0 Hz, 14.0 Hz),
## tape motor flutter, analog noise, pickaxe strike echoes, Morse code telemetry,
## and atmospheric acoustic decays without requiring gigabytes of recorded audio files.

const SAMPLE_RATE: int = 22050
const AudiologRegistryClass = preload("res://scripts/narrative/audiolog_registry.gd")

static var _stream_cache: Dictionary = {}

static func get_audiolog_stream(audio_id: String) -> AudioStreamWAV:
	if _stream_cache.has(audio_id):
		return _stream_cache[audio_id]

	var log_data = AudiologRegistryClass.get_audiolog(audio_id)
	var duration = float(log_data.get("duration", 8.0))
	# Clamp generated preview duration to 6.0 seconds for instant memory-efficient generation
	var gen_duration = clampf(duration, 3.0, 6.0)
	var stream = synthesize_audiolog(audio_id, gen_duration)
	_stream_cache[audio_id] = stream
	return stream

static func synthesize_audiolog(audio_id: String, duration_sec: float = 4.0) -> AudioStreamWAV:
	var total_samples: int = int(SAMPLE_RATE * duration_sec)
	var byte_array = PackedByteArray()
	byte_array.resize(total_samples * 2) # 16-bit mono = 2 bytes per sample

	var log_data = AudiologRegistryClass.get_audiolog(audio_id)
	var recipe: Dictionary = log_data.get("sound_recipe", {})
	var r_type: String = recipe.get("type", "generic_noise")
	var carrier_freq: float = float(recipe.get("carrier", 0.0))

	# Phase accumulators
	var phase_carrier: float = 0.0
	var phase_tone: float = 0.0
	var phase_harmonic: float = 0.0
	var lfo_phase: float = 0.0

	var last_noise: float = 0.0

	for i in range(total_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var sample: float = 0.0

		# 1. Analog tape hiss & wow-flutter (Minecraft Disc 11 texture)
		var raw_noise = (randf() * 2.0 - 1.0)
		# Simple 1-pole lowpass filter for warm vintage tape noise
		last_noise = lerpf(last_noise, raw_noise, 0.15)
		var tape_flutter = 1.0 + 0.04 * sin(t * 3.5)
		var tape_hiss = last_noise * 0.07 * tape_flutter
		sample += tape_hiss

		# 2. Infrasound carrier (11.4 Hz / 7.0 Hz / 14.0 Hz audible harmonic representation)
		if carrier_freq > 0.0:
			# Represent deep infrasound with fundamental plus warm audible 2nd/3rd harmonics
			phase_carrier += (carrier_freq * TAU) / float(SAMPLE_RATE)
			phase_harmonic += ((carrier_freq * 3.0) * TAU) / float(SAMPLE_RATE)
			var sub_pulse = sin(phase_carrier) * 0.35 + sin(phase_harmonic) * 0.18
			# Throbbing LFO modulation
			lfo_phase += (0.8 * TAU) / float(SAMPLE_RATE)
			sample += sub_pulse * (0.7 + 0.3 * sin(lfo_phase))

		# 3. Recipe-specific acoustic events
		match r_type:
			"strikes_with_delayed_echo": # AUD-01 (3 pickaxe strikes + delayed echo)
				var strike_times = [0.4, 1.2, 2.0, 3.8] # 4th strike is delayed!
				for st in strike_times:
					var dt = t - st
					if dt >= 0.0 and dt < 0.45:
						var env = exp(-dt * 14.0)
						var strike_tone = sin(dt * 180.0 * TAU) * 0.45 + (randf() * 2.0 - 1.0) * 0.25
						sample += strike_tone * env

			"harmonic_shatter": # AUD-02 (7.0 Hz harmonic surge & rupture)
				if t > 1.5:
					var surge = clampf((t - 1.5) / 2.0, 0.0, 1.0)
					sample += sin(t * 7.0 * TAU * 12.0) * 0.40 * surge
					if t > 3.2:
						# Shatter burst
						sample += (randf() * 2.0 - 1.0) * 0.65 * exp(-(t - 3.2) * 8.0)

			"morse_and_edward_intercept": # AUD-07 (Cape Silent 1989 Morse & Edward radio intercept)
				# Intermittent Morse code 750 Hz beeps
				var morse_active = (fmod(t, 0.35) < 0.12) and (t < 2.5)
				if morse_active:
					phase_tone += (750.0 * TAU) / float(SAMPLE_RATE)
					sample += sin(phase_tone) * 0.22
				# Low radio voice whisper simulation (filtered bandpass noise)
				if t >= 2.0:
					var voice_env = clampf(sin((t - 2.0) * 2.0), 0.0, 0.6)
					sample += sin(t * 195.0 * TAU) * 0.25 * voice_env

			"eleonora_georadar": # AUD-08 (Carlsbad georadar chirps)
				var ping_period = fmod(t, 0.7)
				if ping_period < 0.08:
					var chirp_freq = 1200.0 - ping_period * 8000.0
					sample += sin(t * chirp_freq * TAU) * 0.30

			"time_loop_carrier": # AUD-20 (Pure 11.4 Hz Anchor Carrier & 3 strikes)
				phase_carrier += (11.4 * TAU) / float(SAMPLE_RATE)
				sample += sin(phase_carrier) * 0.45
				var strikes = [0.8, 1.8, 2.8]
				for st in strikes:
					var dt = t - st
					if dt >= 0.0 and dt < 0.35:
						sample += sin(dt * 114.0 * TAU) * exp(-dt * 10.0) * 0.50

			_: # Generic atmospheric cave presence
				sample += sin(t * 55.0 * TAU) * 0.15

		# Clamp audio amplitude
		sample = clampf(sample * 0.85, -0.98, 0.98)
		var val_16: int = int(sample * 32767.0)

		# Store 16-bit signed PCM (Little-endian)
		var b0 = val_16 & 0xFF
		var b1 = (val_16 >> 8) & 0xFF
		byte_array.encode_u8(i * 2, b0)
		byte_array.encode_u8(i * 2 + 1, b1)

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = byte_array
	return wav
