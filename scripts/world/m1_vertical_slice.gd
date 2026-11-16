# scripts/world/m1_vertical_slice.gd
extends Node3D

## Master Controller for Hollow Core — Milestone 1 (M1): Vertical Slice
## «Шлюзовая Станция 4 и Шурф Эха» (Airlock Station 4 & Echo Shaft).
## Coordinates 256m geology, organic mining, persistent world state,
## the brass lantern with fuel, Document D-01, Easter Egg EE-06,
## EV-01 / EV-02 psychological anomalies, and the diegetic Anti-AI HUD.

const WorldConfigClass = preload("res://scripts/world/world_config.gd")
const VoxelWorldClass = preload("res://scripts/voxel_world.gd")
const PlayerControllerClass = preload("res://scripts/player_controller.gd")
const SoundManagerClass = preload("res://scripts/sound_manager.gd")
const SoundMemoryManagerClass = preload("res://scripts/audio/sound_memory_manager.gd")
const TerrainModifierClass = preload("res://scripts/terrain/terrain_modifier.gd")
const TerrainPersistenceClass = preload("res://scripts/terrain/terrain_persistence.gd")
const M1LevelManagerClass = preload("res://scripts/world/m1_level_manager.gd")
const DocumentViewerClass = preload("res://scripts/narrative/document_viewer.gd")
const AnomalyDirectorClass = preload("res://scripts/horror/anomaly_director.gd")
const AnchorPlacementClass = preload("res://scripts/gameplay/anchor_placement.gd")
const RockAnchorClass = preload("res://scripts/gameplay/rock_anchor.gd")
const BiomeManagerClass = preload("res://scripts/world/biomes/biome_manager.gd")
const NarrativeManagerClass = preload("res://scripts/autoloads/narrative_manager.gd")
const ScenarioManagerClass = preload("res://scripts/scenario_manager.gd")
const FieldJournalViewerClass = preload("res://scripts/narrative/field_journal.gd")
const SanityManagerClass = preload("res://scripts/horror/sanity_manager.gd")
const OrnateUIClass = preload("res://scripts/ui/ornate_ui.gd")
const SegmentedProgressBarClass = preload("res://scripts/ui/segmented_bar.gd")
const SleekHUDClass = preload("res://scripts/ui/sleek_hud.gd")

var world_config: Resource
var sound_manager: Node
var sound_memory_manager: Node
var biome_manager: Node
var voxel_world: Node3D
var terrain_modifier: Node
var level_manager: Node3D
var document_viewer: CanvasLayer
var field_journal: CanvasLayer
var anomaly_director: Node
var sanity_manager: Node
var anchor_placement: Node3D
var player: CharacterBody3D
var world_env: WorldEnvironment
var narrative_manager: Node
var scenario_manager: Node3D

# Sleek Minimalist Subterranean HUD
var hud_canvas: CanvasLayer
var sleek_hud_refs: Dictionary = {}
var depth_label: Label
var compass_label: Label
var lantern_fuel_label: Label
var lantern_fuel_bar: Control
var objective_label: Label
var journal_hint_label: Label
var interact_prompt_label: Label
var interact_prompt_panel: Control
var save_notice_label: Label

# Story Progression State
var is_d01_read: bool = false
var is_valve_turned: bool = false
var is_ee06_unlocked: bool = false

func _ready() -> void:
	print("[M1 Vertical Slice] Initializing 'Airlock Station 4 & Echo Shaft'...")
	world_config = WorldConfigClass.get_default()

	_setup_audio()
	_setup_environment()
	_setup_world()
	_setup_narrative_and_horror()
	_setup_diegetic_hud()
	_setup_player()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	print("[M1 Vertical Slice] Level Ready! Player spawned at Approach Tunnel.")

func _setup_audio() -> void:
	sound_manager = SoundManagerClass.new()
	sound_manager.name = "SoundManager"
	add_child(sound_manager)

	sound_memory_manager = SoundMemoryManagerClass.new()
	sound_memory_manager.name = "SoundMemoryManager"
	add_child(sound_memory_manager)

