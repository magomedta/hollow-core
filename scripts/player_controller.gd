# scripts/player_controller.gd
# Advanced First-Person Subterranean Explorer Controller
# Features:
# - Full cross-layout controls (WASD, Arrow keys, Russian ЦЫФВ)
# - Dual-wield logic: Pickaxe in hand hides left-hand lantern model/arm, but chest harness lamp illuminates forward!
# - Survival Vitals: Health, Hydration (Water), Satiety (Food), Core Temperature
# - Differentiated mining durability: Hit counts scale with block hardness (Gravel: 1 hit, Stone: 3-4 hits, Iron: 5 hits, Gold: 7-8 hits, Bedrock: Indestructible)
# - Dynamic 5-stage progressive fracture decal on targeted voxel face
# - Direct voxel placement (RMB) with real-time amber ghost preview wireframe
# - Consumable support (Canteen = +40 Water, Rations = +50 Food)

class_name PlayerController
extends CharacterBody3D

signal inventory_changed(inventory: Dictionary)
signal active_slot_changed(slot: int)
signal acoustic_noise_emitted(origin: Vector3, radius: float, noise_type: String)
signal health_changed(current: float, max_health: float)
signal vitals_changed(health: float, hydration: float, satiety: float, temperature: float)
signal progression_phase_changed(phase: int)
signal lore_opened(log_id: String)

const LanternClass = preload("res://scripts/lantern.gd")
const PickaxeClass = preload("res://scripts/pickaxe.gd")
const BuildingSystemClass = preload("res://scripts/building_system.gd")
const CraftingSystemClass = preload("res://scripts/crafting_system.gd")
const InventorySystemClass = preload("res://scripts/inventory_system.gd")
const VoxelWorldClass = preload("res://scripts/voxel_world.gd")
const DroppedItemClass = preload("res://scripts/dropped_item.gd")
const PixelTextureGenerator = preload("res://scripts/pixel_texture_generator.gd")

enum QuickSlot {
	SLOT_1 = 1,
	SLOT_2 = 2,
	SLOT_3 = 3,
	SLOT_4 = 4,
	SLOT_5 = 5,
	SLOT_6 = 6,
	SLOT_7 = 7,
	SLOT_8 = 8
}

# Survival Vitals
@export var max_health: float = 100.0
var current_health: float = 100.0
var invulnerability_timer: float = 0.0
@export var max_hydration: float = 100.0
var current_hydration: float = 100.0
@export var max_satiety: float = 100.0
var current_satiety: float = 100.0
var core_temperature: float = 17.0
var footstep_acoustic_timer: float = 0.0


# Movement physics
@export var walk_speed: float = 3.8
@export var sprint_speed: float = 5.6
@export var crouch_speed: float = 1.8
@export var jump_velocity: float = 6.8
@export var auto_jump_velocity: float = 6.8
@export var gravity: float = 19.6
@export var mouse_sensitivity: float = 0.0022
@export var acceleration: float = 14.0
@export var friction: float = 12.0

var hand_strike_timer: float = 0.0
var hand_strike_cooldown: float = 0.35

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
var viewmodel_camera: Camera3D
var viewmodel_layer: CanvasLayer
var wall_tuck_blend: float = 0.0

# State
var is_sprinting: bool = false
var is_crouching: bool = false
var is_wading_in_water: bool = false
var current_water_surface_y: float = 0.0
var current_surface_friction: float = 1.0
var head_bob_phase: float = 0.0
var default_camera_y: float = 1.65
var crouch_camera_y: float = 1.05
var was_on_floor: bool = true

# Subterranean Depth baseline
var base_depth_meters: float = 1420.0
var reference_y: float = 11.2

# Inventory System
var inventory: Dictionary = {
	"timber": 12,
	"cobblestone": 32,
	"iron": 2,
	"calcite": 4,
	"phosphor": 8
}

# Mining State
var active_slot: int = 1
var progression_phase: int = 1
var current_target_voxel: Vector3i = Vector3i(999999, 999999, 999999)
var current_voxel_hits: int = 0
var active_bedrock_crack_mesh: MeshInstance3D
var active_bedrock_crack_mat: StandardMaterial3D
var crack_clear_timer: float = 0.0

# Real-Time Ghost Block Placement Preview
var ghost_block_mesh: MeshInstance3D
var ghost_block_mat: StandardMaterial3D
var active_placement_coord: Vector3i = Vector3i.ZERO
var active_placement_normal: Vector3i = Vector3i.ZERO
var has_valid_placement: bool = false

func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Smooth voxel terrain traversal settings
	floor_snap_length = 0.35
	floor_constant_speed = true
	floor_stop_on_slope = true
	floor_max_angle = deg_to_rad(60.0)
	wall_min_slide_angle = deg_to_rad(15.0)
	safe_margin = 0.005
	up_direction = Vector3.UP

	_setup_nodes()
	_setup_ghost_block()
	_setup_input_actions()
	set_active_slot(1)
	inventory_changed.emit(inventory)
	health_changed.emit(current_health, max_health)
	progression_phase_changed.emit(progression_phase)

