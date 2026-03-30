## Базовый класс игрока — универсальный скелет.
## Все переменные прогресса объявлены явно.
## Данные загружаются из SkillConfig, InventoryConfig, ProtectionConfig.
## PlayerConfig (.tres) используется как legacy-fallback на период миграции.
class_name PlayerBase
extends CharacterBody2D

# ══════════════════════════════════════════════════════════════════════════════
# ─── Action FSM ───────────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
enum State {
	MOVE,      ## Обычное движение
	UNLOAD,    ## Выгрузка тачки — игрок заморожен
	USE_TOOL,  ## Работа инструментом на месте (кирка, лопата, ключ…)
	DAMAGED,   ## Получение удара — i-frames + вспышка
}
var state: State = State.MOVE

# ══════════════════════════════════════════════════════════════════════════════
# ─── Skill FSM ────────────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
enum SkillState {
	LOCKED,    ## Навык не разблокирован
	IDLE,      ## Доступен, не активен
	ACTIVE,    ## Активен прямо сейчас
	COOLDOWN,  ## На перезарядке
}
var skill_state: SkillState = SkillState.IDLE
var active_skill_id: String = ""
var _skill_timer: float          = 0.0
var _skill_cooldown: float       = 0.0
var _skill_cooldown_timer: float = 0.0

## Значения до активации навыка — восстанавливаются при деактивации
var _pre_skill_speed_norm:        float = 0.0
var _pre_skill_speed_shift:       float = 0.0
var _pre_skill_damage_mult:       float = 0.0
var _pre_skill_immune_rain:       bool  = false
var _pre_skill_immune_puddles:    bool  = false
var _pre_skill_immune_animals:    bool  = false
var _pre_skill_immune_lightning:  bool  = false

# ══════════════════════════════════════════════════════════════════════════════
# ─── Узлы сцены ───────────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
## Ссылки на тачку — заполняются InventorySystem через on_wheelbarrow_ready().
# Player no longer stores wheelbarrow nodes; InventorySystem manages equipment.
# Deprecated fields removed.
@onready var gravity             = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var player_anim = $Anim_Player
var unload_ctrl = null
var movement_ctrl = null
var _inv: Node = null  ## Кэш ссылки на InventorySystem (lazy init).
const MovementControllerScript = preload("res://Elements/Player/Player_00/movement_controller.gd")

# ══════════════════════════════════════════════════════════════════════════════
# ─── Прогресс героя (синхронизируется с Globals при старте) ───────────────────
# ══════════════════════════════════════════════════════════════════════════════
## Уровень скилла — определяет базовые характеристики (таблица SkillConfig)
var hero_skill_level: int = 1
## Накопленный опыт на текущем уровне скилла
var skill_xp: int = 0

# ─── Экипировка (уровни определяют бонусы через ProtectionConfig/InventoryConfig)
var boots_level:       int = 0  ## Защита от луж
var cloak_level:       int = 0  ## Защита от дождя
var gloves_level:      int = 0  ## Защита от животных
var wheelbarrow_level: int = 0  ## Улучшения тачки

## Разблокированные навыки: ["invisible", "super", …]
var unlocked_skills: Array = []
## Полученные инструменты: ["pickaxe", "shovel", …]
var owned_tools: Array = []

# ══════════════════════════════════════════════════════════════════════════════
# ─── Capability-флаги (задаются уровнем/сценой через данные уровня) ────────────
# ══════════════════════════════════════════════════════════════════════════════
var can_push_wheelbarrow: bool = true   ## Толкать тачку
var can_mine:             bool = false  ## Добывать породу киркой
var can_dig:              bool = false  ## Копать лопатой
var can_open_channel:     bool = false  ## Открывать канал

# ══════════════════════════════════════════════════════════════════════════════
# ─── Базовые характеристики (загружаются из SkillConfig по hero_skill_level) ──
# ══════════════════════════════════════════════════════════════════════════════
var speed_norm:        float = 80.0
var speed_shift:       float = 120.0
var speed:             float = 80.0
var health_max:        int   = 100   ## Максимальное здоровье на данном уровне скилла
var damage_multiplier: float = 1.0   ## Множитель входящего урона (< 1.0 = прочнее)
var sprint_duration:   float = 3.5
var sprint_cooldown:   float = 4.0

