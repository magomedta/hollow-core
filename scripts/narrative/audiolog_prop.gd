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
	# 1. Cassette body (Weathered Bakelite / plastic)
	cassette_mesh = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.28, 0.06, 0.18)
	cassette_mesh.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.20, 0.22, 1.0)
	mat.roughness = 0.65
	cassette_mesh.material_override = mat
	add_child(cassette_mesh)

	# 2. Spools (white nylon)
	for offset_x in [-0.07, 0.07]:
		var spool = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.035
		cyl.bottom_radius = 0.035
		cyl.height = 0.065
		cyl.radial_segments = 8
		spool.mesh = cyl

		var sp_mat = StandardMaterial3D.new()
		sp_mat.albedo_color = Color(0.85, 0.85, 0.82)
		spool.material_override = sp_mat
		spool.position = Vector3(offset_x, 0.005, 0.0)
		add_child(spool)

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
