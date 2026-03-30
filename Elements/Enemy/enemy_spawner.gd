extends Node2D
class_name EnemySpawner

## Спавнер врагов - управляет появлением врагов по условиям
## Можно использовать как отдельную ноду или через EnemyManager

signal enemy_spawned(enemy: BaseEnemy)
signal spawn_conditions_met(enemy_data: EnemyData)

@export var enemy_data: EnemyData  ## Конфигурация врага для спавна
@export var enabled: bool = true  ## Спавнер активен
@export var spawn_parent: NodePath  ## Родитель для созданных врагов (опционально)
@export var trigger_area: Area2D  ## Область триггера (для AREA_ENTER)

var spawn_timer: float = 0.0
var active_enemies: Array[BaseEnemy] = []
var player: CharacterBody2D = null
var is_triggered: bool = false

func _ready():
	if not enemy_data:
		push_warning("EnemySpawner без EnemyData!")
		enabled = false
		return
	
	# Поиск игрока
	player = get_tree().get_first_node_in_group("player")
	
	# Настройка триггерной области
	if trigger_area:
		if not trigger_area.body_entered.is_connected(_on_trigger_area_entered):
			trigger_area.body_entered.connect(_on_trigger_area_entered)
		if not trigger_area.body_exited.is_connected(_on_trigger_area_exited):
			trigger_area.body_exited.connect(_on_trigger_area_exited)
	
	# Установка начального таймера
	if enemy_data.spawn_trigger == EnemyData.SpawnTrigger.TIMER:
		spawn_timer = enemy_data.get_random_spawn_delay()

func _process(delta: float):
	if not enabled or not enemy_data:
		return
	
	# Очистка неактивных врагов
	_cleanup_inactive_enemies()
	
	# Обработка спавна в зависимости от триггера
	match enemy_data.spawn_trigger:
		EnemyData.SpawnTrigger.TIMER:
			_process_timer_spawn(delta)
		EnemyData.SpawnTrigger.CONDITION:
			_process_condition_spawn()

## Спавн по таймеру
func _process_timer_spawn(delta: float):
	if active_enemies.size() >= enemy_data.max_instances:
		return
	
	spawn_timer -= delta
	if spawn_timer <= 0:
		if _check_spawn_conditions():
			spawn_enemy()
		# Сброс таймера
		spawn_timer = enemy_data.get_random_spawn_delay()

## Спавн по условию
func _process_condition_spawn():
	if active_enemies.size() >= enemy_data.max_instances:
		return
	
	if _check_spawn_conditions():
		spawn_enemy()

## Проверка всех условий для спавна
func _check_spawn_conditions() -> bool:
	# Проверка вероятности
	if not enemy_data.should_spawn():
		return false
	
	# Проверка триггера области
	if enemy_data.spawn_trigger == EnemyData.SpawnTrigger.AREA_ENTER:
		if not is_triggered:
			return false
	
	# Проверка наличия игрока
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return false
	
	# Проверка воды в тачке (если враг крадет воду)
	if enemy_data.can_steal_water and enemy_data.despawn_on_empty_water:
		if player.has_method("get_water_amount"):
			if player.get_water_amount() <= 0:
				return false
	
	# Проверка максимального количества
	if active_enemies.size() >= enemy_data.max_instances:
		return false
	
	return true

## Создание врага
func spawn_enemy() -> BaseEnemy:
	var enemy: BaseEnemy = null
	
	# Создаем врага из сцены или базового класса
	if enemy_data.scene:
		enemy = enemy_data.scene.instantiate()
	else:
		enemy = BaseEnemy.new()
	
	# Устанавливаем данные
	enemy.enemy_data = enemy_data
	
	# Добавляем в сцену
	var parent = get_node_or_null(spawn_parent) if spawn_parent else get_parent()
	if not parent:
		parent = self
	
	parent.add_child(enemy)
	
	# Устанавливаем позицию
	if player:
		enemy.global_position = player.global_position + enemy_data.spawn_position_offset
	else:
		enemy.global_position = global_position
	
	# Инициализируем врага
	if enemy.has_method("initialize"):
		enemy.initialize(0, player)  # 0 - тип по умолчанию
	
	# Подключаем сигналы
	if not enemy.enemy_died.is_connected(_on_enemy_died):
		enemy.enemy_died.connect(_on_enemy_died)
	if not enemy.enemy_despawned.is_connected(_on_enemy_despawned):
		enemy.enemy_despawned.connect(_on_enemy_despawned)
	
	# Добавляем в список активных
	active_enemies.append(enemy)
	
	enemy_spawned.emit(enemy)
	
	return enemy

## Очистка массива от удаленных врагов
func _cleanup_inactive_enemies():
	active_enemies = active_enemies.filter(func(e): return is_instance_valid(e))

## Обработка смерти врага
func _on_enemy_died(enemy: BaseEnemy):
	if enemy in active_enemies:
		active_enemies.erase(enemy)

## Обработка исчезновения врага
func _on_enemy_despawned(enemy: BaseEnemy):
	if enemy in active_enemies:
		active_enemies.erase(enemy)

## Вход в триггерную область
func _on_trigger_area_entered(body: Node):
	if body.is_in_group("player"):
		is_triggered = true
		spawn_conditions_met.emit(enemy_data)
		
		# Для триггера AREA_ENTER спавним сразу
		if enemy_data.spawn_trigger == EnemyData.SpawnTrigger.AREA_ENTER:
			if _check_spawn_conditions():
				spawn_enemy()

## Выход из триггерной области
func _on_trigger_area_exited(body: Node):
	if body.is_in_group("player"):
		is_triggered = false

## Принудительный спавн врага (игнорируя условия)
func force_spawn() -> BaseEnemy:
	if active_enemies.size() >= enemy_data.max_instances:
		return null
	return spawn_enemy()

## Удалить всех активных врагов этого спавнера
func despawn_all():
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.despawn()
	active_enemies.clear()

## Получить количество активных врагов
func get_active_count() -> int:
	_cleanup_inactive_enemies()
	return active_enemies.size()
