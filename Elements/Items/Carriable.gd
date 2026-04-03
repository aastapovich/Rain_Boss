# Carriable.gd — базовый компонент для переносимых предметов (бочка, ведро, лопата и т.д.).
# Подключается как корневой скрипт к сцене предмета.
# Взаимодействует с PlayerInventory через сигналы Area2D и прямые вызовы методов.
extends Node2D

# Тип предмета: используется в PlayerInventory для различия «carriable» и «mechanism» (тачка).
@export var item_type: String = "carriable"
# Отображаемое имя в UI инвентаря.
@export var item_label: String = "Предмет"
# true  — предмет физически присутствует на сцене (можно подобрать через E или слот).
# false — предмет «в кармане»: скрыт по умолчанию, появляется только когда выбран слот.
@export var item_visible: bool = true
# Смещение предмета относительно игрока, пока тот держит предмет в руках.
@export var hand_offset: Vector2 = Vector2(50, -40)
# Дополнительная дельта X при повороте влево (facing == -1).
# Компенсирует разницу в пивоте спрайта. Подбирается индивидуально для каждого предмета.
@export var flip_x_compensation: float = 0.0
@export var held_rotation_deg: float = 0.0    # угол когда в руках
@export var drop_rotation_deg: float = 0.0    # угол когда поставлен

# Ссылка на персонажа, держащего предмет (null — предмет свободен).
var _carrier: CharacterBody2D = null
# true, пока игрок находится в зоне Area2D предмета.
var _player_nearby: bool = false

func _ready() -> void:
	# Подписываемся на сигналы зоны захвата.
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	# Пока предмет держат — следуем за рукой игрока, учитывая направление взгляда.
	if _carrier:
		var facing: int = _carrier.get("_last_facing") if _carrier.get("_last_facing") != null else 1
		var comp: float = flip_x_compensation if facing < 0 else 0.0
		global_position = _carrier.global_position + Vector2(hand_offset.x * float(facing) + comp, hand_offset.y)

# Возвращает true, если игрок рядом и предмет не занят другим носителем.
func can_pickup() -> bool:
	return _player_nearby and _carrier == null

# Вызывается PlayerInventory при подборе: фиксируем носителя, гасим обводку.
func pickup(carrier: CharacterBody2D) -> void:
	_carrier = carrier
	_player_nearby = false
	_set_outline(false)
	rotation_degrees = held_rotation_deg

# Кладём предмет на землю (item_visible = true): носитель отпущен, предмет остаётся видимым.
func drop() -> void:
	_carrier = null
	rotation_degrees = drop_rotation_deg
	# Откладываем проверку, чтобы физика успела обновить overlapping bodies.
	call_deferred("_check_nearby_after_drop")

# Прячем предмет в инвентарь (item_visible = false): отключаем узел и коллизию.
func store() -> void:
	_carrier = null
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	$Area2D.collision_mask = 0

# Достаём предмет из инвентаря: восстанавливаем позицию, коллизию и видимость.
func restore(at_position: Vector2) -> void:
	global_position = at_position
	$Area2D.collision_mask = 8
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT

# Включает/выключает шейдерную обводку у первого дочернего CanvasItem с ShaderMaterial.
func _set_outline(enabled: bool) -> void:
	for child in get_children():
		if child is CanvasItem and child.material is ShaderMaterial:
			(child.material as ShaderMaterial).set_shader_parameter("show_outline", enabled)
			return

# Игрок вошёл в зону: подсвечиваем предмет и сообщаем инвентарю о «ближайшем» предмете.
func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and _carrier == null:
		_player_nearby = true
		_set_outline(true)
		if body.has_method("set_nearby_item"):
			body.set_nearby_item(self, null)

# Игрок вышел из зоны: убираем подсветку и сбрасываем ссылку в инвентаре.
func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = false
		_set_outline(false)
		if body.has_method("set_nearby_item"):
			body.set_nearby_item(null, self)

# После drop() проверяем, не стоит ли игрок уже рядом (вдруг сбросил прямо на себя).
func _check_nearby_after_drop() -> void:
	for body in $Area2D.get_overlapping_bodies():
		if body is CharacterBody2D:
			_player_nearby = true
			_set_outline(true)
			if body.has_method("set_nearby_item"):
				body.set_nearby_item(self, null)
			break
