## InventorySystem — дочерний узел Progression в Game.tscn.
## Управляет жизненным циклом тачки: спавн, PinJoint2D, ссылки для игрока.
## API: spawn_wheelbarrow() / despawn_wheelbarrow() — при смене уровня без тачки.
extends Node

const WHEELBARROW_SCENE = preload("res://Elements/Wheelbarrow/wheelbarrow.tscn") as PackedScene
const BUCKET_SCENE = preload("res://Elements/Inventory/Bucket.tscn") as PackedScene

## Смещение якоря PinJoint2D (HandPoint относительно корня wheelbarrow.tscn).
const PIN_OFFSET:               Vector2 = Vector2(-34, -4)
const WHEELBARROW_SPAWN_Y_LIFT: float   = 6.0   ## подъём перед спавном, чтобы физика не положила тачку

## Смещение тачки относительно игрока при спавне (px).
const WHEELBARROW_SPAWN_OFFSET: Vector2 = Vector2(72, 32)

## Живой инстанс тачки.
var _wheelbarrow_instance: Node2D = null
var _bucket_instance: Node2D = null

func _ready() -> void:
	pass  # Прямая ссылка из game.gd (@onready), группа не нужна

# ── Публичные ссылки (используются player_base и unload_controller) ────────────
var wheelbarrow_root:         Node2D           = null
var wheelbarrow_node:         RigidBody2D      = null
var wheelbarrow_animate_play: AnimatedSprite2D = null
var dump_pivot:         Node2D           = null


## Спавнит тачку как сиблинга игрока, связывает PinJoint2D и уведомляет игрока.

func spawn_wheelbarrow(player: CharacterBody2D, parent: Node2D) -> void:
	print("[WB SPAWN] START  player.gpos=%s  active_equip='%s'" % [player.global_position, Globals.active_equip_id])
	if is_instance_valid(_wheelbarrow_instance):
		_wheelbarrow_instance.queue_free()

	_wheelbarrow_instance = WHEELBARROW_SCENE.instantiate()
	_wheelbarrow_instance.name = "Wheelbarrow"

	# Рассчитываем позицию ДО add_child — чтобы PhysicsServer2D зарегистрировал
	# RigidBody2D (Ruchka) сразу на нужных координатах, а не на (0, 0).
	# Иначе при активной физике (resume) PinJoint получает неверные якоря
	# и тачку уносит на расстояние, равное X-позиции игрока от нуля.
	var spawn_pos: Vector2 = player.global_position + WHEELBARROW_SPAWN_OFFSET

	var space: PhysicsDirectSpaceState2D = null
	if get_tree() and get_tree().get_current_scene():
		var world = get_tree().get_current_scene().get_world_2d()
		if world:
			space = world.direct_space_state

	if space:
		var from := player.global_position + Vector2(0, -8)
		var to := from + Vector2(0, 128)
		var params := PhysicsRayQueryParameters2D.new()
		params.from = from
		params.to = to
		params.exclude = [player]
		var res: Dictionary = space.intersect_ray(params)
		if res and res.has("position"):
			# Меняем только Y — X зафиксирован относительно игрока.
			spawn_pos.y = float(res["position"].y) - 4.0

	spawn_pos.y -= WHEELBARROW_SPAWN_Y_LIFT
	# Позиция задаётся ДО add_child: Elements в (0,0), поэтому position == global_position.
	_wheelbarrow_instance.position = spawn_pos
	print("[WB SPAWN] spawn_pos=%s  (player.gpos=%s)" % [spawn_pos, player.global_position])

	parent.add_child(_wheelbarrow_instance)

	# Кэш ссылок на узлы внутри wheelbarrow.tscn.
	wheelbarrow_root          = _wheelbarrow_instance
	wheelbarrow_node          = _wheelbarrow_instance.get_node("Ruchka")
	dump_pivot                = _wheelbarrow_instance.get_node("Ruchka/DumpPivot")
	wheelbarrow_animate_play  = _wheelbarrow_instance.get_node("Ruchka/DumpPivot/AnimatedSprite2D")

	# Сбрасываем позицию, поворот и скорости Ruchka перед созданием PinJoint.
	# global_position нужно задавать явно: RigidBody2D инициализируется физдвижком
	# на первом тике и может оказаться не там, где Node2D-родитель.
	if is_instance_valid(wheelbarrow_node):
		wheelbarrow_node.global_position   = spawn_pos
		wheelbarrow_node.angular_velocity  = 0
		wheelbarrow_node.linear_velocity   = Vector2.ZERO

	# PinJoint2D без angular limits: угол удерживается physical damp (linear_damp=8, angular_damp=8).
	# Limits задавали абсолютный угол тела в мире (90°–125°), что требовало sleeping/await
	# для синхронизации с физдвижком при каждом спавне.
	var pin := PinJoint2D.new()
	pin.name     = "Point_player"
	pin.softness = 0.0
	var anchor_pos: Vector2 = PIN_OFFSET
	if is_instance_valid(wheelbarrow_node):
		var hand_point := wheelbarrow_node.get_node_or_null("HandPoint")
		anchor_pos = wheelbarrow_node.position + (hand_point.position if hand_point else Vector2.ZERO)
	pin.position = anchor_pos
	_wheelbarrow_instance.add_child(pin)
	# NodePath-и задаются после add_child — нода должна быть в дереве.
	pin.node_a = player.get_path()
	pin.node_b = wheelbarrow_node.get_path()
	print("[WB SPAWN] pin.pos(local)=%s  wb_node.gpos=%s" % [pin.position, wheelbarrow_node.global_position])

	Globals.active_equip_id = "wheelbarrow"
	Events.wheelbarrow_spawned.emit(player, wheelbarrow_node, wheelbarrow_root, wheelbarrow_animate_play, dump_pivot)
	print("[WB SPAWN] DONE   wb.gpos=%s  wb.rotation=%.3f" % [wheelbarrow_node.global_position, wheelbarrow_node.rotation])

