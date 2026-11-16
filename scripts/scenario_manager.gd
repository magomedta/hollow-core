# scripts/scenario_manager.gd
class_name ScenarioManager
extends Node3D

## Canonical Scenario & Chapter Progression Director for Hollow Core.
## Coordinates Act I («Шлюзовая Станция 4 и Шурф Эха»):
## 1. Crash Awakening -> Recover Expedition Lantern & Surveyor Pickaxe in any order
## 2. Approach Horizon 1420m -> Discover Airlock Station 4
## 3. Surveyor Workstation -> Inspect Document D-01 (Prokhorov 1894)
## 4. Drainage System -> Open Cast-Iron Valve to drain lower sump
## 5. Echo Shaft Descent -> Reach Drowned Safe EE-06 (Syndicate 104)
## 6. The Lithic Call -> Receive unprompted 11.4 Hz signal from the abyss

const InteractivePropClass = preload("res://scripts/narrative/interactive_prop.gd")
const StoryStateResourceClass = preload("res://scripts/resources/story_state_resource.gd")
const PickaxeClass = preload("res://scripts/pickaxe.gd")

enum Stage {
	SURVIVE_CRASH = 0,         # Need to recover lantern and/or pickaxe
	RECOVERED_PARTIAL_GEAR = 1,# Got one tool, searching for the other
	REACH_STATION_4 = 2,       # Proceed to Airlock Station 4 (Horizon 1420m)
	INSPECT_DOCUMENT_D01 = 3,  # Inspect surveyor desk & read log D-01
	OPERATE_DRAINAGE_VALVE = 4,# Turn cast-iron valve to drain lower sump
	EXPLORE_ECHO_SHAFT = 5,    # Enter Echo Shaft & locate Drowned Safe EE-06
	UNLOCK_SAFE_EE06 = 6,      # Unlock Syndicate Safe (Code 1924) & start transmitter
	ANOMALOUS_SIGNAL = 7       # 11.4 Hz carrier detected from the deep abyss
}

var current_stage: Stage = Stage.SURVIVE_CRASH
var player_ref: CharacterBody3D = null
var hud_ref: CanvasLayer = null
var voxel_world_ref: Node3D = null

var has_lantern: bool = false
var has_pickaxe: bool = false
var has_read_d01: bool = false
var has_turned_valve: bool = false
var has_unlocked_safe: bool = false

# Interactive tool props
var lantern_prop: Area3D = null
var pickaxe_prop: Area3D = null

signal scenario_stage_advanced(new_stage: int)

func _ready() -> void:
	add_to_group("scenario_manager")

func setup(player: CharacterBody3D, hud: CanvasLayer, voxel_world: Node3D) -> void:
	player_ref = player
	hud_ref = hud
	voxel_world_ref = voxel_world

	_spawn_starting_props()
	_apply_stage_directive()

func _spawn_starting_props() -> void:
	var lantern_pos = Vector3(2.2, 11.2, 0.5)
	var pickaxe_pos = Vector3(-3.8, 11.4, 2.0)

	if player_ref and player_ref.global_position.y > 40.0:
		lantern_pos = Vector3(1.5, 57.06, 0.4)
		pickaxe_pos = Vector3(1.2, 57.06, -0.6)

	# 1. Expedition Brass Lantern Prop (InteractiveProp)
	if lantern_prop == null:
		lantern_prop = InteractivePropClass.new()
		lantern_prop.name = "ScenarioLanternProp"
		lantern_prop.prompt_message = "[E] ПОДОБРАТЬ ЭКСПЕДИЦИОННЫЙ ФОНАРЬ"
		lantern_prop.item_grant_id = "lantern"
		lantern_prop.narrative_flag_on_collect = "lantern_recovered"
		lantern_prop.position = lantern_pos

		var scene_res = load("res://models/expedition_lantern.glb")
		if scene_res:
			var inst = scene_res.instantiate()
			inst.scale = Vector3(0.85, 0.85, 0.85)
			lantern_prop.add_child(inst)

		var light = OmniLight3D.new()
		light.light_color = Color(1.0, 0.75, 0.38)
		light.light_energy = 1.1
		light.omni_range = 4.0
		lantern_prop.add_child(light)

		lantern_prop.prop_interacted.connect(_on_lantern_interacted)
		add_child(lantern_prop)

	# 2. Surveyor Pickaxe Prop (InteractiveProp)
	if pickaxe_prop == null:
		pickaxe_prop = InteractivePropClass.new()
		pickaxe_prop.name = "ScenarioPickaxeProp"
		pickaxe_prop.prompt_message = "[E] ИЗВЛЕЧЬ КИРКУ ГЕОЛОГА ИЗ ОБВАЛА"
		pickaxe_prop.item_grant_id = "pickaxe"
		pickaxe_prop.narrative_flag_on_collect = "pickaxe_recovered"
		pickaxe_prop.position = pickaxe_pos
		pickaxe_prop.rotation_degrees = Vector3(0.0, 35.0, 90.0)

		# Build exact same pickaxe model as held in player's hands!
		var tool_data = PickaxeClass.build_tool_mesh(1)
		var tool_instance = tool_data["root"]
		tool_instance.scale = Vector3(1.15, 1.15, 1.15)
		pickaxe_prop.add_child(tool_instance)

		pickaxe_prop.prop_interacted.connect(_on_pickaxe_interacted)
		add_child(pickaxe_prop)

