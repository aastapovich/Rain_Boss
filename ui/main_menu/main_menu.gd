## Главное меню: кнопки, музыка, анимации облаков и переход к игре.
## Логика запуска игры управляется извне через сигналы (из game.gd).
extends CanvasLayer

signal continue_game
signal new_game

@onready var continue_button = $MenuContainer/ContinueButton
@onready var play_button = $MenuContainer/PlayButton
@onready var settings_button = $MenuContainer/SettingsButton
@onready var credits_button = $MenuContainer/CreditsButton
@onready var quit_button = $MenuContainer/QuitButton
@onready var menu_music = $MenuMusic
@onready var ui_sound = $UISound
@onready var clouds = [$Background/Clouds, $Background/Cloud2, $Background/Cloud3]

## Инициализация: фокус, аудионастройки, анимации облаков и появление меню.
func _ready():
	# Кнопка "Продолжить" — только если есть сохранённая сессия
	var has_save := Globals.has_game_state()
	continue_button.visible = has_save
	if has_save:
		continue_button.grab_focus()
	else:
		play_button.grab_focus()
	
	# Применяем настройки громкости
	apply_audio_settings()
	
	# Запускаем анимацию облаков
	animate_clouds()
	
	# Добавляем анимацию появления меню
	_animate_menu_entrance()

## Анимация появления заголовка и последовательное появление кнопок.
func _animate_menu_entrance():
	# Анимация появления заголовка
	var title = $MenuContainer
	var tween = create_tween()
	tween.tween_property(title, "modulate:a", 1.0, 1.0).from(0.0)
	tween.tween_property(title, "scale", Vector2(1.1, 1.1), 0.3)
	tween.tween_property(title, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Анимация появления кнопок
	var buttons = $MenuContainer.get_children()
	for i in range(buttons.size()):
		var button = buttons[i]
		button.modulate.a = 0.0
		var button_tween = create_tween()
		button_tween.tween_property(button, "modulate:a", 1.0, 0.5)
		button_tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.2).from(Vector2(0.8, 0.8))
		button_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
		await get_tree().create_timer(0.1 * i).timeout

## Продолжает сохранённую сессию.
func _on_continue_pressed():
	play_ui_sound()
	_animate_button_press(continue_button)
	await get_tree().create_timer(0.3).timeout
	if menu_music.playing:
		menu_music.stop()
	continue_game.emit()

## Начинает новую игру.
func _on_play_pressed():
	play_ui_sound()
	_animate_button_press(play_button)
	await get_tree().create_timer(0.3).timeout
	if menu_music.playing:
		menu_music.stop()
	new_game.emit()

## Открывает экран настроек.
func _on_settings_pressed():
	play_ui_sound()
	# Анимация нажатия
	_animate_button_press(settings_button)
	await get_tree().create_timer(0.3).timeout
	
	# Открыть настройки
	var settings_scene = preload("res://ui/settings/settings.tscn").instantiate()
	get_parent().add_child(settings_scene)

## Показывает диалог «Об игре».
func _on_credits_pressed():
	play_ui_sound()
	# Анимация нажатия
	_animate_button_press(credits_button)
	await get_tree().create_timer(0.3).timeout
	
	# Показать информацию об игре
	_show_credits()

## Закрывает приложение.
func _on_quit_pressed():
	play_ui_sound()
	# Анимация нажатия
	_animate_button_press(quit_button)
	await get_tree().create_timer(0.3).timeout
	
	# Выход из игры
	get_tree().quit()

## Анимация нажатия кнопки ((лёгкое сжатие).
func _animate_button_press(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)

## Показывает диалог AcceptDialog с текстом об игре и управлением.
func _show_credits():
	# Создаем диалог с информацией об игре
	var credits_dialog = AcceptDialog.new()
	credits_dialog.title = "Об игре"
	credits_dialog.dialog_text = """
RAIN BOSS - Собери или найди воду!

Цель игры:
	Необходимо находить и собирать воду - дождевые капли,
воду из ручейков и луж, колодцев и водопроводов, и перевози
с помощью тележки в канал. За собранную воду начисляются очки.
	Вода наполняет канал и поднимает переправу, для перехода в
следующий уровень

Управление:
• A/D или ←/→ - движение
• Shift - бег
• ESC - пауза

Разработано с помощью Godot Engine
Версия 1.03
"""
	
	credits_dialog.size = Vector2(500, 400)
	add_child(credits_dialog)
	credits_dialog.popup_centered()

## Применяет сохранённые настройки громкости к музыке и звуковым эффектам.
func apply_audio_settings():
	# Применяем сохраненные настройки громкости
	var settings = get_node("/root/Settings")
	if settings:
		var master_vol = settings.get_master_volume()
		var music_vol = settings.get_music_volume()
		
		menu_music.volume_db = linear_to_db(music_vol) - 15.0  # -15 базовая громкость
		ui_sound.volume_db = linear_to_db(master_vol) - 10.0   # -10 базовая громкость

## Воспроизводит звук нажатия кнопки (один раз за нажатие).
func play_ui_sound():
	if ui_sound and not ui_sound.playing:
		ui_sound.play()

## Запускает бесконечный Tween-параллакс для каждого облака меню.
func animate_clouds():
	# Анимируем каждое облако с разной скоростью и направлением
	for i in range(clouds.size()):
		var cloud = clouds[i]
		var tween = create_tween()
		tween.set_loops()  # Бесконечный цикл
		
		# Разные скорости для разных облаков
		var duration = 20.0 + i * 10.0  # 20, 30, 40 секунд
		var cloud_offset = Vector2(50 + i * 30, 0)  # Разные смещения
		
		# Двигаем облако вправо и влево
		tween.tween_property(cloud, "position", cloud.position + cloud_offset, duration / 2.0)
		tween.tween_property(cloud, "position", cloud.position - cloud_offset, duration / 2.0)
		
		# Добавляем легкое вертикальное движение
		var vertical_tween = create_tween()
		vertical_tween.set_loops()
		var vertical_offset = Vector2(0, 10 + i * 5)
		vertical_tween.tween_property(cloud, "position:y", cloud.position.y + vertical_offset.y, duration * 0.7)
		vertical_tween.tween_property(cloud, "position:y", cloud.position.y - vertical_offset.y, duration * 0.7)
