## Шина событий (Автозагрузка "Events").
## Содержит только сигналы — не имеет логики.
## Подписывайтесь через Events.<signal>.connect() в любом скрипте.
extends Node


# Сигналы для инвентаря
@warning_ignore("unused_signal")
signal item_spawned(player: CharacterBody2D, item_id: String, physics_body: RigidBody2D, root: Node2D, anim_sprite: AnimatedSprite2D, dump_pivot: Node2D)
@warning_ignore("unused_signal")
signal item_despawned(player: Node, item_id: String)

#Сигнал готовности героя
@warning_ignore("unused_signal")
signal player_ready

# --- UI / HUD ---
@warning_ignore("unused_signal")
signal points_changed(points: int)
@warning_ignore("unused_signal")
signal health_changed(health: int)
@warning_ignore("unused_signal")
signal lives_count_changed(lives_count: int)
@warning_ignore("unused_signal")
signal gold_changed(gold: int)
@warning_ignore("unused_signal")
signal level_changed(level: int)

# --- Тачка ---
@warning_ignore("unused_signal")
signal wheelbarrow_changed(amount: int)    # заполнение тачки (0..100) — для HUD и анимаций дождя

# --- Игровые события ---
@warning_ignore("unused_signal")
signal game_over()
@warning_ignore("unused_signal")
signal victory()
@warning_ignore("unused_signal")
signal objective_changed(objective_id: String, completed: bool)
@warning_ignore("unused_signal")
signal objectives_configured(objective_profile_id: String)

# --- Облака ---
## Транслируется каждый кадр каждым активным облаком.
## cloud_type: 0=SIMPLE, 1=RAIN, 2=STORM
## drops_per_sec и spread_x берутся из CloudConfig текущего облака.
@warning_ignore("unused_signal")
signal cloud_state_changed(cloud_id: int, pos: Vector2, cloud_type: int, drops_per_sec: float, spread_x: float)

## Предупреждение о молнии — испускается грозовым облаком перед ударом.
@warning_ignore("unused_signal")
signal lightning_warning(pos: Vector2)

## Одиночная капля из произвольной точки (ветка, крыша, карниз и т.п.).
## drop_type: 0=вода, 1=золото, 2=живительная
@warning_ignore("unused_signal")
signal drip_at(pos: Vector2, drop_type: int)

# --- Прогресс уровня ---
## Прогресс выгрузки воды к переходу на следующий уровень.
## current — сколько уже сдано; max_v — сколько нужно всего.
@warning_ignore("unused_signal")
signal exit_point_changed(current: int, max_v: int)

# --- Прогресс героя ---
## Уровень скилла изменился (прокачка).
@warning_ignore("unused_signal")
signal skill_level_changed(new_level: int)
## Единица экипировки прокачана (item_type: "boots"/"cloak"/"gloves"/"wheelbarrow").
@warning_ignore("unused_signal")
signal equipment_changed(item_type: String, new_level: int)
## Навык активирован игроком.
@warning_ignore("unused_signal")
signal skill_activated(skill_id: String)
## Навык деактивирован (истёк таймер или принудительный сброс).
@warning_ignore("unused_signal")
signal skill_deactivated(skill_id: String)

# --- XP и валюты ---
## XP изменился. current — текущий XP на уровне, threshold — сколько надо до следующего, source — откуда.
@warning_ignore("unused_signal")
signal xp_changed(current: int, threshold: int, source: String)
## Изменилась вода (основная валюта магазина).
@warning_ignore("unused_signal")
signal water_changed(water: int)
## Изменились кристаллы.
@warning_ignore("unused_signal")
signal gems_changed(gems: int)
## Изменились жетоны (premium).
@warning_ignore("unused_signal")
signal tokens_changed(tokens: int)
## Попытка покупки XP не удалась (не хватает валюты).
@warning_ignore("unused_signal")
signal xp_purchase_failed(currency: String, required: int)

# --- Магазин ---
## Игрок вошёл в ShopZone и анимация завершена — открыть экран магазина.
@warning_ignore("unused_signal")
signal shop_opened()
## Пользователь закрыл магазин — ShopZone играет обратную анимацию.
@warning_ignore("unused_signal")
signal shop_closed()

# --- Взаимодействия (InteractZone) ---
## Игрок активировал зону взаимодействия.
## interact_type: "info" | "loot" | "custom"
## title и description — текст для InfoPopup (могут быть пустыми для loot/custom).
@warning_ignore("unused_signal")
signal interact_triggered(interact_type: String, title: String, description: String)
## InfoPopup закрыт игроком.
@warning_ignore("unused_signal")
signal interact_closed()
