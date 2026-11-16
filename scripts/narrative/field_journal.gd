# scripts/narrative/field_journal.gd
class_name FieldJournalViewer
extends CanvasLayer

## Diegetic In-Game Field Notebook & Phonograph Journal for Hollow Core.
## Adheres strictly to Anti-AI-UI guidelines: restrained dark slate/graphite palette,
## single warm amber accent (#D49A3D), clean typography, zero emojis, zero glassmorphism.
## Toggled via [J] key.

const QuestRegistryClass = preload("res://scripts/narrative/quest_registry.gd")
const DocumentRegistryClass = preload("res://scripts/narrative/document_registry.gd")
const AudiologRegistryClass = preload("res://scripts/narrative/audiolog_registry.gd")
const ClueChainRegistryClass = preload("res://scripts/narrative/clue_chain_registry.gd")
const SecretRegistryClass = preload("res://scripts/narrative/secret_registry.gd")
const AudioStorySynthesizerClass = preload("res://scripts/audio/audio_story_synthesizer.gd")
const OrnateUIClass = preload("res://scripts/ui/ornate_ui.gd")
const SegmentedProgressBarClass = preload("res://scripts/ui/segmented_bar.gd")

var is_open: bool = false
var current_tab: int = 0 # 0: Quests, 1: Documents, 2: Audio, 3: Clues

var backdrop: ColorRect
var main_panel: PanelContainer
var tab_btn_quests: Button
var tab_btn_docs: Button
var tab_btn_audio: Button
var tab_btn_clues: Button
var content_container: VBoxContainer
var audio_player: AudioStreamPlayer
var active_playing_audio_id: String = ""

func _ready() -> void:
	add_to_group("field_journal")
	layer = 110
	visible = false
	_build_ui()

func _build_ui() -> void:
	# 1. Dark vignette backdrop
	backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.offset_left = 0
	backdrop.offset_top = 0
	backdrop.offset_right = 0
	backdrop.offset_bottom = 0
	backdrop.color = Color(0.012, 0.015, 0.020, 0.88)
	add_child(backdrop)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.offset_left = 0
	center.offset_top = 0
	center.offset_right = 0
	center.offset_bottom = 0
	center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(center)

	# 2. Main journal frame with Ornate Steampunk Style
	main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(880, 600)
	main_panel.add_theme_stylebox_override("panel", OrnateUIClass.create_main_panel_stylebox())

	var outer_vbox = VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 10)
	main_panel.add_child(outer_vbox)

	# Header: Ornate Plaque Title & Metadata
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 12)
	
	var header_banner = OrnateUIClass.create_header_banner("ПОЛЕВОЙ ЖУРНАЛ ГЕОФИЗИКА — Д-Р ЭДВАРД ВЕЙН", 38)
	header_hbox.add_child(header_banner)

	var close_hint = Label.new()
	close_hint.text = "[J] ИЛИ [ESC] — ЗАКРЫТЬ"
	close_hint.add_theme_color_override("font_color", OrnateUIClass.COLOR_MUTED)
	close_hint.add_theme_font_size_override("font_size", 11)
	header_hbox.add_child(close_hint)
	outer_vbox.add_child(header_hbox)

	var sep1 = HSeparator.new()
	outer_vbox.add_child(sep1)

	# Tab bar (Framed Ornate Metallic Buttons)
	var tabs_hbox = HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 8)

	tab_btn_quests = _create_tab_button("1. ЗАДАЧИ", 0)
	tab_btn_docs = _create_tab_button("2. ДОКУМЕНТЫ", 1)
	tab_btn_audio = _create_tab_button("3. ФОНОГРАММЫ", 2)
	tab_btn_clues = _create_tab_button("4. РАССЛЕДОВАНИЯ", 3)

	tabs_hbox.add_child(tab_btn_quests)
	tabs_hbox.add_child(tab_btn_docs)
	tabs_hbox.add_child(tab_btn_audio)
	tabs_hbox.add_child(tab_btn_clues)
	outer_vbox.add_child(tabs_hbox)

	# Content scroll area
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(824, 430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer_vbox.add_child(scroll)

	content_container = VBoxContainer.new()
	content_container.add_theme_constant_override("separation", 10)
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_container)

	center.add_child(main_panel)

	# Audio player for previewing tapes in journal
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "JournalAudioPlayer"
	audio_player.bus = "Master"
	audio_player.finished.connect(func():
		active_playing_audio_id = ""
		if is_open and current_tab == 2:
			_render_content()
	)
	add_child(audio_player)