func _setup_environment() -> void:
	world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"

	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.020, 0.028, 1.0) # Deep subterranean atmosphere
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.20, 0.25, 0.32, 1.0) # Soft subterranean cold slate bounce
	env.ambient_light_energy = 0.38
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.15
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = Color(0.16, 0.22, 0.28, 1.0) # Eerie subterranean mist
	env.fog_density = 0.020 # Visible silhouettes up to 45m (classic Alpha fog feel)
	env.fog_aerial_perspective = 0.65

	world_env.environment = env
	add_child(world_env)

	# Subterranean Biome Coordinator
	biome_manager = BiomeManagerClass.new()
	biome_manager.name = "BiomeManager"
	biome_manager.world_environment = world_env
	biome_manager.sound_memory_manager = sound_memory_manager
	add_child(biome_manager)

func _setup_world() -> void:
	voxel_world = VoxelWorldClass.new()
	voxel_world.name = "VoxelWorld"
	voxel_world.world_config = world_config
	voxel_world.add_to_group("voxel_world")
	add_child(voxel_world)

	terrain_modifier = TerrainModifierClass.new(voxel_world, world_config)
	terrain_modifier.name = "TerrainModifier"
	add_child(terrain_modifier)
	voxel_world.terrain_modifier = terrain_modifier

	level_manager = M1LevelManagerClass.new(voxel_world, world_config)
	level_manager.name = "M1LevelManager"
	add_child(level_manager)
	level_manager.build_vertical_slice_world()

	# Re-mesh all carved chunks immediately so the subterranean world is rendered
	voxel_world.remesh_all_active_chunks()

	# Listen to drainage valve
	if level_manager.drainage_valve_prop:
		level_manager.drainage_valve_prop.valve_turned.connect(func():
			is_valve_turned = true
			_on_drainage_valve_opened()
			if scenario_manager:
				scenario_manager.notify_drainage_valve_operated()
		)

	# Listen to D-01
	if level_manager.doc_d01_prop:
		level_manager.doc_d01_prop.document_read_event.connect(func(doc_id):
			is_d01_read = true
			print("[M1 Narrative] Document read: ", doc_id)
			if scenario_manager:
				scenario_manager.notify_document_d01_read()
		)

	# Listen to EE-06
	if level_manager.ee06_safe_prop:
		level_manager.ee06_safe_prop.safe_opened.connect(func():
			is_ee06_unlocked = true
			print("[M1 Narrative] Easter Egg EE-06 Safe opened!")
			if scenario_manager:
				scenario_manager.notify_safe_ee06_unlocked()
		)

func _setup_narrative_and_horror() -> void:
	narrative_manager = NarrativeManagerClass.new()
	narrative_manager.name = "NarrativeManager"
	add_child(narrative_manager)

	document_viewer = DocumentViewerClass.new()
	document_viewer.name = "DocumentViewer"
	add_child(document_viewer)

	field_journal = FieldJournalViewerClass.new()
	field_journal.name = "FieldJournalViewer"
	add_child(field_journal)

	anomaly_director = AnomalyDirectorClass.new()
	anomaly_director.name = "AnomalyDirector"
	add_child(anomaly_director)

	sanity_manager = SanityManagerClass.new()
	sanity_manager.name = "SanityManager"
	add_child(sanity_manager)

	# Register Abandoned Camp (Zone D) as Safe Refuge
	var camp_safe_box = AABB(Vector3(-25, 24, -5), Vector3(18, 10, 18))
	anomaly_director.add_safe_zone(camp_safe_box)

	anchor_placement = AnchorPlacementClass.new()
	anchor_placement.name = "AnchorPlacementComponent"
	add_child(anchor_placement)

	scenario_manager = ScenarioManagerClass.new()
	scenario_manager.name = "ScenarioManager"
	add_child(scenario_manager)

