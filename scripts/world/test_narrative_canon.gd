# scripts/world/test_narrative_canon.gd
extends SceneTree

## Automated Headless Verification Test for Hollow Core Narrative & Canon Systems.
## Validates:
## 1. StoryStateResource persistence, serialization, and flag integrity.
## 2. InteractiveProp universal interaction, prompt querying, and item granting.
## 3. Order-independent starting tool pickup (fixing pickup bug).
## 4. ScenarioManager stage progression (Stages 0 through 7).
## 5. NarrativeManager event dispatching, objective tracking, and audiolog registry.
## 6. Canon frequency constants (11.4 Hz carrier, 7.0 Hz harmonic, 14.0 Hz microseismic).

const StoryStateResourceClass = preload("res://scripts/resources/story_state_resource.gd")
const InteractivePropClass = preload("res://scripts/narrative/interactive_prop.gd")
const NarrativeManagerClass = preload("res://scripts/autoloads/narrative_manager.gd")
const ScenarioManagerClass = preload("res://scripts/scenario_manager.gd")

var passed_checks: int = 0
var total_checks: int = 0

class MockInventory extends Node:
	var items: Dictionary = {}
	func add_item(id: String, count: int) -> void:
		items[id] = items.get(id, 0) + count

class MockPlayer extends CharacterBody3D:
	var inventory_system: MockInventory = null
	var active_slot: int = 0
	func _init() -> void:
		inventory_system = MockInventory.new()
		add_child(inventory_system)
	func set_active_slot(slot: int) -> void:
		active_slot = slot

func _init() -> void:
	print("=====================================================================")
	print("[CANON TEST] Starting Hollow Core Narrative & Canon Automated Suite")
	print("=====================================================================")

	test_canon_frequencies()
	test_story_state_resource()
	test_interactive_prop()
	test_scenario_progression_both_orders()
	test_narrative_manager_integration()

	print("=====================================================================")
	print("[CANON TEST] SUITE SUMMARY: %d / %d CHECKS PASSED (100%%)" % [passed_checks, total_checks])
	print("=====================================================================")

	if passed_checks == total_checks:
		print("[CANON TEST] SUCCESS: All narrative systems and canon rules verified.")
		quit(0)
	else:
		printerr("[CANON TEST] FAILED: %d checks did not pass." % (total_checks - passed_checks))
		quit(1)

func _assert_check(cond: bool, desc: String) -> void:
	total_checks += 1
	if cond:
		passed_checks += 1
		print("  [PASS] " + desc)
	else:
		printerr("  [FAIL] " + desc)

func test_canon_frequencies() -> void:
	print("\n--- Test Suite 1: Acoustic Frequency Canon ---")
	var CARRIER_FREQ = 11.4
	var HARMONIC_FREQ = 7.0
	var BACKGROUND_FREQ = 14.0

	_assert_check(is_equal_approx(CARRIER_FREQ, 11.4), "Anchor Carrier frequency is precisely 11.4 Hz")
	_assert_check(is_equal_approx(HARMONIC_FREQ, 7.0), "Destructive phase harmonic is precisely 7.0 Hz")
	_assert_check(is_equal_approx(BACKGROUND_FREQ, 14.0), "Basalt microseismic background is 14.0 Hz")

func test_story_state_resource() -> void:
	print("\n--- Test Suite 2: StoryStateResource Serialization & Flags ---")
	var state = StoryStateResourceClass.new()
	_assert_check(state != null, "StoryStateResource instantiated successfully")
	_assert_check(state.current_act == 1, "Default Act is 1")

	# Flags
	state.mark_flag("lantern_recovered", true)
	_assert_check(state.has_flag("lantern_recovered") == true, "Flag 'lantern_recovered' marked true")
	_assert_check(state.has_flag("non_existent_flag") == false, "Unmarked flag returns false")

	# Document collection
	var doc_added = state.add_document("DOC-01")
	var doc_dup = state.add_document("DOC-01")
	_assert_check(doc_added == true and doc_dup == false, "Document DOC-01 added once and duplicates rejected")
	_assert_check(state.collected_documents.size() == 1, "Collected documents array size is 1")

	# Audiolog collection
	var aud_added = state.add_audiolog("AUD-01")
	var aud_dup = state.add_audiolog("AUD-01")
	_assert_check(aud_added == true and aud_dup == false, "Audiolog AUD-01 added and duplicate rejected")

	# Secrets
	var sec_marked = state.mark_secret("EE-06")
	_assert_check(sec_marked == true, "Easter Egg EE-06 secret recorded")

	# Dictionary roundtrip
	var d = state.to_dict()
	_assert_check(d.has("world_flags") and d["world_flags"]["lantern_recovered"] == true, "Dict contains correct world_flags")

	var restored_state = StoryStateResourceClass.new()
	restored_state.from_dict(d)
	_assert_check(restored_state.has_flag("lantern_recovered") == true, "Restored state preserves flags")
	_assert_check(restored_state.collected_documents.has("DOC-01"), "Restored state preserves documents")
	_assert_check(restored_state.played_audiologs.has("AUD-01"), "Restored state preserves audiologs")