# ══════════════════════════════════════════════════════════════════════════════
# ─── Защита (загружается из ProtectionConfig по уровням экипировки) ────────────
# ══════════════════════════════════════════════════════════════════════════════
var rain_damage_reduction:      float = 0.0  ## 0.0–1.0: сколько % урона от дождя срезано
var animal_damage_reduction:    float = 0.0  ## % урона от животных срезан
var lightning_damage_reduction: float = 0.0  ## % урона от молний срезан
var mud_slow_resistance:        float = 0.0  ## 0.0–1.0: насколько ближе замедл. к 1.0
var immune_to_rain:      bool = false
var immune_to_puddles:   bool = false
var immune_to_animals:   bool = false
var immune_to_lightning: bool = false

# ══════════════════════════════════════════════════════════════════════════════
# ─── Инвентарь / Тачка (загружается из InventoryConfig по wheelbarrow_level) ──
# ══════════════════════════════════════════════════════════════════════════════
var wheelbarrow_capacity:   int = 100  ## Максимальный объём (л.)
var wheelbarrow_durability: int = 100  ## Прочность тачки
var wheelbarrow_resistance: int = 0    ## Снижение урона по тачке

# ══════════════════════════════════════════════════════════════════════════════
# ─── Флаги активных эффектов (читаются врагами и окружающей средой) ────────────
# ══════════════════════════════════════════════════════════════════════════════
var is_invisible:    bool = false  ## Невидим для врагов
var is_super_active: bool = false  ## Активен суперрежим

# ══════════════════════════════════════════════════════════════════════════════
# ─── Runtime-движение ─────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
var direction:          float = 0.0
var previous_direction: float = 0.0
var exit_point:         int   = 0
var max_exit_point:     int   = 30
var puddle_slow_multiplier: float = 1.0
var is_in_puddle:       bool  = false
var sprint_active:      bool  = false
var sprint_time_left:   float = 0.0
var sprint_cooldown_left: float = 0.0

## Длительность неуязвимости после удара
var damage_invuln_duration: float = 0.8
var _damage_invuln_timer:   float = 0.0

# ──────────────────────────────────────────────────────────────────────────────
@export_group("Hand Alignment")
@export var hand_align_right: float = 0.0
@export var hand_align_left:  float = 0.0

@export_group("Splash Offset")
@export var splash_offset: Vector2 = Vector2.ZERO

var _facing_left:   bool  = false
var _sprite_base_x: float = 0.0

## Максимальное снижение скорости при полной тачке (настраивается).
var wb_max_penalty: float = 20.0
## Текущее вычитаемое из скорости: Globals.get_wheelbarrow_percent() * wb_max_penalty.
## Обновляется по сигналу Events.wheelbarrow_changed.
var wb_speed_penalty: float = 0.0

## PlayerConfig (.tres) — legacy-fallback, используется пока идёт миграция на Config-таблицы.
@export var config: PlayerConfig

# ══════════════════════════════════════════════════════════════════════════════
# ─── Инициализация ────────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	add_to_group("player")
	_load_progress_from_globals()
	_apply_config()
	_apply_skill_level()
	_apply_equipment()
	if player_anim:
		_sprite_base_x = player_anim.position.x
		player_anim.visible = true
	movement_ctrl = MovementControllerScript.new()
	movement_ctrl.setup(self)
	_setup_unload_controller()
	Events.wheelbarrow_changed.connect(_on_wb_changed)

## Синхронизирует переменные прогресса из Globals.
func _load_progress_from_globals() -> void:
	hero_skill_level  = XpManager.level_for_xp(Globals.total_xp)
	skill_xp          = Globals.skill_xp
	boots_level       = Globals.boots_level
	cloak_level       = Globals.cloak_level
	gloves_level      = Globals.gloves_level
	wheelbarrow_level = Globals.wheelbarrow_level
	unlocked_skills   = Globals.unlocked_skills.duplicate()
	owned_tools       = Globals.owned_tools.duplicate()

