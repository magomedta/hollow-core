# scripts/ui/sleek_hud.gd
class_name SleekHUD
extends RefCounted

## High-End Minimalist Subterranean Expedition HUD.
## Inspired by Dishonored 2, Frostpunk, and Amnesia: The Bunker.
## Features radical minimalism, floating typography, etched brass hairlines,
## a precision vernier kerosene gauge, and contextual interactive reticle.
## All controls have mouse_filter = MOUSE_FILTER_IGNORE so mouse camera look is 100% unimpeded.

const COLOR_GOLD_TITLE = Color(0.85, 0.72, 0.45, 0.90)
const COLOR_WHITE_PRIMARY = Color(0.95, 0.96, 0.98, 0.95)
const COLOR_STEEL_MUTED = Color(0.62, 0.72, 0.84, 0.75)
const COLOR_AMBER_BRIGHT = Color(0.98, 0.68, 0.18, 0.95)
const COLOR_AMBER_TEXT = Color(0.92, 0.82, 0.55, 0.90)
const COLOR_HINT_MUTED = Color(0.55, 0.62, 0.70, 0.75)
const COLOR_DANGER_RED = Color(0.95, 0.25, 0.20, 0.95)

static func get_texture(rel_path: String) -> Texture2D:
	var full_res = "res://" + rel_path
	if ResourceLoader.exists(full_res):
		return load(full_res)
	var global_path = ProjectSettings.globalize_path(full_res)
	if FileAccess.file_exists(global_path):
		var img = Image.new()
		var err = img.load(global_path)
		if err == OK:
			return ImageTexture.create_from_image(img)
	return null

