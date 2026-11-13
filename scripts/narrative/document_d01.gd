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
const DATE_TEXT: String = "1894 г. // ГОРИЗОНТ IV // ЗАБОЙ 4-Б"
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
	box_mesh = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.38, 0.28, 0.18)
	box_mesh.mesh = mesh

	# Weathered oxidized tin/iron material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.24, 0.22, 0.20, 1.0)
	mat.metallic = 0.75
	mat.roughness = 0.65
	box_mesh.material_override = mat
	add_child(box_mesh)

	# Brass latch
	var latch = MeshInstance3D.new()
	var l_mesh = BoxMesh.new()
	l_mesh.size = Vector3(0.08, 0.06, 0.03)
	latch.mesh = l_mesh
	var l_mat = StandardMaterial3D.new()
	l_mat.albedo_color = Color(0.72, 0.58, 0.26)
	l_mat.metallic = 0.85
	l_mat.roughness = 0.35
	latch.material_override = l_mat
	latch.position = Vector3(0, 0, 0.10)
	add_child(latch)

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
