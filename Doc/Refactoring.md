# Refactoring Guide — Перенос системы инвентаря

**Исходный проект:** `res://` (3d-rain, текущий прототип)  
**Целевой проект:** главный проект (далее — «ГП»)  
**Применяет:** GitHub Copilot при выдаче задачи «перенести инвентарь»

---

## 0. Соглашения, используемые в документе

| Обозначение | Что означает |
|---|---|
| `[SOURCE]` | Путь в исходном проекте (3d-rain) |
| `[TARGET]` | Путь в целевом проекте (ГП) |
| `MUST` | Обязательное требование; нарушение ломает систему |
| `SHOULD` | Рекомендация; нарушение даёт технический долг |
| `collision_mask = 8` | Бит 3 (2³). Player занимает физический слой 8 |

---

## 1. Карта переносимых файлов

| Файл [SOURCE] | Файл [TARGET] | Примечания |
|---|---|---|
| `Carriable.gd` | `res://Items/Carriable.gd` | Без изменений |
| `Wheel.gd` | `res://Items/Wheel.gd` | Без изменений |
| `PlayerInventory.gd` | `res://Player/Player_New/PlayerInventory.gd` | **Требует 2 правки** — см. §4 |
| `InventoryBar.tscn` | `res://ui/Inventory/InventoryBar.tscn` | **Требует 1 правку** — см. §5 |
| `Assets/outline.gdshader` | `res://Assets/outline.gdshader` | Шейдер обводки, нужен всем сценам предметов |
| `barrel.tscn` | `res://Items/barrel.tscn` | Обновить путь к скрипту и шейдеру |
| `bucket.tscn` | `res://Items/bucket.tscn` | Обновить путь + **исправить баг коллизии** |
| `shovel.tscn` | `res://Items/shovel.tscn` | Обновить путь к скрипту и шейдеру |
| `wheel.tscn` | `res://Items/wheel.tscn` | Обновить путь к скрипту |

---

## 2. Предварительные условия (MUST до начала миграции)

### 2.1 Player в целевом проекте MUST иметь:

| Требование | Проверка |
|---|---|
| Тип корневого узла — `CharacterBody2D` | В инспекторе: extends CharacterBody2D |
| Переменная `var _last_facing: int = 1` | Используется предметами для зеркалирования спрайта |
| Метод `set_nearby_item(item, source = null)` | Вызывается из `Area2D` предметов |
| Дочерний узел `PlayerInventory` типа `Node` со скриптом `PlayerInventory.gd` | Путь `$PlayerInventory` |
| В логике движения: при смене направления — вызов `held.set_facing(d)` | Если Player использует FSM — вызов должен быть в состоянии движения |
| `collision_layer = 8` | **MUST совпадать** с `collision_mask` у Area2D всех предметов |

### 2.2 Земля (StaticBody2D / TileMapLayer) MUST иметь:

| Требование | Значение |
|---|---|
| `collision_layer` | Бит 0 (значение = 1) |

### 2.3 Узлы предметов в `res://Levels/level_01.tscn` MUST:

| Требование | Причина |
|---|---|
| Быть **прямыми детьми** корневого узла сцены | `PlayerInventory._ready()` ищет их через `root.get_node_or_null(name)` |
| Иметь **точные имена**: `Wheel`, `Bucket`, `Barrel`, `Shovel` | Жёсткая привязка в `SLOT_NODE_NAMES` |

---

## 3. Известный баг в исходных сценах: исправить до переноса

### BUG: `bucket.tscn` — Area2D не реагирует на игрока

**Файл:** `[SOURCE] bucket.tscn`  
**Узел:** `Bucket/Area2D`  
**Параметр:** `collision_mask = 0` → **MUST** стать `collision_mask = 8`  
**Следствие бага:** ведро никогда не запускает `_on_body_entered`, клавиша E не работает, `nearby_item` не устанавливается.

**Исправление в редакторе:** Inspector → Area2D → Collision → Mask → включить бит 3.  
**Исправление в .tscn:** найти строку `collision_layer = 0` под `[node name="Area2D" ... parent="."]` в bucket.tscn — добавить строку `collision_mask = 8` следом.

