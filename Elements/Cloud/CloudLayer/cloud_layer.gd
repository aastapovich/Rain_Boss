extends Node2D
class_name CloudLayer

## Менеджер пула облаков — независимый слой.
## Активная зона = камера + 1 чанк слева + 1 чанк справа (3 чанка = 3840px при 1280px viewport).

const CLOUD_ENTITY_SCENE    = preload("res://Elements/Cloud/CloudEntity/cloud_entity.tscn")
const RAIN_MANAGER_SCRIPT   = preload("res://Elements/Enemy/Rain/rain_manager.gd")

const _DEFAULT_SIMPLE = preload("res://Elements/Cloud/CloudConfig/configs/cloud_simple.tres")
const _DEFAULT_RAIN   = preload("res://Elements/Cloud/CloudConfig/configs/cloud_rain.tres")
const _DEFAULT_STORM  = preload("res://Elements/Cloud/CloudConfig/configs/cloud_storm.tres")

# --- Настройки ---

## Число облаков в пуле
@export var cloud_count: int = 8

## Начальные конфиги облаков (назначаются случайно при спавне)
@export var initial_configs: Array[CloudConfig] = []

## Ширина одного чанка (px). Должна совпадать с шириной viewport (1280).
## Активная зона = камера + 1 чанк слева + 1 чанк справа = 3 чанка.
@export var chunk_width: float = 1280.0

## Минимальный Y при спавне/ресайкле
@export var y_min: float = 50.0

## Максимальный Y при спавне/ресайкле
@export var y_max: float = 120.0

# --- Конфигурация дождя ---

## Таблица типов капель для этого уровня.
## Пустой список — RainManager использует дефолты (97% вода, 2% золото, 1% жизнь).
## Чтобы настроить: создай массив RainDropEntry-ресурсов и назначь здесь.
@export var rain_config: Array = []

## Максимум одновременных капель на экране (передаётся в RainManager).
@export var rain_max_drops: int = 25

## Глобальный множитель частоты дождя (1.0 = норма, 2.0 = двойной дождь).
@export_range(0.5, 5.0) var rain_rate_multiplier: float = 1.0

# --- Внутренние ---
var _clouds: Array[CloudEntity] = []
var _next_id: int = 0

func _ready() -> void:
	if initial_configs.is_empty():
		initial_configs = [
			_DEFAULT_SIMPLE, _DEFAULT_SIMPLE, _DEFAULT_SIMPLE, _DEFAULT_SIMPLE,
			_DEFAULT_RAIN,   _DEFAULT_RAIN,
			_DEFAULT_STORM,  _DEFAULT_STORM,
		]
	_setup_rain_manager()
	# Ждём один кадр — камера регистрируется в viewport не сразу при _ready()
	await get_tree().process_frame
	_spawn_initial_clouds()

func _setup_rain_manager() -> void:
	var rain_mgr := Node.new()
	rain_mgr.name = "RainManager"
	rain_mgr.set_script(RAIN_MANAGER_SCRIPT)
	add_child(rain_mgr)
	# Применяем конфигурацию уровня (если задана)
	if not rain_config.is_empty() or rain_max_drops != 25 or rain_rate_multiplier != 1.0:
		rain_mgr.call("apply_config", rain_config, rain_max_drops, rain_rate_multiplier)

## Возвращает (left_edge, right_edge) активной зоны: камера + 1 чанк с каждой стороны.
func _get_active_bounds() -> Vector2:
	var cam = get_viewport().get_camera_2d()
	var cam_x: float = cam.global_position.x if cam else get_viewport_rect().size.x * 0.5
	var half_vp: float = get_viewport_rect().size.x * 0.5
	return Vector2(cam_x - half_vp - chunk_width, cam_x + half_vp + chunk_width)

func _spawn_initial_clouds() -> void:
	if initial_configs.is_empty():
		push_warning("CloudLayer: initial_configs пуст — облака не создаются.")
		return

	var bounds: Vector2 = _get_active_bounds()
	var zone_width: float = bounds.y - bounds.x  # = 3 * chunk_width

	for i in range(cloud_count):
		var cfg = initial_configs[randi() % initial_configs.size()]
		var entity: CloudEntity = CLOUD_ENTITY_SCENE.instantiate()
		add_child(entity)

		# Равномерное распределение по всей активной зоне с рандомом внутри слота
		var slot_w: float = zone_width / cloud_count
		var px: float = bounds.x + slot_w * i + randf_range(0.0, slot_w)
		var py: float = randf_range(y_min, y_max)

		entity.setup(_next_id, cfg)
		entity.position = Vector2(px, py)
		_next_id += 1
		_clouds.append(entity)

## Каждый кадр: перемещает облака вышедшие за границы активной зоны на противоположный край.
func _process(_delta: float) -> void:
	var cam = get_viewport().get_camera_2d()
	if cam == null:
		return

	var bounds: Vector2 = _get_active_bounds()

	for cloud in _clouds:
		var cx: float = cloud.global_position.x

		# Облако вышло за правый край активной зоны — ресайкл за левый
		if cx > bounds.y:
			_recycle_cloud(cloud, Vector2(bounds.x + randf_range(0.0, chunk_width * 0.5), randf_range(y_min, y_max)))

		# Облако вышло за левый край активной зоны — ресайкл за правый
		elif cx < bounds.x:
			_recycle_cloud(cloud, Vector2(bounds.y - randf_range(0.0, chunk_width * 0.5), randf_range(y_min, y_max)))

## Сбрасывает позицию и конфиг облака (повторное использование без уничтожения).
func _recycle_cloud(cloud: CloudEntity, new_pos: Vector2) -> void:
	var cfg = initial_configs[randi() % initial_configs.size()]
	cloud.recycle(new_pos, cfg)
