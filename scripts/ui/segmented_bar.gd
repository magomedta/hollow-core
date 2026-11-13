# scripts/ui/segmented_bar.gd
class_name SegmentedProgressBar
extends Control

## Segmented Crystal/LED Progress Bar in the Ornate Steampunk Style
## Features bronze chevron endcaps, sapphire steel rails, and discrete pips.

const OrnateUIClass = preload("res://scripts/ui/ornate_ui.gd")

@export var pip_count: int = 16
@export var variant: String = "amber" # "amber", "red", "green", "blue"
@export var bar_title: String = ""

var value: float = 1.0 : set = set_value

var bg_ninepatch: NinePatchRect
var pips_container: HBoxContainer
var title_label: Label
var pct_label: Label
var pip_rects: Array[TextureRect] = []

func _init(p_count: int = 16, p_variant: String = "amber", p_title: String = "") -> void:
	pip_count = p_count
	variant = p_variant
	bar_title = p_title
	custom_minimum_size = Vector2(260, 44)

func _ready() -> void:
	_build_bar()
	update_display()

func _build_bar() -> void:
	for c in get_children():
		c.queue_free()
	pip_rects.clear()

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)

	# Optional title and % readout row
	var header_hbox = HBoxContainer.new()
	title_label = Label.new()
	title_label.text = bar_title
	title_label.add_theme_color_override("font_color", OrnateUIClass.COLOR_GOLD)
	title_label.add_theme_font_size_override("font_size", 11)
	header_hbox.add_child(title_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)

	pct_label = Label.new()
	pct_label.text = "%d%%" % int(round(value * 100.0))
	pct_label.add_theme_color_override("font_color", OrnateUIClass.COLOR_MUTED)
	pct_label.add_theme_font_size_override("font_size", 10)
	header_hbox.add_child(pct_label)
	vbox.add_child(header_hbox)

	# The Bar Rail Container
	var rail_box = Control.new()
	rail_box.custom_minimum_size = Vector2(240, 26)
	rail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(rail_box)

	bg_ninepatch = NinePatchRect.new()
	var rail_tex = OrnateUIClass.get_texture("textures/ui/ornate_bar_frame_9slice.png")
	if rail_tex:
		bg_ninepatch.texture = rail_tex
		bg_ninepatch.patch_margin_left = 30
		bg_ninepatch.patch_margin_right = 30
		bg_ninepatch.patch_margin_top = 6
		bg_ninepatch.patch_margin_bottom = 6
	bg_ninepatch.set_anchors_preset(Control.PRESET_FULL_RECT)
	rail_box.add_child(bg_ninepatch)

	# Centered pips row
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	rail_box.add_child(margin)

	pips_container = HBoxContainer.new()
	pips_container.alignment = BoxContainer.ALIGNMENT_CENTER
	pips_container.add_theme_constant_override("separation", 3)
	margin.add_child(pips_container)

	var initial_tex = _get_active_texture()
	for i in range(pip_count):
		var pr = TextureRect.new()
		pr.custom_minimum_size = Vector2(8, 16)
		pr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pr.texture = initial_tex
		pips_container.add_child(pr)
		pip_rects.append(pr)

func _get_active_texture() -> Texture2D:
	var path = "textures/ui/pip_amber.png"
	match variant:
		"red": path = "textures/ui/pip_red.png"
		"green": path = "textures/ui/pip_green.png"
		"blue": path = "textures/ui/pip_blue.png"
	return OrnateUIClass.get_texture(path)

func _get_empty_texture() -> Texture2D:
	return OrnateUIClass.get_texture("textures/ui/pip_empty.png")

func set_value(p_val: float) -> void:
	value = clamp(p_val, 0.0, 1.0)
	update_display()

func set_variant(p_variant: String) -> void:
	variant = p_variant
	update_display()

func set_title(p_title: String) -> void:
	bar_title = p_title
	if title_label:
		title_label.text = bar_title

func update_display() -> void:
	if pct_label:
		pct_label.text = "%d%%" % int(round(value * 100.0))
	if title_label and bar_title != "":
		title_label.text = bar_title

	var active_tex = _get_active_texture()
	var empty_tex = _get_empty_texture()

	var filled_count = int(round(value * float(pip_count)))
	for i in range(pip_rects.size()):
		if i < filled_count:
			pip_rects[i].texture = active_tex
		else:
			pip_rects[i].texture = empty_tex
