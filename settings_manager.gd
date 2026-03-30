extends Node

# Автозагрузка: "Settings"
# Только аудионастройки. Прогресс и состояние игры — в SaveManager.

const CONFIG_PATH = "user://settings.cfg"

var _config := ConfigFile.new()

func _ready() -> void:
	if _config.load(CONFIG_PATH) != OK:
		_set_defaults()
		_save()
	apply_audio()

# --- Применение ---

## Устанавливает громкость на шинах Master, Music и SFX.
func apply_audio() -> void:
	_set_bus("Master", get_master_volume())
	_set_bus("Music",  get_music_volume())
	_set_bus("SFX",    get_sfx_volume())

# --- Геттеры ---

## Возвращает громкость Master (0.0–1.0).
func get_master_volume() -> float:
	return _config.get_value("audio", "master_volume", 0.5)

## Возвращает громкость Music (0.0–1.0).
func get_music_volume() -> float:
	return _config.get_value("audio", "music_volume", 0.6)

## Возвращает громкость SFX (0.0–1.0).
func get_sfx_volume() -> float:
	return _config.get_value("audio", "sfx_volume", 0.5)

# --- Сеттеры ---

## Сохраняет и применяет громкость Master.
func set_master_volume(value: float) -> void:
	_config.set_value("audio", "master_volume", value)
	_save()
	apply_audio()

## Сохраняет и применяет громкость Music.
func set_music_volume(value: float) -> void:
	_config.set_value("audio", "music_volume", value)
	_save()
	apply_audio()

## Сохраняет и применяет громкость SFX.
func set_sfx_volume(value: float) -> void:
	_config.set_value("audio", "sfx_volume", value)
	_save()
	apply_audio()

# --- Внутренние ---

## Записывает значения по умолчанию в новый файл.
func _set_defaults() -> void:
	_config.set_value("audio", "master_volume", 0.8)
	_config.set_value("audio", "music_volume",  0.7)
	_config.set_value("audio", "sfx_volume",    0.9)

## Сохраняет конфиг в файл.
func _save() -> void:
	_config.save(CONFIG_PATH)

func _set_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))