## Деспавнит тачку и сбрасывает active_equip_id.
func despawn_wheelbarrow(p_player: Node = null) -> void:
	if is_instance_valid(_wheelbarrow_instance):
		var wb_gpos: String = str(wheelbarrow_node.global_position) if is_instance_valid(wheelbarrow_node) else "n/a"
		print("[WB DESPAWN] wb.gpos=%s active_equip='%s'" % [wb_gpos, Globals.active_equip_id])
		_wheelbarrow_instance.queue_free()
	_wheelbarrow_instance    = null
	wheelbarrow_root         = null
	wheelbarrow_node         = null
	wheelbarrow_animate_play = null
	dump_pivot               = null
	# active_equip_id НЕ сбрасываем здесь — это делает вызывающий (game.gd)
	Events.wheelbarrow_despawned.emit(p_player)

## Спавнит простое ведро: ставится рядом с игроком, без сложной физики.
func spawn_bucket(player: CharacterBody2D, parent: Node2D) -> void:
	if is_instance_valid(_bucket_instance):
		_bucket_instance.queue_free()

	_bucket_instance = BUCKET_SCENE.instantiate()
	_bucket_instance.name = "Bucket"
	parent.add_child(_bucket_instance)

	# Если у сцены ведра есть узел Handle, используем его как якорь.
	var handle_local: Vector2 = Vector2(0, -30)
	# Предпочитаем экспортируемое свойство handle_offset в скрипте сцены,
	# затем узел Handle, затем дефолт.
	if "handle_offset" in _bucket_instance:
		handle_local = _bucket_instance.handle_offset
	elif _bucket_instance.has_node("Handle"):
		handle_local = _bucket_instance.get_node("Handle").position

	# Получаем смещение по X из player (hand_align) и из сцены ведра (flip compensation)
	var player_hand_x: float = 0.0
	var flip_h: bool = false
	if player.has_node("Anim_Player"):
		var anim := player.get_node("Anim_Player")
		flip_h = anim.flip_h
		if "hand_align_left" in player and "hand_align_right" in player:
			player_hand_x = player.hand_align_left if flip_h else player.hand_align_right

	var comp_x: float = 0.0
	if "flip_x_compensation" in _bucket_instance:
		comp_x = float(_bucket_instance.flip_x_compensation)

	var comp_signed: float = -comp_x if flip_h else comp_x

	# Берём глобальную позицию спрайта игрока (Anim_Player) если он есть,
	# иначе используем player.global_position как fallback.
	var base_global: Vector2 = player.global_position
	if player.has_node("Anim_Player"):
		var anim_node := player.get_node("Anim_Player")
		if anim_node:
			base_global = anim_node.global_position

	# Желаемая глобальная позиция handle = позиция anim + hand offset + компенсация
	var desired_handle_global: Vector2 = base_global + Vector2(player_hand_x + comp_signed, handle_local.y)

	# Ставим корень ведра так, чтобы локальная точка handle совпала с desired_handle_global
	_bucket_instance.global_position = desired_handle_global - handle_local

	# Создаём PinJoint2D на ведре, чтобы прикрепить его к игроку в точке ручки
	var pin := PinJoint2D.new()
	pin.name = "Pin_player"
	pin.position = handle_local
	_bucket_instance.add_child(pin)
	pin.node_a = player.get_path()
	pin.node_b = _bucket_instance.get_path()

	Globals.active_equip_id = "bucket"

