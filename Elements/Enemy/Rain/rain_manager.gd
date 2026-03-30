extends Node

## Менеджер дождя — непрерывный спавн капель под каждым активным облаком.
## Получает позиции и параметры через Events.cloud_state_changed.
## Набор типов капель и их вероятности задаются через drop_entries (таблица весов).

# --- Fallback-сцены (drip_at и дефолтная таблица) ---
const RAIN_WATER   = preload("res://Elements/Enemy/Rain/Rain_water.tscn")
const RAIN_GOLD    = preload("res://Elements/Enemy/Rain/Rain_gold.tscn")
const RAIN_LIVE    = preload("res://Elements/Enemy/Rain/Rain_live.tscn")
const RAIN_GEMS = preload("res://Elements/Enemy/Rain/Rain_gems.tscn")
const AMBIENT_RAIN = preload("res://Elements/Enemy/Rain/Rain_animate.tscn")

const _RainDropEntry = preload("res://Elements/Enemy/Rain/rain_drop_entry.gd")

# --- Таблица типов капель ---

# Список типов капель с весами для случайного выбора.
## Пустой список — авто-заполнение дефолтами: 97% вода, 2% золото, 1% жизнь.
## Настраивается через CloudLayer.rain_config (.tres-ресурс на каждый уровень).
@export var drop_entries: Array = []

# --- Настройки спавна ---

## Максимум одновременных капель на экране (защита от перегрузки).
@export var max_active_drops: int = 25

## Глобальный множитель частоты выпадения (нарастание сложности).
@export_range(0.5, 5.0) var global_rate_multiplier: float = 1.0

# --- Внутренние ---
# Словарь: cloud_id → {pos, type, drops_per_sec, spread_x, accumulator}
var _cloud_data: Dictionary = {}
var _active_drops: int = 0
var _drop_parent: Node = null

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	if drop_entries.is_empty():
		_fill_default_entries()
	Events.cloud_state_changed.connect(_on_cloud_state_changed)
	Events.drip_at.connect(_on_drip_at)
	_drop_parent = get_tree().current_scene
	add_child(AMBIENT_RAIN.instantiate())

## Применить конфигурацию дождя динамически (вызывается CloudLayer после создания).
## entries: таблица капель; передай [] чтобы оставить текущую без изменений.
func apply_config(entries: Array, max_drops: int = 25, rate_mult: float = 1.0) -> void:
	if not entries.is_empty():
		drop_entries = entries
	max_active_drops = max_drops
	global_rate_multiplier = rate_mult

## Заполняет дефолтную таблицу: 95-97% вода, 2-3% золото, 1-2% жизнь, 1% кристаллы.
func _fill_default_entries() -> void:
	var water := _RainDropEntry.new()
	water.scene  = RAIN_WATER
	water.weight = 88.0

	var gold := _RainDropEntry.new()
	gold.scene  = RAIN_GOLD
	gold.weight = 1.0

	var life := _RainDropEntry.new()
	life.scene  = RAIN_LIVE
	life.weight = 1.0

	var gems := _RainDropEntry.new()
	gems.scene  = RAIN_GEMS
	gems.weight = 10.0

	# Порядок: 0=water, 1=gold, 2=life, 3=gems
	drop_entries = [water, gold, life, gems]
func _on_cloud_state_changed(cloud_id: int, pos: Vector2, cloud_type: int, drops_per_sec: float, spread_x: float) -> void:
	if not _cloud_data.has(cloud_id):
		_cloud_data[cloud_id] = {
			"pos": pos,
			"type": cloud_type,
			"drops_per_sec": drops_per_sec,
			"spread_x": spread_x,
			"accumulator": randf()  # случайный сдвиг фазы — облака не синхронизируются
		}
	else:
		_cloud_data[cloud_id]["pos"]          = pos
		_cloud_data[cloud_id]["type"]         = cloud_type
		_cloud_data[cloud_id]["drops_per_sec"]= drops_per_sec
		_cloud_data[cloud_id]["spread_x"]     = spread_x

## Каждый кадр: накапливает аккумуляторы и спавнит капли в пределах лимита.
func _process(delta: float) -> void:
	if _active_drops >= max_active_drops:
		return

	for cloud_id in _cloud_data.keys():
		var data = _cloud_data[cloud_id]

		if data["type"] == CloudConfig.CloudType.SIMPLE:
			data["accumulator"] = 0.0
			continue

		data["accumulator"] += data["drops_per_sec"] * global_rate_multiplier * delta

		while data["accumulator"] >= 1.0 and _active_drops < max_active_drops:
			data["accumulator"] -= 1.0
			_spawn_drop_at(data["pos"], data["spread_x"], data["type"])

## Создаёт одну каплю в случайной позиции под облаком.
func _spawn_drop_at(cloud_pos: Vector2, spread_x: float, cloud_type: int) -> void:
	var drop := _pick_drop()
	var spawn_pos := cloud_pos + Vector2(
		randf_range(-spread_x, spread_x),
		randf_range(10.0, 25.0)
	)
	if _drop_parent == null:
		_drop_parent = get_tree().current_scene
	_drop_parent.add_child(drop)
	drop.global_position = spawn_pos
	_active_drops += 1
	if drop.has_signal("tree_exited"):
		drop.tree_exited.connect(_on_drop_removed)
	if cloud_type == CloudConfig.CloudType.STORM and randf() < 0.03:
		Events.lightning_warning.emit(cloud_pos)

## Спавнит одиночную каплю из произвольной мировой точки (ветка, карниз).
## drop_type: 0=вода, 1=золото, 2=жизнь (индекс дефолтной таблицы).
func _on_drip_at(pos: Vector2, drop_type: int) -> void:
	if _active_drops >= max_active_drops:
		return
	# Берём из drop_entries по индексу, иначе fallback на константные сцены
	var drop: Node
	if drop_type >= 0 and drop_type < drop_entries.size() and drop_entries[drop_type].enabled:
		drop = drop_entries[drop_type].scene.instantiate()
	else:
		match drop_type:
			1: drop = RAIN_GOLD.instantiate()
			2: drop = RAIN_LIVE.instantiate()
			3: drop = RAIN_GEMS.instantiate()
			_: drop = RAIN_WATER.instantiate()
	if _drop_parent == null:
		_drop_parent = get_tree().current_scene
	_drop_parent.add_child(drop)
	drop.global_position = pos
	_active_drops += 1
	if drop.has_signal("tree_exited"):
		drop.tree_exited.connect(_on_drop_removed)

func _on_drop_removed() -> void:
	_active_drops = maxi(_active_drops - 1, 0)

# ─── Выбор типа капли ─────────────────────────────────────────────────────────

## Взвешенный случайный выбор из активных записей drop_entries.
## Чем больше weight — тем чаще выпадает этот тип.
func _pick_drop() -> Node:
	var total_weight := 0.0
	for e in drop_entries:
		if e.enabled and e.scene != null:
			total_weight += e.weight

	if total_weight <= 0.0:
		return RAIN_WATER.instantiate()

	var roll := randf() * total_weight
	var cumulative := 0.0
	for e in drop_entries:
		if not e.enabled or e.scene == null:
			continue
		cumulative += e.weight
		if roll <= cumulative:
			return e.scene.instantiate()

	# Страховка: последний активный
	for i in range(drop_entries.size() - 1, -1, -1):
		if drop_entries[i].enabled and drop_entries[i].scene != null:
			return drop_entries[i].scene.instantiate()
	return RAIN_WATER.instantiate()
