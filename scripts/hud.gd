# scripts/hud.gd
extends CanvasLayer

var player: CharacterBody3D
var lantern: Node3D

# UI Elements
var depth_label: Label
var sector_label: Label
var thermal_label: Label
var directive_label: Label
var fuel_label: Label
var fuel_bar: Control
var compass_container: Control
var reticle: Control
var status_label: Label
var resource_label: Label
var hint_label: Label
var quick_bar_container: Control

var current_fuel_pct: float = 1.0
var is_lantern_lit: bool = true
var current_heading_deg: float = 0.0
var current_depth_m: float = 1420.0
var current_active_slot: int = 1
var progression_phase: int = 1

var inventory: Dictionary = {
	"timber": 4,
	"cobblestone": 0,
	"iron": 0,
	"calcite": 0,
	"phosphor": 0
}

func _ready() -> void:
	layer = 10
	_build_ui_nodes()

func set_player(p_player: CharacterBody3D) -> void:
	player = p_player
	if player:
		if "lantern" in player and player.lantern:
			lantern = player.lantern
			if lantern.has_signal("fuel_changed"):
				lantern.fuel_changed.connect(_on_fuel_changed)
			if lantern.has_signal("lantern_toggled"):
				lantern.lantern_toggled.connect(_on_lantern_toggled)

		if player.has_signal("active_slot_changed"):
			player.active_slot_changed.connect(_on_active_slot_changed)
		if player.has_signal("inventory_changed"):
			player.inventory_changed.connect(_on_inventory_changed)
		if player.has_signal("progression_phase_changed"):
			player.progression_phase_changed.connect(_on_progression_phase_changed)
		if "inventory" in player:
			inventory = player.inventory.duplicate()
			_update_resource_display()
		if "progression_phase" in player:
			progression_phase = player.progression_phase
			_update_resource_display()
		if "active_slot" in player:
			current_active_slot = player.active_slot

func _on_fuel_changed(current: float, max_f: float) -> void:
	current_fuel_pct = clamp(current / max_f, 0.0, 1.0)
	if fuel_bar:
		fuel_bar.queue_redraw()

func _on_lantern_toggled(is_on: bool) -> void:
	is_lantern_lit = is_on
	if fuel_bar:
		fuel_bar.queue_redraw()

func _on_active_slot_changed(slot: int) -> void:
	current_active_slot = slot
	if quick_bar_container:
		quick_bar_container.queue_redraw()
	_update_hint_display()

func _on_progression_phase_changed(phase: int) -> void:
	progression_phase = phase
	_update_resource_display()

func _on_inventory_changed(inv: Dictionary) -> void:
	inventory = inv.duplicate()
	_update_resource_display()

func _update_hint_display() -> void:
	if hint_label == null:
		return
	hint_label.text = "[1-8] HOTBAR   [HOLD LMB] MINE/DIG   [RMB] PLACE BLOCK   [E / TAB] INVENTORY   [C] CRAFT   [F] LANTERN"
	hint_label.add_theme_color_override("font_color", Color(0.70, 0.74, 0.78, 0.85))

func _update_resource_display() -> void:
	var timber = inventory.get("timber", 0)
	var cobble = inventory.get("cobblestone", 0)
	var iron = inventory.get("iron", 0)
	var calcite = inventory.get("calcite", 0)
	var phosphor = inventory.get("phosphor", 0)

	if resource_label:
		resource_label.text = "TIMBER: x%d   COBBLE: x%d   IRON: x%d   CALCITE: x%d   PHOSPHOR: x%d" % [
			timber, cobble, iron, calcite, phosphor
		]

	if directive_label:
		match progression_phase:
			1:
				directive_label.text = "EXPEDITION DIRECTIVE [1/5]: SALVAGE TIMBER FROM CAMP CRATES (TIMBER: %d/4)" % timber
				directive_label.add_theme_color_override("font_color", Color(0.95, 0.76, 0.25))
			2:
				directive_label.text = "EXPEDITION DIRECTIVE [2/5]: OPEN WORKBENCH [KEY C] & CRAFT WOODEN PICKAXE"
				directive_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
			3:
				directive_label.text = "EXPEDITION DIRECTIVE [3/5]: DESCEND TRAIL & HARVEST COBBLESTONE OUTCROPS (COBBLE: %d/4)" % cobble
				directive_label.add_theme_color_override("font_color", Color(0.85, 0.82, 0.70))
			4:
				directive_label.text = "EXPEDITION DIRECTIVE [4/5]: FORGE STONE TOOLS & CROSS THE ABYSSAL CHASM"
				directive_label.add_theme_color_override("font_color", Color(0.20, 0.88, 0.95))
			5:
				directive_label.text = "EXPEDITION DIRECTIVE [5/5]: AWAKEN THE ANCIENT PRECURSOR ARCHWAY AT EAST PLATEAU"
				directive_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.30))
			_:
				directive_label.text = "EXPEDITION COMPLETE // ANCIENT ARCHWAY RESONATING // TOTAL SUBTERRANEAN FREEDOM"
				directive_label.add_theme_color_override("font_color", Color(0.35, 0.95, 0.55))