func _setup_input_actions() -> void:
	var actions = {
		"move_forward": [KEY_W, KEY_UP, KEY_Z, 1062],
		"move_back": [KEY_S, KEY_DOWN, 1067],
		"move_left": [KEY_A, KEY_LEFT, KEY_Q, 1060],
		"move_right": [KEY_D, KEY_RIGHT, 1042],
		"jump": [KEY_SPACE],
		"sprint": [KEY_SHIFT],
		"crouch": [KEY_CTRL],
		"toggle_lantern": [KEY_F, 1040],
		"refuel": [KEY_R, 1050],
		"open_crafting": [KEY_C, 1057],
		"interact": [KEY_E, 1059],
		"slot_1": [KEY_1],
		"slot_2": [KEY_2],
		"slot_3": [KEY_3],
		"slot_4": [KEY_4],
		"slot_5": [KEY_5],
		"slot_6": [KEY_6],
		"slot_7": [KEY_7],
		"slot_8": [KEY_8]
	}
	for act in actions.keys():
		if not InputMap.has_action(act):
			InputMap.add_action(act)
		else:
			InputMap.action_erase_events(act)

		for k in actions[act]:
			var ev1 = InputEventKey.new()
			ev1.keycode = k
			InputMap.action_add_event(act, ev1)

			var ev2 = InputEventKey.new()
			ev2.physical_keycode = k
			InputMap.action_add_event(act, ev2)

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
		camera.far = 320.0
		neck.add_child(camera)

	collision_shape = get_node_or_null("CollisionShape3D")
	if collision_shape == null:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		var capsule = CapsuleShape3D.new()
		capsule.radius = 0.34
		capsule.height = 1.75
		collision_shape.shape = capsule
		collision_shape.position = Vector3(0, 0.88, 0)
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

	# 3. Building System
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

	# 5. Inventory System CanvasLayer
	inventory_system = get_node_or_null("InventorySystem")
	if inventory_system == null:
		inventory_system = InventorySystemClass.new()
		inventory_system.name = "InventorySystem"
		add_child(inventory_system)
		inventory_system.set_player(self)
		inventory_system.active_slot_changed.connect(_on_inventory_active_slot_changed)
		inventory_system.inventory_updated.connect(_on_inventory_system_updated)

	# 6. Anti-Wall-Clipping Viewmodel SubViewport Overlay & Layer Isolation
	_setup_viewmodel_viewport()
	_apply_viewmodel_layers()

func _setup_viewmodel_viewport() -> void:
	if camera == null:
		return
	# Main camera only renders layer 1 (world) and layer 4 (enemies), etc., ignoring layer 2 (held items)
	camera.cull_mask = 1 | 4 | 8 | 16
	camera.near = 0.02

	viewmodel_layer = CanvasLayer.new()
	viewmodel_layer.name = "ViewmodelLayer"
	viewmodel_layer.layer = 2 # In front of 3D world (layer 1), below HUD (layer 10)
	add_child(viewmodel_layer)

	var vm_container = SubViewportContainer.new()
	vm_container.name = "ViewmodelContainer"
	vm_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vm_container.stretch = true
	vm_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewmodel_layer.add_child(vm_container)

	var vm_viewport = SubViewport.new()
	vm_viewport.name = "ViewmodelViewport"
	vm_viewport.transparent_bg = true
	vm_viewport.handle_input_locally = false
	vm_viewport.own_world_3d = false # Shared 3D world: shares lantern, torches, atmosphere!
	vm_container.add_child(vm_viewport)

	viewmodel_camera = Camera3D.new()
	viewmodel_camera.name = "ViewmodelCamera"
	viewmodel_camera.cull_mask = 2 # Only renders Layer 2 (viewmodel held items)
	viewmodel_camera.fov = camera.fov
	viewmodel_camera.near = 0.01
	viewmodel_camera.far = 50.0
	if camera.environment:
		viewmodel_camera.environment = camera.environment
	vm_viewport.add_child(viewmodel_camera)

	# Dedicated viewmodel directional fill so held items are crisply shaded
	var vm_fill = OmniLight3D.new()
	vm_fill.name = "ViewmodelFillLight"
	vm_fill.layers = 2
	vm_fill.light_cull_mask = 2
	vm_fill.light_color = Color(1.0, 0.94, 0.82)
	vm_fill.light_energy = 1.2
	vm_fill.omni_range = 4.0
	vm_fill.shadow_enabled = false
	vm_fill.position = Vector3(0.0, 0.1, -0.2)
	viewmodel_camera.add_child(vm_fill)

func _apply_viewmodel_layers() -> void:
	if pickaxe:
		_set_geometry_layers(pickaxe, 2)
	if lantern:
		_set_geometry_layers(lantern, 2)
		if lantern.omni_light:
			lantern.omni_light.layers = 1 | 2 # Visible to both main and viewmodel cameras!
			lantern.omni_light.light_cull_mask = 1 | 2 # Illuminates both world and held arms!
		if lantern.spot_light:
			lantern.spot_light.layers = 1 | 2
			lantern.spot_light.light_cull_mask = 1 | 2
	if building_system:
		_set_geometry_layers(building_system, 2)

func _set_geometry_layers(node: Node, layer_val: int) -> void:
	if node is GeometryInstance3D:
		node.layers = layer_val
	for child in node.get_children():
		_set_geometry_layers(child, layer_val)

func _sync_viewmodel_camera() -> void:
	if viewmodel_camera and camera:
		viewmodel_camera.global_transform = camera.global_transform
		viewmodel_camera.fov = camera.fov
		if camera.environment and viewmodel_camera.environment == null:
			viewmodel_camera.environment = camera.environment

