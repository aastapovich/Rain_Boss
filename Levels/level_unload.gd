## Контроллер выгрузки тачки для уровня.
## Живёт в ноде Unload уровня, работает с новой тачкой Wheel (CharacterBody2D).
extends Node

signal unload_finished

var is_active: bool = false

@export var tip_angle: float = PI * 0.25
@export var tip_duration: float = 0.8
@export var return_duration: float = 1.2

var _anim_player: AnimatedSprite2D
var _dump_pivot: Node2D
var _water_sprite: AnimatedSprite2D

## Принимает анимированный спрайт игрока и узел тачки (Wheel).
## Узлы тачки извлекаются автоматически.
func setup(anim_player: AnimatedSprite2D, wheel_node: Node = null) -> void:
	_anim_player  = anim_player
	if wheel_node:
		_dump_pivot   = wheel_node.get_node_or_null("Visual")
		_water_sprite = wheel_node.get_node_or_null("Visual/AnimatedSprite2D")

func start(flip_h: bool) -> void:
	if is_active:
		return
	var water := Globals.point_wheelbarrow
	if water <= 0:
		return

	is_active = true

	if _anim_player:
		_anim_player.frame  = 0
		_anim_player.flip_h = flip_h
		_anim_player.play("dump_up")

	# Наклон кузова тачки.
	if _dump_pivot:
		_dump_pivot.rotation = 0.0
		var tween_tip := _dump_pivot.create_tween()
		tween_tip.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween_tip.tween_property(_dump_pivot, "rotation",
				-tip_angle if flip_h else tip_angle, tip_duration)
		await tween_tip.finished
	else:
		await get_tree().create_timer(tip_duration).timeout

	# Сбрасываем воду и обновляем счёт.
	Globals.change_point_wheelbarrow(-water)
	Globals.change_points(water)

	# Анимация выливания воды в кузове.
	if _water_sprite:
		_water_sprite.play("Whell_10")

	if _anim_player:
		_anim_player.play("dump_down")

	# Возврат кузова в исходное положение.
	if _dump_pivot:
		var tween_back := _dump_pivot.create_tween()
		tween_back.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween_back.tween_property(_dump_pivot, "rotation", 0.0, return_duration)
		await tween_back.finished
	else:
		await get_tree().create_timer(return_duration).timeout

	await get_tree().create_timer(0.3).timeout

	if _anim_player:
		_anim_player.play("stand")

	is_active = false
	unload_finished.emit()
