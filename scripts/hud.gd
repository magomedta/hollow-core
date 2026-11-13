# scripts/hud.gd
# Diegetic Subterranean Survival HUD & Instrument Cluster
# Aesthetic: Grounded anti-AI-UI typography, minimal vector reticle,
# 8-slot visual item hotbar with pixel icons, survival vitals instrumentation,
# sleek real-time FPS counter, and 8-segment radial selection wheel with mouse wheel support.

class_name GameHUD
extends CanvasLayer

const PixelTextureGenerator = preload("res://scripts/pixel_texture_generator.gd")
const VoxelWorldClass = preload("res://scripts/voxel_world.gd")
const InventorySystemClass = preload("res://scripts/inventory_system.gd")

var player: CharacterBody3D
var lantern: Node3D

# Top-Left Telemetry
var depth_label: Label
var sector_label: Label
var thermal_label: Label
var directive_label: Label

# Top-Right Performance Telemetry
var fps_label: Label

# Center
var compass_container: Control
var reticle: Control
var interact_prompt_label: Label

# Bottom-Left Survival Vitals & Fuel
var vitals_container: Control
var fuel_label: Label
var fuel_bar: Control

# Bottom-Center Visual Hotbar & Key hints
var quick_bar_container: Control
var hint_label: Label

# Bottom-Right Resource Counters
var status_label: Label
var resource_label: Label

# Diegetic Lore Journal Popup
var lore_modal: PanelContainer
var lore_title: Label
var lore_meta: Label
var lore_body: Label
var is_lore_open: bool = false

# Interactive Radial Selection Wheel
var radial_container: Control
var is_radial_menu_open: bool = false
var radial_selected_slot: int = 1
var radial_mouse_offset: Vector2 = Vector2.ZERO

# Live Telemetry State
var current_fuel_pct: float = 1.0
var is_lantern_lit: bool = true
var current_heading_deg: float = 0.0
var current_depth_m: float = 1420.0
var current_active_slot: int = 1
var progression_phase: int = 1

var current_hp: float = 100.0
var max_hp: float = 100.0
var current_water: float = 100.0
var current_food: float = 100.0
var current_temp_c: float = 17.0

var inventory: Dictionary = {
	"timber": 12,
	"cobblestone": 32,
	"iron": 2,
	"calcite": 4,
	"phosphor": 8
}

var ui_font: Font
var vignette_node: Control

const LORE_ENTRIES = {
	"LOG_01_OUTPOST": {
		"title": "SURVEYOR LOG #01: THE BREACH",
		"meta": "EXPEDITION 104 // LEAD GEOLOGIST VANE // STRATUM III",
		"body": "We drilled through 400 meters of subglacial permafrost before the pressure shaft collapsed.\n\nWe expected solid mantle rock, but what we found is an impossible subterranean vault spanning kilometers. There is breathable air here, circulating through deep volcanic fissures.\n\nKeep your pickaxe sharpened and stay alert: the acoustic vibrations of mining echo through the basalt. Something down here reacts to sound."
	},
	"LOG_03_PRECURSOR": {
		"title": "ARCHAEOLOGICAL LOG #03: THE LIVING CORE",
		"meta": "EXPEDITION 104 // DR. ELENA MARCUS // DEEPSLATE CHASM",
		"body": "These hexagonal basalt columns were not shaped by volcanic cooling. The stone is carved with harmonic geometric conduits.\n\nThe precursor civilization did not excavate this hollow to shelter from the surface ice age.\n\nThey built these anchors to contain what sleeps at the planetary core. If you descend past the magma mantle, do not disturb the resonance seals."
	}
}

func _ready() -> void:
	layer = 10
	add_to_group("game_hud")
	_init_system_fonts()
	_build_ui_nodes()

func _init_system_fonts() -> void:
	var sf = SystemFont.new()
	sf.font_names = PackedStringArray(["Segoe UI", "Inter", "Roboto", "Helvetica Neue", "Arial"])
	sf.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	sf.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	ui_font = sf

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
		if player.has_signal("vitals_changed"):
			player.vitals_changed.connect(_on_vitals_changed)
		if player.has_signal("lore_opened"):
			player.lore_opened.connect(_on_lore_opened)

		if "inventory_system" in player and player.inventory_system:
			if player.inventory_system.has_signal("inventory_updated"):
				player.inventory_system.inventory_updated.connect(_on_inventory_system_updated)

		if "inventory" in player:
			inventory = player.inventory.duplicate()
			_update_resource_display()
		if "progression_phase" in player:
			progression_phase = player.progression_phase
			_update_resource_display()
		if "active_slot" in player:
			current_active_slot = player.active_slot

func _on_vitals_changed(health: float, hydration: float, satiety: float, temp: float) -> void:
	current_hp = health
	current_water = hydration
	current_food = satiety
	current_temp_c = temp
	if vitals_container:
		vitals_container.queue_redraw()

func _on_lore_opened(log_id: String) -> void:
	var entry = LORE_ENTRIES.get(log_id, LORE_ENTRIES["LOG_01_OUTPOST"])
	lore_title.text = entry["title"]
	lore_meta.text = entry["meta"]
	lore_body.text = entry["body"]
	lore_modal.visible = true
	is_lore_open = true

