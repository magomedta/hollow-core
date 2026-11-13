# scripts/horror/sanity_manager.gd
class_name SanityManager
extends Node

## Manages psychological tension (Dread Meter) for Hollow Core.
## Operates under strict Anti-AI-UI / diegetic principles:
## NO on-screen insanity meter or HUD bars!
## Tension is a hidden mathematical index (0.0 to 1.0) driving subtle
## psychological anomalies, acoustic hallucinations, and environmental horror.

signal tension_changed(new_tension: float)
signal high_tension_reached()

@export var tension: float = 0.0:
	set(val):
		tension = clampf(val, 0.0, 1.0)
		tension_changed.emit(tension)
		if tension >= 0.70 and not _high_tension_emitted:
			_high_tension_emitted = true
			high_tension_reached.emit()
		elif tension < 0.50:
			_high_tension_emitted = false

var player_ref: CharacterBody3D = null
var _high_tension_emitted: bool = false
var _run_time: float = 0.0

func _ready() -> void:
	add_to_group("sanity_manager")

func set_player(p_player: CharacterBody3D) -> void:
	player_ref = p_player
	if player_ref and player_ref.has_signal("acoustic_noise_emitted"):
		if not player_ref.acoustic_noise_emitted.is_connected(_on_player_acoustic_noise):
			player_ref.acoustic_noise_emitted.connect(_on_player_acoustic_noise)

func _process(delta: float) -> void:
	if player_ref == null:
		return

	var depth_mult = _calculate_depth_multiplier(player_ref.global_position.y)

	# 1. Darkness accumulation (+0.015 / sec in total darkness)
	var is_lit = false
	if player_ref.lantern and "is_lit" in player_ref.lantern:
		is_lit = player_ref.lantern.is_lit

	if not is_lit:
		tension += 0.015 * depth_mult * delta
	else:
		# Slow relaxation near warm lantern light (-0.01 / sec)
		tension -= 0.010 * delta

	# 2. Refuge check
	var ad = get_tree().get_first_node_in_group("anomaly_director")
	if ad and ad.has_method("is_player_in_safe_zone") and ad.is_player_in_safe_zone():
		tension -= 0.025 * delta

	# 3. Sudden stop detection (+0.10 tension spike after prolonged run)
	var speed = Vector2(player_ref.velocity.x, player_ref.velocity.z).length()
	if speed > 2.0 and player_ref.is_on_floor():
		_run_time += delta
	else:
		if _run_time >= 4.0:
			tension += 0.08
		_run_time = 0.0

func _calculate_depth_multiplier(y_pos: float) -> float:
	if y_pos > 35.0:
		return 1.0
	elif y_pos > 15.0:
		return 1.4
	elif y_pos > -10.0:
		return 1.8
	else:
		return 2.5 # Bedrock silence zone

func _on_player_acoustic_noise(_origin: Vector3, _radius: float, noise_type: String) -> void:
	# Monotonous mining increases acoustic tension (+0.008 per strike)
	if noise_type == "pickaxe_hit" or noise_type == "hit":
		tension += 0.008

## Drink from canteen / sedative relief (-0.35 instantly)
func relieve_tension_canteen() -> void:
	tension = maxf(0.0, tension - 0.35)
