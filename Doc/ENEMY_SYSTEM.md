# Унифицированная система врагов (Enemy System)

## Обзор

Универсальная система управления врагами для Godot 4.x, основанная на данных (data-driven) и использующая паттерн Component-Based Architecture.

### Основные компоненты

1. **EnemyData** (Resource) - Конфигурация врага
2. **BaseEnemy** (CharacterBody2D) - Базовый класс всех врагов
3. **EnemySpawner** (Node2D) - Спавнер врагов
4. **EnemyManager** (AutoLoad) - Глобальный менеджер

---

## Архитектура

```
┌─────────────────────────────────────────────┐
│          EnemyManager (AutoLoad)            │
│  - Регистрация всех врагов                  │
│  - Управление спавнерами                    │
│  - Статистика                               │
└─────────────────────┬───────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        │                           │
┌───────▼────────┐        ┌─────────▼────────┐
│ EnemySpawner   │        │   BaseEnemy      │
│ - Условия      │◄───────┤   - AI Logic     │
│ - Таймеры      │spawns  │   - Урон/Кража   │
└────────┬───────┘        └──────────────────┘
         │uses                     │uses
         │                         │
    ┌────▼────────┐                │
    │ EnemyData   │◄───────────────┘
    │ (Resource)  │
    └─────────────┘
```

---

## 1. EnemyData (Resource)

### Описание
Конфигурация врага в формате Resource. Хранит все параметры: внешний вид, характеристики, AI, условия спавна и исчезновения.

### Создание конфигурации

#### Способ 1: Через редактор Godot (рекомендуется)
1. ПКМ в FileSystem → New Resource
2. Выберите `EnemyData`
3. Сохраните как `enemy_name.tres`
4. Настройте параметры в Inspector

#### Способ 2: Через код
```gdscript
var enemy_data = EnemyData.new()
enemy_data.enemy_id = "hedgehog_aggressive"
enemy_data.enemy_name = "Назойливый агрессор"
enemy_data.speed = 50.0
# ... остальные параметры
```

### Основные группы параметров

#### 1. Основная информация
- `enemy_id` - Уникальный идентификатор
- `enemy_name` - Название для UI
- `description` - Описание поведения

#### 2. Внешний вид
- `scene` - PackedScene (если есть кастомная сцена)
- `sprite_frames` - SpriteFrames для анимаций
- `default_animation` - Анимация по умолчанию
- `scale` - Масштаб врага

#### 3. Физические параметры
- `speed` - Базовая скорость
- `speed_variance` - Разброс скорости (мин, макс)
- `has_gravity` - Использовать гравитацию
- `collision_layer/mask` - Слои коллизий

#### 4. Боевые характеристики
- `damage_type` - Тип урона (NONE, SINGLE, CONTINUOUS, ON_COLLISION)
- `damage_player` - Урон игроку
- `damage_wheelbarrow` - Урон тачке
- `damage_is_percent` - Урон в процентах
- `damage_interval` - Интервал урона

#### 5. Кража воды
- `can_steal_water` - Может красть воду
- `water_steal_amount` - Количество
- `water_steal_is_percent` - В процентах
- `water_steal_interval` - Интервал кражи
- `flee_if_no_water` - Убегает при пустой тачке

#### 6. AI и поведение
- `ai_type` - Тип AI:
  - `IDLE` - Стоит на месте (территориальный)
  - `PATROL` - Патрулирует
  - `FOLLOW_PLAYER` - Преследует
  - `FLEE_PLAYER` - Убегает
  - `THIEF` - Воришка (держится на дистанции)
  - `AGGRESSIVE` - Агрессор (прилипает)
- `aggression` - Уровень агрессии (влияет на поведение)
- `target_distance` - Целевая дистанция
- `detection_radius` - Радиус обнаружения

#### 7. Условия появления
- `spawn_trigger` - Триггер спавна:
  - `MANUAL` - Ручное создание
  - `TIMER` - По таймеру
  - `AREA_ENTER` - При входе в область
  - `PLAYER_ACTION` - При действии игрока
  - `CONDITION` - При условии
- `spawn_delay_min/max` - Задержка спавна
- `spawn_probability` - Вероятность (0.0-1.0)
- `max_instances` - Максимальное количество

#### 8. Условия исчезновения
- `idle_timeout` - Тайм-аут бездействия
- `despawn_on_player_stop` - При остановке игрока
- `despawn_on_empty_water` - При пустой тачке
- `despawn_on_home_return` - При возврате домой

#### 9. Модификаторы от улучшений
- `affected_by_*` - Влияние перчаток, сапог, плаща, тачки
- `damage_reduction_per_upgrade` - Снижение урона за уровень (15%)

---

## 2. BaseEnemy (CharacterBody2D)

### Описание
Базовый класс для всех врагов. Реализует общую логику AI, урона, кражи воды, анимации.

