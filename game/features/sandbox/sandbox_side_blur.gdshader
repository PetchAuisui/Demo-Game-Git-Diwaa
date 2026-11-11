shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

uniform vec4 fade_color : source_color = vec4(0.01, 0.01, 0.016, 1.0);
uniform float effect_start : hint_range(0.0, 1.0) = 0.45;
uniform float effect_end : hint_range(0.0, 1.0) = 0.98;
uniform float max_blur_px : hint_range(0.0, 48.0) = 26.0;
uniform float max_darkness : hint_range(0.0, 1.0) = 0.76;

void fragment() {
	float edge_dist = abs(SCREEN_UV.x - 0.5) * 2.0;
	float edge_t = smoothstep(effect_start, effect_end, edge_dist);

	if (edge_t <= 0.001) {
		discard;
	}

	vec2 step_uv = SCREEN_PIXEL_SIZE * (max_blur_px * edge_t);

	// 13-tap disc/Gaussian blur in screen space so pixel-art atlas edges never bleed.
	vec3 col = texture(screen_texture, SCREEN_UV).rgb * 0.16;

	const vec2 TAPS[12] = vec2[](
		vec2(1.0, 0.0),
		vec2(-1.0, 0.0),
		vec2(0.0, 1.0),
		vec2(0.0, -1.0),
		vec2(0.707, 0.707),
		vec2(-0.707, 0.707),
		vec2(0.707, -0.707),
		vec2(-0.707, -0.707),
		vec2(0.45, 0.2),
		vec2(-0.45, -0.2),
		vec2(-0.2, 0.45),
		vec2(0.2, -0.45)
	);

	for (int i = 0; i < 12; i++) {
		float scale = (i < 8) ? 1.0 : 0.55;
		vec2 uv = clamp(SCREEN_UV + TAPS[i] * step_uv * scale, vec2(0.001), vec2(0.999));
		col += texture(screen_texture, uv).rgb * 0.07;
	}

	col = mix(col, fade_color.rgb, edge_t * max_darkness);
	float blend_a = smoothstep(0.0, 0.08, edge_t);
	COLOR = vec4(col, blend_a);
}