---

## 4. Правки в `PlayerInventory.gd` (2 обязательных изменения)

### 4.1 Поиск InventoryBar через группу (вместо имени узла)

**Проблема:** текущий код `root.get_node_or_null("InventoryBar")` предполагает, что инстанс InventoryBar.tscn в сцене называется именно `"InventoryBar"`. В ГП это имя может не совпасть.

**Решение:** использовать Godot-группу `"inventory_bar"`.

Заменить в `_setup_ui()`:
```gdscript
# БЫЛО:
var bar = root.get_node_or_null("InventoryBar")

# СТАЛО:
var bar = get_tree().get_first_node_in_group("inventory_bar")
```

**Требование к InventoryBar.tscn:** корневой узел (`CanvasLayer`) MUST быть добавлен в группу `"inventory_bar"` — см. §5.

### 4.2 Поиск предметов в сцене уровня (актуально только если структура сцены меняется)

Текущий код — **работает без изменений**, если:
- `level_01.tscn` является текущей сценой (`get_tree().current_scene`)
- Узлы `Wheel`, `Bucket`, `Barrel`, `Shovel` — прямые дети корневого узла

Если предметы вложены глубже (например, `Level/Items/Barrel`), заменить:
```gdscript
# БЫЛО:
var root = get_tree().current_scene
_slots.append(root.get_node_or_null(nname) ...)

# СТАЛО (если предметы в группах):
# Каждый предмет в _ready() вызывает add_to_group("inv_slot_1") и т.д.
# PlayerInventory._ready() собирает их через get_tree().get_nodes_in_group(...)
```
> Пока структура соответствует условию — эта замена не нужна.

---

## 5. Правки в `InventoryBar.tscn` (1 изменение)

Добавить группу к корневому узлу `CanvasLayer`:

**В редакторе:** выбрать корневой узел `CanvasLayer` → вкладка Node (рядом с Inspector) → Groups → Add `inventory_bar`.

**Результат в .tscn** (появится строка):
```
[node name="CanvasLayer" type="CanvasLayer" ...]
editor/display_folded = true
# группы задаются через редактор, не через .tscn текст напрямую
```

**Альтернатива** (если группы неудобны): при инстанцировании в `level_01.tscn` назвать экземпляр именно `InventoryBar` — тогда `root.get_node_or_null("InventoryBar")` будет работать без правок в скрипте.

---

## 6. Интеграция в Player ГП (хирургические вставки в существующий скрипт)

Player в ГП уже существует с Camera2D и FSM. Нужно **только добавить** следующее — ничего не переписывать.

### 6.1 Переменные (в секцию деклараций)
```gdscript
var _last_facing: int = 1          # направление взгляда: +1 вправо, -1 влево
@onready var inventory := $PlayerInventory
```

### 6.2 Метод-прокси (добавить как отдельный метод)
```gdscript
func set_nearby_item(item, source = null) -> void:
    if inventory:
        inventory.set_nearby_item(item, source)
```

### 6.3 Хук на смену направления

Найти место в FSM/движении, где меняется направление (обычно `_last_facing = d` или `flip_h`). Добавить **после** обновления `_last_facing`:
```gdscript
_last_facing = d   # ← эта строка уже должна быть
var held = inventory.held_item if inventory else null
if held and held.has_method("set_facing"):
    held.set_facing(d)
```

---

## 7. Структура сцены `level_01.tscn` — требования к иерархии

```
level_01  (Node2D или аналог — корень сцены)
├── ...существующие узлы ГП (TileMap, фон, etc.)...
├── Player          ← CharacterBody2D, res://Player/Player_New/Player.tscn
│   └── PlayerInventory  ← Node, script=PlayerInventory.gd
├── Wheel           ← инстанс res://Items/wheel.tscn     [EXACT NAME]
├── Bucket          ← инстанс res://Items/bucket.tscn    [EXACT NAME]
├── Barrel          ← инстанс res://Items/barrel.tscn    [EXACT NAME]
├── Shovel          ← инстанс res://Items/shovel.tscn    [EXACT NAME]
└── InventoryBar    ← инстанс res://ui/Inventory/InventoryBar.tscn
                      (имя узла MUST быть "InventoryBar" ЛИБО корень сцены в группе "inventory_bar")
```

