# scripts/narrative/document_prop.gd
class_name DocumentProp
extends "res://scripts/narrative/interactive_prop.gd"

## Universal Physical 3D In-World Document Prop for Hollow Core.
## Represents vintage dispatch boxes, surveyor folios, telegram sheets,
## and technical schematics. Directly opens DocumentViewer and records story progress.

const DocumentRegistryClass = preload("res://scripts/narrative/document_registry.gd")
const DocumentViewerClass = preload("res://scripts/narrative/document_viewer.gd")

@export var document_id: String = "DOC-01"

var box_mesh: MeshInstance3D = null
var latch_mesh: MeshInstance3D = null

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("lore_documents")
	collision_layer = 4 | 8 # Item layer + interactable
	collision_mask = 0

	var doc_data = DocumentRegistryClass.get_document(document_id)
	var doc_title = doc_data.get("title", "Документ " + document_id)
	prompt_message = "[E] ИЗУЧИТЬ: %s" % doc_title.to_upper()
	is_one_shot = false # Documents can be re-read in the world!
	sfx_on_interact = "item_pickup"
	doc_id = document_id

	_build_visuals()

	# Ensure collision shape exists
	if get_node_or_null("CollisionShape3D") == null:
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(0.5, 0.4, 0.3)
		col.shape = box
		add_child(col)

func _build_visuals() -> void:
	# 1. Main Document Dispatch Box / Folio
	box_mesh = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.42, 0.30, 0.12)
	box_mesh.mesh = mesh

	var mat = StandardMaterial3D.new()
	# Weathered dark oxidized tin / vulcanite folder
	mat.albedo_color = Color(0.22, 0.24, 0.25, 1.0)
	mat.metallic = 0.65
	mat.roughness = 0.70
	box_mesh.material_override = mat
	add_child(box_mesh)

	# 2. Brass Latch / Stamped Seal
	latch_mesh = MeshInstance3D.new()
	var l_mesh = BoxMesh.new()
	l_mesh.size = Vector3(0.10, 0.06, 0.04)
	latch_mesh.mesh = l_mesh

	var l_mat = StandardMaterial3D.new()
	l_mat.albedo_color = Color(0.75, 0.60, 0.28, 1.0) # Aged brass
	l_mat.metallic = 0.85
	l_mat.roughness = 0.35
	latch_mesh.material_override = l_mat
	latch_mesh.position = Vector3(0, 0, 0.07)
	add_child(latch_mesh)

func get_interaction_prompt() -> String:
	var doc_data = DocumentRegistryClass.get_document(document_id)
	var title = doc_data.get("title", document_id)
	return "Прочесть: %s" % title

func _execute_interaction(_player: CharacterBody3D) -> void:
	var doc_data = DocumentRegistryClass.get_document(document_id)
	if doc_data.is_empty():
		printerr("[DocumentProp] Unknown document_id: ", document_id)
		return

	var title = doc_data.get("title", "ДОКУМЕНТ")
	var header_meta = "%s // %s" % [doc_data.get("date", ""), doc_data.get("author", "")]
	var body = doc_data.get("primary_lore", "")

	# Locate or spawn DocumentViewer in current scene tree
	var tree = get_tree() if is_inside_tree() else null
	if tree:
		var viewer = tree.get_first_node_in_group("document_viewer")
		if viewer == null:
			viewer = DocumentViewerClass.new()
			viewer.name = "DocumentViewer"
			tree.root.add_child(viewer)

		if viewer and viewer.has_method("show_document"):
			viewer.show_document(document_id, title.to_upper(), header_meta, body)

		# Check clue chain progress
		var chain_id = doc_data.get("linked_chain", "")
		var clue_idx = doc_data.get("clue_index", -1)
		if chain_id != "" and clue_idx >= 0:
			var nm = tree.get_first_node_in_group("narrative_manager")
			if nm and nm.has_method("unlock_clue"):
				nm.unlock_clue(chain_id, clue_idx)
