extends CharacterBody3D

const MobDeathEffects = preload("res://scripts/mob_death_effects.gd")

signal strider_died(pos: Vector3)

@export var max_health: float = 40.0
@export var current_health: float = 40.0
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
		var bespoke_mat = StandardMaterial3D.new()
		var img = Image.load_from_file("res://textures/mobs/tex_fungal_strider.png")
		if img:
			bespoke_mat.albedo_texture = ImageTexture.create_from_image(img)
		bespoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		bespoke_mat.emission_enabled = true
		var emit_img = Image.load_from_file("res://textures/mobs/tex_fungal_strider_emit.png")
		if emit_img:
			bespoke_mat.emission_texture = ImageTexture.create_from_image(emit_img)
		bespoke_mat.emission_energy_multiplier = 3.5
		_apply_material_recursive(inst, bespoke_mat)

func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node
		mi.material_override = mat
	for child in node.get_children():
		_apply_material_recursive(child, mat)

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
		MobDeathEffects.play_death_effect(self, "fungal")
