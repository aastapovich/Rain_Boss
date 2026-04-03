## InventorySystem — дочерний узел Progression в Game.tscn.
## Тачка и ведро живут в level_XX.tscn как статичные узлы — здесь НЕ управляются.
## Spawn-система зарезервирована для будущих динамически спавнуемых предметов.
extends Node

# Конфигурация спавнуемых предметов.
# bucket убран: ведро живёт в level_XX.tscn как статичный узел (Carriable.gd).
const ITEM_CONFIGS = {
	# Здесь будут будущие динамически спавнуемые предметы
}

# Текущие инстансы предметов
var _item_instances: Dictionary = {}
var _player: CharacterBody2D = null

func _ready() -> void:
	pass  # Прямая ссылка из game.gd (@onready), группа не нужна

# ── Публичные ссылки (используются player_base и unload_controller) ────────────
var item_root: Node2D = null
var item_physics_body: RigidBody2D = null
var item_animate_play: AnimatedSprite2D = null
var dump_pivot: Node2D = null

## Универсальный метод для спавна предмета
func spawn_item(item_id: String, player: CharacterBody2D, parent: Node2D) -> void:
	_player = player

	# Проверяем, есть ли конфигурация для этого предмета
	if not ITEM_CONFIGS.has(item_id):
		print("Error: Unknown item ID '%s'" % item_id)
		return

	# Деспавним текущий предмет, если он есть
	if _item_instances.has(item_id) and is_instance_valid(_item_instances[item_id]):
		despawn_item(item_id)

	# Получаем конфигурацию предмета
	var config = ITEM_CONFIGS[item_id]

	# Создаем инстанс предмета
	var item_instance = config["scene"].instantiate()
	item_instance.name = item_id.capitalize()
	parent.add_child(item_instance)

	# Сохраняем инстанс
	_item_instances[item_id] = item_instance

	# Кэшируем ноды
	cache_item_nodes(item_instance, config)

	# Устанавливаем начальное состояние
	set_item_initial_state(player, item_instance, config)

	# Уведомляем систему о готовности предмета
	Events.emit_signal("item_spawned", player, item_id, item_physics_body, item_root, item_animate_play, dump_pivot)

	# Подписываемся на сигнал готовности игрока
	await Events.player_ready

	# Создаем соединение, если нужно
	if config["joint_type"]:
		create_joint_connection(item_id, config)

	# Обновляем активный предмет
	Globals.active_equip_id = item_id
	print("[ITEM SPAWN] DONE item='%s' pos=%s rot=%.3f" % [item_id, item_physics_body.global_position, item_physics_body.rotation])

## Создает соединение для предмета
func create_joint_connection(item_id: String, config: Dictionary) -> void:
	if not is_instance_valid(_player) or not is_instance_valid(item_physics_body):
		return

	# Создаем соединение указанного типа
	var joint = config["joint_type"].new()
	joint.name = "ItemJoint_%s" % item_id
	joint.softness = 0.0

	# Устанавливаем позицию соединения
	var anchor_pos = config["joint_offset"]
	if is_instance_valid(item_physics_body):
		var hand_point = item_physics_body.get_node_or_null("HandPoint")
		anchor_pos = item_physics_body.position + (hand_point.position if hand_point else Vector2.ZERO)

	joint.position = anchor_pos
	_item_instances[item_id].add_child(joint)
	joint.node_a = _player.get_path()
	joint.node_b = item_physics_body.get_path()

	# Настройка физики
	item_physics_body.mass = 8.0
	item_physics_body.linear_damp = 0.3
	item_physics_body.angular_damp = 0.3

