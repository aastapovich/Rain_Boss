## База данных магазина. Статический класс — только константы, без логики.
## Используется shop.gd для построения навигации и карточек.
class_name ShopData
extends RefCounted

# ── Категории верхнего уровня ────────────────────────────────────────────────
## Порядок отображения в левой панели.
## locked=true  →  слот отображается с "?????" и блокировкой.
const CATEGORIES: Array = [
	{id = "gear",         label = "Техника",      icon = "⚙",  locked = false},
	{id = "clothing",     label = "Одежда",        icon = "👔", locked = false},
	{id = "tools",        label = "Инструменты",   icon = "🔧", locked = false},
	{id = "achievements", label = "Достижения",    icon = "🏆", locked = true},
	{id = "finance",      label = "Финансы",       icon = "💰", locked = true},
]

# ── Товары по категориям ──────────────────────────────────────────────────────
## type="parts"   → при нажатии открывается уровень «запчасти» (PARTS)
## type="upgrade" → при нажатии открывается уровень «улучшение» (UPGRADE_COSTS)
const ITEMS: Dictionary = {
	"gear": [
		{id = "wheelbarrow", label = "Тачка",  icon = "🛻", type = "parts",   locked = false},
		{id = "pump",        label = "Насос",   icon = "⚙",  type = "parts",   locked = true},
	],
	"clothing": [
		{id = "headdress", label = "Шляпа",      icon = "👢", type = "upgrade", locked = false, max_level = 5, gvar = "head_level"},
		{id = "boots",   label = "Сапоги",      icon = "👢", type = "upgrade", locked = false, max_level = 5, gvar = "boots_level"},
		{id = "cloak",   label = "Плащ",         icon = "🧥", type = "upgrade", locked = false, max_level = 5, gvar = "cloak_level"},
		{id = "gloves",  label = "Перчатки",     icon = "🧤", type = "upgrade", locked = false, max_level = 5, gvar = "gloves_level"},
	],
	"tools": [
		{id = "bucket",   label = "Ведро",      icon = "🪣", type = "parts",   locked = false},
		{id = "shovel",   label = "Лопата",      icon = "⛏",  type = "parts",   locked = true},
		{id = "pickaxe",  label = "Кирка",       icon = "⛏",  type = "parts",   locked = true},
		{id = "saw",      label = "Ножовка",     icon = "🔧", type = "parts",   locked = true},
		{id = "lantern",  label = "Фонарь",      icon = "🔦", type = "parts",   locked = true},
		{id = "wrench",   label = "Ключ",        icon = "🔑", type = "parts",   locked = true},
	],
	"achievements": [],
	"finance":      [],
}

# ── Запчасти оборудования ─────────────────────────────────────────────────────
## Ключ — id товара из ITEMS (только type="parts").
## Значение — список слотов-запчастей. locked=true → не открыт.
const PARTS: Dictionary = {
	"wheelbarrow": [
		{id = "wh_body",   label = "Корпус",  locked = false},
		{id = "wh_wheel",  label = "Привод",  locked = false},
		{id = "wh_handle", label = "Ручки",   locked = false},
	],
	"bucket": [
		{id = "bk_body",   label = "Корпус",  locked = false},
		{id = "bk_handle", label = "Ручка",   locked = true},
	],
}

# ── Варианты запчастей ────────────────────────────────────────────────────────
## Ключ — id запчасти из PARTS.
## Строка: [id, label, icon, locked, cost_gold, cost_xp, stats_dict]
const VARIANTS: Dictionary = {
	"wh_body":   [["wh_body_std",   "Простой",       "🛻", false, 0, 0, {capacity = 50}]],
	"wh_wheel":  [["wh_wheel_std",  "Простое колесо","⚙",  false, 0, 0, {speed_mult = 1.0}]],
	"wh_handle": [["wh_handle_std", "Простые",       "🔧", false, 0, 0, {}]],
	"bk_body":   [["bk_body_std",   "Простой",       "🪣", false, 0, 0, {capacity = 20}]],
	"bk_handle": [["bk_handle_std", "Деревянная",    "🔧", true,  0, 0, {}]],
}

# ── Стоимость апгрейдов одежды ────────────────────────────────────────────────
## Ключ — gvar поля (boots_level / cloak_level / gloves_level).
## costs[i] = [water, xp, gold, gems] для апгрейда ДО уровня i+1.
## Вода — основная валюта. Золото и алмазы нужны только на высоких уровнях.
const UPGRADE_COSTS: Dictionary = {
	"head_level": [
		[8,   0,  0, 0],
		[16, 15,  0, 0],
		[28, 30, 20, 0],
		[44, 50, 60, 1],
		[65, 80, 110, 2],
	],
	"boots_level": [
		[10,  0,  0, 0],
		[20, 20,  0, 0],
		[35, 40, 30, 0],
		[55, 60, 80, 1],
		[80, 100, 150, 2],
	],
	"cloak_level": [
		[10,  0,  0, 0],
		[20, 20,  0, 0],
		[35, 40, 30, 0],
		[55, 60, 80, 1],
		[80, 100, 150, 2],
	],
	"gloves_level": [
		[8,   0,  0, 0],
		[16, 15,  0, 0],
		[28, 30, 25, 0],
		[44, 50, 65, 1],
		[65, 80, 120, 2],
	],
}

# ── Описания эффектов апгрейдов ───────────────────────────────────────────────
## Для отображения в карточке (stats_label).
const UPGRADE_STATS: Dictionary = {
	"head_level":   ["Защита +5%",   "Защита +10%",   "Защита +15%",   "Защита +22%",   "Защита +30%"],
	"boots_level":  ["Скорость +5%", "Скорость +10%", "Скорость +15%", "Скорость +22%", "Скорость +30%"],
	"cloak_level":  ["Урон -5%",     "Урон -10%",     "Урон -15%",     "Урон -22%",     "Урон -30%"],
	"gloves_level": ["Сбор +5%",     "Сбор +10%",     "Сбор +18%",     "Сбор +28%",     "Сбор +40%"],
}