func _close_lore() -> void:
	if lore_modal:
		lore_modal.visible = false
	is_lore_open = false

func toggle_radial_menu() -> void:
	if is_radial_menu_open:
		close_radial_menu()
	else:
		open_radial_menu()

func open_radial_menu() -> void:
	is_radial_menu_open = true
	radial_selected_slot = current_active_slot
	radial_mouse_offset = Vector2.ZERO
	if radial_container:
		radial_container.visible = true
		radial_container.queue_redraw()

func handle_radial_mouse_motion(relative: Vector2) -> void:
	if not is_radial_menu_open:
		return
	radial_mouse_offset += relative
	if radial_mouse_offset.length() > 22.0:
		var angle = atan2(radial_mouse_offset.y, radial_mouse_offset.x)
		var shifted = fposmod(angle + PI * 0.5 + (PI / 8.0), 2.0 * PI)
		var slice_idx = int(floor(shifted / (2.0 * PI / 8.0)))
		var new_slot = slice_idx + 1
		if new_slot != radial_selected_slot:
			radial_selected_slot = new_slot
			if radial_container:
				radial_container.queue_redraw()

func close_radial_menu() -> void:
	if not is_radial_menu_open:
		return
	is_radial_menu_open = false
	if radial_container:
		radial_container.visible = false
	# Equip selected slot
	if player and player.has_method("set_active_slot"):
		player.set_active_slot(radial_selected_slot)

func scroll_radial_menu(delta_step: int) -> void:
	radial_selected_slot += delta_step
	if radial_selected_slot > 8:
		radial_selected_slot = 1
	elif radial_selected_slot < 1:
		radial_selected_slot = 8
	if radial_container:
		radial_container.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if is_lore_open and event is InputEventKey and event.is_pressed():
		var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if code == KEY_ESCAPE or code == KEY_E or event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
			_close_lore()
			get_viewport().set_input_as_handled()
			return

	if is_radial_menu_open:
		if event is InputEventMouseButton and event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				scroll_radial_menu(-1)
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				scroll_radial_menu(1)
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_LEFT:
				close_radial_menu()
				get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.is_pressed():
			var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			if code == KEY_Q or event.keycode == KEY_Q or code == KEY_ESCAPE or event.keycode == KEY_ESCAPE:
				close_radial_menu()
				get_viewport().set_input_as_handled()

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
	radial_selected_slot = slot
	if quick_bar_container:
		quick_bar_container.queue_redraw()
	if radial_container and is_radial_menu_open:
		radial_container.queue_redraw()
	_update_hint_display()

func _on_progression_phase_changed(phase: int) -> void:
	progression_phase = phase
	_update_resource_display()

func _on_inventory_changed(inv: Dictionary) -> void:
	inventory = inv.duplicate()
	_update_resource_display()
	if quick_bar_container:
		quick_bar_container.queue_redraw()
	if radial_container and is_radial_menu_open:
		radial_container.queue_redraw()

func _on_inventory_system_updated() -> void:
	_update_resource_display()
	if quick_bar_container:
		quick_bar_container.queue_redraw()
	if radial_container and is_radial_menu_open:
		radial_container.queue_redraw()

func _update_hint_display() -> void:
	if hint_label == null:
		return
	hint_label.text = "[1-8 / WHEEL] HOTBAR   [Q] RADIAL WHEEL   [HOLD LMB] MINE   [RMB] PLACE/EAT   [E] INTERACT   [C] CRAFT   [F] LANTERN"

func _update_resource_display() -> void:
	var timber = 0
	var cobble = 0
	var iron = 0
	var calcite = 0
	var phosphor = 0

	if player and "inventory_system" in player and player.inventory_system:
		for s in player.inventory_system.slots:
			if not s.is_empty():
				var s_id = s.get("id", "")
				var s_cnt = s.get("count", 0)
				match s_id:
					"timber", "planks": timber += s_cnt
					"cobblestone", "stone", "deepslate": cobble += s_cnt
					"iron": iron += s_cnt
					"calcite": calcite += s_cnt
					"phosphor": phosphor += s_cnt
	else:
		timber = inventory.get("timber", 0)
		cobble = inventory.get("cobblestone", 0)
		iron = inventory.get("iron", 0)
		calcite = inventory.get("calcite", 0)
		phosphor = inventory.get("phosphor", 0)

	if resource_label:
		resource_label.text = "TIMBER: x%d   COBBLE: x%d   IRON: x%d   CALCITE: x%d   PHOSPHOR: x%d" % [
			timber, cobble, iron, calcite, phosphor
		]

	if directive_label:
		match progression_phase:
			1:
				directive_label.text = "EXPEDITION DIRECTIVE [1/5]: SALVAGE TIMBER & CRATES (TIMBER: %d/4)" % timber
				directive_label.add_theme_color_override("font_color", Color(0.95, 0.76, 0.25))
			2:
				directive_label.text = "EXPEDITION DIRECTIVE [2/5]: OPEN WORKBENCH [C] & CRAFT SURVEYOR PICKAXE"
				directive_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
			3:
				directive_label.text = "EXPEDITION DIRECTIVE [3/5]: EXCAVATE ROCK STRATA & GATHER COBBLESTONE (%d/4)" % cobble
				directive_label.add_theme_color_override("font_color", Color(0.85, 0.82, 0.70))
			4:
				directive_label.text = "EXPEDITION DIRECTIVE [4/5]: FORGE IRON PICKAXE & DESCEND INTO DEEPSLATE"
				directive_label.add_theme_color_override("font_color", Color(0.92, 0.80, 0.42))
			5:
				directive_label.text = "EXPEDITION DIRECTIVE [5/5]: DISCOVER THE ANCIENT PRECURSOR MONOLITH IN CHASM"
				directive_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.30))
			_:
				directive_label.text = "EXPEDITION COMPLETE // DEEP MONOLITH ACTIVATED // PLANETARY SURVEY COMPLETE"
				directive_label.add_theme_color_override("font_color", Color(0.35, 0.95, 0.55))

