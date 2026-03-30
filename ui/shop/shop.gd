## Магазин — drill-down навигация. 5 категорий, 3 уровня вглубь.
## Открывается извне через open(ctx). После закрытия эмитит closed(ctx).
## Не знает про Globals, Events и узлы сцены — работает только с ShopContext.
## Паузой управляет game.gd.
extends CanvasLayer

## Пакет данных закрыт — game.gd применит его к Globals.
signal closed(ctx: ShopCtx)

const SLOT_SCENE  := preload("res://ui/shop/shop_slot.tscn")
# Явный preload — обходит задержку регистрации class_name в LSP
const _DATA       := preload("res://ui/shop/shop_data.gd")
const ShopCtx     := preload("res://Core/shop_context.gd")

# ── Ноды ──────────────────────────────────────────────────────────────────────
@onready var _left_list:      VBoxContainer = $Overlay/Panel/VBox/HSplit/LeftPanel/LeftVBox/LeftList
@onready var _apply_btn:      Button        = $Overlay/Panel/VBox/HSplit/LeftPanel/LeftVBox/ApplyButton
@onready var _right_grid:     GridContainer = $Overlay/Panel/VBox/HSplit/RightScroll/RightGrid
@onready var _breadcrumb:     Label         = $Overlay/Panel/VBox/Header/HeaderHBox/Breadcrumb
@onready var _back_btn:       Button        = $Overlay/Panel/VBox/Header/HeaderHBox/BackButton
@onready var _close_btn:      Button        = $Overlay/Panel/VBox/Header/HeaderHBox/CloseButton
@onready var _currency_label: Label         = $Overlay/Panel/VBox/Footer/CurrencyLabel

# ── Навигационный стек ────────────────────────────────────────────────────────
# Каждый элемент: {view, cat_id, item_id, part_id, label}
# view: "cats" | "items" | "parts" | "upgrade" | "variants"
var _nav: Array = []

## Пакет данных текущей сессии магазина.
var _ctx: ShopCtx = null
var _pending_equip: String = ""

# ── Готовность ────────────────────────────────────────────────────────────────

func _ready() -> void:
	visible = false
	_close_btn.pressed.connect(_on_close_pressed)
	_back_btn.pressed.connect(_go_back)
	_apply_btn.pressed.connect(_on_close_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _nav.size() > 1:
			_go_back()
		else:
			_on_close_pressed()

# ── Открытие / Закрытие ───────────────────────────────────────────────────────

## Открыть магазин с переданным пакетом данных.
## Вызывается из game.gd после Events.shop_opened.
func open(ctx: ShopCtx) -> void:
	_ctx = ctx
	_pending_equip = _ctx.active_equip_id
	_nav = [_make_state("cats", "", "", "", "Магазин")]
	visible = true
	_render()

func _on_close_pressed() -> void:
	# Зафиксировать ожидающую экипировку в пакете
	_ctx.active_equip_id = _pending_equip
	visible = false
	closed.emit(_ctx)

# ── Навигация ─────────────────────────────────────────────────────────────────

func _make_state(view: String, cat_id: String, item_id: String,
		part_id: String, label: String) -> Dictionary:
	return {view = view, cat_id = cat_id, item_id = item_id,
			part_id = part_id, label = label}

func _push(state: Dictionary) -> void:
	_nav.append(state)
	_render()

func _go_back() -> void:
	if _nav.size() > 1:
		_nav.pop_back()
		_render()

func _render() -> void:
	var state: Dictionary = _nav.back()
	_back_btn.visible = _nav.size() > 1

	_clear(_left_list)
	_clear(_right_grid)

	# Хлебные крошки
	var crumbs: PackedStringArray = []
	for s in _nav:
		crumbs.append(s.label)
	_breadcrumb.text = "  ▸  ".join(crumbs)

	match state.view:
		"cats":     _render_cats()
		"items":    _render_items(state.cat_id)
		"parts":    _render_parts(state.item_id)
		"upgrade":  _render_upgrade(state.item_id)
		"variants": _render_variants(state.part_id)

	_update_currency()
	_update_apply_btn()

# ── Уровень: Категории ────────────────────────────────────────────────────────

func _render_cats() -> void:
	_add_left_header("Категории")
	for cat in _DATA.CATEGORIES:
		var btn := _make_left_btn(cat.icon + "  " + cat.label, cat.locked)
		if not cat.locked:
			var c: Dictionary = cat  # capture
			btn.pressed.connect(func():
				_push(_make_state("items", c.id, "", "", c.label))
			)
		_left_list.add_child(btn)

	var hint := Label.new()
	hint.text = "← Выберите категорию"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.55, 0.6, 0.75, 1.0)
	hint.add_theme_font_size_override("font_size", 16)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	hint.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	_right_grid.add_child(hint)