func _create_tab_button(text_str: String, tab_idx: int) -> Button:
	var btn = Button.new()
	btn.text = text_str
	btn.custom_minimum_size = Vector2(190, 36)
	OrnateUIClass.style_button(btn, 12)
	btn.pressed.connect(func(): _switch_tab(tab_idx))
	return btn

func toggle_journal() -> void:
	if is_open:
		close_journal()
	else:
		open_journal()

func open_journal() -> void:
	is_open = true
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Cleanly hide viewmodel while inspecting journal
	var players = get_tree().get_nodes_in_group("player") if is_inside_tree() else []
	for p in players:
		if "viewmodel_layer" in p and p.viewmodel_layer:
			p.viewmodel_layer.visible = false
		if "pickaxe" in p and p.pickaxe:
			p.pickaxe.visible = false
	_switch_tab(current_tab)

func close_journal() -> void:
	is_open = false
	visible = false
	if audio_player and audio_player.playing:
		audio_player.stop()
		active_playing_audio_id = ""
	# Restore viewmodel when closing journal
	var players = get_tree().get_nodes_in_group("player") if is_inside_tree() else []
	for p in players:
		if "viewmodel_layer" in p and p.viewmodel_layer:
			p.viewmodel_layer.visible = true
		if "pickaxe" in p and p.pickaxe:
			p.pickaxe.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func switch_tab(tab_idx: int) -> void:
	_switch_tab(tab_idx)

func _switch_tab(tab_idx: int) -> void:
	current_tab = tab_idx
	# Highlight active button
	var btns = [tab_btn_quests, tab_btn_docs, tab_btn_audio, tab_btn_clues]
	for i in range(btns.size()):
		if btns[i] != null:
			if i == current_tab:
				btns[i].modulate = Color(1.0, 0.85, 0.45)
			else:
				btns[i].modulate = Color(0.70, 0.74, 0.80)

	_render_content()

func _render_content() -> void:
	# Clear previous content children
	for child in content_container.get_children():
		child.queue_free()

	var state = _get_story_state()

	match current_tab:
		0: _render_quests_tab(state)
		1: _render_documents_tab(state)
		2: _render_audiologs_tab(state)
		3: _render_clues_tab(state)

func _get_story_state() -> Resource:
	var tree = get_tree() if is_inside_tree() else null
	if tree:
		var nm = tree.get_first_node_in_group("narrative_manager")
		if nm and nm.get("story_state"):
			return nm.story_state
	return null

