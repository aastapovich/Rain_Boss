extends CharacterBody2D
class_name BaseEnemy

## Базовый класс для всех врагов
## Использует EnemyData для конфигурации
## Переопределяйте методы _custom_behavior() для специфического поведения

signal enemy_died(enemy: BaseEnemy)
signal enemy_despawned(enemy: BaseEnemy)
signal player_damaged(damage: float, enemy: BaseEnemy)
signal water_stolen(amount: float, enemy: BaseEnemy)

# ── Машина состояний ───────────────────────────────────────────────────────────────────
enum State {
	IDLE,     ## Стоит, ждёт — по таймауту despawn
	APPROACH, ## Движется к/от игрока согласно ai_type
	ATTACK,   ## Атакует или ворует
	FLEE,     ## Убегает от игрока
	DEAD,     ## Мёртв — финальное состояние
}
var state: State = State.IDLE

#region Основные переменные
@export var enemy_data: EnemyData  ## Конфигурация врага

var player: CharacterBody2D = null  ## Ссылка на игрока
var current_health: float = 0.0  ## Текущее здоровье
var current_speed: float = 0.0  ## Текущая скорость
var current_aggression: float = 1.0  ## Текущая агрессия

# Таймеры
var idle_timer: float = 0.0  ## Таймер бездействия
var damage_timer: float = 0.0  ## Таймер нанесения урона
var steal_timer: float = 0.0  ## Таймер кражи воды
var attack_cooldown: float = 0.0  ## Время до следующей атаки

var can_attack: bool = true  ## Может атаковать
var player_last_direction: float = 0.0  ## Последнее направление игрока

# Компоненты
var sprite: AnimatedSprite2D = null
var collision: CollisionShape2D = null
var audio_player: AudioStreamPlayer2D = null

var gravity: float = 980.0
#endregion

# ── FSM ───────────────────────────────────────────────────────────────────────
func _change_state(new_state: State) -> void:
	if state == new_state:
		return
	_exit_state(state)
	state = new_state
	_enter_state(state)

func _enter_state(s: State) -> void:
	match s:
		State.IDLE:
			velocity.x = 0
			if idle_timer <= 0:
				idle_timer = 0.001  # запускаем таймер бездействия
		State.APPROACH, State.ATTACK, State.FLEE:
			idle_timer = 0.0
		State.DEAD:
			velocity = Vector2.ZERO
			set_physics_process(false)

func _exit_state(_s: State) -> void:
	pass

## Определяет переходы состояний на основе ai_type и дистанции до игрока.
func _decide_state() -> void:
	if not player or not is_instance_valid(player):
		_find_player()
		_change_state(State.IDLE)
		return
	var dist = global_position.distance_to(player.global_position)
	match enemy_data.ai_type:
		EnemyData.AIType.IDLE:
			_change_state(State.IDLE)
		EnemyData.AIType.FOLLOW_PLAYER:
			if dist <= enemy_data.attack_distance:
				_change_state(State.ATTACK)
			elif dist > enemy_data.target_distance:
				_change_state(State.APPROACH)
			else:
				_change_state(State.IDLE)
		EnemyData.AIType.FLEE_PLAYER:
			if dist < enemy_data.flee_distance:
				_change_state(State.FLEE)
			else:
				_change_state(State.IDLE)
		EnemyData.AIType.THIEF:
			var target_dist = enemy_data.target_distance / current_aggression
			if dist <= enemy_data.attack_distance:
				_change_state(State.ATTACK)
			elif dist > target_dist + 20:
				_change_state(State.APPROACH)
			elif dist < target_dist - 20:
				_change_state(State.FLEE)
			else:
				_change_state(State.IDLE)
		EnemyData.AIType.AGGRESSIVE:
			if state == State.FLEE:
				# Продолжаем бежать, пока игрок движется в нашу сторону
				if not _check_player_turning_towards():
					if dist <= enemy_data.attack_distance:
						_change_state(State.ATTACK)
					elif dist > enemy_data.target_distance:
						_change_state(State.APPROACH)
					else:
						_change_state(State.IDLE)
				# иначе — не меняем состояние, продолжаем FLEE
			elif _check_player_turning_towards():
				_change_state(State.FLEE)
			elif dist <= enemy_data.attack_distance:
				_change_state(State.ATTACK)
			elif dist > enemy_data.target_distance:
				_change_state(State.APPROACH)
			else:
				_change_state(State.IDLE)
		EnemyData.AIType.PATROL:
			if dist <= enemy_data.attack_distance:
				_change_state(State.ATTACK)
			else:
				_change_state(State.APPROACH)

func _process_idle(_delta: float) -> void:
	velocity.x = 0
	if idle_timer > 0 and idle_timer >= enemy_data.idle_timeout:
		despawn()

