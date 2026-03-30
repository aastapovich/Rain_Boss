extends Node2D

@onready var sprite: Sprite2D = $Rock1_1
@onready var shadow: Sprite2D = $Shadow

func _ready() -> void:
	# Тень всегда смотрит в одну сторону, независимо от flip
	shadow.flip_h = false
	# Если камень зеркален — компенсируем смещение тени
	if sprite.flip_h:
		shadow.position.x = -shadow.position.x