func _process(_delta: float) -> void:
	if vignette_node:
		vignette_node.queue_redraw()

	# Real-time FPS & Performance Monitoring
	if fps_label:
		var fps = Engine.get_frames_per_second()
		var frame_ms = 1000.0 / max(1.0, float(fps))
		fps_label.text = "FPS  %3d  |  %4.1f MS" % [fps, frame_ms]
		var col = Color(0.88, 0.90, 0.94)
		if fps < 35:
			col = Color(0.95, 0.35, 0.30)
		elif fps < 55:
			col = Color(0.95, 0.78, 0.35)
		fps_label.add_theme_color_override("font_color", col)

	if player:
		if player.has_method("get_current_depth_meters"):
			current_depth_m = player.get_current_depth_meters()
		if player.has_method("get_compass_heading_degrees"):
			current_heading_deg = player.get_compass_heading_degrees()

		if depth_label:
			depth_label.text = "DEPTH  -%s M" % _format_number(int(current_depth_m))

		var sector_str: String = ""
		var temp_str: String = ""
		var temp_color: Color = Color(0.65, 0.75, 0.82)

		var vw_node = player.voxel_world if "voxel_world" in player else null
		if vw_node and vw_node.has_method("get_biome_name_at"):
			sector_str = vw_node.get_biome_name_at(int(player.global_position.x), int(player.global_position.y), int(player.global_position.z))
		elif player.global_position.y >= 44.0:
			sector_str = "STRATUM I // THE FROZEN CRUST (SURFACE BLIZZARD)"
		elif player.global_position.y >= 20.0:
			sector_str = "STRATUM II // CHILLED KARST & SUBGLACIAL ICE"
		elif player.global_position.y >= 0.0:
			sector_str = "STRATUM III // THE HOLLOW CORE BASIN"
		elif player.global_position.y >= -28.0:
			sector_str = "STRATUM IV // BASALTIC DEEPSLATE & PHOSPHOR GROTTO"
		else:
			sector_str = "STRATUM V // THE MAGMA MANTLE & MOLTEN CORE"

		if player.global_position.y >= 44.0:
			temp_str = "TEMP %d°C // GALE SUB-ZERO PERMAFROST" % int(current_temp_c)
			temp_color = Color(0.72, 0.80, 0.88)
		elif player.global_position.y >= 20.0:
			temp_str = "TEMP %+d°C // BOREAL CRYSTAL CAVERN" % int(current_temp_c)
			temp_color = Color(0.78, 0.84, 0.90)
		elif player.global_position.y >= 0.0:
			temp_str = "TEMP %+d°C // TEMPERATE BASALT CHAMBERS" % int(current_temp_c)
			temp_color = Color(0.70, 0.78, 0.85)
		elif player.global_position.y >= -28.0:
			temp_str = "TEMP %+d°C // LUMINESCENT ABYSS" % int(current_temp_c)
			temp_color = Color(0.25, 0.90, 0.75)
		else:
			temp_str = "TEMP %+d°C // CRITICAL VOLCANIC UPWELLING" % int(current_temp_c)
			temp_color = Color(1.0, 0.35, 0.15)

		if sector_label:
			sector_label.text = sector_str
		if thermal_label:
			thermal_label.text = temp_str
			thermal_label.add_theme_color_override("font_color", temp_color)

		if compass_container:
			compass_container.queue_redraw()

		# Hide HUD quickbar and hint overlay when inventory screen is active to prevent visual overlap
		var inv_sys = player.inventory_system if "inventory_system" in player else null
		if inv_sys and "is_open" in inv_sys:
			if quick_bar_container:
				quick_bar_container.visible = not inv_sys.is_open
			if hint_label:
				hint_label.visible = not inv_sys.is_open

		# Update in-world look prompt (Water, Food, Crates)
		_update_interaction_ray_prompt()

	if fuel_label:
		var status_str = "ACTIVE" if is_lantern_lit else "OFF"
		if current_fuel_pct <= 0.0:
			status_str = "DEPLETED"
		fuel_label.text = "LANTERN // %s  %d%%" % [status_str, int(current_fuel_pct * 100.0)]

