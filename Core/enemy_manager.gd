extends Node

## Глобальный менеджер врагов
## Управляет всеми врагами в игре, спавнерами и статистикой
## Добавьте в AutoLoad (Project Settings -> AutoLoad) как "EnemyManager"

signal enemy_spawned(enemy: BaseEnemy, enemy_data: EnemyData)
signal enemy_died(enemy: BaseEnemy)
signal all_enemies_cleared()

#region Конфигурация
@export var enemy_configs: Array[EnemyData] = []  ## Все доступные конфигурации врагов
@export var max_total_enemies: int = 10  ## Максимальное общее количество врагов
@export var enable_debug: bool = false  ## Режим отладки
#endregion

#region Внутренние переменные
var active_enemies: Dictionary = {}  ## {enemy_id: Array[BaseEnemy]}
var spawners: Array[EnemySpawner] = []  ## Все зарегистрированные спавнеры
var enemy_configs_dict: Dictionary = {}  ## {enemy_id: EnemyData}

# Статистика
var total_enemies_spawned: int = 0
var total_enemies_killed: int = 0
var enemies_by_type: Dictionary = {}  ## {enemy_id: {spawned: int, killed: int}}
#endregion

func _ready():
	# Индексируем конфигурации по ID
	for config in enemy_configs:
		if config:
			enemy_configs_dict[config.enemy_id] = config
			enemies_by_type[config.enemy_id] = {"spawned": 0, "killed": 0}

## Регистрация спавнера
func register_spawner(spawner: EnemySpawner):
	if spawner not in spawners:
		spawners.append(spawner)
		
		# Подключаем сигналы
		if not spawner.enemy_spawned.is_connected(_on_spawner_enemy_spawned):
			spawner.enemy_spawned.connect(_on_spawner_enemy_spawned)
		
		if enable_debug:
			print("[EnemyManager] Зарегистрирован спавнер: ", spawner.enemy_data.enemy_id)

## Удаление спавнера из регистрации
func unregister_spawner(spawner: EnemySpawner):
	if spawner in spawners:
		spawners.erase(spawner)
		
		if enable_debug:
			print("[EnemyManager] Спавнер удален: ", spawner.enemy_data.enemy_id)

## Создать врага по ID конфигурации
func spawn_enemy_by_id(enemy_id: String, position: Vector2, parent: Node = null) -> BaseEnemy:
	var config = enemy_configs_dict.get(enemy_id)
	if not config:
		push_error("[EnemyManager] Конфигурация не найдена: " + enemy_id)
		return null
	
	return spawn_enemy(config, position, parent)

## Создать врага по конфигурации
func spawn_enemy(config: EnemyData, position: Vector2, parent: Node = null) -> BaseEnemy:
	# Проверка лимита
	if get_total_active_count() >= max_total_enemies:
		if enable_debug:
			print("[EnemyManager] Достигнут лимит врагов: ", max_total_enemies)
		return null
	
	# Проверка лимита по типу
	var type_count = get_active_count(config.enemy_id)
	if type_count >= config.max_instances:
		if enable_debug:
			print("[EnemyManager] Достигнут лимит для типа ", config.enemy_id, ": ", config.max_instances)
		return null
	
	# Создаем врага
	var enemy: BaseEnemy = null
	
	if config.scene:
		enemy = config.scene.instantiate()
	else:
		enemy = BaseEnemy.new()
	
	enemy.enemy_data = config
	enemy.global_position = position
	
	# Добавляем в сцену
	if not parent:
		parent = get_tree().current_scene
	
	parent.add_child(enemy)
	
	# Регистрируем
	_register_enemy(enemy)
	
	if enable_debug:
		print("[EnemyManager] Создан враг: ", config.enemy_id, " в позиции ", position)
	
	return enemy

## Регистрация врага в менеджере
func _register_enemy(enemy: BaseEnemy):
	var enemy_id = enemy.enemy_data.enemy_id
	
	# Добавляем в список активных
	if not active_enemies.has(enemy_id):
		active_enemies[enemy_id] = []
	
	active_enemies[enemy_id].append(enemy)
	
	# Подключаем сигналы
	if not enemy.enemy_died.is_connected(_on_enemy_died):
		enemy.enemy_died.connect(_on_enemy_died)
	if not enemy.enemy_despawned.is_connected(_on_enemy_despawned):
		enemy.enemy_despawned.connect(_on_enemy_despawned)
	
	# Статистика
	total_enemies_spawned += 1
	if enemies_by_type.has(enemy_id):
		enemies_by_type[enemy_id]["spawned"] += 1
	
	enemy_spawned.emit(enemy, enemy.enemy_data)

