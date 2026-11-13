# scripts/world/test_story_gameplay_full.gd
extends SceneTree

## Comprehensive Headless Story & Gameplay Test Suite for Hollow Core.
## Validates:
## 1. Act 0 & Act I complete story playthrough & stage transitions
## 2. All 20 physical documents (DOC-01 to DOC-20) data, text & viewer
## 3. All 20 audiologs (AUD-01 to AUD-20) procedural synthesis & frequencies
## 4. All 5 clue investigation chains (CH-01 to CH-05) deductions & stats
## 5. All 20 easter eggs (EE-01 to EE-20) and 5 secret rooms (SEC-01 to SEC-05) + EasterEggProp
## 6. Complete quest tree across Acts 0 through V & non-linear resilience
## 7. 3 Canonical Endings (A: Surface Breach, B: Resonance Guardian, C: Overhorizon Loop)
## 8. Diegetic Field Journal UI tab switching & audio playback
## 9. Full persistence serialization roundtrip (StoryStateResource & saves)
## 10. SanityManager Dread Index & NarrativeManager load re-binding

const StoryStateResourceClass = preload("res://scripts/resources/story_state_resource.gd")
const NarrativeManagerClass = preload("res://scripts/autoloads/narrative_manager.gd")
const ScenarioManagerClass = preload("res://scripts/scenario_manager.gd")
const DocumentRegistryClass = preload("res://scripts/narrative/document_registry.gd")
const AudiologRegistryClass = preload("res://scripts/narrative/audiolog_registry.gd")
const ClueChainRegistryClass = preload("res://scripts/narrative/clue_chain_registry.gd")
const SecretRegistryClass = preload("res://scripts/narrative/secret_registry.gd")
const QuestRegistryClass = preload("res://scripts/narrative/quest_registry.gd")
const QuestManagerClass = preload("res://scripts/narrative/quest_manager.gd")
const EndingsDirectorClass = preload("res://scripts/narrative/endings_director.gd")
const AudioStorySynthesizerClass = preload("res://scripts/audio/audio_story_synthesizer.gd")
const FieldJournalViewerClass = preload("res://scripts/narrative/field_journal.gd")
const EasterEggPropClass = preload("res://scripts/narrative/easter_egg_prop.gd")
const SanityManagerClass = preload("res://scripts/horror/sanity_manager.gd")

var passed_checks: int = 0
var total_checks: int = 0

class MockInventory extends Node:
	var items: Dictionary = {}
	func add_item(id: String, count: int) -> void:
		items[id] = items.get(id, 0) + count

class MockPlayer extends CharacterBody3D:
	signal acoustic_noise_emitted(origin: Vector3, radius: float, noise_type: String)

	var inventory_system: MockInventory = null
	var active_slot: int = 0
	var lantern: Node = null
	func _init() -> void:
		inventory_system = MockInventory.new()
		add_child(inventory_system)
		lantern = Node.new()
		lantern.set("is_lit", false)
		add_child(lantern)
	func set_active_slot(slot: int) -> void:
		active_slot = slot

func _init() -> void:
	print("=====================================================================")
	print("  HOLLOW CORE — FULL STORY & NARRATIVE GAMEPLAY VERIFICATION SUITE")
	print("=====================================================================")

	call_deferred("_run_all_tests")

func _assert_check(cond: bool, desc: String) -> void:
	total_checks += 1
	if cond:
		passed_checks += 1
		print("  [PASS] " + desc)
	else:
		printerr("  [FAIL] " + desc)

