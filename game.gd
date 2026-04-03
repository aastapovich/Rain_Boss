## Главный скрипт игровой сцены.
## Управляет игровыми состояниями, сложностью, паузой и переходами.
extends Node2D

const _CTX_CLASS := preload("res://Core/shop_context.gd")

enum GameState {PLAYING, PAUSED, GAME_OVER, VICTORY}

var current_state: GameState = GameState.PLAYING
var game_time: float = 0.0
var difficulty_multiplier: float = 1.0
var _shop_open: bool = false
var _popup_open: bool = false

const _MAIN_MENU_SCENE := preload("res://ui/main_menu/main_menu.tscn")
const _PLAYER_SCENE    := preload("res://Player/Player.tscn")
const _PLAYER_SCRIPT   := preload("res://Player/player_default.gd")
var _main_menu_instance: CanvasLayer = null

## Ссылка на текущий инстанс сцены уровня (потомок LevelContent).
var _level_instance: Node = null

var player: CharacterBody2D = null
## Ссылка на InventorySystem (для спавна bucket и будущих предметов).
@onready var _inventory    = $Progression/InventorySystem
@onready var _shop         = $CanvasLayer/Shop
@onready var game_over_ui  = $CanvasLayer/GameOver
@onready var victory_ui    = $CanvasLayer/Victory
@onready var hud           = $CanvasLayer/Hud
@onready var pause_menu    = $CanvasLayer/pause_menu
@onready var level_intro   = $CanvasLayer/LevelIntro
@onready var level_content = $LevelContent
## Ссылка на CloudLayer текущего уровня (null если уровень без облаков).
var cloud_layer: Node = null

## Инициализация: показывает главное меню поверх игровой сцены.
func _ready() -> void:
	_show_main_menu()

## Показывает главное меню как подгружаемую сцену поверх Game.tscn.
## Безопасно вызывать повторно (из victory/game_over) — чистит предыдущее состояние.
func _show_main_menu() -> void:
	# Убираем старый уровень
	if _level_instance and is_instance_valid(_level_instance):
		_level_instance.queue_free()
		_level_instance = null
	# Убираем старого игрока
	if player and is_instance_valid(player):
		player.queue_free()
		player = null
	# Сбрасываем UI-флаги
	current_state = GameState.PLAYING
	game_time = 0.0
	difficulty_multiplier = 1.0
	if victory_ui:
		victory_ui.visible = false
	if game_over_ui:
		game_over_ui.visible = false

	_main_menu_instance = _MAIN_MENU_SCENE.instantiate()
	add_child(_main_menu_instance)
	_main_menu_instance.continue_game.connect(_on_menu_continue)
	_main_menu_instance.new_game.connect(_on_menu_new_game)

## Вызывается когда игрок выбирает «Продолжить» в главном меню.
func _on_menu_continue() -> void:
	_main_menu_instance.queue_free()
	_main_menu_instance = null
	
	Globals.load_game_state()
	_spawn_player()
	_setup_game_events()
	_load_level(Globals.level, false)
	

## Вызывается когда игрок выбирает «Новая игра» в главном меню.
func _on_menu_new_game() -> void:
	_main_menu_instance.queue_free()
	_main_menu_instance = null
	_spawn_player()
	SaveManager.clear_game_state()
	Globals.reset_game_stats()
	_setup_game_events()
	_load_level(Globals.level, true)

## Создаёт и добавляет игрока в Elements (вызывается один раз при старте игры).
func _spawn_player() -> void:
	player = _PLAYER_SCENE.instantiate() as CharacterBody2D
	player.set_script(_PLAYER_SCRIPT)
	player.hand_align_left = -40.0
	player.name = "Player"
	$Elements.add_child(player)

## Подключает игровые события (вызывается единожды при старте игры из меню).
func _setup_game_events() -> void:
	if not Events.lives_count_changed.is_connected(_on_lives_changed):
		Events.lives_count_changed.connect(_on_lives_changed)
	if not Events.shop_opened.is_connected(_on_shop_opened):
		Events.shop_opened.connect(_on_shop_opened)
	Events.skill_level_changed.connect(func(_lvl): SaveManager.save_progress(Globals))
	Events.interact_triggered.connect(func(_t, _ti, _d): _popup_open = true)
	Events.interact_closed.connect(func(): _popup_open = false)
	if not _shop.closed.is_connected(_on_shop_closed):
		_shop.closed.connect(_on_shop_closed)
	if not pause_menu.resume_pressed.is_connected(_on_pause_resume):
		pause_menu.resume_pressed.connect(_on_pause_resume)
	if not pause_menu.menu_pressed.is_connected(_on_pause_menu):
		pause_menu.menu_pressed.connect(_on_pause_menu)
	if not pause_menu.quit_pressed.is_connected(_on_pause_quit):
		pause_menu.quit_pressed.connect(_on_pause_quit)