### Использование

#### Способ 1: Использовать BaseEnemy напрямую
```gdscript
var enemy = BaseEnemy.new()
enemy.enemy_data = my_enemy_data
add_child(enemy)
```

#### Способ 2: Наследование для специфического поведения
```gdscript
extends BaseEnemy
class_name CustomEnemy

func _custom_behavior(delta: float):
    # Ваша специфическая логика
    if some_condition:
        do_something()
```

### Сигналы
- `enemy_died(enemy)` - Враг умер
- `enemy_despawned(enemy)` - Враг исчез
- `player_damaged(damage, enemy)` - Нанесен урон игроку
- `water_stolen(amount, enemy)` - Украдена вода

### Основные методы
- `take_damage(amount)` - Получить урон
- `die()` - Смерть врага
- `despawn()` - Исчезновение
- `_custom_behavior(delta)` - Переопределяемый метод для кастомного поведения

### AI система
BaseEnemy автоматически обрабатывает поведение на основе `ai_type`:
- **IDLE** - Стоит на месте, атакует при приближении
- **PATROL** - Патрулирует область
- **FOLLOW_PLAYER** - Преследует на определенной дистанции
- **FLEE_PLAYER** - Убегает от игрока
- **THIEF** - Держится на безопасной дистанции, крадет воду
- **AGGRESSIVE** - Прилипает к игроку, убегает если игрок поворачивается

---

## 3. EnemySpawner (Node2D)

### Описание
Управляет спавном врагов по условиям и таймерам.

### Настройка в редакторе
1. Добавьте ноду `Node2D` в сцену
2. Прикрепите скрипт `enemy_spawner.gd`
3. Установите `enemy_data` (ссылка на EnemyData)
4. Опционально: настройте `trigger_area` для триггера AREA_ENTER
5. Настройте `spawn_parent` для определения родителя созданных врагов

### Использование в коде
```gdscript
# Получить спавнер
var spawner = $EnemySpawner

# Принудительный спавн
spawner.force_spawn()

# Удалить всех врагов спавнера
spawner.despawn_all()

# Получить количество активных
var count = spawner.get_active_count()
```

### Сигналы
- `enemy_spawned(enemy)` - Враг создан
- `spawn_conditions_met(enemy_data)` - Условия спавна выполнены

---

## 4. EnemyManager (AutoLoad)

### Описание
Глобальный singleton для управления всей системой врагов.

### Настройка
1. Откройте Project → Project Settings → AutoLoad
2. Добавьте `Core/enemy_manager.gd` как `EnemyManager`

### Использование

```gdscript
# Создать врага по ID конфигурации
var enemy = EnemyManager.spawn_enemy_by_id("hedgehog_aggressive", position)

# Создать врага по конфигурации
var enemy = EnemyManager.spawn_enemy(enemy_data, position, parent_node)

# Получить количество активных врагов
var total = EnemyManager.get_total_active_count()
var hedgehogs = EnemyManager.get_active_count("hedgehog_aggressive")

# Получить всех врагов
var all_enemies = EnemyManager.get_all_active_enemies()

# Удалить всех врагов
EnemyManager.clear_all_enemies()

# Удалить врагов по типу
EnemyManager.clear_enemies_by_type("hedgehog_aggressive")

# Заморозить всех врагов (например, при паузе)
EnemyManager.freeze_all_enemies(true)

# Получить статистику
var stats = EnemyManager.get_statistics()
print("Всего создано: ", stats.total_spawned)
print("Всего убито: ", stats.total_killed)

# Отладочная информация
EnemyManager.print_debug_info()
```

### Сигналы
- `enemy_spawned(enemy, enemy_data)` - Враг создан
- `enemy_died(enemy)` - Враг умер
- `all_enemies_cleared()` - Все враги удалены

---

## Примеры использования

### Пример 1: Простой спавн врага
```gdscript
# В _ready() игровой сцены
func _ready():
    # Загружаем конфигурацию
    var hedgehog_data = load("res://Elements/Enemy/configs/hedgehog_aggressive.tres")
    
    # Создаем врага
    var enemy = EnemyManager.spawn_enemy(hedgehog_data, Vector2(500, 300))
```

### Пример 2: Спавнер с таймером
```gdscript
# Создайте EnemyData с настройками:
# - spawn_trigger = TIMER
# - spawn_delay_min = 30.0
# - spawn_delay_max = 180.0

# Добавьте в сцену:
# 1. Node2D с скриптом enemy_spawner.gd
# 2. Установите enemy_data
# Спавнер автоматически создаст врага через случайное время
```

### Пример 3: Спавнер с триггерной областью
```gdscript
# В сцене:
# 1. Создайте Area2D с CollisionShape2D
# 2. Создайте Node2D (EnemySpawner) с enemy_spawner.gd
# 3. В EnemySpawner укажите trigger_area на Area2D
# 4. В EnemyData установите spawn_trigger = AREA_ENTER

# Враг появится, когда игрок войдет в область
```

