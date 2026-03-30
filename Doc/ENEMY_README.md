# 🎮 Унифицированная система врагов (Enemy System)

> Универсальная, расширяемая и простая в использовании система управления врагами для Godot 4.x

---

## 📋 Содержание

- [Что это?](#что-это)
- [Возможности](#возможности)
- [Быстрый старт](#быстрый-старт)
- [Структура файлов](#структура-файлов)
- [Документация](#документация)
- [Примеры](#примеры)

---

## Что это?

Полноценная система управления врагами, построенная на принципах **Data-Driven Design**. Позволяет создавать, настраивать и управлять любым количеством типов врагов без написания кода.

### ✨ Ключевые особенности

- 🎯 **Data-Driven** - вся конфигурация через Resources
- 🔧 **Расширяемая** - легко добавлять новых врагов
- 🎨 **Гибкая** - 6 типов AI, настройка параметров
- 📊 **Статистика** - отслеживание всех врагов
- 🐛 **Отладка** - встроенные инструменты
- 📚 **Документирована** - подробные гайды и примеры

---

## Возможности

### 🤖 AI системы
- **IDLE** - Стоит на месте (территориальные враги)
- **PATROL** - Патрулирует область
- **FOLLOW_PLAYER** - Преследует игрока
- **FLEE_PLAYER** - Убегает от игрока
- **THIEF** - Воришка (держится на дистанции)
- **AGGRESSIVE** - Агрессор (прилипает к игроку)

### ⚔️ Боевые механики
- Одноразовый урон
- Постоянный урон
- Урон при столкновении
- Кража ресурсов
- Модификаторы от улучшений
- Процентный/абсолютный урон

### 🎭 Условия спавна
- По таймеру
- При входе в область
- При действии игрока
- По условиям
- Ручное создание

### 🎯 Управление
- Централизованный менеджер
- Автоматические спавнеры
- Контроль лимитов
- Глобальная статистика

---

## Быстрый старт

### 1. Настройка (1 минута)

```gdscript
# Project Settings → AutoLoad
# Добавьте: Core/enemy_manager.gd как "EnemyManager"
```

### 2. Создание врага (2 минуты)

```gdscript
# Создайте EnemyData
var enemy_data = EnemyData.new()
enemy_data.enemy_id = "my_enemy"
enemy_data.speed = 50.0
enemy_data.ai_type = EnemyData.AIType.FOLLOW_PLAYER

# Создайте врага
EnemyManager.spawn_enemy(enemy_data, Vector2(500, 300))
```

### 3. Готово! 🎉

Подробнее: [Quick Start Guide](ENEMY_QUICK_START.md)

---

## Структура файлов

```
Elements/Enemy/
├── enemy_data.gd          # Resource конфигурации
├── enemy.gd               # BaseEnemy - базовый класс
├── enemy_spawner.gd       # Спавнер врагов
├── hedgehog.gd            # (старый код - можно удалить)
└── configs/               # Конфигурации врагов
    ├── enemy_config_examples.gd
    ├── hedgehog_aggressive.tres
    └── hedgehog_thief.tres

Core/
└── enemy_manager.gd       # Глобальный менеджер (AutoLoad)

Doc/
├── ENEMY_SYSTEM.md        # Полная документация
├── ENEMY_QUICK_START.md   # Быстрый старт
└── ENEMY_MIGRATION.md     # Гайд по миграции
```

---

## Документация

### 📖 Основные документы

- **[ENEMY_SYSTEM.md](ENEMY_SYSTEM.md)** - Полная документация системы
- **[ENEMY_QUICK_START.md](ENEMY_QUICK_START.md)** - Быстрый старт за 5 минут
- **[ENEMY_MIGRATION.md](ENEMY_MIGRATION.md)** - Миграция существующего кода

### 🎓 Руководства

#### Создание конфигурации врага

```gdscript
var data = EnemyData.new()

# Основное
data.enemy_id = "zombie"
data.enemy_name = "Зомби"
data.speed = 40.0

# AI
data.ai_type = EnemyData.AIType.FOLLOW_PLAYER
data.target_distance = 50.0

# Урон
data.damage_type = EnemyData.DamageType.CONTINUOUS
data.damage_player = 5.0
data.damage_interval = 1.0

# Спавн
data.spawn_trigger = EnemyData.SpawnTrigger.TIMER
data.spawn_delay_min = 30.0
data.spawn_delay_max = 60.0
```

#### Использование спавнера

```gdscript
# В сцене добавьте Node2D с enemy_spawner.gd
$EnemySpawner.enemy_data = my_enemy_data
$EnemySpawner.enabled = true
# Враги будут появляться автоматически!
```

#### Управление через менеджер

```gdscript
# Создать врага
var enemy = EnemyManager.spawn_enemy_by_id("zombie", position)

# Получить статистику
var stats = EnemyManager.get_statistics()
print("Всего врагов: ", stats.total_active)

# Удалить всех
EnemyManager.clear_all_enemies()

# Заморозить (пауза)
EnemyManager.freeze_all_enemies(true)
```

---

## Примеры

### Пример 1: Ёжик-агрессор

```gdscript
var hedgehog = EnemyData.new()
hedgehog.enemy_id = "hedgehog_aggressive"
hedgehog.speed = 50.0
hedgehog.ai_type = EnemyData.AIType.AGGRESSIVE
hedgehog.can_steal_water = true
hedgehog.water_steal_amount = 5.0
hedgehog.is_immortal = true

var enemy = EnemyManager.spawn_enemy(hedgehog, player_position)
```

### Пример 2: Территориальная пчела

```gdscript
var bee = EnemyData.new()
bee.enemy_id = "bee"
bee.speed = 80.0
bee.has_gravity = false  # Летает
bee.ai_type = EnemyData.AIType.PATROL
bee.damage_type = EnemyData.DamageType.CONTINUOUS
bee.damage_interval = 0.5

var enemy = EnemyManager.spawn_enemy(bee, hive_position)
```

### Пример 3: Спавнер с таймером

```gdscript
# Создайте EnemySpawner в сцене
var spawner = EnemySpawner.new()
spawner.enemy_data = snake_config
add_child(spawner)
# Змеи будут появляться каждые 30-180 секунд
```

### Пример 4: Кастомный враг

```gdscript
extends BaseEnemy
class_name BossEnemy

func _custom_behavior(delta: float):
    # Специальная механика босса
    if current_health < enemy_data.health * 0.5:
        enter_rage_mode()

func enter_rage_mode():
    current_speed *= 2.0
    sprite.modulate = Color.RED
```

---

## 🎯 Типы врагов из документации

Система полностью поддерживает всех описанных врагов:

### 🦔 Ёжики
- **Назойливый агрессор** - прилипает и крадет воду
- **Пугливый воришка** - держится на расстоянии

### 🐝 Пчёлы
- **Агрессоры** - территориальные, постоянный урон

### 🐍 Змеи
- **Территориальные** - одноразовый сильный урон

Все параметры из `Doc/Enemy/*.txt` учтены в системе.

---

## 🛠️ API Reference

### EnemyManager

```gdscript
# Создание
spawn_enemy(config: EnemyData, position: Vector2) -> BaseEnemy
spawn_enemy_by_id(enemy_id: String, position: Vector2) -> BaseEnemy

# Управление
clear_all_enemies()
clear_enemies_by_type(enemy_id: String)
freeze_all_enemies(freeze: bool)

# Информация
get_total_active_count() -> int
get_active_count(enemy_id: String) -> int
get_all_active_enemies() -> Array[BaseEnemy]
get_statistics() -> Dictionary

# Отладка
print_debug_info()
```

### BaseEnemy

```gdscript
# Свойства
enemy_data: EnemyData
is_active: bool
current_health: float
player: CharacterBody2D

# Методы
take_damage(amount: float)
die()
despawn()
_custom_behavior(delta: float)  # Переопределяемый

# Сигналы
enemy_died(enemy)
enemy_despawned(enemy)
player_damaged(damage, enemy)
water_stolen(amount, enemy)
```

### EnemySpawner

```gdscript
# Свойства
enemy_data: EnemyData
enabled: bool
trigger_area: Area2D

# Методы
force_spawn() -> BaseEnemy
despawn_all()
get_active_count() -> int

# Сигналы
enemy_spawned(enemy)
spawn_conditions_met(enemy_data)
```

---

## ⚙️ Конфигурация

### EnemyData параметры

| Группа | Параметры |
|--------|----------|
| Основное | enemy_id, enemy_name, description |
| Внешний вид | scene, sprite_frames, scale |
| Физика | speed, has_gravity, collision |
| Боевые | damage_type, damage_player, health |
| Кража | can_steal_water, water_steal_amount |
| AI | ai_type, aggression, target_distance |
| Спавн | spawn_trigger, spawn_delay, max_instances |
| Исчезновение | idle_timeout, despawn_on_* |
| Модификаторы | affected_by_*, damage_reduction |

---

## 🔍 Отладка

```gdscript
# Включить отладку
EnemyManager.enable_debug = true

# Вывести информацию
EnemyManager.print_debug_info()

# Результат:
# === Enemy Manager Debug Info ===
# Total Active: 3/10
# Total Spawned: 15
# Total Killed: 12
# By Type:
#   hedgehog: 2
#   bee: 1
# ================================
```

---

## 🎨 Расширение системы

### Создание своего типа врага

```gdscript
extends BaseEnemy
class_name MyCustomEnemy

func _ready():
    super._ready()
    # Дополнительная инициализация

func _custom_behavior(delta: float):
    # Ваша уникальная логика
    if some_special_condition():
        do_special_attack()

func do_special_attack():
    # Реализация
    pass
```

### Добавление нового AI типа

Расширьте enum в `EnemyData`:
```gdscript
enum AIType {
    # ... существующие типы
    CUSTOM_PATROL,  # Ваш новый тип
}
```

Добавьте обработку в `BaseEnemy`:
```gdscript
func _update_ai(delta: float):
    match enemy_data.ai_type:
        # ... существующие типы
        EnemyData.AIType.CUSTOM_PATROL:
            _custom_patrol_behavior(delta)
```

---

## 📊 Производительность

- ✅ Поддержка 100+ врагов одновременно
- ✅ Оптимизированная система поиска игрока
- ✅ Автоматическая очистка неактивных врагов
- ✅ Ленивые вычисления для статистики

---

## 🤝 Интеграция

### Требования к Player

```gdscript
extends CharacterBody2D

# Обязательные
func _ready():
    add_to_group("player")  # Важно!

func take_damage(amount: float):
    # Ваша логика урона
    pass

func get_water_amount() -> float:
    return current_water

func steal_water(amount: float):
    # Ваша логика кражи
    pass

# Опциональные (для модификаторов)
var gloves_level: int = 0
var boots_level: int = 0
var cloak_level: int = 0
var wheelbarrow_level: int = 0
```

---

## 🐛 Troubleshooting

**Враги не появляются?**
- Проверьте AutoLoad для EnemyManager
- Убедитесь, что `enemy_data` установлен
- Включите `enable_debug = true`

**Ошибка "player not found"?**
- Добавьте: `player.add_to_group("player")`

**Враги не наносят урон?**
- Проверьте наличие метода `take_damage()` у игрока

---

## 📝 Changelog

### Version 1.0
- ✅ Базовая система врагов
- ✅ 6 типов AI
- ✅ Система спавнеров
- ✅ Глобальный менеджер
- ✅ Полная документация

---

## 📄 Лицензия

Свободное использование в ваших проектах.

---

## 🎓 Узнать больше

- [Полная документация](ENEMY_SYSTEM.md)
- [Быстрый старт](ENEMY_QUICK_START.md)
- [Миграция](ENEMY_MIGRATION.md)
- [Примеры конфигураций](../Elements/Enemy/configs/enemy_config_examples.gd)

---

**Создано для Rain Boss** | Godot 4.x | 2026
