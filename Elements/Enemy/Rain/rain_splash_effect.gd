## Анимированные брызги дождя — самоудаляющийся эффект.
## Воспроизводит анимацию Rain_splash и удаляет себя по окончании.
extends AnimatedSprite2D

func _ready() -> void:
	play("Rain_splash")
	animation_finished.connect(queue_free)
