# scripts/narrative/document_viewer.gd
class_name DocumentViewer
extends CanvasLayer

## Diegetic vintage document inspection overlay.
## Displays historic field logs and reports on weathered parchment
## with period typography, avoiding sci-fi HUD tropes.

const OrnateUIClass = preload("res://scripts/ui/ornate_ui.gd")

signal document_closed(doc_id: String)

var active_doc_id: String = ""
var was_opened_from_journal: bool = false
var outer_mount_panel: PanelContainer
var background_panel: PanelContainer
var title_label: Label
var date_label: Label
var body_label: Label
var close_btn: Button
var close_hint: Label

func _ready() -> void:
	add_to_group("document_viewer")
	layer = 105
	visible = false
	_build_ui()

func _build_ui() -> void:
	# Semi-transparent dark vignette backdrop
	var backdrop = ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.offset_left = 0
	backdrop.offset_top = 0
	backdrop.offset_right = 0
	backdrop.offset_bottom = 0
	backdrop.color = Color(0.015, 0.02, 0.03, 0.88)
	add_child(backdrop)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.offset_left = 0
	center.offset_top = 0
	center.offset_right = 0
	center.offset_bottom = 0
	center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(center)

	# Ornate outer mount frame
	outer_mount_panel = PanelContainer.new()
	outer_mount_panel.custom_minimum_size = Vector2(700, 560)
	outer_mount_panel.add_theme_stylebox_override("panel", OrnateUIClass.create_main_panel_stylebox())

	var outer_vbox = VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 10)
	outer_mount_panel.add_child(outer_vbox)

	var header_banner = OrnateUIClass.create_header_banner("АРХИВНЫЙ МАТЕРИАЛ // ЭКСПЕДИЦИОННОЕ ДЕЛО", 36)
	outer_vbox.add_child(header_banner)

	# Inner weathered parchment panel
	background_panel = PanelContainer.new()
	background_panel.custom_minimum_size = Vector2(630, 410)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.88, 0.84, 0.74, 1.0) # Aged yellowed paper
	style.border_color = Color(0.24, 0.20, 0.16, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	background_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	background_panel.add_child(vbox)

	title_label = Label.new()
	title_label.text = "ВАХТЕННЫЙ ЖУРНАЛ ШУРФА №7"
	title_label.add_theme_color_override("font_color", Color(0.18, 0.14, 0.10))
	title_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title_label)

	date_label = Label.new()
	date_label.text = "1894 г. // ЗАБОЙ 4-Б"
	date_label.add_theme_color_override("font_color", Color(0.42, 0.35, 0.28))
	date_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(date_label)

	var separator = HSeparator.new()
	vbox.add_child(separator)

	body_label = Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_color_override("font_color", Color(0.12, 0.10, 0.08))
	body_label.add_theme_font_size_override("font_size", 13)
	body_label.custom_minimum_size = Vector2(560, 240)
	vbox.add_child(body_label)

	outer_vbox.add_child(background_panel)

	# Footer action row with styled button
	var footer_hbox = HBoxContainer.new()
	footer_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	footer_hbox.add_theme_constant_override("separation", 16)

	close_btn = Button.new()
	close_btn.text = "ЗАКРЫТЬ ДОКУМЕНТ [E / ESC]"
	close_btn.custom_minimum_size = Vector2(240, 34)
	OrnateUIClass.style_button(close_btn, 11)
	close_btn.pressed.connect(close_document)
	footer_hbox.add_child(close_btn)

	outer_vbox.add_child(footer_hbox)

	center.add_child(outer_mount_panel)

func show_document(doc_id: String, title: String, date_str: String, text_content: String) -> void:
	active_doc_id = doc_id
	title_label.text = title
	date_label.text = date_str
	body_label.text = text_content
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Play paper rustle sound
	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("item_pickup", Vector3.ZERO, 0.7, -4.0)

	# Cleanly tuck away player viewmodel / tools so they NEVER clip through ceiling or overlap document
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if "viewmodel_layer" in p and p.viewmodel_layer:
			p.viewmodel_layer.visible = false
		if "pickaxe" in p and p.pickaxe:
			p.pickaxe.visible = false
		if "lantern" in p and p.lantern:
			p.lantern.visible = false

func hide_document() -> void:
	if visible:
		visible = false
		var players = get_tree().get_nodes_in_group("player")
		for p in players:
			if "viewmodel_layer" in p and p.viewmodel_layer:
				p.viewmodel_layer.visible = true
			if "pickaxe" in p and p.pickaxe and p.pickaxe.is_active:
				p.pickaxe.visible = true
			if "lantern" in p and p.lantern and p.lantern.is_held_in_hand:
				p.lantern.visible = true
		document_closed.emit(active_doc_id)
		active_doc_id = ""

		if was_opened_from_journal:
			was_opened_from_journal = false
			var journal = get_tree().get_first_node_in_group("field_journal")
			if journal and journal.has_method("open_journal"):
				journal.open_journal()
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_E or event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE:
			get_viewport().set_input_as_handled()
			hide_document()