func _process_approach(_delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
	var dir = sign(player.global_position.x - global_position.x)
	match enemy_data.ai_type:
		EnemyData.AIType.PATROL:
			if abs(velocity.x) < 10:
				velocity.x = current_speed * (1.0 if randf() > 0.5 else -1.0)
		EnemyData.AIType.AGGRESSIVE:
			velocity.x = dir * current_speed * 1.2
		_:
			velocity.x = dir * current_speed

func _process_attack(_delta: float) -> void:
	match enemy_data.ai_type:
		EnemyData.AIType.AGGRESSIVE:
			var dir = sign(player.global_position.x - global_position.x)
			velocity.x = dir * current_speed * 0.5
		_:
			velocity.x = 0
	_handle_attack()

func _process_flee(_delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
	var dir = sign(player.global_position.x - global_position.x)
	velocity.x = -dir * current_speed * 1.5

func _ready():
	if not enemy_data:
		push_error("Enemy spawned without EnemyData!")
		queue_free()
		return
	
	# Устанавливаем начальные параметры из data
	_initialize_from_data()
	
	# Настраиваем компоненты
	_setup_components()
	
	# Поиск игрока
	_find_player()
	
	# Добавляем в группу врагов
	add_to_group("enemies")
	add_to_group(enemy_data.enemy_id)
	
	# Звук и эффект появления
	_play_spawn_effects()
	
	# Обновляем гравитацию
	gravity = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

## Инициализация параметров из EnemyData
func _initialize_from_data():
	current_health = enemy_data.health
	current_speed = enemy_data.get_random_speed()
	current_aggression = enemy_data.get_random_aggression()
	scale = enemy_data.scale
	
	# Настройка коллизий
	collision_layer = enemy_data.collision_layer
	collision_mask = enemy_data.collision_mask

## Настройка компонентов (спрайт, коллизия, аудио)
func _setup_components():
	# Ищем или создаем компоненты
	sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		# Если у ноды уже есть sprite_frames (из tscn), запускаем анимацию
		if sprite.sprite_frames:
			var anim := enemy_data.default_animation if enemy_data.default_animation else "walk"
			if sprite.sprite_frames.has_animation(anim):
				sprite.play(anim)
		# Иначе — берём из конфига
		elif enemy_data.sprite_frames:
			sprite.sprite_frames = enemy_data.sprite_frames
			sprite.play(enemy_data.default_animation)
	elif enemy_data.sprite_frames:
		sprite = AnimatedSprite2D.new()
		sprite.name = "AnimatedSprite2D"
		add_child(sprite)
		sprite.sprite_frames = enemy_data.sprite_frames
		sprite.play(enemy_data.default_animation)
	
	collision = get_node_or_null("CollisionShape2D")
	if not collision:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		add_child(collision)
	
	audio_player = get_node_or_null("AudioStreamPlayer2D")
	if not audio_player:
		audio_player = AudioStreamPlayer2D.new()
		audio_player.name = "AudioStreamPlayer2D"
		add_child(audio_player)

## Поиск игрока в сцене
func _find_player():
	if not player:
		player = get_tree().get_first_node_in_group("player")

## Звук и эффект появления
func _play_spawn_effects():
	if enemy_data.spawn_sound and audio_player:
		audio_player.stream = enemy_data.spawn_sound
		audio_player.play()
	
	if enemy_data.spawn_effect:
		var effect = enemy_data.spawn_effect.instantiate()
		get_parent().add_child(effect)
		effect.global_position = global_position

func _physics_process(delta: float) -> void:
	if state == State.DEAD or not enemy_data:
		return
	if enemy_data.has_gravity:
		velocity.y += gravity * delta
	_update_timers(delta)
	if _should_despawn():
		despawn()
		return
	_decide_state()
	match state:
		State.IDLE:     _process_idle(delta)
		State.APPROACH: _process_approach(delta)
		State.ATTACK:   _process_attack(delta)
		State.FLEE:     _process_flee(delta)
	_custom_behavior(delta)
	move_and_slide()
	_update_animation()

## Обновление всех таймеров
func _update_timers(delta: float):
	if idle_timer > 0:
		idle_timer += delta
	
	if attack_cooldown > 0:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			can_attack = true
	
	if damage_timer > 0:
		damage_timer -= delta
	
	if steal_timer > 0:
		steal_timer -= delta

## Проверка, повернулся ли игрок в сторону врага
func _check_player_turning_towards() -> bool:
	if not player:
		return false
	var direction_to_enemy = sign(global_position.x - player.global_position.x)
	var player_direction = sign(player.velocity.x) if player.velocity.x != 0 else player_last_direction
	player_last_direction = player_direction
	return direction_to_enemy == player_direction

## Обработка атаки (урон и кража)
func _handle_attack():
	if not can_attack:
		return
	
	# Нанесение урона
	if enemy_data.damage_type != EnemyData.DamageType.NONE:
		if enemy_data.damage_type == EnemyData.DamageType.CONTINUOUS:
			if damage_timer <= 0:
				_deal_damage()
				damage_timer = enemy_data.damage_interval
		else:
			_deal_damage()
			can_attack = false
			attack_cooldown = enemy_data.damage_interval
	
	# Кража воды
	if enemy_data.can_steal_water and steal_timer <= 0:
		_steal_water()
		steal_timer = enemy_data.water_steal_interval

## Нанесение урона игроку
func _deal_damage():
	if not player or not player.has_method("take_damage"):
		return
	
	var upgrades = _get_player_upgrades()
	var final_damage = enemy_data.get_final_damage(upgrades)
	
	if enemy_data.damage_is_percent:
		# Процентный урон от максимального здоровья
		final_damage = player.max_health * (final_damage / 100.0)
	
	player.take_damage(final_damage)
	player_damaged.emit(final_damage, self)
	
	# Звук атаки
	if enemy_data.attack_sound and audio_player:
		audio_player.stream = enemy_data.attack_sound
		audio_player.play()

## Кража воды из тачки
func _steal_water():
	# Предполагается, что у игрока есть метод steal_water
	if not player or not player.has_method("get_water_amount"):
		return
	
	var water_amount = player.get_water_amount()
	
	if water_amount <= 0:
		if enemy_data.flee_if_no_water:
			despawn()
		return
	
	var steal_amount = enemy_data.water_steal_amount
	if enemy_data.water_steal_is_percent:
		steal_amount = water_amount * (steal_amount / 100.0)
	
	if player.has_method("steal_water"):
		var inv: Node = null
		if get_tree():
			inv = get_tree().get_root().get_node_or_null("Game/Progression/InventorySystem")
		var steal_int := int(steal_amount)
		if inv and inv.has_method("apply_wheelbarrow_damage"):
			inv.apply_wheelbarrow_damage(player, steal_int, "steal")
			water_stolen.emit(float(steal_int), self)
		elif player.has_method("steal_water"):
			player.steal_water(steal_amount)
			water_stolen.emit(steal_amount, self)

## Получение улучшений игрока
func _get_player_upgrades() -> Dictionary:
	if not player:
		return {}
	
	return {
		"gloves": player.get("gloves_level") if player.get("gloves_level") != null else 0,
		"boots": player.get("boots_level") if player.get("boots_level") != null else 0,
		"cloak": player.get("cloak_level") if player.get("cloak_level") != null else 0,
		"wheelbarrow": player.get("wheelbarrow_level") if player.get("wheelbarrow_level") != null else 0,
	}

## Проверка условий для despawn
func _should_despawn() -> bool:
	# Проверка дистанции
	if global_position.x < -enemy_data.despawn_distance or \
	   global_position.x > 3200 + enemy_data.despawn_distance:
		return true
	
	# Проверка остановки игрока
	if enemy_data.despawn_on_player_stop and player:
		if player.velocity.length() < 5.0 and idle_timer > enemy_data.idle_timeout:
			return true
	
	# Проверка пустой тачки
	if enemy_data.despawn_on_empty_water and player:
		if player.has_method("get_water_amount") and player.get_water_amount() <= 0:
			if enemy_data.flee_if_no_water:
				return true
	
	return false

## Получение урона врагом
func take_damage(amount: float):
	if enemy_data.is_immortal:
		return
	
	current_health -= amount
	
	if current_health <= 0:
		die()

## Смерть врага
func die():
	_change_state(State.DEAD)
	if enemy_data.death_sound and audio_player:
		audio_player.stream = enemy_data.death_sound
		audio_player.play()
	if enemy_data.death_effect:
		var effect = enemy_data.death_effect.instantiate()
		get_parent().add_child(effect)
		effect.global_position = global_position
	enemy_died.emit(self)
	queue_free()

## Исчезновение врага
func despawn():
	_change_state(State.DEAD)
	enemy_despawned.emit(self)
	queue_free()

## Обновление анимации
func _update_animation():
	if not sprite:
		return
	
	# Отражение спрайта по позиции игрока (надёжнее чем по velocity)
	if player and is_instance_valid(player):
		if state == State.FLEE:
			# Убегаем — смотрим ПРОЧЬ от игрока
			sprite.flip_h = player.global_position.x > global_position.x
		else:
			# Преследуем/атакуем — смотрим НА игрока
			sprite.flip_h = player.global_position.x < global_position.x
	elif velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false

	# Выбор анимации
	if sprite.sprite_frames:
		if velocity.x != 0:
			if sprite.sprite_frames.has_animation("walk"):
				sprite.play("walk")
		else:
			if sprite.sprite_frames.has_animation("idle"):
				sprite.play("idle")
			elif sprite.sprite_frames.has_animation("walk"):
				sprite.play("walk")

## Переопределяйте этот метод для специфического поведения врага
func _custom_behavior(_delta: float) -> void:
	pass
