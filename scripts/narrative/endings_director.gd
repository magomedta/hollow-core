# scripts/narrative/endings_director.gd
class_name EndingsDirector
extends CanvasLayer

## Director for the 3 Canonical Endings of Hollow Core:
## - Ending A: «Прорыв на Поверхность» (Breakthrough to Surface)
## - Ending B: «Страж Резонанса» (Resonance Guardian)
## - Ending C: «Петля Сверхоризонта» (Overhorizon Loop)
## Evaluates prerequisites based on StoryStateResource and presents the cinematic epilogue.

const StoryStateResourceClass = preload("res://scripts/resources/story_state_resource.gd")
const AudioStorySynthesizerClass = preload("res://scripts/audio/audio_story_synthesizer.gd")

signal ending_completed(ending_id: String)

var active_ending_id: String = ""
var background_rect: ColorRect
var modal_panel: PanelContainer
var title_label: Label
var subtitle_label: Label
var epilogue_label: Label
var quote_label: Label
var action_btn: Button
var audio_player: AudioStreamPlayer

const ENDING_DATA: Dictionary = {
	"A": {
		"id": "A",
		"title": "ФИНАЛ A: ПРОРЫВ НА ПОВЕРХНОСТЬ",
		"subtitle": "«Эвакуация без настройки Резонансного Анкера»",
		"quote": "«Холодный арктический воздух обжигает легкие. Но в радиоэфире слышны три удара...»",
		"epilogue": "Доктор Эдвард Вейн восстановил тросовый подъёмник и поднялся на поверхность Земли.\n\nПолярная станция «Сверхоризонт» встретила его свистом ледяной метели и брошенными балками. При попытке вызвать базу по рации в наушниках раздался щелчок Olympus: три мерных удара кайла по камню и его собственный голос, который он ещё не записывал.\n\nЭдвард спасся сам, но литоакустическая волна осталась в его памяти. Безмолвие никогда не наступит.",
		"carrier_freq": 14.0
	},
	"B": {
		"id": "B",
		"title": "ФИНАЛ B: СТРАЖ РЕЗОНАНСА",
		"subtitle": "«Стабилизация Анкера ценой собственной личности»",
		"quote": "«Звуки глубины один за другим прекращаются. Наступает тишина, которой не было восемьдесят лет».",
		"epilogue": "Эдвард замкнул три фазовых узла на частоте 11,4 Гц, подключив демпферы к собственному телу.\n\nРазрушительная гармоника 7,0 Гц угасла. Порода перестала стонать и осыпаться. Пальцы Эдварда покрылись тонкой коркой черного кристаллического базальта, пока тишина медленно заполняла залы Бедрока.\n\nПолое Ядро уснуло. Никто на поверхности так и не узнает, кто сохранил спокойствие литосферы Земли.",
		"carrier_freq": 11.4
	},
	"C": {
		"id": "C",
		"title": "ФИНАЛ C: ПЕТЛЯ СВЕРХОРИЗОНТА",
		"subtitle": "«Истинный финал — замыкание причинно-следственной петли 1989 года»",
		"quote": "«Не закрывайте колодец. Он слушает».",
		"epilogue": "Эдвард ввёл скрытые координаты станции «Мыс Молчаливый» в терминал Анкера и нажал передачу на частоте 11,4 Гц.\n\nСлова, которые он произнёс в микрофон: 'Не закрывайте колодец. Он слушает' — были теми самыми словами, которые советский радист майор Кравцов записал на бобинный магнитофон в октябре 1989 года.\n\nЭкспедиция 2025 года отправилась в путь именно ради этого сигнала. Причинно-следственная петля замкнулась навсегда.",
		"carrier_freq": 11.4
	}
}

func _ready() -> void:
	add_to_group("endings_director")
	layer = 120
	visible = false
	_build_ui()

func _build_ui() -> void:
	background_rect = ColorRect.new()
	background_rect.anchors_preset = Control.PRESET_FULL_RECT
	background_rect.color = Color(0.01, 0.012, 0.015, 0.95) # Deep black graphite
	add_child(background_rect)

	var center = CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	add_child(center)

	modal_panel = PanelContainer.new()
	modal_panel.custom_minimum_size = Vector2(760, 520)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.07, 1.0)
	style.border_color = Color(0.35, 0.38, 0.44, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 35
	style.content_margin_bottom = 35
	modal_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	modal_panel.add_child(vbox)

	title_label = Label.new()
	title_label.text = "ФИНАЛ HOLLOW CORE"
	title_label.add_theme_color_override("font_color", Color(0.92, 0.74, 0.35)) # Warm amber
	title_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "Эпилог"
	subtitle_label.add_theme_color_override("font_color", Color(0.60, 0.65, 0.72))
	subtitle_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(subtitle_label)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	quote_label = Label.new()
	quote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
	quote_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(quote_label)

	epilogue_label = Label.new()
	epilogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	epilogue_label.custom_minimum_size = Vector2(680, 200)
	epilogue_label.add_theme_color_override("font_color", Color(0.70, 0.74, 0.80))
	epilogue_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(epilogue_label)

	var h_space = Control.new()
	h_space.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(h_space)

	action_btn = Button.new()
	action_btn.text = "ЗАВЕРШИТЬ СЕАНС [ESC]"
	action_btn.custom_minimum_size = Vector2(220, 38)
	action_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	action_btn.pressed.connect(_on_close_pressed)
	vbox.add_child(action_btn)

	center.add_child(modal_panel)

	audio_player = AudioStreamPlayer.new()
	audio_player.name = "EndingAudioPlayer"
	audio_player.bus = "Master"
	add_child(audio_player)

static func evaluate_available_endings(state: Resource) -> Dictionary:
	var result = {
		"A": false,
		"B": false,
		"C": false
	}
	if state == null:
		return result

	# Ending A (Breakthrough): always accessible if lift path is open or surface determination >= 1
	result["A"] = true

	# Ending B (Resonance Guardian): requires resonance attunement >= 2 or anchor phase calibrated
	if state.resonance_attunement >= 2 or state.has_flag("anchor_phase_calibrated"):
		result["B"] = true

	# Ending C (Overhorizon Loop): requires Chain CH-05 complete (all 4 clues)
	if state.is_clue_chain_complete("CH-05"):
		result["C"] = true

	return result

func trigger_ending(ending_id: String) -> void:
	if not ENDING_DATA.has(ending_id):
		printerr("[EndingsDirector] Unknown ending: ", ending_id)
		return

	active_ending_id = ending_id
	var data = ENDING_DATA[ending_id]

	title_label.text = data["title"]
	subtitle_label.text = data["subtitle"]
	quote_label.text = data["quote"]
	epilogue_label.text = data["epilogue"]
	visible = true

	# Play carrier synth tone (11.4 Hz or 14.0 Hz)
	var audio_id = "AUD-20" if ending_id == "C" else ("AUD-14" if ending_id == "A" else "AUD-07")
	var stream = AudioStorySynthesizerClass.get_audiolog_stream(audio_id)
	if stream and audio_player:
		audio_player.stream = stream
		audio_player.play()

	# Record in story state
	var tree = get_tree() if is_inside_tree() else null
	if tree:
		var nm = tree.get_first_node_in_group("narrative_manager")
		if nm and nm.get("story_state"):
			nm.story_state.set_ending(ending_id)
			nm.save_state()

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_close_pressed() -> void:
	visible = false
	if audio_player:
		audio_player.stop()
	ending_completed.emit(active_ending_id)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			get_viewport().set_input_as_handled()
			_on_close_pressed()