func _update_interaction_ray_prompt() -> void:
	if interact_prompt_label == null or player == null or not ("camera" in player) or player.camera == null:
		return

	var space = player.get_world_3d().direct_space_state
	var origin = player.camera.global_position
	var forward = -player.camera.global_transform.basis.z
	var end = origin + forward * 3.8
	var query = PhysicsRayQueryParameters3D.create(origin, end, 1 | 4 | 8, [player])
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result = space.intersect_ray(query)

	if result:
		var col = result.collider
		if col != null:
			if col is DroppedItem or col.is_in_group("dropped_items") or col.has_method("get_interaction_prompt"):
				interact_prompt_label.text = "[E] " + col.get_interaction_prompt().to_upper()
				interact_prompt_label.visible = true
				return
			if col.has_meta("interaction_text"):
				interact_prompt_label.text = str(col.get_meta("interaction_text"))
				interact_prompt_label.visible = true
				return

		var hit_pos = result.position
		var hit_norm = result.normal
		var coord = Vector3i(floor(hit_pos.x - hit_norm.x * 0.4), floor(hit_pos.y - hit_norm.y * 0.4), floor(hit_pos.z - hit_norm.z * 0.4))
		var vw = player.voxel_world if "voxel_world" in player else null
		if vw and vw.has_method("get_block"):
			var b = vw.get_block(coord.x, coord.y, coord.z)
			if b == VoxelWorldClass.BlockType.WATER_SPRING:
				interact_prompt_label.text = "[E] DRINK PURE SPRING WATER / REFILL CANTEEN"
				interact_prompt_label.visible = true
				return
			elif b == VoxelWorldClass.BlockType.BIOLUM_MUSHROOM:
				interact_prompt_label.text = "[E / LMB] HARVEST EDIBLE GLOW-CAP"
				interact_prompt_label.visible = true
				return
			elif b == VoxelWorldClass.BlockType.LICHEN_ROOT:
				interact_prompt_label.text = "[E / LMB] HARVEST SUBTERRANEAN LICHEN ROOT"
				interact_prompt_label.visible = true
				return
			elif b == VoxelWorldClass.BlockType.CARGO_CRATE:
				interact_prompt_label.text = "[E] SALVAGE EXPEDITION RATIONS & NOTES"
				interact_prompt_label.visible = true
				return

	# Proximity check for nearby dropped item within 2.2m
	var items = get_tree().get_nodes_in_group("dropped_items")
	for it in items:
		if it is Node3D and is_instance_valid(it):
			if player.global_position.distance_to(it.global_position) < 2.2:
				if it.has_method("get_interaction_prompt"):
					interact_prompt_label.text = "[E] " + it.get_interaction_prompt().to_upper()
					interact_prompt_label.visible = true
					return

	interact_prompt_label.visible = false

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

	# Horror Atmosphere Vignette Overlay (Dark edges, subtle breathing pulse, critical blood pulse)
	vignette_node = Control.new()
	vignette_node.name = "HorrorVignette"
	vignette_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vignette_node)
	vignette_node.draw.connect(_draw_horror_vignette)

	# 1. Top-Left: Depth & Sector Readout
	var top_left = VBoxContainer.new()
	top_left.position = Vector2(48, 36)
	top_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_left)

	depth_label = Label.new()
	depth_label.text = "DEPTH  -1,420 M"
	depth_label.add_theme_font_size_override("font_size", 18)
	depth_label.add_theme_color_override("font_color", Color(0.88, 0.90, 0.92))
	if ui_font: depth_label.add_theme_font_override("font", ui_font)
	top_left.add_child(depth_label)

	sector_label = Label.new()
	sector_label.text = "STRATUM III // THE HOLLOW CORE BASIN"
	sector_label.add_theme_font_size_override("font_size", 11)
	sector_label.add_theme_color_override("font_color", Color(0.68, 0.74, 0.82))
	if ui_font: sector_label.add_theme_font_override("font", ui_font)
	top_left.add_child(sector_label)

	thermal_label = Label.new()
	thermal_label.text = "TEMP +17°C // TEMPERATE BASALT"
	thermal_label.add_theme_font_size_override("font_size", 11)
	thermal_label.add_theme_color_override("font_color", Color(0.70, 0.78, 0.85))
	if ui_font: thermal_label.add_theme_font_override("font", ui_font)
	top_left.add_child(thermal_label)

	# Top-Right: Sleek FPS & Frame-time Telemetry Monitor
	var top_right = VBoxContainer.new()
	top_right.position = Vector2(1720, 36)
	top_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_right)

	fps_label = Label.new()
	fps_label.text = "FPS  60  |  16.6 MS"
	fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fps_label.add_theme_font_size_override("font_size", 13)
	fps_label.add_theme_color_override("font_color", Color(0.92, 0.78, 0.42))
	if ui_font: fps_label.add_theme_font_override("font", ui_font)
	top_right.add_child(fps_label)

	var eng_sub = Label.new()
	eng_sub.text = "ENGINE // FORWARD+ VULKAN 128M"
	eng_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	eng_sub.add_theme_font_size_override("font_size", 10)
	eng_sub.add_theme_color_override("font_color", Color(0.45, 0.52, 0.58))
	if ui_font: eng_sub.add_theme_font_override("font", ui_font)
	top_right.add_child(eng_sub)

	# 2. Top-Center: Minimal Compass & Directive Banner
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
	directive_label.text = "EXPEDITION DIRECTIVE [1/5]: SALVAGE TIMBER & CRATES"
	directive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	directive_label.add_theme_font_size_override("font_size", 12)
	directive_label.add_theme_color_override("font_color", Color(0.95, 0.76, 0.25))
	if ui_font: directive_label.add_theme_font_override("font", ui_font)
	top_center.add_child(directive_label)

	# 3. Center: Sleek Reticle & Interaction Prompt
	reticle = Control.new()
	reticle.position = Vector2(960 - 16, 540 - 16)
	reticle.custom_minimum_size = Vector2(32, 32)
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reticle.draw.connect(_draw_reticle)
	root.add_child(reticle)

	interact_prompt_label = Label.new()
	interact_prompt_label.position = Vector2(960 - 200, 565)
	interact_prompt_label.custom_minimum_size = Vector2(400, 24)
	interact_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_prompt_label.add_theme_font_size_override("font_size", 11)
	interact_prompt_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.42))
	if ui_font: interact_prompt_label.add_theme_font_override("font", ui_font)
	interact_prompt_label.visible = false
	root.add_child(interact_prompt_label)

	# 4. Bottom-Left: Survival Vitals & Lantern Fuel Instrumentation
	var bottom_left = VBoxContainer.new()
	bottom_left.position = Vector2(48, 880)
	bottom_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_left.add_theme_constant_override("separation", 6)
	root.add_child(bottom_left)

	vitals_container = Control.new()
	vitals_container.custom_minimum_size = Vector2(230, 80)
	vitals_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vitals_container.draw.connect(_draw_vitals)
	bottom_left.add_child(vitals_container)

	fuel_label = Label.new()
	fuel_label.text = "LANTERN // ACTIVE  100%"
	fuel_label.add_theme_font_size_override("font_size", 11)
	fuel_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42))
	if ui_font: fuel_label.add_theme_font_override("font", ui_font)
	bottom_left.add_child(fuel_label)

	fuel_bar = Control.new()
	fuel_bar.custom_minimum_size = Vector2(220, 8)
	fuel_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fuel_bar.draw.connect(_draw_fuel_bar)
	bottom_left.add_child(fuel_bar)

	# 5. Bottom-Right: Environmental Telemetry & Resources
	var bottom_right = VBoxContainer.new()
	bottom_right.position = Vector2(1380, 950)
	bottom_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom_right)

	resource_label = Label.new()
	resource_label.text = "TIMBER: x12   COBBLE: x32   IRON: x2   CALCITE: x4   PHOSPHOR: x8"
	resource_label.add_theme_font_size_override("font_size", 12)
	resource_label.add_theme_color_override("font_color", Color(0.92, 0.78, 0.42))
	if ui_font: resource_label.add_theme_font_override("font", ui_font)
	bottom_right.add_child(resource_label)

	status_label = Label.new()
	status_label.text = "PRESSURE 1.42 ATM // ACOUSTIC ECHO ACTIVE\nVOXEL STRATIFICATION: UNIFIED 128M DEPTH"
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", Color(0.45, 0.52, 0.58))
	if ui_font: status_label.add_theme_font_override("font", ui_font)
	bottom_right.add_child(status_label)

	# 6. Bottom-Center: 8-Slot Visual Hotbar with Large 54x54 Item Icons
	quick_bar_container = Control.new()
	quick_bar_container.position = Vector2(960 - 304, 960)
	quick_bar_container.custom_minimum_size = Vector2(608, 72)
	quick_bar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quick_bar_container.draw.connect(_draw_quick_bar)
	root.add_child(quick_bar_container)

	# 7. Interaction Prompts
	hint_label = Label.new()
	hint_label.text = "[1-8 / WHEEL] HOTBAR   [Q] RADIAL WHEEL   [HOLD LMB] MINE   [RMB] PLACE/EAT   [E] INTERACT   [C] CRAFT   [F] LANTERN"
	hint_label.position = Vector2(960 - 390, 1040)
	hint_label.add_theme_font_size_override("font_size", 11)
	hint_label.add_theme_color_override("font_color", Color(0.68, 0.72, 0.78, 0.85))
	if ui_font: hint_label.add_theme_font_override("font", ui_font)
	root.add_child(hint_label)

	# 8. Interactive Radial Selection Wheel Overlay
	_build_radial_menu(root)

	# 9. Diegetic Lore Reader Modal
	_build_lore_modal(root)

