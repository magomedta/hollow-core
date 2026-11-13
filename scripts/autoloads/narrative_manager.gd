# scripts/autoloads/narrative_manager.gd
class_name NarrativeManager
extends Node

## Central Narrative Coordinator for Hollow Core.
## Manages story state persistence, act advancement, objective tracking,
## audio logs (Minecraft Disc 11-style), documents, clue chains, secret rooms,
## and canonical ending evaluations.

const StoryStateResourceClass = preload("res://scripts/resources/story_state_resource.gd")
const QuestManagerClass = preload("res://scripts/narrative/quest_manager.gd")
const EndingsDirectorClass = preload("res://scripts/narrative/endings_director.gd")
const ClueChainRegistryClass = preload("res://scripts/narrative/clue_chain_registry.gd")
const SecretRegistryClass = preload("res://scripts/narrative/secret_registry.gd")

signal act_changed(new_act: int)
signal objective_updated(obj_id: String, obj_text: String)
signal document_inspected(doc_id: String)
signal audiolog_triggered(audio_id: String)
signal clue_discovered(clue_id: String)
signal clue_chain_completed(chain_id: String, deduction: String)
signal world_flag_changed(flag_name: String, new_value: bool)
signal secret_room_unlocked(room_id: String)
signal ending_triggered(ending_id: String)

@export var story_state: Resource = null

var quest_manager: Node = null
var endings_director: CanvasLayer = null

const SAVE_PATH: String = "user://saves/story_state.tres"

func _init() -> void:
	if story_state == null:
		story_state = StoryStateResourceClass.new()

func _ready() -> void:
	add_to_group("narrative_manager")
	load_state()

	# Child coordinators
	quest_manager = QuestManagerClass.new()
	quest_manager.name = "QuestManager"
	add_child(quest_manager)
	quest_manager.setup(story_state)

	world_flag_changed.connect(quest_manager.on_world_flag_updated)

	endings_director = EndingsDirectorClass.new()
	endings_director.name = "EndingsDirector"
	add_child(endings_director)

func set_objective(obj_id: String, obj_text: String) -> void:
	story_state.active_objective_id = obj_id
	story_state.active_objective_text = obj_text
	objective_updated.emit(obj_id, obj_text)
	print("[NarrativeManager] Objective: %s — %s" % [obj_id, obj_text])

func trigger_world_event(flag_name: String) -> void:
	story_state.mark_flag(flag_name, true)
	world_flag_changed.emit(flag_name, true)
	print("[NarrativeManager] World Event Triggered: ", flag_name)
	save_state()

func advance_act(target_act: int) -> void:
	if target_act > story_state.current_act:
		story_state.current_act = target_act
		act_changed.emit(target_act)
		print("[NarrativeManager] Act Advanced to: ", target_act)
		save_state()

func inspect_document(doc_id: String) -> void:
	if story_state.add_document(doc_id):
		document_inspected.emit(doc_id)
		print("[NarrativeManager] Document Discovered: ", doc_id)
		save_state()

func play_audiolog(audio_id: String) -> void:
	if story_state.add_audiolog(audio_id):
		audiolog_triggered.emit(audio_id)
		print("[NarrativeManager] Audiolog Played: ", audio_id)
		save_state()

func unlock_clue(chain_id: String, clue_idx: int) -> void:
	if story_state.record_clue(chain_id, clue_idx):
		var clue_key = "%s_%d" % [chain_id, clue_idx]
		clue_discovered.emit(clue_key)
		print("[NarrativeManager] Clue Discovered: %s [%d]" % [chain_id, clue_idx])

		# Check if chain became complete
		if story_state.is_clue_chain_complete(chain_id):
			var ch_data = ClueChainRegistryClass.get_chain(chain_id)
			var ded = ch_data.get("deduction", "")
			var r_stat = ch_data.get("reward_stat", "")
			var r_pts = ch_data.get("reward_points", 1)

			if r_stat == "resonance_attunement":
				story_state.resonance_attunement += r_pts
			elif r_stat == "surface_determination":
				story_state.surface_determination += r_pts
			elif r_stat == "causal_loop_insight":
				story_state.causal_loop_insight += r_pts

			clue_chain_completed.emit(chain_id, ded)
			print("[NarrativeManager] Clue Chain Completed: %s! Deduction: %s" % [chain_id, ded])

		save_state()

func register_clue(clue_id: String) -> void:
	if not story_state.discovered_clues.get(clue_id, false):
		story_state.discovered_clues[clue_id] = true
		clue_discovered.emit(clue_id)
		print("[NarrativeManager] Clue Registered: ", clue_id)
		save_state()

func register_secret(secret_id: String) -> void:
	if story_state.mark_secret(secret_id):
		print("[NarrativeManager] Secret Unlocked: ", secret_id)
		save_state()

func unlock_secret_room(room_id: String) -> void:
	if story_state.record_secret_room(room_id):
		secret_room_unlocked.emit(room_id)
		print("[NarrativeManager] Secret Room Unlocked: ", room_id)
		save_state()

func get_available_endings() -> Dictionary:
	if endings_director and endings_director.has_method("evaluate_available_endings"):
		return endings_director.call("evaluate_available_endings", story_state)
	return { "A": true, "B": false, "C": false }

func trigger_ending(ending_id: String) -> void:
	story_state.set_ending(ending_id)
	ending_triggered.emit(ending_id)
	if endings_director:
		endings_director.trigger_ending(ending_id)
	print("[NarrativeManager] Ending Triggered: ", ending_id)
	save_state()

func save_state() -> void:
	var dir_path = "user://saves"
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	ResourceSaver.save(story_state, SAVE_PATH)

func load_state() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		var res = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		if res != null:
			story_state = res
			print("[NarrativeManager] Loaded story state from disk (Act %d)" % story_state.current_act)
			if quest_manager and quest_manager.has_method("setup"):
				quest_manager.setup(story_state)