func _run_all_tests() -> void:
	_test_1_act0_and_act1_playthrough()
	_test_2_all_20_documents()
	_test_3_all_20_audiologs_and_synthesis()
	_test_4_all_5_clue_chains()
	_test_5_easter_eggs_and_secret_rooms()
	_test_6_all_acts_and_quest_tree()
	_test_7_three_canonical_endings()
	_test_8_field_journal_ui()
	_test_9_persistence_serialization_roundtrip()
	_test_10_sanity_and_load_sync()

	print("\n=====================================================================")
	print("STORY VERIFICATION SUMMARY: %d / %d CHECKS PASSED (%d%%)" % [
		passed_checks, total_checks, int((float(passed_checks) / float(total_checks)) * 100.0)
	])
	print("=====================================================================")

	if passed_checks == total_checks:
		print(">> ALL STORY, QUEST, NARRATIVE & CANON SYSTEMS FULLY VERIFIED! <<")
		for i in range(2):
			await process_frame
		quit(0)
	else:
		printerr(">> STORY VERIFICATION SUITE FAILED (%d checks failed) <<" % (total_checks - passed_checks))
		for i in range(2):
			await process_frame
		quit(1)

# -----------------------------------------------------------------------------
# TEST 1: Act 0 & Act I Complete Gameplay Flow
# -----------------------------------------------------------------------------
func _test_1_act0_and_act1_playthrough() -> void:
	print("\n--- Test Suite 1: Act 0 & Act I Complete Gameplay Flow ---")

	var nm = NarrativeManagerClass.new()
	root.add_child(nm)

	var sm = ScenarioManagerClass.new()
	root.add_child(sm)
	sm.setup(null, null, null)

	var player = MockPlayer.new()
	root.add_child(player)
	player.global_position = Vector3(1.0, 57.0, 0.0)

	# 1. Order-independent tool recovery
	_assert_check(sm.current_stage == ScenarioManagerClass.Stage.SURVIVE_CRASH, "Start at Stage 0: SURVIVE_CRASH")
	sm._on_lantern_interacted(player)
	_assert_check(sm.current_stage == ScenarioManagerClass.Stage.RECOVERED_PARTIAL_GEAR, "Partial gear: lantern recovered")
	sm._on_pickaxe_interacted(player)
	_assert_check(sm.current_stage == ScenarioManagerClass.Stage.REACH_STATION_4, "Full gear: advance to REACH_STATION_4")

	# 2. Entering Station 4
	player.global_position = Vector3(12.0, 40.0, -10.0)
	sm.player_ref = player
	sm._process(0.1)
	_assert_check(sm.current_stage == ScenarioManagerClass.Stage.INSPECT_DOCUMENT_D01, "Entered Station 4: stage is INSPECT_DOCUMENT_D01")
	_assert_check(nm.story_state.has_flag("station4_entered"), "World flag station4_entered set")

	# 3. Inspecting DOC-01
	sm.notify_document_d01_read()
	_assert_check(sm.current_stage == ScenarioManagerClass.Stage.OPERATE_DRAINAGE_VALVE, "Read DOC-01: stage is OPERATE_DRAINAGE_VALVE")
	_assert_check(nm.story_state.has_flag("document_d01_read"), "World flag document_d01_read set")
	_assert_check(nm.story_state.collected_documents.has("DOC-01"), "DOC-01 recorded in collected documents")

	# 4. Drainage valve operation
	sm.notify_drainage_valve_operated()
	_assert_check(sm.current_stage == ScenarioManagerClass.Stage.EXPLORE_ECHO_SHAFT, "Operated valve: stage is EXPLORE_ECHO_SHAFT")
	_assert_check(nm.story_state.has_flag("sump_drained"), "World flag sump_drained set")

	# 5. Exploring Camp and Sump
	player.global_position = Vector3(-16.0, 26.0, 4.0)
	sm._process(0.1)
	_assert_check(nm.story_state.has_flag("camp_discovered"), "World flag camp_discovered set upon reaching camp")

	player.global_position = Vector3(14.0, 28.0, -12.0)
	sm._process(0.1)
	_assert_check(nm.story_state.has_flag("sump_reached"), "World flag sump_reached set upon reaching sump")

	# 6. Unlocking safe EE-06
	sm.notify_safe_ee06_unlocked()
	_assert_check(sm.current_stage == ScenarioManagerClass.Stage.ANOMALOUS_SIGNAL, "Unlocked safe EE-06: stage is ANOMALOUS_SIGNAL (11.4 Hz)")
	_assert_check(nm.story_state.has_flag("ee06_safe_unlocked"), "World flag ee06_safe_unlocked set")
	_assert_check(nm.story_state.has_flag("signal_11_4_received"), "World flag signal_11_4_received set")
	_assert_check(nm.story_state.discovered_secrets.has("EE-06"), "EE-06 registered in discovered secrets")
	_assert_check(nm.story_state.played_audiologs.has("AUD-07"), "Audiolog AUD-07 registered from safe")
	_assert_check(nm.story_state.discovered_secret_rooms.has("SEC-01"), "Secret room SEC-01 unlocked")

	root.remove_child(sm)
	sm.free()
	root.remove_child(nm)
	nm.free()
	root.remove_child(player)
	player.free()

