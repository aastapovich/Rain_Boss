## Капельница — вешается на любой узел сцены (ветка, крыша, карниз).
## Каждый кадр эмитирует Events.cloud_state_changed с позицией этого узла,
## что заставляет RainManager спавнить капли прямо здесь (через стандартный аккумулятор).
##
## Использование:
##   1. Добавь Node2D в нужное место сцены.
##   2. Назначь скрипт drip_emitter.gd.
##   3. Настрой drops_per_second, spread_x и drop_type в инспекторе.
extends Node2D

@export_group("Drip Settings")

## Капель в секунду (0.01 — редкие, 1.0 — частые).
@export_range(0.01, 5.0) var drops_per_second: float = 0.5

## Горизонтальный разброс (пиксели).
@export_range(0.0, 100.0) var spread_x: float = 0.0

## Тип облака: 1 = RAIN (вода, редкое золото/жизнь по шансу),
##             2 = STORM (вода + молния + повышенный шанс спецкапель)
@export_range(1, 2) var cloud_type: int = 1

## Позволяет временно отключить эмиттер без удаления из сцены.
@export var active: bool = true

func _process(_delta: float) -> void:
	if not active:
		return
	# Используем cloud_state_changed: RainManager сам накапливает аккумулятор
	# и спавнит нужное количество капель в нужный момент.
	# get_instance_id() гарантирует уникальный cloud_id для каждого эмиттера.
	Events.cloud_state_changed.emit(
		get_instance_id(),
		global_position,
		cloud_type,
		drops_per_second,
		spread_x
	)
