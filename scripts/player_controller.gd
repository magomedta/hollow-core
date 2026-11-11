# scripts/player_controller.gd
extends CharacterBody3D

signal inventory_changed(inventory: Dictionary)
signal active_slot_changed(slot: int)
signal acoustic_noise_emitted(origin: Vector3, radius: float, noise_type: String)
signal health_changed(current: float, max_health: float)
signal progression_phase_changed(phase: int)

const LanternClass = preload("res://scripts/lantern.gd")
const PickaxeClass = preload("res://scripts/pickaxe.gd")
const BuildingSystemClass = preload("res://scripts/building_system.gd")
const CraftingSystemClass = preload("res://scripts/crafting_system.gd")
const InventorySystemClass = preload("res://scripts/inventory_system.gd")
const VoxelWorldClass = preload("res://scripts/voxel_world.gd")
const DroppedItemClass = preload("res://scripts/dropped_item.gd")
const PixelTextureGenerator = preload("res://scripts/pixel_texture_generator.gd")

enum QuickSlot {
	LANTERN = 1,
	PICKAXE = 2,
	SCAFFOLD = 3,
	BRIDGE = 4,
	BLOCK_5 = 5,
	BLOCK_6 = 6,
	BLOCK_7 = 7,
	BLOCK_8 = 8
}

# Health & Survival
@export var max_health: float = 100.0
var current_health: float = 100.0
var footstep_acoustic_timer: float = 0.0

@export var walk_speed: float = 4.8
@export var sprint_speed: float = 8.2
@export var crouch_speed: float = 2.4
@export var jump_velocity: float = 5.2
@export var mouse_sensitivity: float = 0.0022
@export var acceleration: float = 14.0
@export var friction: float = 12.0

# References
var camera: Camera3D
var neck: Node3D
var collision_shape: CollisionShape3D
var lantern: Node3D
var pickaxe: Node3D
var building_system: Node3D
var crafting_system: CanvasLayer
var inventory_system: CanvasLayer
var voxel_world: Node3D

# State
var is_sprinting: bool = false
var is_crouching: bool = false
var head_bob_phase: float = 0.0
var default_camera_y: float = 1.65
var crouch_camera_y: float = 1.05

# Subterranean Depth baseline
var base_depth_meters: float = 1420.0
var reference_y: float = 15.35

# Inventory System (Starting out at Expedition Outpost with basic survival kit)
var inventory: Dictionary = {
	"timber": 0,
	"cobblestone": 0,
	"iron": 0,
	"calcite": 0,
	"phosphor": 0
}

# Milestone-Based Progression (Phases 1 through 5, never regresses!)
var progression_phase: int = 1
var bedrock_dig_hits: int = 0
var active_bedrock_crack_mesh: MeshInstance3D
var active_bedrock_crack_mat: StandardMaterial3D
var last_bedrock_hit_pos: Vector3 = Vector3.ZERO
var bedrock_crack_clear_timer: float = 0.0
var hand_strike_timer: float = 0.0

# Active QuickSlot (1: Lantern, 2: Pickaxe, 3: Scaffold, 4: Bridge)
var active_slot: int = QuickSlot.LANTERN

func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_setup_nodes()
	_setup_input_actions()
	set_active_slot(QuickSlot.LANTERN)
	inventory_changed.emit(inventory)
	progression_phase_changed.emit(progression_phase)

func _setup_input_actions() -> void:
	var actions = {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE],
		"sprint": [KEY_SHIFT],
		"crouch": [KEY_CTRL],
		"toggle_lantern": [KEY_F],
		"refuel": [KEY_R],
		"open_crafting": [KEY_C],
		"slot_1": [KEY_1],
		"slot_2": [KEY_2],
		"slot_3": [KEY_3],
		"slot_4": [KEY_4]
	}
	for act in actions.keys():
		if not InputMap.has_action(act):
			InputMap.add_action(act)
			for k in actions[act]:
				var ev = InputEventKey.new()
				ev.physical_keycode = k
				InputMap.action_add_event(act, ev)