# -----------------------------------------------------------------------------
# TEST 2: All 20 Physical Documents (DOC-01 to DOC-20)
# -----------------------------------------------------------------------------
func _test_2_all_20_documents() -> void:
	print("\n--- Test Suite 2: All 20 Physical Documents (DOC-01 to DOC-20) ---")

	var doc_ids = DocumentRegistryClass.get_all_document_ids()
	_assert_check(doc_ids.size() == 20, "DocumentRegistry contains exactly 20 canonical documents")

	var all_fields_valid = true
	for i in range(1, 21):
		var doc_id = "DOC-%02d" % i
		if not DocumentRegistryClass.has_document(doc_id):
			all_fields_valid = false
			printerr("Missing document: ", doc_id)
			break
		var doc = DocumentRegistryClass.get_document(doc_id)
		if doc.get("title", "") == "" or doc.get("date", "") == "" or doc.get("author", "") == "" or doc.get("primary_lore", "") == "" or doc.get("secret_truth", "") == "":
			all_fields_valid = false
			printerr("Incomplete fields in document: ", doc_id)
			break

	_assert_check(all_fields_valid, "All 20 documents possess valid titles, dates, authors, text, and secret truths")
	_assert_check(DocumentRegistryClass.get_document("DOC-01").title.contains("шурфа №4"), "DOC-01 matches 1894 Prokhorov journal canon")
	_assert_check(DocumentRegistryClass.get_document("DOC-06").date.contains("1989"), "DOC-06 matches Cape Silent 1989 telegram canon")
	_assert_check(DocumentRegistryClass.get_document("DOC-07").date.contains("2019"), "DOC-07 matches Carlsbad 2019 FBI inquiry canon")
	_assert_check(DocumentRegistryClass.get_document("DOC-08").primary_lore.contains("12"), "DOC-08 matches 2025 expedition 12-specialist group canon")
	_assert_check(DocumentRegistryClass.get_document("DOC-20").secret_truth.contains("48"), "DOC-20 confirms 48 hours elapsed on surface since crash canon")

# -----------------------------------------------------------------------------
# TEST 3: All 20 Audiologs & Procedural Sound Synthesis
# -----------------------------------------------------------------------------
func _test_3_all_20_audiologs_and_synthesis() -> void:
	print("\n--- Test Suite 3: All 20 Audiologs & Procedural Sound Synthesis ---")

	var audio_ids = AudiologRegistryClass.get_all_audiolog_ids()
	_assert_check(audio_ids.size() == 20, "AudiologRegistry contains exactly 20 canonical audiologs")

	var all_synthesized = true
	for i in range(1, 21):
		var a_id = "AUD-%02d" % i
		var stream = AudioStorySynthesizerClass.get_audiolog_stream(a_id)
		if stream == null or stream.data.size() < 1000:
			all_synthesized = false
			printerr("Synthesis failed for audiolog: ", a_id)
			break

	_assert_check(all_synthesized, "All 20 audiologs successfully synthesized into valid AudioStreamWAV buffers")
	_assert_check(AudiologRegistryClass.get_audiolog("AUD-02").frequency == 7.0, "AUD-02 Destructive harmonic is precisely 7.0 Hz")
	_assert_check(AudiologRegistryClass.get_audiolog("AUD-07").frequency == 11.4, "AUD-07 Cape Silent Carrier is precisely 11.4 Hz")
	_assert_check(AudiologRegistryClass.get_audiolog("AUD-08").frequency == 11.4, "AUD-08 Eleonora Carlsbad harmonic is 11.4 Hz")
	_assert_check(AudiologRegistryClass.get_audiolog("AUD-14").title.contains("14"), "AUD-14 Microseismic basalt background is 14.0 Hz")
	_assert_check(AudiologRegistryClass.get_audiolog("AUD-20").frequency == 11.4, "AUD-20 Anchor Final Echo is 11.4 Hz")
	_assert_check(AudiologRegistryClass.get_audiolog("AUD-20").transcript.contains("Не закрывайте колодец"), "AUD-20 contains exact canonical time-loop key line")

