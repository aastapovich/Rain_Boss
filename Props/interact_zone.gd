## InteractZone — универсальная зона взаимодействия.
## Используется для знаков, лута, подсказок — любых точечных событий на карте.
## Настраивается через @export в Инспекторе, не требует отдельных скриптов.
##
## Использование:
##   1. Добавь инстанс interact_zone.tscn в сцену уровня.
##   2. Задай параметры в Инспекторе.
##   3. Для "info": InfoPopup слушает Events.interact_triggered и показывает текст.
##   4. Для "loot"/"custom": подпишись на Events.interact_triggered в нужном скрипте.
class_name InteractZone
extends Area2D

@export_group("Interaction")
## Тип взаимодействия: "info" — информационный попап, "loot" — лут, "custom" — произвольный.
@export var interact_type: String = "info"
## Текст подсказки над зоной (например "↑ Осмотреть").
@export var hint_text: String = "↑ Осмотреть"
## Название для InfoPopup (заголовок).
@export var popup_title: String = ""
## Описание для InfoPopup (поддерживает BBCode).
@export var popup_text: String = ""

@export_group("Animation")
## Имя анимации на AnimatedSprite2D игрока перед показом попапа. "" = без анимации.
@export var player_anim: String = "rotate"

@export_group("Behaviour")
## Если true — зона срабатывает только один раз за сессию уровня.
@export var one_shot: bool = true

# ── Внутреннее состояние ──────────────────────────────────────────────────────
var _player: CharacterBody2D = null
var _in_zone: bool = false
var _triggered: bool = false  ## Сработала ли зона (для one_shot)
var _is_busy: bool = false    ## Блокировка во время анимации

@onready var _hint_label: Label = $HintLabel

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	Events.interact_closed.connect(_on_interact_closed)
	_hint_label.text = hint_text
	_hint_label.visible = false

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player = body as CharacterBody2D
	_in_zone = true
	if not (one_shot and _triggered):
		_hint_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_in_zone = false
	# Не обнуляем _player если анимация/попап ещё активны — он нужен для restore state.
	if not _is_busy:
		_player = null
	_hint_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not _in_zone or not _player:
		return
	if one_shot and _triggered:
		return
	if _is_busy:
		return
	if event.is_action_pressed("Up"):
		get_viewport().set_input_as_handled()
		_trigger()

## Запускает взаимодействие: анимация (если задана) → emit Events.interact_triggered.
func _trigger() -> void:
	_is_busy = true
	_hint_label.visible = false

	if player_anim != "" and is_instance_valid(_player):
		_player.state = PlayerBase.State.USE_TOOL
		var anim: AnimatedSprite2D = _player.get_node("Anim_Player")
		anim.play(player_anim)
		await anim.animation_finished

	if one_shot:
		_triggered = true

	Events.interact_triggered.emit(interact_type, popup_title, popup_text)

## Вызывается когда InfoPopup закрыт — восстанавливает состояние игрока.
func _on_interact_closed() -> void:
	if not _is_busy:
		return
	if is_instance_valid(_player) and player_anim != "":
		var anim: AnimatedSprite2D = _player.get_node("Anim_Player")
		anim.play_backwards(player_anim)
		await anim.animation_finished
		_player.state = PlayerBase.State.MOVE
	elif is_instance_valid(_player):
		_player.state = PlayerBase.State.MOVE
	_is_busy = false
	# Если игрок вышел из зоны пока попап был открыт — теперь безопасно обнулить
	if not _in_zone:
		_player = null
	# Показать подсказку снова если не one_shot и игрок ещё в зоне
	if _in_zone and not (one_shot and _triggered):
		_hint_label.visible = true