func _process(_delta: float) -> void:
	_sync_viewmodel_camera()
	var doc_open = false
	var doc_viewer = get_tree().get_first_node_in_group("document_viewer")
	if doc_viewer and doc_viewer.visible:
		doc_open = true
	var inv_open = (inventory_system != null and inventory_system.is_open)
	var holding_lantern = (lantern != null and lantern.is_held_in_hand)

	if viewmodel_layer:
		viewmodel_layer.visible = not inv_open and not doc_open
	if pickaxe:
		# Strictly mutually exclusive: if holding lantern, pickaxe is NEVER drawn!
		pickaxe.visible = pickaxe.is_active and not inv_open and not doc_open and not holding_lantern
	if lantern and lantern.lantern_body_root:
		# If pickaxe is active, lantern model is NEVER drawn in hand
		if pickaxe and pickaxe.is_active:
			lantern.lantern_body_root.visible = false

func _process_wall_obstruction(delta: float) -> void:
	if camera == null:
		return

	var space = get_world_3d().direct_space_state
	var cam_pos = camera.global_position
	var forward = -camera.global_transform.basis.z
	var ray_dist = 0.95

	# Multi-ray obstacle probe: center ray + right offset ray (where tool is held)
	var right_dir = camera.global_transform.basis.x
	var query_center = PhysicsRayQueryParameters3D.create(cam_pos, cam_pos + forward * ray_dist, 1, [self])
	var hit_center = space.intersect_ray(query_center)

	var tool_origin = cam_pos + (right_dir * 0.22) + (camera.global_transform.basis.y * -0.15)
	var query_tool = PhysicsRayQueryParameters3D.create(tool_origin, tool_origin + forward * ray_dist, 1, [self])
	var hit_tool = space.intersect_ray(query_tool)

	var min_dist = 999.0
	if not hit_center.is_empty():
		min_dist = min(min_dist, cam_pos.distance_to(hit_center.position))
	if not hit_tool.is_empty():
		min_dist = min(min_dist, tool_origin.distance_to(hit_tool.position))

	var target_tuck = 0.0
	if min_dist < 0.85:
		target_tuck = clamp((0.85 - min_dist) / 0.50, 0.0, 1.0)

	wall_tuck_blend = lerp(wall_tuck_blend, target_tuck, delta * 16.0)

	if pickaxe and pickaxe.has_method("set_wall_tuck"):
		pickaxe.set_wall_tuck(wall_tuck_blend)
	if lantern and lantern.has_method("set_wall_tuck"):
		lantern.set_wall_tuck(wall_tuck_blend)
	if building_system and building_system.has_method("set_wall_tuck"):
		building_system.set_wall_tuck(wall_tuck_blend)

func _setup_ghost_block() -> void:
	ghost_block_mat = StandardMaterial3D.new()
	ghost_block_mat.albedo_color = Color(0.95, 0.78, 0.35, 0.38)
	ghost_block_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_block_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost_block_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	ghost_block_mesh = MeshInstance3D.new()
	ghost_block_mesh.name = "GhostPlacementPreview"
	var bm = BoxMesh.new()
	bm.size = Vector3(1.02, 1.02, 1.02)
	ghost_block_mesh.mesh = bm
	ghost_block_mesh.material_override = ghost_block_mat
	ghost_block_mesh.visible = false
	get_tree().root.call_deferred("add_child", ghost_block_mesh)

func _on_inventory_active_slot_changed(slot_idx: int) -> void:
	var target_slot = slot_idx + 1
	if active_slot != target_slot:
		set_active_slot(target_slot)

func _on_inventory_system_updated() -> void:
	_update_active_held_item()

func set_active_slot(slot: int) -> void:
	active_slot = clamp(slot, 1, 8)
	active_slot_changed.emit(active_slot)

	if inventory_system and inventory_system.active_hotbar_index != (active_slot - 1):
		inventory_system.select_hotbar_slot(active_slot - 1)

	_update_active_held_item()

func _update_active_held_item() -> void:
	var cur_item_id = ""
	if inventory_system and inventory_system.has_method("get_active_item"):
		var cur_item = inventory_system.get_active_item()
		cur_item_id = cur_item.get("id", "")

	# Tool equipping strictly mirrors actual inventory contents:
	# - "lantern" equipped: held up in left hand
	# - "pickaxe" equipped: held in right hand; lantern holstered to chest harness
	# - Empty or blocks: both tool models hidden; lantern holstered to chest harness
	if cur_item_id == "lantern":
		if lantern:
			lantern.set_hand_mode(true)
		if pickaxe:
			pickaxe.set_active(false)
	elif cur_item_id == "pickaxe":
		if lantern:
			lantern.set_hand_mode(false)
		if pickaxe:
			pickaxe.set_active(true)
	else:
		if lantern:
			lantern.set_hand_mode(false)
		if pickaxe:
			pickaxe.set_active(false)

func set_in_water(in_water: bool, surface_y: float = 0.0) -> void:
	is_wading_in_water = in_water
	current_water_surface_y = surface_y