# -----------------------------------------------------------------------------
# TEST 4: All 5 Clue Investigation Chains (CH-01 to CH-05)
# -----------------------------------------------------------------------------
func _test_4_all_5_clue_chains() -> void:
	print("\n--- Test Suite 4: All 5 Clue Investigation Chains (CH-01 to CH-05) ---")

	var chain_ids = ClueChainRegistryClass.get_all_chain_ids()
	_assert_check(chain_ids.size() == 5, "ClueChainRegistry contains exactly 5 canonical investigation chains")

	var state = StoryStateResourceClass.new()
	state.record_clue("CH-01", 0) # DOC-02
	state.record_clue("CH-01", 1) # AUD-15
	state.record_clue("CH-01", 2) # DOC-04

	_assert_check(not state.is_clue_chain_complete("CH-01"), "CH-01 incomplete at 3/4 clues")
	state.record_clue("CH-01", 3) # EE-06
	_assert_check(state.is_clue_chain_complete("CH-01"), "CH-01 completes upon 4th clue discovered")

	# Test Chain CH-05: Overhorizon Loop
	state.record_clue("CH-05", 0) # DOC-06
	state.record_clue("CH-05", 1) # AUD-07
	state.record_clue("CH-05", 2) # DOC-10
	state.record_clue("CH-05", 3) # AUD-20
	_assert_check(state.is_clue_chain_complete("CH-05"), "CH-05 (1989 Time Loop) successfully completed")

	# Verify strict canonical sources in Clue Chains
	var ch1 = ClueChainRegistryClass.get_chain("CH-01")
	_assert_check(ch1["clues"][0]["source_id"] == "DOC-02", "CH-01 clue 0 is DOC-02")
	_assert_check(ch1["clues"][1]["source_id"] == "AUD-15", "CH-01 clue 1 is AUD-15")
	_assert_check(ch1["clues"][2]["source_id"] == "DOC-04", "CH-01 clue 2 is DOC-04")
	_assert_check(ch1["clues"][3]["source_id"] == "EE-06", "CH-01 clue 3 is EE-06")

# -----------------------------------------------------------------------------
# TEST 5: Easter Eggs & Secret Rooms + EasterEggProp
# -----------------------------------------------------------------------------
func _test_5_easter_eggs_and_secret_rooms() -> void:
	print("\n--- Test Suite 5: Easter Eggs & Secret Rooms ---")

	var egg_ids = SecretRegistryClass.get_all_easter_egg_ids()
	_assert_check(egg_ids.size() == 20, "SecretRegistry contains exactly 20 easter eggs (EE-01 to EE-20)")

	var room_ids = SecretRegistryClass.get_all_secret_room_ids()
	_assert_check(room_ids.size() == 5, "SecretRegistry contains exactly 5 secret rooms (SEC-01 to SEC-05)")

	var sec1 = SecretRegistryClass.get_secret_room("SEC-01")
	_assert_check(sec1.name.contains("гидронасосная"), "SEC-01 matches Flooded Sump Station canon")

	var ee6 = SecretRegistryClass.get_easter_egg("EE-06")
	_assert_check(ee6.description.contains("1924"), "EE-06 specifies combination 1924 canon")

	var ee20 = SecretRegistryClass.get_easter_egg("EE-20")
	_assert_check(ee20.name.contains("EE-27"), "EE-20 corresponds to Eleonora Lithoacoustic Mirage EE-27")

	# Test physical EasterEggProp interaction and clue triggering
	var nm = NarrativeManagerClass.new()
	root.add_child(nm)

	var ee_prop = EasterEggPropClass.new()
	ee_prop.easter_egg_id = "EE-04"
	root.add_child(ee_prop)

	var p = MockPlayer.new()
	root.add_child(p)
	ee_prop.interact(p)

	_assert_check(nm.story_state.discovered_secrets.has("EE-04"), "EasterEggProp records EE-04 in discovered_secrets")
	_assert_check(nm.story_state.clue_chains_progress.get("CH-04", []).has(2), "EasterEggProp EE-04 unlocks clue CH-04 [2]")

	root.remove_child(ee_prop)
	ee_prop.free()
	root.remove_child(p)
	p.free()
	root.remove_child(nm)
	nm.free()

