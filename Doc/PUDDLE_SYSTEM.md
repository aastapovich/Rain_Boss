# Система луж (Puddle System)

## Описание

Система луж создается при падении **обычных капель воды** на землю. Лужи замедляют движение игрока и существуют 10-15 секунд.

---

## Компоненты

### 1. Puddle (Rain/puddle.gd)
Класс лужи, наследуется от Area2D.

**Файл:** `Elements/Enemy/Rain/Rain/puddle.gd`

#### Параметры

```gdscript
const SPEED_REDUCTION: float = 0.5  # 50% замедление

# Настраиваемые параметры
@export var lifetime_min: float = 10.0  # Минимальное время жизни
@export var lifetime_max: float = 15.0  # Максимальное время жизни
@export var puddle_radius: float = 30.0  # Радиус лужи
```

#### Функции

- `_setup_collision()` - Создает круглую коллизию
- `_setup_visual()` - Использует анимацию брызг как визуал
- `_on_body_entered(body)` - Применяет замедление
- `_on_body_exited(body)` - Убирает замедление
- `_on_lifetime_expired()` - Удаляет лужу с fade-out эффектом

---

## Как это работает

### 1. Создание лужи

Когда **обычная капля воды** падает на землю:

```gdscript
# В place.gd
func rain_place(rain_type, rain_position):
	# ... анимация брызг
	
	# Создаем лужу только для обычных капель
	if rain_type == "water":
		_create_puddle(rain_position)
```

> 💡 **Важно:** Золотые и живительные капли НЕ создают луж!

### 2. Замедление игрока

Когда игрок входит в лужу:

```gdscript
# В Rain/puddle.gd
func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		_apply_slow_effect(body)

func _apply_slow_effect(player: Node):
	player.apply_puddle_slow(SPEED_REDUCTION)  # 50% замедление
```

В `player_base.gd`:

```gdscript
func apply_puddle_slow(slow_multiplier: float):
	puddle_slow_multiplier = slow_multiplier  # 0.5
	is_in_puddle = true
	# Визуальный эффект - синеватый оттенок

# В _physics_process:
speed *= puddle_slow_multiplier  # Применяем замедление
```

### 3. Исчезновение

Через 10-15 секунд (рандомно):

```gdscript
func _on_lifetime_expired():
	# Убираем эффект со всех игроков
	for player in affected_players:
		_remove_slow_effect(player)
	
	# Плавное исчезновение (fade out)
	var tween = create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 1.0)
	await tween.finished
	
	queue_free()
```

---

## Визуализация

### Текущая реализация

Лужа использует **анимацию брызг** как визуал:

```gdscript
# В Rain/puddle.gd
func _setup_visual():
	var splash_node = get_node_or_null("/root/Game/Elements/Animated_shwaps")
	visual.sprite_frames = splash_node.sprite_frames
	visual.play("Rain_splash")
	
	# Останавливаем на первом кадре
	await visual.animation_finished
	visual.frame = 0
	visual.pause()
	
	# Делаем синеватой и полупрозрачной
	visual.modulate = Color(0.5, 0.7, 1.0, 0.6)
	visual.scale = Vector2(1.2, 0.8)  # Растянутая форма
```

### Замена визуала (опционально)

Чтобы использовать свою текстуру лужи:

```gdscript
# Вариант 1: Спрайт
var sprite = Sprite2D.new()
sprite.texture = load("res://путь/к/текстуре/лужи.png")
add_child(sprite)

# Вариант 2: AnimatedSprite2D
var anim = AnimatedSprite2D.new()
anim.sprite_frames = load("res://путь/к/анимации.tres")
anim.play("puddle_idle")
add_child(anim)
```

---

## Настройка параметров

### Изменение силы замедления

В `Rain/puddle.gd` измените константу:

```gdscript
const SPEED_REDUCTION: float = 0.3  # 70% замедление (было 0.5)
```

### Изменение времени жизни

В `Rain/puddle.gd`:

```gdscript
@export var lifetime_min: float = 15.0  # Было 10.0
@export var lifetime_max: float = 25.0  # Было 15.0
```

Или при создании:

```gdscript
func _create_puddle(position: Vector2):
	var puddle = Area2D.new()
	puddle.set_script(PuddleScene)
	puddle.lifetime_min = 15.0
	puddle.lifetime_max = 25.0
	# ...
```

### Изменение размера лужи

```gdscript
@export var puddle_radius: float = 50.0  # Было 30.0
```

---

## Интеграция с игроком

### Требования к Player

Player должен иметь:

```gdscript
# 1. Быть в группе "player"
func _ready():
	add_to_group("player")  # Обязательно!

# 2. Методы для замедления
func apply_puddle_slow(slow_multiplier: float):
	puddle_slow_multiplier = slow_multiplier
	is_in_puddle = true

func remove_puddle_slow():
	puddle_slow_multiplier = 1.0
	is_in_puddle = false

# 3. Применение в physics_process
func _physics_process(delta):
	speed = base_speed * puddle_slow_multiplier  # Применяем модификатор
```

> ✅ **Уже реализовано** в `Elements/Player/Player_00/player_base.gd`

---

## Примеры использования

### Пример 1: Ручное создание лужи

```gdscript
# Создание лужи программно
var puddle = Area2D.new()
puddle.set_script(preload("res://Elements/Enemy/Rain/Rain/puddle.gd"))
get_parent().add_child(puddle)
puddle.global_position = Vector2(500, 300)
```

### Пример 2: Создание лужи с кастомными параметрами

