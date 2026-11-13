# scripts/narrative/quest_registry.gd
class_name QuestRegistry
extends RefCounted

## Canonical Quest Registry for Hollow Core spanning Acts 0 through V.
## Each quest has clear player motivations, structured objectives, dependencies,
## world consequences, and narrative rewards.

const QUESTS: Dictionary = {
	"Q00_CRASH_SURVIVAL": {
		"id": "Q00_CRASH_SURVIVAL",
		"act": 0,
		"title": "Катастрофа «ТяжМаш-4»",
		"description": "Прийти в себя среди обломков разбившейся клети. Найти аварийный латунный фонарь и кирку геолога в завале штольни.",
		"directive": "Найти аварийный фонарь и кирку геолога среди обломков",
		"sub_objectives": {
			"lantern": { "text": "Подобрать экспедиционный фонарь", "done": false },
			"pickaxe": { "text": "Извлечь кирку геолога из завала", "done": false }
		},
		"required_flags": [],
		"completion_flag": "starting_gear_recovered",
		"next_quest": "Q01_APPROACH_STATION4"
	},
	"Q01_APPROACH_STATION4": {
		"id": "Q01_APPROACH_STATION4",
		"act": 1,
		"title": "Ледниковый разлом",
		"description": "Спуститься по наклонной штольне в толще мерзлоты к гермопорталу Шлюзовой Станции 4 (горизонт 1420м).",
		"directive": "Пройти по ледниковой штольне к Шлюзовой Станции 4 (1420м)",
		"sub_objectives": {
			"enter_station": { "text": "Войти в зал Шлюзовой Станции 4", "done": false }
		},
		"required_flags": ["starting_gear_recovered"],
		"completion_flag": "station4_entered",
		"next_quest": "Q02_SURVEYOR_WORKSTATION"
	},
	"Q02_SURVEYOR_WORKSTATION": {
		"id": "Q02_SURVEYOR_WORKSTATION",
		"act": 1,
		"title": "Журнал маркшейдера",
		"description": "Обследовать рабочий стол маркшейдера Прохорова и прочесть вахтенный журнал 1894 года (DOC-01).",
		"directive": "Осмотреть рабочий стол маркшейдера и прочесть Журнал (DOC-01)",
		"sub_objectives": {
			"read_d01": { "text": "Изучить полевой журнал шурфа №4 (DOC-01)", "done": false }
		},
		"required_flags": ["station4_entered"],
		"completion_flag": "document_d01_read",
		"next_quest": "Q03_DRAINAGE_RESTORATION"
	},
	"Q03_DRAINAGE_RESTORATION": {
		"id": "Q03_DRAINAGE_RESTORATION",
		"act": 1,
		"title": "Осушение зумпфа",
		"description": "Повернуть главный чугунный маховик системы водоотлива, чтобы осушить затопленный нижний зумпф (SEC-01).",
		"directive": "Повернуть чугунный вентиль, чтобы осушить нижний коллектор",
		"sub_objectives": {
			"turn_valve": { "text": "Повернуть маховик водоотлива Шлюза 4", "done": false }
		},
		"required_flags": ["document_d01_read"],
		"completion_flag": "sump_drained",
		"next_quest": "Q04_ECHO_SHAFT_DESCENT"
	},
	"Q04_ECHO_SHAFT_DESCENT": {
		"id": "Q04_ECHO_SHAFT_DESCENT",
		"act": 1,
		"title": "Шурф Эха и Заброшенный Лагерь",
		"description": "Преодолеть 22-метровый колодец Шурфа Эха, найти заброшенный спасательный лагерь и спуститься в осушенный зумпф.",
		"directive": "Спуститься в Шурф Эха и обследовать заброшенный лагерь",
		"sub_objectives": {
			"reach_camp": { "text": "Обнаружить безопасный приют в гроте лагеря", "done": false },
			"descend_sump": { "text": "Спуститься на дно осушенного зумпфа", "done": false }
		},
		"required_flags": ["sump_drained"],
		"completion_flag": "echo_shaft_explored",
		"next_quest": "Q05_SYNDICATE_SAFE"
	},
	"Q05_SYNDICATE_SAFE": {
		"id": "Q05_SYNDICATE_SAFE",
		"act": 1,
		"title": "Тайна затонувшего сейфа EE-06",
		"description": "Вскрыть сейф обер-бухгалтера Синдиката 104 шифром 1924 года, забрать кварцевый резонатор и кассету AUD-07.",
		"directive": "Вскрыть сейф EE-06 (код 1924) и забрать кассету AUD-07",
		"sub_objectives": {
			"unlock_safe": { "text": "Подобрать шифр 1924 на дисковом замке сейфа", "done": false },
			"take_resonator": { "text": "Извлечь кварцевый резонатор и AUD-07", "done": false }
		},
		"required_flags": ["echo_shaft_explored"],
		"completion_flag": "ee06_safe_unlocked",
		"next_quest": "Q06_ABYSS_CALL"
	},
	"Q06_ABYSS_CALL": {
		"id": "Q06_ABYSS_CALL",
		"act": 1,
		"title": "Резонанс из Бездны (11,4 Гц)",
		"description": "Зафиксировать глубинную несущую частоту 11,4 Гц. Увидеть силуэт Наблюдателя в тумане каньона и подготовиться к переходу на горизонт Синдиката.",
		"directive": "РЕЗОНАНС: Зафиксирован сигнал 11,4 Гц из Бездны. Следовать в глубину.",
		"sub_objectives": {
			"witness_signal": { "text": "Зарегистрировать приём сигнала 11,4 Гц", "done": false }
		},
		"required_flags": ["ee06_safe_unlocked"],
		"completion_flag": "signal_11_4_received",
		"next_quest": "Q07_SUBSTATION_REPAIR"
	},
	"Q07_SUBSTATION_REPAIR": {
		"id": "Q07_SUBSTATION_REPAIR",
		"act": 2,
		"title": "Энергия Подстанции №12",
		"description": "Восстановить распределительный щит и запустить шахтную узкоколейку Синдиката 104.",
		"directive": "Подать напряжение на подстанцию горизонта -1000м",
		"sub_objectives": {
			"repair_transformer": { "text": "Заменить медные предохранители трансформатора", "done": false },
			"start_winch": { "text": "Запустить лебёдку грузового подъёмника", "done": false }
		},
		"required_flags": ["signal_11_4_received"],
		"completion_flag": "substation_online",
		"next_quest": "Q08_SYNDICATE_CONSPIRACY"
	},
	"Q08_SYNDICATE_CONSPIRACY": {
		"id": "Q08_SYNDICATE_CONSPIRACY",
		"act": 2,
		"title": "Тайные протоколы Консорциума",
		"description": "Собрать архивные улики DOC-02, DOC-12 и AUD-15, подтверждающие умышленное сокрытие акустической угрозы руководством шахт.",
		"directive": "Собрать улики заговора Синдиката 104 (Цепочка CH-01)",
		"sub_objectives": {
			"find_protocol": { "text": "Обнаружить протокол заседания правления 1923 года", "done": false }
		},
		"required_flags": ["substation_online"],
		"completion_flag": "syndicate_conspiracy_revealed",
		"next_quest": "Q09_KELLER_SUSPENSION"
	},
	"Q09_KELLER_SUSPENSION": {
		"id": "Q09_KELLER_SUSPENSION",
		"act": 3,
		"title": "Тросы Висячего Города",
		"description": "Преодолеть колодец Келлер-Вайс по подвесным мостам и канатам, добраться до ратуши магистрата.",
		"directive": "Проникнуть в висячий город Келлер-Вайс (горизонт -1800м)",
		"sub_objectives": {
			"cross_chasm": { "text": "Отрегулировать натяжитель несущего троса", "done": false },
			"reach_townhall": { "text": "Войти в ратушу Келлер-Вайса", "done": false }
		},
		"required_flags": ["syndicate_conspiracy_revealed"],
		"completion_flag": "keller_weiss_entered",
		"next_quest": "Q10_THE_GREAT_HARMONIZATION"
	},
	"Q10_THE_GREAT_HARMONIZATION": {
		"id": "Q10_THE_GREAT_HARMONIZATION",
		"act": 3,
		"title": "Трагедия сорока органов",
		"description": "Восстановить ход событий Великой Гармонизации 1946 года, изучив документы DOC-05 и запись фонограммы AUD-05.",
		"directive": "Раскрыть причину гибели Келлер-Вайса в концертном зале (Цепочка CH-02)",
		"sub_objectives": {
			"listen_organ_tape": { "text": "Прослушать фонограмму репетиции сорока органов AUD-05", "done": false }
		},
		"required_flags": ["keller_weiss_entered"],
		"completion_flag": "harmonization_truth_uncovered",
		"next_quest": "Q11_GEOTHERMAL_IGNITION"
	},
	"Q11_GEOTHERMAL_IGNITION": {
		"id": "Q11_GEOTHERMAL_IGNITION",
		"act": 4,
		"title": "Геотермальное пламя Нексус-Осы",
		"description": "Открыть паровой клапан высокого давления и запустить генератор AEG 1932 года над лавовой кальдерой.",
		"directive": "Запустить геотермальную турбину в Черном Горниле Нексус-Осы",
		"sub_objectives": {
			"open_steam_valve": { "text": "Сбросить давление в обводной магистрали", "done": false },
			"spool_turbine": { "text": "Вывести ротор турбины на рабочие обороты", "done": false }
		},
		"required_flags": ["harmonization_truth_uncovered"],
		"completion_flag": "nexus_turbine_started",
		"next_quest": "Q12_ELEONORA_MIRAGE"
	},
	"Q12_ELEONORA_MIRAGE": {
		"id": "Q12_ELEONORA_MIRAGE",
		"act": 4,
		"title": "Сектор EE-27: Элеонора",
		"description": "Следовать за литоакустическим отражением сестры в фантомную комнату EE-27. Прослушать диалог AUD-19.",
		"directive": "Исследовать литоакустический мираж EE-27 и найти блокнот Элеоноры",
		"sub_objectives": {
			"inspect_room": { "text": "Осмотреть письменный стол и блокнот DOC-15", "done": false },
			"hear_echo": { "text": "Услышать голос сестры на несущей 11,4 Гц", "done": false }
		},
		"required_flags": ["nexus_turbine_started"],
		"completion_flag": "eleonora_truth_understood",
		"next_quest": "Q13_PHASE_CALIBRATION"
	},
	"Q13_PHASE_CALIBRATION": {
		"id": "Q13_PHASE_CALIBRATION",
		"act": 5,
		"title": "Калибровка Анкера Зодчих",
		"description": "Спуститься на абсолютное дно Пустоты Бедрока (Y = -52) и настроить три фазовых узла на точную частоту 11,4 Гц.",
		"directive": "Откалибровать три фазовых узла Анкера в Пустоте Бедрока",
		"sub_objectives": {
			"align_node_alpha": { "text": "Синхронизировать фазовый узел Альфа", "done": false },
			"align_node_beta": { "text": "Синхронизировать фазовый узел Бета", "done": false },
			"align_node_gamma": { "text": "Синхронизировать фазовый узел Гамма", "done": false }
		},
		"required_flags": ["eleonora_truth_understood"],
		"completion_flag": "anchor_phase_calibrated",
		"next_quest": "Q14_THE_FINAL_DECISION"
	},
	"Q14_THE_FINAL_DECISION": {
		"id": "Q14_THE_FINAL_DECISION",
		"act": 5,
		"title": "Выбор Горизонта",
		"description": "Принять окончательное решение у терминала управления Резонансным Анкером.",
		"directive": "Совершить выбор у алтаря Анкера Бедрока (Финал A, B или C)",
		"sub_objectives": {
			"trigger_climax": { "text": "Активировать терминал Анкера", "done": false }
		},
		"required_flags": ["anchor_phase_calibrated"],
		"completion_flag": "game_climax_resolved",
		"next_quest": ""
	}
}

static func get_quest(quest_id: String) -> Dictionary:
	return QUESTS.get(quest_id, {})

static func get_all_quest_ids() -> Array:
	return QUESTS.keys()

static func get_act_quests(act: int) -> Array:
	var res: Array = []
	for q_id in QUESTS:
		if QUESTS[q_id].get("act", -1) == act:
			res.append(QUESTS[q_id])
	return res