## Применяет legacy PlayerConfig (.tres) как fallback.
func _apply_config() -> void:
	if not config:
		return
	speed_norm          = config.speed_norm
	speed_shift         = config.speed_shift
	speed               = config.speed_norm
	sprint_duration     = config.sprint_duration
	sprint_cooldown     = config.sprint_cooldown
	immune_to_rain      = config.immune_to_rain
	immune_to_puddles   = config.immune_to_puddles
	immune_to_animals   = config.immune_to_animals
	immune_to_lightning = config.immune_to_lightning
	damage_multiplier   = config.damage_multiplier

## Применяет характеристики из SkillConfig по текущему уровню скилла.
## Перезаписывает значения legacy-конфига.
func _apply_skill_level() -> void:
	var data: Dictionary = SkillConfig.get_level(hero_skill_level)
	if data.is_empty():
		return
	speed_norm        = data.get("speed_norm",        speed_norm)
	speed_shift       = data.get("speed_shift",       speed_shift)
	speed             = speed_norm
	health_max        = data.get("health_max",        health_max)
	damage_multiplier = data.get("damage_multiplier", damage_multiplier)
	sprint_duration   = data.get("sprint_duration",   sprint_duration)
	sprint_cooldown   = data.get("sprint_cooldown",   sprint_cooldown)

## Применяет бонусы экипировки из ProtectionConfig и InventoryConfig.
func _apply_equipment() -> void:
	# Сапоги → защита от луж
	var boot_data: Dictionary = ProtectionConfig.get_item("boots", boots_level)
	mud_slow_resistance = boot_data.get("mud_slow_resist",   0.0)
	immune_to_puddles   = boot_data.get("immune_to_puddles", false)

	# Плащ → защита от дождя
	var cloak_data: Dictionary = ProtectionConfig.get_item("cloak", cloak_level)
	rain_damage_reduction = cloak_data.get("rain_damage_reduction", 0.0)
	immune_to_rain        = cloak_data.get("immune_to_rain",        false)

	# Перчатки → защита от животных
	var gloves_data: Dictionary = ProtectionConfig.get_item("gloves", gloves_level)
	animal_damage_reduction = gloves_data.get("animal_damage_reduction", 0.0)
	immune_to_animals       = gloves_data.get("immune_to_animals",       false)

	# Тачка → вместимость и прочность
	var wb_data: Dictionary = InventoryConfig.get_item("wheelbarrow", wheelbarrow_level)
	wheelbarrow_capacity   = wb_data.get("capacity",   100)
	wheelbarrow_durability = wb_data.get("durability", 100)
	wheelbarrow_resistance = wb_data.get("resistance", 0)
	# Сообщаем Globals актуальную ёмкость тачки
	Globals.wheelbarrow_capacity_max = wheelbarrow_capacity

## Передаёт узлы в UnloadController для анимации выгрузки.
func _setup_unload_controller() -> void:
	if unload_ctrl:
		# Level unload controller will use Globals/InventorySystem for references.
		unload_ctrl.setup(player_anim, null, null, null)

## Возвращает InventorySystem (lazy init — кэшируется при первом обращении).
func _get_inv() -> Node:
	if not is_instance_valid(_inv):
		_inv = get_tree().get_root().get_node_or_null("Game/Progression/InventorySystem")
	return _inv

## InventorySystem now emits Events.wheelbarrow_spawned — обработчик moved в LevelUnload.

# ══════════════════════════════════════════════════════════════════════════════
# ─── Action FSM ───────────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
func _change_state(new_state: State) -> void:
	if state == new_state:
		return
	_exit_state(state)
	state = new_state
	_enter_state(state)

func _enter_state(s: State) -> void:
	match s:
		State.MOVE:
			if player_anim:
				player_anim.visible = true
		State.UNLOAD:
			direction  = 0
			velocity.x = 0
		State.USE_TOOL:
			direction  = 0
			velocity.x = 0
		State.DAMAGED:
			_damage_invuln_timer = damage_invuln_duration
			direction  = 0
			velocity.x = 0
			if player_anim:
				var t := create_tween()
				t.tween_property(player_anim, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.08)

func _exit_state(s: State) -> void:
	match s:
		State.DAMAGED:
			if player_anim:
				var t := create_tween()
				t.tween_property(player_anim, "modulate", Color.WHITE, 0.2)

