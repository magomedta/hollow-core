# scripts/inventory_system.gd
# Full Expedition Backpack & Crafting Inventory System
# Minecraft-style 24-slot Backpack + 8-slot Hotbar + 2x2 Crafting Grid
# Click / Drag / Stack swapping / Tooltips / Quick Recipes

class_name InventorySystem
extends CanvasLayer

signal inventory_updated
signal active_slot_changed(slot_idx: int)
signal item_crafted(recipe_name: String)

var player: CharacterBody3D
var is_open: bool = false

# Total 32 inventory slots:
# Slots 0..7: Hotbar (keys 1-8)
# Slots 8..31: Backpack (3 rows x 8 columns)
var slots: Array = []
var cursor_stack: Dictionary = {} # Stack currently held by mouse cursor: {"id": "", "count": 0, ...}

# 2x2 Crafting matrix + Output
var craft_grid: Array = [{}, {}, {}, {}]
var craft_output: Dictionary = {}

# UI Nodes
var root_panel: PanelContainer
var backpack_container: GridContainer
var hotbar_container: HBoxContainer
var craft_grid_container: GridContainer
var craft_output_slot_btn: Button
var tooltip_panel: PanelContainer
var tooltip_title: Label
var tooltip_info: Label
var tooltip_desc: Label
var cursor_preview: Control

# Active hotbar selection (0 to 7)
var active_hotbar_index: int = 0

const TOTAL_SLOTS = 32
const HOTBAR_COUNT = 8
const BACKPACK_COUNT = 24

# Item Registry with Block mappings & descriptions
const ITEM_REGISTRY = {
	"lantern": {
		"name": "Expedition Brass Lantern",
		"category": "LIGHT & ILLUMINATION",
		"max_stack": 1,
		"block_type": 0,
		"desc": "Heavy pressurised kerosene lantern. Illuminates deep caverns and reveals hidden ore veins."
	},
	"pickaxe": {
		"name": "Prospector Pickaxe",
		"category": "EXCAVATION TOOL",
		"max_stack": 1,
		"block_type": 0,
		"desc": "Hardened chiseled pickaxe. Carves through cavern rock, extracts raw mineral ores, and chips masonry."
	},
	"torch": {
		"name": "Carbide Wall Torch",
		"category": "LIGHT & ILLUMINATION",
		"max_stack": 64,
		"block_type": 23,
		"desc": "Placeable wall and floor torch. Emits steady warm cave illumination to secure your mineshafts."
	},
	"timber": {
		"name": "Hewn Timber Beam",
		"category": "CONSTRUCTION TIMBER",
		"max_stack": 64,
		"block_type": 18,
		"desc": "Solid subterranean timber. Used to frame mine shafts, scaffold across chasms, and craft tools."
	},
	"planks": {
		"name": "Wooden Planks",
		"category": "CONSTRUCTION MATERIAL",
		"max_stack": 64,
		"block_type": 17,
		"desc": "Smooth hewn cedar planks. Ideal for flooring, stairways, and modular underground structures."
	},
	"cobblestone": {
		"name": "Cavern Cobblestone",
		"category": "GEOLOGICAL ROCK",
		"max_stack": 64,
		"block_type": 15,
		"desc": "Fractured subterranean stone blocks. Heavy, reliable building material for ramps and walls."
	},
	"stone": {
		"name": "Natural Stone",
		"category": "GEOLOGICAL ROCK",
		"max_stack": 64,
		"block_type": 1,
		"desc": "Smooth natural cave rock. Extracted from mid-depth cavern strata."
	},
	"deepslate": {
		"name": "Basaltic Deepslate",
		"category": "GEOLOGICAL ROCK",
		"max_stack": 64,
		"block_type": 2,
		"desc": "Dense abyssal slate from the deep stratum. Highly resistant to impacts."
	},
	"granite": {
		"name": "Intrusive Granite",
		"category": "GEOLOGICAL ROCK",
		"max_stack": 64,
		"block_type": 3,
		"desc": "Coarse pinkish volcanic granite. Excellent decorative masonry."
	},
	"diorite": {
		"name": "Crystalline Diorite",
		"category": "GEOLOGICAL ROCK",
		"max_stack": 64,
		"block_type": 4,
		"desc": "Pale salt-and-pepper crystalline rock found in deep volcanic veins."
	},
	"andesite": {
		"name": "Volcanic Andesite",
		"category": "GEOLOGICAL ROCK",
		"max_stack": 64,
		"block_type": 5,
		"desc": "Smooth slate-gray rock found in upper cavern pockets."
	},
	"iron": {
		"name": "Raw Iron Ingot",
		"category": "METALLIC RESOURCE",
		"max_stack": 64,
		"block_type": 8,
		"desc": "Smelted high-purity iron. Required to forge advanced mining equipment and archway resonators."
	},
	"calcite": {
		"name": "Calcite Geode Crystal",
		"category": "CRYSTALLINE MINERAL",
		"max_stack": 64,
		"block_type": 11,
		"desc": "Vibrant crystalline mineral harvested from subterranean geodes. Used in optics and lanterns."
	},
	"phosphor": {
		"name": "Bioluminescent Phosphor",
		"category": "ENERGY & LIGHT",
		"max_stack": 64,
		"block_type": 22,
		"desc": "Glowing deep-earth mineral. Fuel for lanterns, torches, and eternal luminescent fixtures."
	},
	"magma": {
		"name": "Abyssal Magma Rock",
		"category": "CORE STRATA",
		"max_stack": 64,
		"block_type": 14,
		"desc": "Superheated scorched rock from the deep mantle. Emits natural thermal light."
	},
	"ice": {
		"name": "Permafrost Glacial Ice",
		"category": "SURFACE STRATA",
		"max_stack": 64,
		"block_type": 13,
		"desc": "Subglacial permafrost ice harvested from the frigid upper surface caverns."
	}
}