# ── Уровень: Товары категории ─────────────────────────────────────────────────

func _render_items(cat_id: String) -> void:
	var items: Array = _DATA.ITEMS.get(cat_id, [])
	_add_left_header("Товары")
	for it in items:
		var btn := _make_left_btn(it.icon + "  " + it.label, it.locked)
		if not it.locked:
			var i: Dictionary = it  # capture
			btn.pressed.connect(func():
				_open_item(cat_id, i)
			)
		_left_list.add_child(btn)

	for it in items:
		var slot := SLOT_SCENE.instantiate()
		_right_grid.add_child(slot)
		var data := _build_item_slot_data(it)
		slot.setup(data)
		if not it.locked:
			var i: Dictionary = it  # capture
			slot.slot_pressed.connect(func(_id):
				if i.type == "upgrade":
					_try_upgrade(i)
				else:
					_open_item(cat_id, i)
			)
			if i.get("type") == "parts":
				slot.select_toggled.connect(func(sid: String, sel: bool):
					_pending_equip = sid if sel else ""
					_render()
				)

func _open_item(cat_id: String, it: Dictionary) -> void:
	if it.type == "parts":
		_push(_make_state("parts", cat_id, it.id, "", it.label))
	else:
		_push(_make_state("upgrade", cat_id, it.id, "", it.label))

func _build_item_slot_data(it: Dictionary) -> Dictionary:
	var data := {id = it.id, label = it.label, icon = it.icon, locked = it.locked}
	if it.get("type") == "upgrade":
		var gvar: String  = it.get("gvar", "")
		var lvl: int      = _gvar_get(gvar)
		var max_lv: int   = it.get("max_level", 5)
		data.stars        = lvl
		data.stats        = _upgrade_stat(gvar, lvl)
		data.cost         = _upgrade_cost_str(gvar, lvl)
		data.btn_text     = "МАКС" if lvl >= max_lv else "Улучшить"
		data.btn_disabled = lvl >= max_lv or not _can_afford_upgrade(gvar, lvl)
	else:
		data.btn_text = "Открыть"
		if it.get("type") == "parts":
			data.show_select = true
			data.is_selected = (_pending_equip == it.id)
	return data

# ── Уровень: Запчасти ─────────────────────────────────────────────────────────

func _render_parts(item_id: String) -> void:
	var parts: Array = _DATA.PARTS.get(item_id, [])
	_add_left_header("Запчасти")

	var is_equipped := (_pending_equip == item_id)
	var equip_btn   := Button.new()
	equip_btn.text  = "✓ Экипировано" if is_equipped else "Взять"
	equip_btn.add_theme_font_size_override("font_size", 13)
	equip_btn.add_theme_color_override("font_color",
		Color(0.4, 1.0, 0.5) if is_equipped else Color.WHITE)
	equip_btn.pressed.connect(func():
		_pending_equip = "" if _pending_equip == item_id else item_id
		_render()
	)
	_left_list.add_child(equip_btn)
	_add_left_sep()

	for p in parts:
		var btn := _make_left_btn(p.label, p.locked)
		if not p.locked:
			var p_c: Dictionary = p  # capture
			btn.pressed.connect(func():
				_push(_make_state("variants", "", item_id, p_c.id, p_c.label))
			)
		_left_list.add_child(btn)

	for p in parts:
		var slot := SLOT_SCENE.instantiate()
		_right_grid.add_child(slot)
		var variants: Array = _DATA.VARIANTS.get(p.id, [])
		var v_label: String = variants[0][1] if variants.size() > 0 else "—"
		slot.setup({
			id = p.id, label = p.label, icon = "🔧",
			locked = p.locked, stats = v_label, btn_text = "Выбрать",
		})
		if not p.locked:
			var p_c: Dictionary = p  # capture
			slot.slot_pressed.connect(func(_id):
				_push(_make_state("variants", "", item_id, p_c.id, p_c.label))
			)