func _setup_nodes() -> void:
	neck = get_node_or_null("Neck")
	if neck == null:
		neck = Node3D.new()
		neck.name = "Neck"
		neck.position = Vector3(0, default_camera_y, 0)
		add_child(neck)

	camera = neck.get_node_or_null("Camera3D")
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		camera.fov = 85.0
		camera.near = 0.05
		camera.far = 280.0
		neck.add_child(camera)

	collision_shape = get_node_or_null("CollisionShape3D")
	if collision_shape == null:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		var capsule = CapsuleShape3D.new()
		capsule.radius = 0.38
		capsule.height = 1.8
		collision_shape.shape = capsule
		collision_shape.position = Vector3(0, 0.9, 0)
		add_child(collision_shape)

	# 1. Lantern inside camera
	lantern = camera.get_node_or_null("Lantern")
	if lantern == null:
		lantern = LanternClass.new()
		lantern.name = "Lantern"
		camera.add_child(lantern)

	# 2. Surveyor Pickaxe inside camera
	pickaxe = camera.get_node_or_null("Pickaxe")
	if pickaxe == null:
		pickaxe = PickaxeClass.new()
		pickaxe.name = "Pickaxe"
		camera.add_child(pickaxe)
		if pickaxe.has_method("set_camera"):
			pickaxe.set_camera(camera)
		if pickaxe.has_signal("hit_landed"):
			pickaxe.hit_landed.connect(_on_pickaxe_hit_landed)

	# 3. Building System inside camera
	building_system = camera.get_node_or_null("BuildingSystem")
	if building_system == null:
		building_system = BuildingSystemClass.new()
		building_system.name = "BuildingSystem"
		camera.add_child(building_system)
		if building_system.has_method("set_player"):
			building_system.set_player(self)

	# 4. Crafting System CanvasLayer
	crafting_system = get_node_or_null("CraftingSystem")
	if crafting_system == null:
		crafting_system = CraftingSystemClass.new()
		crafting_system.name = "CraftingSystem"
		add_child(crafting_system)
		crafting_system.set_player(self)

	# 5. Full Expedition Backpack & Inventory System CanvasLayer
	inventory_system = get_node_or_null("InventorySystem")
	if inventory_system == null:
		inventory_system = InventorySystemClass.new()
		inventory_system.name = "InventorySystem"
		add_child(inventory_system)
		inventory_system.set_player(self)
		inventory_system.active_slot_changed.connect(_on_inventory_active_slot_changed)

func _on_inventory_active_slot_changed(slot_idx: int) -> void:
	var target_slot = slot_idx + 1
	if active_slot != target_slot:
		set_active_slot(target_slot)

func set_active_slot(slot: int) -> void:
	active_slot = clamp(slot, 1, 8)
	active_slot_changed.emit(active_slot)

	if inventory_system and inventory_system.active_hotbar_index != (active_slot - 1):
		inventory_system.select_hotbar_slot(active_slot - 1)

	match active_slot:
		QuickSlot.LANTERN:
			if lantern:
				lantern.set_hand_mode(true)
			if pickaxe:
				pickaxe.set_active(false)
			if building_system:
				building_system.set_build_type(BuildingSystemClass.BuildType.NONE)

		QuickSlot.PICKAXE:
			if lantern:
				lantern.set_hand_mode(false) # Harness/belt illumination
			if pickaxe:
				pickaxe.set_active(true)
			if building_system:
				building_system.set_build_type(BuildingSystemClass.BuildType.NONE)

		QuickSlot.SCAFFOLD:
			if lantern:
				lantern.set_hand_mode(false)
			if pickaxe:
				pickaxe.set_active(false)
			if building_system:
				building_system.set_build_type(BuildingSystemClass.BuildType.SCAFFOLD)

		QuickSlot.BRIDGE:
			if lantern:
				lantern.set_hand_mode(false)
			if pickaxe:
				pickaxe.set_active(false)
			if building_system:
				building_system.set_build_type(BuildingSystemClass.BuildType.BRIDGE)

		_:
			# Slots 5 through 8: Hand holds placeable blocks/items from inventory
			if lantern:
				lantern.set_hand_mode(false)
			if pickaxe:
				pickaxe.set_active(false)
			if building_system:
				building_system.set_build_type(BuildingSystemClass.BuildType.NONE)

func add_resource(res_name: String, amount: int) -> void:
	var key = res_name.to_lower()
	if not inventory.has(key):
		inventory[key] = 0
	inventory[key] += amount
	inventory_changed.emit(inventory)
	if inventory_system and inventory_system.has_method("add_item"):
		inventory_system.add_item(key, amount)
	_evaluate_progression_milestones()

func has_resource(res_name: String, amount: int) -> bool:
	var key = res_name.to_lower()
	return inventory.has(key) and inventory[key] >= amount

