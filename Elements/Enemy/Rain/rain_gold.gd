## Золотая капля: урон игроку (-20), вода в тачку (+10), +1 золото; падает быстрее воды.
## Эффекты (звук, брызги) и действия при попадании наследуются из RainDropBase.
## Переопределяй любой @export прямо в .tscn через Инспектор — код менять не нужно.
extends "res://Elements/Enemy/Rain/rain_drop_base.gd"

const _SPLASH   := preload("res://Elements/Enemy/Rain/rain_splash.tscn")
const _HitCfg   := preload("res://Elements/Enemy/Rain/drop_hit_config.gd")

func _ready() -> void:
	speed_min = 110.0
	speed_max = 130.0

	if splash_scene == null:
		splash_scene = _SPLASH

	if sounds.is_empty():
		sounds.append(preload("res://Assets/Sounds/blop0.mp3"))
		sounds.append(preload("res://Assets/Sounds/blop1.mp3"))
		sounds.append(preload("res://Assets/Sounds/blop2.mp3"))

	if hit_configs.is_empty():
		_add_default_hit_configs()

	super._ready()

## Дефолтная таблица попаданий для золота.
## Переопределяется через Инспектор в .tscn если hit_configs не пуст.
func _add_default_hit_configs() -> void:
	# Земля / стена → брызги, без лужи
	var ground := _HitCfg.new()
	ground.key_method = "rain_place"
	ground.call_args  = ["gold", "_pos_"]
	ground.do_splash  = true
	ground.do_puddle  = false
	hit_configs.append(ground)

		# Тачка (Wheel) → +10 воды + 1 золото через Globals
	var wheelbarrow := _HitCfg.new()
	wheelbarrow.key_method    = "rain_wheelbarrow_add"
	wheelbarrow.call_args     = [10, "gold"]
	wheelbarrow.globals_method = "change_gold"
	wheelbarrow.globals_args  = [1]
	wheelbarrow.do_splash     = false
	hit_configs.append(wheelbarrow)

	# Игрок → -20 HP
	var player := _HitCfg.new()
	player.key_method = "player_shot"
	player.call_args  = [-20, "gold"]
	player.do_splash  = true
	hit_configs.append(player)
