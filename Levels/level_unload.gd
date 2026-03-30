## Контроллер выгрузки тачки для уровня.
## Перемещён из Player — теперь живёт в ноде Unload уровня.
extends Node

signal unload_finished

var is_active: bool = false

@export var tip_angle: float = PI * 0.25
@export var tip_duration: float = 0.8
@export var return_duration: float = 1.2
@export var push_distance: float = 10.0

var _anim_player: AnimatedSprite2D
var _wheelbarrow_animate: AnimatedSprite2D
var _dump_pivot: Node2D
var _wheelbarrow_root: Node2D

var _orig_wheelbarrow_pos: Vector2

func setup(anim_player: AnimatedSprite2D, wheelbarrow_animate: AnimatedSprite2D, dump_pivot: Node2D = null, wheelbarrow_root: Node2D = null):
	_anim_player            = anim_player
	_wheelbarrow_animate   = wheelbarrow_animate
	_dump_pivot             = dump_pivot
	_wheelbarrow_root      = wheelbarrow_root

func start(flip_h: bool) -> void:
	if is_active:
		return
	var water = Globals.point_wheelbarrow
	if water <= 0:
		return

	is_active = true

	if _anim_player:
		_anim_player.frame  = 0
		_anim_player.flip_h = flip_h
		_anim_player.play("dump_up")

	var tween_tip: Tween = null
	if _dump_pivot:
		_dump_pivot.rotation = 0.0
		tween_tip = _dump_pivot.create_tween()
		tween_tip.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween_tip.tween_property(_dump_pivot, "rotation", tip_angle, tip_duration)
	if _wheelbarrow_root:
		_orig_wheelbarrow_pos = _wheelbarrow_root.position
		var dir_x = -1.0 if flip_h else 1.0
		var target_pos = _orig_wheelbarrow_pos + Vector2(push_distance * dir_x, 0.0)
		var tween_push = _wheelbarrow_root.create_tween()
		tween_push.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween_push.tween_property(_wheelbarrow_root, "position", target_pos, 0.4)

	if tween_tip:
		await tween_tip.finished
	else:
		await get_tree().create_timer(tip_duration).timeout

	Globals.change_point_wheelbarrow(-water)
	Globals.change_points(water)
	if _wheelbarrow_animate:
		_wheelbarrow_animate.play("Whell_10")
	if _anim_player:
		_anim_player.play("dump_down")

	if _wheelbarrow_root:
		var tween_back_w = _wheelbarrow_root.create_tween()
		tween_back_w.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween_back_w.tween_property(_wheelbarrow_root, "position", _orig_wheelbarrow_pos, 0.4)
	if _dump_pivot:
		var tween_back = _dump_pivot.create_tween()
		tween_back.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween_back.tween_property(_dump_pivot, "rotation", 0.0, return_duration)
		await tween_back.finished

	await get_tree().create_timer(0.3).timeout

	if _anim_player:
		_anim_player.play("stand")

	is_active = false
	unload_finished.emit()