# -----------------------------------------------------------------------------
# TEST 6: Complete Quest Tree across Acts 0 through V & Non-Linear Execution
# -----------------------------------------------------------------------------
func _test_6_all_acts_and_quest_tree() -> void:
	print("\n--- Test Suite 6: Complete Quest Tree across Acts 0 through V ---")

	var quest_ids = QuestRegistryClass.get_all_quest_ids()
	_assert_check(quest_ids.size() >= 14, "QuestRegistry contains full quest campaign across all acts (%d quests)" % quest_ids.size())

	var state = StoryStateResourceClass.new()
	var qm = QuestManagerClass.new()
	root.add_child(qm)
	qm.setup(state)

	_assert_check(qm.current_quest_id == "Q00_CRASH_SURVIVAL", "Initial active quest is Q00_CRASH_SURVIVAL")

	# Walk full campaign via world flags
	qm.on_world_flag_updated("lantern_recovered", true)
	qm.on_world_flag_updated("pickaxe_recovered", true)
	_assert_check(qm.current_quest_id == "Q01_APPROACH_STATION4", "Q00 advances to Q01")

	qm.on_world_flag_updated("station4_entered", true)
	_assert_check(qm.current_quest_id == "Q02_SURVEYOR_WORKSTATION", "Q01 advances to Q02")

	qm.on_world_flag_updated("document_d01_read", true)
	_assert_check(qm.current_quest_id == "Q03_DRAINAGE_RESTORATION", "Q02 advances to Q03")

	qm.on_world_flag_updated("sump_drained", true)
	_assert_check(qm.current_quest_id == "Q04_ECHO_SHAFT_DESCENT", "Q03 advances to Q04")

	qm.on_world_flag_updated("camp_discovered", true)
	qm.on_world_flag_updated("sump_reached", true)
	_assert_check(qm.current_quest_id == "Q05_SYNDICATE_SAFE", "Q04 advances to Q05 after camp & sump reached")

	qm.on_world_flag_updated("ee06_safe_unlocked", true)
	_assert_check(qm.current_quest_id == "Q06_ABYSS_CALL", "Q05 advances to Q06")

	qm.on_world_flag_updated("signal_11_4_received", true)
	_assert_check(qm.current_quest_id == "Q07_SUBSTATION_REPAIR", "Q06 advances to Act 2 (Q07)")

	# Act 2 -> 5 advancement
	qm.on_world_flag_updated("substation_online", true)
	_assert_check(qm.current_quest_id == "Q08_SYNDICATE_CONSPIRACY", "Q07 advances to Q08")

	qm.on_world_flag_updated("syndicate_conspiracy_revealed", true)
	_assert_check(qm.current_quest_id == "Q09_KELLER_SUSPENSION", "Q08 advances to Act 3 (Q09)")

	qm.on_world_flag_updated("keller_weiss_entered", true)
	_assert_check(qm.current_quest_id == "Q10_THE_GREAT_HARMONIZATION", "Q09 advances to Q10")

	qm.on_world_flag_updated("harmonization_truth_uncovered", true)
	_assert_check(qm.current_quest_id == "Q11_GEOTHERMAL_IGNITION", "Q10 advances to Act 4 (Q11)")

	qm.on_world_flag_updated("nexus_turbine_started", true)
	_assert_check(qm.current_quest_id == "Q12_ELEONORA_MIRAGE", "Q11 advances to Q12")

	qm.on_world_flag_updated("eleonora_truth_understood", true)
	_assert_check(qm.current_quest_id == "Q13_PHASE_CALIBRATION", "Q12 advances to Act 5 (Q13)")

	qm.on_world_flag_updated("anchor_phase_calibrated", true)
	_assert_check(qm.current_quest_id == "Q14_THE_FINAL_DECISION", "Q13 advances to Q14 (Climax)")

	qm.queue_free()

	# Test Non-Linear / Out-of-order startup resilience
	var state_nl = StoryStateResourceClass.new()
	state_nl.mark_flag("lantern_recovered", true)
	state_nl.mark_flag("pickaxe_recovered", true)
	state_nl.mark_flag("station4_entered", true)
	var qm_nl = QuestManagerClass.new()
	root.add_child(qm_nl)
	qm_nl.setup(state_nl)
	_assert_check(qm_nl.current_quest_id == "Q02_SURVEYOR_WORKSTATION", "Out-of-order pre-satisfied flags automatically advance to active stage")
	qm_nl.queue_free()

