## ShopZone — зона взаимодействия у жилища игрока (дом, палатка, башня и т.п.).
## Когда игрок входит в зону и нажимает Up/W, герой проигрывает анимацию rotate,
## после чего открывается экран магазина через Events.shop_opened.
## Закрытие магазина (Events.shop_closed) проигрывает анимацию обратно.
extends Area2D

@onready var hint_label: Label = $HintLabel

var _player: CharacterBody2D = null
var _in_zone: bool = false
var _is_entering: bool = false  ## Блокирует повторный вход пока идёт анимация

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	Events.shop_closed.connect(_on_shop_closed)
	hint_label.visible = false

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player = body
	_in_zone = true
	hint_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_in_zone = false
	_player = null
	hint_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not _in_zone or not _player:
		return
	if event.is_action_pressed("Up"):
		get_viewport().set_input_as_handled()
		_enter_shop()

func _enter_shop() -> void:
	if _is_entering:
		return
	_is_entering = true
	hint_label.visible = false
	var p := _player
	if not is_instance_valid(p):
		_is_entering = false
		return
	p.state = PlayerBase.State.USE_TOOL
	var anim: AnimatedSprite2D = p.get_node("Anim_Player")
	anim.play("rotate")
	await anim.animation_finished
	Events.shop_opened.emit()

func _on_shop_closed() -> void:
	var p := _player
	if not is_instance_valid(p):
		_is_entering = false
		return
	var anim: AnimatedSprite2D = p.get_node("Anim_Player")
	anim.play_backwards("rotate")
	await anim.animation_finished
	if is_instance_valid(p):
		p.state = PlayerBase.State.MOVE
	_is_entering = false
	if _in_zone:
		hint_label.visible = true
