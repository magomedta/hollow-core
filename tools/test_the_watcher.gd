extends SceneTree

func _init():
	var watcher_class = load("res://scripts/the_watcher.gd")
	var watcher = watcher_class.new()
	root.add_child(watcher)
	print("TheWatcher initialized successfully!")
	print("Watcher position: ", watcher.position)
	print("Has eyes: ", watcher.eye_left != null, watcher.eye_right != null)
	watcher.queue_free()
	print("TheWatcher destroyed cleanly!")
	quit(0)
