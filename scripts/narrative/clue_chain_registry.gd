# scripts/narrative/clue_chain_registry.gd
class_name ClueChainRegistry
extends RefCounted

## Canonical Registry of the 5 Clue Investigation Chains (CH-01 to CH-05).
## Coordinates progressive player deductions, linking physical documents,
## audio logs, and easter eggs into cohesive narrative revelations.

const CHAINS: Dictionary = {
	"CH-01": {
		"id": "CH-01",
		"title": "Заговор Синдиката 104 и сокрытие резонанса",
		"clues": [
			{ "source_id": "DOC-02", "name": "Предписание №14-Б «О режиме тишины» (1922 г.)" },
			{ "source_id": "AUD-15", "name": "Секретный протокол о кессонной болезни (1923 г.)" },
			{ "source_id": "DOC-04", "name": "Справка лазарета о серной интоксикации (1944 г.)" },
			{ "source_id": "EE-06",  "name": "Вскрытый сейф обер-бухгалтера Синдиката 104" }
		],
		"deduction": "Катастрофа не была внезапной: жадность консорциума привела к сознательному сокрытию акустических жертв ради экспорта руды.",
		"reward_stat": "surface_determination",
		"reward_points": 1
	},
	"CH-02": {
		"id": "CH-02",
		"title": "Трагедия Великой Гармонизации Келлер-Вайс",
		"clues": [
			{ "source_id": "DOC-05", "name": "План Великой Гармонизации (1946 г.)" },
			{ "source_id": "AUD-02", "name": "Авария парового шпинделя от гармоники 7,0 Гц (1922 г.)" },
			{ "source_id": "AUD-05", "name": "Запись репетиции сорока паровых органов (1946 г.)" },
			{ "source_id": "DOC-11", "name": "Дневник смотрителя об опустевшем висячем городе (1947 г.)" }
		],
		"deduction": "Висячий Город Келлер-Вайс погубила не потусторонняя нечисть, а фатальная инженерная ошибка фазировки акустических органов на разрушительной частоте 7,0 Гц.",
		"reward_stat": "resonance_attunement",
		"reward_points": 1
	},
	"CH-03": {
		"id": "CH-03",
		"title": "Литоакустический след Элеоноры Вейн",
		"clues": [
			{ "source_id": "DOC-07", "name": "Справка ФБР по инциденту в Карлсбаде (2019 г.)" },
			{ "source_id": "AUD-08", "name": "Сейсмический профиль Элеоноры перед обвалом (2019 г.)" },
			{ "source_id": "DOC-15", "name": "Блокнот сестры с древней акустической формулой (2018 г.)" },
			{ "source_id": "EE-20",  "name": "Литоакустический фантом Элеоноры в секторе EE-27" }
		],
		"deduction": "Элеонора физически погибла в Карлсбаде, но глубинная базальтовая плита сохранила её сознание. Сектор EE-27 — это мираж её памяти.",
		"reward_stat": "resonance_attunement",
		"reward_points": 1
	},
	"CH-04": {
		"id": "CH-04",
		"title": "Природа и повадки Наблюдателя",
		"clues": [
			{ "source_id": "DOC-09", "name": "Памятка горноспасателю о четвёртом ударе (1935 г.)" },
			{ "source_id": "DOC-19", "name": "Протокол допроса дезертира о белом двойнике (1946 г.)" },
			{ "source_id": "EE-04",  "name": "Светящийся след ладони на монолите" },
			{ "source_id": "AUD-03", "name": "Дневник Смирнова о камне, помнящем мысли (1944 г.)" }
		],
		"deduction": "Наблюдатель — не боевой монстр и не враг. Это бесплотное акустическое зеркало разума исследователя, отраженное пьезо-кристаллами базальта.",
		"reward_stat": "causal_loop_insight",
		"reward_points": 1
	},
	"CH-05": {
		"id": "CH-05",
		"title": "Петля Сверхоризонта (Секрет 1989 года)",
		"clues": [
			{ "source_id": "DOC-06", "name": "Телеграмма станции «Мыс Молчаливый» (Октябрь 1989 г.)" },
			{ "source_id": "AUD-07", "name": "Радиоперехват фразы «Не закрывайте колодец...» (1989 г.)" },
			{ "source_id": "DOC-10", "name": "Древняя схема фазовых регуляторов Анкера" },
			{ "source_id": "AUD-20", "name": "Финальная передача Эдварда на частоте 11,4 Гц" }
		],
		"deduction": "Экспедиция «Сверхоризонт» 2025 года была направлена в глубину на сигнал, который отправил сам Эдвард Вейн из будущего. Причинно-следственная петля замкнута.",
		"reward_stat": "causal_loop_insight",
		"reward_points": 2
	}
}

static func get_chain(chain_id: String) -> Dictionary:
	return CHAINS.get(chain_id, {})

static func get_all_chain_ids() -> Array:
	return CHAINS.keys()
