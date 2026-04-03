# Plan: Inventory System

## Архитектура: 3 слоя

```
[Shop] → [InventoryManager (Autoload)] → [PlayerInventory] → [WorldSpawner]
```

---

## Слой 1: InventoryManager (Autoload)

- Только данные, никаких сцен и узлов
- Предмет — `Resource`:
  ```gdscript
  { "id": "wheel", "scene": preload("res://wheel.tscn"), "count": 1, "level": 1 }
  ```
- Методы: `buy(id)`, `upgrade(id)`, `get_item(id)`
- Сохранение через `ConfigFile` или `JSON` в `user://`

---

## Слой 2: PlayerInventory (на Player)

- Фиксированный массив слотов: `var slots: Array = [null, null, null]`
- При выборе слота → запрашивает сцену у `InventoryManager` → передаёт `WorldSpawner`
- Хранит ссылку на **уже заспавненный** узел (не PackedScene)
- Переключение слота: сначала скрыть текущий, потом показать новый

---

## Слой 3: WorldSpawner (на уровне)

Единственное место спавна/деспавна.

**Скрыть предмет:**
```gdscript
item.process_mode = Node.PROCESS_MODE_DISABLED
item.visible = false
item.collision_layer = 0
item.collision_mask = 0
```

**Показать предмет:**
```gdscript
item.collision_layer = 1
item.collision_mask = 1
item.process_mode = Node.PROCESS_MODE_INHERIT
item.visible = true
# ВАЖНО: позицию ставить через call_deferred, не в том же кадре что add_child
item.call_deferred("set_global_position", spawn_point.global_position)
```

**Первый спавн:**
```gdscript
var node = scene.instantiate()
get_tree().current_scene.add_child(node)
node.call_deferred("set_global_position", spawn_point.global_position)
```

---

## Физика предметов: CharacterBody2D (не RigidBody2D)

Опыт проекта: `RigidBody2D` + `PinJoint2D` непредсказуем при движении по рельефу.

`CharacterBody2D` для переносимых предметов:
- Гравитация и `move_and_slide()` — ручные, в скрипте
- `is_attached = true` → тянется к руке игрока через `lerp` или `clamp`
- `is_attached = false` → `PROCESS_MODE_DISABLED`, никакой физики, не проваливается

Прикрепление без джоинтов — вычислять смещение `grip_to_root`:
```gdscript
var grip_to_root = global_position - use_player_node.global_position
var target_x = player.global_position.x + hand_offset.x + grip_to_root.x
```

---

## UI: Меню смены предмета (в сессии)

**Структура:**
```
Player
  └── CanvasLayer          ← не зависит от камеры
        └── QuickSlotUI    ← Control/HBoxContainer
              ├── Slot0    ← TextureButton
              ├── Slot1
              └── Slot2
```

**Принцип работы:**
- Открывается по кнопке (Tab, E и т.д.) — `visible = !visible`
- Каждый слот показывает иконку предмета и количество из `InventoryManager`
- При нажатии на слот → `PlayerInventory.equip(slot_index)` → `WorldSpawner` скрывает текущий, показывает новый
- Меню закрывается автоматически после выбора

**Важно:** меню на `CanvasLayer` не реагирует на масштаб/позицию камеры, поэтому позиционировать его фиксированно в экранных координатах (anchor bottom-center или corner).

**Не делать:** привязывать меню к `Node2D` в мировом пространстве — будет "плыть" с камерой.

---

## Магазин

- Отдельная сцена, вызывается через `change_scene_to_file` или overlay `CanvasLayer`
- При покупке: `InventoryManager.buy(id)` → добавляет в данные
- Улучшения: `InventoryManager.upgrade(id)` → меняет `level`, `WorldSpawner` применяет свойства при следующем спавне

---

## Частые ошибки (из опыта)

| Проблема | Причина | Решение |
|---|---|---|
| Предмет телепортируется при спавне | `set_position` в том же кадре что `add_child` | `call_deferred` |
| Предмет улетает | `RigidBody2D` + джоинт при резких движениях | `CharacterBody2D` + ручная физика |
| Предмет проваливается при скрытии | `visible=false` без отключения процессинга | `PROCESS_MODE_DISABLED` |
| node_b джоинта не работает | Путь задан до добавления узла в дерево | Инициализировать в `_ready`, не в `_init` |
| Дочерний RigidBody2D перекашивает родителя | `PinJoint2D` создаёт крутящий момент | `freeze = true` для визуальных тел |
