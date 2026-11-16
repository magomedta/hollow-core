# scripts/ui/ornate_ui.gd
class_name OrnateUI
extends RefCounted

## Minimalist High-End Subterranean UI Kit for Hollow Core.
## Inspired by Dishonored 2, Frostpunk, and Amnesia: The Bunker.
## - Sleek obsidian/slate background (#090C10)
## - Precision 1px etched brass & muted steel hairlines (#A68452, #47586E)
## - Elegant uppercase typography with generous tracking
## - Radical minimalism: zero heavy corner brackets, zero glassmorphism SaaS cards
## - Zero double-slashes: clean dashes (—), colons (:), and bullets (•)
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
const COLOR_GOLD = Color(0.92, 0.80, 0.55, 0.95)
const COLOR_AMBER = Color(0.96, 0.74, 0.30, 0.95)
const COLOR_STEEL = Color(0.60, 0.72, 0.85, 0.80)
const COLOR_MUTED = Color(0.55, 0.62, 0.72, 0.75)
const COLOR_DARK = Color(0.04, 0.05, 0.07, 0.96)

static func create_main_panel_stylebox() -> StyleBox:
	var flat = StyleBoxFlat.new()
	flat.bg_color = Color(0.035, 0.045, 0.060, 0.96)
	flat.border_color = Color(0.65, 0.52, 0.32, 0.85) # Crisp 1px antique brass hairline
	flat.set_border_width_all(1)
	flat.set_corner_radius_all(3)
	flat.shadow_color = Color(0.0, 0.0, 0.0, 0.80)
	flat.shadow_size = 24
	flat.content_margin_left = 28
	flat.content_margin_right = 28
	flat.content_margin_top = 22
	flat.content_margin_bottom = 22
	return flat

static func create_sub_panel_stylebox() -> StyleBox:
	var flat = StyleBoxFlat.new()
	flat.bg_color = Color(0.050, 0.065, 0.085, 0.90)
	flat.border_color = Color(0.30, 0.38, 0.48, 0.55) # Subtle slate hairline
	flat.set_border_width_all(1)
	flat.set_corner_radius_all(2)
	flat.content_margin_left = 14
	flat.content_margin_right = 14
	flat.content_margin_top = 10
	flat.content_margin_bottom = 10
	return flat

static func create_button_stylebox(state: String = "normal") -> StyleBox:
	var flat = StyleBoxFlat.new()
	flat.set_corner_radius_all(2)
	flat.content_margin_left = 14
	flat.content_margin_right = 14
	flat.content_margin_top = 7
	flat.content_margin_bottom = 7

	match state:
		"hover":
			flat.bg_color = Color(0.10, 0.13, 0.18, 0.95)
			flat.border_color = Color(0.92, 0.76, 0.38, 0.90)
			flat.set_border_width_all(1)
		"pressed", "active":
			flat.bg_color = Color(0.14, 0.12, 0.08, 0.98)
			flat.border_color = Color(0.95, 0.80, 0.35, 1.0)
			flat.set_border_width_all(2)
		_:
			flat.bg_color = Color(0.05, 0.07, 0.10, 0.88)
			flat.border_color = Color(0.28, 0.36, 0.46, 0.55)
			flat.set_border_width_all(1)
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
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.10, 0.85)
	style.border_color = Color(0.65, 0.52, 0.32, 0.70)
	style.border_width_bottom = 1
	style.border_width_top = 1
	style.border_width_left = 0
	style.border_width_right = 0
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(300, height)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = title
	label.add_theme_color_override("font_color", COLOR_GOLD)
	label.add_theme_font_size_override("font_size", 13)
	panel.add_child(label)
	return panel