func _physics_process(delta: float) -> void:
	if invulnerability_timer > 0.0:
		invulnerability_timer -= delta

	# 1. Update Survival Vitals
	_update_vitals(delta)

	# 2. Movement & Gravity
	var on_floor = is_on_floor()
	if not was_on_floor and on_floor:
		var sm = get_tree().get_first_node_in_group("sound_manager")
		if sm and sm.has_method("play_land"):
			sm.play_land(global_position)
		elif sm and sm.has_method("play_sfx"):
			sm.play_sfx("land", global_position, 1.0, -2.0)
	was_on_floor = on_floor

	if not on_floor:
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0:
			velocity.y = 0.0

	if Input.is_action_just_pressed("jump") and on_floor:
		velocity.y = jump_velocity * (0.8 if is_wading_in_water else 1.0)
		var sm = get_tree().get_first_node_in_group("sound_manager")
		if sm and sm.has_method("play_sfx"):
			sm.play_sfx("jump", global_position, -4.0)

	is_sprinting = Input.is_action_pressed("sprint") and not is_crouching and not is_wading_in_water
	is_crouching = Input.is_action_pressed("crouch")

	var target_cam_y = crouch_camera_y if is_crouching else default_camera_y
	if neck:
		neck.position.y = move_toward(neck.position.y, target_cam_y, delta * 6.0)

	var move_spd = walk_speed
	if is_sprinting:
		move_spd = sprint_speed
	elif is_crouching:
		move_spd = crouch_speed

	# Water wading dampens movement speed
	if is_wading_in_water:
		move_spd *= 0.62

	# Evaluate geological surface friction underfoot (Permafrost Ice vs Rock vs Brick)
	var is_on_ice = false
	if on_floor:
		var floor_block_y = int(floor(global_position.y - 0.2))
		var floor_block_x = int(floor(global_position.x))
		var floor_block_z = int(floor(global_position.z))
		if voxel_world != null and voxel_world.has_method("get_block"):
			var bt = voxel_world.get_block(floor_block_x, floor_block_y, floor_block_z)
			if bt == 13: # VoxelWorld.BlockType.PERMAFROST_ICE
				is_on_ice = true

	var effective_friction = friction
	var effective_accel = acceleration
	if is_on_ice:
		effective_friction = 2.8 # Slippery glacial drift
		effective_accel = 5.5
		current_surface_friction = 0.38
	else:
		current_surface_friction = 1.0

	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"): input_dir.y -= 1
	if Input.is_action_pressed("move_back"): input_dir.y += 1
	if Input.is_action_pressed("move_left"): input_dir.x -= 1
	if Input.is_action_pressed("move_right"): input_dir.x += 1
	input_dir = input_dir.normalized()

	var wish_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if wish_dir != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, wish_dir.x * move_spd, effective_accel * delta)
		velocity.z = move_toward(velocity.z, wish_dir.z * move_spd, effective_accel * delta)
		if on_floor:
			footstep_acoustic_timer += delta
			var step_interval = 0.32 if is_sprinting else 0.52
			if is_wading_in_water:
				step_interval = 0.60
			if footstep_acoustic_timer >= step_interval:
				footstep_acoustic_timer = 0.0
				var noise_rad = 18.0 if is_sprinting else 8.0
				acoustic_noise_emitted.emit(global_position, noise_rad, "footstep")
				var sm = get_tree().get_first_node_in_group("sound_manager")

				var step_sfx = "footstep_stone"
				var pitch_scale = 1.0
				if is_wading_in_water:
					step_sfx = "footstep_stone"
					pitch_scale = 0.72 # Deeper sloshing water step
				elif is_on_ice:
					step_sfx = "footstep_stone"
					pitch_scale = 1.25 # Crisp high-frequency ice crunch
				if sm and sm.has_method("play_sfx"):
					sm.play_sfx(step_sfx, global_position, pitch_scale, -5.0)

				# Record acoustic event in lithic memory
				var smm = get_tree().get_first_node_in_group("sound_memory_manager")
				if smm and smm.has_method("record_event"):
					smm.record_event("step", global_position, step_sfx, 0.8)
	else:
		velocity.x = move_toward(velocity.x, 0.0, effective_friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, effective_friction * delta)

	# Smooth 1-block step-up assist: effortlessly ascend onto 1-block steps
	if on_floor and wish_dir != Vector3.ZERO and is_on_wall():
		var space = get_world_3d().direct_space_state
		var shin_from = global_position + Vector3(0, 0.4, 0)
		var shin_to = shin_from + wish_dir * 0.8
		var chest_from = global_position + Vector3(0, 1.25, 0)
		var chest_to = chest_from + wish_dir * 0.8
		var q_shin = PhysicsRayQueryParameters3D.create(shin_from, shin_to, 1, [self])
		var q_chest = PhysicsRayQueryParameters3D.create(chest_from, chest_to, 1, [self])
		var hit_shin = space.intersect_ray(q_shin)
		var hit_chest = space.intersect_ray(q_chest)
		if hit_shin and not hit_chest:
			velocity.y = auto_jump_velocity

	move_and_slide()
	_sync_viewmodel_camera()

	# Process tactile weapon wall tuck when facing obstacles
	_process_wall_obstruction(delta)

	# Continuous hand mining when holding LMB and not using pickaxe
	if hand_strike_timer > 0.0:
		hand_strike_timer -= delta

	if active_slot != 2 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var hud = get_tree().get_first_node_in_group("game_hud")
		var is_radial = hud and hud.get("is_radial_menu_open")
		if not is_radial and hand_strike_timer <= 0.0:
			hand_strike_timer = hand_strike_cooldown
			_perform_hand_strike()

	# 3. Update Crack Decay Timer
	if crack_clear_timer > 0.0:
		crack_clear_timer -= delta
		if crack_clear_timer <= 0.0:
			_clear_bedrock_crack_decal()
			current_voxel_hits = 0

	# 4. Update Ghost Block Placement Raycast Preview
	_update_ghost_placement_preview()

