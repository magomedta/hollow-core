# HOLLOW CORE — ТЕХНИЧЕСКИЙ ДИЗАЙН НАРРАТИВНЫХ СИСТЕМ (GODOT 4.7+)
*Архитектура кода, синглтоны, сериализация состояния, интерактивные ноды и инжекция POI*
*Версия: 1.0 // Спецификация вселенной Hollow Core (Godot 4.7+)*

---

## 1. АРХИТЕКТУРА НАРРАТИВНОГО СТЕКА В ДВИЖКЕ GODOT 4.7+

Нарративная система Hollow Core построена на принципах слабой связанности (Decoupled Event-Driven Architecture) через шину сигналов и строго типизированные ресурсы.

```
                      +-------------------------+
                      |   EventBus (Autoload)   |
                      +------------+------------+
                                   |
       +---------------------------+---------------------------+
       |                           |                           |
       v                           v                           v
+------------------+     +-------------------+     +--------------------+
| NarrativeManager |     |   SanityManager   |     |    SoundManager    |
| (Сюжет и Акты)   |     | (Индекс саспенса) |     | (3D Аудио и Эхо)   |
+--------+---------+     +-------------------+     +--------------------+
         |
         +──► StoryStateResource (Сериализация в user://saves/story_state.tres)
         |
         +──► InteractiveProp (Базовый класс улик, документов и вентилей)
```

---

## 2. КЛАСС StoryStateResource (ХРАНИЛИЩЕ СОСТОЯНИЯ МИРА)

Файл: `res://scripts/resources/story_state_resource.gd`

```gdscript
class_name StoryStateResource
extends Resource

@export var current_act: int = 0
@export var player_sanity: float = 1.0
@export var dread_meter: float = 0.0

# Прогресс исследования
@export var discovered_secrets: Dictionary = {} # secret_id: bool
@export var collected_documents: Array[String] = [] # doc_id
@export var played_audiologs: Array[String] = [] # audio_id

# Флаги глобальных мировых событий
@export var world_flags: Dictionary = {
	"sluices_drained": false,
	"nexus_turbine_online": false,
	"keller_bridge_collapsed": false,
	"resonance_anchor_awakened": false,
	"watcher_physical_manifest": false
}

# Репутация / параметры концовок
@export var attunement_points: int = 0 # Очки сонастройки с Ядром
@export var surface_yearning: int = 0   # Очки стремления на Поверхность
```

---

## 3. СИНГЛТОН NarrativeManager (МЕНЕДЖЕР СЮЖЕТА)

Файл: `res://scripts/autoloads/narrative_manager.gd`

```gdscript
extends Node

signal act_changed(new_act: int)
signal document_inspected(doc_id: String, text_content: String)
signal audiolog_started(audio_id: String, stream: AudioStream)
signal secret_unlocked(secret_id: String)
signal world_flag_changed(flag_name: String, new_value: bool)

@export var story_state: StoryStateResource

const SAVE_PATH: String = "user://saves/story_state.tres"

func _ready() -> void:
	load_or_create_state()

func trigger_world_event(flag_name: String) -> void:
	if story_state.world_flags.has(flag_name):
		story_state.world_flags[flag_name] = true
		world_flag_changed.emit(flag_name, true)
		save_state()
		print("[NarrativeManager] World event triggered: ", flag_name)

func advance_act(target_act: int) -> void:
	if target_act > story_state.current_act:
		story_state.current_act = target_act
		act_changed.emit(target_act)
		save_state()

func register_secret(secret_id: String) -> void:
	if not story_state.discovered_secrets.get(secret_id, false):
		story_state.discovered_secrets[secret_id] = true
		secret_unlocked.emit(secret_id)
		save_state()

func save_state() -> void:
	ResourceSaver.save(story_state, SAVE_PATH)

func load_or_create_state() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		story_state = ResourceLoader.load(SAVE_PATH) as StoryStateResource
	else:
		story_state = StoryStateResource.new()
		save_state()
```

---

## 4. БАЗОВЫЙ КЛАСС ИНТЕРАКТИВНОГО ОБЪЕКТА (InteractiveProp)

Файл: `res://scripts/interactables/interactive_prop.gd`

```gdscript
class_name InteractiveProp
extends Area3D

@export var prompt_message: String = "Осмотреть [E]"
@export var inspect_sound: AudioStream
@export var is_one_shot: bool = true

var is_interacted: bool = false

func _ready() -> void:
	collision_layer = 8 # Слой Interactable
	collision_mask = 0

func interact(player: CharacterBody3D) -> void:
	if is_one_shot and is_interacted:
		return
	is_interacted = true
	_execute_interaction(player)

func _execute_interaction(_player: CharacterBody3D) -> void:
	# Переопределяется в подклассах (записка, вентиль, аудиовалик)
	pass
```

---

## 5. ИНЖЕКЦИЯ СЮЖЕТНЫХ СТРУКТУР В ВОКСЕЛЬНЫЙ МИР (POI INJECTION)

Чтобы сюжетные города, форпосты и секреты гармонично сочетались с процедурной воксельной генерацией в `voxel_world.gd`:
1. **Координатная маска POI**: Для каждого ключевого объекта (Келлер-Вайс, Дамба Каскада, Шурф 2х2) задается ограничивающий параллелепипед (`AABB`).
2. **Подавление процедурного шума**: При генерации чанков внутри `AABB` процедурный шум плотности заменяется на чтение готовой воксельной матрицы структуры (`PackedByteArray`).
3. **Бесшовный блендинг**: На границе `AABB` (полоса шириной в 3 блока) применяется линейная интерполяция между готовой архитектурой и природной карстовой пещерой, исключая резкие срезы скалы.
