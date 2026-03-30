## Базовый класс для всех типов капель дождя.
## Движение, деспавн, звук, брызги, лужа и логика попадания — всё здесь.
##
## Каждая .tscn-сцена капли может задать индивидуальные эффекты через @export
## прямо в Инспекторе, ничего не переопределяя в коде.
##
## Таблица попаданий (hit_configs):
##   Капля перебирает записи по порядку.
##   Первая, где body.has_method(cfg.key_method) == true, — выполняется.
##   Подкласс заполняет hit_configs дефолтами в своём _ready() если список пуст.
extends Area2D

const _DropHitConfig = preload("res://Elements/Enemy/Rain/drop_hit_config.gd")

# ─── Движение ────────────────────────────────────────────────────────────────

@export_group("Movement")
## Минимальная скорость падения (px/с).
@export var speed_min: float = 90.0
## Максимальная скорость падения (px/с).
@export var speed_max: float = 100.0
## Y-координата за которой каплю удаляют (пиксели от верха экрана).
@export var despawn_y: float = 800.0

# ─── Эффекты ─────────────────────────────────────────────────────────────────

@export_group("Effects")
## Сцена брызг. Инстанциируется в точке попадания.
## Оставьте пустым — брызги не появятся (даже если do_splash=true в hit_config).
@export var splash_scene: PackedScene = null
## Сцена лужи. null → автоматически используется Puddle.new() (класс puddle.gd).
@export var puddle_scene: PackedScene = null
## Звуки попадания. При ударе выбирается случайный.
@export var sounds: Array[AudioStream] = []
## Громкость звука (dB). -5 = нормальный игровой уровень.
@export var sound_volume_db: float = -5.0

# ─── Таблица попаданий ────────────────────────────────────────────────────────

@export_group("Hit Actions")
## Правила попадания: перебираются по порядку, срабатывает первое совпадение.
## Если список пуст — подкласс должен заполнить его в своём _ready().
@export var hit_configs: Array = []

# ─── Внутренние ───────────────────────────────────────────────────────────────

var _speed: float = 0.0
var _hit_done: bool = false  # защита от двойного срабатывания до queue_free

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_speed = randf_range(speed_min, speed_max)
	# .tscn подключает сигнал через [connection] — проверяем перед дублированием
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position.y += _speed * delta
	if global_position.y > despawn_y:
		queue_free()

# ─── Попадание ────────────────────────────────────────────────────────────────

func _on_body_entered(body: Node2D) -> void:
	if _hit_done:
		return
	_hit_done = true

	for cfg in hit_configs:
		if cfg.key_method != "" and body.has_method(cfg.key_method):
			_execute_hit(body, cfg)
			break

	queue_free()

func _execute_hit(body: Node2D, cfg) -> void:
	_play_sound()

	if cfg.do_splash:
		_spawn_splash(global_position)

	if cfg.do_puddle:
		_spawn_puddle(global_position)

	if cfg.key_method != "" and body.has_method(cfg.key_method):
		body.callv(cfg.key_method, _resolve_args(cfg.call_args))

	if cfg.globals_method != "" and Globals.has_method(cfg.globals_method):
		Globals.callv(cfg.globals_method, cfg.globals_args)

## Заменяет строку "_pos_" на текущий global_position капли.
func _resolve_args(args: Array) -> Array:
	var out: Array = []
	for a in args:
		out.append(global_position if (typeof(a) == TYPE_STRING and a == "_pos_") else a)
	return out

# ─── Вспомогательные ─────────────────────────────────────────────────────────

func _spawn_splash(pos: Vector2) -> void:
	if splash_scene == null:
		return
	var s := splash_scene.instantiate()
	get_tree().current_scene.add_child(s)
	s.global_position = pos

func _spawn_puddle(pos: Vector2) -> void:
	var node: Node2D
	if puddle_scene != null:
		node = puddle_scene.instantiate()
	else:
		node = Puddle.new()
	# Устанавливаем позицию до добавления в дерево
	# (parent обычно в (0,0), поэтому position == global_position)
	node.position = pos
	# call_deferred на РОДИТЕЛЬСКОМ узле — он не будет удалён,
	# поэтому колбэк не отменится в отличие от call_deferred на самой капле
	var parent: Node = get_node_or_null("/root/Game/Elements")
	if parent == null:
		parent = get_tree().root
	parent.call_deferred("add_child", node)

func _play_sound() -> void:
	if sounds.is_empty():
		return
	var player := AudioStreamPlayer.new()
	player.stream = sounds[randi() % sounds.size()]
	player.volume_db = sound_volume_db
	get_tree().root.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