# ── Уровень: Варианты запчасти ────────────────────────────────────────────────

func _render_variants(part_id: String) -> void:
	var variants: Array = _DATA.VARIANTS.get(part_id, [])
	_add_left_header("Варианты")
	for v in variants:
		_left_list.add_child(_make_left_btn(v[2] + "  " + v[1], v[3]))

	for v in variants:
		var slot := SLOT_SCENE.instantiate()
		_right_grid.add_child(slot)
		var stat_parts: PackedStringArray = []
		for k in v[6]:
			stat_parts.append("%s: %s" % [k, str(v[6][k])])
		var cost_str := ("G:%d  XP:%d" % [v[4], v[5]]) if (v[4] > 0 or v[5] > 0) else ""
		slot.setup({
			id = v[0], label = v[1], icon = v[2], locked = v[3],
			stats = "  ".join(stat_parts), cost = cost_str,
			btn_text = "Выбрать", btn_disabled = v[3],
		})

# ── Уровень: Улучшения (одежда) ───────────────────────────────────────────────

func _render_upgrade(item_id: String) -> void:
	var item_data: Dictionary = _find_item(item_id)
	if item_data.is_empty():
		return

	var gvar: String  = item_data.get("gvar", "")
	var max_lv: int   = item_data.get("max_level", 5)
	var cur_lv: int   = _gvar_get(gvar)

	_add_left_header(item_data.label)
	var info_lbl := Label.new()
	info_lbl.text = "Уровень: %d / %d" % [cur_lv, max_lv]
	info_lbl.add_theme_font_size_override("font_size", 13)
	info_lbl.modulate = Color(0.8, 0.9, 1.0, 1.0)
	_left_list.add_child(info_lbl)

	var costs: Array = _DATA.UPGRADE_COSTS.get(gvar, [])
	for i in range(max_lv):
		var slot := SLOT_SCENE.instantiate()
		_right_grid.add_child(slot)
		var bought  := i < cur_lv
		var is_next := i == cur_lv
		var c_arr: Array = costs[i] if i < costs.size() else [0, 0, 0, 0]

		var cost_str := ""
		if not bought:
			var cp: PackedStringArray = []
			if c_arr[0] > 0: cp.append("💧:%d" % c_arr[0])
			if c_arr[1] > 0: cp.append("XP:%d" % c_arr[1])
			if c_arr[2] > 0: cp.append("G:%d"  % c_arr[2])
			if c_arr[3] > 0: cp.append("💎:%d" % c_arr[3])
			cost_str = "  ".join(cp)

		var can_buy := is_next and _can_afford_upgrade(gvar, i)
		var btn_txt: String
		if bought:    btn_txt = "✓ Куплено"
		elif is_next: btn_txt = "Улучшить"
		else:         btn_txt = "Закрыто"

		slot.setup({
			id = "%s_%d" % [item_id, i + 1],
			label = "Уровень %d" % (i + 1),
			icon = "★",
			locked = false,
			stars = i + 1,
			stats = _upgrade_stat(gvar, i + 1),
			cost = cost_str,
			btn_text = btn_txt,
			btn_disabled = bought or not can_buy,
		})
		if can_buy:
			var it_c := item_data  # capture
			var idx   := i
			slot.slot_pressed.connect(func(_id):
				_do_upgrade(it_c, idx)
			)

# ── Покупка апгрейда ──────────────────────────────────────────────────────────