func consume_resource(res_name: String, amount: int) -> bool:
	var key = res_name.to_lower()
	if has_resource(key, amount):
		inventory[key] -= amount
		inventory_changed.emit(inventory)
		return true
	return false

func _evaluate_progression_milestones() -> void:
	var old_phase = progression_phase
	var timber = inventory.get("timber", 0)
	var cobble = inventory.get("cobblestone", 0)
	var iron = inventory.get("iron", 0)
	var calcite = inventory.get("calcite", 0)
	var phosphor = inventory.get("phosphor", 0)
	var current_tier = pickaxe.tier if pickaxe else 1

	if progression_phase == 1 and timber >= 4:
		progression_phase = 2
	if progression_phase == 2 and (current_tier >= 2 or cobble >= 4):
		progression_phase = 3
	if progression_phase == 3 and (iron >= 3 or current_tier >= 3):
		progression_phase = 4
	if progression_phase == 4 and (phosphor >= 3 or global_position.x > 22.0):
		progression_phase = 5

	if progression_phase != old_phase:
		progression_phase_changed.emit(progression_phase)

func advance_progression_phase(phase: int) -> void:
	if phase > progression_phase:
		progression_phase = phase
		progression_phase_changed.emit(progression_phase)

func upgrade_pickaxe_tier(new_tier: int) -> void:
	if pickaxe and pickaxe.has_method("set_tier"):
		pickaxe.set_tier(new_tier)
	if new_tier == 2 and progression_phase < 3:
		advance_progression_phase(3)
	elif new_tier >= 3 and progression_phase < 4:
		advance_progression_phase(4)

