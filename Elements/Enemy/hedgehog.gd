## Ёжик — extends BaseEnemy.
## FOLLOWER (AIType.AGGRESSIVE): преследует, атакует при сближении, отступает после удара.
## THIEF (AIType.THIEF): подкрадывается только при наполненной тачке, крадёт воду процентом.
## Конфигурация задаётся через .tres (hedgehog_follower / hedgehog_thief).
## Обратная совместимость: stop_point.gd вызывает initialize(type, player) — поддерживается.
extends BaseEnemy
class_name Hedgehog

const SPLASH_SCENE := preload("res://Elements/Enemy/Rain/rain_splash.tscn")

## Пути к конфигам для обратной совместимости с initialize(type, player).
const _CONFIG_PATHS: Array[String] = [
	"res://Elements/Enemy/configs/hedgehog_follower.tres",
	"res://Elements/Enemy/configs/hedgehog_thief.tres",
]

func _ready() -> void:
	# enemy_data может быть null если используется initialize() — BaseEnemy._ready()
	# вызовется через _do_init() после установки данных.
	if enemy_data:
		_do_init()

## Обратная совместимость: stop_point.gd передаёт (0=FOLLOWER, 1=THIEF, player).
func initialize(type: int, player_node: CharacterBody2D) -> void:
	enemy_data = load(_CONFIG_PATHS[clamp(type, 0, _CONFIG_PATHS.size() - 1)])
	player = player_node
	_do_init()
	if player_node:
		var offset := enemy_data.spawn_position_offset if enemy_data else Vector2(-300, 0)
		global_position = player_node.global_position + offset

## Спавн со стороны знака: враг появляется между знаком и игроком.
## sign_pos — мировая позиция знака, offset_dist — на сколько px ближе к игроку.
func initialize_at(type: int, player_node: CharacterBody2D, sign_pos: Vector2, offset_dist: float = 200.0) -> void:
	enemy_data = load(_CONFIG_PATHS[clamp(type, 0, _CONFIG_PATHS.size() - 1)])
	player = player_node
	_do_init()
	if player_node:
		# Направление: от знака к игроку
		var dir: float = sign(player_node.global_position.x - sign_pos.x)
		# Появляемся у знака, немного со стороны игрока
		global_position = Vector2(sign_pos.x + dir * offset_dist, sign_pos.y)

## Запускает инициализацию BaseEnemy (вызывается из _ready или initialize).
func _do_init() -> void:
	_initialize_from_data()
	_setup_components()
	_find_player()
	add_to_group("enemies")
	add_to_group(enemy_data.enemy_id)
	add_to_group("hedgehogs")
	_play_spawn_effects()
	gravity = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

## Для THIEF: динамически обновляет скорость по жадности (зависит от заполнения тачки).
func _custom_behavior(_delta: float) -> void:
	if enemy_data and enemy_data.ai_type == EnemyData.AIType.THIEF:
		var fill_pct := Globals.get_wheelbarrow_percent()
		current_speed = enemy_data.get_random_speed() * (0.5 + fill_pct * 1.5)

## Переопределение: процентная кража воды + брызги + плавающий текст.
func _steal_water() -> void:
	if not player:
		return
	var water := Globals.point_wheelbarrow
	if water <= 0:
		if enemy_data and enemy_data.flee_if_no_water:
			despawn()
		return
	var fill_pct := Globals.get_wheelbarrow_percent()
	var amount: int = max(1, int(water * (0.10 + fill_pct * 0.15) * current_aggression))
	amount = min(amount, water)
	if player.has_method("apply_wheelbarrow_damage"):
		var inv: Node = null
		if get_tree():
			inv = get_tree().get_root().get_node_or_null("Game/Progression/InventorySystem")
		if inv and inv.has_method("apply_wheelbarrow_damage"):
			inv.apply_wheelbarrow_damage(player, amount, "steal")
		elif player.has_method("apply_wheelbarrow_damage"):
			player.apply_wheelbarrow_damage(amount, "steal")
		else:
			Globals.change_point_wheelbarrow(-amount)
	water_stolen.emit(float(amount), self)
	_spawn_splash(global_position + Vector2(0, -20))
	_show_damage_label(amount)

## Переопределение: урон здоровью + процентный урон тачке + брызги.
func _deal_damage() -> void:
	if not player:
		return
	if player.has_method("take_damage"):
		player.take_damage(int(10.0 * current_aggression))
	var water := Globals.point_wheelbarrow
	if water > 0:
		var fill_pct := Globals.get_wheelbarrow_percent()
		var dmg: int = max(1, int(water * (0.05 + fill_pct * 0.10) * current_aggression))
		var inv2: Node = null
		if get_tree():
			inv2 = get_tree().get_root().get_node_or_null("Game/Progression/InventorySystem")
		if inv2 and inv2.has_method("apply_wheelbarrow_damage"):
			inv2.apply_wheelbarrow_damage(player, dmg, "hedgehog_attack")
		elif player.has_method("apply_wheelbarrow_damage"):
			player.apply_wheelbarrow_damage(dmg, "hedgehog_attack")
		else:
			Globals.change_point_wheelbarrow(-dmg)
		_spawn_splash(global_position + Vector2(0, -20))
		_show_damage_label(dmg)
	player_damaged.emit(float(10.0 * current_aggression), self)

func _spawn_splash(pos: Vector2) -> void:
	var splash := SPLASH_SCENE.instantiate()
	get_tree().current_scene.add_child(splash)
	splash.global_position = pos

## Плавающий текст «-N л» над ёжиком.
func _show_damage_label(amount: int) -> void:
	var label := Label.new()
	label.text = "-%d л" % amount
	label.modulate = Color(1.0, 0.3, 0.3)
	label.add_theme_font_size_override("font_size", 24)
	label.z_index = 100
	get_tree().root.add_child(label)
	label.global_position = global_position + Vector2(-20, -40)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 50, 1.5)
	tween.tween_property(label, "modulate:a", 0.0, 1.5)
	tween.chain().tween_callback(label.queue_free)
