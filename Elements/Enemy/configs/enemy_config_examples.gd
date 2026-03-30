# Примеры создания конфигураций врагов

## Этот файл содержит примеры создания EnemyData через GDScript
## В реальном проекте лучше создавать .tres файлы через редактор Godot

## Пример 1: Ёжик-агрессор
static func create_hedgehog_aggressive() -> EnemyData:
	var data = EnemyData.new()
	
	# Основная информация
	data.enemy_id = "hedgehog_aggressive"
	data.enemy_name = "Назойливый агрессор"
	data.description = "Прилипает к герою, уменьшает скорость и крадет воду"
	
	# Физические параметры
	data.speed = 50.0
	data.speed_variance = Vector2(0.8, 1.2)
	data.has_gravity = true
	
	# Боевые характеристики
	data.is_immortal = true
	data.damage_type = EnemyData.DamageType.SINGLE
	data.damage_player = 5.0  # 5% здоровья
	data.damage_is_percent = true
	data.damage_interval = 1.0
	
	# Кража воды
	data.can_steal_water = true
	data.water_steal_amount = 5.0  # 5 литров
	data.water_steal_interval = 5.0  # каждые 5 секунд
	data.flee_if_no_water = true
	
	# AI
	data.ai_type = EnemyData.AIType.AGGRESSIVE
	data.aggression = Vector2(0.7, 1.3)
	data.target_distance = 20.0
	data.attack_distance = 30.0
	
	# Появление
	data.spawn_trigger = EnemyData.SpawnTrigger.TIMER
	data.spawn_delay_min = 30.0
	data.spawn_delay_max = 180.0
	data.spawn_probability = 0.5  # 50% шанс (при выборе между 2 типами)
	data.spawn_position_offset = Vector2(-150, 0)
	data.max_instances = 1
	
	# Исчезновение
	data.idle_timeout = 10.0
	data.despawn_on_player_stop = true
	data.despawn_on_empty_water = true
	data.despawn_on_home_return = true
	
	# Модификаторы
	data.affected_by_gloves = true
	data.affected_by_boots = true
	data.affected_by_cloak = true
	data.affected_by_wheelbarrow = true
	data.damage_reduction_per_upgrade = 0.15
	
	return data

## Пример 2: Ёжик-воришка
static func create_hedgehog_thief() -> EnemyData:
	var data = EnemyData.new()
	
	# Основная информация
	data.enemy_id = "hedgehog_thief"
	data.enemy_name = "Пугливый воришка"
	data.description = "Крадет воду, держится на расстоянии, убегает при приближении"
	
	# Физические параметры
	data.speed = 60.0  # Чуть быстрее
	data.speed_variance = Vector2(0.8, 1.2)
	data.has_gravity = true
	
	# Боевые характеристики
	data.is_immortal = true
	data.damage_type = EnemyData.DamageType.SINGLE
	data.damage_player = 5.0  # 5% при наступлении
	data.damage_wheelbarrow = 10.0  # 10 литров при наступлении
	data.damage_is_percent = true
	
	# Кража воды
	data.can_steal_water = true
	data.water_steal_amount = 10.0  # 10% от текущей воды
	data.water_steal_is_percent = true
	data.water_steal_interval = 3.0
	data.flee_if_no_water = true
	
	# AI
	data.ai_type = EnemyData.AIType.THIEF
	data.aggression = Vector2(0.7, 1.3)
	data.target_distance = 60.0  # Держится на дистанции
	data.attack_distance = 40.0
	data.flee_distance = 40.0
	
	# Появление
	data.spawn_trigger = EnemyData.SpawnTrigger.TIMER
	data.spawn_delay_min = 30.0
	data.spawn_delay_max = 180.0
	data.spawn_probability = 0.5  # 50% шанс
	data.spawn_position_offset = Vector2(-150, 0)
	data.max_instances = 1
	
	# Исчезновение
	data.idle_timeout = 10.0
	data.despawn_on_player_stop = true
	data.despawn_on_empty_water = true
	data.despawn_on_home_return = true
	
	# Модификаторы
	data.affected_by_gloves = true
	data.affected_by_boots = true
	data.affected_by_wheelbarrow = true
	
	return data

## Пример 3: Пчела
static func create_bee() -> EnemyData:
	var data = EnemyData.new()
	
	# Основная информация
	data.enemy_id = "bee"
	data.enemy_name = "Пчела-агрессор"
	data.description = "Территориальный враг, постоянный урон в области улья/дерева"
	
	# Физические параметры
	data.speed = 80.0  # Быстрая
	data.has_gravity = false  # Летает
	
	# Боевые характеристики
	data.is_immortal = true
	data.damage_type = EnemyData.DamageType.CONTINUOUS
	data.damage_player = 2.0  # Постоянный небольшой урон
	data.damage_wheelbarrow = 1.0
	data.damage_interval = 0.5  # Каждые 0.5 секунды
	
	# Кража воды
	data.can_steal_water = true
	data.water_steal_amount = 2.0
	data.water_steal_interval = 1.0
	data.flee_if_no_water = false  # Атакует тачку если нет воды
	
	# AI
	data.ai_type = EnemyData.AIType.PATROL  # Патрулирует область
	data.detection_radius = 150.0
	data.patrol_radius = 100.0
	
	# Появление
	data.spawn_trigger = EnemyData.SpawnTrigger.AREA_ENTER  # При входе в область улья
	data.max_instances = 3  # Может быть несколько пчел
	
	# Исчезновение
	data.despawn_on_player_stop = false  # Не исчезает при остановке
	data.despawn_on_empty_water = false
	data.despawn_distance = 300.0  # Исчезает при удалении от улья
	
	# Модификаторы
	data.affected_by_gloves = true
	data.affected_by_boots = true
	data.affected_by_cloak = true
	data.affected_by_wheelbarrow = true
	
	return data

## Пример 4: Змея
static func create_snake() -> EnemyData:
	var data = EnemyData.new()
	
	# Основная информация
	data.enemy_id = "snake"
	data.enemy_name = "Змея"
	data.description = "Территориальный враг, сильный одноразовый урон"
	
	# Физические параметры
	data.speed = 40.0  # Медленная
	data.has_gravity = true
	
	# Боевые характеристики
	data.is_immortal = true
	data.damage_type = EnemyData.DamageType.SINGLE
	data.damage_player = 20.0  # Значительный урон
	data.damage_wheelbarrow = 15.0  # Средний урон тачке
	data.damage_interval = 10.0  # Кулдаун 10 сек
	
	# Кража воды
	data.can_steal_water = true
	data.water_steal_amount = 20.0
	data.water_steal_interval = 10.0
	data.flee_if_no_water = false  # Атакует тачку
	
	# AI
	data.ai_type = EnemyData.AIType.IDLE  # Территориальная
	data.detection_radius = 100.0
	
	# Появление
	data.spawn_trigger = EnemyData.SpawnTrigger.AREA_ENTER
	data.max_instances = 2
	
	# Исчезновение
	data.idle_timeout = 10.0  # Исчезает через 10 сек бездействия
	data.despawn_distance = 200.0
	
	# Модификаторы
	data.affected_by_gloves = true
	data.affected_by_boots = true
	data.affected_by_wheelbarrow = true
	
	return data

## Создать все базовые конфигурации
static func create_all_configs() -> Array[EnemyData]:
	return [
		create_hedgehog_aggressive(),
		create_hedgehog_thief(),
		create_bee(),
		create_snake()
	]
