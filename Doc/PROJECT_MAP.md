# PROJECT MAP — Rain Boss

Полный список сцен и скриптов проекта.

---

## Корень

| Файл | Описание |
|------|----------|
| `/game.gd` | Главный скрипт сцены: состояния игры, загрузка уровней, пауза |
| `/Game.tscn` | Корневая игровая сцена: Player, LevelContent, UI, Progression (InventorySystem/SkillSystem/ShopSystem); CloudLayer в сценах уровней |
| `/settings_manager.gd` | Автозагрузка **Settings**: чтение/запись аудионастроек в `settings.cfg` |

---

## Core — автозагрузки и данные

| Файл | Описание |
|------|----------|
| `/Core/globals.gd` | Автозагрузка **Globals**: здоровье, жизни, очки, золото, прогресс героя |
| `/Core/events.gd` | Автозагрузка **Events**: шина сигналов, логики нет — только объявления |
| `/Core/save_manager.gd` | Автозагрузка **SaveManager**: чтение/запись `save.cfg` (прогресс + состояние) |
| `/Core/xp_manager.gd` | Автозагрузка **XpManager**: начисление XP, повышение уровня героя |
| `/Core/level_data.gd` | Resource **LevelData**: данные уровня (сцена, флаги систем, старт игрока) |
| `/Core/level_registry.gd` | Автозагрузка **LevelRegistry**: реестр путей к LevelData по level_id |
| `/Core/enemy_manager.gd` | Автозагрузка **EnemyManager**: глобальный учёт врагов, спавнеры, статистика |
| `/Core/inventory_system.gd` | **InventorySystem** (Progression/InventorySystem): спавн тачки, PinJoint2D, ссылки для игрока |

---

## Elements / Cloud — система облаков

| Файл | Описание |
|------|----------|
| `/Elements/Cloud/CloudConfig/cloud_config.gd` | Resource **CloudConfig**: параметры одного типа облака (SIMPLE/RAIN/STORM) |
| `/Elements/Cloud/CloudEntity/cloud_entity.gd` | **CloudEntity**: одно облако, FSM состояний, шейдер, трансляция координат |
| `/Elements/Cloud/CloudEntity/cloud_entity.tscn` | Сцена экземпляра облака (Sprite2D + Area2D) |
| `/Elements/Cloud/CloudLayer/cloud_layer.gd` | **CloudLayer**: пул облаков, спавн/ресайкл по чанкам, управление конфигами |
| `/Elements/Cloud/CloudLayer/cloud_layer.tscn` | Сцена слоя облаков; добавляется в Game.tscn |
| `/Elements/Cloud/TransformZone/transform_zone.gd` | **TransformZone**: Area2D-триггер смены типа облака при входе в зону |
| `/Elements/Cloud/TransformZone/transform_zone.tscn` | Сцена зоны трансформации облаков |

---

## Elements / Enemy — враги и зоны спавна

| Файл | Описание |
|------|----------|
| `/Elements/Enemy/enemy_data.gd` | Resource **EnemyData**: конфигурация врага (AI, урон, спавн, визуал) |
| `/Elements/Enemy/enemy.gd` | **BaseEnemy**: базовый класс врага, FSM (IDLE/APPROACH/ATTACK/FLEE/DEAD) |
| `/Elements/Enemy/enemy.tscn` | Базовая сцена врага (CharacterBody2D + коллизия + анимация) |
| `/Elements/Enemy/enemy_spawner.gd` | **EnemySpawner**: создаёт BaseEnemy по условиям (таймер/триггер) |
| `/Elements/Enemy/hedgehog.gd` | **Hedgehog** extends BaseEnemy: два режима — AGGRESSIVE и THIEF |
| `/Elements/Enemy/hedgehog.tscn` | Сцена ёжика |
| `/Elements/Enemy/Rain/puddle.gd` | **Puddle**: Area2D-лужа, замедляет игрока; визуал инстанцируется из `puddle_effect.tscn`; удаляется по таймеру |
| `/Elements/Enemy/stop_point.gd` | Зона спавна ёжиков (Area2D): адаптивный интервал, ограничение количества |
| `/Elements/Enemy/stop_point.tscn` | Сцена зоны спавна ёжиков (видимый знак + Area2D) |
| `/Elements/Enemy/StopPointPlayer.tscn` | Триггер-область игрока для определения входа в зону спавна |
| `/Elements/Enemy/configs/enemy_config_examples.gd` | Примеры создания EnemyData через GDScript (только для справки) |

