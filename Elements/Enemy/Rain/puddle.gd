extends Area2D
class_name Puddle

## Лужа-враг, замедляющая игрока на %

const SPEED_REDUCTION: float = 0.75  # % от обычной скорости
const PUDDLE_EFFECT = preload("res://Elements/Enemy/Rain/puddle_effect.tscn")

@export var lifetime_min: float = 8.0  ## Минимальное время жизни
@export var lifetime_max: float = 12.0  ## Максимальное время жизни

var affected_players: Array = []
var visual: AnimatedSprite2D

## Создаёт коллизию, визуализацию и запускает таймер самоудаления.
func _ready():
	# Настраиваем коллизию
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 25.0
	collision.shape = shape
	add_child(collision)
	
	# z_index чтобы лужа была видна поверх земли
	z_index = 1
	
	# Настраиваем визуал
	setup_visual()
	
	# Слои коллизий
	collision_layer = 0
	collision_mask = 1  # Обнаруживает игрока
	
	# Подключаем сигналы
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Таймер удаления
	var lifetime = randf_range(lifetime_min, lifetime_max)
	await get_tree().create_timer(lifetime).timeout
	_despawn()

## Настройка визуализации лужи
func setup_visual():
	visual = PUDDLE_EFFECT.instantiate()
	visual.name = "Visual"
	visual.z_index = 1
	visual.position.y = 8
	add_child(visual)

	# Проигрываем анимацию появления
	if visual.sprite_frames and visual.sprite_frames.has_animation("puddle_on"):
		visual.play("puddle_on")
		await visual.animation_finished

	# Переходим к статичной анимации
	if visual.sprite_frames and visual.sprite_frames.has_animation("puddle"):
		visual.play("puddle")

## Удаление лужи с анимацией исчезновения
func _despawn():
	# Убираем эффект со всех игроков
	for player in affected_players.duplicate():
		_remove_slow(player)
	
	# Анимация исчезновения
	if visual and visual.sprite_frames and visual.sprite_frames.has_animation("puddle_of"):
		visual.play("puddle_of")
		await visual.animation_finished
	
	queue_free()

## Игрок вошел в лужу
func _on_body_entered(body: Node):
	if body.is_in_group("player") and body not in affected_players:
		affected_players.append(body)
		_apply_slow(body)

## Игрок вышел из лужи
func _on_body_exited(body: Node):
	if body.is_in_group("player") and body in affected_players:
		affected_players.erase(body)
		_remove_slow(body)

## Применить замедление % от скорости
func _apply_slow(player: Node):
	if player.has_method("apply_puddle_slow"):
		player.apply_puddle_slow(SPEED_REDUCTION)

## Убрать замедление
func _remove_slow(player: Node):
	if player.has_method("remove_puddle_slow"):
		player.remove_puddle_slow()

## Очистка при удалении
func _exit_tree():
	for player in affected_players:
		if is_instance_valid(player):
			_remove_slow(player)