func _update_vitals(delta: float) -> void:
	# Hydration drain (accelerates on sprint)
	var hydro_drain = 0.10 if not is_sprinting else 0.26
	current_hydration = max(0.0, current_hydration - hydro_drain * delta)

	# Satiety drain
	var food_drain = 0.06 if not is_sprinting else 0.16
	current_satiety = max(0.0, current_satiety - food_drain * delta)

	# Starvation / Dehydration damage
	if current_hydration <= 0.0 or current_satiety <= 0.0:
		current_health = max(0.0, current_health - 1.2 * delta)
		health_changed.emit(current_health, max_health)

	# Dynamic Core Temperature calculation
	var current_y = global_position.y
	if current_y >= 44.0:
		core_temperature = -34.0 # Surface Cryosphere blizzard!
	elif current_y >= 20.0:
		core_temperature = -4.0 # Ice Karst
	elif current_y >= 0.0:
		core_temperature = 17.0 # Outpost Basin
	elif current_y >= -28.0:
		core_temperature = 28.0 # Deepslate Chasm
	else:
		core_temperature = 65.0 # Magma Core

	# Nearby warmth from lantern
	if lantern and "is_lit" in lantern and lantern.is_lit:
		core_temperature += 8.0

	vitals_changed.emit(current_health, current_hydration, current_satiety, core_temperature)

func _update_ghost_placement_preview() -> void:
	if ghost_block_mesh == null or not is_instance_valid(ghost_block_mesh):
		return

	if inventory_system == null or camera == null:
		ghost_block_mesh.visible = false
		return

	var item = inventory_system.get_active_item()
	if item.is_empty():
		ghost_block_mesh.visible = false
		return

	var reg = InventorySystemClass.ITEM_REGISTRY.get(item.id, {})
	var b_type = reg.get("block_type", 0)
	if b_type <= 0:
		ghost_block_mesh.visible = false
		return

	var space = get_world_3d().direct_space_state
	var origin = camera.global_position
	var forward = -camera.global_transform.basis.z
	var end = origin + forward * 4.8
	var query = PhysicsRayQueryParameters3D.create(origin, end, 1 | 8, [self])
	var result = space.intersect_ray(query)

	if result:
		var hit_pos: Vector3 = result.position
		var hit_norm: Vector3 = result.normal
		var target_coord = Vector3i(floor(hit_pos.x - hit_norm.x * 0.4), floor(hit_pos.y - hit_norm.y * 0.4), floor(hit_pos.z - hit_norm.z * 0.4))
		var place_normal = Vector3i(round(hit_norm.x), round(hit_norm.y), round(hit_norm.z))
		var place_pos = target_coord + place_normal

		# Avoid placing inside player bounding box
		var player_min = global_position - Vector3(0.4, 0.0, 0.4)
		var player_max = global_position + Vector3(0.4, 1.8, 0.4)
		var b_min = Vector3(place_pos.x, place_pos.y, place_pos.z)
		var b_max = b_min + Vector3(1.0, 1.0, 1.0)

		if player_max.x > b_min.x and player_min.x < b_max.x and player_max.y > b_min.y and player_min.y < b_max.y and player_max.z > b_min.z and player_min.z < b_max.z:
			ghost_block_mesh.visible = false
			has_valid_placement = false
			return

		active_placement_coord = target_coord
		active_placement_normal = place_normal
		has_valid_placement = true

		ghost_block_mesh.visible = true
		ghost_block_mesh.global_position = Vector3(place_pos.x + 0.5, place_pos.y + 0.5, place_pos.z + 0.5)
	else:
		ghost_block_mesh.visible = false
		has_valid_placement = false

func _unhandled_input(event: InputEvent) -> void:
	if crafting_system and crafting_system.is_open:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var hud = get_tree().get_first_node_in_group("game_hud")
		if hud and hud.get("is_radial_menu_open"):
			if hud.has_method("handle_radial_mouse_motion"):
				hud.handle_radial_mouse_motion(event.relative)
			return

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
			var cur_item_id = ""
			if inventory_system and inventory_system.has_method("get_active_item"):
				cur_item_id = inventory_system.get_active_item().get("id", "")
			if cur_item_id == "pickaxe" and pickaxe:
				pickaxe.start_swing()
			else:
				_perform_hand_strike()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click_interaction()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var hud = get_tree().get_first_node_in_group("game_hud")
			if hud and hud.get("is_radial_menu_open"):
				hud.scroll_radial_menu(-1)
			else:
				var prev = active_slot - 1
				if prev < 1: prev = 8
				set_active_slot(prev)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var hud = get_tree().get_first_node_in_group("game_hud")
			if hud and hud.get("is_radial_menu_open"):
				hud.scroll_radial_menu(1)
			else:
				var nxt = active_slot + 1
				if nxt > 8: nxt = 1
				set_active_slot(nxt)

	elif event is InputEventKey and event.is_pressed():
		var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if event.keycode == KEY_ESCAPE or code == KEY_ESCAPE:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.keycode == KEY_Q or code == KEY_Q or event.keycode == 1049:
			var hud = get_tree().get_first_node_in_group("game_hud")
			if hud and hud.has_method("toggle_radial_menu"):
				hud.toggle_radial_menu()
		elif event.keycode == KEY_TAB or code == KEY_TAB or event.keycode == KEY_I or code == KEY_I:
			if inventory_system:
				inventory_system.toggle()
		elif event.keycode == KEY_E or code == KEY_E or event.keycode == 1059:
			_handle_interaction_key()
		elif event.keycode == KEY_C or code == KEY_C or event.keycode == 1057:
			if crafting_system:
				crafting_system.toggle_menu()
		elif event.keycode == KEY_J or code == KEY_J or event.keycode == 1054 or code == 1054:
			var journal = get_tree().get_first_node_in_group("field_journal")
			if journal and journal.has_method("toggle_journal"):
				journal.toggle_journal()
		elif event.keycode == KEY_F or code == KEY_F or event.keycode == 1040:
			# If player is looking directly at a dropped item or interactable prop, allow F as pickup fallback
			var handled_pickup = false
			if camera:
				var space = get_world_3d().direct_space_state
				var q = PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_transform.basis.z * 3.2, 4 | 8, [self])
				q.collide_with_areas = true
				var res = space.intersect_ray(q)
				if res and res.collider != null and (res.collider is DroppedItem or res.collider.is_in_group("dropped_items") or res.collider.is_in_group("interactable")):
					if res.collider.has_method("interact"):
						res.collider.interact(self)
						acoustic_noise_emitted.emit(global_position, 3.0, "interact")
						handled_pickup = true
			if not handled_pickup and lantern and lantern.has_method("toggle_lantern"):
				lantern.toggle_lantern()
		elif (code >= KEY_1 and code <= KEY_8) or (event.keycode >= KEY_1 and event.keycode <= KEY_8):
			var k = code if (code >= KEY_1 and code <= KEY_8) else event.keycode
			set_active_slot(k - KEY_0)

