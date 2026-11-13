# scripts/narrative/quest_manager.gd
class_name QuestManager
extends Node

## Central Quest Coordinator for Hollow Core.
## Manages active quest state, sub-objectives, dependency resolution,
## persistence through StoryStateResource, and synchronization with the Diegetic HUD.
## Supports non-linear / out-of-order execution without softlocking.

const QuestRegistryClass = preload("res://scripts/narrative/quest_registry.gd")
const StoryStateResourceClass = preload("res://scripts/resources/story_state_resource.gd")

signal quest_started(quest_id: String, quest_data: Dictionary)
signal quest_objective_updated(quest_id: String, objective_key: String, is_done: bool)
signal quest_completed(quest_id: String, next_quest_id: String)
signal active_quest_changed(quest_id: String, directive_text: String)

var story_state: Resource = null
var current_quest_id: String = "Q00_CRASH_SURVIVAL"

func setup(state: Resource) -> void:
	story_state = state
	_sync_from_story_state()

func _ready() -> void:
	add_to_group("quest_manager")

func _sync_from_story_state() -> void:
	if story_state == null:
		return

	# Find current uncompleted quest
	var candidate_id = ""
	for q_id in QuestRegistryClass.get_all_quest_ids():
		if not story_state.is_quest_completed(q_id):
			candidate_id = q_id
			break
	if candidate_id != "":
		current_quest_id = candidate_id

	# Ensure current quest is registered in story_state and evaluate sub-objectives
	var q_data = QuestRegistryClass.get_quest(current_quest_id)
	var sub_init = {}
	var existing_sub = {}
	if story_state.active_quests.has(current_quest_id):
		existing_sub = story_state.active_quests[current_quest_id].get("sub_objectives", {})

	for sub_k in q_data.get("sub_objectives", {}):
		var prev = existing_sub.get(sub_k, false)
		var from_state = _evaluate_sub_objective_from_state(current_quest_id, sub_k)
		sub_init[sub_k] = (prev or from_state)

	story_state.record_quest_stage(current_quest_id, 0, sub_init)
	story_state.active_objective_id = current_quest_id
	story_state.active_objective_text = q_data.get("directive", "")

	_emit_active_directive()

	# If all sub-objectives are already satisfied from saved flags, complete it
	_check_and_auto_complete_current()

func get_current_quest() -> Dictionary:
	var base_data = QuestRegistryClass.get_quest(current_quest_id).duplicate(true)
	if story_state and story_state.active_quests.has(current_quest_id):
		var state_entry = story_state.active_quests[current_quest_id]
		var sub_state = state_entry.get("sub_objectives", {})
		if base_data.has("sub_objectives"):
			for sub_k in base_data["sub_objectives"]:
				base_data["sub_objectives"][sub_k]["done"] = sub_state.get(sub_k, false)
	return base_data

func set_sub_objective(quest_id: String, sub_key: String, done: bool = true) -> void:
	if story_state == null:
		return

	if not story_state.active_quests.has(quest_id):
		story_state.record_quest_stage(quest_id, 0, { sub_key: done })
	else:
		story_state.active_quests[quest_id]["sub_objectives"][sub_key] = done

	quest_objective_updated.emit(quest_id, sub_key, done)

	# Check if all sub-objectives completed
	var q_def = QuestRegistryClass.get_quest(quest_id)
	var all_done = true
	var current_sub = story_state.active_quests[quest_id].get("sub_objectives", {})
	for k in q_def.get("sub_objectives", {}):
		if not current_sub.get(k, false):
			all_done = false
			break

	if all_done and not q_def.get("sub_objectives", {}).is_empty():
		complete_quest(quest_id)

func complete_quest(quest_id: String) -> void:
	if story_state == null:
		return

	story_state.record_quest_completed(quest_id)
	var q_def = QuestRegistryClass.get_quest(quest_id)
	var comp_flag = q_def.get("completion_flag", "")
	if comp_flag != "":
		story_state.mark_flag(comp_flag, true)

	var next_id = q_def.get("next_quest", "")
	print("[QuestManager] Quest Completed: %s -> Next: %s" % [quest_id, next_id])
	quest_completed.emit(quest_id, next_id)

	if next_id != "":
		start_quest(next_id)

