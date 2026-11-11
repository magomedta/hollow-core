# scripts/crafting_system.gd
class_name CraftingSystem
extends CanvasLayer

signal crafting_opened(is_open: bool)
signal item_crafted(recipe_id: String)

var player: CharacterBody3D
var is_open: bool = false

# UI references
var panel: PanelContainer
var recipe_list_container: VBoxContainer
var status_label: Label
var details_title: Label
var details_cost: Label
var details_desc: Label
var craft_btn: Button
var close_btn: Button

var selected_recipe_index: int = 0

var recipes: Array = [
	{
		"id": "stone_pickaxe",
		"name": "STONE PROSPECTOR PICKAXE",
		"cost": {"timber": 2, "cobblestone": 3},
		"yield": {"pickaxe_tier": 2},
		"desc": "Hardened stone mattock. Delivers 55 damage per strike with faster swing speed. Enables mining of raw iron veins!"
	},
	{
		"id": "iron_pickaxe",
		"name": "STEEL GEOLOGIST MATTOCK",
		"cost": {"iron": 3, "timber": 2},
		"yield": {"pickaxe_tier": 3},
		"desc": "High-carbon forged steel pickaxe. Delivers 90 damage per strike. Required to harvest deep Abyssal Phosphor!"
	},
	{
		"id": "scaffold_timber",
		"name": "STRUCTURAL TIMBER BUNDLE (x4)",
		"cost": {"cobblestone": 2, "timber": 1},
		"yield": {"timber": 4},
		"desc": "Reinforce wooden beams with stone chocks to expand your construction supply for scaffolds and bridges."
	},
	{
		"id": "carbide_refuel",
		"name": "CARBIDE LANTERN REFUEL (+60%)",
		"cost": {"calcite": 2, "timber": 1},
		"yield": {"refuel_oil": 60},
		"desc": "Subterranean hydrocarbon slurry. Instantly replenishes +60% lantern fuel tank."
	},
	{
		"id": "eternal_lantern",
		"name": "ETERNAL BIOLUMINESCENT LAMP",
		"cost": {"phosphor": 3, "iron": 2},
		"yield": {"eternal_lamp": 1},
		"desc": "Harnesses glowing phosphor crystals. Burns perpetually with ZERO fuel depletion!"
	},
	{
		"id": "precursor_key",
		"name": "PRECURSOR ARCHWAY RESONATOR",
		"cost": {"phosphor": 3, "calcite": 3, "iron": 3},
		"yield": {"precursor_key": 1},
		"desc": "Tuned tri-mineral harmonic key. Activates the ancient Precursor Archway on the East Plateau!"
	}
]

func _ready() -> void:
	layer = 20
	visible = false
	_build_ui()

func set_player(p_player: CharacterBody3D) -> void:
	player = p_player

func toggle_menu() -> void:
	set_menu_open(not is_open)

func set_menu_open(opened: bool) -> void:
	is_open = opened
	visible = is_open
	crafting_opened.emit(is_open)

	if is_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_refresh_recipe_list()
		_select_recipe(selected_recipe_index)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_C:
			toggle_menu()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and is_open:
			set_menu_open(false)
			get_viewport().set_input_as_handled()

func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 480)
	panel.anchors_preset = Control.PRESET_CENTER
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -380
	panel.offset_top = -240
	panel.offset_right = 380
	panel.offset_bottom = 240

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.14, 0.94)
	style.border_color = Color(0.85, 0.68, 0.28, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.set("theme_override_constants/separation", 12)
	panel.add_child(main_vbox)

	# Header
	var header_hbox = HBoxContainer.new()
	main_vbox.add_child(header_hbox)

	var title_lbl = Label.new()
	title_lbl.text = "FIELD WORKBENCH // EXPEDITION CRAFTING COMPENDIUM"
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.84, 0.35))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_lbl)

	close_btn = Button.new()
	close_btn.text = " [X] CLOSE "
	close_btn.pressed.connect(set_menu_open.bind(false))
	header_hbox.add_child(close_btn)

	var sep = HSeparator.new()
	main_vbox.add_child(sep)

	# Content Area: Left = Recipe List, Right = Details & Action
	var content_hbox = HBoxContainer.new()
	content_hbox.set("theme_override_constants/separation", 18)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_hbox)

	# Scrollable recipe list
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(340, 320)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(scroll)

	recipe_list_container = VBoxContainer.new()
	recipe_list_container.set("theme_override_constants/separation", 6)
	recipe_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(recipe_list_container)

	# Right panel details
	var details_vbox = VBoxContainer.new()
	details_vbox.set("theme_override_constants/separation", 10)
	details_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(details_vbox)

	details_title = Label.new()
	details_title.text = "SELECT RECIPE"
	details_title.add_theme_color_override("font_color", Color(0.96, 0.88, 0.45))
	details_vbox.add_child(details_title)

	details_desc = Label.new()
	details_desc.text = ""
	details_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_desc.add_theme_color_override("font_color", Color(0.78, 0.82, 0.88))
	details_vbox.add_child(details_desc)

	var cost_header = Label.new()
	cost_header.text = "REQUIRED MATERIALS:"
	cost_header.add_theme_color_override("font_color", Color(0.85, 0.72, 0.32))
	details_vbox.add_child(cost_header)

	details_cost = Label.new()
	details_cost.text = ""
	details_vbox.add_child(details_cost)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_vbox.add_child(spacer)

	status_label = Label.new()
	status_label.text = ""
	status_label.add_theme_color_override("font_color", Color(0.2, 0.85, 0.4))
	details_vbox.add_child(status_label)

	craft_btn = Button.new()
	craft_btn.text = "ASSEMBLE COMPONENT"
	craft_btn.custom_minimum_size = Vector2(240, 42)
	craft_btn.pressed.connect(_on_craft_button_pressed)
	details_vbox.add_child(craft_btn)

