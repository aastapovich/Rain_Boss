shader_type canvas_item;

/// Затемнение облака (0 = без изменений, 1 = полностью чёрное)
uniform float darkness : hint_range(0.0, 1.0) = 0.0;

/// Синий сдвиг — придаёт грозовой/дождевой оттенок (0 = нет, 1 = максимум)
uniform float blue_shift : hint_range(0.0, 1.0) = 0.0;

/// Прогресс трансформации (0 = старый конфиг, 1 = новый конфиг) — для Tween
uniform float transition_progress : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	// Применяем затемнение
	vec3 darkened = col.rgb * (1.0 - darkness * 0.75);

	// Применяем синий сдвиг: уводим R и G к синему
	vec3 shifted = vec3(
		darkened.r * (1.0 - blue_shift * 0.4),
		darkened.g * (1.0 - blue_shift * 0.2),
		darkened.b + (1.0 - darkened.b) * blue_shift * 0.35
	);

	// transition_progress управляет плавностью через Tween — уже применён к параметрам выше
	COLOR = vec4(shifted, col.a * COLOR.a);
}
