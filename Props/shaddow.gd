extends Node2D

@onready var shadow: Sprite2D = $Shadow

func _ready() -> void:
	# Тень всегда смотрит в одну сторону, независимо от flip
	shadow.flip_h = false
	# Если камень зеркален — компенсируем смещение тени
	if $Sprite2D.flip_h:
		shadow.position.x = -shadow.position.x