func _refresh_recipe_list() -> void:
	for child in recipe_list_container.get_children():
		child.queue_free()

	for i in range(recipes.size()):
		var r = recipes[i]
		var btn = Button.new()
		btn.text = "  %s" % r["name"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(320, 36)
		btn.pressed.connect(_select_recipe.bind(i))
		recipe_list_container.add_child(btn)

func _select_recipe(idx: int) -> void:
	selected_recipe_index = clamp(idx, 0, recipes.size() - 1)
	var r = recipes[selected_recipe_index]

	details_title.text = r["name"]
	details_desc.text = r["desc"]

	var cost_parts = []
	var can_craft = true
	var cost_dict: Dictionary = r["cost"]

	for res in cost_dict.keys():
		var need = cost_dict[res]
		var have = 0
		if player and "inventory" in player and player.inventory.has(res):
			have = player.inventory[res]
		var color_tag = "[OK]" if have >= need else "[MISSING]"
		cost_parts.append("• %s: %d / %d %s" % [res.to_upper(), have, need, color_tag])
		if have < need:
			can_craft = false

	details_cost.text = "\n".join(cost_parts)
	craft_btn.disabled = not can_craft
	status_label.text = "READY TO ASSEMBLE" if can_craft else "INSUFFICIENT RESOURCES"
	status_label.add_theme_color_override("font_color", Color(0.2, 0.85, 0.4) if can_craft else Color(0.9, 0.25, 0.25))

func _on_craft_button_pressed() -> void:
	if player == null:
		return
	var r = recipes[selected_recipe_index]
	var cost_dict: Dictionary = r["cost"]

	# Verify and consume
	for res in cost_dict.keys():
		if not player.has_resource(res, cost_dict[res]):
			status_label.text = "CANNOT CRAFT: LACKING %s" % res.to_upper()
			status_label.add_theme_color_override("font_color", Color(0.9, 0.25, 0.25))
			return

	for res in cost_dict.keys():
		player.consume_resource(res, cost_dict[res])

	# Apply yields
	var yield_dict: Dictionary = r["yield"]
	for yk in yield_dict.keys():
		var amt = yield_dict[yk]
		match yk:
			"timber":
				player.add_resource("timber", amt)
			"pickaxe_tier":
				if player.has_method("upgrade_pickaxe_tier"):
					player.upgrade_pickaxe_tier(amt)
				if amt == 2 and player.has_method("advance_progression_phase"):
					player.advance_progression_phase(3)
				elif amt == 3 and player.has_method("advance_progression_phase"):
					player.advance_progression_phase(4)
			"refuel_oil":
				if "lantern" in player and player.lantern:
					player.lantern.current_fuel = min(player.lantern.max_fuel, player.lantern.current_fuel + float(amt))
					player.lantern.fuel_changed.emit(player.lantern.current_fuel, player.lantern.max_fuel)
			"eternal_lamp":
				if "lantern" in player and player.lantern:
					player.lantern.fuel_burn_rate = 0.0 # Infinite fuel
					player.lantern.current_fuel = 100.0
					player.lantern.fuel_changed.emit(100.0, 100.0)
			"precursor_key":
				player.add_resource("precursor_key", amt)
				if player.has_method("advance_progression_phase"):
					player.advance_progression_phase(5)

	status_label.text = "CRAFTED: %s" % r["name"]
	status_label.add_theme_color_override("font_color", Color(0.2, 0.95, 0.5))
	item_crafted.emit(r["id"])
	_select_recipe(selected_recipe_index)