func _process(_delta: float) -> void:
	if player:
		if player.has_method("get_current_depth_meters"):
			current_depth_m = player.get_current_depth_meters()
		if player.has_method("get_compass_heading_degrees"):
			current_heading_deg = player.get_compass_heading_degrees()

		if depth_label:
			depth_label.text = "DEPTH  -%s M" % _format_number(int(current_depth_m))

		# Multi-Level Vertical Strata & Dynamic Depth-Temperature System
		var current_temp_c: float = 15.0
		var temp_str: String = ""
		var temp_color: Color = Color(0.65, 0.75, 0.82)
		var sector_str: String = ""

		if current_depth_m < 600.0:
			var t_norm = clamp(current_depth_m / 600.0, 0.0, 1.0)
			current_temp_c = lerp(-32.0, -8.0, t_norm)
			sector_str = "STRATUM I // THE FROZEN CRUST (SURFACE WINTER)"
			temp_str = "TEMP %d°C // SUB-ZERO PERMAFROST" % int(current_temp_c)
			temp_color = Color(0.45, 0.82, 1.0)
		elif current_depth_m < 1100.0:
			var t_norm = clamp((current_depth_m - 600.0) / 500.0, 0.0, 1.0)
			current_temp_c = lerp(-8.0, 8.0, t_norm)
			sector_str = "STRATUM II // CHILLED KARST & FROST SEAMS"
			temp_str = "TEMP %+d°C // BOREAL CAVERN" % int(current_temp_c)
			temp_color = Color(0.60, 0.85, 0.90)
		elif current_depth_m < 1700.0:
			var t_norm = clamp((current_depth_m - 1100.0) / 600.0, 0.0, 1.0)
			current_temp_c = lerp(8.0, 22.0, t_norm)
			sector_str = "STRATUM III // THE HOLLOW CORE (THE GREAT DESCENT)"
			temp_str = "TEMP %+d°C // TEMPERATE BASALT" % int(current_temp_c)
			temp_color = Color(0.70, 0.78, 0.85)
		elif current_depth_m < 2300.0:
			var t_norm = clamp((current_depth_m - 1700.0) / 600.0, 0.0, 1.0)
			current_temp_c = lerp(22.0, 75.0, t_norm)
			sector_str = "STRATUM IV // GEOTHERMAL ABYSS & SULFUR SEAMS"
			temp_str = "TEMP %+d°C // THERMAL UPWELLING" % int(current_temp_c)
			temp_color = Color(1.0, 0.65, 0.25)
		else:
			var t_norm = clamp((current_depth_m - 2300.0) / 700.0, 0.0, 1.0)
			current_temp_c = lerp(75.0, 240.0, t_norm)
			sector_str = "STRATUM V // THE PLANETARY CORE (MOLTEN MANTLE)"
			temp_str = "TEMP %+d°C // MAGMATIC HEAT [CRITICAL]" % int(current_temp_c)
			temp_color = Color(1.0, 0.35, 0.15)

		if sector_label:
			sector_label.text = sector_str
		if thermal_label:
			thermal_label.text = temp_str
			thermal_label.add_theme_color_override("font_color", temp_color)

		if compass_container:
			compass_container.queue_redraw()

	if fuel_label:
		var status_str = "ACTIVE" if is_lantern_lit else "OFF"
		if current_fuel_pct <= 0.0:
			status_str = "DEPLETED"
		fuel_label.text = "LANTERN // %s  %d%%" % [status_str, int(current_fuel_pct * 100.0)]

func _format_number(n: int) -> String:
	var s = str(abs(n))
	var res = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	return res

