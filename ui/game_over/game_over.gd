## Экран Game Over: кнопка возвращает в главное меню.
extends CanvasLayer

## Снимает паузу и переходит в главное меню.
func _on_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")