---

## Elements / Enemy / Rain — капли дождя

| Файл | Описание |
|------|----------|
| `/Elements/Enemy/Rain/rain_manager.gd` | **RainManager**: непрерывный спавн капель под облаками; включает ambient sound |
| `/Elements/Enemy/Rain/drip_emitter.gd` | **DripEmitter**: Node2D-эмиттер капель с произвольной точки (карниз, ветка) |
| `/Elements/Enemy/Rain/rain_water.gd` | Обычная капля: урон игроку, вода в тачку, создаёт лужу, самостоятельные брызги |
| `/Elements/Enemy/Rain/rain_gold.gd` | Золотая капля: +очки, +вода в тачку, +1 золото; самостоятельные брызги |
| `/Elements/Enemy/Rain/rain_live.gd` | Живительная капля: лечит игрока, +очки, +вода в тачку; самостоятельные брызги |
| `/Elements/Enemy/Rain/Rain_water.tscn` | Сцена обычной капли воды |
| `/Elements/Enemy/Rain/Rain_gold.tscn` | Сцена золотой капли |
| `/Elements/Enemy/Rain/Rain_live.tscn` | Сцена живительной капли |
| `/Elements/Enemy/Rain/rain_splash.tscn` | Самоуничтожающийся эффект брызг (AnimatedSprite2D + rain_splash_effect.gd) |
| `/Elements/Enemy/Rain/rain_splash_effect.gd` | Скрипт: играет анимацию Rain_splash и queue_free по окончании |
| `/Elements/Enemy/Rain/Rain_animate.tscn` | Ambient sound нода (AudioStreamPlayer, blop1.mp3) — подключается в rain_manager |
| `/Elements/Enemy/Rain/Rain/puddle_effect.tscn` | Визуал лужи: AnimatedSprite2D со SpriteFrames (puddle/puddle_on/puddle_of) |

---

## Elements / Player — герой

| Файл | Описание |
|------|----------|
| `/Elements/Player/player_config.gd` | Resource **PlayerConfig**: скорость, иммунитеты, спринт, множитель урона |
| `/Elements/Player/Player_00/player_base.gd` | **PlayerBase**: базовый класс героя, FSM (MOVE/UNLOAD/USE_TOOL/DAMAGED) |
| `/Elements/Player/Player_00/player_default.gd` | Герой по умолчанию: подключает `config_default.tres`, вызывает super._ready() |
| `/Elements/Player/Player_00/Player.tscn` | Сцена героя с тачкой и коллизиями (контроллер выгрузки перемещён в `/Levels/level_unload.gd`, нода `Unload` уровня) |
| `/Elements/Player/configs/inventory_config.gd` | **InventoryConfig**: таблица уровней тачки, кирки, лопаты |
| `/Elements/Player/configs/protection_config.gd` | **ProtectionConfig**: таблица уровней сапог, плаща, перчаток |
| `/Elements/Player/configs/skill_config.gd` | **SkillConfig**: таблица прогрессии уровней скилла героя (скорость, HP, урон) |

---

## Elements / Wheelbarrow — тачка

| Файл | Описание |
|------|----------|
| `/Elements/Wheelbarrow/wheelbarrow.gd` | **Wheelbarrow (Wheelbarrow)** (RigidBody2D): визуализация воды, расплёскивание, предупреждения |
| `/Elements/Wheelbarrow/wheelbarrow.tscn` | Сцена тачки |
| `/Elements/Wheelbarrow/ruchka.gd` | **Ruchka** (RigidBody2D): ручка тачки, регистрирует попадания капель |

---

## Elements / Exit\_plot — финишная зона

| Файл | Описание |
|------|----------|
| `/Elements/Exit_plot/exit_plot.gd` | **ExitPlot**: зона финиша уровня; показывает счётчик литров до перехода |
| `/Elements/Exit_plot/exit_plot.tscn` | Сцена финишной зоны (плот-переправа) |

