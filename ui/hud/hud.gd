## HUD: прогресс воды к переходу, здоровье, жизни, тачка, золото и уровень.
## Подписывается на Events-сигналы и обновляет UI-элементы при каждом изменении.
extends CanvasLayer

@onready var level_value  = $MarginContainer/VBoxContainer/Row1/LevelValue
@onready var exit_bar     = $MarginContainer/VBoxContainer2/Row2/ExitBar
@onready var exit_label   = $MarginContainer/VBoxContainer2/Row2/ExitLabel
@onready var gold_label   = $MarginContainer/VBoxContainer/Row1/Gold
@onready var gems_label   = $MarginContainer/VBoxContainer/Row1/Gems
@onready var tokens_label = $MarginContainer/VBoxContainer/Row1/Tokens
@onready var water_label  = $MarginContainer/VBoxContainer/Row1/WaterBank
@onready var xp_label     = $MarginContainer/VBoxContainer/Row1/SkillXp
@onready var health_bar   = $MarginContainer/VBoxContainer/Row1/HealthBar
@onready var hp_value     = $MarginContainer/VBoxContainer/Row1/HpValue
@onready var lives_count  = $MarginContainer/VBoxContainer/Row1/HeartBox/LivesCount
@onready var wheelbarrow_label  = $MarginContainer/VBoxContainer2/Row2/Wheelbarrow
@onready var points_label = $MarginContainer/VBoxContainer/Row1/Points

## Подключает Events-сигналы и инициализирует начальное отображение.
func _ready() -> void:
	Events.points_changed.connect(update_points)
	Events.health_changed.connect(update_health)
	Events.lives_count_changed.connect(update_lives_count)
	Events.wheelbarrow_changed.connect(update_wheelbarrow)
	Events.gold_changed.connect(update_gold)
	Events.gems_changed.connect(update_gems)
	Events.tokens_changed.connect(update_tokens)
	Events.water_changed.connect(update_water)
	Events.xp_changed.connect(func(cur, _t, _s): update_xp(cur))
	Events.level_changed.connect(update_level)
	Events.exit_point_changed.connect(update_exit_point)
	update_gold(Globals.gold)
	update_gems(Globals.gems)
	update_tokens(Globals.tokens)
	update_water(Globals.water)
	update_xp(Globals.skill_xp)
	update_level(Globals.level)
	update_health(Globals.health)
	update_lives_count(Globals.lives_count)
	update_wheelbarrow(Globals.point_wheelbarrow)

## Обновляет счётчик воды (общий).
func update_points(pts: int) -> void:
	points_label.text = str(pts)

## Обновляет HealthBar и числовое значение HP.
func update_health(health: int) -> void:
	health_bar.value = clampi(health, 0, 100)
	hp_value.text = str(clampi(health, 0, 100))

## Обновляет цифру жизней на сердечке.
func update_lives_count(count: int) -> void:
	lives_count.text = str(count)

## Обновляет количество воды в тачке.
func update_wheelbarrow(amount) -> void:
	wheelbarrow_label.text = str(amount)

## Обновляет отображение золота.
func update_gold(amount: int) -> void:
	gold_label.text = str(amount)

## Обновляет отображение кристаллов.
func update_gems(amount: int) -> void:
	gems_label.text = str(amount)

## Обновляет отображение жетонов.
func update_tokens(amount: int) -> void:
	tokens_label.text = str(amount)

## Обновляет отображение воды (валюта магазина).
func update_water(amount: int) -> void:
	water_label.text = str(amount)

## Обновляет отображение накопленного опыта.
func update_xp(amount: int) -> void:
	xp_label.text = str(amount)

## Обновляет отображение текущего уровня.
func update_level(lv: int) -> void:
	level_value.text = str(lv)

## Обновляет прогресс-бар воды и метку "X/Y".
func update_exit_point(current: int, max_v: int) -> void:
	exit_bar.max_value = max_v
	exit_bar.value = current
	exit_label.text = " %d/%d" % [current, max_v]