func despawn_bucket() -> void:
	if is_instance_valid(_bucket_instance):
		_bucket_instance.queue_free()
	_bucket_instance = null

## Деспавнит конкретный предмет по id.
func despawn_equip(equip_id: String) -> void:
	match equip_id:
		"wheelbarrow": despawn_wheelbarrow()
		"bucket": despawn_bucket()
		# другие предметы добавлять здесь

## Спавнит предмет по active_equip_id при resume.
## Добавь новые ветки match при добавлении новых предметов (bucket, pickaxe…).
func spawn_active(p_player: CharacterBody2D, p_parent: Node2D) -> void:
	match Globals.active_equip_id:
		"wheelbarrow": spawn_wheelbarrow(p_player, p_parent)
		"bucket": spawn_bucket(p_player, p_parent)

## Полный сброс инвентаря при старте нового уровня.
## Деспавнит всю текущую экипировку по сохранённому id (до того как Globals сбросит его).
func reset_for_level(equip_id_to_remove: String) -> void:
	despawn_equip(equip_id_to_remove)

## Адаптерный API для внешних систем (Player и др.) — минимальные операции над тачкой.
func set_wheelbarrow_moving(_p_player: Node, moving: bool) -> void:
	if is_instance_valid(wheelbarrow_node):
		wheelbarrow_node.set_moving(moving)

func apply_wheelbarrow_damage(_p_player: Node, amount: int, damage_type: String = "enemy") -> void:
	if is_instance_valid(wheelbarrow_node):
		wheelbarrow_node.apply_damage(amount, damage_type)
	else:
		Globals.change_point_wheelbarrow(-amount)

func get_wheelbarrow_fill(_p_player: Node) -> int:
	return Globals.point_wheelbarrow


## Универсальная выгрузка активного предмета.
## Возвращает количество выгруженной воды (int). Если предметная сцена
## реализует свою визуальную выгрузку (метод `start_unload`), то этот
## метод делегирует ей. Иначе используется старый fallback: вызывает
## `unload_ctrl.start(flip)` и списывает воду из Globals.
func unload_active(p_player: Node, unload_ctrl: Node, flip: bool = false) -> int:
	var equip_id: String = Globals.active_equip_id
	match equip_id:
		"wheelbarrow":
			var water_before: int = Globals.point_wheelbarrow
			# Если у корня сцены wheelbarrow есть метод start_unload, делегируем туда
			if is_instance_valid(wheelbarrow_root) and wheelbarrow_root.has_method("start_unload"):
				var res = await wheelbarrow_root.start_unload(p_player, unload_ctrl, flip)
				if typeof(res) == TYPE_INT:
					return res
				return water_before
			# Fallback: используем уровень (unload_ctrl) и сами списываем воду
			if not unload_ctrl:
				push_warning("InventorySystem: unload_ctrl missing, cannot play unload animation")
				return 0
			await unload_ctrl.start(flip)
			Globals.change_point_wheelbarrow(-water_before)
			return water_before
		_:
			return 0
