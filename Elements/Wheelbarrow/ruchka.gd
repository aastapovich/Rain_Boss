## Ручка тачки (RigidBody2D): коллектор попадания капель в тачку.
## Прямая логика хранится в wheelbarrow.gd.
extends RigidBody2D

## Наполняет тачку: num очков воды данного типа.
func rain_wheelbarrow_add(num = 0, rain_type = "water"):
	print('Попал в ручку телеги: ', num, ' тип: ', rain_type)