func _on_lantern_interacted(_p: CharacterBody3D) -> void:
	has_lantern = true
	print("[ScenarioManager] Expedition Lantern collected!")
	_check_starting_gear()

func _on_pickaxe_interacted(_p: CharacterBody3D) -> void:
	has_pickaxe = true
	print("[ScenarioManager] Surveyor Pickaxe collected!")
	_check_starting_gear()

func _check_starting_gear() -> void:
	if has_lantern and has_pickaxe:
		current_stage = Stage.REACH_STATION_4
	elif has_lantern or has_pickaxe:
		current_stage = Stage.RECOVERED_PARTIAL_GEAR

	_apply_stage_directive()
	scenario_stage_advanced.emit(int(current_stage))

## Generic interaction hook invoked by PlayerController
func interact_with_prop(prop: Node) -> bool:
	if prop == null:
		return false

	if prop == lantern_prop or (prop.has_meta("is_scenario_lantern")):
		if lantern_prop and is_instance_valid(lantern_prop):
			lantern_prop.interact(player_ref)
			return true
	elif prop == pickaxe_prop or (prop.has_meta("is_scenario_pickaxe")):
		if pickaxe_prop and is_instance_valid(pickaxe_prop):
			pickaxe_prop.interact(player_ref)
			return true

	# Direct handling for Document D-01
	if prop.has_method("get_document_id") or prop.name.begins_with("Document_D01"):
		notify_document_d01_read()
		return true

	# Direct handling for Drainage Valve
	if prop.name.begins_with("DrainageValve") or prop.has_method("operate_valve"):
		notify_drainage_valve_operated()
		return true

	# Direct handling for EE-06 Safe
	if prop.name.begins_with("EE06") or prop.has_method("unlock_safe"):
		notify_safe_ee06_unlocked()
		return true

	return false

func _process(_delta: float) -> void:
	if player_ref == null:
		return

	var pos = player_ref.global_position

	# Spatial progression trigger: Reaching Airlock Station 4
	if current_stage == Stage.REACH_STATION_4:
		if pos.x >= 10.0 and pos.y <= 46.0 and pos.y >= 36.0:
			current_stage = Stage.INSPECT_DOCUMENT_D01
			_apply_stage_directive()
			scenario_stage_advanced.emit(int(current_stage))

			var tree = get_tree() if is_inside_tree() else null
			if tree:
				var nm = tree.get_first_node_in_group("narrative_manager")
				if nm and nm.has_method("trigger_world_event"):
					nm.trigger_world_event("station4_entered")

	# Spatial triggers for Echo Shaft, Abandoned Camp & Lower Sump
	var tree = get_tree() if is_inside_tree() else null
	if tree:
		var nm = tree.get_first_node_in_group("narrative_manager")
		if nm and nm.has_method("trigger_world_event") and nm.get("story_state"):
			# Zone D: Abandoned Camp (X: -26..-10, Y: 24..30, Z: -5..12)
			if pos.x <= -10.0 and pos.y <= 30.0 and pos.y >= 23.0 and pos.z >= -6.0:
				if not nm.story_state.has_flag("camp_discovered"):
					nm.trigger_world_event("camp_discovered")
			# Zone E: Lower Sump (X: 11..19, Y: 26..32, Z: -17..-7)
			if pos.x >= 11.0 and pos.y <= 32.0 and pos.y >= 26.0 and pos.z <= -7.0:
				if not nm.story_state.has_flag("sump_reached"):
					nm.trigger_world_event("sump_reached")

func notify_document_d01_read() -> void:
	if not has_read_d01:
		has_read_d01 = true
		var tree = get_tree() if is_inside_tree() else null
		if tree:
			var nm = tree.get_first_node_in_group("narrative_manager")
			if nm:
				if nm.has_method("inspect_document"):
					nm.inspect_document("DOC-01")
				if nm.has_method("trigger_world_event"):
					nm.trigger_world_event("document_d01_read")
		if current_stage <= Stage.INSPECT_DOCUMENT_D01:
			current_stage = Stage.OPERATE_DRAINAGE_VALVE
			_apply_stage_directive()
			scenario_stage_advanced.emit(int(current_stage))