### Пример 4: Кастомный враг
```gdscript
extends BaseEnemy
class_name BossEnemy

func _custom_behavior(delta: float):
    # Специальная механика босса
    if current_health < enemy_data.health * 0.5:
        # Вторая фаза
        current_speed *= 1.5
        
    # Специальная атака каждые 10 секунд
    if attack_timer > 10.0:
        special_attack()
        attack_timer = 0.0

func special_attack():
    # Ваша логика специальной атаки
    pass
```

### Пример 5: Инициализация конфигураций в EnemyManager
```gdscript
# В autoload скрипте или в главной сцене
func _ready():
    # Загружаем все конфигурации
    var configs = [
        load("res://Elements/Enemy/configs/hedgehog_aggressive.tres"),
        load("res://Elements/Enemy/configs/hedgehog_thief.tres"),
        load("res://Elements/Enemy/configs/bee.tres"),
        load("res://Elements/Enemy/configs/snake.tres")
    ]
    
    # Присваиваем в менеджер
    EnemyManager.enemy_configs = configs
```

---

## Интеграция с существующим кодом

### Требования к Player
Игрок должен иметь следующие методы/свойства:

```gdscript
extends CharacterBody2D

var max_health: float = 100.0
var current_health: float = 100.0

# Уровни улучшений (опционально)
var gloves_level: int = 0
var boots_level: int = 0
var cloak_level: int = 0
var wheelbarrow_level: int = 0

# Получение урона
func take_damage(amount: float):
    current_health -= amount
    # ... логика урона

# Получение количества воды
func get_water_amount() -> float:
    return current_water

# Кража воды
func steal_water(amount: float):
    current_water -= amount
    # ... логика кражи
```

---

## Миграция существующего кода

### Пример: Миграция Hedgehog

#### Старый код (hedgehog.gd):
```gdscript
extends CharacterBody2D

var speed = 50.0
var player = null
# ... 300+ строк кода
```

#### Новый код:
```gdscript
# 1. Создайте hedgehog_aggressive.tres с нужными параметрами
# 2. В сцене замените старый скрипт на BaseEnemy
# 3. Установите enemy_data на hedgehog_aggressive.tres
# Готово! Вся логика работает через BaseEnemy
```

Или для специфичного поведения:
```gdscript
extends BaseEnemy
class_name Hedgehog

func _custom_behavior(delta: float):
    # Только уникальная логика ёжика
    # Вся базовая логика в BaseEnemy
    pass
```

---

## Отладка

### Включение режима отладки
```gdscript
EnemyManager.enable_debug = true
```

### Просмотр информации в консоли
```gdscript
EnemyManager.print_debug_info()
```

Вывод:
```
=== Enemy Manager Debug Info ===
Total Active: 3/10
Total Spawned: 15
Total Killed: 12

By Type:
  hedgehog_aggressive: 2
  bee: 1

Spawners: 4
================================
```

---

## FAQ

**Q: Как создать территориального врага (привязан к месту)?**
A: Установите `ai_type = IDLE` и настройте `trigger_area` в спавнере.

**Q: Как сделать летающего врага?**
A: Установите `has_gravity = false` в EnemyData.

**Q: Как сделать босса?**
A: Создайте класс, наследующий BaseEnemy, и переопределите `_custom_behavior()`.

**Q: Как враг может взаимодействовать с другими объектами?**
A: Переопределите `_custom_behavior()` и добавьте свою логику коллизий.

**Q: Как настроить анимации?**
A: Создайте SpriteFrames, установите в `enemy_data.sprite_frames`. Анимации "idle" и "walk" будут воспроизводиться автоматически.

---

## Best Practices

1. **Используйте .tres файлы** для конфигураций, а не создавайте в коде
2. **Группируйте похожих врагов** - создайте базовый конфиг, дублируйте и изменяйте
3. **Используйте процентный урон** для балансировки на разных уровнях
4. **Настраивайте вариативность** (speed_variance, aggression) для разнообразия
5. **Тестируйте с EnemyManager.enable_debug = true**
6. **Подписывайтесь на сигналы** для игровых событий (урон, смерть)

---

## Дополнительные файлы

- `Elements/Enemy/enemy_data.gd` - Класс EnemyData
- `Elements/Enemy/enemy.gd` - Класс BaseEnemy
- `Elements/Enemy/enemy_spawner.gd` - Класс EnemySpawner
- `Core/enemy_manager.gd` - EnemyManager singleton
- `Elements/Enemy/configs/` - Папка для .tres конфигураций
- `Elements/Enemy/configs/enemy_config_examples.gd` - Примеры создания конфигураций

---

## Лицензия
Используйте свободно в своих проектах.