func _unhandled_input(event: InputEvent) -> void:
	# If Crafting UI is open, don't process player controls
	if crafting_system and crafting_system.is_open:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_delta = event.relative
		rotate_y(-mouse_delta.x * mouse_sensitivity)
		if neck:
			neck.rotate_x(-mouse_delta.y * mouse_sensitivity)
			neck.rotation.x = clamp(neck.rotation.x, -deg_to_rad(85.0), deg_to_rad(85.0))

		if lantern and lantern.has_method("apply_camera_rotation_impulse"):
			lantern.apply_camera_rotation_impulse(mouse_delta)
		if pickaxe and pickaxe.has_method("apply_camera_rotation_impulse"):
			pickaxe.apply_camera_rotation_impulse(mouse_delta)

	elif event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			if active_slot == QuickSlot.PICKAXE and pickaxe:
				pickaxe.start_swing()
			elif (active_slot == QuickSlot.SCAFFOLD or active_slot == QuickSlot.BRIDGE) and building_system:
				building_system.try_place()
			elif active_slot == QuickSlot.LANTERN:
				_perform_hand_strike()
			else:
				# Other slots (5-8): punch or place
				_perform_hand_strike()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if (active_slot == QuickSlot.SCAFFOLD or active_slot == QuickSlot.BRIDGE) and building_system:
				building_system.rotate_90()
			else:
				_handle_right_click_place()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var prev = active_slot - 1
			if prev < 1: prev = 8
			set_active_slot(prev)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var nxt = active_slot + 1
			if nxt > 8: nxt = 1
			set_active_slot(nxt)

	elif event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_ESCAPE:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.keycode == KEY_E or event.keycode == KEY_TAB:
			if inventory_system:
				inventory_system.toggle()
		elif event.keycode == KEY_C:
			if crafting_system:
				crafting_system.toggle_menu()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_8:
			var slot_num = event.keycode - KEY_1 + 1
			set_active_slot(slot_num)
		elif event.is_action_pressed("toggle_lantern") or event.keycode == KEY_F:
			if lantern and lantern.has_method("toggle_lantern"):
				lantern.toggle_lantern()
		elif event.is_action_pressed("refuel") or event.keycode == KEY_R:
			if active_slot == QuickSlot.SCAFFOLD or active_slot == QuickSlot.BRIDGE:
				if building_system:
					building_system.rotate_90()
			else:
				if consume_resource("calcite", 2) or consume_resource("phosphor", 3):
					if lantern and lantern.has_method("refuel"):
						lantern.refuel(50.0)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta * 1.5

	is_sprinting = (Input.is_action_pressed("sprint") or Input.is_physical_key_pressed(KEY_SHIFT)) and not is_crouching
	is_crouching = Input.is_action_pressed("crouch") or Input.is_physical_key_pressed(KEY_CTRL)

	if (Input.is_action_just_pressed("jump") or Input.is_physical_key_pressed(KEY_SPACE)) and is_on_floor():
		velocity.y = jump_velocity

	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward") or Input.is_physical_key_pressed(KEY_W):
		input_dir.y -= 1.0
	if Input.is_action_pressed("move_back") or Input.is_physical_key_pressed(KEY_S):
		input_dir.y += 1.0
	if Input.is_action_pressed("move_left") or Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1.0
	input_dir = input_dir.normalized()

	var target_speed = walk_speed
	if is_sprinting:
		target_speed = sprint_speed
	elif is_crouching:
		target_speed = crouch_speed

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction != Vector3.ZERO:
		velocity.x = lerp(velocity.x, direction.x * target_speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * target_speed, acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		velocity.z = lerp(velocity.z, 0.0, friction * delta)

	move_and_slide()
	_handle_camera_and_headbob(delta)

	# Acoustic vibration emission for blind subterranean predators
	var horiz_vel = Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horiz_vel > 0.3:
		footstep_acoustic_timer += delta
		var step_interval = 0.32 if is_sprinting else 0.52
		if footstep_acoustic_timer >= step_interval:
			footstep_acoustic_timer = 0.0
			if is_sprinting:
				acoustic_noise_emitted.emit(global_position, 16.0, "sprint")
			elif not is_crouching:
				acoustic_noise_emitted.emit(global_position, 6.0, "walk")
	else:
		footstep_acoustic_timer = 0.0

	if lantern and lantern.has_method("apply_movement_bob"):
		lantern.apply_movement_bob(velocity, is_on_floor(), delta)
	if pickaxe and pickaxe.has_method("apply_movement_bob"):
		pickaxe.apply_movement_bob(velocity, is_on_floor(), delta)

	# Continuous punching/mining with bare hands when Slot 1 is active
	if hand_strike_timer > 0.0:
		hand_strike_timer -= delta
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if active_slot == QuickSlot.LANTERN and hand_strike_timer <= 0.0:
			hand_strike_timer = 0.38
			_perform_hand_strike()

	if bedrock_crack_clear_timer > 0.0:
		bedrock_crack_clear_timer -= delta
		if bedrock_crack_clear_timer <= 0.0:
			bedrock_dig_hits = 0
			_clear_bedrock_crack_decal()

func _perform_hand_strike() -> void:
	if camera == null:
		return
	var space = get_world_3d().direct_space_state
	var origin = camera.global_position
	var forward = -camera.global_transform.basis.z
	var end = origin + forward * 3.4
	var query = PhysicsRayQueryParameters3D.create(origin, end, 1 | 8, [self])
	var result = space.intersect_ray(query)
	if result:
		var collider = result.collider
		var hit_pos = result.position
		var hit_norm = result.normal
		# Hand strike damages wooden camp crates and minable targets!
		if collider.has_method("mine"):
			collider.mine(25.0, hit_pos, hit_norm)
		elif collider.has_method("take_hit"):
			collider.take_hit(25.0, hit_pos, hit_norm)
		else:
			_on_pickaxe_hit_landed(collider, hit_pos, hit_norm)

		if neck:
			neck.rotation.x += deg_to_rad(0.6)

func _on_pickaxe_hit_landed(collider: Object, hit_point: Vector3, hit_normal: Vector3) -> void:
	acoustic_noise_emitted.emit(hit_point, 38.0, "pickaxe_impact")
	if collider == null:
		return

	# Minecraft-Style Bedrock Rule: True bedrock is completely indestructible
	if collider.is_in_group("bedrock"):
		_spawn_bedrock_sparks(hit_point, hit_normal)
		_clear_bedrock_crack_decal()
		return

	var pick_dmg = pickaxe.damage if pickaxe else 35.0

	if collider.has_method("mine"):
		collider.mine(pick_dmg, hit_point, hit_normal)
	elif collider.has_method("take_hit"):
		collider.take_hit(pick_dmg, hit_point, hit_normal)
	elif collider.has_method("take_damage"):
		collider.take_damage(pick_dmg, hit_point, hit_normal)
	else:
		# Dynamic Voxel Terrain Excavation
		if voxel_world == null:
			voxel_world = get_tree().get_first_node_in_group("voxel_world")
			if voxel_world == null and get_parent() and get_parent().has_node("VoxelWorld"):
				voxel_world = get_parent().get_node("VoxelWorld")

		var target_coord = Vector3i(floor(hit_point.x - hit_normal.x * 0.4), floor(hit_point.y - hit_normal.y * 0.4), floor(hit_point.z - hit_normal.z * 0.4))
		var is_bedrock = false
		if voxel_world and voxel_world.has_method("get_block"):
			var b_type = voxel_world.get_block(target_coord.x, target_coord.y, target_coord.z)
			if b_type == VoxelWorldClass.BlockType.BEDROCK:
				is_bedrock = true

		if is_bedrock:
			_spawn_bedrock_sparks(hit_point, hit_normal)
			_clear_bedrock_crack_decal()
			return

		_spawn_bedrock_impact(hit_point, hit_normal)
		if hit_point.distance_to(last_bedrock_hit_pos) > 1.2:
			bedrock_dig_hits = 0
		last_bedrock_hit_pos = hit_point
		bedrock_dig_hits += 1
		bedrock_crack_clear_timer = 4.0

		_update_bedrock_crack_decal(hit_point, hit_normal, bedrock_dig_hits)

		var hits_needed = 2
		if pickaxe and pickaxe.tier >= 3:
			hits_needed = 1
		elif active_slot == QuickSlot.LANTERN:
			hits_needed = 3

		if bedrock_dig_hits >= hits_needed:
			bedrock_dig_hits = 0
			_clear_bedrock_crack_decal()
			if voxel_world and voxel_world.has_method("mine_block"):
				voxel_world.mine_block(target_coord, pick_dmg, hit_point, hit_normal)
			else:
				_spawn_loose_cobblestone_drop(hit_point, hit_normal)

func _handle_right_click_place() -> void:
	if inventory_system == null or camera == null:
		return
	var item = inventory_system.get_active_item()
	if item.is_empty():
		return

	var reg = InventorySystemClass.ITEM_REGISTRY.get(item.id, {})
	var b_type = reg.get("block_type", 0)
	if b_type <= 0:
		return

	var space = get_world_3d().direct_space_state
	var origin = camera.global_position
	var forward = -camera.global_transform.basis.z
	var end = origin + forward * 4.5
	var query = PhysicsRayQueryParameters3D.create(origin, end, 1 | 8, [self])
	var result = space.intersect_ray(query)
	if result:
		var hit_pos = result.position
		var hit_norm = result.normal
		var target_coord = Vector3i(floor(hit_pos.x - hit_norm.x * 0.4), floor(hit_pos.y - hit_norm.y * 0.4), floor(hit_pos.z - hit_norm.z * 0.4))
		var place_normal = Vector3i(round(hit_norm.x), round(hit_norm.y), round(hit_norm.z))
		var place_pos = target_coord + place_normal

		# Avoid placing block inside player's own bounding box
		var player_min = global_position - Vector3(0.4, 0.0, 0.4)
		var player_max = global_position + Vector3(0.4, 1.8, 0.4)
		var b_min = Vector3(place_pos.x, place_pos.y, place_pos.z)
		var b_max = b_min + Vector3(1.0, 1.0, 1.0)

		if player_max.x > b_min.x and player_min.x < b_max.x and player_max.y > b_min.y and player_min.y < b_max.y and player_max.z > b_min.z and player_min.z < b_max.z:
			return

		if voxel_world == null:
			voxel_world = get_tree().get_first_node_in_group("voxel_world")
			if voxel_world == null and get_parent() and get_parent().has_node("VoxelWorld"):
				voxel_world = get_parent().get_node("VoxelWorld")

		if voxel_world and voxel_world.has_method("place_block_at"):
			if voxel_world.place_block_at(target_coord, place_normal, b_type):
				inventory_system.consume_active_item(1)
				acoustic_noise_emitted.emit(hit_pos, 14.0, "block_place")

func _update_bedrock_crack_decal(pos: Vector3, normal: Vector3, stage: int) -> void:
	if active_bedrock_crack_mesh == null or not is_instance_valid(active_bedrock_crack_mesh):
		active_bedrock_crack_mat = StandardMaterial3D.new()
		active_bedrock_crack_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		active_bedrock_crack_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		active_bedrock_crack_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		active_bedrock_crack_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

		active_bedrock_crack_mesh = MeshInstance3D.new()
		var qm = QuadMesh.new()
		qm.size = Vector2(1.15, 1.15)
		active_bedrock_crack_mesh.mesh = qm
		active_bedrock_crack_mesh.material_override = active_bedrock_crack_mat
		get_parent().add_child(active_bedrock_crack_mesh)

	var tex_stage = clamp(stage, 1, 5)
	active_bedrock_crack_mat.albedo_texture = PixelTextureGenerator.get_dig_crack_texture(tex_stage)
	active_bedrock_crack_mesh.visible = true
	active_bedrock_crack_mesh.global_position = pos + normal * 0.025
	var up = Vector3.UP if abs(normal.y) < 0.9 else Vector3.FORWARD
	active_bedrock_crack_mesh.look_at(pos + normal, up)

func _clear_bedrock_crack_decal() -> void:
	if active_bedrock_crack_mesh and is_instance_valid(active_bedrock_crack_mesh):
		active_bedrock_crack_mesh.visible = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if active_bedrock_crack_mesh and is_instance_valid(active_bedrock_crack_mesh):
			active_bedrock_crack_mesh.queue_free()

func _spawn_bedrock_impact(hit_pos: Vector3, normal: Vector3) -> void:
	var p = CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 14
	p.lifetime = 0.5
	p.direction = normal + Vector3(randf_range(-0.25, 0.25), 0.3, randf_range(-0.25, 0.25))
	p.spread = 45.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.2
	p.gravity = Vector3(0, -9.8, 0)
	p.scale_amount_min = 0.03
	p.scale_amount_max = 0.07

	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(0.04, 0.04, 0.04)
	p.mesh = p_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.40, 0.44, 0.50)
	p.material_override = mat

	get_parent().add_child(p)
	p.global_position = hit_pos
	p.restart()

	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(p.queue_free)