## Builds the complete minimalist floating HUD
static func build_hud(canvas: CanvasLayer) -> Dictionary:
	var result = {}

	# -------------------------------------------------------------------------
	# 1. Top-Left: Sleek Expedition Cluster (Floating, no heavy box)
	# -------------------------------------------------------------------------
	var cluster = Control.new()
	cluster.name = "ExpeditionCluster"
	cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cluster.position = Vector2(36, 32)
	cluster.custom_minimum_size = Vector2(380, 180)
	canvas.add_child(cluster)
	result["cluster"] = cluster

	var vbox = VBoxContainer.new()
	vbox.name = "TelemetryVBox"
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	cluster.add_child(vbox)

	# Small category header
	var cat_label = Label.new()
	cat_label.name = "CategoryLabel"
	cat_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cat_label.text = "ЭКСПЕДИЦИОННЫЙ ГОРИЗОНТ"
	cat_label.add_theme_color_override("font_color", COLOR_GOLD_TITLE)
	cat_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(cat_label)

	# Primary Depth & Stratum Line (Crisp, bold, prominent)
	var depth_label = Label.new()
	depth_label.name = "DepthLabel"
	depth_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	depth_label.text = "1420 м  •  ЛЕДНИКОВЫЕ ШПИЛИ"
	depth_label.add_theme_color_override("font_color", COLOR_WHITE_PRIMARY)
	depth_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(depth_label)
	result["depth_label"] = depth_label

	# Compass / Azimuth reading
	var compass_label = Label.new()
	compass_label.name = "CompassLabel"
	compass_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	compass_label.text = "КОМПАС  [ N 000° ]"
	compass_label.add_theme_color_override("font_color", COLOR_STEEL_MUTED)
	compass_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(compass_label)
	result["compass_label"] = compass_label

	# Etched brass hairline divider
	var div_tex = get_texture("textures/ui_sleek/expedition_hud_divider.png")
	if div_tex:
		var div_rect = TextureRect.new()
		div_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		div_rect.texture = div_tex
		div_rect.custom_minimum_size = Vector2(360, 8)
		div_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox.add_child(div_rect)
	else:
		# Fallback hairline
		var line = ColorRect.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.custom_minimum_size = Vector2(320, 1)
		line.color = Color(0.70, 0.55, 0.32, 0.60)
		vbox.add_child(line)

	# -------------------------------------------------------------------------
	# 2. Sleek Kerosene Fuel Gauge (Surveyor Vernier Rail)
	# -------------------------------------------------------------------------
	var fuel_container = VBoxContainer.new()
	fuel_container.name = "FuelContainer"
	fuel_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fuel_container.add_theme_constant_override("separation", 2)
	vbox.add_child(fuel_container)

	var fuel_header_hbox = HBoxContainer.new()
	fuel_header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fuel_header_hbox.custom_minimum_size = Vector2(280, 14)
	fuel_container.add_child(fuel_header_hbox)

	var fuel_title = Label.new()
	fuel_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fuel_title.text = "КЕРОСИН ФОНАРЯ"
	fuel_title.add_theme_color_override("font_color", COLOR_GOLD_TITLE)
	fuel_title.add_theme_font_size_override("font_size", 10)
	fuel_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fuel_header_hbox.add_child(fuel_title)

	var fuel_pct_lbl = Label.new()
	fuel_pct_lbl.name = "FuelPctLabel"
	fuel_pct_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fuel_pct_lbl.text = "100%"
	fuel_pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fuel_pct_lbl.add_theme_color_override("font_color", COLOR_AMBER_BRIGHT)
	fuel_pct_lbl.add_theme_font_size_override("font_size", 11)
	fuel_header_hbox.add_child(fuel_pct_lbl)
	result["fuel_pct_lbl"] = fuel_pct_lbl

	# Slender progress bar
	var bar_track = Panel.new()
	bar_track.name = "FuelTrack"
	bar_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_track.custom_minimum_size = Vector2(280, 8)

	var track_style = StyleBoxFlat.new()
	track_style.bg_color = Color(0.04, 0.06, 0.09, 0.85)
	track_style.border_color = Color(0.55, 0.42, 0.25, 0.75) # Fine antique brass rim
	track_style.set_border_width_all(1)
	track_style.set_corner_radius_all(2)
	bar_track.add_theme_stylebox_override("panel", track_style)
	fuel_container.add_child(bar_track)

	var bar_fill = ColorRect.new()
	bar_fill.name = "FuelFill"
	bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_fill.color = COLOR_AMBER_BRIGHT
	bar_fill.position = Vector2(1, 1)
	bar_fill.size = Vector2(278, 6)
	bar_track.add_child(bar_fill)
	result["fuel_fill"] = bar_fill
	result["fuel_track"] = bar_track

	# -------------------------------------------------------------------------
	# 3. Active Mission Objective Line
	# -------------------------------------------------------------------------
	var obj_spacer = Control.new()
	obj_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	obj_spacer.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(obj_spacer)

	var obj_hbox = HBoxContainer.new()
	obj_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	obj_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(obj_hbox)

	var obj_icon = Label.new()
	obj_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	obj_icon.text = "◈"
	obj_icon.add_theme_color_override("font_color", COLOR_AMBER_BRIGHT)
	obj_icon.add_theme_font_size_override("font_size", 12)
	obj_hbox.add_child(obj_icon)

	var objective_label = Label.new()
	objective_label.name = "ObjectiveLabel"
	objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_label.text = "Найти аварийный фонарь и кирку геолога среди обломков"
	objective_label.add_theme_color_override("font_color", COLOR_AMBER_TEXT)
	objective_label.add_theme_font_size_override("font_size", 11)
	obj_hbox.add_child(objective_label)
	result["objective_label"] = objective_label

	# -------------------------------------------------------------------------
	# 4. Precision Antique Reticle (Center Dot + 4 subtle vernier ticks)
	# -------------------------------------------------------------------------
	var reticle_ctrl = Control.new()
	reticle_ctrl.name = "PrecisionReticle"
	reticle_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reticle_ctrl.set_anchors_preset(Control.PRESET_CENTER)
	reticle_ctrl.position = Vector2.ZERO
	canvas.add_child(reticle_ctrl)

	var reticle_tex = get_texture("textures/ui_sleek/sleek_reticle.png")
	var reticle_rect = TextureRect.new()
	reticle_rect.name = "ReticleRect"
	reticle_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reticle_rect.custom_minimum_size = Vector2(32, 32)
	reticle_rect.position = Vector2(-16, -16)
	if reticle_tex:
		reticle_rect.texture = reticle_tex
	else:
		# Fallback procedural crosshair
		var p_dot = ColorRect.new()
		p_dot.size = Vector2(2, 2)
		p_dot.position = Vector2(-1, -1)
		p_dot.color = Color(0.95, 0.90, 0.80, 0.9)
		reticle_ctrl.add_child(p_dot)
	reticle_ctrl.add_child(reticle_rect)
	result["reticle_rect"] = reticle_rect
	result["reticle_ctrl"] = reticle_ctrl

	# -------------------------------------------------------------------------
	# 5. Floating Interaction Prompt Plate (Center Lower Third)
	# -------------------------------------------------------------------------
	var prompt_ctrl = Control.new()
	prompt_ctrl.name = "InteractionPromptRoot"
	prompt_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_ctrl.set_anchors_preset(Control.PRESET_CENTER)
	prompt_ctrl.visible = false
	canvas.add_child(prompt_ctrl)

	var prompt_panel = PanelContainer.new()
	prompt_panel.name = "PromptPanel"
	prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_panel.custom_minimum_size = Vector2(440, 34)
	prompt_panel.position = Vector2(-220, 48) # 48px below crosshair

	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.04, 0.06, 0.09, 0.88) # Smoked obsidian
	p_style.border_color = Color(0.75, 0.60, 0.35, 0.85) # Fine antique brass hairline
	p_style.set_border_width_all(1)
	p_style.set_corner_radius_all(3)
	p_style.content_margin_left = 16
	p_style.content_margin_right = 16
	p_style.content_margin_top = 4
	p_style.content_margin_bottom = 4
	prompt_panel.add_theme_stylebox_override("panel", p_style)

	var prompt_label = Label.new()
	prompt_label.name = "PromptLabel"
	prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.text = "[ E ]  ПОДОБРАТЬ ЭКСПЕДИЦИОННЫЙ ФОНАРЬ"
	prompt_label.add_theme_color_override("font_color", COLOR_WHITE_PRIMARY)
	prompt_label.add_theme_font_size_override("font_size", 12)
	prompt_panel.add_child(prompt_label)
	prompt_ctrl.add_child(prompt_panel)

	result["prompt_ctrl"] = prompt_ctrl
	result["prompt_label"] = prompt_label

	# -------------------------------------------------------------------------
	# 6. Save Notice Banner (Floating bottom-left)
	# -------------------------------------------------------------------------
	var save_notice = Label.new()
	save_notice.name = "SaveNotice"
	save_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	save_notice.position = Vector2(36, 210)
	save_notice.add_theme_color_override("font_color", Color(0.45, 0.80, 0.55, 0.90))
	save_notice.add_theme_font_size_override("font_size", 11)
	save_notice.text = ""
	canvas.add_child(save_notice)
	result["save_notice"] = save_notice

	return result