## Каждый кадр: увеличивает таймер игры, обновляет сложность и проверяет ESC.
func _process(delta: float):
	if _main_menu_instance:
		return
	if current_state == GameState.PLAYING:
		game_time += delta
		_update_difficulty()
	
	# Пауза на ESC — только если ни магазин, ни попап не открыты
	if Input.is_action_just_pressed("ui_cancel") and not _shop_open and not _popup_open:
		_toggle_pause()

## Пересчитывает множитель сложности: +20% каждые 30 секунд игры.
func _update_difficulty():
	difficulty_multiplier = 1.0 + (game_time / 30.0) * 0.05

## Срабатывает при изменении счётчика жизней — запускает Game Over при 0.
func _on_lives_changed(lives_count: int):
	if lives_count <= 0:
		_game_over()

## Открывает магазин: создаёт ShopContext из Globals и передаёт в shop.
func _on_shop_opened() -> void:
	_shop_open = true
	get_tree().paused = true
	_shop.open(_CTX_CLASS.from_globals())

## Применяет результат магазина: ctx → Globals.
## Спавн/деспавн тачки здесь не нужен — она живёт в сцене уровня постоянно.
func _on_shop_closed(ctx) -> void:
	ctx.apply_to_globals()
	Events.shop_closed.emit()
	get_tree().paused = false
	_shop_open = false

## Переводит игру в состояние Game Over, сохраняет прогресс и показывает экран.
func _game_over():
	current_state = GameState.GAME_OVER
	Globals.end_game()  # Сохраняем прогресс
	get_tree().paused = true
	if game_over_ui:
		game_over_ui.visible = true

## Вызывается из player.gd когда exit_point достигает максимума.
## Увеличивает уровень, сохраняет прогресс и показывает экран победы.
func victory():
	current_state = GameState.VICTORY
	# XP за переход уровня (множитель = номер текущего уровня)
	XpManager.add_xp("level_clear", Globals.level)
	# Бонус за первое прохождение уровня
	if Globals.games_played == 0 or Globals.best_score < Globals.points:
		XpManager.add_xp("level_first")
	Globals.set_level(Globals.level + 1)
	Globals.end_game()
	get_tree().paused = true
	if victory_ui:
		victory_ui.visible = true

## Загружает (или перезагружает) сцену уровня в слот LevelContent.
## show_intro=true показывает вступительный экран с описанием уровня.
func _load_level(level_id: int, show_intro: bool = true) -> void:
	var data: LevelData = LevelRegistry.get_level(level_id)
	if not data or not data.level_scene:
		push_error("_load_level: нет данных для level_id=%d" % level_id)
		return

	var is_resume: bool = Globals.has_game_state() and Globals.game_state_level_id == level_id

	# ── Сброс предыдущего уровня ─────────────────────────────────────────────
	if not is_resume:
		# Тачка живёт в сцене — деспавнить не нужно.
		# Для будущих спавнуемых предметов (bucket и др.) оставить:
		# _inventory.reset_for_level(Globals.active_equip_id)
		# Сбрасываем только сессионные данные (здоровье, тачка, позиция и т.д.)
		Globals.reset_session()

	# Очистить предыдущий контент уровня
	if _level_instance and is_instance_valid(_level_instance):
		_level_instance.queue_free()
		_level_instance = null

	# ── Загрузка новой сцены уровня ──────────────────────────────────────────
	_level_instance = data.level_scene.instantiate()
	level_content.add_child(_level_instance)

	# CloudLayer живёт в уровне
	cloud_layer = _level_instance.find_child("CloudLayer", true, false)
	if cloud_layer and not data.has_cloud_system:
		cloud_layer.visible = false

	# ── Настройка игрока ─────────────────────────────────────────────────────
	if player:
		if is_resume:
			print("[RESUME] player.gpos restored=%s  active_equip='%s'" % [Vector2(Globals.player_position_x, Globals.player_position_y), Globals.active_equip_id])
			player.global_position = Vector2(Globals.player_position_x, Globals.player_position_y)
		else:
			player.global_position = data.player_start_position

		player.max_exit_point = data.max_exit_point
		player.exit_point = 0
		Events.exit_point_changed.emit(0, data.max_exit_point)

	# ── Экипировка ───────────────────────────────────────────────────────────
	# Тачка живёт в сцене уровня постоянно — автоспавн при resume не нужен.
	# Для будущих спавнуемых предметов добавить вызов _inventory.spawn_active() здесь.

	# ── Интро уровня ─────────────────────────────────────────────────────────
	if show_intro and not is_resume and data.level_description != "" and level_intro:
		level_intro.show_intro(data.level_name, data.level_description, data.intro_image)

	_connect_level_signals()
