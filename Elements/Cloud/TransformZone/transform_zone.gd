extends Area2D
class_name TransformZone

## Зона трансформации облаков.
## Размещается на уровне как Area2D-полоса. Каждая зона полностью независима.
## Облако, войдя в зону, трансформируется в target_config — если выполнены условия.

# --- Настройки (в инспекторе) ---

## Конфиг, в который превратится облако при входе в зону
@export var target_config: CloudConfig = null

## Минимальный счёт для срабатывания трансформации (0 = всегда)
@export var min_score: int = 0

## Периодическая повторная проверка облаков внутри зоны (сек). 0 = выкл.
## Полезно для облаков, которые уже были в зоне до выполнения условий.
@export var periodic_interval: float = 0.0

# --- Внутренние ---
var _timer: Timer = null

func _ready() -> void:
	area_entered.connect(_on_area_entered)

	if periodic_interval > 0.0:
		_timer = Timer.new()
		_timer.wait_time = periodic_interval
		_timer.timeout.connect(_check_overlapping_clouds)
		add_child(_timer)
		_timer.start()

func _on_area_entered(area: Area2D) -> void:
	if not area is CloudEntity:
		return
	_try_transform(area as CloudEntity)

func _try_transform(cloud: CloudEntity) -> void:
	if target_config == null:
		return
	if Globals.points < min_score:
		return
	cloud.start_transform(target_config)

func _check_overlapping_clouds() -> void:
	## Периодически обрабатывает все облака, уже находящиеся внутри зоны.
	## Нужно для случая, когда условие (min_score) выполнилось после входа облака.
	for area in get_overlapping_areas():
		if area is CloudEntity:
			_try_transform(area as CloudEntity)
