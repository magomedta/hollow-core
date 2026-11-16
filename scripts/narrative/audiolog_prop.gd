# scripts/narrative/audiolog_prop.gd
class_name AudiologProp
extends "res://scripts/narrative/interactive_prop.gd"

## Universal Physical 3D In-World Audiolog Prop for Hollow Core.
## Represents vintage field magnetic cassettes, wax cylinders, or wire spools.
## Interacting triggers spatial 3D audio playback and logs the evidence into the player's journal.

const AudiologRegistryClass = preload("res://scripts/narrative/audiolog_registry.gd")
const AudioStorySynthesizerClass = preload("res://scripts/audio/audio_story_synthesizer.gd")

@export var audio_tape_id: String = "AUD-01"

var audio_player_3d: AudioStreamPlayer3D = null
var cassette_mesh: MeshInstance3D = null
var spool_mesh_left: MeshInstance3D = null
var spool_mesh_right: MeshInstance3D = null

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("lore_audiologs")
	collision_layer = 4 | 8 # Item layer + interactable
	collision_mask = 0

	var log_data = AudiologRegistryClass.get_audiolog(audio_tape_id)
	var title = log_data.get("title", "Фонограмма " + audio_tape_id)
	prompt_message = "[E] ПРОСЛУШАТЬ: %s" % title.to_upper()
	is_one_shot = false # Can replay tape in the world
	sfx_on_interact = "item_pickup"
	audiolog_id = audio_tape_id

	_build_visuals()
	_setup_audio_player()

	if get_node_or_null("CollisionShape3D") == null:
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(0.4, 0.25, 0.25)
		col.shape = box
		add_child(col)

func _setup_audio_player() -> void:
	audio_player_3d = AudioStreamPlayer3D.new()
	audio_player_3d.name = "SpatialTapeAudio"
	audio_player_3d.unit_size = 6.0
	audio_player_3d.max_distance = 25.0
	audio_player_3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	audio_player_3d.bus = "Master"
	add_child(audio_player_3d)

func _build_visuals() -> void:
	# Handcrafted Low-Poly Vintage Compact Cassette Prop
	var cassette_root = Node3D.new()
	cassette_root.name = "CassetteModel"
	add_child(cassette_root)

	var scene_res = load("res://models/cassette_tape.glb")
	if scene_res:
		var inst = scene_res.instantiate()
		inst.scale = Vector3(1.35, 1.35, 1.35)
		inst.position = Vector3(0, 0.008, 0)
		cassette_root.add_child(inst)
	else:
		# Fallback basic mesh
		var shell_mat = StandardMaterial3D.new()
		shell_mat.albedo_color = Color(0.14, 0.15, 0.17, 1.0)
		shell_mat.roughness = 0.50

		cassette_mesh = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(0.18, 0.022, 0.115)
		cassette_mesh.mesh = mesh
		cassette_mesh.material_override = shell_mat
		cassette_mesh.position = Vector3(0, 0.011, 0)
		cassette_root.add_child(cassette_mesh)

	# Glowing amber phosphor indicator
	var led = MeshInstance3D.new()
	var led_box = BoxMesh.new()
	led_box.size = Vector3(0.008, 0.024, 0.008)
	led.mesh = led_box
	var led_mat = StandardMaterial3D.new()
	led_mat.albedo_color = Color(1.0, 0.70, 0.20, 1.0)
	led_mat.emission_enabled = true
	led_mat.emission = Color(1.0, 0.65, 0.15, 1.0)
	led_mat.emission_energy_multiplier = 2.0
	led.material_override = led_mat
	led.position = Vector3(0.065, 0.012, -0.038)
	cassette_root.add_child(led)

	# Soft warm area light around tape
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.72, 0.35)
	light.light_energy = 0.65
	light.omni_range = 1.8
	light.omni_attenuation = 1.2
	light.position = Vector3(0, 0.08, 0)
	add_child(light)

	# Subtle point light so the cassette is visible in pitch darkness
	var led_light = OmniLight3D.new()
	led_light.light_color = Color(1.0, 0.70, 0.20)
	led_light.light_energy = 0.40
	led_light.omni_range = 1.2
	led_light.position = Vector3(0.065, 0.030, -0.038)
	cassette_root.add_child(led_light)

func get_interaction_prompt() -> String:
	var log_data = AudiologRegistryClass.get_audiolog(audio_tape_id)
	var title = log_data.get("title", audio_tape_id)
	return "Прослушать: %s" % title

func _execute_interaction(_player: CharacterBody3D) -> void:
	var log_data = AudiologRegistryClass.get_audiolog(audio_tape_id)
	if log_data.is_empty():
		printerr("[AudiologProp] Unknown audio_tape_id: ", audio_tape_id)
		return

	# Generate or retrieve procedural AudioStreamWAV
	var stream = AudioStorySynthesizerClass.get_audiolog_stream(audio_tape_id)
	if audio_player_3d and stream:
		audio_player_3d.stream = stream
		audio_player_3d.play()

	# Notify Narrative Coordinator
	var tree = get_tree() if is_inside_tree() else null
	if tree:
		var nm = tree.get_first_node_in_group("narrative_manager")
		if nm and nm.has_method("play_audiolog"):
			nm.play_audiolog(audio_tape_id)

		# Check clue chain progress
		var chain_id = log_data.get("linked_chain", "")
		var clue_idx = log_data.get("clue_index", -1)
		if chain_id != "" and clue_idx >= 0 and nm and nm.has_method("unlock_clue"):
			nm.unlock_clue(chain_id, clue_idx)
