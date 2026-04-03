# Wheel.gd — скрипт тачки (механизм, присоединяемый к игроку).
# В отличие от Carriable, тачка — это CharacterBody2D с собственной физикой:
# она катится рядом с игроком, а не просто телепортируется в руку.
extends CharacterBody2D

const SPLASH_SCENE := preload("res://Elements/Enemy/Rain/rain_splash.tscn")

# Максимальная скорость догонялки и жёсткость пружины следования за игроком.
@export var follow_speed: float = 600.0
@export var follow_stiffness: float = 10.0
@export var gravity: float = 1000.0

var player: CharacterBody2D
# false — тачка стоит отдельно; игрок подходит и подхватывает её сам.
var is_attached: bool = false
# Тип «mechanism» отличает тачку от обычных carriable-предметов в логике инвентаря.
var item_type: String = "mechanism"
var item_label: String = "Тачка"

# Смещение точки захвата для направления «вправо» (dir=1). При dir=-1 x зеркалится.
@export var hand_offset: Vector2 = Vector2(-14, -10)
# Дополнительная коррекция X при flip (dir=-1), аналог flip_x_compensation для Carriable.
@export var flip_x_compensation: float = 0.0
var _facing: int = 1
# Текущее смещение с учётом зеркалирования.
var _effective_offset: Vector2
var _player_nearby: bool = false

## Скорость плавного перехода уровня воды (ед/сек, 0..1 диапазон).
@export var water_lerp_speed: float = 4.0

# use_Player — маркер-узел, указывающий точку захвата на самой тачке.
@onready var use_player_node: Node2D = $use_Player
@onready var visual := $Visual
@onready var _attach_area: Area2D = $use_Player/AttachArea
@onready var _water: AnimatedSprite2D = $Visual/AnimatedSprite2D

var _water_base_scale_y: float  # сохраняем базовый Y из сцены
var _water_fill_target: float = 0.0  # 0..1

func _ready():
	# Ищем Player по группе — работает независимо от иерархии сцены.
	# (В ГП Player живёт в Game/Elements, Wheel — в Game/LevelContent/Level01Content.)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as CharacterBody2D
	# Исключаем коллизию между тачкой и игроком, чтобы они не толкали друг друга.
	if player:
		add_collision_exception_with(player)
	_effective_offset = hand_offset
	_attach_area.body_entered.connect(_on_attach_area_entered)
	_attach_area.body_exited.connect(_on_attach_area_exited)
	# Вода: сохраняем базовый scale.y и устанавливаем текущее заполнение.
	_water_base_scale_y = _water.scale.y
	Events.wheelbarrow_changed.connect(_on_fill_changed)
	_on_fill_changed(Globals.point_wheelbarrow)

func _physics_process(delta):
	if is_attached and player:
		# Вычисляем целевую X-позицию корня тачки так, чтобы use_Player
		# оказался точно у руки игрока (_effective_offset от позиции игрока).
		var grip_to_root = global_position - use_player_node.global_position
		var target_x = player.global_position.x + _effective_offset.x + grip_to_root.x
		velocity.x = clamp(
			(target_x - global_position.x) * follow_stiffness,
			-follow_speed, follow_speed
		)
	else:
		# После отсоединения плавно тормозим.
		velocity.x = move_toward(velocity.x, 0, follow_speed * delta)

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	move_and_slide()

	# Плавная анимация уровня воды (только scale.y).
	var cur := _water.scale.y
	var target := _water_fill_target * _water_base_scale_y
	if not is_equal_approx(cur, target):
		_water.scale.y = move_toward(cur, target, _water_base_scale_y * water_lerp_speed * delta)

# Зеркалит спрайт и сдвигает точку захвата при смене направления движения игрока.
func set_facing(dir: int) -> void:
	if dir == _facing:
		return
	_facing = dir
	var comp: float = flip_x_compensation if dir < 0 else 0.0
	_effective_offset = Vector2(hand_offset.x * float(dir) + comp, hand_offset.y)
	visual.scale.x = float(dir)
	use_player_node.position.x = -abs(use_player_node.position.x) * float(dir)
	$Shin/shin.flip_h = (dir < 0)

func set_outline(enabled: bool) -> void:
	($Visual/Whell_tank.material as ShaderMaterial).set_shader_parameter("show_outline", enabled)

# Игрок вошёл в зону захвата (только когда тачка не присоединена).
func _on_attach_area_entered(body: Node2D) -> void:
	if body == player and not is_attached:
		_player_nearby = true
		set_outline(true)
		if body.has_method("set_nearby_item"):
			body.set_nearby_item(self, null)

# Игрок вышел из зоны захвата.
func _on_attach_area_exited(body: Node2D) -> void:
	if body == player:
		_player_nearby = false
		set_outline(false)
		if body.has_method("set_nearby_item"):
			body.set_nearby_item(null, self)

# Тачку можно прицепить, только если игрок рядом и она уже не прицеплена.
func can_pickup() -> bool:
	return _player_nearby and not is_attached

# Присоединяем тачку: сразу ориентируем по направлению игрока.
func pickup(p: CharacterBody2D) -> void:
	var facing: int = p.get("_last_facing") if p.get("_last_facing") != null else 1
	set_facing(facing)
	set_outline(false)
	_player_nearby = false
	is_attached = true

# Отсоединяем тачку — она остаётся на месте и катится по инерции.
func drop() -> void:
	is_attached = false

# Скрываем тачку в инвентарь (на случай item_visible = false).
func store() -> void:
	is_attached = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

# Восстанавливаем тачку из инвентаря на заданную позицию.
func restore(at_position: Vector2) -> void:
	global_position = at_position
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT

## Запускает выгрузку воды через UnloadController уровня.
## Вызывается из InventorySystem.unload_active().
func start_unload(_p_player: Node, unload_ctrl: Node, flip: bool) -> int:
	if not unload_ctrl or Globals.point_wheelbarrow <= 0:
		return 0
	var water_before := Globals.point_wheelbarrow
	await unload_ctrl.start(flip)
	return water_before

## Попадание капли дождя в тачку.
## Метод намеренно называется rain_wheelbarrow_add — rain_drop_base ищет его через has_method.
func rain_wheelbarrow_add(num: int = 0, _rain_type: String = "water", _source: Node = null) -> void:
	Globals.change_point_wheelbarrow(num)  # emit wheelbarrow_changed → _on_fill_changed
	if SPLASH_SCENE:
		var splash := SPLASH_SCENE.instantiate()
		get_tree().current_scene.add_child(splash)
		splash.global_position = global_position

func _on_fill_changed(amount: int) -> void:
	_water_fill_target = float(amount) / float(maxf(Globals.wheelbarrow_capacity_max, 1))
	_water.visible = amount > 0
