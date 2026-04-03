## Глобальное состояние игры (Автозагрузка "Globals").
## Две чёткие зоны данных:
##   SESSION  — временные, сбрасываются reset_session() при каждом новом уровне.
##   PROGRESS — постоянные, читаются/пишутся SaveManager. НЕ сбрасываются между уровнями.
extends Node

# =============================================================================
# SESSION — сбрасываются при новом уровне (через reset_session())
# =============================================================================
var health: int       = 100   ## 0..200 (при 200 добавляется жизнь)
var lives_count: int  = 3     ## 0..3
var points: int       = 0     ## Очки за текущий уровень
var point_wheelbarrow: int  = 0     ## Текущее кол-во воды в тачке

## Ёмкость тачки (динамическая, задаётся InventoryConfig через player)
var wheelbarrow_capacity_max: int = 100

## Текущее экипированное оборудование (сбрасывается при новом уровне,
## восстанавливается при resume). Нода в сцене управляется через InventorySystem.
## "" / "wheelbarrow" / "bucket"
var active_equip_id: String = ""

## Позиция игрока для resume на том же уровне
var player_position_x: float = 0.0
var player_position_y: float = 0.0
var player_facing_left: bool = false
var game_state_level_id: int = -1   ## id сохранённого уровня (-1 = нет)

# =============================================================================
# PROGRESS — сохраняются между сессиями (читаются/пишутся через SaveManager)
# =============================================================================
var gold: int   = 0
var gems: int   = 0     ## Кристаллы — редкая внутриигровая валюта
var tokens: int = 0     ## Жетоны
var level: int        = 1
var best_score: int   = 0
var games_played: int = 0

## Опыт героя. hero_skill_level НЕ хранится — вычисляется XpManager.level_for_xp(total_xp)
var skill_xp: int = 0   ## Накопленный опыт (зарабатывается и тратится в магазине)
var total_xp: int = 0   ## Суммарный XP за всё время (только растёт, определяет уровень)
var water: int    = 0   ## Вода — основная валюта магазина

## Уровни апгрейдов экипировки
var head_level: int        = 0
var boots_level: int       = 0
var cloak_level: int       = 0
var gloves_level: int      = 0
var wheelbarrow_level: int = 0

## Наборы инструментов, навыков и перков
var owned_tools: Array     = []
var unlocked_skills: Array = []
var passive_perks: Array   = []

# =============================================================================

## Загружает PROGRESS из файла при старте игры.
func _ready() -> void:
	SaveManager.load_progress(self)

## Сбрасывает только SESSION-данные (здоровье, очки, тачка, позиция).
## active_equip_id убран: тачка живёт в сцене уровня постоянно, не спавнится.
## PROGRESS-данные (gold, xp, уровни экипировки) НЕ трогает.
func reset_session() -> void:
	health               = 100
	lives_count          = 3
	points               = 0
	point_wheelbarrow    = 0
	active_equip_id      = ""   # зарезервировано для будущих спавнуемых предметов (bucket и др.)
	player_position_x    = 0.0
	player_position_y    = 0.0
	player_facing_left   = false
	game_state_level_id  = -1

# --- Очки ---

## Изменяет очки на diff и оповещает HUD.
func change_points(diff: int) -> void:
	points += diff
	Events.points_changed.emit(points)

# --- Здоровье ---

## Изменяет здоровье на diff.
## При 100→200 добавляет жизнь, при падении до 0 — сшибает жизнь.
func change_health(diff: int) -> void:
	health += diff

	if health >= 200:
		if lives_count < 3:
			lives_count += 1
			Events.lives_count_changed.emit(lives_count)
		health = 100

	if health <= 0:
		lives_count -= 1
		Events.lives_count_changed.emit(lives_count)
		health = 100 if lives_count > 0 else 0

	health = clamp(health, 0, 200)
	Events.health_changed.emit(health)

# --- Тачка ---

## Добавляет воду в тачку (зажим до wheelbarrow_capacity_max) и оповещает HUD.
func change_point_wheelbarrow(diff: int) -> void:
	point_wheelbarrow = clamp(point_wheelbarrow + diff, 0, wheelbarrow_capacity_max)
	Events.wheelbarrow_changed.emit(point_wheelbarrow)

## Возвращает процент наполнения тачки (0.0–1.0).
func get_wheelbarrow_percent() -> float:
	if wheelbarrow_capacity_max <= 0:
		return 0.0
	return float(point_wheelbarrow) / float(wheelbarrow_capacity_max)

# --- Золото ---

## Изменяет количество золота на diff и оповещает HUD.
func change_gold(diff: int) -> void:
	gold += diff
	Events.gold_changed.emit(gold)

## Изменяет количество кристаллов на diff и оповещает подписчиков.
func change_gems(diff: int) -> void:
	gems = max(0, gems + diff)
	Events.gems_changed.emit(gems)

## Изменяет количество жетонов на diff и оповещает подписчиков.
func change_tokens(diff: int) -> void:
	tokens = max(0, tokens + diff)
	Events.tokens_changed.emit(tokens)

## Изменяет количество воды на diff и оповещает подписчиков.
func change_water(diff: int) -> void:
	water = max(0, water + diff)
	Events.water_changed.emit(water)

# --- Уровень ---

## Устанавливает новый уровень (минимум 1) и оповещает HUD.
func set_level(new_level: int) -> void:
	level = max(1, new_level)
	Events.level_changed.emit(level)

# --- Управление состоянием ---

## Сбрасывает PROGRESS (новая игра, не resume).
## Используется когда сохранения нет (main_menu, first run).
func reset_game_stats() -> void:
	reset_session()
	level        = 1
	points       = 0

## Завершает сессию: обновляет лучший результат, счётчик игр, сохраняет прогресс и чистит game_state.
func end_game() -> void:
	if points > best_score:
		best_score = points
	games_played += 1
	SaveManager.save_progress(self)
	SaveManager.clear_game_state()

## Возвращает true, если есть сохранённое состояние (для кнопки "Продолжить").
func has_game_state() -> bool:
	return SaveManager.has_game_state()

## Сохраняет текущее состояние игры через SaveManager.
func save_game_state() -> void:
	SaveManager.save_game_state(self)

## Загружает сохранённое состояние и рассылает Events для обновления HUD.
func load_game_state() -> void:
	SaveManager.load_game_state(self)
	# Обновляем HUD по всем SESSION-данным одновременно
	Events.points_changed.emit(points)
	Events.health_changed.emit(health)
	Events.lives_count_changed.emit(lives_count)
	Events.gold_changed.emit(gold)
	Events.wheelbarrow_changed.emit(point_wheelbarrow)
	Events.level_changed.emit(level)
	Events.water_changed.emit(water)
	Events.xp_changed.emit(skill_xp, XpManager.xp_to_next_level(), "resume")
