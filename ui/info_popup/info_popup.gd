## InfoPopup — информационный попап для InteractZone.
## Слушает Events.interact_triggered(type=="info") и показывает заголовок + описание.
## Не паузит игру — только блокирует ESC через флаг _popup_open в game.gd.
extends CanvasLayer

@onready var _panel: PanelContainer       = $Panel
@onready var _title_label: Label          = $Panel/VBox/TitleLabel
@onready var _desc_label: RichTextLabel   = $Panel/VBox/DescLabel
@onready var _close_btn: Button           = $Panel/VBox/CloseButton

func _ready() -> void:
	visible = false
	Events.interact_triggered.connect(_on_interact_triggered)
	_close_btn.pressed.connect(_on_close_pressed)

func _on_interact_triggered(interact_type: String, title: String, description: String) -> void:
	if interact_type != "info":
		return
	_title_label.text = title
	_desc_label.text  = description
	visible = true
	await get_tree().process_frame
	_close_btn.grab_focus()

func _on_close_pressed() -> void:
	visible = false
	Events.interact_closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()
