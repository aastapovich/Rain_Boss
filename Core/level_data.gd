## Данные одного уровня — подгружаются через LevelRegistry.
## Определяют, какая сцена загружается в слот LevelContent,
## флаги систем (облака, дождь) и стартовую позицию героя.
class_name LevelData
extends Resource

## Уникальный id уровня (совпадает с Globals.level).
@export var level_id: int = 1

## Человекочитаемое название (для отладки и UI).
@export var level_name: String = "Level 1"

## Сцена с окружением уровня (фон, пропсы, триггеры, финишная зона).
## Загружается в слот LevelContent в Game.tscn.
@export var level_scene: PackedScene

## Включить систему облаков (CloudLayer) для этого уровня.
@export var has_cloud_system: bool = true

## Включить систему дождевых капель (RainManager) для этого уровня.
@export var has_rain_system: bool = true

## Стартовая (или дефолтная) позиция героя на этом уровне.
@export var player_start_position: Vector2 = Vector2(-50, 596)

## Сколько воды нужно сдать для победы.
@export var max_exit_point: int = 30

## Описание уровня для экрана вступления (пустая строка = не показывать).
@export_multiline var level_description: String = ""
