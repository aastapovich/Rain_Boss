## Реестр уровней — Автозагрузка "LevelRegistry".
## Хранит путь к LevelData-ресурсу для каждого level_id.
## Добавьте новый уровень одной строкой в _registry.
extends Node

## Словарь: level_id (int) → путь к .tres файлу LevelData.
const _registry: Dictionary = {
	1: "res://Levels/level_data_01.tres",
	2: "res://Levels/level_data_02.tres",
}

## Вернуть LevelData для заданного level_id.
## Если уровень не найден — вернуть данные последнего зарегистрированного.
func get_level(level_id: int) -> LevelData:
	var path: String = ""
	if _registry.has(level_id):
		path = _registry[level_id]
	else:
		# Цикличный переход: повторяем последний известный уровень
		var max_id: int = _registry.keys().max()
		path = _registry[max_id]
		push_warning("LevelRegistry: level_id %d не найден, используем %d" % [level_id, max_id])
	return load(path) as LevelData

## Есть ли зарегистрированный уровень с данным id.
func has_level(level_id: int) -> bool:
	return _registry.has(level_id)

## Максимальный зарегистрированный level_id.
func max_level() -> int:
	return _registry.keys().max()