func _build_ui_nodes() -> void:
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# 1. Top-Left: Depth & Sector Readout
	var top_left = VBoxContainer.new()
	top_left.position = Vector2(48, 36)
	top_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_left)

	depth_label = Label.new()
	depth_label.text = "DEPTH  -1,420 M"
	depth_label.add_theme_font_size_override("font_size", 18)
	depth_label.add_theme_color_override("font_color", Color(0.88, 0.90, 0.92))
	top_left.add_child(depth_label)

	sector_label = Label.new()
	sector_label.text = "STRATUM III // THE HOLLOW CORE (THE GREAT DESCENT)"
	sector_label.add_theme_font_size_override("font_size", 11)
	sector_label.add_theme_color_override("font_color", Color(0.68, 0.74, 0.82))
	top_left.add_child(sector_label)

	thermal_label = Label.new()
	thermal_label.text = "TEMP +16°C // TEMPERATE BASALT"
	thermal_label.add_theme_font_size_override("font_size", 11)
	thermal_label.add_theme_color_override("font_color", Color(0.70, 0.78, 0.85))
	top_left.add_child(thermal_label)

	# 2. Top-Center: Minimal Geometric Compass & Directive Banner
	var top_center = VBoxContainer.new()
	top_center.position = Vector2(960 - 240, 24)
	top_center.custom_minimum_size = Vector2(480, 60)
	top_center.alignment = BoxContainer.ALIGNMENT_CENTER
	top_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_center)

	compass_container = Control.new()
	compass_container.custom_minimum_size = Vector2(300, 24)
	compass_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	compass_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	compass_container.draw.connect(_draw_compass)
	top_center.add_child(compass_container)

	directive_label = Label.new()
	directive_label.text = "EXPEDITION DIRECTIVE [1/5]: SALVAGE TIMBER FROM CAMP CRATES (HAVE: 4/6)"
	directive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	directive_label.add_theme_font_size_override("font_size", 12)
	directive_label.add_theme_color_override("font_color", Color(0.95, 0.76, 0.25))
	top_center.add_child(directive_label)

	# 3. Center: Sleek Reticle
	reticle = Control.new()
	reticle.position = Vector2(960 - 16, 540 - 16)
	reticle.custom_minimum_size = Vector2(32, 32)
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reticle.draw.connect(_draw_reticle)
	root.add_child(reticle)

	# 4. Bottom-Left: Diegetic Lantern Fuel
	var bottom_left = VBoxContainer.new()
	bottom_left.position = Vector2(48, 970)
	bottom_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom_left)

	fuel_label = Label.new()
	fuel_label.text = "LANTERN // ACTIVE  100%"
	fuel_label.add_theme_font_size_override("font_size", 13)
	fuel_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42))
	bottom_left.add_child(fuel_label)

	fuel_bar = Control.new()
	fuel_bar.custom_minimum_size = Vector2(220, 10)
	fuel_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fuel_bar.draw.connect(_draw_fuel_bar)
	bottom_left.add_child(fuel_bar)

	# 5. Bottom-Right: Environmental telemetry & Resource Counters
	var bottom_right = VBoxContainer.new()
	bottom_right.position = Vector2(1380, 950)
	bottom_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom_right)

	resource_label = Label.new()
	resource_label.text = "TIMBER: x4   COBBLE: x0   IRON: x0   CALCITE: x0   PHOSPHOR: x0"
	resource_label.add_theme_font_size_override("font_size", 12)
	resource_label.add_theme_color_override("font_color", Color(0.92, 0.78, 0.42))
	bottom_right.add_child(resource_label)

	status_label = Label.new()
	status_label.text = "ATMOSPHERE // PRESSURE 1.42 ATM\nAIR: DRY MIST // ACOUSTIC ECHO ACTIVE"
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", Color(0.45, 0.52, 0.58))
	bottom_right.add_child(status_label)

	# 6. Bottom-Center: Diegetic Minimalist Quick-Bar (8 slots centered on screen)
	quick_bar_container = Control.new()
	quick_bar_container.position = Vector2(960 - 349, 960) # 698px wide centered on 1920x1080
	quick_bar_container.custom_minimum_size = Vector2(700, 48)
	quick_bar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quick_bar_container.draw.connect(_draw_quick_bar)
	root.add_child(quick_bar_container)

	# 7. Bottom-Center: Minimalist Interaction Prompts
	hint_label = Label.new()
	hint_label.text = "[1-8] HOTBAR   [HOLD LMB] MINE/DIG   [RMB] PLACE BLOCK/TORCH   [E / TAB] INVENTORY   [C] CRAFT   [F] LANTERN"
	hint_label.position = Vector2(960 - 355, 1025)
	hint_label.add_theme_font_size_override("font_size", 11)
	hint_label.add_theme_color_override("font_color", Color(0.65, 0.70, 0.76, 0.85))
	root.add_child(hint_label)

