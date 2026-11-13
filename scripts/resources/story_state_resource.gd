# scripts/resources/story_state_resource.gd
class_name StoryStateResource
extends Resource

## Persistent Story State Container for Hollow Core.
## Tracks narrative progression, active & completed quests, collected documents,
## played audiologs, clue investigation chains, discovered easter eggs/secrets,
## secret rooms, achieved endings, and world event flags across save/load cycles.

@export var current_act: int = 1 # 0: Prologue, 1: Station 4, 2: Industrial Horizon, 3: Keller-Weiss, 4: Nexus-Wasp, 5: Bedrock Anchor
@export var active_objective_id: String = "OBJ_SURVIVE_CRASH"
@export var active_objective_text: String = "Найти аварийное снаряжение и обследовать штольню"

# Collected Evidence & Lore
@export var collected_documents: Array[String] = []
@export var played_audiologs: Array[String] = []
@export var discovered_secrets: Dictionary = {} # secret_id: bool
@export var discovered_clues: Dictionary = {}   # clue_id: bool
@export var discovered_secret_rooms: Array[String] = []

# Quests progression
@export var active_quests: Dictionary = {}      # quest_id: { "stage": int, "sub_objectives": Dictionary, "completed": bool }
@export var completed_quests: Array[String] = []

# Clue Investigation Chains (CH-01 .. CH-05)
@export var clue_chains_progress: Dictionary = {} # chain_id: Array[int] (found clue indices)
@export var completed_clue_chains: Array[String] = []

# Global World Narrative Flags
@export var world_flags: Dictionary = {
	"lantern_recovered": false,
	"pickaxe_recovered": false,
	"starting_gear_recovered": false,
	"station4_entered": false,
	"document_d01_read": false,
	"drainage_valve_opened": false,
	"sump_drained": false,
	"camp_discovered": false,
	"sump_reached": false,
	"echo_shaft_explored": false,
	"ee06_safe_unlocked": false,
	"watcher_first_sighting": false,
	"signal_11_4_received": false,
	"substation_online": false,
	"syndicate_conspiracy_revealed": false,
	"keller_weiss_entered": false,
	"harmonization_truth_uncovered": false,
	"keller_bridge_aligned": false,
	"nexus_turbine_started": false,
	"eleonora_truth_understood": false,
	"anchor_phase_calibrated": false,
	"game_climax_resolved": false
}

# Endings Alignment Trackers & Results
@export var resonance_attunement: int = 0  # Points toward Ending B: Resonance Guardian
@export var surface_determination: int = 0 # Points toward Ending A: Surface Breach
@export var causal_loop_insight: int = 0   # Points toward Ending C: Overhorizon Loop
@export var achieved_ending: String = ""   # "A", "B", "C" or ""

func _init() -> void:
	collected_documents = []
	played_audiologs = []
	discovered_secrets = {}
	discovered_clues = {}
	discovered_secret_rooms = []
	active_quests = {}
	completed_quests = []
	clue_chains_progress = {}
	completed_clue_chains = []
	world_flags = {
		"lantern_recovered": false,
		"pickaxe_recovered": false,
		"starting_gear_recovered": false,
		"station4_entered": false,
		"document_d01_read": false,
		"drainage_valve_opened": false,
		"sump_drained": false,
		"camp_discovered": false,
		"sump_reached": false,
		"echo_shaft_explored": false,
		"ee06_safe_unlocked": false,
		"watcher_first_sighting": false,
		"signal_11_4_received": false,
		"substation_online": false,
		"syndicate_conspiracy_revealed": false,
		"keller_weiss_entered": false,
		"harmonization_truth_uncovered": false,
		"keller_bridge_aligned": false,
		"nexus_turbine_started": false,
		"eleonora_truth_understood": false,
		"anchor_phase_calibrated": false,
		"game_climax_resolved": false
	}

func mark_flag(flag_name: String, val: bool = true) -> void:
	world_flags[flag_name] = val

func has_flag(flag_name: String) -> bool:
	return world_flags.get(flag_name, false)

func add_document(doc_id: String) -> bool:
	if not collected_documents.has(doc_id):
		collected_documents.append(doc_id)
		return true
	return false

func add_audiolog(audio_id: String) -> bool:
	if not played_audiologs.has(audio_id):
		played_audiologs.append(audio_id)
		return true
	return false