## Переподключает межсценарные сигналы после загрузки нового level-pack.
func _connect_level_signals() -> void:
	if not _level_instance:
		return

	# drain → player: выгрузка тачки
	var drain = _level_instance.find_child("drain", true, false)
	if drain and player:
		if not drain.body_entered.is_connected(player._on_stop_player_body_entered):
			drain.body_entered.connect(player._on_stop_player_body_entered)
		if not drain.body_exited.is_connected(player._on_stop_player_body_exited):
			drain.body_exited.connect(player._on_stop_player_body_exited)

	# Assign level Unload controller to player
	var unload_node = _level_instance.find_child("Unload", true, false)
	if unload_node and player:
		player.unload_ctrl = unload_node
		# Try to (re)setup unload controller in player in case wheelbarrow already spawned
		if player.has_method("_setup_unload_controller"):
			player._setup_unload_controller()

	# Home → game: возврат игрока домой (деспавн врагов)
	var home = _level_instance.find_child("Home", true, false)
	if home:
		var home_area = home.find_child("Home", true, false) if home.get_child_count() > 0 else home
		if home_area and home_area.has_signal("body_entered"):
			if not home_area.body_entered.is_connected(_on_home_area_entered):
				home_area.body_entered.connect(_on_home_area_entered)

## Переключает паузу: PLAYING → PAUSED или обратно.
func _toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		pause_menu.visible = true
	elif current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false
		pause_menu.visible = false

## Возобновляет игру по команде из меню паузы.
func _on_pause_resume() -> void:
	_toggle_pause()

## Сохраняет прогресс и возвращает в главное меню.
func _on_pause_menu() -> void:
	_capture_player_transform()
	SaveManager.save_progress(Globals)
	SaveManager.save_game_state(Globals)
	get_tree().paused = false
	get_tree().reload_current_scene()

## Сохраняет прогресс и закрывает игру.
func _on_pause_quit() -> void:
	_capture_player_transform()
	SaveManager.save_progress(Globals)
	SaveManager.save_game_state(Globals)
	get_tree().quit()

## Записывает трансформ игрока в Globals перед сохранением состояния.
func _capture_player_transform() -> void:
	if not player:
		return
	Globals.player_position_x   = player.global_position.x
	print("[СОХРАНЕНИЕ] player.gpos=%s  active_equip='%s'" % [player.global_position, Globals.active_equip_id])
	Globals.player_position_y   = player.global_position.y
	Globals.player_facing_left  = player._facing_left
	Globals.game_state_level_id = Globals.level

## Перезапускает текущую сцену (используется кнопкой Restart).
func restart_game():
	get_tree().paused = false
	get_tree().reload_current_scene()

## Деспавн всех врагов и остановка спавна при возврате игрока домой.
func _on_home_area_entered(body: Node2D) -> void:
	if body.name == "Player":
		despawn_all_enemies()
		stop_all_spawn_zones()

## Удаляет всех живых врагов на сцене.
func despawn_all_enemies():
	var enemies = get_tree().get_nodes_in_group("hedgehogs")
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			enemy.despawn()

## Останавливает спавн во всех зарегистрированных зонах.
func stop_all_spawn_zones():
	var zones = get_tree().get_nodes_in_group("spawn_zones")
	for zone in zones:
		if zone and zone.has_method("stop_spawning"):
			zone.stop_spawning()
