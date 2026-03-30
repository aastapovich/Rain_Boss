## Экран вступления к уровню (и вступление в игру).
## Показывает название и описание уровня с кнопкой «Продолжить».
## Вызов: level_intro.show_intro(title, description)
extends CanvasLayer

signal continued

@onready var title_label  = $Panel/VBox/TitleLabel
@onready var desc_label   = $Panel/VBox/DescLabel
@onready var continue_btn = $Panel/VBox/ContinueButton

## Показывает экран вступления с заданным заголовком и текстом описания.
func show_intro(title: String, description: String) -> void:
	title_label.text = title
	desc_label.text  = description
	visible = true
	get_tree().paused = true
	await get_tree().process_frame
	continue_btn.grab_focus()

## Закрывает экран вступления и возобновляет игру.
func _on_continue_pressed() -> void:
	visible = false
	get_tree().paused = false
	continued.emit()