func _handle_interaction_key() -> void:
	# Raycast forward to check if looking at dropped items, lore logs, chests, water springs, or food
	var space = get_world_3d().direct_space_state
	var origin = camera.global_position
	var forward = -camera.global_transform.basis.z
	var end = origin + forward * 3.8
	var query = PhysicsRayQueryParameters3D.create(origin, end, 1 | 4 | 8, [self])
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result = space.intersect_ray(query)

	if result:
		var col = result.collider
		# 1. Dropped Item direct pickup
		if col != null and (col is DroppedItem or col.is_in_group("dropped_items") or col.has_method("interact")):
			if col.has_method("interact"):
				col.interact(self)
				acoustic_noise_emitted.emit(global_position, 3.0, "interact")
				return

		# 2. Scenario props / lore / interactive objects
		if col != null and (col.is_in_group("interactable") or col.has_method("interact")):
			if col.has_method("interact"):
				col.interact(self)
				acoustic_noise_emitted.emit(global_position, 3.0, "interact")
				return

		var sm = get_tree().get_first_node_in_group("scenario_manager")
		if sm and sm.has_method("interact_with_prop"):
			if sm.interact_with_prop(col):
				acoustic_noise_emitted.emit(global_position, 4.0, "interact")
				return

		# 3. Interactive voxel blocks
		var hit_pos = result.position
		var hit_norm = result.normal
		var coord = Vector3i(floor(hit_pos.x - hit_norm.x * 0.4), floor(hit_pos.y - hit_norm.y * 0.4), floor(hit_pos.z - hit_norm.z * 0.4))
		if voxel_world and voxel_world.has_method("get_block"):
			var b = voxel_world.get_block(coord.x, coord.y, coord.z)
			if b == VoxelWorldClass.BlockType.CARGO_CRATE:
				if inventory_system:
					inventory_system.add_item("rations", 2)
					inventory_system.add_item("water", 1)
				lore_opened.emit("LOG_01_OUTPOST")
				return
			elif b == VoxelWorldClass.BlockType.SLATE_BRICK:
				lore_opened.emit("LOG_03_PRECURSOR")
				return
			elif b == VoxelWorldClass.BlockType.WATER_SPRING:
				current_hydration = max_hydration
				acoustic_noise_emitted.emit(global_position, 8.0, "drink")
				vitals_changed.emit(current_health, current_hydration, current_satiety, core_temperature)
				return
			elif b == VoxelWorldClass.BlockType.BIOLUM_MUSHROOM:
				voxel_world.set_block(coord.x, coord.y, coord.z, VoxelWorldClass.BlockType.AIR, true)
				if inventory_system:
					inventory_system.add_item("mushroom", 2)
				acoustic_noise_emitted.emit(hit_pos, 8.0, "harvest")
				return
			elif b == VoxelWorldClass.BlockType.LICHEN_ROOT:
				voxel_world.set_block(coord.x, coord.y, coord.z, VoxelWorldClass.BlockType.AIR, true)
				if inventory_system:
					inventory_system.add_item("lichen", 1)
				acoustic_noise_emitted.emit(hit_pos, 8.0, "harvest")
				return

	# 4. Proximity pickup fallback: if crosshair was slightly off, pick up nearest dropped item within 2.5m
	var items = get_tree().get_nodes_in_group("dropped_items")
	var closest_item: Node3D = null
	var closest_dist: float = 2.5
	for it in items:
		if it is Node3D and is_instance_valid(it):
			var d = global_position.distance_to(it.global_position)
			if d < closest_dist:
				closest_dist = d
				closest_item = it

	if closest_item and closest_item.has_method("interact"):
		closest_item.interact(self)
		acoustic_noise_emitted.emit(global_position, 3.0, "interact")
		return