# -----------------------------------------------------------------------------
# TAB 1: QUESTS
# -----------------------------------------------------------------------------
func _render_quests_tab(state: Resource) -> void:
	var qm = get_tree().get_first_node_in_group("quest_manager") if is_inside_tree() else null
	var current_q = qm.get_current_quest() if qm else QuestRegistryClass.get_quest("Q00_CRASH_SURVIVAL")

	var q_card = PanelContainer.new()
	q_card.add_theme_stylebox_override("panel", OrnateUIClass.create_sub_panel_stylebox())
	var q_vbox = VBoxContainer.new()
	q_vbox.add_theme_constant_override("separation", 8)
	q_card.add_child(q_vbox)

	var act_header = Label.new()
	act_header.text = "АКТУАЛЬНАЯ ЗАДАЧА — АКТ %d" % (state.current_act if state else 1)
	act_header.add_theme_color_override("font_color", OrnateUIClass.COLOR_AMBER)
	act_header.add_theme_font_size_override("font_size", 13)
	q_vbox.add_child(act_header)

	var q_title = Label.new()
	q_title.text = current_q.get("title", "Поиск выхода").to_upper()
	q_title.add_theme_color_override("font_color", OrnateUIClass.COLOR_GOLD)
	q_title.add_theme_font_size_override("font_size", 15)
	q_vbox.add_child(q_title)

	var q_desc = Label.new()
	q_desc.text = current_q.get("description", "")
	q_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q_desc.add_theme_color_override("font_color", Color(0.72, 0.78, 0.85))
	q_desc.add_theme_font_size_override("font_size", 12)
	q_vbox.add_child(q_desc)

	# Sub-objectives checklist
	var subs = current_q.get("sub_objectives", {})
	if not subs.is_empty():
		var subs_vbox = VBoxContainer.new()
		subs_vbox.add_theme_constant_override("separation", 6)
		for sub_k in subs:
			var s_data = subs[sub_k]
			var is_done = s_data.get("done", false)
			var sub_lbl = Label.new()
			sub_lbl.text = "  [%s]  %s" % ["X" if is_done else " ", s_data.get("text", "")]
			sub_lbl.add_theme_color_override("font_color", Color(0.45, 0.85, 0.55) if is_done else Color(0.85, 0.88, 0.92))
			sub_lbl.add_theme_font_size_override("font_size", 12)
			subs_vbox.add_child(sub_lbl)
		q_vbox.add_child(subs_vbox)

	content_container.add_child(q_card)

	var sep = HSeparator.new()
	content_container.add_child(sep)

	# Completed quests log
	var comp_header = Label.new()
	comp_header.text = "ВЫПОЛНЕННЫЕ ЭТАПЫ"
	comp_header.add_theme_color_override("font_color", Color(0.60, 0.65, 0.72))
	comp_header.add_theme_font_size_override("font_size", 12)
	content_container.add_child(comp_header)

	var comp_list = state.completed_quests if state else []
	if comp_list.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "  (Нет завершённых этапов)"
		empty_lbl.add_theme_color_override("font_color", Color(0.45, 0.48, 0.52))
		empty_lbl.add_theme_font_size_override("font_size", 11)
		content_container.add_child(empty_lbl)
	else:
		for cq_id in comp_list:
			var q_data = QuestRegistryClass.get_quest(cq_id)
			var cq_lbl = Label.new()
			cq_lbl.text = "  [ВЫПОЛНЕНО]  %s" % q_data.get("title", cq_id)
			cq_lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.55))
			cq_lbl.add_theme_font_size_override("font_size", 11)
			content_container.add_child(cq_lbl)

# -----------------------------------------------------------------------------
# TAB 2: DOCUMENTS
# -----------------------------------------------------------------------------
func _render_documents_tab(state: Resource) -> void:
	var collected = state.collected_documents if state else []
	var count_lbl = Label.new()
	count_lbl.text = "НАЙДЕНО ДОКУМЕНТОВ: %d / 20" % collected.size()
	count_lbl.add_theme_color_override("font_color", Color(0.92, 0.74, 0.35))
	count_lbl.add_theme_font_size_override("font_size", 13)
	content_container.add_child(count_lbl)

	for doc_id in DocumentRegistryClass.get_all_document_ids():
		var doc_data = DocumentRegistryClass.get_document(doc_id)
		var is_found = collected.has(doc_id)

		var item_hbox = HBoxContainer.new()
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(780, 36)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		OrnateUIClass.style_button(btn, 11)

		if is_found:
			btn.text = "  [%s]  %s (%s)" % [doc_id, doc_data.get("title", ""), doc_data.get("date", "")]
			btn.pressed.connect(func(): _open_document(doc_id))
		else:
			btn.text = "  [%s]  [АРХИВНЫЙ ДОКУМЕНТ НЕ ОБНАРУЖЕН]" % doc_id
			btn.disabled = true
			btn.modulate = Color(0.40, 0.44, 0.48)

		item_hbox.add_child(btn)
		content_container.add_child(item_hbox)

