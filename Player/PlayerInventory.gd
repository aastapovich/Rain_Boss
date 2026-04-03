# PlayerInventory.gd — управление инвентарём игрока (хотбар 0–4).
# Дочерний узел Player. Обрабатывает клавиши 0–4 и E (interact),
# обновляет UI-панель InventoryBar.
#
# АРХИТЕКТУРНЫЕ ОТЛИЧИЯ от прототипа 3d-rain:
#   - Player живёт в Game/Elements, уровень — в Game/LevelContent/Level01Content.
#     Поэтому _slots заполняются ЛЕНИВО через find_child(name, true, false),
#     что работает независимо от глубины иерархии.
#   - InventoryBar ищется через группу "inventory_bar" (не по имени узла).
#   - _find_items_and_setup() вызывается через call_deferred, чтобы сцена уровня
#     успела добавиться в дерево (она добавляется в том же кадре, что и Player).
extends Node

# ── Константы слотов ──────────────────────────────────────────────────────────
# Слот 0 зарезервирован под действие «положить». Слоты 1–4 — конкретные предметы.
const SLOT_COUNT = 5
const SLOT_LABELS = ["Пусто", "Тачка", "Ведро", "Бочка", "Лопата"]
# Имена узлов предметов в сцене уровня (пустая строка = слот 0).
const SLOT_NODE_NAMES = ["", "Wheel", "Bucket", "Barrel", "Shovel"]

# ── Состояние ─────────────────────────────────────────────────────────────────
# Предмет, который игрок держит прямо сейчас.
var held_item: Node = null
# Предмет, рядом с которым стоит игрок (последний вошедший в Area2D).
var nearby_item: Node = null

var _slots: Array = []        # ссылки на узлы предметов; индекс = номер слота
var _active_slot: int = 0     # номер выделенного слота в UI
var _slot_panels: Array = []  # Panel-узлы из InventoryBar
var _slot_labels_ui: Array = [] # Label-узлы внутри панелей

func _ready() -> void:
	# Деферируем поиск предметов: уровень добавляется в том же кадре, что и Player,
	# но чуть позже (после _load_level). Deferred запустится в конце кадра —
	# когда все add_child уже завершены.
	call_deferred("_find_items_and_setup")

# ── Поиск предметов и настройка UI ────────────────────────────────────────────
func _find_items_and_setup() -> void:
	_slots.clear()
	for nname in SLOT_NODE_NAMES:
		if nname == "":
			_slots.append(null)
		else:
			# find_child(name, recursive=true, owned=false) ищет во всём дереве,
			# включая .tscn-подсцены — работает при любой глубине вложенности.
			_slots.append(get_tree().root.find_child(nname, true, false))

	# Синхронизировать held_item с реальным состоянием предметов при старте
	# (например, Wheel уже может быть прикреплена к игроку из save-state).
	for i in _slots.size():
		var item = _slots[i]
		if item == null:
			continue
		var attached = item.get("is_attached")
		var carrier  = item.get("_carrier")
		if (attached != null and bool(attached)) or (carrier != null):
			held_item    = item
			_active_slot = i
			break

	_setup_ui()

# ── Повторная инициализация при смене уровня ──────────────────────────────────
# Вызывать извне (game.gd или level script) после загрузки нового уровня.
func reinit_for_level() -> void:
	held_item    = null
	nearby_item  = null
	_active_slot = 0
	call_deferred("_find_items_and_setup")

# ── Обработка ввода ───────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	if event.is_action("interact"):
		_try_interact()
		return
	# Клавиши 0–4 выбирают слоты.
	for i in SLOT_COUNT:
		if event.is_action(str(i)):
			_select_slot(i)
			return

# ── Взаимодействие клавишей E ─────────────────────────────────────────────────
# Повторное E на удерживаемом предмете — положить.
# Первое E рядом со свободным предметом — подобрать.
func _try_interact() -> void:
	if held_item != null and nearby_item == held_item:
		_drop_held()
		return
	if nearby_item == null:
		return
	if not nearby_item.has_method("can_pickup") or not nearby_item.can_pickup():
		return
	# Нельзя подобрать новый предмет, пока в руках carriable (сначала клавиша 0).
	if held_item != null and held_item.get("item_type") == "carriable":
		return
	_do_pickup(nearby_item)