## Основной цикл: тикает Skill FSM, затем рутинг по Action FSM.
func _physics_process(delta: float) -> void:
	_skill_tick(delta)
	match state:
		State.MOVE:     _process_move(delta)
		State.UNLOAD:   _process_unload(delta)
		State.USE_TOOL: _process_use_tool(delta)
		State.DAMAGED:  _process_damaged(delta)

## Движение, анимация, спринт, взаимодействие с тачкой.
func _process_move(delta: float) -> void:
	if movement_ctrl:
		movement_ctrl.process_move(delta)
		return
	# fallback (should not happen): keep original behavior
	var left_play   := Input.is_action_pressed("Left")
	var right_play  := Input.is_action_pressed("Right")
	var shift_press := Input.is_action_pressed("Shift")
	_update_sprint_state(delta, shift_press, left_play, right_play)
	var inv := _get_inv()
	var anim_speed: float = 1.2 if sprint_active else 1.0
	speed = (speed_shift if sprint_active else speed_norm) * puddle_slow_multiplier

	if player_anim:
		player_anim.visible     = true
		player_anim.speed_scale = anim_speed

	var moving := left_play or right_play
	if moving:
		if left_play:  _set_facing(true)
		if right_play: _set_facing(false)
		visible = true
		player_anim.play("walk")
	else:
		player_anim.play("stand")
	if inv:
		inv.set_wheelbarrow_moving(self, moving)

	previous_direction = direction
	direction          = Input.get_axis("Left", "Right")
	velocity.x         = direction * max(0.0, speed - wb_speed_penalty)
	velocity.y        += gravity * delta
	move_and_slide()

## Физика в UNLOAD: игрок заморожен, только гравитация.
func _process_unload(delta: float) -> void:
	direction  = 0
	velocity.x = 0
	velocity.y += gravity * delta
	move_and_slide()

## Физика в USE_TOOL: игрок стоит на месте, только гравитация.
func _process_use_tool(delta: float) -> void:
	direction  = 0
	velocity.x = 0
	velocity.y += gravity * delta
	move_and_slide()

## Физика в DAMAGED: заморожен, i-frames тикают до выхода обратно в MOVE.
func _process_damaged(delta: float) -> void:
	direction  = 0
	velocity.x = 0
	velocity.y += gravity * delta
	move_and_slide()
	_damage_invuln_timer -= delta
	if _damage_invuln_timer <= 0.0:
		_change_state(State.MOVE)

## Смена направления взгляда + смещение спрайта для выравнивания руки.
func _set_facing(left: bool) -> void:
	if _facing_left == left:
		return
	_facing_left = left
	player_anim.flip_h     = left
	player_anim.position.x = _sprite_base_x + (hand_align_left if left else hand_align_right)

## Логика спринта (кулдаун, начало, завершение).
func _update_sprint_state(delta: float, shift_pressed: bool, left_play: bool, right_play: bool) -> void:
	if movement_ctrl:
		movement_ctrl.update_sprint_state(delta, shift_pressed, left_play, right_play)
		return
	if sprint_cooldown_left > 0.0:
		sprint_cooldown_left = max(0.0, sprint_cooldown_left - delta)
	var moving := left_play or right_play
	var wants_sprint := shift_pressed and moving
	if sprint_active:
		if not wants_sprint:
			_end_sprint()
			return
		sprint_time_left -= delta
		if sprint_time_left <= 0.0:
			_end_sprint()
		return
	if wants_sprint and sprint_cooldown_left <= 0.0:
		_start_sprint()

func _start_sprint() -> void:
	if movement_ctrl:
		movement_ctrl.start_sprint()
		return
	sprint_active    = true
	sprint_time_left = sprint_duration

func _end_sprint() -> void:
	if movement_ctrl:
		movement_ctrl.end_sprint()
		return
	sprint_active        = false
	sprint_time_left     = 0.0
	sprint_cooldown_left = sprint_cooldown

## Возвращает разницу направлений (для ёжиков-воришек).
func get_direction_change() -> float:
	if movement_ctrl:
		return movement_ctrl.get_direction_change()
	return abs(direction - previous_direction) * speed

# ══════════════════════════════════════════════════════════════════════════════
# ─── Skill FSM ────────────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════