func _open_document(doc_id: String) -> void:
	var doc_data = DocumentRegistryClass.get_document(doc_id)
	var viewer = get_tree().get_first_node_in_group("document_viewer") if is_inside_tree() else null
	if viewer and viewer.has_method("show_document"):
		close_journal()
		if "was_opened_from_journal" in viewer:
			viewer.was_opened_from_journal = true
		viewer.show_document(
			doc_id,
			doc_data.get("title", "").to_upper(),
			"%s — %s" % [doc_data.get("date", ""), doc_data.get("author", "")],
			doc_data.get("primary_lore", "")
		)

# -----------------------------------------------------------------------------
# TAB 3: AUDIOLOGS
# -----------------------------------------------------------------------------
func _render_audiologs_tab(state: Resource) -> void:
	var played = state.played_audiologs if state else []
	var count_lbl = Label.new()
	count_lbl.text = "ПОЛЕВОЙ ФОНОГРАФ — НАЙДЕНО ПЛЕНОК: %d / 20" % played.size()
	count_lbl.add_theme_color_override("font_color", Color(0.92, 0.74, 0.35))
	count_lbl.add_theme_font_size_override("font_size", 13)
	content_container.add_child(count_lbl)

	for audio_id in AudiologRegistryClass.get_all_audiolog_ids():
		var log_data = AudiologRegistryClass.get_audiolog(audio_id)
		var is_unlocked = played.has(audio_id)

		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", OrnateUIClass.create_sub_panel_stylebox())

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		card.add_child(vbox)

		var h_line = HBoxContainer.new()
		var title_lbl = Label.new()
		if is_unlocked:
			var freq_str = " — %.1f Гц" % log_data.get("frequency", 0.0) if log_data.get("frequency", 0.0) > 0.0 else ""
			title_lbl.text = "[%s]  %s (%s)%s" % [audio_id, log_data.get("title", ""), log_data.get("date", ""), freq_str]
			title_lbl.add_theme_color_override("font_color", OrnateUIClass.COLOR_GOLD)
			title_lbl.add_theme_font_size_override("font_size", 12)
		else:
			title_lbl.text = "[%s]  [МАГНИТНАЯ ЛЕНТА НЕ НАЙДЕНА]" % audio_id
			title_lbl.add_theme_color_override("font_color", Color(0.40, 0.44, 0.48))
			title_lbl.add_theme_font_size_override("font_size", 12)
		h_line.add_child(title_lbl)

		var sp = Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h_line.add_child(sp)

		if is_unlocked:
			var play_btn = Button.new()
			var is_currently_playing = (audio_player and audio_player.playing and active_playing_audio_id == audio_id)
			play_btn.text = "СТОП" if is_currently_playing else "ВОСПРОИЗВЕСТИ"
			play_btn.custom_minimum_size = Vector2(140, 30)
			OrnateUIClass.style_button(play_btn, 11)
			play_btn.pressed.connect(func(): _toggle_play_tape(audio_id))
			h_line.add_child(play_btn)

		vbox.add_child(h_line)

		if is_unlocked:
			if audio_player and audio_player.playing and active_playing_audio_id == audio_id:
				var tape_bar = SegmentedProgressBarClass.new(16, "amber", "ВОСПРОИЗВЕДЕНИЕ СИГНАЛА")
				tape_bar.set_value(0.75)
				vbox.add_child(tape_bar)

			var transcript_lbl = Label.new()
			transcript_lbl.text = log_data.get("transcript", "")
			transcript_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			transcript_lbl.add_theme_color_override("font_color", Color(0.70, 0.74, 0.78))
			transcript_lbl.add_theme_font_size_override("font_size", 11)
			vbox.add_child(transcript_lbl)

		content_container.add_child(card)