func _spawn_bedrock_sparks(hit_pos: Vector3, normal: Vector3) -> void:
	var p = CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 22
	p.lifetime = 0.35
	p.direction = normal + Vector3(randf_range(-0.35, 0.35), 0.45, randf_range(-0.35, 0.35))
	p.spread = 55.0
	p.initial_velocity_min = 3.5
	p.initial_velocity_max = 6.5
	p.gravity = Vector3(0, -9.8, 0)
	p.scale_amount_min = 0.02
	p.scale_amount_max = 0.05

	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(0.03, 0.03, 0.03)
	p.mesh = p_mesh

	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.90, 0.45)
	p.material_override = mat

	get_parent().add_child(p)
	p.global_position = hit_pos
	p.restart()

	var timer = get_tree().create_timer(0.6)
	timer.timeout.connect(p.queue_free)

func _spawn_loose_cobblestone_drop(hit_pos: Vector3, normal: Vector3) -> void:
	var drop = DroppedItemClass.new()
	drop.item_type = DroppedItemClass.ItemType.COBBLESTONE
	drop.amount = 1
	get_parent().add_child(drop)
	drop.global_position = hit_pos + normal * 0.35 + Vector3(0, 0.2, 0)

func take_damage(amount: float) -> void:
	current_health = clamp(current_health - amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)
	if neck:
		neck.rotation.z += randf_range(-0.06, 0.06)