## Активирует навык по id. Вызывается из внешнего кода (UI, триггер уровня).
## duration — сколько длится, cooldown — перезарядка после.
func activate_skill(skill_id: String, duration: float = 8.0, cooldown: float = 15.0) -> void:
	if skill_state in [SkillState.LOCKED, SkillState.COOLDOWN, SkillState.ACTIVE]:
		return
	if skill_id not in unlocked_skills:
		push_warning("Player: навык '%s' не разблокирован" % skill_id)
		return
	active_skill_id       = skill_id
	_skill_timer          = duration
	_skill_cooldown       = cooldown
	skill_state           = SkillState.ACTIVE
	_enter_skill(skill_id)
	Events.skill_activated.emit(skill_id)

## Тикает Skill FSM — вызывается каждый кадр из _physics_process.
func _skill_tick(delta: float) -> void:
	match skill_state:
		SkillState.ACTIVE:
			_skill_timer -= delta
			if _skill_timer <= 0.0:
				_exit_skill(active_skill_id)
				Events.skill_deactivated.emit(active_skill_id)
				skill_state           = SkillState.COOLDOWN
				_skill_cooldown_timer = _skill_cooldown
		SkillState.COOLDOWN:
			_skill_cooldown_timer -= delta
			if _skill_cooldown_timer <= 0.0:
				skill_state     = SkillState.IDLE
				active_skill_id = ""

## Применяет эффект навыка при входе.
func _enter_skill(skill_id: String) -> void:
	match skill_id:
		"invisible":
			is_invisible = true
			if player_anim:
				var t := create_tween()
				t.tween_property(player_anim, "modulate:a", 0.25, 0.3)
		"super":
			is_super_active           = true
			_pre_skill_speed_norm     = speed_norm
			_pre_skill_speed_shift    = speed_shift
			_pre_skill_damage_mult    = damage_multiplier
			_pre_skill_immune_rain    = immune_to_rain
			_pre_skill_immune_puddles = immune_to_puddles
			_pre_skill_immune_animals = immune_to_animals
			_pre_skill_immune_lightning = immune_to_lightning
			speed_norm          = 130.0
			speed_shift         = 180.0
			damage_multiplier   = 0.1
			immune_to_rain      = true
			immune_to_puddles   = true
			immune_to_animals   = true
			immune_to_lightning = true
			if player_anim:
				player_anim.modulate = Color(1.0, 0.9, 0.2, 1.0)

## Восстанавливает состояние после завершения навыка.
func _exit_skill(skill_id: String) -> void:
	match skill_id:
		"invisible":
			is_invisible = false
			if player_anim:
				var t := create_tween()
				t.tween_property(player_anim, "modulate:a", 1.0, 0.3)
		"super":
			is_super_active     = false
			speed_norm          = _pre_skill_speed_norm
			speed_shift         = _pre_skill_speed_shift
			damage_multiplier   = _pre_skill_damage_mult
			immune_to_rain      = _pre_skill_immune_rain
			immune_to_puddles   = _pre_skill_immune_puddles
			immune_to_animals   = _pre_skill_immune_animals
			immune_to_lightning = _pre_skill_immune_lightning
			if player_anim:
				var t := create_tween()
				t.tween_property(player_anim, "modulate", Color.WHITE, 0.5)

# ══════════════════════════════════════════════════════════════════════════════
# ─── Входящий урон (контракт с Enemy) ─────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════

## Принять урон от врага. Enemy уже применил снижение от экипировки.
## Здесь применяется damage_multiplier от уровня скилла героя.
func take_damage(amount: float) -> void:
	if state == State.DAMAGED:
		return  # i-frames активны
	var final := int(round(amount * damage_multiplier))
	if final > 0:
		Globals.change_health(-final)
	_change_state(State.DAMAGED)

## Урон от дождя (rain_type: "water", "gold", "live", "lightning").
func player_shot(num: int, rain_type: String = "water") -> void:
	if rain_type == "lightning" and immune_to_lightning:
		return
	if rain_type in ["water", "gold", "live"] and immune_to_rain:
		return
	var actual := num
	if num < 0:
		# Применяем снижение урона от плаща (rain_damage_reduction) и скилла (damage_multiplier)
		var reduced := float(num) * (1.0 - rain_damage_reduction)
		actual = int(round(reduced * damage_multiplier))
	Globals.change_health(actual)

