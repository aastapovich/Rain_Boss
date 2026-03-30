## Таблица уровней инвентарных предметов.
## Уровень 0 = базовый предмет без улучшений.
##
## Использование:
##   var data := InventoryConfig.get_item("wheelbarrow", wheelbarrow_level)
##   wheelbarrow_capacity = data.get("capacity", 100)
class_name InventoryConfig
extends RefCounted

## Возвращает словарь параметров предмета заданного уровня.
## item_type: "wheelbarrow" | "pickaxe" | "shovel"
static func get_item(item_type: String, level: int) -> Dictionary:
	match item_type:
		"wheelbarrow":
			return _get_wheelbarrow(level)
		"pickaxe":
			return _get_pickaxe(level)
		"shovel":
			return _get_shovel(level)
	return {}

# ─── Тачка ────────────────────────────────────────────────────────────────────
static func _get_wheelbarrow(level: int) -> Dictionary:
	var table: Array = [
		{  # 0 — стандартная
			"capacity": 50,
			"durability": 60,
			"resistance": 0,
		},
		{  # 1 — укреплённая
			"capacity": 55,
			"durability": 80,
			"resistance": 10,
		},
		{  # 2 — большая
			"capacity": 70,
			"durability": 100,
			"resistance": 25,
		},
		{  # 3 — прочная большая
			"capacity": 85,
			"durability": 130,
			"resistance": 40,
		},
		{  # 4 — суперпрочная
			"capacity": 100,
			"durability": 160,
			"resistance": 60,
		},
	]
	return table[clampi(level, 0, table.size() - 1)]

# ─── Кирка (геолог / шахтёр) ──────────────────────────────────────────────────
static func _get_pickaxe(level: int) -> Dictionary:
	var table: Array = [
		{  # 0 — ржавая
			"mining_speed": 0.8,
			"durability": 40,
		},
		{  # 1 — стандартная
			"mining_speed": 1.0,
			"durability": 60,
		},
		{  # 2 — закалённая
			"mining_speed": 1.4,
			"durability": 90,
		},
		{  # 3 — алмазная
			"mining_speed": 2.0,
			"durability": 130,
		},
	]
	return table[clampi(level, 0, table.size() - 1)]

# ─── Лопата ───────────────────────────────────────────────────────────────────
static func _get_shovel(level: int) -> Dictionary:
	var table: Array = [
		{  # 0 — деревянная
			"dig_speed": 0.8,
			"durability": 30,
		},
		{  # 1 — стальная
			"dig_speed": 1.0,
			"durability": 50,
		},
		{  # 2 — усиленная
			"dig_speed": 1.5,
			"durability": 80,
		},
		{  # 3 — механическая
			"dig_speed": 2.2,
			"durability": 120,
		},
	]
	return table[clampi(level, 0, table.size() - 1)]
