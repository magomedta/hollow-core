# scripts/horror/anomaly_director.gd
class_name AnomalyDirector
extends Node

## Manages psychological horror pacing and micro-anomalies (EV-01, EV-02).
## Operates under strict "Silent Director" principles:
## - No on-screen horror meters or HUD alerts.
## - Long contextual cooldowns (3-5 minutes) to prevent desensitization.
## - Respects safety pockets (warm lighted refuges).

signal anomaly_triggered(anomaly_id: String, world_pos: Vector3)

const EV01_MIN_COOLDOWN: float = 180.0
const EV02_MIN_COOLDOWN: float = 220.0

var player_ref: CharacterBody3D = null
var sound_manager: Node = null

# EV-01 State: Delayed footsteps
var ev01_cooldown_timer: float = 45.0 # Initial grace period
var player_moving_duration: float = 0.0
var ev01_pending: bool = false
var ev01_delay_timer: float = 0.0
var ev01_stop_pos: Vector3 = Vector3.ZERO
var ev01_stop_forward: Vector3 = Vector3.FORWARD

# EV-02 State: Fourth strike
var ev02_cooldown_timer: float = 60.0 # Initial grace period
var recent_pickaxe_strikes: Array[float] = [] # timestamps
var ev02_pending: bool = false
var ev02_delay_timer: float = 0.0
var ev02_last_strike_pos: Vector3 = Vector3.ZERO

# Safe Zones (No anomalies trigger inside refuge areas)
var safe_zones: Array[AABB] = []

func _ready() -> void:
	add_to_group("anomaly_director")
	sound_manager = get_tree().get_first_node_in_group("sound_manager")

func set_player(p_player: CharacterBody3D) -> void:
	player_ref = p_player
	if player_ref and not player_ref.acoustic_noise_emitted.is_connected(_on_player_acoustic_noise):
		player_ref.acoustic_noise_emitted.connect(_on_player_acoustic_noise)

func add_safe_zone(zone_bounds: AABB) -> void:
	safe_zones.append(zone_bounds)

func is_player_in_safe_zone() -> bool:
	if player_ref == null:
		return false
	var pos = player_ref.global_position
	for box in safe_zones:
		if box.has_point(pos):
			return true
	return false

func _process(delta: float) -> void:
	# Decrement cooldowns
	if ev01_cooldown_timer > 0.0:
		ev01_cooldown_timer -= delta
	if ev02_cooldown_timer > 0.0:
		ev02_cooldown_timer -= delta

	_process_ev01_delayed_steps(delta)
	_process_ev02_fourth_strike(delta)

func _process_ev01_delayed_steps(delta: float) -> void:
	if player_ref == null:
		return

	var speed = Vector2(player_ref.velocity.x, player_ref.velocity.z).length()
	var on_floor = player_ref.is_on_floor()

	if on_floor and speed > 1.5:
		player_moving_duration += delta
	else:
		# Just stopped moving!
		if player_moving_duration >= 3.2 and ev01_cooldown_timer <= 0.0 and not is_player_in_safe_zone() and not ev01_pending:
			# Queue EV-01!
			ev01_pending = true
			ev01_delay_timer = 0.38 # 380 ms delay after coming to a full stop
			ev01_stop_pos = player_ref.global_position
			ev01_stop_forward = -player_ref.global_transform.basis.z

		player_moving_duration = 0.0

	# Process pending EV-01 execution
	if ev01_pending:
		ev01_delay_timer -= delta
		if ev01_delay_timer <= 0.0:
			ev01_pending = false
			ev01_cooldown_timer = EV01_MIN_COOLDOWN + randf_range(0.0, 60.0)
			_execute_ev01_sound()

func _execute_ev01_sound() -> void:
	# 2 heavy footsteps on slate located 2.4 meters directly behind the player
	var step_pos = ev01_stop_pos - ev01_stop_forward * 2.4 + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))

	if sound_manager and sound_manager.has_method("play_sfx"):
		# First step
		sound_manager.play_sfx("footstep_stone", step_pos, 0.92, -2.0)

		# Second step after 0.28 seconds
		var t = get_tree().create_timer(0.28)
		t.timeout.connect(func():
			var second_pos = step_pos + ev01_stop_forward * 0.7
			sound_manager.play_sfx("footstep_stone", second_pos, 0.88, -2.5)
		)

	anomaly_triggered.emit("EV-01", step_pos)

func _on_player_acoustic_noise(origin: Vector3, _radius: float, noise_type: String) -> void:
	if noise_type != "pickaxe_hit" and noise_type != "hit":
		return

	var now = float(Time.get_ticks_msec()) / 1000.0

	# Prune strikes older than 2.8 seconds
	while recent_pickaxe_strikes.size() > 0 and (now - recent_pickaxe_strikes[0]) > 2.8:
		recent_pickaxe_strikes.pop_front()

	recent_pickaxe_strikes.append(now)
	ev02_last_strike_pos = origin

	# If player struck 3 times consecutively and cooldown is ready
	if recent_pickaxe_strikes.size() == 3 and ev02_cooldown_timer <= 0.0 and not is_player_in_safe_zone() and not ev02_pending:
		ev02_pending = true
		ev02_delay_timer = 1.80 # Canonical 1.8 seconds delay

func _process_ev02_fourth_strike(delta: float) -> void:
	if not ev02_pending:
		return

	ev02_delay_timer -= delta
	if ev02_delay_timer <= 0.0:
		ev02_pending = false
		ev02_cooldown_timer = EV02_MIN_COOLDOWN + randf_range(0.0, 90.0)
		recent_pickaxe_strikes.clear()
		_execute_ev02_sound()

func _execute_ev02_sound() -> void:
	# Sharp, resonant 4th strike emerging from within the solid monolith 1.2m ahead
	var strike_pos = ev02_last_strike_pos + Vector3(randf_range(-0.4, 0.4), randf_range(-0.2, 0.2), randf_range(-0.4, 0.4))

	if sound_manager and sound_manager.has_method("play_sfx"):
		# Slightly deeper pitch and metallic ringing resonance
		sound_manager.play_sfx("pickaxe_stone", strike_pos, 0.82, 1.5)

	# Subtle shudder on player if within 8 meters
	if player_ref and player_ref.has_method("apply_subterranean_shudder"):
		var d = player_ref.global_position.distance_to(strike_pos)
		if d < 8.0:
			player_ref.apply_subterranean_shudder(0.20, 0.8)

	anomaly_triggered.emit("EV-02", strike_pos)
