extends RigidBody2D

@export var flip_x_compensation: float = 0.0
@export var handle_offset: Vector2 = Vector2(0, -1)

## `handle_offset` — локальная позиция ручки внутри сцены ведра.
## Используется InventorySystem при прикреплении к игроку.
