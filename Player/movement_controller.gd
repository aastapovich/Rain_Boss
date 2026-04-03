extends RefCounted
class_name MovementController

var player = null

func setup(p_player) -> void:
	player = p_player

func process_move(delta: float) -> void:
	var left_play   := Input.is_action_pressed("Left")
	var right_play  := Input.is_action_pressed("Right")
	var shift_press := Input.is_action_pressed("Shift")
	update_sprint_state(delta, shift_press, left_play, right_play)
	var anim_speed: float = 1.2 if player.sprint_active else 1.0
	player.speed = (player.speed_shift if player.sprint_active else player.speed_norm) * player.puddle_slow_multiplier

	if player.player_anim:
		player.player_anim.visible     = true
		player.player_anim.speed_scale = anim_speed

	var moving := left_play or right_play
	if moving:
		if left_play:  player._set_facing(true)
		if right_play: player._set_facing(false)
		player.visible = true
		if player.player_anim:
			player.player_anim.play("walk")
	else:
		if player.player_anim:
			player.player_anim.play("stand")
	# Уведомляем тачку о движении (замедление при наполнении).
	var wb: Node = player.get_tree().root.find_child("Wheelbarrow", true, false) if player.get_tree() else null
	if wb and wb.has_method("set_moving"):
		wb.set_moving(moving)

	player.previous_direction = player.direction
	player.direction          = Input.get_axis("Left", "Right")
	player.velocity.x         = player.direction * player.speed
	player.velocity.y        += player.gravity * delta
	player.move_and_slide()

func update_sprint_state(delta: float, shift_pressed: bool, left_play: bool, right_play: bool) -> void:
	if player.sprint_cooldown_left > 0.0:
		player.sprint_cooldown_left = max(0.0, player.sprint_cooldown_left - delta)
	var moving := left_play or right_play
	var wants_sprint := shift_pressed and moving
	if player.sprint_active:
		if not wants_sprint:
			end_sprint()
			return
		player.sprint_time_left -= delta
		if player.sprint_time_left <= 0.0:
			end_sprint()
		return
	if wants_sprint and player.sprint_cooldown_left <= 0.0:
		start_sprint()

func start_sprint() -> void:
	player.sprint_active    = true
	player.sprint_time_left = player.sprint_duration

func end_sprint() -> void:
	player.sprint_active        = false
	player.sprint_time_left     = 0.0
	player.sprint_cooldown_left = player.sprint_cooldown

func get_direction_change() -> float:
	return abs(player.direction - player.previous_direction) * player.speed