# ── Выбор слота клавишами 0–4 ─────────────────────────────────────────────────
# 0 — всегда кладёт/убирает текущий предмет.
# 1–4 — берёт предмет напрямую по номеру слота.
func _select_slot(idx: int) -> void:
	if idx == 0:
		_drop_held()
		return

	if idx >= SLOT_COUNT or _slots[idx] == null:
		# Предмет ещё не заспавнен на уровне — переинициализировать и попробовать ещё раз.
		call_deferred("_find_items_and_setup")
		return

	var item = _slots[idx]

	# Предмет скрыт (item_visible = false, убран в инвентарь) → достать и взять.
	if not item.visible:
		if held_item != null and held_item.get("item_type") == "carriable":
			return
		_drop_held()
		# Появляется чуть правее игрока, затем сразу берётся в руки.
		item.call("restore", get_parent().global_position + Vector2(60, 0))
		item.call("pickup", get_parent() as CharacterBody2D)
		held_item    = item
		_active_slot = idx
		_update_ui()
		return

	# Предмет уже в руках → toggle: положить.
	if held_item == item:
		_drop_held()
		return

	# Предмет виден на сцене, не в руках → взять напрямую без необходимости стоять рядом.
	if held_item != null and held_item.get("item_type") == "carriable":
		return  # сначала положи текущий carriable (клавиша 0)
	_do_pickup(item)

# ── Внутренние методы ─────────────────────────────────────────────────────────

# Кладём текущий предмет, берём новый; обновляем активный слот.
func _do_pickup(item: Node) -> void:
	_drop_held()
	held_item = item
	item.call("pickup", get_parent() as CharacterBody2D)
	for i in _slots.size():
		if _slots[i] == item:
			_active_slot = i
			break
	_update_ui()

# Кладём/убираем текущий удерживаемый предмет.
# item_visible = false → store() (скрыть), item_visible = true → drop() (на землю).
func _drop_held() -> void:
	if held_item == null:
		return
	var iv = held_item.get("item_visible")
	if iv != null and not bool(iv):
		held_item.call("store")
	else:
		held_item.call("drop")
	held_item    = null
	_active_slot = 0
	_update_ui()

# Вызывается предметом при входе (item != null) или выходе (item = null) игрока в зону.
# source — ссылка на предмет, генерирующий событие; защищает от перетирания чужими событиями.
func set_nearby_item(item, source = null) -> void:
	if item != null:
		nearby_item = item
	elif source == null or nearby_item == source:
		nearby_item = null

# ── UI ────────────────────────────────────────────────────────────────────────

# Находит Panel- и Label-узлы в InventoryBar (по группе "inventory_bar")
# и сохраняет ссылки для быстрого обновления.
func _setup_ui() -> void:
	# InventoryBar — отдельная CanvasLayer-сцена, добавляемая в сцену уровня.
	# Ищем через группу чтобы не зависеть от имени узла или позиции в иерархии.
	var bar = get_tree().get_first_node_in_group("inventory_bar")
	if bar == null:
		return
	var hbox = bar.get_node_or_null("MarginContainer/HBoxContainer")
	if hbox == null:
		return
	_slot_panels.clear()
	_slot_labels_ui.clear()
	for i in SLOT_COUNT:
		var panel = hbox.get_node_or_null("slot_%d" % i)
		_slot_panels.append(panel)
		_slot_labels_ui.append(panel.get_node_or_null("Label") if panel else null)
	_update_ui()

# Перекрашивает панели: активный слот — золотой, остальные — тёмные.
# Добавляет «•» к имени предмета, если тот скрыт (в инвентаре).
func _update_ui() -> void:
	for i in _slot_panels.size():
		if _slot_panels[i] == null:
			continue
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(4)
		style.content_margin_left   = 10
		style.content_margin_right  = 10
		style.content_margin_top    = 5
		style.content_margin_bottom = 5
		style.bg_color = Color(0.9, 0.7, 0.1, 0.9) if i == _active_slot else Color(0.12, 0.12, 0.12, 0.7)
		_slot_panels[i].add_theme_stylebox_override("panel", style)
		if i < _slot_labels_ui.size() and _slot_labels_ui[i]:
			var txt := "[%d] %s" % [i, SLOT_LABELS[i]]
			# «•» означает: предмет есть, но сейчас убран в инвентарь.
			if i > 0 and i < _slots.size() and _slots[i] != null and not _slots[i].visible:
				txt += " •"
			_slot_labels_ui[i].text = txt
