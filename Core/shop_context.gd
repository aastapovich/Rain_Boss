## ShopContext — пакет данных для магазина.
## Снимок состояния игрока: создаётся перед открытием магазина,
## возвращается после закрытия и применяется к Globals медиатором (game.gd).
## Магазин работает ТОЛЬКО с этим объектом — не знает про Globals и Events.
class_name ShopContext
extends RefCounted

# ── Валюты (тратятся в магазине) ──────────────────────────────────────────────
var water: int = 0       ## Основная валюта. Цена любой базовой покупки.
var skill_xp: int = 0   ## Опыт — тратится вместе с водой.
var gold: int = 0        ## Золото — вторичная валюта (средние/топ апгрейды).
var gems: int = 0        ## Алмазы — редкая (только топ апгрейды).

# ── Прогресс (READ-ONLY в магазине) ──────────────────────────────────────────
## Суммарный XP. Определяет уровень и разблокировки. Не тратится никогда.
var total_xp: int = 0

# ── Экипировка ────────────────────────────────────────────────────────────────
var active_equip_id: String = ""
var head_level: int = 0
var boots_level: int = 0
var cloak_level: int = 0
var gloves_level: int = 0
var wheelbarrow_level: int = 0

# ── Фабрика: снимок из Globals ────────────────────────────────────────────────

## Создаёт ShopContext из текущего состояния Globals.
## Вызывается game.gd перед тем как открыть магазин.
static func from_globals() -> ShopContext:
	var ctx := ShopContext.new()
	ctx.water             = Globals.water
	ctx.skill_xp          = Globals.skill_xp
	ctx.gold              = Globals.gold
	ctx.gems              = Globals.gems
	ctx.total_xp          = Globals.total_xp
	ctx.active_equip_id   = Globals.active_equip_id
	ctx.head_level        = Globals.head_level
	ctx.boots_level       = Globals.boots_level
	ctx.cloak_level       = Globals.cloak_level
	ctx.gloves_level      = Globals.gloves_level
	ctx.wheelbarrow_level = Globals.wheelbarrow_level
	return ctx

# ── Применение: обратно в Globals ────────────────────────────────────────────

## Записывает изменённые данные обратно в Globals.
## Вызывается game.gd после закрытия магазина.
## Для валют с событиями — использует change_* методы, чтобы
## сохранить bounds-check и автоматический emit сигналов.
func apply_to_globals() -> void:
	# Валюты — через change_*, чтобы сохранить Events.*_changed
	var gold_delta := gold - Globals.gold
	if gold_delta != 0:
		Globals.change_gold(gold_delta)

	var gems_delta := gems - Globals.gems
	if gems_delta != 0:
		Globals.change_gems(gems_delta)

	var water_delta := water - Globals.water
	if water_delta != 0:
		Globals.change_water(water_delta)

	# skill_xp — прямая запись (трата не эмитит отдельный сигнал)
	Globals.skill_xp = skill_xp

	# active_equip_id — прямая запись, spawn/despawn делает game.gd
	Globals.active_equip_id = active_equip_id

	# Уровни апгрейдов — пишем напрямую и эмитим equipment_changed если изменились
	_apply_equip_level("head_level",        head_level)
	_apply_equip_level("boots_level",       boots_level)
	_apply_equip_level("cloak_level",       cloak_level)
	_apply_equip_level("gloves_level",      gloves_level)
	_apply_equip_level("wheelbarrow_level", wheelbarrow_level)

# ── Вспомогательное ───────────────────────────────────────────────────────────

func _apply_equip_level(gvar: String, new_val: int) -> void:
	var old_val: int = int(Globals.get(gvar))
	if new_val != old_val:
		Globals.set(gvar, new_val)
		Events.equipment_changed.emit(gvar.replace("_level", ""), new_val)
