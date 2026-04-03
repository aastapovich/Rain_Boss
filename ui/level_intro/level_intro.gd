## Экран вступления к уровню (и вступление в игру).
## Показывает название и описание уровня с кнопкой «Продолжить».
## Вызов: level_intro.show_intro(title, description, image)
extends CanvasLayer

signal continued

@onready var bg_image    = $BgImage
@onready var bg_dim      = $BgDim
@onready var title_label  = $Panel/VBox/TitleLabel
@onready var desc_label   = $Panel/VBox/DescLabel
@onready var continue_btn = $Panel/VBox/ContinueButton

## Показывает экран вступления с заданным заголовком, текстом и необязательной картинкой.
func show_intro(title: String, description: String, image: Texture2D = null) -> void:
	title_label.text = title
	desc_label.text  = description
	if image:
		bg_image.texture = image
		bg_image.visible = true
		bg_dim.color     = Color(0, 0, 0, 0.45)
	else:
		bg_image.visible = false
		bg_dim.color     = Color(0, 0, 0, 0.72)
	visible = true
	get_tree().paused = true
	await get_tree().process_frame
	continue_btn.grab_focus()

## Закрывает экран вступления и возобновляет игру.
func _on_continue_pressed() -> void:
	visible = false
	get_tree().paused = false
	continued.emit()
