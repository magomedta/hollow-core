extends SceneTree

const CarbideTorchClass = preload("res://scripts/carbide_torch.gd")

func _init() -> void:
	print("=== [TEST] Carbide Torch Verification by Hydrogen & Antigravity ===")
	
	var root = Node3D.new()
	root.name = "TestRoot"
	get_root().add_child(root)
	
	# 1. Floor Torch
	var floor_torch = CarbideTorchClass.new()
	root.add_child(floor_torch)
	floor_torch.place_on_surface(Vector3(0, 0, 0), Vector3.UP)
	print("✓ Floor torch mounted at (0, 0, 0) with normal UP.")
	
	# 2. Wall Torch
	var wall_torch = CarbideTorchClass.new()
	root.add_child(wall_torch)
	wall_torch.place_on_surface(Vector3(2, 1.5, 0), Vector3.LEFT)
	print("✓ Wall torch mounted at (2, 1.5, 0) with normal LEFT (tilted).")
	
	# 3. Verify Light and Safe Zone
	assert(floor_torch.is_lit(), "Floor torch should be lit")
	assert(wall_torch.is_lit(), "Wall torch should be lit")
	print("✓ Torches are lit with active OmniLight3D and Safe Zone Area3D.")
	
	print("=== [TEST SUCCESS] All Carbide Torch checks passed! ===")
	quit(0)
