## Таблица уровней защитного снаряжения героя.
## Каждый тип предмета имеет уровни от 0 (нет) до MAX.
##
## Использование:
##   var data := ProtectionConfig.get_item("boots", boots_level)
##   mud_slow_resistance = data.get("mud_slow_resist", 0.0)
class_name ProtectionConfig
extends RefCounted

## Возвращает словарь бонусов для предмета заданного уровня.
## item_type: "boots" | "cloak" | "gloves"
## Уровень 0 = предмета нет, каждый следующий — улучшение.
static func get_item(item_type: String, level: int) -> Dictionary:
	match item_type:
		"boots":
			return _get_boots(level)
		"cloak":
			return _get_cloak(level)
		"gloves":
			return _get_gloves(level)
	return {}

# ─── Сапоги: снижают замедление от луж ───────────────────────────────────────
static func _get_boots(level: int) -> Dictionary:
	var table: Array = [
		{  # 0 — нет сапог
			"mud_slow_resist": 0.0,
			"immune_to_puddles": false,
		},
		{  # 1 — простые (−20% замедления)
			"mud_slow_resist": 0.20,
			"immune_to_puddles": false,
		},
		{  # 2 — хорошие (−50%)
			"mud_slow_resist": 0.50,
			"immune_to_puddles": false,
		},
		{  # 3 — прочные (−80%)
			"mud_slow_resist": 0.80,
			"immune_to_puddles": false,
		},
		{  # 4 — водонепроницаемые (полный иммунитет)
			"mud_slow_resist": 1.0,
			"immune_to_puddles": true,
		},
	]
	return table[clampi(level, 0, table.size() - 1)]

# ─── Плащ: снижает урон от дождя ─────────────────────────────────────────────
static func _get_cloak(level: int) -> Dictionary:
	var table: Array = [
		{  # 0 — нет плаща
			"rain_damage_reduction": 0.0,
			"immune_to_rain": false,
		},
		{  # 1 — тонкий (−20%)
			"rain_damage_reduction": 0.20,
			"immune_to_rain": false,
		},
		{  # 2 — плотный (−45%)
			"rain_damage_reduction": 0.45,
			"immune_to_rain": false,
		},
		{  # 3 — армированный (−70%)
			"rain_damage_reduction": 0.70,
			"immune_to_rain": false,
		},
		{  # 4 — непромокаемый (полный иммунитет)
			"rain_damage_reduction": 1.0,
			"immune_to_rain": true,
		},
	]
	return table[clampi(level, 0, table.size() - 1)]

# ─── Перчатки: снижают урон от животных ──────────────────────────────────────
static func _get_gloves(level: int) -> Dictionary:
	var table: Array = [
		{  # 0 — нет
			"animal_damage_reduction": 0.0,
			"immune_to_animals": false,
		},
		{  # 1 (−20%)
			"animal_damage_reduction": 0.20,
			"immune_to_animals": false,
		},
		{  # 2 (−45%)
			"animal_damage_reduction": 0.45,
			"immune_to_animals": false,
		},
		{  # 3 (−70%)
			"animal_damage_reduction": 0.70,
			"immune_to_animals": false,
		},
		{  # 4 — полный иммунитет
			"animal_damage_reduction": 1.0,
			"immune_to_animals": true,
		},
	]
	return table[clampi(level, 0, table.size() - 1)]

## Максимальный уровень для любого предмета.
static func max_level() -> int:
	return 4
