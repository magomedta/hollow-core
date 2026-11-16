# scripts/narrative/document_d01.gd
class_name DocumentD01Prop
extends Area3D

## In-world interactive dispatch container for Document D-01:
## "Страница из вахтенного журнала шурфа №7 (1894 г.)"

signal document_read_event(doc_id: String)

@export var document_id: String = "D-01"
var is_read: bool = false
var box_mesh: MeshInstance3D

const TITLE_TEXT: String = "ВАХТЕННЫЙ ЖУРНАЛ ШУРФА №7 (АРТЕЛЬ 'СЕВЕР')"
const DATE_TEXT: String = "1894 г. — ГОРИЗОНТ IV — ЗАБОЙ 4-Б"
const BODY_TEXT: String = """«14 ноября. Забой 4-Б сухой. Артельщик Прохоров пожаловался, что порода перед ним вздыхает. Наложил штраф в полтинник за суеверие.

16 ноября. Прохоров не вышел. Нашли его в штреке: сидит на коленях, прижав ухо к гранитному забою. Зубы сжаты так, что лопнули резцы. Шепчет: 'Она зовет меня по имени-отчеству'. Отправили наверх в лазарет.

18 ноября. Лазарет сообщает: Прохоров ночью разбил окно и сбежал обратно вниз. Без сапог и фонаря. В стволе №2 слышали его смех. Мы заложили ствол дубовым брусом на шесть клиньев»."""

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("lore_documents")
	collision_layer = 4 | 8 # Item layer + interactable
	collision_mask = 0

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.45, 0.35, 0.25)
	col.shape = box
	add_child(col)

	_build_visuals()

func _build_visuals() -> void:
	# Handcrafted Low-Poly Open Surveyor's Field Journal (1894 г.)
	var journal_root = Node3D.new()
	journal_root.name = "JournalVisuals"
	add_child(journal_root)

	# 1. Dark Brown Embossed Leather Cover (Open flat on table)
	var leather_mat = StandardMaterial3D.new()
	leather_mat.albedo_color = Color(0.22, 0.14, 0.09, 1.0) # Aged dark morocco leather
	leather_mat.roughness = 0.85

	box_mesh = MeshInstance3D.new()
	var cover_box = BoxMesh.new()
	cover_box.size = Vector3(0.44, 0.016, 0.32)
	box_mesh.mesh = cover_box
	box_mesh.material_override = leather_mat
	box_mesh.position = Vector3(0, 0.008, 0)
	journal_root.add_child(box_mesh)

	# 2. Cream Open Parchment Pages with Hand-Cut Deckle Edges
	var paper_mat = StandardMaterial3D.new()
	paper_mat.albedo_color = Color(0.92, 0.88, 0.76, 1.0) # Aged vintage rag paper
	paper_mat.roughness = 0.90

	for px in [-0.105, 0.105]:
		var page = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(0.195, 0.018, 0.285)
		page.mesh = p_box
		page.material_override = paper_mat
		page.position = Vector3(px, 0.018, 0)
		# Slight angle for open book pages
		page.rotation_degrees = Vector3(0, 0, -2.5 if px < 0 else 2.5)
		journal_root.add_child(page)

	# 3. Ink ruled ledger lines & handwritten markings
	var ink_mat = StandardMaterial3D.new()
	ink_mat.albedo_color = Color(0.28, 0.25, 0.22, 1.0)
	ink_mat.roughness = 0.95

	for lz in [-0.08, -0.04, 0.0, 0.04, 0.08]:
		for lx in [-0.105, 0.105]:
			var line = MeshInstance3D.new()
			var l_box = BoxMesh.new()
			l_box.size = Vector3(0.16, 0.020, 0.004)
			line.mesh = l_box
			line.material_override = ink_mat
			line.position = Vector3(lx, 0.027, lz)
			journal_root.add_child(line)

	# 4. Red Silk Bookmark Ribbon trailing across the pages
	var ribbon_mat = StandardMaterial3D.new()
	ribbon_mat.albedo_color = Color(0.68, 0.16, 0.16, 1.0)
	ribbon_mat.roughness = 0.70

	var ribbon = MeshInstance3D.new()
	var r_box = BoxMesh.new()
	r_box.size = Vector3(0.016, 0.022, 0.36)
	ribbon.mesh = r_box
	ribbon.material_override = ribbon_mat
	ribbon.position = Vector3(0.015, 0.028, 0.02)
	ribbon.rotation_degrees = Vector3(0, 8.0, 0)
	journal_root.add_child(ribbon)

	# 5. Brass Corner Protectors
	var brass_mat = StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.80, 0.66, 0.32, 1.0)
	brass_mat.metallic = 0.85
	brass_mat.roughness = 0.35

	for cx in [-0.21, 0.21]:
		for cz in [-0.15, 0.15]:
			var corner = MeshInstance3D.new()
			var c_box = BoxMesh.new()
			c_box.size = Vector3(0.035, 0.020, 0.035)
			corner.mesh = c_box
			corner.material_override = brass_mat
			corner.position = Vector3(cx, 0.010, cz)
			journal_root.add_child(corner)

	# 6. Brass Surveyor's Drafting Calipers resting on the ledger
	var caliper_root = Node3D.new()
	caliper_root.position = Vector3(0.18, 0.032, 0.08)
	caliper_root.rotation_degrees = Vector3(0, -25.0, 0)
	journal_root.add_child(caliper_root)

	for leg_rot in [-12.0, 12.0]:
		var cal_leg = MeshInstance3D.new()
		var cl_box = BoxMesh.new()
		cl_box.size = Vector3(0.006, 0.006, 0.12)
		cal_leg.mesh = cl_box
		cal_leg.material_override = brass_mat
		cal_leg.position = Vector3(0, 0, 0.05)
		cal_leg.rotation_degrees = Vector3(0, leg_rot, 0)
		caliper_root.add_child(cal_leg)

func get_interaction_prompt() -> String:
	return "Прочитать: Вахтенный Журнал Забоя 4-Б (1894 г.)"

func interact(_player: CharacterBody3D) -> bool:
	is_read = true
	document_read_event.emit(document_id)

	# Locate or spawn DocumentViewer
	var viewer = get_tree().get_first_node_in_group("document_viewer") as CanvasLayer
	if viewer == null:
		viewer = get_tree().root.get_node_or_null("DocumentViewer") as CanvasLayer
	if viewer != null and viewer.has_method("show_document"):
		viewer.show_document(document_id, TITLE_TEXT, DATE_TEXT, BODY_TEXT)
	return true
