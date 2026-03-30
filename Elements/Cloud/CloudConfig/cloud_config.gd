class_name CloudConfig
extends Resource

## Конфигурация облака — описывает один тип облака (простое/дождевое/грозовое).
## Используется CloudEntity и CloudLayer. Хранится как .tres файл.

enum CloudType { SIMPLE = 0, RAIN = 1, STORM = 2 }

# --- Идентификация ---
## Тип облака: SIMPLE / RAIN / STORM
@export var cloud_type: CloudType = CloudType.SIMPLE

# --- Визуал ---
## Спрайты облака — при спавне выбирается рандомно один из массива (добавляй формы в Инспекторе)
@export var sprite_textures: Array[Texture2D] = []
## Диапазон масштаба по X (min, max)
@export var scale_x_range: Vector2 = Vector2(0.9, 1.5)
## Диапазон масштаба по Y (min, max)
@export var scale_y_range: Vector2 = Vector2(0.9, 1.1)

# --- Движение ---
## Скорость движения (px/sec)
@export var speed: float = 30.0

# --- Шейдер ---
## Затемнение (0 = нет, 1 = полностью тёмное)
@export_range(0.0, 1.0) var shader_darkness: float = 0.0
## Синий сдвиг (0 = нет, 1 = максимально синее)
@export_range(0.0, 1.0) var shader_blue_shift: float = 0.0

# --- Дождь ---
## Количество капель в секунду (0 = без дождя)
@export var rain_drops_per_second: float = 0.0
## Горизонтальный разброс капель (px)
@export var rain_spread_x: float = 40.0
