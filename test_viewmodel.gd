extends SceneTree

func _init() -> void:
	print("Testing viewmodel camera architecture...")
	var root_node = Node3D.new()
	root.add_child(root_node)

	var sub_viewport_container = SubViewportContainer.new()
	sub_viewport_container.stretch = true
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 5
	canvas_layer.add_child(sub_viewport_container)
	root_node.add_child(canvas_layer)

	var sub_viewport = SubViewport.new()
	sub_viewport.transparent_bg = true
	sub_viewport.own_world_3d = false
	sub_viewport_container.add_child(sub_viewport)

	var vm_cam = Camera3D.new()
	vm_cam.cull_mask = 2
	sub_viewport.add_child(vm_cam)

	print("Viewmodel SubViewport setup completed successfully!")
	quit(0)