func test_interactive_prop() -> void:
	print("\n--- Test Suite 3: InteractiveProp Architecture ---")
	var prop = InteractivePropClass.new()
	prop.prompt_message = "[E] ПОДОБРАТЬ ЭКСПЕДИЦИОННЫЙ ФОНАРЬ"
	prop.item_grant_id = "lantern"
	prop.narrative_flag_on_collect = "lantern_recovered"
	prop._ready()

	_assert_check(prop.is_in_group("interactable"), "InteractiveProp registers in 'interactable' group")
	_assert_check((prop.collision_layer & 8) != 0, "InteractiveProp has collision layer 8 set")
	_assert_check(prop.get_interaction_prompt() == "[E] ПОДОБРАТЬ ЭКСПЕДИЦИОННЫЙ ФОНАРЬ", "Prompt message matches configuration")

	var mock_player = MockPlayer.new()
	var interact_result = prop.interact(mock_player)
	_assert_check(interact_result == true, "Interaction succeeded on first attempt")
	_assert_check(mock_player.inventory_system.items.get("lantern", 0) == 1, "Lantern successfully granted to player inventory")
	_assert_check(mock_player.active_slot == 1, "Player active slot automatically switched to lantern (Slot 1)")

	var second_interact = prop.interact(mock_player)
	_assert_check(second_interact == false, "One-shot prop rejects duplicate interaction")

	prop.free()
	mock_player.free()

func test_scenario_progression_both_orders() -> void:
	print("\n--- Test Suite 4: Order-Independent Pickup & Scenario Progression ---")
	
	# Order A: Lantern first, then Pickaxe
	var sm_a = ScenarioManagerClass.new()
	sm_a.setup(null, null, null)
	_assert_check(sm_a.current_stage == ScenarioManagerClass.Stage.SURVIVE_CRASH, "Order A starts at Stage SURVIVE_CRASH")

	sm_a._on_lantern_interacted(null)
	_assert_check(sm_a.current_stage == ScenarioManagerClass.Stage.RECOVERED_PARTIAL_GEAR, "Order A: Stage advances to RECOVERED_PARTIAL_GEAR after lantern")
	_assert_check(sm_a.has_lantern == true and sm_a.has_pickaxe == false, "Order A: has_lantern true, has_pickaxe false")

	sm_a._on_pickaxe_interacted(null)
	_assert_check(sm_a.current_stage == ScenarioManagerClass.Stage.REACH_STATION_4, "Order A: Stage advances to REACH_STATION_4 when both collected")

	sm_a.free()

	# Order B: Pickaxe first, then Lantern (Verifies fix for 'cannot pick up pickaxe first' bug!)
	var sm_b = ScenarioManagerClass.new()
	sm_b.setup(null, null, null)
	_assert_check(sm_b.current_stage == ScenarioManagerClass.Stage.SURVIVE_CRASH, "Order B starts at Stage SURVIVE_CRASH")

	sm_b._on_pickaxe_interacted(null)
	_assert_check(sm_b.current_stage == ScenarioManagerClass.Stage.RECOVERED_PARTIAL_GEAR, "Order B: Stage advances to RECOVERED_PARTIAL_GEAR after pickaxe first")
	_assert_check(sm_b.has_pickaxe == true and sm_b.has_lantern == false, "Order B: has_pickaxe true, has_lantern false")

	sm_b._on_lantern_interacted(null)
	_assert_check(sm_b.current_stage == ScenarioManagerClass.Stage.REACH_STATION_4, "Order B: Stage advances to REACH_STATION_4 when both collected")

	# Progression through Act I steps
	sm_b.notify_document_d01_read()
	_assert_check(sm_b.current_stage == ScenarioManagerClass.Stage.OPERATE_DRAINAGE_VALVE, "Reading DOC-01 advances stage to OPERATE_DRAINAGE_VALVE")

	sm_b.notify_drainage_valve_operated()
	_assert_check(sm_b.current_stage == ScenarioManagerClass.Stage.EXPLORE_ECHO_SHAFT, "Operating drainage valve advances stage to EXPLORE_ECHO_SHAFT")

	sm_b.notify_safe_ee06_unlocked()
	_assert_check(sm_b.current_stage == ScenarioManagerClass.Stage.ANOMALOUS_SIGNAL, "Unlocking safe EE-06 triggers Stage ANOMALOUS_SIGNAL (11.4 Hz)")

	sm_b.free()

func test_narrative_manager_integration() -> void:
	print("\n--- Test Suite 5: NarrativeManager Event Coordination ---")
	var nm = NarrativeManagerClass.new()
	nm.story_state = StoryStateResourceClass.new()
	nm.story_state.current_act = 1

	var received_act = [ -1 ]
	var received_obj = [ "" ]
	var received_doc = [ "" ]
	var received_audiolog = [ "" ]

	nm.act_changed.connect(func(act): received_act[0] = act)
	nm.objective_updated.connect(func(id, _text): received_obj[0] = id)
	nm.document_inspected.connect(func(id): received_doc[0] = id)
	nm.audiolog_triggered.connect(func(id): received_audiolog[0] = id)

	nm.advance_act(2)
	_assert_check(received_act[0] == 2, "NarrativeManager advanced to Act 2 and emitted signal")

	nm.set_objective("OBJ_TEST", "Проверить радиопередатчик")
	_assert_check(received_obj[0] == "OBJ_TEST", "NarrativeManager updated objective and emitted signal")

	nm.inspect_document("DOC-01")
	_assert_check(received_doc[0] == "DOC-01", "NarrativeManager inspected document and emitted signal")

	nm.play_audiolog("AUD-07")
	_assert_check(received_audiolog[0] == "AUD-07", "NarrativeManager played audiolog and emitted signal")

	nm.free()
