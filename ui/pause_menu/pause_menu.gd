## Меню паузы: работает даже когда дерево на паузе (PROCESS_MODE_ALWAYS).
## Испускает сигналы resume_pressed, menu_pressed, quit_pressed в game.gd.
extends CanvasLayer

signal resume_pressed
signal menu_pressed
signal quit_pressed

## Включает always-режим и устанавливает фокус на первую кнопку.
func _ready():
	# Устанавливаем режим обработки - работает даже на паузе
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Устанавливаем фокус на кнопку "Продолжить"
	$Background/Container/ResumeButton.grab_focus()

## Испускает сигнал продолжения игры.
func _on_resume_button_pressed():
	resume_pressed.emit()

## Испускает сигнал выхода в главное меню.
func _on_menu_button_pressed():
	menu_pressed.emit()

## Испускает сигнал выхода из игры.
func _on_quit_button_pressed():
	quit_pressed.emit()