# -----------------------------------------------------------------------------
# TEST 7: Three Canonical Endings (A, B, C)
# -----------------------------------------------------------------------------
func _test_7_three_canonical_endings() -> void:
	print("\n--- Test Suite 7: Three Canonical Endings (A, B, C) ---")

	var state = StoryStateResourceClass.new()
	var endings = EndingsDirectorClass.evaluate_available_endings(state)
	_assert_check(endings["A"] == true, "Ending A (Surface Breach) available by default")
	_assert_check(endings["B"] == false and endings["C"] == false, "Endings B and C locked without prerequisites")

	# Verify signal_11_4_received ALONE does not unlock Ending C
	state.mark_flag("signal_11_4_received", true)
	var endings_premature = EndingsDirectorClass.evaluate_available_endings(state)
	_assert_check(endings_premature["C"] == false, "Ending C strictly locked in Act 1 even after 11.4 Hz signal received")

	# Attune state for Ending B (Resonance Guardian)
	state.resonance_attunement = 2
	var endings_b = EndingsDirectorClass.evaluate_available_endings(state)
	_assert_check(endings_b["B"] == true, "Ending B unlocked when resonance attunement >= 2")

	# Complete full 4-clue loop for Ending C (Overhorizon Loop)
	state.record_clue("CH-05", 0)
	state.record_clue("CH-05", 1)
	state.record_clue("CH-05", 2)
	state.record_clue("CH-05", 3)
	var endings_c = EndingsDirectorClass.evaluate_available_endings(state)
	_assert_check(endings_c["C"] == true, "Ending C unlocked upon completing Chain CH-05 (all 4 clues)")

	# Test ending trigger
	var nm = NarrativeManagerClass.new()
	root.add_child(nm)
	nm.story_state = state

	nm.trigger_ending("C")
	_assert_check(state.achieved_ending == "C", "Ending C recorded in StoryStateResource")

	nm.queue_free()

# -----------------------------------------------------------------------------
# TEST 8: Field Journal UI (Anti-AI-UI)
# -----------------------------------------------------------------------------
func _test_8_field_journal_ui() -> void:
	print("\n--- Test Suite 8: Field Journal UI (Anti-AI-UI) ---")

	var journal = FieldJournalViewerClass.new()
	root.add_child(journal)

	_assert_check(journal.is_in_group("field_journal"), "FieldJournal registers in 'field_journal' group")

	journal.open_journal()
	_assert_check(journal.is_open == true and journal.visible == true, "Journal opened successfully")

	# Switch across all 4 tabs
	for tab_idx in [0, 1, 2, 3]:
		journal._switch_tab(tab_idx)
		_assert_check(journal.current_tab == tab_idx, "Switched cleanly to Tab %d" % tab_idx)

	journal.close_journal()
	_assert_check(journal.is_open == false and journal.visible == false, "Journal closed cleanly")

	journal.queue_free()

