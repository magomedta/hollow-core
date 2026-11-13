# tools/update_scenario_manager.py
import sys

content = """class_name ScenarioManager
extends Node3D

## Scripted Survival Horror Campaign Director (Expedition 104)
## Gives the game a complete, terrifying, and rewarding progression arc:
## 1. Outpost Awakening -> Recover Lantern & Pickaxe
## 2. Salvage Crates & Craft Torches to repel shadows
## 3. Delve into the Eastern Caverns to mine Raw Iron
## 4. Uncover the Secret Crypt behind the 2x2 Herobrine shaft & claim the Watcher's Glyph Rune
## 5. Descend into the Abyssal Core (Y <= -35) & activate the Planetary Rift Anchor to break the curse and escape!

enum Stage {
	FIND_LANTERN = 0,
	FIND_PICKAXE = 1,
	SALVAGE_CRATES = 2,
	MINE_IRON = 3,
	FIND_CRYPT_RUNE = 4,
	ACTIVATE_RIFT_ANCHOR = 5,
	ESCAPED = 6
}

var current_stage: Stage = Stage.FIND_LANTERN
var player_ref: CharacterBody3D = null
var hud_ref: CanvasLayer = null
var voxel_world_ref: Node3D = null

var lantern_prop: StaticBody3D = null
var pickaxe_prop: StaticBody3D = null
var crypt_rune_prop: StaticBody3D = null
var rift_anchor_prop: StaticBody3D = null

var mined_iron_count: int = 0
var required_iron: int = 3
var has_crypt_rune: bool = false

signal scenario_stage_advanced(new_stage: int)

func setup(player: CharacterBody3D, hud: CanvasLayer, voxel_world: Node3D) -> void:
	player_ref = player
	hud_ref = hud
	voxel_world_ref = voxel_world

	if voxel_world_ref and voxel_world_ref.has_signal("block_broken"):
		voxel_world_ref.block_broken.connect(_on_block_broken)

	_spawn_lantern_prop()
	_spawn_pickaxe_prop()
	_spawn_crypt_rune_prop()
	_spawn_rift_anchor_prop()
	_apply_stage_directive()

func _process(_delta: float) -> void:
	if player_ref == null:
		return

	var py = player_ref.global_position.y

	# Altitude and exploration progression checks
	if current_stage == Stage.MINE_IRON:
		var iron_cnt = 0
		if "inventory_system" in player_ref and player_ref.inventory_system:
			for s in player_ref.inventory_system.slots:
				if not s.is_empty() and s.get("id") == "iron":
					iron_cnt += s.get("count", 0)
		if iron_cnt >= required_iron:
			_on_iron_requirement_met()

	elif current_stage == Stage.FIND_CRYPT_RUNE:
		if has_crypt_rune:
			current_stage = Stage.ACTIVATE_RIFT_ANCHOR
			_apply_stage_directive()
			scenario_stage_advanced.emit(int(current_stage))

func _spawn_lantern_prop() -> void:
	if lantern_prop != null:
		return

	lantern_prop = StaticBody3D.new()
	lantern_prop.name = "ScenarioLantern"
	lantern_prop.collision_layer = 8
	lantern_prop.collision_mask = 0
	lantern_prop.position = Vector3(2.2, 11.0, 0.5)

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.6, 0.8, 0.6)
	col.shape = box
	lantern_prop.add_child(col)

	var scene_res = load("res://models/expedition_lantern.glb")
	if scene_res:
		var inst = scene_res.instantiate()
		inst.scale = Vector3(0.85, 0.85, 0.85)
		lantern_prop.add_child(inst)

	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.72, 0.35)
	light.light_energy = 0.9
	light.omni_range = 3.5
	lantern_prop.add_child(light)

	lantern_prop.set_meta("interaction_text", "[E] ПОДОБРАТЬ АВАРИЙНЫЙ ФОНАРЬ ЭКСПЕДИЦИИ")
	lantern_prop.set_meta("is_scenario_lantern", true)
	add_child(lantern_prop)

func _spawn_pickaxe_prop() -> void:
	if pickaxe_prop != null:
		return

	pickaxe_prop = StaticBody3D.new()
	pickaxe_prop.name = "ScenarioPickaxe"
	pickaxe_prop.collision_layer = 8
	pickaxe_prop.collision_mask = 0
	pickaxe_prop.position = Vector3(-3.8, 11.3, 2.0)
	pickaxe_prop.rotation_degrees = Vector3(25.0, 75.0, -15.0)

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.8, 0.8, 0.8)
	col.shape = box
	pickaxe_prop.add_child(col)

	var scene_res = load("res://models/prospector_pickaxe.glb")
	if scene_res:
		var inst = scene_res.instantiate()
		inst.scale = Vector3(0.9, 0.9, 0.9)
		pickaxe_prop.add_child(inst)

	pickaxe_prop.set_meta("interaction_text", "[E] ИЗВЛЕЧЬ КИРКУ ГЕОЛОГА ИЗ ОБВАЛА БАЛКИ")
	pickaxe_prop.set_meta("is_scenario_pickaxe", true)
	add_child(pickaxe_prop)

func _spawn_crypt_rune_prop() -> void:
	if crypt_rune_prop != null:
		return

	crypt_rune_prop = StaticBody3D.new()
	crypt_rune_prop.name = "CryptRuneProp"
	crypt_rune_prop.collision_layer = 8
	crypt_rune_prop.collision_mask = 0
	# Located on the occult bedrock altar in the crypt at (18.5, 11.8, 38.5)
	crypt_rune_prop.position = Vector3(18.5, 11.8, 38.5)

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.7, 0.7, 0.7)
	col.shape = box
	crypt_rune_prop.add_child(col)

	var mesh_inst = MeshInstance3D.new()
	var prism = BoxMesh.new()
	prism.size = Vector3(0.35, 0.5, 0.35)
	mesh_inst.mesh = prism
	mesh_inst.rotation_degrees = Vector3(25, 45, 15)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.85, 0.95)
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.9, 1.0)
	mat.emission_energy_multiplier = 4.0
	mesh_inst.material_override = mat
	crypt_rune_prop.add_child(mesh_inst)

	var light = OmniLight3D.new()
	light.light_color = Color(0.2, 0.85, 1.0)
	light.light_energy = 2.2
	light.omni_range = 5.0
	crypt_rune_prop.add_child(light)

	crypt_rune_prop.set_meta("interaction_text", "[E] ЗАБРАТЬ РЕЛИКТОВЫЙ РУННЫЙ КЛЮЧ НАБЛЮДАТЕЛЯ")
	crypt_rune_prop.set_meta("is_crypt_rune", true)
	add_child(crypt_rune_prop)

func _spawn_rift_anchor_prop() -> void:
	if rift_anchor_prop != null:
		return

	rift_anchor_prop = StaticBody3D.new()
	rift_anchor_prop.name = "RiftAnchorProp"
	rift_anchor_prop.collision_layer = 8
	rift_anchor_prop.collision_mask = 0
	# Deep in the volcanic abyss at (24.0, -36.0, 10.0)
	rift_anchor_prop.position = Vector3(24.0, -36.0, 10.0)

	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 1.2
	cyl.height = 3.0
	col.shape = cyl
	rift_anchor_prop.add_child(col)

	var mesh_inst = MeshInstance3D.new()
	var c_mesh = CylinderMesh.new()
	c_mesh.top_radius = 0.9
	c_mesh.bottom_radius = 1.2
	c_mesh.height = 2.8
	mesh_inst.mesh = c_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.14, 0.18)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.45, 0.1)
	mat.emission_energy_multiplier = 2.5
	mesh_inst.material_override = mat
	rift_anchor_prop.add_child(mesh_inst)

	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.55, 0.2)
	light.light_energy = 3.0
	light.omni_range = 9.0
	rift_anchor_prop.add_child(light)

	rift_anchor_prop.set_meta("interaction_text", "[E] АКТИВИРОВАТЬ РЕЗОНАНСНЫЙ ЯКОРЬ РАЗЛОМА")
	rift_anchor_prop.set_meta("is_rift_anchor", true)
	add_child(rift_anchor_prop)

func interact_with_prop(prop: Node) -> bool:
	if prop == null:
		return false

	if prop.has_meta("is_scenario_lantern") and current_stage == Stage.FIND_LANTERN:
		_on_lantern_collected()
		return true
	elif prop.has_meta("is_scenario_pickaxe") and current_stage == Stage.FIND_PICKAXE:
		_on_pickaxe_collected()
		return true
	elif prop.has_meta("is_crypt_rune") and current_stage == Stage.FIND_CRYPT_RUNE:
		_on_crypt_rune_collected()
		return true
	elif prop.has_meta("is_rift_anchor") and current_stage == Stage.ACTIVATE_RIFT_ANCHOR:
		_on_rift_anchor_activated()
		return true

	return false

func _on_lantern_collected() -> void:
	if lantern_prop and is_instance_valid(lantern_prop):
		lantern_prop.queue_free()
		lantern_prop = null

	if player_ref and "inventory_system" in player_ref and player_ref.inventory_system:
		player_ref.inventory_system.set_slot(0, "lantern", 1)
		player_ref.set_active_slot(1)

	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("item_pickup", player_ref.global_position)

	current_stage = Stage.FIND_PICKAXE
	_apply_stage_directive()
	scenario_stage_advanced.emit(int(current_stage))

func _on_pickaxe_collected() -> void:
	if pickaxe_prop and is_instance_valid(pickaxe_prop):
		pickaxe_prop.queue_free()
		pickaxe_prop = null

	if player_ref and "inventory_system" in player_ref and player_ref.inventory_system:
		player_ref.inventory_system.set_slot(1, "pickaxe", 1)
		player_ref.set_active_slot(2)

	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("item_pickup", player_ref.global_position)

	current_stage = Stage.SALVAGE_CRATES
	_apply_stage_directive()
	scenario_stage_advanced.emit(int(current_stage))

func _on_block_broken(_coord: Vector3i, block_type: int) -> void:
	if block_type == 19 and current_stage == Stage.SALVAGE_CRATES:
		_on_crate_salvaged()
	elif block_type == 8: # Iron ore
		mined_iron_count += 1
		if current_stage == Stage.MINE_IRON:
			_apply_stage_directive()

func _on_crate_salvaged() -> void:
	current_stage = Stage.MINE_IRON
	_apply_stage_directive()

	if player_ref and player_ref.has_method("apply_screen_shake"):
		player_ref.apply_screen_shake(1.2)

	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("distant_scream", player_ref.global_position + Vector3(30, 4, 10))

	scenario_stage_advanced.emit(int(current_stage))

func _on_iron_requirement_met() -> void:
	current_stage = Stage.FIND_CRYPT_RUNE
	_apply_stage_directive()

	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_horror_swell"):
		sm.play_horror_swell()

	scenario_stage_advanced.emit(int(current_stage))

func _on_crypt_rune_collected() -> void:
	has_crypt_rune = true
	if crypt_rune_prop and is_instance_valid(crypt_rune_prop):
		crypt_rune_prop.queue_free()
		crypt_rune_prop = null

	if player_ref and "inventory_system" in player_ref and player_ref.inventory_system:
		player_ref.inventory_system.add_item("ancient_core", 1)

	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_horror_swell"):
		sm.play_horror_swell()
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("item_pickup", player_ref.global_position)

	current_stage = Stage.ACTIVATE_RIFT_ANCHOR
	_apply_stage_directive()
	scenario_stage_advanced.emit(int(current_stage))

func _on_rift_anchor_activated() -> void:
	current_stage = Stage.ESCAPED
	_apply_stage_directive()

	# Dramatic blinding flash and purge of subterranean horror
	if player_ref and player_ref.has_method("apply_screen_shake"):
		player_ref.apply_screen_shake(3.0)

	var sm = get_tree().get_first_node_in_group("sound_manager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("explosion", player_ref.global_position, 0.7, 4.0)

	scenario_stage_advanced.emit(int(current_stage))

func _apply_stage_directive() -> void:
	if hud_ref == null:
		return

	var d_lbl: Label = hud_ref.get("directive_label")
	if d_lbl == null:
		return

	match current_stage:
		Stage.FIND_LANTERN:
			d_lbl.text = "⚡ [МИССИЯ 1/5]: ПОДОБРАТЬ АВАРИЙНЫЙ ФОНАРЬ СО СТОЛА (НАЖМИТЕ E)"
			d_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.28))
		Stage.FIND_PICKAXE:
			d_lbl.text = "⚡ [МИССИЯ 2/5]: ИЗВЛЕЧЬ КИРКУ ГЕОЛОГА ИЗ ОБВАЛА БАЛКИ (НАЖМИТЕ E)"
			d_lbl.add_theme_color_override("font_color", Color(0.92, 0.82, 0.45))
		Stage.SALVAGE_CRATES:
			d_lbl.text = "⚡ [МИССИЯ 3/5]: РАЗБИТЬ ЯЩИКИ СНАБЖЕНИЯ [ЛКМ] ДЛЯ СПАСЕНИЯ ДОСОК"
			d_lbl.add_theme_color_override("font_color", Color(0.95, 0.65, 0.30))
		Stage.MINE_IRON:
			var iron_cnt = 0
			if player_ref and "inventory_system" in player_ref and player_ref.inventory_system:
				for s in player_ref.inventory_system.slots:
					if not s.is_empty() and s.get("id") == "iron":
						iron_cnt += s.get("count", 0)
			d_lbl.text = "⚡ [МИССИЯ 4/5]: ДОБЫТЬ 3 ЖЕЛЕЗНЫЕ РУДЫ В ВОСТОЧНОМ РАЗЛОМЕ (ЖЕЛЕЗО: %d/3)" % iron_cnt
			d_lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.65))
		Stage.FIND_CRYPT_RUNE:
			d_lbl.text = "⚡ [МИССИЯ 5/5]: НАЙТИ ТАЙНУЮ КРИПТУ ЗА ТОННЕЛЕМ 2x2 И ЗАБРАТЬ РУННЫЙ КЛЮЧ"
			d_lbl.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0))
		Stage.ACTIVATE_RIFT_ANCHOR:
			d_lbl.text = "⚡ [ФИНАЛ]: СПУСТИТЬСЯ В БЕЗДНУ (Y <= -35) И АКТИВИРОВАТЬ РЕЗОНАНСНЫЙ ЯКОРЬ!"
			d_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.25))
		Stage.ESCAPED:
			d_lbl.text = "★ ПРОРЫВ ИЗ ПОЛОЙ БЕЗДНЫ СОВЕРШЕН // КОШМАР ИЗГНАН // ВЫ СПАСЛИСЬ!"
			d_lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
"""

with open("c:/Users/magom/Downloads/twitchst/hollow_core/scripts/scenario_manager.gd", "w", encoding="utf-8") as f:
    f.write(content)

print("Updated scenario_manager.gd successfully!")
