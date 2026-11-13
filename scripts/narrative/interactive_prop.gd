# scripts/narrative/interactive_prop.gd
class_name InteractiveProp
extends Area3D

## Universal Base Class for Physical Story Props, Pickups, and Interactive Lore.
## Directly integrates with PlayerController raycasts and NarrativeManager.

signal prop_interacted(player: CharacterBody3D)

@export var prompt_message: String = "[E] ОСМОТРЕТЬ"
@export var is_one_shot: bool = true
@export var sfx_on_interact: String = "item_pickup"
@export var item_grant_id: String = ""
@export var item_grant_count: int = 1
@export var narrative_flag_on_collect: String = ""
@export var doc_id: String = ""
@export var audiolog_id: String = ""

var is_interacted: bool = false
var collision_shape: CollisionShape3D = null

func _ready() -> void:
	add_to_group("interactable")
	# Layer 8: Interactable Props, Layer 4: Items
	collision_layer = 4 | 8
	collision_mask = 0

	# Ensure a collision shape exists if not set in editor/procedurally
	if get_node_or_null("CollisionShape3D") == null:
		collision_shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(0.8, 0.8, 0.8)
		collision_shape.shape = box
		add_child(collision_shape)
	else:
		collision_shape = get_node("CollisionShape3D")

func get_interaction_prompt() -> String:
	return prompt_message

func interact(player: CharacterBody3D) -> bool:
	if is_one_shot and is_interacted:
		return false

	is_interacted = true
	_execute_interaction(player)
	prop_interacted.emit(player)

	# Audio feedback
	var tree = get_tree() if is_inside_tree() else null
	if sfx_on_interact != "" and tree:
		var sm = tree.get_first_node_in_group("sound_manager")
		if sm and sm.has_method("play_sfx"):
			sm.play_sfx(sfx_on_interact, global_position)

	# Optional Item Grant into Inventory
	if item_grant_id != "" and player:
		if "inventory_system" in player and player.inventory_system:
			if player.inventory_system.has_method("add_item"):
				player.inventory_system.add_item(item_grant_id, item_grant_count)
			# If lantern or pickaxe, sync held viewmodel instantly
			if item_grant_id == "lantern":
				if player.has_method("set_active_slot"):
					player.set_active_slot(1)
				if "lantern" in player and player.lantern:
					player.lantern.set_hand_mode(true)
					player.lantern.set_lit(true)
			elif item_grant_id == "pickaxe":
				if player.has_method("set_active_slot"):
					player.set_active_slot(2)

		if tree:
			var hud = tree.get_first_node_in_group("hud")
			if hud and hud.has_method("show_pickup_notice"):
				hud.show_pickup_notice(item_grant_id, item_grant_id.capitalize(), item_grant_count)

	# Narrative flag & system updates
	if tree:
		var nm = tree.get_first_node_in_group("narrative_manager")
		if nm:
			if narrative_flag_on_collect != "" and nm.has_method("trigger_world_event"):
				nm.trigger_world_event(narrative_flag_on_collect)
			if doc_id != "" and nm.has_method("inspect_document"):
				nm.inspect_document(doc_id)
			if audiolog_id != "" and nm.has_method("play_audiolog"):
				nm.play_audiolog(audiolog_id)

	# Free prop if one-shot item pickup
	if is_one_shot and item_grant_id != "":
		call_deferred("queue_free")

	return true

func _execute_interaction(_player: CharacterBody3D) -> void:
	# Virtual extension point for custom mechanics (valves, doors, safes)
	pass
