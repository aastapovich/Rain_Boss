## Таблица прогрессии уровней скилла героя.
## Индекс = hero_skill_level (1-based; индекс 0 — заглушка).
##
## Использование:
##   var data := SkillConfig.get_level(hero_skill_level)
##   speed_norm = data.get("speed_norm", 80.0)
class_name SkillConfig
extends RefCounted

## Возвращает словарь характеристик для заданного уровня скилла.
## Уровни выше MAX возвращают данные MAX-уровня.
static func get_level(level: int) -> Dictionary:
	var table: Array = [
		{},  # 0 — заглушка (не используется)
		{    # 1 — базовый
			"speed_norm": 80.0,
			"speed_shift": 120.0,
			"health_max": 100,
			"damage_multiplier": 1.0,
			"sprint_duration": 3.5,
			"sprint_cooldown": 4.0,
		},
		{    # 2
			"speed_norm": 85.0,
			"speed_shift": 128.0,
			"health_max": 110,
			"damage_multiplier": 0.95,
			"sprint_duration": 3.8,
			"sprint_cooldown": 3.8,
		},
		{    # 3
			"speed_norm": 90.0,
			"speed_shift": 136.0,
			"health_max": 120,
			"damage_multiplier": 0.90,
			"sprint_duration": 4.2,
			"sprint_cooldown": 3.5,
		},
		{    # 4
			"speed_norm": 95.0,
			"speed_shift": 144.0,
			"health_max": 130,
			"damage_multiplier": 0.85,
			"sprint_duration": 4.5,
			"sprint_cooldown": 3.2,
		},
		{    # 5
			"speed_norm": 100.0,
			"speed_shift": 150.0,
			"health_max": 140,
			"damage_multiplier": 0.80,
			"sprint_duration": 5.0,
			"sprint_cooldown": 3.0,
		},
	]
	var idx := clampi(level, 1, table.size() - 1)
	return table[idx]

## Максимальный доступный уровень скилла.
static func max_level() -> int:
	return 5
