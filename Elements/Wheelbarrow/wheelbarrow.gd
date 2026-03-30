## Тачка (RigidBody2D): визуализация заполнения, предупреждения, расплёскивание воды.
## Читает Globals.point_wheelbarrow через Events.wheelbarrow_changed.
extends RigidBody2D

const SPLASH_SCENE := preload("res://Elements/Enemy/Rain/rain_splash.tscn")

# ── Публичное состояние (читается player_base) ─────────────────────────────
var speed_coef: float = 1.0

# ── Настройки (экспорт) ────────────────────────────────────────────────────

## Заполнение (0..1), при котором появляется предупреждающая надпись «!!!»
@export var warning_fill_threshold: float  = 0.85

## Заполнение (0..1), при котором надпись краснеет и начинается расплёскивание
@export var overflow_fill_threshold: float = 0.95

## Минимальный процент воды, который выплёскивается за одну итерацию (0..1)
@export var spill_min_percent: float = 0.02

## Максимальный процент воды, который выплёскивается за одну итерацию (0..1)
@export var spill_max_percent: float = 0.03

## Задержка (сек) между двумя последовательными расплёскиваниями
@export var spill_cooldown: float = 1.5

## Порог урона за один удар (доля MAX_WHELL_CAPACITY), при котором срабатывает расплёскивание
@export var critical_damage_percent: float = 0.15

## Сколько секунд показывается предупреждение после получения урона
@export var damage_warning_duration: float = 2.0

## Минимальное заполнение (0..1), при котором вода плещется при старте/остановке
@export var slosh_min_fill: float = 0.01

## Скорость сглаживания масштаба воды (ед/сек). Выше — быстрее реагирует на каждую каплю
@export var water_scale_lerp_speed: float = 5.0

@export_group("Splash Offset")
## Смещение точки брызг при попадании капли в тачку
@export var splash_offset_rain:  Vector2 = Vector2(50.0, -1.0)
## Смещение точки брызг при расплёскивании (переполнение/урон)
@export var splash_offset_spill: Vector2 = Vector2(0.0, -20.0)

# ── Узлы ──────────────────────────────────────────────────────────────────
@onready var _sprite: AnimatedSprite2D = $DumpPivot/AnimatedSprite2D
@onready var _warning_label            = $WarningLabel
@onready var dump_pivot: Node2D = $DumpPivot

# ── Внутренние переменные ─────────────────────────────────────────────────
var _is_moving: bool   = false
var _is_sloshing: bool = false  # идёт Whell_left или Whell_right

var _base_scale: Vector2      = Vector2.ONE  # оригинальный scale спрайта из сцены
var _current_scale_mul: float = 0.0          # текущий множитель (0..1)
var _target_scale_mul: float  = 0.0          # целевой множитель (0..1)

var _last_fill: int    = 0

var _warning_active: bool      = false
var _warning_blink_state: bool = false
var _warning_timer: float      = 0.0
var _damage_warning_timer: float = 0.0
var _spill_cooldown_timer: float = 0.0

const _BLINK_INTERVAL: float = 0.45

# ──────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	Events.wheelbarrow_changed.connect(_on_fill_changed)
	if _warning_label:
		_warning_label.visible = false
	if _sprite:
		_base_scale = _sprite.scale
		# animation_finished срабатывает только для незацикленных анимаций (Whell_left/right)
		_sprite.animation_finished.connect(_on_slosh_finished)
	_apply_level(Globals.point_wheelbarrow)

func _process(delta: float) -> void:
	_tick_timers(delta)
	_blink(delta)
	_update_water_scale(delta)

# ── Публичный API ──────────────────────────────────────────────────────────

## Сообщить тачке, движется ли игрок — запускает плескание или нормальную анимацию.
func set_moving(is_moving: bool) -> void:
	if _is_moving == is_moving:
		return
	_is_moving = is_moving
	# Плескание воды только при достаточном количестве воды
	if Globals.get_wheelbarrow_percent() >= slosh_min_fill:
		# Старт → вода плещется назад (Whell_right)
		# Стоп  → вода плещется вперёд (Whell_left)
		_play_slosh("Whell_right" if is_moving else "Whell_left")
	else:
		_play_normal_anim()

## Урон по тачке (проксируется из player_base).
func apply_damage(amount: int, damage_type: String = "enemy") -> void:
	if amount <= 0:
		return
	Globals.change_point_wheelbarrow(-amount)
	_damage_warning_timer = max(_damage_warning_timer, damage_warning_duration)
	if _is_critical(amount, damage_type):
		_spill("critical_damage")
	_refresh_warning()

## Попадание капли дождя в тачку.
func rain_wheelbarrow_add(num: int = 0, rain_type: String = "water", source: Node = null) -> void:
	# Если передан источник (например, капля), попробуем нанести урон этому объекту
	if source and is_instance_valid(source) and source.has_method("take_damage"):
		# Наносим минимальный урон — капля умрёт и сама раздаст награду через EnemyManager
		source.take_damage(1)
		return

	# Fallback: добавляем воду/наградные очки в тачку как раньше
	Globals.change_point_wheelbarrow(num)
	_play_splash(global_position + splash_offset_rain, rain_type)

# ── Внутренняя логика ──────────────────────────────────────────────────────