func start_quest(quest_id: String) -> void:
	current_quest_id = quest_id
	var q_def = QuestRegistryClass.get_quest(quest_id)
	var sub_init = {}

	# Retroactively check if sub-objectives were already achieved (out-of-order play)
	for sub_k in q_def.get("sub_objectives", {}):
		sub_init[sub_k] = _evaluate_sub_objective_from_state(quest_id, sub_k)

	if story_state:
		story_state.record_quest_stage(quest_id, 0, sub_init)
		story_state.active_objective_id = quest_id
		story_state.active_objective_text = q_def.get("directive", "")

	quest_started.emit(quest_id, q_def)
	_emit_active_directive()

	_check_and_auto_complete_current()

func _check_and_auto_complete_current() -> void:
	if story_state == null:
		return
	var q_def = QuestRegistryClass.get_quest(current_quest_id)
	var subs = q_def.get("sub_objectives", {})
	if subs.is_empty():
		return

	var current_sub = story_state.active_quests.get(current_quest_id, {}).get("sub_objectives", {})
	var all_done = true
	for k in subs:
		if not current_sub.get(k, false):
			all_done = false
			break
	if all_done:
		complete_quest(current_quest_id)

func _emit_active_directive() -> void:
	var q_def = QuestRegistryClass.get_quest(current_quest_id)
	var dir_text = q_def.get("directive", "Обследовать штольню")
	active_quest_changed.emit(current_quest_id, dir_text)

## Evaluates whether a sub-objective is satisfied based on current story state
func _evaluate_sub_objective_from_state(quest_id: String, sub_key: String) -> bool:
	if story_state == null:
		return false

	match quest_id:
		"Q00_CRASH_SURVIVAL":
			if sub_key == "lantern":
				return story_state.has_flag("lantern_recovered")
			elif sub_key == "pickaxe":
				return story_state.has_flag("pickaxe_recovered")
		"Q01_APPROACH_STATION4":
			if sub_key == "enter_station":
				return story_state.has_flag("station4_entered")
		"Q02_SURVEYOR_WORKSTATION":
			if sub_key == "read_d01":
				return story_state.has_flag("document_d01_read") or story_state.collected_documents.has("DOC-01")
		"Q03_DRAINAGE_RESTORATION":
			if sub_key == "turn_valve":
				return story_state.has_flag("drainage_valve_opened") or story_state.has_flag("sump_drained")
		"Q04_ECHO_SHAFT_DESCENT":
			if sub_key == "reach_camp":
				return story_state.has_flag("camp_discovered")
			elif sub_key == "descend_sump":
				return story_state.has_flag("sump_reached") or story_state.has_flag("ee06_safe_unlocked")
		"Q05_SYNDICATE_SAFE":
			if sub_key == "unlock_safe":
				return story_state.has_flag("ee06_safe_unlocked")
			elif sub_key == "take_resonator":
				return story_state.has_flag("ee06_safe_unlocked")
		"Q06_ABYSS_CALL":
			if sub_key == "witness_signal":
				return story_state.has_flag("signal_11_4_received")
		"Q07_SUBSTATION_REPAIR":
			if sub_key == "repair_transformer":
				return story_state.has_flag("substation_online") or story_state.has_flag("transformer_repaired")
			elif sub_key == "start_winch":
				return story_state.has_flag("substation_online") or story_state.has_flag("winch_started")
		"Q08_SYNDICATE_CONSPIRACY":
			if sub_key == "find_protocol":
				return story_state.has_flag("syndicate_conspiracy_revealed") or story_state.collected_documents.has("DOC-02") or story_state.played_audiologs.has("AUD-15")
		"Q09_KELLER_SUSPENSION":
			if sub_key == "cross_chasm":
				return story_state.has_flag("keller_weiss_entered") or story_state.has_flag("keller_bridge_aligned")
			elif sub_key == "reach_townhall":
				return story_state.has_flag("keller_weiss_entered")
		"Q10_THE_GREAT_HARMONIZATION":
			if sub_key == "listen_organ_tape":
				return story_state.has_flag("harmonization_truth_uncovered") or story_state.played_audiologs.has("AUD-05")
		"Q11_GEOTHERMAL_IGNITION":
			if sub_key == "open_steam_valve":
				return story_state.has_flag("nexus_turbine_started") or story_state.has_flag("steam_valve_opened")
			elif sub_key == "spool_turbine":
				return story_state.has_flag("nexus_turbine_started")
		"Q12_ELEONORA_MIRAGE":
			if sub_key == "inspect_room":
				return story_state.has_flag("eleonora_truth_understood") or story_state.collected_documents.has("DOC-15")
			elif sub_key == "hear_echo":
				return story_state.has_flag("eleonora_truth_understood") or story_state.played_audiologs.has("AUD-19")
		"Q13_PHASE_CALIBRATION":
			if sub_key == "align_node_alpha":
				return story_state.has_flag("anchor_phase_calibrated") or story_state.has_flag("node_alpha_aligned")
			elif sub_key == "align_node_beta":
				return story_state.has_flag("anchor_phase_calibrated") or story_state.has_flag("node_beta_aligned")
			elif sub_key == "align_node_gamma":
				return story_state.has_flag("anchor_phase_calibrated") or story_state.has_flag("node_gamma_aligned")
		"Q14_THE_FINAL_DECISION":
			if sub_key == "trigger_climax":
				return story_state.has_flag("game_climax_resolved") or story_state.achieved_ending != ""

	return false