func _ready() -> void:
	layer = 25
	_init_slots()
	_populate_starting_kit()
	_build_ui()
	set_open(false)

func set_player(p_player: CharacterBody3D) -> void:
	player = p_player

func _init_slots() -> void:
	slots.clear()
	for i in range(TOTAL_SLOTS):
		slots.push_back({})

func _populate_starting_kit() -> void:
	# Slot 0: Brass Lantern
	slots[0] = {"id": "lantern", "count": 1}
	# Slot 1: Prospector Pickaxe
	slots[1] = {"id": "pickaxe", "count": 1}
	# Slot 2: Carbide Torches (x16)
	slots[2] = {"id": "torch", "count": 16}
	# Slot 3: Hewn Timber (x12)
	slots[3] = {"id": "timber", "count": 12}
	# Slot 4: Cavern Cobblestone (x32)
	slots[4] = {"id": "cobblestone", "count": 32}
	# Slot 5: Wooden Planks (x16)
	slots[5] = {"id": "planks", "count": 16}
	# Slot 6: Calcite Crystals (x4)
	slots[6] = {"id": "calcite", "count": 4}
	# Slot 7: Phosphor Ore (x8)
	slots[7] = {"id": "phosphor", "count": 8}

func toggle() -> void:
	set_open(not is_open)

func set_open(open_state: bool) -> void:
	is_open = open_state
	visible = is_open

	if is_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_refresh_all_slots()
		_update_crafting_output()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		# Return cursor stack to inventory if holding anything
		if not cursor_stack.is_empty():
			add_item(cursor_stack.id, cursor_stack.count)
			cursor_stack = {}
		_hide_tooltip()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_E or event.keycode == KEY_TAB:
			toggle()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and is_open:
			set_open(false)
			get_viewport().set_input_as_handled()
		elif not is_open:
			# Hotbar number keys 1 through 8
			if event.keycode >= KEY_1 and event.keycode <= KEY_8:
				var slot_idx = event.keycode - KEY_1
				select_hotbar_slot(slot_idx)
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseButton and event.is_pressed() and not is_open:
		# Mouse wheel scrolling across hotbar
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			select_hotbar_slot((active_hotbar_index - 1 + HOTBAR_COUNT) % HOTBAR_COUNT)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			select_hotbar_slot((active_hotbar_index + 1) % HOTBAR_COUNT)

