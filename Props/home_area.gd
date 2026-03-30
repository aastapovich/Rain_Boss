extends Area2D

const SPLASH_SCENE := preload("res://Elements/Enemy/Rain/rain_splash.tscn")

## Зона крыши дома: капли дождя при попадании дают брызги, но не наносят урона и не оставляют луж.
## Привяжи этот скрипт к узлу Home/Home/Home (Area2D) в редакторе.
##
## ⚠ Условие работы: у капель дождя (Area2D) и у этого Area2D должны совпадать Collision Layer/Mask.
## Обычно достаточно добавить в Mask этого узла тот слой, на котором находятся Rain-капли.

func _ready() -> void:
	area_entered.connect(_on_rain_entered)

func _on_rain_entered(area: Area2D) -> void:
	var splash := SPLASH_SCENE.instantiate()
	get_tree().current_scene.add_child(splash)
	splash.global_position = area.global_position
	area.queue_free()