func _build_radial_menu(parent: Control) -> void:
	radial_container = Control.new()
	radial_container.name = "RadialSelectionWheel"
	radial_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	radial_container.mouse_filter = Control.MOUSE_FILTER_PASS
	radial_container.visible = false
	radial_container.draw.connect(_draw_radial_menu)
	parent.add_child(radial_container)

func _draw_radial_menu() -> void:
	var center = Vector2(960, 540)
	var radius_outer = 165.0
	var radius_inner = 65.0
	var font = ui_font if ui_font else ThemeDB.fallback_font

	# Dimmed dark backdrop
	radial_container.draw_circle(center, radius_outer + 35.0, Color(0.04, 0.05, 0.07, 0.75))

	var total_slices = 8
	var angle_per_slice = (2.0 * PI) / float(total_slices)
	# Start at top (-PI/2)
	var start_angle = -PI * 0.5 - (angle_per_slice * 0.5)

	# Draw 8 radial segments
	for i in range(total_slices):
		var slot_num = i + 1
		var is_selected = (slot_num == radial_selected_slot)
		var a0 = start_angle + i * angle_per_slice
		var a1 = a0 + angle_per_slice
		var mid_angle = (a0 + a1) * 0.5

		var slice_col = Color(0.18, 0.16, 0.12, 0.95) if is_selected else Color(0.08, 0.10, 0.12, 0.85)
		var border_col = Color(0.95, 0.78, 0.38, 1.0) if is_selected else Color(0.24, 0.28, 0.35, 0.65)

		# Wedge polygon
		var pts = PackedVector2Array()
		var steps = 12
		for s in range(steps + 1):
			var t = float(s) / float(steps)
			var a = lerp(a0, a1, t)
			pts.push_back(center + Vector2(cos(a), sin(a)) * radius_outer)
		for s in range(steps, -1, -1):
			var t = float(s) / float(steps)
			var a = lerp(a0, a1, t)
			pts.push_back(center + Vector2(cos(a), sin(a)) * radius_inner)

		radial_container.draw_polygon(pts, [slice_col])
		radial_container.draw_polyline(pts, border_col, 2.0 if is_selected else 1.0)

		# Item icon & count centered in segment
		var icon_pos = center + Vector2(cos(mid_angle), sin(mid_angle)) * (radius_inner + (radius_outer - radius_inner) * 0.5)
		var item_id = ""
		var count = 0
		if player and "inventory_system" in player and player.inventory_system:
			var slots_arr = player.inventory_system.slots
			if i < slots_arr.size() and not slots_arr[i].is_empty():
				item_id = slots_arr[i].id
				count = slots_arr[i].count

		if item_id != "":
			var icon_tex = PixelTextureGenerator.get_item_icon(item_id)
			if icon_tex:
				var r = Rect2(icon_pos - Vector2(24, 24), Vector2(48, 48))
				radial_container.draw_texture_rect(icon_tex, r, false)
			if count > 1:
				var c_str = "x%d" % count
				radial_container.draw_string(font, icon_pos + Vector2(10, 20), c_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, Color(0.95, 0.95, 0.98))

		# Hotkey number in slice
		var num_pos = center + Vector2(cos(mid_angle), sin(mid_angle)) * (radius_outer - 14.0)
		var num_col = Color(0.95, 0.78, 0.38) if is_selected else Color(0.55, 0.60, 0.66)
		radial_container.draw_string(font, num_pos - Vector2(4, -4), str(slot_num), HORIZONTAL_ALIGNMENT_CENTER, -1, 10, num_col)

	# Center Hub: Display currently highlighted item details
	var sel_item_name = "EMPTY SLOT"
	var sel_count_str = ""
	if player and "inventory_system" in player and player.inventory_system:
		var slots_arr = player.inventory_system.slots
		var sel_idx = radial_selected_slot - 1
		if sel_idx >= 0 and sel_idx < slots_arr.size() and not slots_arr[sel_idx].is_empty():
			var i_id = slots_arr[sel_idx].id
			sel_item_name = i_id.capitalize()
			if i_id in InventorySystemClass.ITEM_REGISTRY:
				sel_item_name = InventorySystemClass.ITEM_REGISTRY[i_id].get("name", i_id.capitalize())
			if slots_arr[sel_idx].count > 1:
				sel_count_str = "COUNT: %d" % slots_arr[sel_idx].count

	radial_container.draw_circle(center, radius_inner - 2.0, Color(0.08, 0.10, 0.12, 0.96))
	radial_container.draw_arc(center, radius_inner - 2.0, 0, 2.0 * PI, 32, Color(0.95, 0.78, 0.38, 0.8), 2.0)

	radial_container.draw_string(font, center + Vector2(-60, -8), sel_item_name, HORIZONTAL_ALIGNMENT_CENTER, 120, 11, Color(0.95, 0.82, 0.42))
	if sel_count_str != "":
		radial_container.draw_string(font, center + Vector2(-50, 12), sel_count_str, HORIZONTAL_ALIGNMENT_CENTER, 100, 9, Color(0.70, 0.75, 0.82))
	var hint = "WHEEL / [1-8] SELECT"
	radial_container.draw_string(font, center + Vector2(-50, 26), hint, HORIZONTAL_ALIGNMENT_CENTER, 100, 8, Color(0.50, 0.55, 0.60))