func notify_drainage_valve_operated() -> void:
	if not has_turned_valve:
		has_turned_valve = true
		var tree = get_tree() if is_inside_tree() else null
		if tree:
			var nm = tree.get_first_node_in_group("narrative_manager")
			if nm and nm.has_method("trigger_world_event"):
				nm.trigger_world_event("drainage_valve_opened")
				nm.trigger_world_event("sump_drained")
		if current_stage <= Stage.OPERATE_DRAINAGE_VALVE:
			current_stage = Stage.EXPLORE_ECHO_SHAFT
			_apply_stage_directive()
			scenario_stage_advanced.emit(int(current_stage))

func notify_safe_ee06_unlocked() -> void:
	if not has_unlocked_safe:
		has_unlocked_safe = true
		current_stage = Stage.ANOMALOUS_SIGNAL
		_apply_stage_directive()
		scenario_stage_advanced.emit(int(current_stage))

		var tree = get_tree() if is_inside_tree() else null
		if tree:
			var nm = tree.get_first_node_in_group("narrative_manager")
			if nm:
				if nm.has_method("register_secret"):
					nm.register_secret("EE-06")
				if nm.has_method("play_audiolog"):
					nm.play_audiolog("AUD-07")
				if nm.has_method("inspect_document"):
					nm.inspect_document("DOC-06")
				if nm.has_method("unlock_secret_room"):
					nm.unlock_secret_room("SEC-01")
				if nm.has_method("unlock_clue"):
					nm.unlock_clue("CH-01", 3)
					nm.unlock_clue("CH-05", 1)
				if nm.has_method("trigger_world_event"):
					nm.trigger_world_event("ee06_safe_unlocked")
					nm.trigger_world_event("signal_11_4_received")

			var smm = tree.get_first_node_in_group("sound_memory_manager")
			if smm and smm.has_method("_trigger_infrasound_resonance"):
				smm._trigger_infrasound_resonance()

func _apply_stage_directive() -> void:
	var tree = get_tree() if is_inside_tree() else null
	var nm = tree.get_first_node_in_group("narrative_manager") if tree else null

	var obj_id = ""
	var directive_text = ""
	var text_color = Color(0.85, 0.88, 0.92)

	match current_stage:
		Stage.SURVIVE_CRASH:
			obj_id = "OBJ_01_GEAR"
			directive_text = "ЗАДАЧА: Найти аварийный фонарь и кирку геолога среди обломков"
			text_color = Color(1.0, 0.82, 0.40)
		Stage.RECOVERED_PARTIAL_GEAR:
			obj_id = "OBJ_01_GEAR"
			directive_text = "ЗАДАЧА: Собрать оставшееся снаряжение в штреке"
			text_color = Color(0.95, 0.78, 0.35)
		Stage.REACH_STATION_4:
			obj_id = "OBJ_02_STATION4"
			directive_text = "ЗАДАЧА: Пройти по ледниковой штольне к Шлюзовой Станции 4 (1420м)"
			text_color = Color(0.70, 0.82, 0.95)
		Stage.INSPECT_DOCUMENT_D01:
			obj_id = "OBJ_03_LOG_D01"
			directive_text = "ЗАДАЧА: Осмотреть рабочий стол маркшейдера и прочесть Журнал (D-01)"
			text_color = Color(0.92, 0.86, 0.70)
		Stage.OPERATE_DRAINAGE_VALVE:
			obj_id = "OBJ_04_DRAIN_VALVE"
			directive_text = "ЗАДАЧА: Повернуть чугунный вентиль, чтобы осушить нижний коллектор"
			text_color = Color(0.88, 0.55, 0.35)
		Stage.EXPLORE_ECHO_SHAFT:
			obj_id = "OBJ_05_ECHO_SHAFT"
			directive_text = "ЗАДАЧА: Спуститься в Шурф Эха и разыскать затонувший сейф Синдиката 104"
			text_color = Color(0.45, 0.85, 0.95)
		Stage.UNLOCK_SAFE_EE06:
			obj_id = "OBJ_06_UNLOCK_SAFE"
			directive_text = "ЗАДАЧА: Вскрыть сейф EE-06 (код 1924) и запустить аварийный передатчик"
			text_color = Color(0.95, 0.85, 0.45)
		Stage.ANOMALOUS_SIGNAL:
			obj_id = "OBJ_07_ANOMALOUS_SIGNAL"
			directive_text = "РЕЗОНАНС: Зафиксирован сигнал 11,4 Гц из Бездны. Следовать в глубину."
			text_color = Color(0.95, 0.40, 0.30)

	if nm:
		nm.set_objective(obj_id, directive_text)

	if hud_ref:
		var d_lbl: Label = hud_ref.get("directive_label")
		if d_lbl:
			d_lbl.text = directive_text
			d_lbl.add_theme_color_override("font_color", text_color)
