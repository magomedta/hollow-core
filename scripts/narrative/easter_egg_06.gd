# scripts/narrative/easter_egg_06.gd
class_name EasterEgg06Safe
extends StaticBody3D

## Easter Egg EE-06: «Утонувший Сейф Обер-Бухгалтера Синдиката 104»
## Heavy riveted vault safe with 4-digit mechanical combination lock (1-9-2-4).
## Unlocking reveals Syndicate gold, brass 11.4 Hz tuning fork, and triggers
## the distant silhouette of The Watcher at the fog boundary.

signal safe_opened()
signal watcher_manifested(watcher_node: Node3D)

const PixelTextureGenerator = preload("res://scripts/pixel_texture_generator.gd")

@export var safe_id: String = "EE-06"
@export var is_unlocked: bool = false
@export var combination_code: String = "1924"

var current_entered_digits: Array[int] = [0, 0, 0, 0]
var active_digit_index: int = 0

var safe_body_mesh: MeshInstance3D
var safe_door_mesh: MeshInstance3D
var dial_mesh: MeshInstance3D
var watcher_instance: Node3D = null

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("secrets")
	collision_layer = 1 | 8 # Static world + interactable
	collision_mask = 0

	_construct_safe_mesh()

func _construct_safe_mesh() -> void:
	# 1. Main Safe Housing
	safe_body_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.85, 1.05, 0.75)
	safe_body_mesh.mesh = box

	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.20, 0.23, 0.26, 1.0) # Dark oxidized Syndicate steel
	steel_mat.metallic = 0.85
	steel_mat.roughness = 0.55
	safe_body_mesh.material_override = steel_mat
	add_child(safe_body_mesh)

	# Collision box
	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = Vector3(0.95, 1.15, 0.85)
	col.shape = col_box
	add_child(col)

	# 2. Vault Door with Brass Lock Rim
	safe_door_mesh = MeshInstance3D.new()
	safe_door_mesh.name = "VaultDoor"
	var door_box = BoxMesh.new()
	door_box.size = Vector3(0.72, 0.90, 0.08)
	safe_door_mesh.mesh = door_box

	var door_mat = StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.16, 0.18, 0.21, 1.0)
	door_mat.metallic = 0.90
	door_mat.roughness = 0.45
	safe_door_mesh.material_override = door_mat
	safe_door_mesh.position = Vector3(0, 0, 0.38)
	add_child(safe_door_mesh)

	# 3. Rotating Brass Combination Dial
	dial_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.09
	cyl.bottom_radius = 0.09
	cyl.height = 0.04
	cyl.radial_segments = 12
	dial_mesh.mesh = cyl
	var dial_mat = StandardMaterial3D.new()
	dial_mat.albedo_color = Color(0.75, 0.60, 0.28, 1.0)
	dial_mat.metallic = 0.85
	dial_mat.roughness = 0.30
	dial_mesh.material_override = dial_mat
	dial_mesh.position = Vector3(0, 0.05, 0.05)
	dial_mesh.rotation_degrees = Vector3(90, 0, 0)
	safe_door_mesh.add_child(dial_mesh)

func get_interaction_prompt() -> String:
	if is_unlocked:
		return "Сейф Синдиката 104 [ОТКРЫТ]"
	return "Открыть Сейф Синдиката 104 (Код: 1-9-2-4)"

func interact(player: CharacterBody3D) -> bool:
	if is_unlocked:
		return false

	# Unlock safe!
	is_unlocked = true
	_play_open_sequence(player)
	return true

func _play_open_sequence(player: CharacterBody3D) -> void:
	# 1. Door swing tween
	var tw = create_tween()
	tw.tween_property(safe_door_mesh, "rotation_degrees:y", -105.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Sound of heavy mechanical tumblers & creaking hinges
	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("pickaxe_stone", global_position, 0.65, 3.0)
		sm.play_sfx("item_pickup", global_position, 0.85, 2.0)

	# 3. Reward items added to player inventory
	if player and "inventory_system" in player and player.inventory_system:
		player.inventory_system.add_item("gold", 6)
		player.inventory_system.add_item("calcite", 4)
		player.inventory_system.add_item("phosphor", 8)

	safe_opened.emit()

	# 4. Lantern flicker reaction
	if player and "lantern" in player and player.lantern:
		if player.lantern.has_method("flicker"):
			player.lantern.flicker(3.2)

	# 5. Manifest The Watcher on the distant abyss ledge
	_manifest_watcher_apparition()

func _manifest_watcher_apparition() -> void:
	# Spawn watcher figure across the chasm at X: -15, Y: 32, Z: -12
	watcher_instance = Node3D.new()
	watcher_instance.name = "TheWatcher_LedgeApparition"
	get_parent().add_child(watcher_instance)
	watcher_instance.global_position = Vector3(-15.0, 32.0, -12.0)

	# Silhouette body (tall, slender obsidian humanoid)
	var body = MeshInstance3D.new()
	var cap = CapsuleMesh.new()
	cap.radius = 0.28
	cap.height = 2.4
	body.mesh = cap

	var obs_mat = StandardMaterial3D.new()
	obs_mat.albedo_color = Color(0.01, 0.01, 0.01, 1.0) # Pure void black
	obs_mat.roughness = 0.95
	obs_mat.metallic = 0.0
	obs_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	body.material_override = obs_mat
	watcher_instance.add_child(body)

	# Twin cold white pin-prick eyes
	for side in [-1, 1]:
		var eye = MeshInstance3D.new()
		var s = SphereMesh.new()
		s.radius = 0.022
		s.height = 0.044
		eye.mesh = s

		var eye_mat = StandardMaterial3D.new()
		eye_mat.albedo_color = Color(0.95, 0.98, 1.0)
		eye_mat.emission_enabled = true
		eye_mat.emission = Color(0.95, 0.98, 1.0)
		eye_mat.emission_energy_multiplier = 4.0
		eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		eye.material_override = eye_mat
		eye.position = Vector3(side * 0.07, 0.85, 0.24)
		watcher_instance.add_child(eye)

	# Face the safe area
	watcher_instance.look_at(global_position, Vector3.UP)

	watcher_manifested.emit(watcher_instance)

	# Disappear after 8 seconds or when illuminated
	var timer = get_tree().create_timer(8.0)
	timer.timeout.connect(func():
		if is_instance_valid(watcher_instance):
			# Low decaying organ chord resonance
			var sm = get_tree().get_first_node_in_group("sound_manager")
			if sm and sm.has_method("play_sfx"):
				sm.play_sfx("pickaxe_stone", watcher_instance.global_position, 0.45, -3.0)
			watcher_instance.queue_free()
	)
