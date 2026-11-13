"""
Generates clean, production-grade GDScript AI controllers for all 6 new mobs.
"""
import os
import sys

SCRIPTS_DIR = "hollow_core/scripts"

MOB_TEMPLATES = {
    "magma_basilisk": """extends CharacterBody3D

signal basilisk_died(pos: Vector3)

@export var max_health: float = 120.0
@export var current_health: float = 120.0
@export var move_speed: float = 4.8
@export var attack_damage: float = 32.0
@export var attack_range: float = 2.4

var player_ref: CharacterBody3D
var model_root: Node3D
var attack_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	_setup_collision()
	_load_model()
	_find_player()

func _setup_collision() -> void:
	collision_layer = 4
	collision_mask = 1
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.2, 0.7, 2.0)
	col.shape = box
	col.position = Vector3(0, 0.35, 0)
	add_child(col)

func _load_model() -> void:
	model_root = Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)
	var glb = load("res://models/magma_basilisk.glb")
	if glb:
		var inst = glb.instantiate()
		model_root.add_child(inst)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if player_ref:
		var to_player = player_ref.global_position - global_position
		to_player.y = 0.0
		var dist = to_player.length()
		if dist < 18.0 and dist > attack_range:
			var dir = to_player.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
			rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), delta * 5.0)
		elif dist <= attack_range and attack_cooldown <= 0.0:
			velocity.x = 0.0
			velocity.z = 0.0
			_attack_player()
		else:
			velocity.x = move_toward(velocity.x, 0.0, delta * 5.0)
			velocity.z = move_toward(velocity.z, 0.0, delta * 5.0)
	move_and_slide()

func _attack_player() -> void:
	attack_cooldown = 1.8
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(attack_damage)

func take_damage(amount: float, hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> void:
	current_health -= amount
	velocity += hit_normal * 3.5
	if current_health <= 0.0:
		basilisk_died.emit(global_position)
		queue_free()
""",

    "fungal_strider": """extends CharacterBody3D

signal strider_died(pos: Vector3)

@export var max_health: float = 75.0
@export var current_health: float = 75.0
@export var walk_speed: float = 2.0

var player_ref: CharacterBody3D
var model_root: Node3D
var is_alarmed: bool = false
var wander_timer: float = 0.0
var wander_dir: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group("enemies")
	_setup_collision()
	_load_model()

func _setup_collision() -> void:
	collision_layer = 4
	collision_mask = 1
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.8
	cap.height = 2.4
	col.shape = cap
	col.position = Vector3(0, 1.2, 0)
	add_child(col)

func _load_model() -> void:
	model_root = Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)
	var glb = load("res://models/fungal_strider.glb")
	if glb:
		var inst = glb.instantiate()
		model_root.add_child(inst)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 19.6 * delta

	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_timer = randf_range(3.0, 8.0)
		var angle = randf() * TAU
		wander_dir = Vector3(cos(angle), 0, sin(angle)).normalized()

	velocity.x = wander_dir.x * (walk_speed * 1.8 if is_alarmed else walk_speed)
	velocity.z = wander_dir.z * (walk_speed * 1.8 if is_alarmed else walk_speed)
	if wander_dir.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-wander_dir.x, -wander_dir.z), delta * 3.0)
	move_and_slide()

func take_damage(amount: float, hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> void:
	current_health -= amount
	is_alarmed = true
	velocity += hit_normal * 4.0
	if current_health <= 0.0:
		strider_died.emit(global_position)
		queue_free()
""",

    "geode_golem": """extends CharacterBody3D

signal golem_died(pos: Vector3)

@export var max_health: float = 250.0
@export var current_health: float = 250.0
@export var move_speed: float = 1.8
@export var attack_damage: float = 45.0
@export var slam_radius: float = 5.0

var player_ref: CharacterBody3D
var model_root: Node3D
var slam_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	_setup_collision()
	_load_model()
	_find_player()

func _setup_collision() -> void:
	collision_layer = 4
	collision_mask = 1
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.6, 2.5, 1.4)
	col.shape = box
	col.position = Vector3(0, 1.25, 0)
	add_child(col)

func _load_model() -> void:
	model_root = Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)
	var glb = load("res://models/geode_golem.glb")
	if glb:
		var inst = glb.instantiate()
		model_root.add_child(inst)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	if slam_cooldown > 0.0:
		slam_cooldown -= delta

	if player_ref:
		var to_player = player_ref.global_position - global_position
		to_player.y = 0.0
		var dist = to_player.length()
		if dist < 22.0 and dist > 3.0:
			var dir = to_player.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
			rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), delta * 3.0)
		elif dist <= 3.2 and slam_cooldown <= 0.0:
			velocity.x = 0.0
			velocity.z = 0.0
			_ground_slam()
		else:
			velocity.x = move_toward(velocity.x, 0.0, delta * 4.0)
			velocity.z = move_toward(velocity.z, 0.0, delta * 4.0)
	move_and_slide()

func _ground_slam() -> void:
	slam_cooldown = 3.0
	if player_ref and global_position.distance_to(player_ref.global_position) <= slam_radius:
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(attack_damage)

func take_damage(amount: float, hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> void:
	# Heavy stone armor reduces damage by 30%
	current_health -= amount * 0.70
	if current_health <= 0.0:
		golem_died.emit(global_position)
		queue_free()
""",

    "abyssal_glider": """extends CharacterBody3D

signal glider_died(pos: Vector3)

@export var max_health: float = 45.0
@export var current_health: float = 45.0
@export var fly_speed: float = 7.5
@export var attack_damage: float = 18.0

var player_ref: CharacterBody3D
var model_root: Node3D
var is_swooping: bool = false
var roost_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group("enemies")
	roost_pos = global_position
	_setup_collision()
	_load_model()
	_find_player()

func _setup_collision() -> void:
	collision_layer = 4
	collision_mask = 1
	var col = CollisionShape3D.new()
	var sph = SphereShape3D.new()
	sph.radius = 0.7
	col.shape = sph
	col.position = Vector3(0, 0.5, 0)
	add_child(col)

func _load_model() -> void:
	model_root = Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)
	var glb = load("res://models/abyssal_glider.glb")
	if glb:
		var inst = glb.instantiate()
		model_root.add_child(inst)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func _physics_process(delta: float) -> void:
	if player_ref:
		var dist = global_position.distance_to(player_ref.global_position)
		if dist < 16.0:
			var target_pos = player_ref.global_position + Vector3(0, 1.2, 0)
			var to_target = (target_pos - global_position).normalized()
			velocity = to_target * fly_speed
			rotation.y = lerp_angle(rotation.y, atan2(-to_target.x, -to_target.z), delta * 6.0)
			if dist < 1.8:
				if player_ref.has_method("take_damage"):
					player_ref.take_damage(attack_damage)
				velocity = Vector3.UP * 5.0
		else:
			velocity = velocity.move_toward(Vector3.ZERO, delta * 4.0)
	move_and_slide()

func take_damage(amount: float, hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> void:
	current_health -= amount
	if current_health <= 0.0:
		glider_died.emit(global_position)
		queue_free()
""",

    "cave_wyrm": """extends CharacterBody3D

signal wyrm_died(pos: Vector3)

@export var max_health: float = 140.0
@export var current_health: float = 140.0
@export var burrow_speed: float = 3.6
@export var bite_damage: float = 35.0

var player_ref: CharacterBody3D
var model_root: Node3D
var bite_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	_setup_collision()
	_load_model()
	_find_player()

func _setup_collision() -> void:
	collision_layer = 4
	collision_mask = 1
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.55
	cap.height = 2.8
	col.shape = cap
	col.position = Vector3(0, 0.4, 0)
	add_child(col)

func _load_model() -> void:
	model_root = Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)
	var glb = load("res://models/cave_wyrm.glb")
	if glb:
		var inst = glb.instantiate()
		model_root.add_child(inst)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	if bite_cooldown > 0.0:
		bite_cooldown -= delta

	if player_ref:
		var to_player = player_ref.global_position - global_position
		to_player.y = 0.0
		var dist = to_player.length()
		if dist < 20.0 and dist > 2.0:
			var dir = to_player.normalized()
			velocity.x = dir.x * burrow_speed
			velocity.z = dir.z * burrow_speed
			rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), delta * 4.0)
		elif dist <= 2.2 and bite_cooldown <= 0.0:
			bite_cooldown = 2.0
			if player_ref.has_method("take_damage"):
				player_ref.take_damage(bite_damage)
		else:
			velocity.x = move_toward(velocity.x, 0.0, delta * 4.0)
			velocity.z = move_toward(velocity.z, 0.0, delta * 4.0)
	move_and_slide()

func take_damage(amount: float, hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> void:
	current_health -= amount
	if current_health <= 0.0:
		wyrm_died.emit(global_position)
		queue_free()
""",

    "spore_spitter": """extends StaticBody3D

signal spitter_destroyed(pos: Vector3)

@export var max_health: float = 60.0
@export var current_health: float = 60.0
@export var spit_range: float = 14.0
@export var acid_damage: float = 15.0

var player_ref: CharacterBody3D
var model_root: Node3D
var spit_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	_setup_collision()
	_load_model()
	_find_player()

func _setup_collision() -> void:
	collision_layer = 4
	collision_mask = 1
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 0.8
	cyl.height = 1.8
	col.shape = cyl
	col.position = Vector3(0, 0.9, 0)
	add_child(col)

func _load_model() -> void:
	model_root = Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)
	var glb = load("res://models/spore_spitter.glb")
	if glb:
		var inst = glb.instantiate()
		model_root.add_child(inst)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func _process(delta: float) -> void:
	if spit_cooldown > 0.0:
		spit_cooldown -= delta

	if player_ref and spit_cooldown <= 0.0:
		var dist = global_position.distance_to(player_ref.global_position)
		if dist <= spit_range:
			_spit_acid_burst()

func _spit_acid_burst() -> void:
	spit_cooldown = 2.4
	# Acid burst damages player if in direct line-of-sight
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(acid_damage)

func take_damage(amount: float, hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> void:
	current_health -= amount
	if current_health <= 0.0:
		spitter_destroyed.emit(global_position)
		queue_free()
"""
}

for name, script_code in MOB_TEMPLATES.items():
    file_path = os.path.join(SCRIPTS_DIR, f"{name}.gd")
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(script_code)
    print(f"Generated controller script: {file_path}")
