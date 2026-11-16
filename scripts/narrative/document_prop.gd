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
	# 1. Main Vintage Field Folio Binder
	box_mesh = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.38, 0.038, 0.28)
	box_mesh.mesh = mesh

	var mat = StandardMaterial3D.new()
	# Weathered dark umber leather folio binding
	mat.albedo_color = Color(0.24, 0.16, 0.11, 1.0)
	mat.roughness = 0.80
	box_mesh.material_override = mat
	box_mesh.position = Vector3(0, 0.019, 0)
	add_child(box_mesh)

	# 2. Cream Document Paper Core protruding between covers
	var paper_core = MeshInstance3D.new()
	var p_box = BoxMesh.new()
	p_box.size = Vector3(0.36, 0.024, 0.26)
	paper_core.mesh = p_box
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.90, 0.86, 0.74, 1.0)
	p_mat.roughness = 0.90
	paper_core.material_override = p_mat
	paper_core.position = Vector3(0.005, 0.019, 0)
	add_child(paper_core)

	# 3. Brass Latch & Riveted Seal
	latch_mesh = MeshInstance3D.new()
	var l_mesh = BoxMesh.new()
	l_mesh.size = Vector3(0.08, 0.040, 0.03)
	latch_mesh.mesh = l_mesh

	var l_mat = StandardMaterial3D.new()
	l_mat.albedo_color = Color(0.80, 0.65, 0.30, 1.0) # Aged brass
	l_mat.metallic = 0.85
	l_mat.roughness = 0.35
	latch_mesh.material_override = l_mat
	latch_mesh.position = Vector3(0, 0.020, 0.14)
	add_child(latch_mesh)

	# 4. Brass Corner Protectors
	for cx in [-0.18, 0.18]:
		for cz in [-0.13, 0.13]:
			var corner = MeshInstance3D.new()
			var c_box = BoxMesh.new()
			c_box.size = Vector3(0.030, 0.040, 0.030)
			corner.mesh = c_box
			corner.material_override = l_mat
			corner.position = Vector3(cx, 0.019, cz)
			add_child(corner)

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
	var header_meta = "%s — %s" % [doc_data.get("date", ""), doc_data.get("author", "")]
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