func _setup_player() -> void:
	player = PlayerControllerClass.new()
	player.name = "Player"
	player.add_to_group("player")
	add_child(player)

	# Spawn at Zone A (Approach tunnel)
	# Tunnel extends along +X (towards Station 4 at x=12).
	# Face +X (-90 deg around Y) and tilt camera down slightly (-14 deg) towards the lantern and pickaxe on the floor.
	player.global_position = Vector3(0.4, 57.0, 0.0)
	player.rotation_degrees = Vector3(0, -90, 0)
	if player.neck:
		player.neck.rotation_degrees = Vector3(-14.0, 0, 0)
	player.voxel_world = voxel_world

	sound_memory_manager.set_player(player)
	anomaly_director.set_player(player)
	if sanity_manager:
		sanity_manager.set_player(player)
	anchor_placement.set_player(player)
	if biome_manager:
		biome_manager.target_player = player

	scenario_manager.setup(player, hud_canvas, voxel_world)

	# Connect acoustic noise
	player.acoustic_noise_emitted.connect(func(pos, rad, n_type):
		var snd_id = "footstep_stone" if n_type == "footstep" else "pickaxe_stone"
		sound_memory_manager.record_event(n_type, pos, snd_id, clamp(rad / 20.0, 0.2, 1.0))
	)

	# Starting equipment: Hands empty (tools recovered from crash rubble), 4 Rock Anchors, 2 Rations, 1 Canteen
	if player.inventory_system:
		player.inventory_system.add_item("timber", 8)
		player.inventory_system.add_item("anchor", 4)
		player.inventory_system.add_item("canteen", 1)
		player.inventory_system.add_item("rations", 2)
	player.set_active_slot(8) # Hands start empty after crash

func _setup_diegetic_hud() -> void:
	hud_canvas = CanvasLayer.new()
	hud_canvas.name = "DiegeticHUD"
	hud_canvas.layer = 90
	add_child(hud_canvas)

	sleek_hud_refs = SleekHUDClass.build_hud(hud_canvas)
	depth_label = sleek_hud_refs.get("depth_label")
	compass_label = sleek_hud_refs.get("compass_label")
	objective_label = sleek_hud_refs.get("objective_label")
	save_notice_label = sleek_hud_refs.get("save_notice")
	interact_prompt_panel = sleek_hud_refs.get("prompt_ctrl")
	interact_prompt_label = sleek_hud_refs.get("prompt_label")

func _process(_delta: float) -> void:
	_update_hud()
	_handle_input_keys()

func _update_hud() -> void:
	if player == null:
		return

	var pos = player.global_position
	var depth_val = 1420.0 + (50.0 - pos.y)
	var stratum_name = "НЕИЗВЕСТНЫЙ ГОРИЗОНТ"
	if biome_manager and biome_manager.current_biome:
		stratum_name = biome_manager.current_biome.display_name.to_upper()

	var cam = player.camera if player else null
	var deg = 0
	if cam:
		deg = int(posmod(-cam.global_rotation_degrees.y, 360.0))

	var fuel_pct = 0.0
	var is_lit = false
	if player.lantern:
		fuel_pct = (player.lantern.current_fuel / player.lantern.max_fuel) * 100.0
		is_lit = player.lantern.is_lit

	var act_obj = "Найти аварийный фонарь и кирку геолога среди обломков"
	if narrative_manager and narrative_manager.story_state:
		var n_obj = narrative_manager.story_state.active_objective_text
		if n_obj != "":
			act_obj = n_obj

	SleekHUDClass.update_display(
		sleek_hud_refs,
		int(round(depth_val)),
		stratum_name,
		deg,
		fuel_pct,
		is_lit,
		act_obj
	)

	_check_interaction_prompt()

func _check_interaction_prompt() -> void:
	if player == null or player.camera == null or interact_prompt_label == null or interact_prompt_panel == null:
		return

	var space = get_world_3d().direct_space_state
	var origin = player.camera.global_position
	var forward = -player.camera.global_transform.basis.z
	var end = origin + forward * 3.8

	var query = PhysicsRayQueryParameters3D.create(origin, end, 1 | 4 | 8, [player])
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var hit = space.intersect_ray(query)

	var reticle_rect: TextureRect = sleek_hud_refs.get("reticle_rect")

	if hit and hit.collider:
		var col = hit.collider
		if col.has_method("get_interaction_prompt"):
			var p_text = col.get_interaction_prompt().to_upper()
			if not p_text.begins_with("[E]"):
				p_text = "[E] " + p_text
			interact_prompt_label.text = p_text
			interact_prompt_panel.visible = true
			if reticle_rect:
				var act_tex = SleekHUDClass.get_texture("textures/ui_sleek/sleek_reticle_interact.png")
				if act_tex:
					reticle_rect.texture = act_tex
			return

	interact_prompt_panel.visible = false
	if reticle_rect:
		var def_tex = SleekHUDClass.get_texture("textures/ui_sleek/sleek_reticle.png")
		if def_tex:
			reticle_rect.texture = def_tex

