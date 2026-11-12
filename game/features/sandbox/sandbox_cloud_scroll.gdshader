shader_type canvas_item;

uniform float scroll_speed = 0.025;
uniform float time_offset = 0.0;
uniform vec2 tex_pixel_size = vec2(480.0, 270.0);

void fragment() {
	float shift = fract((TIME + time_offset) * scroll_speed);
	float wrapped_u = fract(UV.x - shift);
	float clamped_v = clamp(UV.y, 0.0, 0.9999);
	COLOR = texture(TEXTURE, vec2(wrapped_u, clamped_v));
}
