# tools/import_assets.gd
extends SceneTree

func _init():
	print("[Importer] Scanning filesystem...")
	var fs = EditorInterface.get_resource_filesystem() if Engine.is_editor_hint() else null
	# Simple load test
	var glb_cassette = load("res://models/cassette_tape.glb")
	print("Cassette loaded: ", glb_cassette != null)
	var glb_arm = load("res://models/first_person_arm.glb")
	print("Arm loaded: ", glb_arm != null)
	quit(0)