func select_hotbar_slot(idx: int) -> void:
	active_hotbar_index = clamp(idx, 0, HOTBAR_COUNT - 1)
	active_slot_changed.emit(active_hotbar_index)
	_refresh_all_slots()

func get_active_item() -> Dictionary:
	if active_hotbar_index >= 0 and active_hotbar_index < slots.size():
		return slots[active_hotbar_index]
	return {}

func consume_active_item(amount: int = 1) -> bool:
	if active_hotbar_index < 0 or active_hotbar_index >= slots.size():
		return false
	var item = slots[active_hotbar_index]
	if item.is_empty():
		return false
	item.count -= amount
	if item.count <= 0:
		slots[active_hotbar_index] = {}
	inventory_updated.emit()
	_refresh_all_slots()
	return true

func add_item(item_id: String, count: int = 1) -> int:
	var reg = ITEM_REGISTRY.get(item_id, {})
	var max_s = reg.get("max_stack", 64)

	# 1. Fill existing matching stacks first
	for i in range(TOTAL_SLOTS):
		var s = slots[i]
		if not s.is_empty() and s.id == item_id and s.count < max_s:
			var space = max_s - s.count
			var add_amt = min(space, count)
			s.count += add_amt
			count -= add_amt
			if count <= 0:
				inventory_updated.emit()
				_refresh_all_slots()
				return 0

	# 2. Fill empty slots
	for i in range(TOTAL_SLOTS):
		if slots[i].is_empty():
			var add_amt = min(max_s, count)
			slots[i] = {"id": item_id, "count": add_amt}
			count -= add_amt
			if count <= 0:
				inventory_updated.emit()
				_refresh_all_slots()
				return 0

	inventory_updated.emit()
	_refresh_all_slots()
	return count # Remainder if inventory completely full

# --- UI Layout Construction ---

