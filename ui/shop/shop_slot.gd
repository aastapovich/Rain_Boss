## Карточка товара в магазине. Используется как reusable-компонент в GridContainer.
## Поддерживает 3 состояния: "normal", "selected", "locked".
## setup() принимает унифицированный словарь-строку данных.
class_name ShopSlot
extends PanelContainer

signal slot_pressed(item_id: String)
signal select_toggled(item_id: String, selected: bool)

# ── Ноды (настраиваются в shop_slot.tscn) ────────────────────────────────────
@onready var _icon_label:   Label  = $Margin/VBox/IconLabel
@onready var _name_label:   Label  = $Margin/VBox/NameLabel
@onready var _stars_label:  Label  = $Margin/VBox/StarsLabel
@onready var _stats_label:  Label  = $Margin/VBox/StatsLabel
@onready var _cost_label:   Label  = $Margin/VBox/CostLabel
@onready var _action_btn:   Button      = $Margin/VBox/ActionButton
@onready var _select_check: CheckButton = $Margin/VBox/SelectCheck

# ── Внутреннее состояние ──────────────────────────────────────────────────────
var _item_id: String = ""
var _state: String   = "normal"   # "normal" | "selected" | "locked"

# ── StyleBox-ы (создаются в _ready для всех трёх состояний) ──────────────────
var _sb_normal:   StyleBoxFlat
var _sb_selected: StyleBoxFlat
var _sb_locked:   StyleBoxFlat

func _ready() -> void:
	_build_styleboxes()
	_action_btn.pressed.connect(_on_action_pressed)
	_select_check.toggled.connect(_on_select_toggled)

# ── Настройка карточки ────────────────────────────────────────────────────────

## Универсальный метод установки данных.
## data — словарь с полями: id, label, icon, locked (обязательные).
## Опциональные: stars (int 0..5), stats (String), cost (String), btn_text (String), btn_disabled (bool).
func setup(data: Dictionary, state: String = "normal") -> void:
	_item_id = data.get("id", "")
	_state   = "locked" if data.get("locked", false) else state

	if _state == "locked":
		_apply_locked_style()
		return

	# Иконка и название
	_icon_label.text  = data.get("icon", "?")
	_name_label.text  = data.get("label", "")

	# Звёздочки (только для upgrade-слотов)
	var stars: int = data.get("stars", -1)
	if stars >= 0:
		_stars_label.text    = "★".repeat(stars) + "☆".repeat(maxi(0, 5 - stars))
		_stars_label.visible = true
	else:
		_stars_label.visible = false

	# Описание эффекта
	_stats_label.text    = data.get("stats", "")
	_stats_label.visible = not _stats_label.text.is_empty()

	# Цена
	_cost_label.text    = data.get("cost", "")
	_cost_label.visible = not _cost_label.text.is_empty()

	# Кнопка
	_action_btn.text     = data.get("btn_text", "Выбрать")
	_action_btn.disabled = data.get("btn_disabled", false)

	# Чекбокс «Выбрать» (только для экипируемых товаров)
	var show_sel: bool = data.get("show_select", false)
	_select_check.visible = show_sel
	if show_sel:
		_select_check.set_pressed_no_signal(data.get("is_selected", false))

	_apply_style(_state)

## Переключает визуальное выделение без перестройки данных.
func set_selected(on: bool) -> void:
	if _state == "locked":
		return
	_state = "selected" if on else "normal"
	_apply_style(_state)

# ── Приватные методы ──────────────────────────────────────────────────────────

func _apply_locked_style() -> void:
	_icon_label.text      = "🔒"
	_name_label.text      = "?????"
	_stars_label.visible  = false
	_stats_label.visible  = false
	_cost_label.visible   = false
	_action_btn.text      = "Закрыто"
	_action_btn.disabled  = true
	_select_check.visible = false
	modulate              = Color(1, 1, 1, 0.45)
	add_theme_stylebox_override("panel", _sb_locked)

func _apply_style(s: String) -> void:
	modulate = Color.WHITE
	match s:
		"selected":
			add_theme_stylebox_override("panel", _sb_selected)
		_:
			add_theme_stylebox_override("panel", _sb_normal)

func _build_styleboxes() -> void:
	_sb_normal = StyleBoxFlat.new()
	_sb_normal.bg_color                  = Color(0.10, 0.10, 0.15, 0.95)
	_sb_normal.border_width_left         = 1
	_sb_normal.border_width_top          = 1
	_sb_normal.border_width_right        = 1
	_sb_normal.border_width_bottom       = 1
	_sb_normal.border_color              = Color(0.3, 0.35, 0.5, 0.7)
	_sb_normal.corner_radius_top_left    = 6
	_sb_normal.corner_radius_top_right   = 6
	_sb_normal.corner_radius_bottom_right = 6
	_sb_normal.corner_radius_bottom_left = 6
	_sb_normal.content_margin_left       = 8.0
	_sb_normal.content_margin_top        = 8.0
	_sb_normal.content_margin_right      = 8.0
	_sb_normal.content_margin_bottom     = 8.0

	_sb_selected = StyleBoxFlat.new()
	_sb_selected.bg_color                  = Color(0.10, 0.18, 0.32, 0.98)
	_sb_selected.border_width_left         = 2
	_sb_selected.border_width_top          = 2
	_sb_selected.border_width_right        = 2
	_sb_selected.border_width_bottom       = 2
	_sb_selected.border_color              = Color(0.3, 0.65, 1.0, 1.0)
	_sb_selected.corner_radius_top_left    = 6
	_sb_selected.corner_radius_top_right   = 6
	_sb_selected.corner_radius_bottom_right = 6
	_sb_selected.corner_radius_bottom_left = 6
	_sb_selected.content_margin_left       = 8.0
	_sb_selected.content_margin_top        = 8.0
	_sb_selected.content_margin_right      = 8.0
	_sb_selected.content_margin_bottom     = 8.0

	_sb_locked = StyleBoxFlat.new()
	_sb_locked.bg_color                  = Color(0.05, 0.05, 0.08, 0.90)
	_sb_locked.border_width_left         = 1
	_sb_locked.border_width_top          = 1
	_sb_locked.border_width_right        = 1
	_sb_locked.border_width_bottom       = 1
	_sb_locked.border_color              = Color(0.2, 0.2, 0.3, 0.5)
	_sb_locked.corner_radius_top_left    = 6
	_sb_locked.corner_radius_top_right   = 6
	_sb_locked.corner_radius_bottom_right = 6
	_sb_locked.corner_radius_bottom_left = 6
	_sb_locked.content_margin_left       = 8.0
	_sb_locked.content_margin_top        = 8.0
	_sb_locked.content_margin_right      = 8.0
	_sb_locked.content_margin_bottom     = 8.0

	add_theme_stylebox_override("panel", _sb_normal)

func _on_action_pressed() -> void:
	if _state != "locked":
		slot_pressed.emit(_item_id)

func _on_select_toggled(pressed: bool) -> void:
	select_toggled.emit(_item_id, pressed)
