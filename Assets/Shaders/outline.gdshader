shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.95, 0.2, 1.0);
uniform float outline_size : hint_range(0.0, 10.0) = 5.0;
uniform bool show_outline = false;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	COLOR = col;

	if (show_outline && col.a < 0.1) {
		vec2 size = outline_size * TEXTURE_PIXEL_SIZE;
		float alpha =
			texture(TEXTURE, UV + vec2(size.x, 0.0)).a +
			texture(TEXTURE, UV - vec2(size.x, 0.0)).a +
			texture(TEXTURE, UV + vec2(0.0, size.y)).a +
			texture(TEXTURE, UV - vec2(0.0, size.y)).a;
		if (alpha > 0.0) {
			COLOR = outline_color;
		}
	}
}
