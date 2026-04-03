## Экран Game Over: кнопка возвращает в главное меню.
extends CanvasLayer

## Снимает паузу и возвращает в главное меню через game.gd.
func _on_button_pressed():
	get_tree().paused = false
	var game = get_tree().root.get_node_or_null("Game")
	if game and game.has_method("_show_main_menu"):
		visible = false
		game._show_main_menu()
	else:
		get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")
