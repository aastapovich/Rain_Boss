## XpManager — автозагрузка "XpManager".
## Единственное место, где меняется skill_xp и total_xp.
## hero_skill_level НЕ хранится — вычисляется через level_for_xp(total_xp).
## Все внешние системы вызывают add_xp() или buy_xp_*().
## Не хранит состояние — читает/пишет через Globals.
extends Node

# ──────────────────────────────────────────────────────────────────────────────
# Таблица наград по источнику (xp_source → значение)
# ──────────────────────────────────────────────────────────────────────────────
const XP_REWARDS: Dictionary = {
	"water_100":        1,   ## +1 за каждые 100л воды
	"coin":             2,   ## золотая монета
	"gem":              5,   ## кристалл
	"treasure":        15,   ## клад
	"level_clear":     10,   ## переход на новый уровень (множитель × номер уровня)
	"level_first":     25,   ## первое прохождение уровня (бонус)
	"quest":           20,   ## задание внутри уровня
}

# Цены покупки XP
const XP_PER_GOLD: int  = 10   ## 10 золота → 1 XP
const XP_PER_GEM: int   = 5    ## 1 кристалл → 5 XP

## Сколько суммарного XP нужно для каждого следующего уровня.
## hero_skill_level = int(total_xp / XP_PER_LEVEL) + 1
## Значение настраивается здесь — меняет крутизну прокачки.
const XP_PER_LEVEL: int = 100

## Вычисляет уровень героя из суммарного опыта.
## Уровень начинается с 1. Не хранится — всегда считается на лету.
func level_for_xp(p_total_xp: int) -> int:
	@warning_ignore("integer_division")
	return int(p_total_xp / XP_PER_LEVEL) + 1

## Максимальный уровень героя.
func max_level() -> int:
	return SkillConfig.max_level()

# ──────────────────────────────────────────────────────────────────────────────
# Внутренний счётчик воды (для threshold каждые 100л)
# ──────────────────────────────────────────────────────────────────────────────
var _water_xp_counter: int = 0

# ──────────────────────────────────────────────────────────────────────────────
# Публичный API
# ──────────────────────────────────────────────────────────────────────────────

## Начислить XP из игрового источника.
## source — ключ из XP_REWARDS или произвольное значение с явным amount.
## multiplier — для level_clear передаём номер уровня.
func add_xp(source: String, multiplier: int = 1) -> void:
	var base: int = XP_REWARDS.get(source, 0)
	var amount: int = base * multiplier
	if amount <= 0:
		return
	_apply_xp(amount, source)

## Начислить произвольное количество XP напрямую (для квестов/заданий).
func add_xp_amount(amount: int, source: String = "direct") -> void:
	if amount <= 0:
		return
	_apply_xp(amount, source)

## Обработать полученную воду (вызывать при каждой выгрузке).
## Начисляет +1 XP за каждые 100л нарастающим итогом.
func on_water_unloaded(liters: int) -> void:
	_water_xp_counter += liters
	@warning_ignore("integer_division")
	var earned := _water_xp_counter / 100
	if earned > 0:
		_water_xp_counter = _water_xp_counter % 100
		_apply_xp(earned, "water_100")

## Купить XP за золото. Возвращает true если покупка прошла.
func buy_xp_for_gold(gold_amount: int) -> bool:
	if Globals.gold < gold_amount:
		Events.xp_purchase_failed.emit("gold", gold_amount)
		return false
	@warning_ignore("integer_division")
	var xp_gained := gold_amount / XP_PER_GOLD
	if xp_gained <= 0:
		return false
	Globals.change_gold(-gold_amount)
	_apply_xp(xp_gained, "buy_gold")
	return true

## Купить XP за кристаллы. Возвращает true если покупка прошла.
func buy_xp_for_gems(gem_amount: int) -> bool:
	if Globals.gems < gem_amount:
		Events.xp_purchase_failed.emit("gems", gem_amount)
		return false
	var xp_gained := gem_amount * XP_PER_GEM
	Globals.change_gems(-gem_amount)
	_apply_xp(xp_gained, "buy_gems")
	return true

## Сколько XP нужно для следующего уровня (от текущего total_xp).
func xp_to_next_level() -> int:
	var cur_level := level_for_xp(Globals.total_xp)
	return cur_level * XP_PER_LEVEL - Globals.total_xp

## Прогресс к следующему уровню (0.0–1.0) — для прогресс-бара.
func xp_progress() -> float:
	var cur_level := level_for_xp(Globals.total_xp)
	var level_start := (cur_level - 1) * XP_PER_LEVEL
	var progress := Globals.total_xp - level_start
	return clampf(float(progress) / float(XP_PER_LEVEL), 0.0, 1.0)

## На максимальном уровне — больше не прокачаться.
func is_max_level() -> bool:
	return level_for_xp(Globals.total_xp) >= max_level()

# ──────────────────────────────────────────────────────────────────────────────
# Внутренняя логика
# ──────────────────────────────────────────────────────────────────────────────

func _apply_xp(amount: int, source: String) -> void:
	if is_max_level():
		return

	var level_before := level_for_xp(Globals.total_xp)

	Globals.skill_xp += amount
	Globals.total_xp += amount
	Events.xp_changed.emit(Globals.skill_xp, xp_to_next_level(), source)

	# Проверяем level-up по total_xp (без сброса skill_xp)
	var level_after := level_for_xp(Globals.total_xp)
	if level_after > level_before:
		Events.skill_level_changed.emit(level_after)
		# Сохранение прогресса при level-up делает game.gd через Events.skill_level_changed