---

## 8. Параметры коллизий — полная таблица

| Узел | `collision_layer` | `collision_mask` | Примечание |
|---|---|---|---|
| Player (CharacterBody2D) | **8** | 1 | Слой «Character» = бит 3 |
| StaticBody2D / TileMap (земля) | **1** | — | Слой «World» = бит 0 |
| Wheel (CharacterBody2D) | **2** | 1 | Слой «Vehicle», взаимодействует с землёй |
| Wheel/Shin (RigidBody2D) | **2** | 0 | Не реагирует на другие тела |
| AttachArea в Wheel (Area2D) | **0** | 8 | Детектирует только Player |
| Area2D в Barrel (Area2D) | **0** | 8 | Детектирует только Player |
| Area2D в Bucket (Area2D) | **0** | **8** ← исправлено | Детектирует только Player |
| Area2D в Shovel (Area2D) | **0** | 8 | Детектирует только Player |
| `Carriable.restore()` устанавливает | — | 8 | Восстанавливает маску после store() |

> Если Player в ГП занимает **другой** слой (не 8) — нужно обновить `collision_mask` во всех Area2D предметов и в `Carriable.restore()` (`$Area2D.collision_mask = X`).

---

## 9. Параметры сцен предметов — полная справка

### 9.1 Структура любого Carriable-предмета (barrel / bucket / shovel)

```
ItemName  (Node2D)
│   script = Carriable.gd
│   item_type    = "carriable" | "tool"
│   item_label   = "<Отображаемое имя>"
│   item_visible = true | false
│   hand_offset  = Vector2(x, y)        ← смещение от игрока в руках
│   held_rotation_deg  = 0.0            ← угол, когда предмет держат
│   drop_rotation_deg  = 0.0            ← угол, когда предмет на земле
│
├── Sprite2D | AnimatedSprite2D
│       material = ShaderMaterial
│                   shader = outline.gdshader
│                   shader_parameter/outline_color = Color(1, 0.95, 0.2, 1)
│                   shader_parameter/outline_size  = 3.0
│                   shader_parameter/show_outline  = false   ← MUST false
│
├── Area2D
│       collision_layer = 0
│       collision_mask  = 8             ← MUST = Player layer
│   └── CollisionShape2D
│           shape = CapsuleShape2D | etc.
│
└── RayCast2D
        target_position = Vector2(0, half_height)   ← вниз, для земли
```

### 9.2 Конкретные параметры существующих предметов

| Предмет | item_type | hand_offset | CollisionShape | sprite scale |
|---|---|---|---|---|
| Barrel | `"carriable"` | `Vector2(50, -40)` | CapsuleShape r=40 h=82 | 0.4138 |
| Bucket | `"tool"` | `Vector2(50, -30)` | CapsuleShape r=17 h=34 | 0.1774 |
| Shovel | `"tool"` | `Vector2(40, -50)` | CapsuleShape r=19 h=124 | 0.4118 |

### 9.3 Структура Wheel (механизм, отличается от Carriable)

```
Wheel  (CharacterBody2D)
│   script = Wheel.gd
│   collision_layer = 2
│   collision_mask  = 1   ← земля
│   hand_offset     = Vector2(-14, -10)
│   follow_speed    = 600.0
│   follow_stiffness = 10.0
│   gravity         = 1000.0
│
├── Visual  (Node2D)
│   ├── Shaddow_whell  (Sprite2D)
│   ├── Whell_tank     (Sprite2D)   material=ShaderMaterial(outline.gdshader)
│   └── AnimatedSprite2D
│
├── Support  (CollisionShape2D)   top_level = true
├── Shin     (RigidBody2D)        collision_layer=2, collision_mask=0
│   ├── shin  (Sprite2D)
│   └── CollisionShape2D
├── Pin_Shin  (PinJoint2D)        node_a=Wheel, node_b=Shin
└── use_Player  (Node2D)
    └── AttachArea  (Area2D)      collision_layer=0, collision_mask=8
        └── CollisionShape2D
```