func _handle_right_click_interaction() -> void:
	if inventory_system == null:
		return

	var item = inventory_system.get_active_item()
	if item.is_empty():
		return

	# 1. Consumable Items
	if item.id == "canteen":
		current_hydration = min(max_hydration, current_hydration + 40.0)
		acoustic_noise_emitted.emit(global_position, 6.0, "drink")
		vitals_changed.emit(current_health, current_hydration, current_satiety, core_temperature)
		return
	elif item.id == "rations":
		current_satiety = min(max_satiety, current_satiety + 50.0)
		inventory_system.consume_active_item(1)
		acoustic_noise_emitted.emit(global_position, 6.0, "eat")
		vitals_changed.emit(current_health, current_hydration, current_satiety, core_temperature)
		return
	elif item.id == "mushroom":
		current_satiety = min(max_satiety, current_satiety + 35.0)
		current_hydration = min(max_hydration, current_hydration + 15.0)
		inventory_system.consume_active_item(1)
		acoustic_noise_emitted.emit(global_position, 6.0, "eat")
		vitals_changed.emit(current_health, current_hydration, current_satiety, core_temperature)
		return
	elif item.id == "water":
		current_hydration = min(max_hydration, current_hydration + 40.0)
		inventory_system.consume_active_item(1)
		acoustic_noise_emitted.emit(global_position, 6.0, "drink")
		vitals_changed.emit(current_health, current_hydration, current_satiety, core_temperature)
		return
	elif item.id == "lichen":
		current_satiety = min(max_satiety, current_satiety + 25.0)
		inventory_system.consume_active_item(1)
		acoustic_noise_emitted.emit(global_position, 6.0, "eat")
		vitals_changed.emit(current_health, current_hydration, current_satiety, core_temperature)
		return
	elif item.id == "journal":
		lore_opened.emit("LOG_01_OUTPOST")
		return

	# 2. Block & Structure Placement
	var reg = InventorySystemClass.ITEM_REGISTRY.get(item.id, {})
	var b_type = reg.get("block_type", 0)
	if b_type > 0 and has_valid_placement:
		if voxel_world == null:
			voxel_world = get_tree().get_first_node_in_group("voxel_world")

		if voxel_world and voxel_world.has_method("place_block_at"):
			if voxel_world.place_block_at(active_placement_coord, active_placement_normal, b_type):
				inventory_system.consume_active_item(1)
				if inventory.has(item.id):
					inventory[item.id] = max(0, inventory[item.id] - 1)
				inventory_changed.emit(inventory)
				var place_center = Vector3(active_placement_coord.x + active_placement_normal.x + 0.5, active_placement_coord.y + active_placement_normal.y + 0.5, active_placement_coord.z + active_placement_normal.z + 0.5)
				acoustic_noise_emitted.emit(place_center, 14.0, "block_place")

func _perform_hand_strike() -> void:
	# Hand punch / mining with lantern
	if camera == null: return
	var space = get_world_3d().direct_space_state
	var origin = camera.global_position
	var forward = -camera.global_transform.basis.z
	var end = origin + forward * 3.5
	var query = PhysicsRayQueryParameters3D.create(origin, end, 1 | 4 | 8, [self])
	var result = space.intersect_ray(query)
	if result:
		_on_pickaxe_hit_landed(result.collider, result.position, result.normal)

func _on_pickaxe_hit_landed(collider: Object, hit_point: Vector3, hit_normal: Vector3) -> void:

	acoustic_noise_emitted.emit(hit_point, 36.0, "pickaxe_impact")
	if collider == null:
		return

	var pick_dmg = pickaxe.damage if pickaxe else 35.0

	# Attack enemy mobs
	if collider.has_method("take_damage"):
		collider.take_damage(pick_dmg, hit_point)
		return

	# Voxel Terrain Excavation
	if voxel_world == null:
		voxel_world = get_tree().get_first_node_in_group("voxel_world")

	var target_coord = Vector3i(floor(hit_point.x - hit_normal.x * 0.4), floor(hit_point.y - hit_normal.y * 0.4), floor(hit_point.z - hit_normal.z * 0.4))
	if voxel_world and voxel_world.has_method("get_block"):
		var b_type = voxel_world.get_block(target_coord.x, target_coord.y, target_coord.z)
		if b_type == VoxelWorldClass.BlockType.AIR:
			return

		var props = VoxelWorldClass.BLOCK_PROPS.get(b_type, {})
		var hardness: float = props.get("hardness", 32.0)

		# Bedrock is 100% indestructible!
		if hardness < 0.0 or b_type == VoxelWorldClass.BlockType.BEDROCK:
			_spawn_bedrock_sparks(hit_point, hit_normal)
			_clear_bedrock_crack_decal()
			return

		_spawn_bedrock_impact(hit_point, hit_normal)

		var sm = get_tree().get_first_node_in_group("sound_manager")
		if sm and sm.has_method("play_sfx"):
			if props.get("drop_item", "") != "":
				sm.play_sfx("pickaxe_ore", hit_point)
			else:
				sm.play_sfx("pickaxe_hit", hit_point)
		acoustic_noise_emitted.emit(hit_point, 14.0, "pickaxe_hit")

		# Check target coordinate continuity
		if target_coord != current_target_voxel:
			current_target_voxel = target_coord
			current_voxel_hits = 0

		current_voxel_hits += 1
		crack_clear_timer = 4.0

		# Differentiated hit scaling based on block hardness, tool type & pickaxe tier
		var is_pickaxe = (active_slot == 2)
		if inventory_system:
			var cur = inventory_system.get_active_item()
			if not cur.is_empty() and cur.id == "pickaxe":
				is_pickaxe = true

		var is_soft = props.get("is_soft", false)
		var hits_needed = 1

		if is_pickaxe:
			var pick_tier = pickaxe.tier if pickaxe else 1
			var tier_multi = 1.0
			if pick_tier == 2:
				tier_multi = 1.8
			elif pick_tier >= 3:
				tier_multi = 3.0
			var base_hits = max(1, int(round(hardness / 13.0)))
			hits_needed = max(1, int(ceil(float(base_hits) / tier_multi)))
		else:
			# Bare hands or non-pickaxe item
			if is_soft:
				hits_needed = max(1, int(round(hardness / 8.0)))
			else:
				# Hard stone & ores take 18 hits with bare hands!
				hits_needed = 18

		# Update progressive crack decal stage (1 to 5)
		var stage = clamp(int(ceil(float(current_voxel_hits) / float(hits_needed) * 5.0)), 1, 5)
		_update_bedrock_crack_decal(hit_point, hit_normal, stage)

		if current_voxel_hits >= hits_needed:
			current_voxel_hits = 0
			_clear_bedrock_crack_decal()
			if sm and sm.has_method("play_sfx"):
				sm.play_sfx("block_break", hit_point)
			if voxel_world.has_method("mine_block"):
				voxel_world.mine_block(target_coord, pick_dmg, hit_point, hit_normal, not is_pickaxe)

