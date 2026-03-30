extends Resource
class_name EnemyData

## Конфигурация врага - используется для создания различных типов врагов
## Все параметры настраиваются через Inspector или код

#region Основная информация
@export_group("Основная информация")
@export var enemy_id: String = "enemy_base"  ## Уникальный идентификатор врага
@export var enemy_name: String = "Враг"  ## Название врага
@export_multiline var description: String = ""  ## Описание поведения
#endregion

#region Внешний вид
@export_group("Внешний вид")
@export var scene: PackedScene  ## Сцена врага (опционально)
@export var sprite_frames: SpriteFrames  ## Анимации врага
@export var default_animation: String = "idle"  ## Анимация по умолчанию
@export var scale: Vector2 = Vector2.ONE  ## Масштаб врага
#endregion

#region Физические параметры
@export_group("Физические параметры")
@export var speed: float = 50.0  ## Базовая скорость передвижения
@export var speed_variance: Vector2 = Vector2(0.8, 1.2)  ## Разброс скорости (мин, макс)
@export var has_gravity: bool = true  ## Использовать гравитацию
@export var collision_layer: int = 2  ## Слой коллизий
@export var collision_mask: int = 1  ## Маска коллизий
#endregion

#region Боевые характеристики
@export_group("Боевые характеристики")
@export var health: float = 100.0  ## Здоровье врага
@export var is_immortal: bool = false  ## Враг неубиваемый

## Тип урона
enum DamageType {
	NONE,           ## Не наносит урон
	SINGLE,         ## Одноразовый урон
	CONTINUOUS,     ## Постоянный урон
	ON_COLLISION    ## Урон при столкновении
}

@export var damage_type: DamageType = DamageType.SINGLE
@export var damage_player: float = 5.0  ## Урон игроку (абсолютный или %)
@export var damage_wheelbarrow: float = 0.0  ## Урон тачке
@export var damage_is_percent: bool = false  ## Урон в процентах от здоровья
@export var damage_interval: float = 1.0  ## Интервал урона (для CONTINUOUS)
#endregion

#region Кража воды
@export_group("Кража воды")
@export var can_steal_water: bool = false  ## Может красть воду
@export var water_steal_amount: float = 5.0  ## Количество украденной воды
@export var water_steal_is_percent: bool = false  ## Кража в процентах
@export var water_steal_interval: float = 2.0  ## Интервал кражи
@export var flee_if_no_water: bool = true  ## Убегает, если воды нет
#endregion

#region AI и поведение
@export_group("AI и поведение")

## Тип AI
enum AIType {
	IDLE,           ## Стоит на месте (территориальный)
	PATROL,         ## Патрулирует область
	FOLLOW_PLAYER,  ## Преследует игрока
	FLEE_PLAYER,    ## Убегает от игрока
	THIEF,          ## Воришка (держится на дистанции)
	AGGRESSIVE,     ## Агрессор (прилипает к игроку)
	PROJECTILE,     ## Снаряд — падает по прямой (дождевые капли и т.п.)
}

@export var ai_type: AIType = AIType.IDLE
@export var aggression: Vector2 = Vector2(0.7, 1.3)  ## Разброс агрессии
@export var target_distance: float = 60.0  ## Целевая дистанция до игрока
@export var attack_distance: float = 30.0  ## Дистанция атаки
@export var flee_distance: float = 40.0  ## Дистанция отступления
@export var detection_radius: float = 300.0  ## Радиус обнаружения игрока
@export var patrol_radius: float = 100.0  ## Радиус патрулирования
#endregion

#region Условия появления
@export_group("Условия появления")

## Тип триггера появления
enum SpawnTrigger {
	MANUAL,          ## Ручное создание
	TIMER,           ## По таймеру
	AREA_ENTER,      ## При входе в область
	PLAYER_ACTION,   ## При действии игрока
	CONDITION        ## При условии
}

@export var spawn_trigger: SpawnTrigger = SpawnTrigger.MANUAL
@export var spawn_delay_min: float = 30.0  ## Минимальная задержка спавна (сек)
@export var spawn_delay_max: float = 180.0  ## Максимальная задержка спавна (сек)
@export var spawn_probability: float = 1.0  ## Вероятность спавна (0.0-1.0)
@export var spawn_position_offset: Vector2 = Vector2(-150, 0)  ## Смещение от игрока
@export var max_instances: int = 1  ## Максимальное количество одновременно
#endregion

#region Условия исчезновения
@export_group("Условия исчезновения")
@export var idle_timeout: float = 10.0  ## Время бездействия до исчезновения
@export var despawn_on_player_stop: bool = true  ## Исчезает при остановке игрока
@export var despawn_on_empty_water: bool = true  ## Исчезает при пустой тачке
@export var despawn_on_home_return: bool = true  ## Исчезает при возврате домой
@export var despawn_distance: float = 200.0  ## Дистанция для автоудаления
#endregion

#region Модификаторы от улучшений
@export_group("Модификаторы")
@export var affected_by_gloves: bool = true  ## Снижение урона от перчаток
@export var affected_by_boots: bool = true  ## Снижение урона от сапог
@export var affected_by_cloak: bool = true  ## Снижение урона от плаща
@export var affected_by_wheelbarrow: bool = true  ## Снижение урона от супертачки
@export var damage_reduction_per_upgrade: float = 0.15  ## Снижение урона за улучшение (15%)
#endregion

#region Звуки и эффекты
@export_group("Звуки и эффекты")
@export var spawn_sound: AudioStream  ## Звук появления
@export var attack_sound: AudioStream  ## Звук атаки
@export var death_sound: AudioStream  ## Звук смерти
@export var idle_sound: AudioStream  ## Фоновый звук
@export var spawn_effect: PackedScene  ## Эффект появления
@export var death_effect: PackedScene  ## Эффект смерти
#endregion

## Получить случайную скорость с учетом вариативности
func get_random_speed() -> float:
	return speed * randf_range(speed_variance.x, speed_variance.y)

## Получить случайную агрессию
func get_random_aggression() -> float:
	return randf_range(aggression.x, aggression.y)

## Получить случайную задержку спавна
func get_random_spawn_delay() -> float:
	return randf_range(spawn_delay_min, spawn_delay_max)

## Проверить, должен ли враг появиться
func should_spawn() -> bool:
	return randf() < spawn_probability

## Получить финальный урон с учетом улучшений игрока
func get_final_damage(player_upgrades: Dictionary) -> float:
	var final_damage = damage_player
	var reduction = 0.0
	
	if affected_by_gloves and player_upgrades.get("gloves", 0) > 0:
		reduction += player_upgrades.gloves * damage_reduction_per_upgrade
	if affected_by_boots and player_upgrades.get("boots", 0) > 0:
		reduction += player_upgrades.boots * damage_reduction_per_upgrade
	if affected_by_cloak and player_upgrades.get("cloak", 0) > 0:
		reduction += player_upgrades.cloak * damage_reduction_per_upgrade
	if affected_by_wheelbarrow and player_upgrades.get("wheelbarrow", 0) > 0:
		reduction += player_upgrades.wheelbarrow * damage_reduction_per_upgrade
	
	# Ограничиваем максимальное снижение 80%
	reduction = min(reduction, 0.8)
	return final_damage * (1.0 - reduction)
