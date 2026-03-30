extends Node

# Автозагрузка: "SaveManager"
# Только чтение/запись файлов. Не знает про Events и игровую логику.

const SAVE_PATH = "user://save.cfg"

var _config := ConfigFile.new()

func _ready() -> void:
	_config.load(SAVE_PATH)  # ошибку игнорируем — файл может не существовать

# ----------------------------------------------------------------
# Прогресс (сохраняется между сессиями)
# ----------------------------------------------------------------

## Записывает золото, лучший результат, количество игр, уровень и прогресс героя в файл.
func save_progress(g: Node) -> void:
	_config.set_value("progress", "gold",           g.gold)
	_config.set_value("progress", "gems",           g.gems)
	_config.set_value("progress", "tokens",         g.tokens)
	_config.set_value("progress", "best_score",     g.best_score)
	_config.set_value("progress", "games_played",   g.games_played)
	_config.set_value("progress", "level",           g.level)
	# --- Прогресс героя ---
	_config.set_value("progress", "skill_xp",         g.skill_xp)
	_config.set_value("progress", "total_xp",         g.total_xp)
	_config.set_value("progress", "water",             g.water)
	# --- Экипировка ---
	_config.set_value("progress", "head_level",        g.head_level)
	_config.set_value("progress", "boots_level",       g.boots_level)
	_config.set_value("progress", "cloak_level",       g.cloak_level)
	_config.set_value("progress", "gloves_level",      g.gloves_level)
	_config.set_value("progress", "wheelbarrow_level", g.wheelbarrow_level)
	# --- Инструменты и навыки ---
	_config.set_value("progress", "owned_tools",     g.owned_tools)
	_config.set_value("progress", "unlocked_skills", g.unlocked_skills)
	_config.set_value("progress", "passive_perks",   g.passive_perks)
	_config.save(SAVE_PATH)

## Загружает золото, лучший результат, количество игр, уровень и прогресс героя из файла.
func load_progress(g: Node) -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	_config.load(SAVE_PATH)
	g.gold         = _config.get_value("progress", "gold",         0)
	g.gems         = _config.get_value("progress", "gems",         0)
	g.tokens       = _config.get_value("progress", "tokens",       0)
	g.best_score   = _config.get_value("progress", "best_score",   0)
	g.games_played = _config.get_value("progress", "games_played", 0)
	g.level        = _config.get_value("progress", "level",        1)
	# --- Прогресс героя ---
	g.skill_xp          = _config.get_value("progress", "skill_xp",         0)
	g.total_xp          = _config.get_value("progress", "total_xp",         0)
	g.water             = _config.get_value("progress", "water",             0)
	# --- Экипировка ---
	g.head_level        = _config.get_value("progress", "head_level",        0)
	g.boots_level       = _config.get_value("progress", "boots_level",       0)
	g.cloak_level       = _config.get_value("progress", "cloak_level",       0)
	g.gloves_level      = _config.get_value("progress", "gloves_level",      0)
	g.wheelbarrow_level = _config.get_value("progress", "wheelbarrow_level", 0)
	# --- Инструменты и навыки ---
	g.owned_tools     = _config.get_value("progress", "owned_tools",     [])
	g.unlocked_skills = _config.get_value("progress", "unlocked_skills", [])
	g.passive_perks   = _config.get_value("progress", "passive_perks",   [])

# ----------------------------------------------------------------
# Состояние игры (для функции "продолжить")
# ----------------------------------------------------------------

## Сохраняет runtime-состояние для возможности «Продолжить».
## Содержит только SESSION-данные; PROGRESS хранится отдельно.
func save_game_state(g: Node) -> void:
	_config.set_value("game_state", "health",        g.health)
	_config.set_value("game_state", "lives_count",   g.lives_count)
	_config.set_value("game_state", "points",         g.points)
	_config.set_value("game_state", "point_wheelbarrow",    g.point_wheelbarrow)
	_config.set_value("game_state", "level_id",       g.game_state_level_id)
	_config.set_value("game_state", "position_x",     g.player_position_x)
	print("Позиция 4 ",g.player_position_x)
	_config.set_value("game_state", "position_y",     g.player_position_y)
	_config.set_value("game_state", "facing_left",    g.player_facing_left)
	_config.set_value("game_state", "active_equip_id", g.active_equip_id)
	_config.save(SAVE_PATH)

## Загружает runtime-состояние из файла (только SESSION-данные).
func load_game_state(g: Node) -> void:
	_config.load(SAVE_PATH)
	g.health      = _config.get_value("game_state", "health",      100)
	g.lives_count = _config.get_value("game_state", "lives_count", 3)
	g.points      = _config.get_value("game_state", "points",      0)
	g.point_wheelbarrow = _config.get_value("game_state", "point_wheelbarrow", 0)
	# level и gold уже загружены через load_progress — не дублируем
	g.game_state_level_id = _config.get_value("game_state", "level_id",    -1)
	g.player_position_x   = _config.get_value("game_state", "position_x",  0.0)
	print("Позиция 1 ",g.player_position_x)
	g.player_position_y   = _config.get_value("game_state", "position_y",  0.0)
	g.player_facing_left  = _config.get_value("game_state", "facing_left",    false)
	g.active_equip_id     = _config.get_value("game_state", "active_equip_id", "")

## Возвращает true, если секция game_state есть в файле сохранения.
func has_game_state() -> bool:
	return _config.has_section("game_state")

## Удаляет секцию game_state из файла (вызывается после end_game).
func clear_game_state() -> void:
	if _config.has_section("game_state"):
		_config.erase_section("game_state")
		_config.save(SAVE_PATH)