func _build_ui() -> void:
	# Full-screen dark translucent backdrop
	var bg = ColorRect.new()
	bg.name = "Backdrop"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.07, 0.72)
	add_child(bg)

	# Main Central Card
	root_panel = PanelContainer.new()
	root_panel.name = "RootPanel"
	root_panel.set_anchors_preset(Control.PRESET_CENTER)
	root_panel.custom_minimum_size = Vector2(740, 520)
	root_panel.position = Vector2(-370, -260)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.11, 0.13, 0.96)
	panel_style.border_color = Color(0.24, 0.28, 0.35, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	root_panel.add_theme_stylebox_override("panel", panel_style)
	bg.add_child(root_panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 14)
	root_panel.add_child(main_vbox)

	# Header Bar
	var header = HBoxContainer.new()
	var title = Label.new()
	title.text = "EXPEDITION BACKPACK & FIELD CRAFTING"
	title.add_theme_color_override("font_color", Color(0.92, 0.78, 0.42))
	title.add_theme_font_size_override("font_size", 16)
	header.add_child(title)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	var close_btn = Button.new()
	close_btn.text = " [X] ESC "
	close_btn.flat = true
	close_btn.add_theme_color_override("font_color", Color(0.65, 0.70, 0.78))
	close_btn.pressed.connect(func(): set_open(false))
	header.add_child(close_btn)
	main_vbox.add_child(header)

	# Middle Area: 2x2 Crafting & Quick Recipes
	var craft_row = HBoxContainer.new()
	craft_row.add_theme_constant_override("separation", 24)

	# Left: 2x2 Field Crafting Box
	var craft_box = VBoxContainer.new()
	var craft_label = Label.new()
	craft_label.text = "FIELD CRAFTING (2x2)"
	craft_label.add_theme_color_override("font_color", Color(0.70, 0.75, 0.82))
	craft_label.add_theme_font_size_override("font_size", 12)
	craft_box.add_child(craft_label)

	var craft_inner = HBoxContainer.new()
	craft_inner.add_theme_constant_override("separation", 12)

	craft_grid_container = GridContainer.new()
	craft_grid_container.columns = 2
	craft_grid_container.add_theme_constant_override("h_separation", 6)
	craft_grid_container.add_theme_constant_override("v_separation", 6)

	for ci in range(4):
		var btn = _create_slot_button(100 + ci)
		craft_grid_container.add_child(btn)
	craft_inner.add_child(craft_grid_container)

	var arrow = Label.new()
	arrow.text = " ➔ "
	arrow.add_theme_color_override("font_color", Color(0.85, 0.65, 0.25))
	arrow.add_theme_font_size_override("font_size", 20)
	craft_inner.add_child(arrow)

	craft_output_slot_btn = _create_slot_button(200)
	craft_inner.add_child(craft_output_slot_btn)
	craft_box.add_child(craft_inner)
	craft_row.add_child(craft_box)

	# Right: Quick Crafting Presets
	var quick_box = VBoxContainer.new()
	var quick_label = Label.new()
	quick_label.text = "EXPEDITION RECIPES (ONE-CLICK)"
	quick_label.add_theme_color_override("font_color", Color(0.70, 0.75, 0.82))
	quick_label.add_theme_font_size_override("font_size", 12)
	quick_box.add_child(quick_label)

	var recipes_hbox = HBoxContainer.new()
	recipes_hbox.add_theme_constant_override("separation", 8)

	var r1 = _create_recipe_button("TORCHES (x4)", "1 Timber + 1 Phosphor", func(): _craft_preset({"timber": 1, "phosphor": 1}, "torch", 4))
	var r2 = _create_recipe_button("PLANKS (x4)", "1 Timber Beam", func(): _craft_preset({"timber": 1}, "planks", 4))
	var r3 = _create_recipe_button("STONE PICKAXE", "2 Timber + 3 Cobblestone", func(): _craft_preset({"timber": 2, "cobblestone": 3}, "pickaxe", 1))
	var r4 = _create_recipe_button("BRICKS (x4)", "4 Cobblestone", func(): _craft_preset({"cobblestone": 4}, "cobblestone", 4))

	recipes_hbox.add_child(r1)
	recipes_hbox.add_child(r2)
	recipes_hbox.add_child(r3)
	recipes_hbox.add_child(r4)
	quick_box.add_child(recipes_hbox)
	craft_row.add_child(quick_box)

	main_vbox.add_child(craft_row)

	# Divider line
	var sep = HSeparator.new()
	main_vbox.add_child(sep)

	# Backpack 24-slot grid (3 rows x 8 columns)
	var bp_label = Label.new()
	bp_label.text = "SURVEYOR BACKPACK (SLOTS 9-32)"
	bp_label.add_theme_color_override("font_color", Color(0.70, 0.75, 0.82))
	bp_label.add_theme_font_size_override("font_size", 12)
	main_vbox.add_child(bp_label)

	backpack_container = GridContainer.new()
	backpack_container.columns = 8
	backpack_container.add_theme_constant_override("h_separation", 6)
	backpack_container.add_theme_constant_override("v_separation", 6)

	for bi in range(BACKPACK_COUNT):
		var slot_idx = HOTBAR_COUNT + bi
		var btn = _create_slot_button(slot_idx)
		backpack_container.add_child(btn)
	main_vbox.add_child(backpack_container)

	# Hotbar 8-slot strip
	var hb_label = Label.new()
	hb_label.text = "EQUIPMENT BELT / HOTBAR (KEYS 1-8)"
	hb_label.add_theme_color_override("font_color", Color(0.92, 0.78, 0.42))
	hb_label.add_theme_font_size_override("font_size", 12)
	main_vbox.add_child(hb_label)

	hotbar_container = HBoxContainer.new()
	hotbar_container.add_theme_constant_override("separation", 6)

	for hi in range(HOTBAR_COUNT):
		var btn = _create_slot_button(hi)
		hotbar_container.add_child(btn)
	main_vbox.add_child(hotbar_container)

	# Sleek Tooltip Panel
	_build_tooltip(bg)

	# Mouse Cursor Floating Preview Stack
	cursor_preview = Control.new()
	cursor_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_preview.visible = false
	var cp_lbl = Label.new()
	cp_lbl.name = "CursorLabel"
	cursor_preview.add_child(cp_lbl)
	add_child(cursor_preview)

func _create_slot_button(slot_idx: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(76, 52)
	btn.clip_text = true

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.14, 0.16, 0.19, 0.90)
	style_normal.border_color = Color(0.25, 0.28, 0.35, 1.0)
	style_normal.border_width_left = 1
	style_normal.border_width_right = 1
	style_normal.border_width_top = 1
	style_normal.border_width_bottom = 1
	style_normal.corner_radius_top_left = 3
	style_normal.corner_radius_top_right = 3
	style_normal.corner_radius_bottom_left = 3
	style_normal.corner_radius_bottom_right = 3

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.gui_input.connect(func(event): _on_slot_gui_input(slot_idx, event))
	btn.mouse_entered.connect(func(): _on_slot_hover(slot_idx))
	btn.mouse_exited.connect(func(): _hide_tooltip())

	return btn

func _create_recipe_button(btn_text: String, subtext: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = "%s\n[%s]" % [btn_text, subtext]
	btn.custom_minimum_size = Vector2(125, 48)
	btn.add_theme_font_size_override("font_size", 10)
	btn.pressed.connect(callback)
	return btn

func _build_tooltip(parent: Control) -> void:
	tooltip_panel = PanelContainer.new()
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.custom_minimum_size = Vector2(220, 90)

	var tt_style = StyleBoxFlat.new()
	tt_style.bg_color = Color(0.06, 0.07, 0.09, 0.98)
	tt_style.border_color = Color(0.85, 0.65, 0.25, 0.90)
	tt_style.border_width_left = 1
	tt_style.border_width_right = 1
	tt_style.border_width_top = 1
	tt_style.border_width_bottom = 1
	tooltip_panel.add_theme_stylebox_override("panel", tt_style)

	var vb = VBoxContainer.new()
	tooltip_title = Label.new()
	tooltip_title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
	tooltip_title.add_theme_font_size_override("font_size", 13)
	vb.add_child(tooltip_title)

	tooltip_info = Label.new()
	tooltip_info.add_theme_color_override("font_color", Color(0.65, 0.72, 0.85))
	tooltip_info.add_theme_font_size_override("font_size", 10)
	vb.add_child(tooltip_info)

	tooltip_desc = Label.new()
	tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	tooltip_desc.add_theme_color_override("font_color", Color(0.80, 0.82, 0.85))
	tooltip_desc.add_theme_font_size_override("font_size", 11)
	vb.add_child(tooltip_desc)

	tooltip_panel.add_child(vb)
	parent.add_child(tooltip_panel)

# --- Slot Clicks & Drag Handling ---

func _on_slot_gui_input(slot_idx: int, event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.is_pressed()):
		return

	var is_left = (event.button_index == MOUSE_BUTTON_LEFT)
	var is_right = (event.button_index == MOUSE_BUTTON_RIGHT)
	var is_shift = Input.is_key_pressed(KEY_SHIFT)

	if slot_idx < 100:
		# Normal inventory slot (0..31)
		_handle_inventory_slot_click(slot_idx, is_left, is_right, is_shift)
	elif slot_idx >= 100 and slot_idx < 104:
		# Crafting grid input slot (0..3)
		var c_idx = slot_idx - 100
		_handle_craft_grid_click(c_idx, is_left, is_right)
	elif slot_idx == 200:
		# Craft output slot
		_handle_craft_output_click()

	_refresh_all_slots()

func _handle_inventory_slot_click(idx: int, is_left: bool, is_right: bool, is_shift: bool) -> void:
	var slot_data = slots[idx]

	if is_shift and not slot_data.is_empty():
		# Shift-click: Transfer between Hotbar (0..7) and Backpack (8..31)
		var is_in_hotbar = (idx < HOTBAR_COUNT)
		var target_start = HOTBAR_COUNT if is_in_hotbar else 0
		var target_end = TOTAL_SLOTS if is_in_hotbar else HOTBAR_COUNT
		var moved_count = slot_data.count
		for t in range(target_start, target_end):
			if slots[t].is_empty():
				slots[t] = slot_data.duplicate()
				slots[idx] = {}
				break
			elif slots[t].id == slot_data.id:
				slots[t].count += slot_data.count
				slots[idx] = {}
				break
		return

	if is_left:
		if cursor_stack.is_empty():
			# Pick up stack
			cursor_stack = slot_data.duplicate()
			slots[idx] = {}
		else:
			# Cursor holding item
			if slot_data.is_empty():
				# Drop stack into empty slot
				slots[idx] = cursor_stack.duplicate()
				cursor_stack = {}
			elif slot_data.id == cursor_stack.id:
				# Merge stack
				var reg = ITEM_REGISTRY.get(slot_data.id, {})
				var max_s = reg.get("max_stack", 64)
				var space = max_s - slot_data.count
				var merge_amt = min(space, cursor_stack.count)
				slot_data.count += merge_amt
				cursor_stack.count -= merge_amt
				if cursor_stack.count <= 0:
					cursor_stack = {}
			else:
				# Swap items
				var temp = slots[idx].duplicate()
				slots[idx] = cursor_stack.duplicate()
				cursor_stack = temp
	elif is_right:
		if cursor_stack.is_empty() and not slot_data.is_empty():
			# Pick up half stack
			var half = int(ceil(float(slot_data.count) / 2.0))
			cursor_stack = {"id": slot_data.id, "count": half}
			slot_data.count -= half
			if slot_data.count <= 0:
				slots[idx] = {}
		elif not cursor_stack.is_empty():
			# Drop 1 item
			if slot_data.is_empty():
				slots[idx] = {"id": cursor_stack.id, "count": 1}
				cursor_stack.count -= 1
				if cursor_stack.count <= 0:
					cursor_stack = {}
			elif slot_data.id == cursor_stack.id:
				var reg = ITEM_REGISTRY.get(slot_data.id, {})
				var max_s = reg.get("max_stack", 64)
				if slot_data.count < max_s:
					slot_data.count += 1
					cursor_stack.count -= 1
					if cursor_stack.count <= 0:
						cursor_stack = {}

func _handle_craft_grid_click(c_idx: int, is_left: bool, is_right: bool) -> void:
	var item = craft_grid[c_idx]
	if is_left:
		if cursor_stack.is_empty():
			cursor_stack = item.duplicate()
			craft_grid[c_idx] = {}
		else:
			if item.is_empty():
				craft_grid[c_idx] = cursor_stack.duplicate()
				cursor_stack = {}
			elif item.id == cursor_stack.id:
				item.count += cursor_stack.count
				cursor_stack = {}
			else:
				var temp = craft_grid[c_idx].duplicate()
				craft_grid[c_idx] = cursor_stack.duplicate()
				cursor_stack = temp
	elif is_right:
		if not cursor_stack.is_empty():
			if item.is_empty():
				craft_grid[c_idx] = {"id": cursor_stack.id, "count": 1}
				cursor_stack.count -= 1
				if cursor_stack.count <= 0:
					cursor_stack = {}
			elif item.id == cursor_stack.id:
				item.count += 1
				cursor_stack.count -= 1
				if cursor_stack.count <= 0:
					cursor_stack = {}
	_update_crafting_output()

func _handle_craft_output_click() -> void:
	if craft_output.is_empty():
		return
	if cursor_stack.is_empty():
		cursor_stack = craft_output.duplicate()
		# Consume 1 from each occupied crafting input slot
		for i in range(4):
			if not craft_grid[i].is_empty():
				craft_grid[i].count -= 1
				if craft_grid[i].count <= 0:
					craft_grid[i] = {}
		_update_crafting_output()

func _craft_preset(cost: Dictionary, out_item: String, out_count: int) -> void:
	# Check costs
	for k in cost.keys():
		var have = 0
		for s in slots:
			if not s.is_empty() and s.id == k:
				have += s.count
		if have < cost[k]:
			return # Not enough ingredients

	# Consume costs
	for k in cost.keys():
		var need = cost[k]
		for s in slots:
			if not s.is_empty() and s.id == k:
				var take = min(s.count, need)
				s.count -= take
				need -= take
				if s.count <= 0:
					s.clear()
				if need <= 0:
					break

	add_item(out_item, out_count)
	item_crafted.emit(out_item)
	_refresh_all_slots()

func _update_crafting_output() -> void:
	# Count items in 2x2 grid
	var counts = {}
	var non_empty = 0
	for item in craft_grid:
		if not item.is_empty():
			non_empty += 1
			counts[item.id] = counts.get(item.id, 0) + item.count

	craft_output = {}

	# Recipes
	if counts.has("timber") and non_empty == 1 and counts["timber"] >= 1:
		craft_output = {"id": "planks", "count": 4}
	elif counts.has("planks") and non_empty == 1 and counts["planks"] >= 1:
		craft_output = {"id": "timber", "count": 1}
	elif counts.has("timber") and counts.has("phosphor") and non_empty == 2:
		craft_output = {"id": "torch", "count": 4}
	elif counts.has("cobblestone") and counts["cobblestone"] >= 4 and non_empty == 4:
		craft_output = {"id": "cobblestone", "count": 4}

	if craft_output_slot_btn:
		_render_slot_btn(craft_output_slot_btn, craft_output, false)

func _process(_delta: float) -> void:
	if not is_open:
		return
	if not cursor_stack.is_empty():
		cursor_preview.visible = true
		cursor_preview.global_position = get_viewport().get_mouse_position() + Vector2(16, 16)
		var lbl: Label = cursor_preview.get_node("CursorLabel")
		lbl.text = "%s (x%d)" % [cursor_stack.id.to_upper(), cursor_stack.count]
		lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	else:
		cursor_preview.visible = false

# --- Tooltip & Visual Rendering ---

func _on_slot_hover(slot_idx: int) -> void:
	var item = {}
	if slot_idx < TOTAL_SLOTS:
		item = slots[slot_idx]
	elif slot_idx >= 100 and slot_idx < 104:
		item = craft_grid[slot_idx - 100]
	elif slot_idx == 200:
		item = craft_output

	if item.is_empty():
		_hide_tooltip()
		return

	var reg = ITEM_REGISTRY.get(item.id, {})
	tooltip_title.text = reg.get("name", item.id.capitalize())
	tooltip_info.text = "CATEGORY: %s   |   STACK: x%d / %d" % [reg.get("category", "ITEM"), item.count, reg.get("max_stack", 64)]
	tooltip_desc.text = reg.get("desc", "")

	tooltip_panel.visible = true
	var mpos = get_viewport().get_mouse_position()
	tooltip_panel.global_position = mpos + Vector2(18, 18)

func _hide_tooltip() -> void:
	if tooltip_panel:
		tooltip_panel.visible = false

func _refresh_all_slots() -> void:
	# 1. Hotbar slots
	if hotbar_container:
		for i in range(HOTBAR_COUNT):
			var btn: Button = hotbar_container.get_child(i)
			var is_active = (i == active_hotbar_index)
			_render_slot_btn(btn, slots[i], is_active, str(i + 1))

	# 2. Backpack slots
	if backpack_container:
		for i in range(BACKPACK_COUNT):
			var btn: Button = backpack_container.get_child(i)
			var slot_idx = HOTBAR_COUNT + i
			_render_slot_btn(btn, slots[slot_idx], false)

	# 3. Crafting grid
	if craft_grid_container:
		for i in range(4):
			var btn: Button = craft_grid_container.get_child(i)
			_render_slot_btn(btn, craft_grid[i], false)

func _render_slot_btn(btn: Button, item: Dictionary, is_active: bool, hotkey_badge: String = "") -> void:
	var text = ""
	if hotkey_badge != "":
		text += "[%s] " % hotkey_badge

	if item.is_empty():
		btn.text = text
		btn.remove_theme_color_override("font_color")
	else:
		var reg = ITEM_REGISTRY.get(item.id, {})
		var short_name = reg.get("name", item.id).substr(0, 10).to_upper()
		btn.text = "%s%s\nx%d" % [text, short_name, item.count]
		btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))

	# Active border style
	var style: StyleBoxFlat = btn.get_theme_stylebox("normal").duplicate()
	if is_active:
		style.border_color = Color(0.95, 0.78, 0.28, 1.0)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.bg_color = Color(0.20, 0.22, 0.28, 0.95)
	else:
		style.border_color = Color(0.24, 0.28, 0.35, 1.0)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.bg_color = Color(0.12, 0.14, 0.17, 0.90)
	btn.add_theme_stylebox_override("normal", style)