```gdscript
var puddle = Area2D.new()
puddle.set_script(preload("res://Elements/Enemy/Rain/Rain/puddle.gd"))
puddle.puddle_radius = 50.0  # Большая лужа
puddle.lifetime_min = 20.0  # Долгая жизнь
puddle.lifetime_max = 30.0
add_child(puddle)
puddle.global_position = position
```

### Пример 3: Проверка, в луже ли игрок

```gdscript
# В любом скрипте
if player.is_in_puddle:
	print("Игрок в луже! Скорость: ", player.speed)
else:
	print("Игрок вне лужи")
```

---

## Слои коллизий

### Настройка в Rain/puddle.gd

```gdscript
func _ready():
	collision_layer = 0  # Лужа не физическое тело
	collision_mask = 1   # Обнаруживает игрока (слой 1)
```

### В Project Settings

**Physics → 2D → Layer Names:**
- Layer 1: `player`
- Layer 2: `enemy`
- Layer 3: `ground`

Лужа взаимодействует только с игроком (маска = 1).

---

## Отладка

### Включение визуализации коллизий

**Debug → Visible Collision Shapes** в редакторе Godot

### Проверка создания луж

Добавьте отладочные сообщения:

```gdscript
# В place.gd
func _create_puddle(position: Vector2):
	print("Создана лужа в позиции: ", position)
	var puddle = Area2D.new()
	# ...
```

### Проверка замедления

```gdscript
# В player_base.gd
func apply_puddle_slow(slow_multiplier: float):
	puddle_slow_multiplier = slow_multiplier
	print("Игрок замедлен до ", slow_multiplier * 100, "%")
```

---

## Оптимизация

### Ограничение количества луж

Добавьте в `place.gd`:

```gdscript
const MAX_PUDDLES: int = 10
var active_puddles: Array = []

func _create_puddle(position: Vector2):
	# Удаляем старую лужу если превышен лимит
	if active_puddles.size() >= MAX_PUDDLES:
		var oldest = active_puddles.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	
	var puddle = Area2D.new()
	# ...
	active_puddles.append(puddle)
```

### Дистанционный кулл

Удаление луж вдали от игрока:

```gdscript
# В Rain/puddle.gd
func _process(_delta):
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) > 1000:
		queue_free()  # Слишком далеко
```

---

## Расширение системы

### Разные типы луж

```gdscript
# Добавьте в Rain/puddle.gd
enum PuddleType {
	WATER,    # Обычная вода
	MUD,      # Грязь (сильное замедление)
	ICE,      # Лед (скольжение)
	POISON    # Яд (урон + замедление)
}

@export var puddle_type: PuddleType = PuddleType.WATER

const WATER_REDUCTION: float = 0.5
const MUD_REDUCTION: float = 0.3
const ICE_REDUCTION: float = 0.8  # Меньше замедление, но скользко

func _apply_slow_effect(player: Node):
	var slow_value = WATER_REDUCTION
	match puddle_type:
		PuddleType.MUD:
			slow_value = MUD_REDUCTION
		PuddleType.ICE:
			slow_value = ICE_REDUCTION
	
	player.apply_puddle_slow(slow_value)
```

### Лужа с уроном

```gdscript
# В Rain/puddle.gd
@export var deals_damage: bool = false
@export var damage_per_second: float = 1.0
var damage_timer: float = 0.0

func _process(delta):
	if deals_damage:
		damage_timer += delta
		if damage_timer >= 1.0:
			_deal_damage_to_players()
			damage_timer = 0.0

func _deal_damage_to_players():
	for player in affected_players:
		if player.has_method("take_damage"):
			player.take_damage(damage_per_second)
```

---

## Частые вопросы (FAQ)

**Q: Лужи не создаются?**  
A: Проверьте:
- Капля вызывает `rain_place("water", position)` с типом "water"
- В `place.gd` есть метод `_create_puddle()`
- Нет ошибок в консоли

**Q: Игрок не замедляется?**  
A: Убедитесь:
- Игрок добавлен в группу "player": `add_to_group("player")`
- У игрока есть методы `apply_puddle_slow()` и `remove_puddle_slow()`
- Коллизии настроены правильно (collision_mask = 1)

**Q: Как сделать, чтобы золотые капли тоже создавали лужи?**  
A: В `place.gd` измените условие:
```gdscript
# Было:
if rain_type == "water":
	_create_puddle(rain_position)

# Стало:
if rain_type in ["water", "gold"]:
	_create_puddle(rain_position)
```

**Q: Можно ли сделать визуальный эффект "волны" на луже?**  
A: Да! Добавьте shader или анимацию:
```gdscript
# Shader пример
shader_type canvas_item;
uniform float time_scale = 1.0;

void fragment() {
	vec2 uv = UV;
	uv.y += sin(uv.x * 10.0 + TIME * time_scale) * 0.01;
	COLOR = texture(TEXTURE, uv);
}
```

---

## Структура файлов

```
Elements/Enemy/Rain/
├── Rain/puddle.gd              # Класс лужи
├── rain_water.gd          # Обычная капля (создает лужи)
├── rain_gold.gd           # Золотая капля (не создает лужи)
└── rain_live.gd           # Живительная капля (не создает лужи)

Background/Wall/
└── place.gd               # Создает лужи при столкновении

Elements/Player/Player_00/
└── player_base.gd         # Обрабатывает замедление
```

---

## Changelog

### Version 1.0
- ✅ Создание луж при падении обычных капель
- ✅ Замедление игрока на 50%
- ✅ Время жизни 10-15 секунд
- ✅ Плавное исчезновение
- ✅ Визуал из анимации брызг
- ✅ Поддержка множественных луж

---

**Готово!** 🌧️ Система луж работает и интегрирована в игру.
