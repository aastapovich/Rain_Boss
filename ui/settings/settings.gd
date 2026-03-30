## Экран настроек: слайдеры громкости и сохранение через автозагрузку Settings.
extends CanvasLayer

@onready var master_slider = $Panel/TabContainer/Audio/MasterVolume
@onready var master_label = $Panel/TabContainer/Audio/MasterValue
@onready var music_slider = $Panel/TabContainer/Audio/MusicVolume
@onready var music_label = $Panel/TabContainer/Audio/MusicValue
@onready var sfx_slider = $Panel/TabContainer/Audio/SFXVolume
@onready var sfx_label = $Panel/TabContainer/Audio/SFXValue
@onready var ui_sound = $AudioStreamPlayer

## Загружает настройки, обновляет метки и показывает анимацию появления.
func _ready():
	load_settings()
	update_labels()
	
	# Анимация появления
	animate_entrance()

## Анимация при открытии: панель появляется из малого с плавно.
func animate_entrance():
	var panel = $Panel
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2(1, 1), 0.3).from(Vector2(0.8, 0.8))
	tween.tween_property(panel, "modulate:a", 1.0, 0.3).from(0.0)

## Загружает значения слайдеров из автозагрузки Settings.
func load_settings():
	# Загружаем значения из глобального менеджера
	var settings = get_node("/root/Settings")
	if settings:
		var master_vol = settings.get_master_volume()
		var music_vol = settings.get_music_volume()
		var sfx_vol = settings.get_sfx_volume()
		
		master_slider.value = master_vol
		music_slider.value = music_vol
		sfx_slider.value = sfx_vol

## Сохраняет значения слайдеров через автозагрузку Settings и применяет их.
func save_settings():
	# Сохраняем через глобальный менеджер
	var settings = get_node("/root/Settings")
	if settings:
		settings.set_master_volume(master_slider.value)
		settings.set_music_volume(music_slider.value)
		settings.set_sfx_volume(sfx_slider.value)

func apply_audio_settings():
	var settings = get_node("/root/Settings")
	if settings:
		settings.set_master_volume(master_slider.value)
		settings.set_music_volume(music_slider.value)
		settings.set_sfx_volume(sfx_slider.value)

## Обновляет метки слайдеров в процентах.
func update_labels():
	master_label.text = str(int(master_slider.value * 100)) + "%"
	music_label.text = str(int(music_slider.value * 100)) + "%"
	sfx_label.text = str(int(sfx_slider.value * 100)) + "%"

## Срабатывает при изменении общей громкости.
func _on_master_volume_changed(_value: float):
	update_labels()
	apply_audio_settings()
	play_ui_sound()

## Срабатывает при изменении громкости музыки.
func _on_music_volume_changed(_value: float):
	update_labels()
	apply_audio_settings()
	play_ui_sound()

## Срабатывает при изменении громкости SFX.
func _on_sfx_volume_changed(_value: float):
	update_labels()
	apply_audio_settings()
	play_ui_sound()

## Сохраняет настройки и показывает подтверждение.
func _on_save_pressed():
	save_settings()
	play_ui_sound()
	
	# Показываем сообщение о сохранении
	show_save_message()

## Закрывает себя: анимация исчезновения и queue_free.
func _on_back_pressed():
	play_ui_sound()
	
	# Анимация исчезновения
	var panel = $Panel
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.2)
	tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(Callable(self, "queue_free"))

## Воспроизводит звук UI (один раз за действие).
func play_ui_sound():
	if ui_sound and not ui_sound.playing:
		ui_sound.play()

## Показывает надпись "Настройки сохранены!" c анимацией появления/исчезновения.
func show_save_message():
	var label = Label.new()
	label.text = "Настройки сохранены!"
	label.add_theme_font_size_override("font_size", 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 100, get_viewport().get_visible_rect().size.y / 2 - 50)
	label.modulate = Color(0, 1, 0)
	
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3).from(0.0)
	await get_tree().create_timer(2.0).timeout
	tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(Callable(label, "queue_free"))