## Удаление врага из регистрации
func _unregister_enemy(enemy: BaseEnemy):
	var enemy_id = enemy.enemy_data.enemy_id
	
	if active_enemies.has(enemy_id):
		active_enemies[enemy_id].erase(enemy)
		
		# Удаляем пустой массив
		if active_enemies[enemy_id].is_empty():
			active_enemies.erase(enemy_id)

## Обработка спавна от спавнера
func _on_spawner_enemy_spawned(enemy: BaseEnemy):
	_register_enemy(enemy)

## Обработка смерти врага
func _on_enemy_died(enemy: BaseEnemy):
	_unregister_enemy(enemy)
	
	# Статистика
	total_enemies_killed += 1
	var enemy_id = enemy.enemy_data.enemy_id
	if enemies_by_type.has(enemy_id):
		enemies_by_type[enemy_id]["killed"] += 1
	
	enemy_died.emit(enemy)
	
	if enable_debug:
		print("[EnemyManager] Враг убит: ", enemy_id, " | Всего убито: ", total_enemies_killed)
	
	# Проверка на очистку всех врагов
	if get_total_active_count() == 0:
		all_enemies_cleared.emit()

## Обработка исчезновения врага
func _on_enemy_despawned(enemy: BaseEnemy):
	_unregister_enemy(enemy)
	
	if enable_debug:
		print("[EnemyManager] Враг исчез: ", enemy.enemy_data.enemy_id)

## Получить количество активных врагов по типу
func get_active_count(enemy_id: String) -> int:
	if not active_enemies.has(enemy_id):
		return 0
	
	# Очищаем невалидные
	active_enemies[enemy_id] = active_enemies[enemy_id].filter(func(e): return is_instance_valid(e))
	
	return active_enemies[enemy_id].size()

## Получить общее количество активных врагов
func get_total_active_count() -> int:
	var total = 0
	for enemy_id in active_enemies.keys():
		total += get_active_count(enemy_id)
	return total

## Получить всех активных врагов
func get_all_active_enemies() -> Array[BaseEnemy]:
	var all: Array[BaseEnemy] = []
	for enemies in active_enemies.values():
		all.append_array(enemies)
	return all

## Получить активных врагов по типу
func get_enemies_by_type(enemy_id: String) -> Array[BaseEnemy]:
	if not active_enemies.has(enemy_id):
		return []
	
	return active_enemies[enemy_id].duplicate()

## Удалить всех врагов
func clear_all_enemies():
	for enemies in active_enemies.values():
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.queue_free()
	
	active_enemies.clear()
	all_enemies_cleared.emit()
	
	if enable_debug:
		print("[EnemyManager] Все враги удалены")

## Удалить врагов по типу
func clear_enemies_by_type(enemy_id: String):
	if not active_enemies.has(enemy_id):
		return
	
	for enemy in active_enemies[enemy_id]:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	active_enemies.erase(enemy_id)
	
	if enable_debug:
		print("[EnemyManager] Удалены враги типа: ", enemy_id)

## Заморозить всех врагов
func freeze_all_enemies(freeze: bool):
	for enemies in active_enemies.values():
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.is_active = not freeze

## Получить статистику
func get_statistics() -> Dictionary:
	return {
		"total_spawned": total_enemies_spawned,
		"total_killed": total_enemies_killed,
		"total_active": get_total_active_count(),
		"by_type": enemies_by_type.duplicate()
	}

## Сбросить статистику
func reset_statistics():
	total_enemies_spawned = 0
	total_enemies_killed = 0
	for type_id in enemies_by_type.keys():
		enemies_by_type[type_id] = {"spawned": 0, "killed": 0}

## Загрузить конфигурацию врага из файла
func load_enemy_config(path: String) -> EnemyData:
	var config = load(path) as EnemyData
	if config:
		enemy_configs.append(config)
		enemy_configs_dict[config.enemy_id] = config
		if not enemies_by_type.has(config.enemy_id):
			enemies_by_type[config.enemy_id] = {"spawned": 0, "killed": 0}
	return config

## Отладочная информация
func print_debug_info():
	print("\n=== Enemy Manager Debug Info ===")
	print("Total Active: ", get_total_active_count(), "/", max_total_enemies)
	print("Total Spawned: ", total_enemies_spawned)
	print("Total Killed: ", total_enemies_killed)
	print("\nBy Type:")
	for enemy_id in active_enemies.keys():
		print("  ", enemy_id, ": ", get_active_count(enemy_id))
	print("\nSpawners: ", spawners.size())
	print("================================\n")