func _on_fill_changed(amount: int) -> void:
	var diff := amount - _last_fill
	_last_fill = amount
	_apply_level(amount)
	if diff > 0:
		_check_overflow()
	_refresh_warning()

func _apply_level(amount: int) -> void:
	var fill_pct := float(amount) / float(Globals.wheelbarrow_capacity_max)

	# Скорость тачки линейно: 1.0 (пусто) → 0.5 (полно)
	speed_coef = lerp(1.0, 0.5, fill_pct)

	# Целевой масштаб воды: 0 (пусто) → 1 (полно)
	_target_scale_mul = fill_pct

## Запустить анимацию плескания (Whell_left / Whell_right).
## Если анимация ещё не добавлена в SpriteFrames — просто продолжаем обычную.
func _play_slosh(anim: String) -> void:
	if not _sprite or not _sprite.sprite_frames:
		_play_normal_anim()
		return
	if not _sprite.sprite_frames.has_animation(anim):
		_play_normal_anim()
		return
	_is_sloshing = true
	_sprite.play(anim)

func _on_slosh_finished() -> void:
	_is_sloshing = false
	_play_normal_anim()

func _play_normal_anim() -> void:
	if not _sprite:
		return
	_sprite.play("Whell_11" if _is_moving else "Whell_10")

func _update_water_scale(delta: float) -> void:
	if not _sprite:
		return
	_current_scale_mul = move_toward(_current_scale_mul, _target_scale_mul, water_scale_lerp_speed * delta)
	_sprite.scale.y = _base_scale.y * _current_scale_mul
	_sprite.scale.x = _base_scale.x  # Сохраняем исходный масштаб по оси X

func _is_critical(amount: int, damage_type: String) -> bool:
	if damage_type == "steal":
		return false
	return amount >= max(1, int(ceil(Globals.MAX_WHELL_CAPACITY * critical_damage_percent)))

func _check_overflow() -> void:
	if _spill_cooldown_timer > 0.0:
		return
	if Globals.get_wheelbarrow_percent() >= overflow_fill_threshold:
		_spill("overflow")

func _spill(_reason: String) -> void:
	if _spill_cooldown_timer > 0.0:
		return
	var current := Globals.point_wheelbarrow
	if current <= 0:
		return
	var pct    := randf_range(spill_min_percent, spill_max_percent)
	var amount: int = clamp(int(ceil(current * pct)), 1, current)
	Globals.change_point_wheelbarrow(-amount)
	_spill_cooldown_timer = spill_cooldown
	_play_splash(global_position + splash_offset_spill, "water")
	_damage_warning_timer = max(_damage_warning_timer, damage_warning_duration)
	_refresh_warning()

func _refresh_warning() -> void:
	var fill := Globals.get_wheelbarrow_percent()
	var was  := _warning_active
	_warning_active = fill >= warning_fill_threshold or _damage_warning_timer > 0.0
	if not _warning_label:
		return
	if not _warning_active:
		_warning_label.visible = false
		return
	_warning_label.modulate = Color(1.0, 0.2, 0.2) if fill >= overflow_fill_threshold \
							else Color(1.0, 0.9, 0.2)
	if not was:
		_warning_timer       = 0.0
		_warning_blink_state = true
		_warning_label.visible = true

func _blink(delta: float) -> void:
	if not _warning_active or not _warning_label:
		return
	_warning_timer += delta
	if _warning_timer >= _BLINK_INTERVAL:
		_warning_timer       = 0.0
		_warning_blink_state = not _warning_blink_state
	_warning_label.visible = _warning_blink_state

func _tick_timers(delta: float) -> void:
	if _spill_cooldown_timer > 0.0:
		_spill_cooldown_timer = max(0.0, _spill_cooldown_timer - delta)
	if _damage_warning_timer > 0.0:
		_damage_warning_timer = max(0.0, _damage_warning_timer - delta)

func _play_splash(pos: Vector2, _rain_type: String) -> void:
	var splash := SPLASH_SCENE.instantiate()
	get_tree().current_scene.add_child(splash)
	splash.global_position = pos


## Визуальная выгрузка. Делегирует уровню через `unload_ctrl.start(flip)` если он передан,
## иначе проигрывает локальную анимацию ручки. Возвращает количество выгруженной воды (int).
func start_unload(_p_player: Node, unload_ctrl: Node, flip: bool = false) -> int:
	var water_before: int = Globals.point_wheelbarrow
	if water_before <= 0:
		return 0

	# Если уровень предоставляет контроллер визуальной выгрузки — используем его.
	if unload_ctrl and unload_ctrl.has_method("start"):
		await unload_ctrl.start(flip)
	else:
		# Простая локальная анимация: повернём DumpPivot вперёд и обратно
		if is_instance_valid(dump_pivot):
			var start_rot: float = dump_pivot.rotation
			var t := create_tween()
			t.tween_property(dump_pivot, "rotation", start_rot + 0.6, 0.28)
			t.tween_property(dump_pivot, "rotation", start_rot, 0.28)
			await t.finished
		# Минимальный эффект расплёскивания
		_play_splash(global_position + splash_offset_spill, "water")

	# Списываем всю воду и возвращаем её количество (соответствует legacy-логике)
	Globals.change_point_wheelbarrow(-water_before)
	return water_before