func _handle_camera_and_headbob(delta: float) -> void:
	var target_neck_y = crouch_camera_y if is_crouching else default_camera_y
	neck.position.y = lerp(neck.position.y, target_neck_y, delta * 10.0)

	var horiz_vel = Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horiz_vel > 0.3:
		var bob_freq = 11.0 if is_sprinting else 8.0
		var bob_amp = 0.038 if is_sprinting else 0.022
		head_bob_phase += delta * bob_freq
		camera.position.y = sin(head_bob_phase) * bob_amp
		camera.position.x = cos(head_bob_phase * 0.5) * (bob_amp * 0.5)
		var strafe_factor = clamp(neck.basis.inverse() * velocity, Vector3(-1,-1,-1), Vector3(1,1,1)).x
		camera.rotation.z = lerp(camera.rotation.z, -strafe_factor * 0.02, delta * 8.0)
	else:
		camera.position = camera.position.lerp(Vector3.ZERO, delta * 8.0)
		camera.rotation.z = lerp(camera.rotation.z, 0.0, delta * 8.0)

func get_current_depth_meters() -> float:
	# Scaled subterranean depth: Surface (Y=32) is ~210m, Outpost (Y=10) is 1,200m, Deepslate (Y=-6) is 1,920m, Magma Core (Y=-25) is 2,775m
	return clamp(1200.0 + (10.0 - global_position.y) * 45.0, 50.0, 3200.0)

func get_compass_heading_degrees() -> float:
	return fposmod(-rotation_degrees.y, 360.0)