## Деспавнит предмет
func despawn_item(item_id: String, p_player: Node = null) -> void:
	if _item_instances.has(item_id) and is_instance_valid(_item_instances[item_id]):
		var item_instance = _item_instances[item_id]
		var pos_str = "n/a"
		if is_instance_valid(item_physics_body):
			pos_str = str(item_physics_body.global_position)

		print("[ITEM DESPAWN] item='%s' pos=%s active_equip='%s'" % [item_id, pos_str, Globals.active_equip_id])
		item_instance.queue_free()

		# Сбрасываем ссылки
		item_root = null
		item_physics_body = null
		item_animate_play = null
		dump_pivot = null

		# Удаляем из словаря инстансов
		_item_instances.erase(item_id)

		Events.item_despawned.emit(p_player, item_id)

## Кэширует ноды предмета
func cache_item_nodes(instance: Node2D, config: Dictionary) -> void:
	item_root = instance.get_node(config["node_paths"]["root"])
	item_physics_body = instance.get_node(config["node_paths"]["physics_body"])

	if config["node_paths"]["animated_sprite"]:
		item_animate_play = instance.get_node(config["node_paths"]["animated_sprite"])
	else:
		item_animate_play = null

	if config["node_paths"]["dump_pivot"]:
		dump_pivot = instance.get_node(config["node_paths"]["dump_pivot"])
	else:
		dump_pivot = null

## Устанавливает начальное состояние предмета
func set_item_initial_state(player: CharacterBody2D, instance: Node2D, config: Dictionary) -> void:
	if not is_instance_valid(instance):
		return

	# Устанавливаем только global_position — instance.position после этого НЕ трогать,
	# иначе локальная позиция (0,0) перезапишет вычисленную глобальную и тачка окажется
	# в начале координат сцены вместо позиции рядом с игроком.
	instance.global_position = calculate_spawn_position(player, config)
	instance.rotation = 0.0

	# Дополнительные настройки для физики
	if is_instance_valid(item_physics_body):
		item_physics_body.sleeping = false
		item_physics_body.linear_velocity = Vector2.ZERO
		item_physics_body.angular_velocity = 0.0

## Вычисляет позицию спавна
func calculate_spawn_position(player: CharacterBody2D, config: Dictionary) -> Vector2:
	var spawn_pos = player.global_position + config["spawn_offset"]

	# Проверяем пересечение с землей
	var space = get_tree().get_current_scene().get_world_2d().direct_space_state
	if space:
		var from = player.global_position + Vector2(0, -8)
		var to = from + Vector2(0, 128)
		var params = PhysicsRayQueryParameters2D.new()
		params.from = from
		params.to = to
		params.exclude = [player]
		var res = space.intersect_ray(params)
		if res and res.has("position"):
			spawn_pos.y = float(res["position"].y) - 4.0

	spawn_pos.y -= config["spawn_y_lift"]
	return spawn_pos

## Деспавнит конкретный предмет по id
func despawn_equip(equip_id: String) -> void:
	despawn_item(equip_id)

## Спавнит предмет по active_equip_id при resume
func spawn_active(p_player: CharacterBody2D, p_parent: Node2D) -> void:
	spawn_item(Globals.active_equip_id, p_player, p_parent)

## Полный сброс инвентаря при старте нового уровня
func reset_for_level(equip_id_to_remove: String) -> void:
	despawn_equip(equip_id_to_remove)

## Универсальная выгрузка активного предмета
func unload_active(p_player: Node, unload_ctrl: Node, flip: bool = false) -> int:
	# Тачка живёт в сцене уровня — ищем её напрямую.
	var wb := get_tree().root.find_child("Wheel", true, false) if get_tree() else null
	if wb and wb.has_method("start_unload"):
		var res = await wb.start_unload(p_player, unload_ctrl, flip)
		if typeof(res) == TYPE_INT:
			return res
	# Спавнуемые предметы (bucket и др.)
	var equip_id = Globals.active_equip_id
	if _item_instances.has(equip_id) and is_instance_valid(_item_instances[equip_id]):
		var item_instance = _item_instances[equip_id]
		if item_instance.has_method("start_unload"):
			var res = await item_instance.start_unload(p_player, unload_ctrl, flip)
			if typeof(res) == TYPE_INT:
				return res
	return 0
