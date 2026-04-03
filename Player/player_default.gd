## Герой по умолчанию — стандартные параметры.
## Чтобы создать нового героя: создать новый .gd, унаследовать player_base,
## назначить нужный config через @export или preload в _ready().
extends "res://Player/player_base.gd"

const CONFIG_DEFAULT = preload("res://Player/configs/config_default.tres")

func _ready():
	config = CONFIG_DEFAULT
	super._ready()