func _toggle_play_tape(audio_id: String) -> void:
	if audio_player == null:
		return

	if audio_player.playing and active_playing_audio_id == audio_id:
		audio_player.stop()
		active_playing_audio_id = ""
		_render_content()
		return

	var stream = AudioStorySynthesizerClass.get_audiolog_stream(audio_id)
	if stream:
		audio_player.stream = stream
		audio_player.play()
		active_playing_audio_id = audio_id
		_render_content()

# -----------------------------------------------------------------------------
# TAB 4: CLUE CHAINS & SECRETS
# -----------------------------------------------------------------------------
func _render_clues_tab(state: Resource) -> void:
	var chains_hdr = Label.new()
	chains_hdr.text = "СЮЖЕТНЫЕ ЦЕПОЧКИ РАССЛЕДОВАНИЯ"
	chains_hdr.add_theme_color_override("font_color", Color(0.92, 0.74, 0.35))
	chains_hdr.add_theme_font_size_override("font_size", 13)
	content_container.add_child(chains_hdr)

	for chain_id in ClueChainRegistryClass.get_all_chain_ids():
		var chain_data = ClueChainRegistryClass.get_chain(chain_id)
		var progress: Array = state.clue_chains_progress.get(chain_id, []) if state else []
		var is_complete = progress.size() >= 4

		var panel = PanelContainer.new()
		panel.add_theme_stylebox_override("panel", OrnateUIClass.create_sub_panel_stylebox())

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		panel.add_child(vbox)

		var status_str = "[ВЫВОД СФОРМУЛИРОВАН]" if is_complete else "[УЛИК: %d / 4]" % progress.size()
		var t_lbl = Label.new()
		t_lbl.text = "%s: %s  %s" % [chain_id, chain_data.get("title", ""), status_str]
		t_lbl.add_theme_color_override("font_color", Color(0.45, 0.85, 0.55) if is_complete else Color(0.85, 0.88, 0.92))
		t_lbl.add_theme_font_size_override("font_size", 13)
		vbox.add_child(t_lbl)

		var clues_arr = chain_data.get("clues", [])
		for idx in range(clues_arr.size()):
			var c_entry = clues_arr[idx]
			var found = progress.has(idx)
			var c_lbl = Label.new()
			c_lbl.text = "    [%s]  %s" % ["X" if found else " ", c_entry.get("name", "")]
			c_lbl.add_theme_color_override("font_color", Color(0.50, 0.75, 0.50) if found else Color(0.45, 0.48, 0.52))
			c_lbl.add_theme_font_size_override("font_size", 11)
			vbox.add_child(c_lbl)

		if is_complete:
			var ded_lbl = Label.new()
			ded_lbl.text = "    ВЫВОД: " + chain_data.get("deduction", "")
			ded_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ded_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
			ded_lbl.add_theme_font_size_override("font_size", 12)
			vbox.add_child(ded_lbl)

		content_container.add_child(panel)

	var sep = HSeparator.new()
	content_container.add_child(sep)

	# Secrets & Rooms counter
	var secrets_hdr = Label.new()
	var sec_count = state.discovered_secrets.size() if state else 0
	var room_count = state.discovered_secret_rooms.size() if state else 0
	secrets_hdr.text = "СЕКРЕТЫ МИРА — ПАСХАЛКИ: %d / 20  |  ТАЙНЫЕ ПОМЕЩЕНИЯ: %d / 5" % [sec_count, room_count]
	secrets_hdr.add_theme_color_override("font_color", Color(0.60, 0.65, 0.72))
	secrets_hdr.add_theme_font_size_override("font_size", 12)
	content_container.add_child(secrets_hdr)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		# Do not toggle journal if document viewer is currently open
		var viewer = get_tree().get_first_node_in_group("document_viewer") if is_inside_tree() else null
		if viewer and viewer.get("visible") == true:
			return

		var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if event.keycode == KEY_J or code == KEY_J or event.keycode == 1054 or code == 1054:
			get_viewport().set_input_as_handled()
			toggle_journal()
		elif is_open and event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			close_journal()