func _build_lore_modal(parent: Control) -> void:
	lore_modal = PanelContainer.new()
	lore_modal.name = "LoreReaderModal"
	lore_modal.set_anchors_preset(Control.PRESET_CENTER)
	lore_modal.custom_minimum_size = Vector2(640, 360)
	lore_modal.position = Vector2(-320, -180)
	lore_modal.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.11, 0.96)
	style.border_color = Color(0.85, 0.68, 0.32, 0.85)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	lore_modal.add_theme_stylebox_override("panel", style)

	var m_margin = MarginContainer.new()
	m_margin.add_theme_constant_override("margin_left", 24)
	m_margin.add_theme_constant_override("margin_right", 24)
	m_margin.add_theme_constant_override("margin_top", 20)
	m_margin.add_theme_constant_override("margin_bottom", 20)
	lore_modal.add_child(m_margin)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	m_margin.add_child(vb)

	lore_title = Label.new()
	lore_title.text = "SURVEYOR LOG #01"
	lore_title.add_theme_font_size_override("font_size", 15)
	lore_title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.42))
	if ui_font: lore_title.add_theme_font_override("font", ui_font)
	vb.add_child(lore_title)

	lore_meta = Label.new()
	lore_meta.text = "EXPEDITION 104 // STRATUM III"
	lore_meta.add_theme_font_size_override("font_size", 10)
	lore_meta.add_theme_color_override("font_color", Color(0.65, 0.70, 0.78))
	if ui_font: lore_meta.add_theme_font_override("font", ui_font)
	vb.add_child(lore_meta)

	var sep = HSeparator.new()
	vb.add_child(sep)

	lore_body = Label.new()
	lore_body.text = "Body text goes here..."
	lore_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	lore_body.add_theme_font_size_override("font_size", 12)
	lore_body.add_theme_color_override("font_color", Color(0.88, 0.90, 0.94))
	lore_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if ui_font: lore_body.add_theme_font_override("font", ui_font)
	vb.add_child(lore_body)

	var close_hint = Label.new()
	close_hint.text = "[KEY E / ESC] CLOSE ARCHIVAL LOG"
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	close_hint.add_theme_font_size_override("font_size", 10)
	close_hint.add_theme_color_override("font_color", Color(0.55, 0.60, 0.65))
	if ui_font: close_hint.add_theme_font_override("font", ui_font)
	vb.add_child(close_hint)

	parent.add_child(lore_modal)

