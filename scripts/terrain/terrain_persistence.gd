# scripts/terrain/terrain_persistence.gd
class_name TerrainPersistence
extends RefCounted

## Manages persistent storage and loading of modified geology deltas.
## Ensures that dug cavities and placed blocks survive game restarts
## without saving gigabytes of unchanged procedural noise.

const BASE_SAVES_DIR: String = "user://saves"

static func get_slot_dir(slot_name: String) -> String:
	return BASE_SAVES_DIR + "/" + slot_name

static func get_chunks_dir(slot_name: String) -> String:
	return get_slot_dir(slot_name) + "/chunks"

static func save_world_modifications(slot_name: String, world_seed: int, modified_voxels: Dictionary) -> bool:
	var dir_path = get_chunks_dir(slot_name)
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	# 1. Group modified voxels by chunk column Vector2i(cx, cz)
	var chunk_groups: Dictionary = {}
	for coord in modified_voxels.keys():
		var cx = int(floor(float(coord.x) / 16.0))
		var cz = int(floor(float(coord.z) / 16.0))
		var c_key = Vector2i(cx, cz)
		if not chunk_groups.has(c_key):
			chunk_groups[c_key] = {}
		chunk_groups[c_key][coord] = modified_voxels[coord]

	# 2. Write metadata header
	var meta_file_path = get_slot_dir(slot_name) + "/world_meta.json"
	var meta_file = FileAccess.open(meta_file_path, FileAccess.WRITE)
	if meta_file == null:
		push_error("[TerrainPersistence] Failed to open meta file: " + meta_file_path)
		return false

	var meta = {
		"version": 1,
		"seed": world_seed,
		"timestamp": Time.get_unix_time_from_system(),
		"total_modified_voxels": modified_voxels.size(),
		"modified_chunks_count": chunk_groups.size()
	}
	meta_file.store_string(JSON.stringify(meta, "\t"))
	meta_file.close()

	# 3. Save each modified chunk column delta
	for c_key in chunk_groups.keys():
		var chunk_mods: Dictionary = chunk_groups[c_key]
		var chunk_file_path = dir_path + "/chunk_%d_%d.dat" % [c_key.x, c_key.y]
		var f = FileAccess.open(chunk_file_path, FileAccess.WRITE)
		if f:
			# Store count of modified voxels in this chunk
			f.store_32(chunk_mods.size())
			for coord in chunk_mods.keys():
				f.store_32(coord.x)
				f.store_32(coord.y)
				f.store_32(coord.z)
				f.store_16(chunk_mods[coord]) # BlockType
			f.close()

	print("[TerrainPersistence] Saved %d modified voxels across %d chunks to slot '%s'." % [
		modified_voxels.size(), chunk_groups.size(), slot_name
	])
	return true

static func load_world_modifications(slot_name: String, expected_seed: int = -1) -> Dictionary:
	var result: Dictionary = {}
	var slot_dir = get_slot_dir(slot_name)
	var meta_file_path = slot_dir + "/world_meta.json"

	if not FileAccess.file_exists(meta_file_path):
		return result # Clean world, no saves

	var meta_file = FileAccess.open(meta_file_path, FileAccess.READ)
	if meta_file == null:
		return result

	var meta_text = meta_file.get_as_text()
	meta_file.close()

	var parse_res = JSON.parse_string(meta_text)
	if parse_res is Dictionary:
		if expected_seed != -1 and parse_res.has("seed"):
			if parse_res["seed"] != expected_seed:
				push_warning("[TerrainPersistence] Warning: Save seed (%d) does not match world seed (%d)" % [
					parse_res["seed"], expected_seed
				])

	var chunks_dir = get_chunks_dir(slot_name)
	var dir = DirAccess.open(chunks_dir)
	if dir == null:
		return result

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.begins_with("chunk_") and file_name.ends_with(".dat"):
			var file_path = chunks_dir + "/" + file_name
			var f = FileAccess.open(file_path, FileAccess.READ)
			if f:
				var count = f.get_32()
				for i in range(count):
					var x = f.get_32()
					var y = f.get_32()
					var z = f.get_32()
					var b_type = f.get_16()
					result[Vector3i(x, y, z)] = b_type
				f.close()
		file_name = dir.get_next()
	dir.list_dir_end()

	print("[TerrainPersistence] Loaded %d modified voxels from slot '%s'." % [result.size(), slot_name])
	return result

static func has_save(slot_name: String) -> bool:
	return FileAccess.file_exists(get_slot_dir(slot_name) + "/world_meta.json")

static func clear_save(slot_name: String) -> void:
	var chunks_dir = get_chunks_dir(slot_name)
	if DirAccess.dir_exists_absolute(chunks_dir):
		var dir = DirAccess.open(chunks_dir)
		if dir:
			dir.list_dir_begin()
			var fn = dir.get_next()
			while fn != "":
				if not dir.current_is_dir():
					dir.remove(fn)
				fn = dir.get_next()
			dir.list_dir_end()
			DirAccess.remove_absolute(chunks_dir)

	var slot_dir = get_slot_dir(slot_name)
	if DirAccess.dir_exists_absolute(slot_dir):
		if FileAccess.file_exists(slot_dir + "/world_meta.json"):
			DirAccess.remove_absolute(slot_dir + "/world_meta.json")
		DirAccess.remove_absolute(slot_dir)