func _try_upgrade(item: Dictionary) -> void:
	var gvar: String = item.get("gvar", "")
	var lvl: int     = _gvar_get(gvar)
	if lvl < item.get("max_level", 5):
		_do_upgrade(item, lvl)

func _do_upgrade(item: Dictionary, idx: int) -> void:
	var gvar: String = item.get("gvar", "")
	if gvar == "":
		return
	var costs: Array = _DATA.UPGRADE_COSTS.get(gvar, [])
	if idx >= costs.size() or not _can_afford_upgrade(gvar, idx):
		return
	_deduct(costs[idx])
	_gvar_set(gvar, _gvar_get(gvar) + 1)
	_render()

# ── Вспомогательные ───────────────────────────────────────────────────────────

func _find_item(item_id: String) -> Dictionary:
	for arr in _DATA.ITEMS.values():
		for it in arr:
			if it.id == item_id:
				return it
	return {}

func _can_afford_upgrade(gvar: String, idx: int) -> bool:
	var costs: Array = _DATA.UPGRADE_COSTS.get(gvar, [])
	if idx >= costs.size():
		return false
	var c: Array = costs[idx]
	return _ctx.water >= c[0] and _ctx.skill_xp >= c[1] \
		   and _ctx.gold >= c[2] and _ctx.gems >= c[3]

func _upgrade_cost_str(gvar: String, cur_lv: int) -> String:
	var costs: Array = _DATA.UPGRADE_COSTS.get(gvar, [])
	if cur_lv >= costs.size():
		return "МАКС"
	var c: Array = costs[cur_lv]
	var parts: PackedStringArray = []
	if c[0] > 0: parts.append("💧:%d" % c[0])
	if c[1] > 0: parts.append("XP:%d"  % c[1])
	if c[2] > 0: parts.append("G:%d"   % c[2])
	if c[3] > 0: parts.append("💎:%d"  % c[3])
	return "  ".join(parts)

func _upgrade_stat(gvar: String, level: int) -> String:
	var stats: Array = _DATA.UPGRADE_STATS.get(gvar, [])
	if level <= 0 or level > stats.size():
		return ""
	return stats[level - 1]

func _deduct(c: Array) -> void:
	if c[0] > 0: _ctx.water    -= c[0]
	if c[1] > 0: _ctx.skill_xp -= c[1]
	if c[2] > 0: _ctx.gold     -= c[2]
	if c[3] > 0: _ctx.gems     -= c[3]

func _gvar_get(gvar: String) -> int:
	if gvar == "" or _ctx == null:
		return 0
	var val = _ctx.get(gvar)
	return int(val) if val != null else 0

func _gvar_set(gvar: String, val: int) -> void:
	if gvar != "" and _ctx != null:
		_ctx.set(gvar, val)

func _update_currency() -> void:
	if _ctx == null:
		return
	_currency_label.text = "💧 %d   XP: %d   G: %d   💎 %d" % [
		_ctx.water, _ctx.skill_xp, _ctx.gold, _ctx.gems
	]

func _update_apply_btn() -> void:
	if _pending_equip.is_empty():
		_apply_btn.text     = "Применить"
		_apply_btn.modulate = Color(0.8, 0.8, 0.8, 1.0)
	else:
		_apply_btn.text     = "✓ Применить"
		_apply_btn.modulate = Color(0.45, 1.0, 0.55, 1.0)

func _add_left_header(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.modulate = Color(0.5, 0.65, 0.9, 1.0)
	lbl.uppercase = true
	_left_list.add_child(lbl)
	_add_left_sep()

func _add_left_sep() -> void:
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 3)
	_left_list.add_child(sep)

func _make_left_btn(text: String, locked: bool = false) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_size_override("font_size", 14)
	btn.flat = true
	btn.disabled = locked
	btn.modulate = Color(0.5, 0.5, 0.6, 0.7) if locked else Color.WHITE
	return btn

func _clear(node: Node) -> void:
	for ch in node.get_children():
		ch.queue_free()