func _update_bedrock_crack_decal(pos: Vector3, normal: Vector3, stage: int) -> void:
	if active_bedrock_crack_mesh == null or not is_instance_valid(active_bedrock_crack_mesh):
		active_bedrock_crack_mat = StandardMaterial3D.new()
		active_bedrock_crack_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		active_bedrock_crack_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		active_bedrock_crack_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		active_bedrock_crack_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

		active_bedrock_crack_mesh = MeshInstance3D.new()
		var qm = QuadMesh.new()
		qm.size = Vector2(1.10, 1.10)
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

func apply_subterranean_shudder(intensity: float = 0.35, duration: float = 1.2) -> void:
	if camera == null or not is_instance_valid(camera):
		return
	var tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var orig_rot = camera.rotation
	tw.tween_property(camera, "rotation:z", orig_rot.z + deg_to_rad(intensity * 1.5), duration * 0.25)
	tw.tween_property(camera, "rotation:z", orig_rot.z - deg_to_rad(intensity * 1.2), duration * 0.35)
	tw.tween_property(camera, "rotation:z", orig_rot.z, duration * 0.40)

func _spawn_bedrock_sparks(pos: Vector3, normal: Vector3) -> void:
	var p = CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 16
	p.lifetime = 0.35
	p.direction = normal
	p.spread = 45.0
	p.initial_velocity_min = 3.5
	p.initial_velocity_max = 6.0
	p.color = Color(1.0, 0.92, 0.45)
	get_parent().add_child(p)
	p.global_position = pos + normal * 0.05
	p.emitting = true
	var t = create_tween()
	t.tween_interval(0.4)
	t.tween_callback(p.queue_free)

func _spawn_bedrock_impact(pos: Vector3, normal: Vector3) -> void:
	var p = CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 12
	p.lifetime = 0.4
	p.direction = normal
	p.spread = 50.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.5
	p.color = Color(0.65, 0.70, 0.76)
	get_parent().add_child(p)
	p.global_position = pos + normal * 0.05
	p.emitting = true
	var t = create_tween()
	t.tween_interval(0.45)
	t.tween_callback(p.queue_free)

func add_resource(res_key: String, count: int) -> void:
	inventory[res_key] = inventory.get(res_key, 0) + count
	if inventory_system and inventory_system.has_method("add_item"):
		inventory_system.add_item(res_key, count)
	inventory_changed.emit(inventory)

func take_damage(amount: float, from_pos: Vector3 = Vector3.ZERO) -> void:
	if invulnerability_timer > 0.0:
		return
	invulnerability_timer = 0.85 # 850ms of invulnerability frames to prevent instant death swarms

	current_health = max(0.0, current_health - amount)

	# Physical knockback impulse away from the attacker
	if from_pos != Vector3.ZERO:
		var knock_dir = (global_position - from_pos).normalized()
		knock_dir.y = 0.35
		velocity += knock_dir * 5.5

	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_player_hurt"):
		sm.play_player_hurt()
		sm.set_heartbeat(current_health < 35.0)

	health_changed.emit(current_health, max_health)
	vitals_changed.emit(current_health, current_hydration, current_satiety, core_temperature)
	if current_health <= 0.0:
		_respawn()

func _respawn() -> void:
	current_health = max_health
	current_hydration = max_hydration
	current_satiety = max_satiety
	global_position = Vector3(0.5, 11.2, 0.5)
	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("set_heartbeat"):
		sm.set_heartbeat(false)
	health_changed.emit(current_health, max_health)
	vitals_changed.emit(current_health, current_hydration, current_satiety, core_temperature)

func get_current_depth_meters() -> float:
	return base_depth_meters + ((reference_y - global_position.y) * 8.5)

func get_compass_heading_degrees() -> float:
	return fposmod(-rotation_degrees.y, 360.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if active_bedrock_crack_mesh and is_instance_valid(active_bedrock_crack_mesh):
			active_bedrock_crack_mesh.queue_free()
		if ghost_block_mesh and is_instance_valid(ghost_block_mesh):
			ghost_block_mesh.queue_free()