func _on_drainage_valve_opened() -> void:
	print("[M1 Level] Drainage valve opened! Draining lower sump...")
	# Carve drainage discharge flow and clear any water blocks in Sump
	for x in range(12, 19):
		for z in range(-16, -8):
			for y in range(29, 34):
				if voxel_world.get_block(x, y, z) == VoxelWorld.BlockType.WATER_SPRING:
					voxel_world.set_block(x, y, z, VoxelWorld.BlockType.AIR, true)

func _handle_input_keys() -> void:
	if Input.is_key_pressed(KEY_F5):
		save_vertical_slice_state("m1_slot")
	elif Input.is_key_pressed(KEY_F9):
		load_vertical_slice_state("m1_slot")

## Saves complete vertical slice progress
func save_vertical_slice_state(slot_name: String = "m1_slot") -> bool:
	var ok_vox = voxel_world.save_world_state(slot_name)

	# Save placed anchors and story state into manifest JSON
	var dir_path = "user://saves/%s/" % slot_name
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(dir_path):
		dir.make_dir_recursive(dir_path)

	var story_data = {
		"player_pos": [player.global_position.x, player.global_position.y, player.global_position.z],
		"lantern_fuel": player.lantern.current_fuel if player.lantern else 100.0,
		"is_d01_read": is_d01_read,
		"is_valve_turned": is_valve_turned,
		"is_ee06_unlocked": is_ee06_unlocked,
		"anchors": []
	}

	var anchors = get_tree().get_nodes_in_group("placed_anchors")
	for anc in anchors:
		if anc.has_method("serialize"):
			story_data["anchors"].append(anc.serialize())

	var f = FileAccess.open(dir_path + "m1_state.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(story_data, "\t"))
		f.close()

	if narrative_manager and narrative_manager.has_method("save_state"):
		narrative_manager.save_state()

	_show_notice("СОХРАНЕНО: %s" % slot_name)
	return ok_vox

## Restores complete vertical slice progress
func load_vertical_slice_state(slot_name: String = "m1_slot") -> bool:
	var ok_vox = voxel_world.load_world_state(slot_name)

	var path = "user://saves/%s/m1_state.json" % slot_name
	if not FileAccess.file_exists(path):
		_show_notice("ЗАГРУЖЕНО (ТОЛЬКО ВОКСЕЛИ)")
		return ok_vox

	var f = FileAccess.open(path, FileAccess.READ)
	if f:
		var text = f.get_as_text()
		f.close()
		var json = JSON.new()
		if json.parse(text) == OK:
			var data = json.data
			if player and data.has("player_pos"):
				var pp = data["player_pos"]
				player.global_position = Vector3(pp[0], pp[1], pp[2])
			if player and player.lantern and data.has("lantern_fuel"):
				player.lantern.current_fuel = data["lantern_fuel"]

			is_d01_read = data.get("is_d01_read", false)
			is_valve_turned = data.get("is_valve_turned", false)
			is_ee06_unlocked = data.get("is_ee06_unlocked", false)

			if is_valve_turned and level_manager.drainage_valve_prop:
				level_manager.drainage_valve_prop.is_turned = true
			if is_ee06_unlocked and level_manager.ee06_safe_prop:
				level_manager.ee06_safe_prop.is_unlocked = true

			# Restore anchors
			var existing_anchors = get_tree().get_nodes_in_group("placed_anchors")
			for ea in existing_anchors:
				if ea.name != "Sample_Expedition_Anchor":
					ea.queue_free()

			for anc_data in data.get("anchors", []):
				var anc = RockAnchorClass.deserialize(anc_data)
				level_manager.props_container.add_child(anc)

	if narrative_manager and narrative_manager.has_method("load_state"):
		narrative_manager.load_state()

	_show_notice("ЗАГРУЖЕНО: %s" % slot_name)
	return ok_vox

func _show_notice(text: String) -> void:
	if save_notice_label:
		save_notice_label.text = text
		var t = get_tree().create_timer(3.0)
		t.timeout.connect(func():
			if save_notice_label: save_notice_label.text = ""
		)