> `Wheel.gd._ready()` ищет Player через `get_node("../Player")`. В `level_01.tscn` Wheel и Player MUST быть на **одном уровне** иерархии (siblings).

---

## 10. Порядок выполнения миграции (пошаговый чеклист)

```
[ ] Шаг 1.  Скопировать файлы согласно таблице §1.
            Обновить все ext_resource пути внутри .tscn файлов предметов
            (Carriable.gd, outline.gdshader, текстуры).

[ ] Шаг 2.  Исправить bucket.tscn: Area2D → collision_mask = 8. (§3)

[ ] Шаг 3.  Скопировать PlayerInventory.gd → res://Player/Player_New/.
            Применить правку 4.1 (поиск InventoryBar через группу).

[ ] Шаг 4.  В InventoryBar.tscn добавить группу "inventory_bar"
            к корневому узлу CanvasLayer. (§5)

[ ] Шаг 5.  В скрипт Player ГП добавить: _last_facing, inventory,
            set_nearby_item(), хук set_facing(). (§6)

[ ] Шаг 6.  Добавить к Player дочерний узел PlayerInventory (Node)
            с подключённым скриптом PlayerInventory.gd.

[ ] Шаг 7.  Собрать level_01.tscn согласно иерархии §7:
            — Player как инстанс res://Player/Player_New/
            — Wheel, Bucket, Barrel, Shovel как прямые дети корня
            — InventoryBar как инстанс res://ui/Inventory/InventoryBar.tscn

[ ] Шаг 8.  Проверить collision_layer Player в ГП.
            Если не 8 — обновить collision_mask у всех Area2D предметов
            и метод Carriable.restore() ($Area2D.collision_mask = X).

[ ] Шаг 9.  Верификация (§11).
```

---

## 11. Верификация после миграции

| Тест | Ожидаемый результат |
|---|---|
| Подойти к Barrel | Появляется жёлтая обводка |
| Нажать E рядом с Barrel | Barrel следует за игроком; слот 3 подсвечен в UI |
| Нажать E повторно | Barrel остаётся на месте; слот 0 активен |
| Подойти к Bucket, нажать E | Ведро подбирается (обводка работает — баг §3 исправлен) |
| Нажать клавишу 2 не рядом с Bucket | Bucket телепортируется к Player и берётся в руки (item_visible=true) |
| Нажать 0 | Предмет кладётся на землю |
| Нажать 4 (Shovel) | Лопата берётся в руки |
| Сменить направление движения | Предмет в руках зеркалится |
| Тачка: отойти от Wheel, нажать 1 | Тачка не берётся (item_visible=true, нужно подойти и E) |
| InventoryBar | Виден поверх всей сцены (CanvasLayer работает) |

---

## 12. Подводные камни

| Риск | Симптом | Решение |
|---|---|---|
| Player layer ≠ 8 в ГП | Обводка/E никогда не работает | Выровнять collision_mask Area2D с реальным layer Player |
| Предмет не прямой ребёнок корня level_01 | `_slots[i] == null` при старте, слоты не работают | Переместить в иерархии ИЛИ применить правку 4.2 |
| FSM Player не вызывает set_facing | Предмет не зеркалится при смене направления | Найти переход состояния движения и добавить хук §6.3 |
| PlayerInventory ищет `$PlayerInventory` у root | Если путь другой — `null` reference | Обновить путь в PlayerInventory: `get_parent()` MUST быть CharacterBody2D |
| Wheel ищет `get_node("../Player")` | Если Wheel не sibling игрока — краш | Переместить Wheel и Player на один уровень в level_01 |
| `restore()` появляется в стене | Предмет застревает при извлечении из инвентаря | Добавить `RayCast2D` от позиции игрока вниз и располагать на первой точке пола |
| InventoryBar инстанс не назван "InventoryBar" ИЛИ нет группы | UI не обновляется, `_slot_panels` пустой | Проверить имя узла или наличие группы "inventory_bar" |
