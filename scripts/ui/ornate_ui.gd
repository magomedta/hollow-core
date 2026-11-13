# scripts/ui/ornate_ui.gd
class_name OrnateUI
extends RefCounted

## Utility class for the Ornate Dark Fantasy / Steampunk UI Kit.
## Provides factory methods and stylebox configurations matching media_1794584154612_c29e3d32.jpg.
## - Double sapphire-steel borders (#2E4B6E)
## - Sculpted antique bronze / brass chiseled corner brackets (#CAA46E, #EEDAB0)
## - Deep abyssal slate background (#0A0D13)
## - Segmented crystal/LED pips with chevron endcap rails
## - Fully in Russian.

static var _cache: Dictionary = {}

static func get_texture(rel_path: String) -> Texture2D:
	if _cache.has(rel_path):
		return _cache[rel_path]
	
	var full_res_path = "res://" + rel_path
	if ResourceLoader.exists(full_res_path):
		var loaded = load(full_res_path)
		if loaded is Texture2D:
			_cache[rel_path] = loaded
			return loaded

	var global_path = ProjectSettings.globalize_path(full_res_path)
	var img = Image.new()
	var err = img.load(global_path)
	if err == OK:
		var itex = ImageTexture.create_from_image(img)
		_cache[rel_path] = itex
		return itex

	return null

# Palette constants
const COLOR_GOLD = Color(0.93, 0.85, 0.69)
const COLOR_AMBER = Color(0.96, 0.72, 0.28)
const COLOR_STEEL = Color(0.45, 0.65, 0.88)
const COLOR_MUTED = Color(0.60, 0.66, 0.75)
const COLOR_DARK = Color(0.04, 0.05, 0.07, 0.95)

static func create_main_panel_stylebox() -> StyleBox:
	var tex = get_texture("textures/ui/ornate_frame_9slice.png")
	if tex:
		var sb = StyleBoxTexture.new()
		sb.texture = tex
		sb.texture_margin_left = 36
		sb.texture_margin_right = 36
		sb.texture_margin_top = 36
		sb.texture_margin_bottom = 36
		sb.content_margin_left = 28
		sb.content_margin_right = 28
		sb.content_margin_top = 24
		sb.content_margin_bottom = 24
		return sb
	
	# Fallback flat stylebox if texture not found
	var flat = StyleBoxFlat.new()
	flat.bg_color = Color(0.035, 0.042, 0.052, 0.95)
	flat.border_color = Color(0.35, 0.55, 0.80, 0.9)
	flat.set_border_width_all(2)
	flat.set_corner_radius_all(3)
	flat.content_margin_left = 24
	flat.content_margin_right = 24
	flat.content_margin_top = 20
	flat.content_margin_bottom = 20
	return flat

static func create_sub_panel_stylebox() -> StyleBox:
	var tex = get_texture("textures/ui/ornate_frame_light_9slice.png")
	if tex:
		var sb = StyleBoxTexture.new()
		sb.texture = tex
		sb.texture_margin_left = 16
		sb.texture_margin_right = 16
		sb.texture_margin_top = 16
		sb.texture_margin_bottom = 16
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 12
		sb.content_margin_bottom = 12
		return sb

	var flat = StyleBoxFlat.new()
	flat.bg_color = Color(0.045, 0.055, 0.065, 0.85)
	flat.border_color = Color(0.25, 0.38, 0.55, 0.8)
	flat.set_border_width_all(1)
	flat.set_corner_radius_all(2)
	flat.content_margin_left = 12
	flat.content_margin_right = 12
	flat.content_margin_top = 8
	flat.content_margin_bottom = 8
	return flat

static func create_button_stylebox(state: String = "normal") -> StyleBox:
	var tex_name = "ornate_button_normal.png"
	match state:
		"hover": tex_name = "ornate_button_hover.png"
		"pressed": tex_name = "ornate_button_pressed.png"
	
	var tex = get_texture("textures/ui/" + tex_name)
	if tex:
		var sb = StyleBoxTexture.new()
		sb.texture = tex
		sb.texture_margin_left = 10
		sb.texture_margin_right = 10
		sb.texture_margin_top = 10
		sb.texture_margin_bottom = 10
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		return sb

	var flat = StyleBoxFlat.new()
	flat.bg_color = Color(0.06, 0.08, 0.11, 0.9)
	flat.border_color = Color(0.35, 0.55, 0.80, 0.8) if state == "hover" else Color(0.20, 0.30, 0.42, 0.7)
	flat.set_border_width_all(1)
	flat.content_margin_left = 10
	flat.content_margin_right = 10
	flat.content_margin_top = 6
	flat.content_margin_bottom = 6
	return flat

static func style_button(btn: Button, font_size: int = 12) -> void:
	btn.add_theme_stylebox_override("normal", create_button_stylebox("normal"))
	btn.add_theme_stylebox_override("hover", create_button_stylebox("hover"))
	btn.add_theme_stylebox_override("pressed", create_button_stylebox("pressed"))
	btn.add_theme_stylebox_override("focus", create_button_stylebox("hover"))
	btn.add_theme_color_override("font_color", COLOR_GOLD)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.85))
	btn.add_theme_color_override("font_pressed_color", COLOR_AMBER)
	btn.add_theme_font_size_override("font_size", font_size)

static func create_header_banner(title: String, height: int = 38) -> Control:
	var banner = NinePatchRect.new()
	var tex = get_texture("textures/ui/ornate_header_plaque.png")
	if tex:
		banner.texture = tex
		banner.patch_margin_left = 40
		banner.patch_margin_right = 40
		banner.patch_margin_top = 8
		banner.patch_margin_bottom = 8
	banner.custom_minimum_size = Vector2(280, height)
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var label = Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = title
	label.add_theme_color_override("font_color", COLOR_GOLD)
	label.add_theme_font_size_override("font_size", 13)
	banner.add_child(label)
	
	return banner
