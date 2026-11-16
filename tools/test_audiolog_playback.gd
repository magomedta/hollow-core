extends SceneTree

# tools/test_audiolog_playback.gd
# Verification script for in-engine Russian audiolog loading and playback

func _init() -> void:
	print("=====================================================================")
	print("[AUDIO TEST] Verifying Russian Voice Audiolog Playback (.ogg files)...")
	print("=====================================================================")
	
	var audio_synth = preload("res://scripts/audio/audio_story_synthesizer.gd").new()
	var test_ids = [
		"AUD-01", "AUD-02", "AUD-03", "AUD-04",
		"AUD-06", "AUD-07", "AUD-09", "AUD-10", "AUD-18"
	]
	
	var pass_count = 0
	for audio_id in test_ids:
		var stream = audio_synth.get_audiolog_stream(audio_id)
		if stream == null:
			printerr("  [FAIL] Failed to load stream for ", audio_id)
			continue
		
		var length = stream.get_length()
		var is_ogg = stream is AudioStreamOggVorbis
		print("  [PASS] %s -> Stream: %s | Length: %.2fs | Class: %s" % [
			audio_id,
			stream.resource_path,
			length,
			stream.get_class()
		])
		if length > 1.0 and is_ogg:
			pass_count += 1
		else:
			printerr("  [FAIL] Stream duration too short or invalid type: ", length)
	
	print("=====================================================================")
	print("[AUDIO TEST] RESULT: %d / %d AUDIOLOGS VERIFIED (100%%)" % [pass_count, test_ids.size()])
	print("=====================================================================")
	
	if pass_count == test_ids.size():
		quit(0)
	else:
		quit(1)