## Listener hook for world flags changed in NarrativeManager
func on_world_flag_updated(flag_name: String, _val: bool) -> void:
	match flag_name:
		"lantern_recovered":
			set_sub_objective("Q00_CRASH_SURVIVAL", "lantern", true)
		"pickaxe_recovered":
			set_sub_objective("Q00_CRASH_SURVIVAL", "pickaxe", true)
		"station4_entered":
			set_sub_objective("Q01_APPROACH_STATION4", "enter_station", true)
		"document_d01_read":
			set_sub_objective("Q02_SURVEYOR_WORKSTATION", "read_d01", true)
		"drainage_valve_opened", "sump_drained":
			set_sub_objective("Q03_DRAINAGE_RESTORATION", "turn_valve", true)
		"camp_discovered":
			set_sub_objective("Q04_ECHO_SHAFT_DESCENT", "reach_camp", true)
		"sump_reached":
			set_sub_objective("Q04_ECHO_SHAFT_DESCENT", "descend_sump", true)
		"echo_shaft_explored":
			set_sub_objective("Q04_ECHO_SHAFT_DESCENT", "reach_camp", true)
			set_sub_objective("Q04_ECHO_SHAFT_DESCENT", "descend_sump", true)
		"ee06_safe_unlocked":
			set_sub_objective("Q04_ECHO_SHAFT_DESCENT", "descend_sump", true)
			set_sub_objective("Q05_SYNDICATE_SAFE", "unlock_safe", true)
			set_sub_objective("Q05_SYNDICATE_SAFE", "take_resonator", true)
		"signal_11_4_received":
			set_sub_objective("Q06_ABYSS_CALL", "witness_signal", true)
		"substation_online":
			set_sub_objective("Q07_SUBSTATION_REPAIR", "repair_transformer", true)
			set_sub_objective("Q07_SUBSTATION_REPAIR", "start_winch", true)
		"syndicate_conspiracy_revealed":
			set_sub_objective("Q08_SYNDICATE_CONSPIRACY", "find_protocol", true)
		"keller_weiss_entered":
			set_sub_objective("Q09_KELLER_SUSPENSION", "cross_chasm", true)
			set_sub_objective("Q09_KELLER_SUSPENSION", "reach_townhall", true)
		"harmonization_truth_uncovered":
			set_sub_objective("Q10_THE_GREAT_HARMONIZATION", "listen_organ_tape", true)
		"nexus_turbine_started":
			set_sub_objective("Q11_GEOTHERMAL_IGNITION", "open_steam_valve", true)
			set_sub_objective("Q11_GEOTHERMAL_IGNITION", "spool_turbine", true)
		"eleonora_truth_understood":
			set_sub_objective("Q12_ELEONORA_MIRAGE", "inspect_room", true)
			set_sub_objective("Q12_ELEONORA_MIRAGE", "hear_echo", true)
		"anchor_phase_calibrated":
			set_sub_objective("Q13_PHASE_CALIBRATION", "align_node_alpha", true)
			set_sub_objective("Q13_PHASE_CALIBRATION", "align_node_beta", true)
			set_sub_objective("Q13_PHASE_CALIBRATION", "align_node_gamma", true)
		"game_climax_resolved":
			set_sub_objective("Q14_THE_FINAL_DECISION", "trigger_climax", true)
