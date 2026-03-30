extends Area2D
class_name CloudEntity

## Отдельное облако: конечный автомат состояний, движение, шейдер, трансляция координат.
## Управляется CloudLayer (пул). Трансформируется через TransformZone.

# --- Состояния ---
enum State { SPAWNING, ACTIVE, TRANSFORMING }

# --- Идентификация ---
var cloud_id: int = 0

# --- Конфиги ---
var config: CloudConfig = null         # Текущий активный конфиг
var _target_config: CloudConfig = null # Цель трансформации

# --- Состояние FSM ---
var _state: State = State.SPAWNING
var _spawn_alpha: float = 0.0           # 0→1 при появлении

# --- Направление движения ---
## -1.0 = влево (по умолчанию), 1.0 = вправо
var direction: float = 1.0

# --- Внутренние ссылки ---
@onready var _sprite: Sprite2D = $SpriteImg

# Шейдерный материал — создаётся в _ready()
var _shader_mat: ShaderMaterial = null

const _SHADER = preload("res://Elements/Cloud/Shaders/cloud_transition.gdshader")
const _SPAWN_DURATION: float = 0.6
const _TRANSFORM_DURATION: float = 4.0

# --- Инициализация ---

func _ready() -> void:
	z_index = 1  # Выше капель (z=0), ниже HUD
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = _SHADER
	_sprite.material = _shader_mat
	# Не добавляем в "Cloud_Group" — новая система использует Events.cloud_state_changed,
	# а старый area_cloud_right.gd перехватывает всё из этой группы и сбрасывает позицию.

func setup(id: int, cfg: CloudConfig) -> void:
	cloud_id = id
	config = cfg
	_apply_config_visual(cfg)
	_state = State.SPAWNING
	_spawn_alpha = 0.0
	_sprite.modulate.a = 0.0

# --- Процесс ---

func _process(delta: float) -> void:
	match _state:
		State.SPAWNING:
			_spawn_alpha += delta / _SPAWN_DURATION
			_sprite.modulate.a = clampf(_spawn_alpha, 0.0, 1.0)
			if _spawn_alpha >= 1.0:
				_state = State.ACTIVE
			position.x += direction * config.speed * delta

		State.ACTIVE:
			position.x += direction * config.speed * delta
			Events.cloud_state_changed.emit(cloud_id, global_position, config.cloud_type,
					config.rain_drops_per_second, config.rain_spread_x)

		State.TRANSFORMING:
			position.x += direction * config.speed * delta
			Events.cloud_state_changed.emit(cloud_id, global_position, config.cloud_type,
					config.rain_drops_per_second, config.rain_spread_x)

# --- Трансформация ---

func start_transform(new_config: CloudConfig) -> void:
	if _state == State.TRANSFORMING:
		return  # Не прерывать незавершённую трансформацию
	if config != null and config.cloud_type == new_config.cloud_type:
		return  # Уже нужный тип

	_target_config = new_config
	_state = State.TRANSFORMING

	var tween = create_tween().set_parallel(true)

	# Плавно меняем шейдерные параметры (цвет/темноту)
	tween.tween_method(_set_shader_darkness, _shader_mat.get_shader_parameter("darkness"),
			new_config.shader_darkness, _TRANSFORM_DURATION)
	tween.tween_method(_set_shader_blue_shift, _shader_mat.get_shader_parameter("blue_shift"),
			new_config.shader_blue_shift, _TRANSFORM_DURATION)

	# Плавно меняем масштаб к новому диапазону
	var new_scale = Vector2(
		randf_range(new_config.scale_x_range.x, new_config.scale_x_range.y),
		randf_range(new_config.scale_y_range.x, new_config.scale_y_range.y)
	)
	tween.tween_property(_sprite, "scale", new_scale, _TRANSFORM_DURATION).set_ease(Tween.EASE_IN_OUT)

	# Надёжный финальный callback через Timer (tween_callback.set_delay ненадёжен в parallel)
	get_tree().create_timer(_TRANSFORM_DURATION).timeout.connect(_finish_transform)

func _finish_transform() -> void:
	if _target_config:
		config = _target_config
		_target_config = null
	_state = State.ACTIVE

# --- Ресайкл (без queue_free) ---

func recycle(new_pos: Vector2, new_config: CloudConfig) -> void:
	_state = State.SPAWNING
	_spawn_alpha = 0.0
	position = new_pos
	config = new_config
	_target_config = null
	_apply_config_visual(new_config)
	_sprite.modulate.a = 0.0

# --- Вспомогательные ---

func _apply_config_visual(cfg: CloudConfig) -> void:
	if not _sprite:
		return
	if not cfg.sprite_textures.is_empty():
		_sprite.texture = cfg.sprite_textures[randi() % cfg.sprite_textures.size()]
	_sprite.scale = Vector2(
		randf_range(cfg.scale_x_range.x, cfg.scale_x_range.y),
		randf_range(cfg.scale_y_range.x, cfg.scale_y_range.y)
	)
	if _shader_mat:
		_shader_mat.set_shader_parameter("darkness", cfg.shader_darkness)
		_shader_mat.set_shader_parameter("blue_shift", cfg.shader_blue_shift)
		_shader_mat.set_shader_parameter("transition_progress", 1.0)

func _set_shader_darkness(val: float) -> void:
	if _shader_mat:
		_shader_mat.set_shader_parameter("darkness", val)

func _set_shader_blue_shift(val: float) -> void:
	if _shader_mat:
		_shader_mat.set_shader_parameter("blue_shift", val)