func _draw_vitals() -> void:
	var font = ui_font if ui_font else ThemeDB.fallback_font
	var w = 220.0
	var h_bar = 7.0
	var bg_col = Color(0.06, 0.07, 0.09, 0.92)
	var border_col = Color(0.55, 0.44, 0.26, 0.85)

	# 1. Health Bar
	vitals_container.draw_string(font, Vector2(0, 10), "SURVIVOR VITALS // INTEGRITY", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.92, 0.82, 0.55))
	vitals_container.draw_rect(Rect2(0, 14, w, h_bar), bg_col, true)
	vitals_container.draw_rect(Rect2(0, 14, w, h_bar), border_col, false, 1.5)
	var hp_pct = clamp(current_hp / max_hp, 0.0, 1.0)
	var hp_col = Color(0.85, 0.30, 0.28, 0.95) if hp_pct > 0.25 else Color(0.98, 0.15, 0.15, 0.98)
	if hp_pct > 0.0:
		vitals_container.draw_rect(Rect2(1, 15, (w - 2) * hp_pct, h_bar - 2), hp_col, true)

	# 2. Hydration Bar
	vitals_container.draw_string(font, Vector2(0, 33), "GLACIAL RESERVOIR // DEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.70, 0.78, 0.85))
	vitals_container.draw_rect(Rect2(0, 37, w, h_bar), bg_col, true)
	vitals_container.draw_rect(Rect2(0, 37, w, h_bar), border_col, false, 1.5)
	var water_pct = clamp(current_water / 100.0, 0.0, 1.0)
	var water_col = Color(0.48, 0.65, 0.78, 0.92)
	if water_pct > 0.0:
		vitals_container.draw_rect(Rect2(1, 38, (w - 2) * water_pct, h_bar - 2), water_col, true)

	# 3. Satiety Bar
	vitals_container.draw_string(font, Vector2(0, 56), "METABOLIC NOURISHMENT", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.92, 0.75, 0.38))
	vitals_container.draw_rect(Rect2(0, 60, w, h_bar), bg_col, true)
	vitals_container.draw_rect(Rect2(0, 60, w, h_bar), border_col, false, 1.5)
	var food_pct = clamp(current_food / 100.0, 0.0, 1.0)
	var food_col = Color(0.88, 0.68, 0.28, 0.90)
	if food_pct > 0.0:
		vitals_container.draw_rect(Rect2(1, 61, (w - 2) * food_pct, h_bar - 2), food_col, true)