func _draw_quick_bar() -> void:
	var slots = [
		{"key": "1", "name": "LANTERN"},
		{"key": "2", "name": "PICKAXE"},
		{"key": "3", "name": "TORCH"},
		{"key": "4", "name": "TIMBER"},
		{"key": "5", "name": "COBBLE"},
		{"key": "6", "name": "PLANKS"},
		{"key": "7", "name": "CALCITE"},
		{"key": "8", "name": "PHOSPHOR"}
	]

	var slot_w = 82.0
	var slot_h = 32.0
	var gap = 6.0
	var font = ThemeDB.fallback_font

	for i in range(slots.size()):
		var x = i * (slot_w + gap)
		var is_selected = (current_active_slot == (i + 1))
		var rect = Rect2(Vector2(x, 0), Vector2(slot_w, slot_h))

		if is_selected:
			quick_bar_container.draw_rect(rect, Color(0.18, 0.14, 0.08, 0.90), true)
			quick_bar_container.draw_rect(rect, Color(0.95, 0.78, 0.42, 0.95), false, 1.5)
			quick_bar_container.draw_line(Vector2(x + slot_w * 0.35, -2), Vector2(x + slot_w * 0.65, -2), Color(0.95, 0.78, 0.42, 1.0), 2.0)
		else:
			quick_bar_container.draw_rect(rect, Color(0.06, 0.08, 0.10, 0.65), true)
			quick_bar_container.draw_rect(rect, Color(0.25, 0.30, 0.35, 0.45), false, 1.0)

		var key_str = "[%s]" % slots[i]["key"]
		var key_color = Color(0.95, 0.78, 0.42) if is_selected else Color(0.5, 0.55, 0.6)
		quick_bar_container.draw_string(font, Vector2(x + 5, 20), key_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, key_color)

		var name_str = slots[i]["name"]
		var name_color = Color(0.95, 0.96, 0.98) if is_selected else Color(0.55, 0.60, 0.65)
		quick_bar_container.draw_string(font, Vector2(x + 24, 20), name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, name_color)

func _draw_reticle() -> void:
	var center = Vector2(16, 16)
	reticle.draw_circle(center, 1.5, Color(0.85, 0.88, 0.92, 0.75))
	var d = 6.0
	var tick = 3.0
	reticle.draw_line(center + Vector2(-d, -d), center + Vector2(-d + tick, -d), Color(0.6, 0.65, 0.7, 0.45), 1.0)
	reticle.draw_line(center + Vector2(-d, -d), center + Vector2(-d, -d + tick), Color(0.6, 0.65, 0.7, 0.45), 1.0)
	reticle.draw_line(center + Vector2(d, -d), center + Vector2(d - tick, -d), Color(0.6, 0.65, 0.7, 0.45), 1.0)
	reticle.draw_line(center + Vector2(d, -d), center + Vector2(d, -d + tick), Color(0.6, 0.65, 0.7, 0.45), 1.0)

func _draw_compass() -> void:
	var w = 300.0
	var h = 24.0
	var center_x = w * 0.5
	var font = ThemeDB.fallback_font

	compass_container.draw_line(Vector2(0, h * 0.5), Vector2(w, h * 0.5), Color(0.28, 0.32, 0.38, 0.5), 1.0)
	compass_container.draw_line(Vector2(center_x, 0), Vector2(center_x, h), Color(0.95, 0.78, 0.42, 0.85), 1.5)

	var cardinal_dirs = [
		{"deg": 0.0, "text": "N"},
		{"deg": 45.0, "text": "NE"},
		{"deg": 90.0, "text": "E"},
		{"deg": 135.0, "text": "SE"},
		{"deg": 180.0, "text": "S"},
		{"deg": 225.0, "text": "SW"},
		{"deg": 270.0, "text": "W"},
		{"deg": 315.0, "text": "NW"}
	]

	for c in cardinal_dirs:
		var diff = fposmod(c["deg"] - current_heading_deg + 180.0, 360.0) - 180.0
		if abs(diff) <= 75.0:
			var px = center_x + (diff / 75.0) * (w * 0.45)
			var alpha = 1.0 - (abs(diff) / 75.0)
			var is_primary = (c["text"] in ["N", "S", "E", "W"])
			var col = Color(0.95, 0.78, 0.42, alpha) if is_primary else Color(0.65, 0.70, 0.75, alpha * 0.7)
			compass_container.draw_line(Vector2(px, h * 0.25), Vector2(px, h * 0.75), col, 1.0)
			compass_container.draw_string(font, Vector2(px - 5, h - 2), c["text"], HORIZONTAL_ALIGNMENT_CENTER, -1, 9, col)

func _draw_fuel_bar() -> void:
	var w = 220.0
	var h = 8.0
	var border_col = Color(0.35, 0.38, 0.44, 0.6)
	var bg_col = Color(0.08, 0.10, 0.12, 0.8)

	fuel_bar.draw_rect(Rect2(0, 0, w, h), bg_col, true)
	fuel_bar.draw_rect(Rect2(0, 0, w, h), border_col, false, 1.0)

	if is_lantern_lit and current_fuel_pct > 0.0:
		var fill_w = w * current_fuel_pct
		var fill_col = Color(0.95, 0.74, 0.35, 0.90)
		if current_fuel_pct < 0.20:
			fill_col = Color(0.90, 0.25, 0.18, 0.95)
		fuel_bar.draw_rect(Rect2(1, 1, fill_w - 2, h - 2), fill_col, true)