---

## Background — окружение

| Файл | Описание |
|------|----------|
| `/Background/background.tscn` | Статичный фон уровня (слои спрайтов неба/земли) |
| `/Background/Parallax/parallax_background.tscn` | Параллакс-слои фона для создания эффекта глубины |
| `/Background/Wall/place.gd` | `StaticBody2D` поверхность: принимает `rain_place()`, капля сама воспроизводит брызги |
| `/Background/Wall/place.tscn` | Сцена наземной поверхности |
| `/Background/Wall/wall_down.tscn` | Нижняя граница уровня (StaticBody2D) |
| `/Background/Wall/wall_left.tscn` | Левая граница уровня (StaticBody2D) |
| `/Background/Wall/wall_right.gd` | Правая стена: заглушка StaticBody2D, место для логики столкновений |
| `/Background/Wall/wall_right.tscn` | Правая граница уровня (StaticBody2D) |

---

## Props — объекты окружения

| Файл | Описание |
|------|----------|
| `/Props/home.tscn` | Дом с крышей: декоративный объект, капли отбиваются без луж |
| `/Props/home_area.gd` | Area2D крыши дома: капли дождя → брызги, без урона и луж |

---

## Levels — уровни

| Файл | Описание |
|------|----------|
| `/Levels/level_01.tscn` | Контент уровня 1 (окружение, триггеры, финишная зона) |
| `/Levels/level_02.tscn` | Контент уровня 2 |
| `/Levels/level_data_01.tres` | LevelData для уровня 1 (параметры, путь к сцене, старт героя) |
| `/Levels/level_data_02.tres` | LevelData для уровня 2 |

---

## UI — интерфейс

| Файл | Описание |
|------|----------|
| `/ui/game_ui.tscn` | Корневая сцена UI (контейнер для всех HUD-элементов) |
| `/ui/hud/hud.gd` | **HUD**: подписка на Events, отображение HP/жизней/воды/золота/прогресса |
| `/ui/hud/hud.tscn` | Сцена HUD |
| `/ui/main_menu/main_menu.gd` | Главное меню: кнопки, музыка, анимации облаков, переход к игре |
| `/ui/main_menu/main_menu.tscn` | Сцена главного меню |
| `/ui/pause_menu/pause_menu.gd` | Меню паузы: работает при `PROCESS_MODE_ALWAYS`, испускает сигналы в game.gd |
| `/ui/pause_menu/pause_menu.tscn` | Сцена меню паузы |
| `/ui/game_over/game_over.gd` | Экран Game Over: кнопка возврата в главное меню |
| `/ui/game_over/game_over.tscn` | Сцена экрана Game Over |
| `/ui/victory/victory.gd` | Экран победы: переход к следующему уровню или в главное меню |
| `/ui/victory/victory.tscn` | Сцена экрана победы |
| `/ui/level_intro/level_intro.gd` | Экран вступления к уровню: заголовок + описание + кнопка «Продолжить» |
| `/ui/level_intro/level_intro.tscn` | Сцена экрана вступления |
| `/ui/settings/settings.gd` | Экран настроек: слайдеры громкости, сохранение через Settings |
| `/ui/settings/settings.tscn` | Сцена экрана настроек |
| `/ui/lives_bar/lives_bar.gd` | Полоса жизней: HBoxContainer с иконками сердец |
| `/ui/lives_bar/lives_bar.tscn` | Сцена полосы жизней |
| `/ui/lives_bar/live_rect.tscn` | Одна иконка жизни для lives_bar |

---

## Addons

| Файл | Описание |
|------|----------|
| `/addons/codeandweb.texturepacker/codeandweb.texturepacker_importer.gd` | Плагин TexturePacker: регистрирует кастомный импортёр спрайтшитов |
| `/addons/codeandweb.texturepacker/texturepacker_import_spritesheet.gd` | Логика импорта: конвертирует `.tpsheet` в SpriteFrames |

---

*Файлы `.uid`, `.import`, `._*` (macOS metadata) в таблицах не указаны.*