func _draw_fuel_bar() -> void:
	var w = 220.0
	var h = 8.0
	var border_col = Color(0.55, 0.44, 0.26, 0.85)
	var bg_col = Color(0.06, 0.07, 0.09, 0.92)

	fuel_bar.draw_rect(Rect2(0, 0, w, h), bg_col, true)
	fuel_bar.draw_rect(Rect2(0, 0, w, h), border_col, false, 1.5)

	if is_lantern_lit and current_fuel_pct > 0.0:
		var fill_w = w * current_fuel_pct
		var fill_col = Color(0.95, 0.74, 0.35, 0.90)
		if current_fuel_pct < 0.20:
			fill_col = Color(0.90, 0.25, 0.18, 0.95)
		fuel_bar.draw_rect(Rect2(1, 1, fill_w - 2, h - 2), fill_col, true)

func _draw_quick_bar() -> void:
	var slot_size = 68.0
	var gap = 8.0
	var font = ui_font if ui_font else ThemeDB.fallback_font

	for i in range(8):
		var x = i * (slot_size + gap)
		var is_selected = (current_active_slot == (i + 1))
		var rect = Rect2(Vector2(x, 0), Vector2(slot_size, slot_size))

		# Background & Ornate Brass Expedition Framing
		if is_selected:
			quick_bar_container.draw_rect(rect, Color(0.18, 0.14, 0.08, 0.96), true)
			quick_bar_container.draw_rect(rect, Color(1.0, 0.84, 0.36, 1.0), false, 2.5)
			# Top golden selection crest
			quick_bar_container.draw_line(Vector2(x + slot_size * 0.25, -4), Vector2(x + slot_size * 0.75, -4), Color(1.0, 0.84, 0.36, 1.0), 3.0)
		else:
			quick_bar_container.draw_rect(rect, Color(0.06, 0.08, 0.10, 0.92), true)
			quick_bar_container.draw_rect(rect, Color(0.48, 0.38, 0.22, 0.85), false, 1.5)
			# Corner rivets
			quick_bar_container.draw_circle(Vector2(x + 4, 4), 1.2, Color(0.72, 0.58, 0.32, 0.9))
			quick_bar_container.draw_circle(Vector2(x + slot_size - 4, 4), 1.2, Color(0.72, 0.58, 0.32, 0.9))
			quick_bar_container.draw_circle(Vector2(x + 4, slot_size - 4), 1.2, Color(0.72, 0.58, 0.32, 0.9))
			quick_bar_container.draw_circle(Vector2(x + slot_size - 4, slot_size - 4), 1.2, Color(0.72, 0.58, 0.32, 0.9))

		# Hotkey number in top-left
		var key_str = str(i + 1)
		var key_col = Color(1.0, 0.84, 0.38) if is_selected else Color(0.72, 0.65, 0.52)
		quick_bar_container.draw_string(font, Vector2(x + 5, 14), key_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, key_col)

		# Item Icon from Inventory
		var item_id = ""
		var count = 0
		if player and "inventory_system" in player and player.inventory_system:
			var slots_arr = player.inventory_system.slots
			if i < slots_arr.size() and not slots_arr[i].is_empty():
				item_id = slots_arr[i].id
				count = slots_arr[i].count

		if item_id != "":
			var icon_tex = PixelTextureGenerator.get_item_icon(item_id)
			if icon_tex:
				# Large 54x54 icon centered inside 68x68 slot
				var icon_rect = Rect2(Vector2(x + 7, 7), Vector2(54, 54))
				quick_bar_container.draw_texture_rect(icon_tex, icon_rect, false)

			# Stack count in bottom-right with clear drop shadow
			if count > 1:
				var count_str = "x%d" % count
				quick_bar_container.draw_string(font, Vector2(x + slot_size - 28, slot_size - 5), count_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 12, Color(0.04, 0.05, 0.07, 0.95))
				quick_bar_container.draw_string(font, Vector2(x + slot_size - 29, slot_size - 6), count_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 12, Color(0.96, 0.96, 0.98))

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
	var font = ui_font if ui_font else ThemeDB.fallback_font

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


func _draw_horror_vignette() -> void:
	if vignette_node == null: return
	var size = vignette_node.get_viewport_rect().size
	var border_w = 160.0
	var border_h = 120.0

	var base_alpha = 0.22
	var is_critical = (current_hp < 35.0)
	var tint = Color(0.01, 0.01, 0.02)

	if is_critical:
		var pulse = (sin(Time.get_ticks_msec() * 0.005) * 0.5 + 0.5)
		base_alpha = lerp(0.20, 0.55, pulse)
		tint = Color(0.35, 0.02, 0.02)

	for i in range(5):
		var step_pct = float(i + 1) / 5.0
		var step_alpha = base_alpha * (1.0 - float(i) / 5.0)
		var col = Color(tint.r, tint.g, tint.b, step_alpha)
		var inset_x = border_w * (1.0 - step_pct)
		var inset_y = border_h * (1.0 - step_pct)
		vignette_node.draw_rect(Rect2(0, inset_y, size.x, border_h / 5.0), col)
		vignette_node.draw_rect(Rect2(0, size.y - inset_y - (border_h / 5.0), size.x, border_h / 5.0), col)
		vignette_node.draw_rect(Rect2(inset_x, 0, border_w / 5.0, size.y), col)
		vignette_node.draw_rect(Rect2(size.x - inset_x - (border_w / 5.0), 0, border_w / 5.0, size.y), col)
