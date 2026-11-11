shader_type canvas_item;

uniform vec2 sheet_grid = vec2(11.0, 12.0);
uniform float min_blue = 0.33;
uniform float min_blue_green_diff = 0.095;

bool _in_window_rect(vec2 fuv) {
	if (fuv.y < 0.174 || fuv.y > 0.615) {
		return false;
	}
	bool in_left = (fuv.x >= 0.162 && fuv.x <= 0.232);
	bool in_center = (fuv.x >= 0.464 && fuv.x <= 0.534);
	bool in_right = (fuv.x >= 0.764 && fuv.x <= 0.834);
	return in_left || in_center || in_right;
}

void fragment() {
	vec4 tex = COLOR;
	vec2 frame_uv = fract(UV * sheet_grid);
	if (_in_window_rect(frame_uv) && tex.b >= min_blue && (tex.b - tex.g) >= min_blue_green_diff) {
		tex.a = 0.0;
	}
	COLOR = tex;
}
