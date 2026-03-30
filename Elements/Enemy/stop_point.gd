## Зона спавна врагов — активируется когда игрок проходит знак (Sign).
## Спавн происходит со стороны знака, ближе к игроку.
extends Area2D

# Универсальные параметры зоны спавна
@export_group("Spawn Settings")
@export var enemy_scene_path: String = "res://Elements/Enemy/hedgehog.tscn"
@export var spawn_interval_min: float = 45.0  # Минимальный интервал спавна (секунды)
@export var spawn_interval_max: float = 120.0  # Максимальный интервал спавна (секунды)
@export var enemy_types_count: int = 2      # Сколько типов врагов доступно
## Дистанция от знака, в которой появляется враг (со стороны игрока).
@export var spawn_offset_from_sign: float = 200.0

# Адаптивный спавн (зависит от наполнения тачки)
@export_group("Adaptive Spawning")
@export var adaptive_spawning: bool = true  # Включить адаптивный спавн
@export var spawn_rate_multiplier_min: float = 0.7  # При пустой тачке
@export var spawn_rate_multiplier_max: float = 1.5  # При полной тачке

# Ограничение количества врагов
@export_group("Enemy Limits")
@export var max_enemies_per_zone: int = 1  # Максимум врагов от этой зоны одновременно
@export var max_total_enemies: int = 2  # Максимум врагов всего на уровне

@onready var lbl_visible = $Label
@onready var Animate_label = $AnimationPlayer
var enemy_scene = null
var spawn_timer: float = 0.0
var next_spawn_time: float = 0.0
var is_zone_active: bool = false
var player: Node2D = null
var spawned_enemies: Array = []  # Отслеживание врагов от этой зоны

## Инициализация: загружает сцену врага, находит игрока, устанавливает первый таймер.
func _ready():
	add_to_group("spawn_zones")
	
	# Загружаем сцену врага
	if enemy_scene_path != "":
		enemy_scene = load(enemy_scene_path)
	
	# Устанавливаем первый таймер
	_set_next_spawn_time()
	
	# Получаем ссылку на игрока
	if get_tree().get_first_node_in_group("player"):
		player = get_tree().get_first_node_in_group("player")

## Каждый кадр: проверяет позицию игрока и запускает спавн если зона активна.
func _process(delta: float):
	if not player or not is_instance_valid(player):
		return
	
	# Очищаем список от удалённых врагов
	_cleanup_spawned_enemies()
	
	# Проверяем активность зоны: игрок прошёл знак (Sign) по X
	var player_x = player.global_position.x
	is_zone_active = player_x >= global_position.x
	
	# Проверяем лимиты
	var total_enemies = get_tree().get_nodes_in_group("hedgehogs").size()
	var can_spawn = spawned_enemies.size() < max_enemies_per_zone and total_enemies < max_total_enemies
	
	# Таймер спавна работает только если зона активна и лимиты не превышены
	if is_zone_active and can_spawn:
		spawn_timer += delta
		
		if spawn_timer >= next_spawn_time:
			_spawn_enemy()
			spawn_timer = 0.0
			_set_next_spawn_time()

## Удаляет неактивных врагов из списка
func _cleanup_spawned_enemies():
	var valid_enemies = []
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			valid_enemies.append(enemy)
	spawned_enemies = valid_enemies

## Устанавливает следующий интервал спавна (адаптивный к наполнению тачки)
func _set_next_spawn_time():
	var base_interval = randf_range(spawn_interval_min, spawn_interval_max)
	
	if adaptive_spawning:
		# Чем полнее тачка, тем чаще появляются враги
		var fill_percent = Globals.get_wheelbarrow_percent()
		var multiplier = lerp(spawn_rate_multiplier_min, spawn_rate_multiplier_max, fill_percent)
		next_spawn_time = base_interval / multiplier
	else:
		next_spawn_time = base_interval

## Создаёт врага
func _spawn_enemy():
	if not enemy_scene or not player:
		return
	
	# Создаём врага
	var enemy = enemy_scene.instantiate()
	var elements_node = get_tree().root.get_node("Game/Elements")
	
	if not elements_node:
		return
	
	elements_node.add_child(enemy)
	spawned_enemies.append(enemy)  # Отслеживаем созданного врага
	
	# Инициализация в зависимости от типа врага
	if enemy.has_method("initialize_at"):
		var enemy_type = 0
		if enemy_types_count > 1:
			enemy_type = randi() % enemy_types_count
		enemy.initialize_at(enemy_type, player, global_position, spawn_offset_from_sign)
	elif enemy.has_method("initialize"):
		var enemy_type = 0
		if enemy_types_count > 1:
			enemy_type = randi() % enemy_types_count
		enemy.initialize(enemy_type, player)

## Показываем предупреждение когда игрок рядом
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		lbl_visible.show()
		Animate_label.play("Label_show")
## Скрываем предупреждение
func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		lbl_visible.hide()

## Останавливает спавн (например, при возврате домой)
func stop_spawning():
	spawn_timer = 0.0
	_set_next_spawn_time()
	# Удаляем всех врагов, созданных этой зоной
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	spawned_enemies.clear()

## Сброс зоны (для перезапуска уровня)
func reset_zone():
	spawn_timer = 0.0
	_set_next_spawn_time()
	spawned_enemies.clear()
