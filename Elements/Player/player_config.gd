## Конфигурация героя — Resource, создаётся один раз как .tres в редакторе.
## Разные типы героев = разные .tres файлы, единственный скрипт player_base.gd.
class_name PlayerConfig
extends Resource

# --- Скорость ---
## Базовая скорость ходьбы
@export var speed_norm: float = 80.0
## Скорость бега (Shift)
@export var speed_shift: float = 120.0

# --- Иммунитеты ---
## Не получает урона от капель дождя (water, gold, live)
@export var immune_to_rain: bool = false
## Лужа не замедляет игрока
@export var immune_to_puddles: bool = false
## Урон от животных (ёжики и др.) не применяется
@export var immune_to_animals: bool = false
## Не получает урона от молний
@export var immune_to_lightning: bool = false

# --- Здоровье ---
## Множитель входящего урона (< 1.0 = получает меньше урона)
@export_range(0.1, 2.0, 0.05) var damage_multiplier: float = 1.0

# --- Спринт ---
## Длительность спринта (сек)
@export var sprint_duration: float = 3.5
## Кулдаун спринта (сек)
@export var sprint_cooldown: float = 4.0