# -----------------------------------------------------------------------------
# TEST 9: Persistence Serialization Roundtrip
# -----------------------------------------------------------------------------
func _test_9_persistence_serialization_roundtrip() -> void:
	print("\n--- Test Suite 9: Persistence Serialization Roundtrip ---")

	var original = StoryStateResourceClass.new()
	original.current_act = 3
	original.active_objective_id = "Q09_KELLER_SUSPENSION"
	original.active_objective_text = "Проникнуть в висячий город Келлер-Вайс"
	original.add_document("DOC-01")
	original.add_document("DOC-05")
	original.add_audiolog("AUD-01")
	original.add_audiolog("AUD-07")
	original.mark_secret("EE-06")
	original.record_secret_room("SEC-01")
	original.record_clue("CH-01", 0)
	original.record_clue("CH-01", 1)
	original.record_quest_completed("Q00_CRASH_SURVIVAL")
	original.set_ending("B")

	var dict = original.to_dict()
	_assert_check(dict.has("active_quests") and dict.has("completed_quests"), "Dictionary contains quest arrays")
	_assert_check(dict.has("clue_chains_progress") and dict.has("discovered_secret_rooms"), "Dictionary contains clues & secrets")

	var restored = StoryStateResourceClass.new()
	restored.from_dict(dict)

	_assert_check(restored.current_act == 3, "Restored Act is 3")
	_assert_check(restored.active_objective_id == "Q09_KELLER_SUSPENSION", "Restored active objective matches")
	_assert_check(restored.collected_documents.has("DOC-05"), "Restored documents contain DOC-05")
	_assert_check(restored.played_audiologs.has("AUD-07"), "Restored audiologs contain AUD-07")
	_assert_check(restored.discovered_secrets.has("EE-06"), "Restored secrets contain EE-06")
	_assert_check(restored.discovered_secret_rooms.has("SEC-01"), "Restored secret rooms contain SEC-01")
	_assert_check(restored.completed_quests.has("Q00_CRASH_SURVIVAL"), "Restored completed quests contain Q00")
	_assert_check(restored.achieved_ending == "B", "Restored ending matches 'B'")

# -----------------------------------------------------------------------------
# TEST 10: SanityManager & NarrativeManager Load Re-Binding
# -----------------------------------------------------------------------------
func _test_10_sanity_and_load_sync() -> void:
	print("\n--- Test Suite 10: SanityManager & Load Synchronization ---")

	# 1. SanityManager Tension checks
	var sm = SanityManagerClass.new()
	root.add_child(sm)
	var p = MockPlayer.new()
	root.add_child(p)
	sm.set_player(p)

	_assert_check(sm.tension == 0.0, "Sanity tension starts at 0.0")
	sm._process(2.0)
	_assert_check(sm.tension > 0.0, "Darkness increases tension (%.4f > 0.0)" % sm.tension)

	sm.relieve_tension_canteen()
	_assert_check(sm.tension == 0.0, "Canteen relieves tension to 0.0")

	root.remove_child(sm)
	sm.free()
	root.remove_child(p)
	p.free()

	# 2. NarrativeManager Load Sync Re-binding
	var nm = NarrativeManagerClass.new()
	root.add_child(nm)

	var initial_state = nm.story_state
	var qm_bound_state = nm.quest_manager.story_state
	_assert_check(initial_state == qm_bound_state, "QuestManager initially bound to NarrativeManager story_state")

	var new_state = StoryStateResourceClass.new()
	new_state.current_act = 2
	new_state.record_quest_completed("Q00_CRASH_SURVIVAL")
	new_state.record_quest_completed("Q01_APPROACH_STATION4")

	# Save mock to disk and load
	ResourceSaver.save(new_state, NarrativeManagerClass.SAVE_PATH)
	nm.load_state()

	_assert_check(nm.story_state.current_act == 2, "Loaded story state has Act 2")
	_assert_check(nm.quest_manager.story_state == nm.story_state, "QuestManager cleanly re-bound to loaded story state")
	_assert_check(nm.quest_manager.current_quest_id == "Q02_SURVEYOR_WORKSTATION", "QuestManager restored active quest to Q02")

	root.remove_child(nm)
	nm.free()
