## Экран победы: переход к следующему уровню или в главное меню.
extends CanvasLayer

## Загружает следующий уровень через game.gd._load_level().
func _on_next_level_pressed():
	get_tree().paused = false
	var game = get_tree().root.get_node_or_null("Game")
	if game and game.has_method("_load_level"):
		game.current_state = game.GameState.PLAYING
		game.game_time = 0.0
		game.difficulty_multiplier = 1.0
		visible = false
		game._load_level(Globals.level)
	else:
		get_tree().reload_current_scene()

## Снимает паузу и переходит в главное меню.
func _on_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")
