# Quick Start Guide - Система врагов

## Быстрый старт за 5 минут

### Шаг 1: Настройка EnemyManager (1 минута)

1. Откройте **Project → Project Settings → AutoLoad**
2. Нажмите **Add** (значок папки)
3. Выберите `Core/enemy_manager.gd`
4. Имя: `EnemyManager`
5. Нажмите **Add**

✅ **Готово!** EnemyManager теперь доступен глобально.

---

### Шаг 2: Создание конфигурации врага (2 минуты)

#### Способ 1: Через редактор (рекомендуется)

1. В FileSystem, ПКМ на папке `Elements/Enemy/configs/`
2. **New Resource**
3. Найдите и выберите **EnemyData**
4. Сохраните как `my_enemy.tres`
5. Настройте параметры в Inspector:
   - **Enemy Id**: `my_enemy`
   - **Enemy Name**: `Мой враг`
   - **Speed**: `50.0`
   - **AI Type**: `FOLLOW_PLAYER`
   - Остальное оставьте по умолчанию

#### Способ 2: Использовать готовый пример

```gdscript
# В вашем скрипте
func _ready():
    # Загружаем один из примеров
    var config = preload("res://Elements/Enemy/configs/enemy_config_examples.gd")
    var enemy_data = config.create_hedgehog_aggressive()
    
    # Используем
    EnemyManager.spawn_enemy(enemy_data, Vector2(500, 300))
```

---

### Шаг 3: Создание врага (2 минуты)

#### Вариант A: Прямое создание в коде

```gdscript
# В любом скрипте, например в game.gd
func _ready():
    # Загружаем конфигурацию
    var enemy_data = load("res://Elements/Enemy/configs/my_enemy.tres")
    
    # Создаем врага в позиции (500, 300)
    var enemy = EnemyManager.spawn_enemy(enemy_data, Vector2(500, 300))
    
    print("Враг создан: ", enemy.enemy_data.enemy_name)
```

#### Вариант B: С использованием спавнера

1. В вашей сцене добавьте **Node2D**
2. Переименуйте в `EnemySpawner`
3. Прикрепите скрипт `Elements/Enemy/enemy_spawner.gd`
4. В Inspector установите:
   - **Enemy Data**: выберите `my_enemy.tres`
   - **Enabled**: ✓
   - **Spawn Trigger**: `TIMER` (или другой)

Враг будет автоматически создаваться по таймеру!

---

## Готовые примеры для копирования

### Пример 1: Ёжик-агрессор

```gdscript
# Создание через код
func spawn_aggressive_hedgehog():
    var data = EnemyData.new()
    data.enemy_id = "hedgehog_aggressive"
    data.speed = 50.0
    data.ai_type = EnemyData.AIType.AGGRESSIVE
    data.damage_type = EnemyData.DamageType.CONTINUOUS
    data.damage_player = 5.0
    data.damage_interval = 1.0
    data.can_steal_water = true
    data.water_steal_amount = 5.0
    data.water_steal_interval = 5.0
    data.is_immortal = true
    
    return EnemyManager.spawn_enemy(data, player.global_position + Vector2(-150, 0))
```

### Пример 2: Территориальная пчела

```gdscript
func spawn_bee_at_hive(hive_position: Vector2):
    var data = EnemyData.new()
    data.enemy_id = "bee"
    data.speed = 80.0
    data.has_gravity = false  # Летает!
    data.ai_type = EnemyData.AIType.PATROL
    data.damage_type = EnemyData.DamageType.CONTINUOUS
    data.damage_player = 2.0
    data.damage_interval = 0.5
    data.is_immortal = true
    
    return EnemyManager.spawn_enemy(data, hive_position)
```

### Пример 3: Спавнер с триггером

```gdscript
# В сцене создайте:
# 1. Area2D с CollisionShape2D (назовите TriggerArea)
# 2. Node2D с enemy_spawner.gd (назовите Spawner)

# Подключение в скрипте уровня:
func _ready():
    var spawner = $Spawner
    var trigger = $TriggerArea
    
    # Настройка
    spawner.trigger_area = trigger
    spawner.enemy_data = load("res://Elements/Enemy/configs/my_enemy.tres")
    spawner.spawn_parent = $Enemies  # Где создавать врагов
```

---

## Частые задачи

### Удалить всех врагов
```gdscript
EnemyManager.clear_all_enemies()
```

### Заморозить врагов (пауза)
```gdscript
func _on_pause_toggled(paused: bool):
    EnemyManager.freeze_all_enemies(paused)
```

### Узнать количество врагов
```gdscript
var total = EnemyManager.get_total_active_count()
var hedgehogs = EnemyManager.get_active_count("hedgehog_aggressive")
print("Всего врагов: ", total, ", ёжиков: ", hedgehogs)
```

### Отследить смерть врага
```gdscript
func _ready():
    EnemyManager.enemy_died.connect(_on_enemy_died)

func _on_enemy_died(enemy: BaseEnemy):
    print("Убит: ", enemy.enemy_data.enemy_name)
    # Дать награду игроку
    player.add_score(100)
```

---

## Интеграция с Player

Добавьте в скрипт игрока:

```gdscript
extends CharacterBody2D

# Здоровье
var max_health: float = 100.0
var current_health: float = 100.0

# Вода
var max_water: float = 100.0
var current_water: float = 50.0

# Улучшения (опционально)
var gloves_level: int = 0
var boots_level: int = 0
var cloak_level: int = 0
var wheelbarrow_level: int = 0

func _ready():
    add_to_group("player")  # Важно!

func take_damage(amount: float):
    current_health -= amount
    if current_health <= 0:
        die()

func get_water_amount() -> float:
    return current_water

func steal_water(amount: float):
    current_water = max(0, current_water - amount)

func die():
    # Логика смерти игрока
    print("Game Over")
```

---

## Отладка

Включите отладочный режим:

```gdscript
func _ready():
    EnemyManager.enable_debug = true
```

Просмотр информации в реальном времени:

```gdscript
func _process(_delta):
    if Input.is_action_just_pressed("ui_accept"):  # Пробел
        EnemyManager.print_debug_info()
```

---

## Что дальше?

- 📖 Прочитайте полную документацию: [ENEMY_SYSTEM.md](ENEMY_SYSTEM.md)  
- 🔧 Изучите примеры конфигураций: `Elements/Enemy/configs/enemy_config_examples.gd`
- 🎮 Создайте своих уникальных врагов, наследуясь от BaseEnemy
- 💡 Экспериментируйте с параметрами AI и поведения

---

## Помощь

**Проблема:** Враги не появляются  
**Решение:** 
1. Проверьте, что EnemyManager добавлен в AutoLoad
2. Убедитесь, что `enemy_data` установлен в спавнере
3. Включите `enable_debug = true` и проверьте консоль

**Проблема:** Ошибка "Node not found: player"  
**Решение:** Добавьте игрока в группу: `add_to_group("player")`

**Проблема:** Враги не наносят урон  
**Решение:** Убедитесь, что у игрока есть метод `take_damage(amount: float)`

---

**Готово!** 🎉 Теперь у вас работает полноценная система врагов!