## Updates the HUD state cleanly and efficiently
static func update_display(hud_refs: Dictionary, depth_m: int, stratum_name: String, compass_deg: int,
                           fuel_pct: float, is_lantern_lit: bool, objective_text: String) -> void:
	if hud_refs.has("depth_label") and hud_refs["depth_label"]:
		hud_refs["depth_label"].text = "%d м  •  %s" % [depth_m, stratum_name.to_upper()]

	if hud_refs.has("compass_label") and hud_refs["compass_label"]:
		var dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
		var idx = int(round(compass_deg / 45.0)) % 8
		hud_refs["compass_label"].text = "КОМПАС  [ %s %03d° ]" % [dirs[idx], compass_deg]

	if hud_refs.has("fuel_pct_lbl") and hud_refs["fuel_pct_lbl"]:
		hud_refs["fuel_pct_lbl"].text = "%d%%" % int(fuel_pct)
		if fuel_pct < 15.0:
			hud_refs["fuel_pct_lbl"].add_theme_color_override("font_color", COLOR_DANGER_RED)
		else:
			hud_refs["fuel_pct_lbl"].add_theme_color_override("font_color", COLOR_AMBER_BRIGHT)

	if hud_refs.has("fuel_fill") and hud_refs["fuel_fill"]:
		var fill_node: ColorRect = hud_refs["fuel_fill"]
		var max_w = 278.0
		fill_node.size.x = clamp(max_w * (fuel_pct / 100.0), 0.0, max_w)
		if not is_lantern_lit:
			fill_node.color = Color(0.35, 0.40, 0.48, 0.50) # Grayed out when off
		elif fuel_pct < 15.0:
			fill_node.color = COLOR_DANGER_RED
		else:
			fill_node.color = COLOR_AMBER_BRIGHT

	if hud_refs.has("objective_label") and hud_refs["objective_label"]:
		hud_refs["objective_label"].text = objective_text