## Вернуть количество воды в тачке (контракт с Enemy).
func get_water_amount() -> float:
	return float(Globals.point_wheelbarrow)

## Украсть воду из тачки (контракт с Enemy).
func steal_water(amount: float) -> void:
	var inv := _get_inv()
	if inv:
		inv.apply_wheelbarrow_damage(self, int(amount), "steal")
	else:
		Globals.change_point_wheelbarrow(-int(amount))

## Урон по тачке — прокси в wheelbarrow_node.
func apply_wheelbarrow_damage(amount: int, damage_type: String = "enemy") -> void:
	var inv := _get_inv()
	if inv:
		inv.apply_wheelbarrow_damage(self, amount, damage_type)
	else:
		Globals.change_point_wheelbarrow(-amount)

# ══════════════════════════════════════════════════════════════════════════════
# ─── Лужи ─────────────────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════

## Применить замедление от лужи с учётом mud_slow_resistance (ProtectionConfig).
func apply_puddle_slow(slow_multiplier: float) -> void:
	if immune_to_puddles:
		return
	# mud_slow_resistance интерполирует эффект к 1.0 (нет замедления)
	var effective := lerpf(slow_multiplier, 1.0, mud_slow_resistance)
	puddle_slow_multiplier = effective
	is_in_puddle = true
	if player_anim:
		var tween := create_tween()
		tween.tween_property(player_anim, "modulate", Color(0.7, 0.8, 1.0, 1.0), 0.3)

## Убрать замедление от лужи.
func remove_puddle_slow() -> void:
	puddle_slow_multiplier = 1.0
	is_in_puddle = false
	if player_anim:
		var tween := create_tween()
		tween.tween_property(player_anim, "modulate", Color.WHITE, 0.3)

## Обновляет wb_speed_penalty при изменении воды в тачке.
func _on_wb_changed(_amount: int) -> void:
	wb_speed_penalty = Globals.get_wheelbarrow_percent() * wb_max_penalty

# ══════════════════════════════════════════════════════════════════════════════
# ─── Выгрузка тачки (StopPoint) ───────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════

func _on_stop_player_body_exited(_body: Node2D) -> void:
	pass

## Срабатывает при входе в StopPoint: запускает выгрузку тачки.
func _on_stop_player_body_entered(body: Node2D) -> void:
	if state != State.MOVE:
		return
	if not can_push_wheelbarrow:
		return
	if body.name != "Player" or direction <= 0:
		return
	# Delegate unload behaviour to InventorySystem (adapter). InventorySystem
	# will decide what to unload (wheelbarrow, bucket, ...). It should
	# perform item-specific work and return unloaded amount.
	var inv := _get_inv()
	var flip: bool = player_anim.flip_h if player_anim else false
	if inv:
		_change_state(State.UNLOAD)
		var unloaded_amount: int = await inv.unload_active(self, unload_ctrl, flip)
		if unloaded_amount > 0:
			exit_point += unloaded_amount
			XpManager.on_water_unloaded(unloaded_amount)
			Events.exit_point_changed.emit(exit_point, max_exit_point)
			# victory check remains in Player (level progression)
			if exit_point >= max_exit_point:
				var game := get_tree().root.get_node_or_null("Game")
				if game:
					game.victory()
		_change_state(State.MOVE)
		return
	# Fallback: preserve legacy behaviour if InventorySystem not present
	if body.name == "Player" and Globals.point_wheelbarrow > 0:
		var water_before := Globals.point_wheelbarrow
		var flip2: bool = player_anim.flip_h if player_anim else false
		if not unload_ctrl:
			push_warning("Player: unload_ctrl not assigned (no Unload node in level)")
			return
		_change_state(State.UNLOAD)
		await unload_ctrl.start(flip2)
		exit_point += water_before
		XpManager.on_water_unloaded(water_before)  # +1 XP за каждые 100л
		Events.exit_point_changed.emit(exit_point, max_exit_point)
		_change_state(State.MOVE)
		if exit_point >= max_exit_point:
			var game := get_tree().root.get_node_or_null("Game")
			if game:
				game.victory()
