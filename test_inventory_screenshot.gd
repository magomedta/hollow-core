extends SceneTree

func _init():
	print("[InventoryTest] Launching...")
	var main_scene = load("res://scenes/main.tscn")
	var root_node = null
	if main_scene:
		root_node = main_scene.instantiate()
	else:
		root_node = load("res://scripts/main.gd").new()
	root.add_child(root_node)

	# Wait 20 frames for full initialization
	for i in range(20):
		await process_frame

	var player = root.get_node_or_null("Node3D/Player")
	if not player:
		player = root_node.get_node_or_null("Player")

	if player and "inventory_system" in player and player.inventory_system:
		var inv = player.inventory_system
		inv.set_slot(0, "lantern", 1)
		inv.set_slot(1, "pickaxe", 1)
		inv.set_slot(2, "torch", 16)
		inv.set_slot(3, "timber", 12)
		inv.set_slot(4, "planks", 24)
		inv.set_slot(5, "cobblestone", 32)
		inv.set_slot(6, "calcite", 8)
		inv.set_slot(7, "magma", 4)
		inv.set_slot(8, "cargo_crate", 2)
		inv.set_slot(9, "iron", 6)
		inv.set_slot(10, "copper", 12)
		inv.set_slot(11, "gold", 3)
		inv.set_slot(12, "phosphor", 15)
		inv.set_slot(13, "mushroom", 5)
		inv.set_slot(14, "canteen", 1)
		inv.set_slot(15, "rations", 4)
		inv.set_open(true)
		print("[InventoryTest] Inventory opened with showcase items.")

	for i in range(25):
		await process_frame

	var tex = root.get_texture()
	if tex:
		var img = tex.get_image()
		if img:
			var path = "res://screenshots/screen_inventory_large_icons.png"
			img.save_png(path)
			print("[InventoryTest] Successfully saved screen_inventory_large_icons.png!")

	quit(0)