func mark_secret(secret_id: String) -> bool:
	if not discovered_secrets.get(secret_id, false):
		discovered_secrets[secret_id] = true
		return true
	return false

func record_secret_room(room_id: String) -> bool:
	if not discovered_secret_rooms.has(room_id):
		discovered_secret_rooms.append(room_id)
		return true
	return false

func record_clue(chain_id: String, clue_idx: int) -> bool:
	if not clue_chains_progress.has(chain_id):
		clue_chains_progress[chain_id] = []
	var arr: Array = clue_chains_progress[chain_id]
	if not arr.has(clue_idx):
		arr.append(clue_idx)
		arr.sort()
		clue_chains_progress[chain_id] = arr
		discovered_clues["%s_%d" % [chain_id, clue_idx]] = true
		if arr.size() >= 4 and not completed_clue_chains.has(chain_id):
			completed_clue_chains.append(chain_id)
		return true
	return false

func is_clue_chain_complete(chain_id: String) -> bool:
	return completed_clue_chains.has(chain_id)

func record_quest_stage(quest_id: String, stage: int, sub_obj: Dictionary = {}) -> void:
	if not active_quests.has(quest_id):
		active_quests[quest_id] = {
			"stage": stage,
			"sub_objectives": sub_obj,
			"completed": false
		}
	else:
		active_quests[quest_id]["stage"] = stage
		for k in sub_obj:
			active_quests[quest_id]["sub_objectives"][k] = sub_obj[k]

func record_quest_completed(quest_id: String) -> void:
	if not completed_quests.has(quest_id):
		completed_quests.append(quest_id)
	if active_quests.has(quest_id):
		active_quests[quest_id]["completed"] = true

func is_quest_completed(quest_id: String) -> bool:
	return completed_quests.has(quest_id)

func set_ending(ending_id: String) -> void:
	achieved_ending = ending_id

func to_dict() -> Dictionary:
	return {
		"current_act": current_act,
		"active_objective_id": active_objective_id,
		"active_objective_text": active_objective_text,
		"collected_documents": collected_documents,
		"played_audiologs": played_audiologs,
		"discovered_secrets": discovered_secrets,
		"discovered_clues": discovered_clues,
		"discovered_secret_rooms": discovered_secret_rooms,
		"active_quests": active_quests,
		"completed_quests": completed_quests,
		"clue_chains_progress": clue_chains_progress,
		"completed_clue_chains": completed_clue_chains,
		"world_flags": world_flags,
		"resonance_attunement": resonance_attunement,
		"surface_determination": surface_determination,
		"causal_loop_insight": causal_loop_insight,
		"achieved_ending": achieved_ending
	}

func from_dict(d: Dictionary) -> void:
	current_act = d.get("current_act", 1)
	active_objective_id = d.get("active_objective_id", "OBJ_SURVIVE_CRASH")
	active_objective_text = d.get("active_objective_text", "Найти аварийное снаряжение и обследовать штольню")
	
	collected_documents.clear()
	for doc in d.get("collected_documents", []):
		collected_documents.append(str(doc))
		
	played_audiologs.clear()
	for aud in d.get("played_audiologs", []):
		played_audiologs.append(str(aud))
		
	discovered_secrets = d.get("discovered_secrets", {})
	discovered_clues = d.get("discovered_clues", {})
	
	discovered_secret_rooms.clear()
	for room in d.get("discovered_secret_rooms", []):
		discovered_secret_rooms.append(str(room))
		
	active_quests = d.get("active_quests", {})
	
	completed_quests.clear()
	for q in d.get("completed_quests", []):
		completed_quests.append(str(q))
		
	clue_chains_progress.clear()
	var raw_cc = d.get("clue_chains_progress", {})
	for k in raw_cc:
		var arr = []
		for v in raw_cc[k]:
			arr.append(int(v))
		clue_chains_progress[str(k)] = arr
	
	completed_clue_chains.clear()
	for c in d.get("completed_clue_chains", []):
		completed_clue_chains.append(str(c))
		
	var loaded_flags = d.get("world_flags", {})
	for fk in loaded_flags:
		world_flags[fk] = loaded_flags[fk]
	resonance_attunement = d.get("resonance_attunement", 0)
	surface_determination = d.get("surface_determination", 0)
	causal_loop_insight = d.get("causal_loop_insight", 0)
	achieved_ending = d.get("achieved_ending", "")
