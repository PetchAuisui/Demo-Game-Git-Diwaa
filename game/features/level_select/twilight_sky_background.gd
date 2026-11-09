extends Control

var _sky_gradient_tex: GradientTexture2D
var _stars: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_gradient()
	_init_stars()
	resized.connect(_on_resized)


func _setup_gradient() -> void:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 0.85, 1.0])
	grad.colors = PackedColorArray([
		Color("#0a0b16"),
		Color("#16132b"),
		Color("#2e1c36"),
		Color("#1b1210")
	])
	_sky_gradient_tex = GradientTexture2D.new()
	_sky_gradient_tex.gradient = grad
	_sky_gradient_tex.fill_from = Vector2(0.0, 0.0)
	_sky_gradient_tex.fill_to = Vector2(0.0, 1.0)
	_sky_gradient_tex.width = 64
	_sky_gradient_tex.height = 256


func _init_stars() -> void:
	_stars.clear()
	var w := size.x if size.x > 0.0 else 1920.0
	var h := size.y if size.y > 0.0 else 1080.0
	var count := int(floorf((w * h) / 12000.0)) + 35
	for i in range(count):
		_stars.append({
			"x": randf() * w,
			"y": randf() * (h * 0.7),
			"size": 3.0 if randf() > 0.85 else 2.0,
			"alpha": randf() * TAU,
			"speed": 0.015 + randf() * 0.025
		})


func _on_resized() -> void:
	_init_stars()
	queue_redraw()


func _process(delta: float) -> void:
	var step := delta * 60.0
	for s in _stars:
		s["alpha"] += s["speed"] * step
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return

	# 1. Deep Midnight Gradient with Violet Twilight Tone
	if _sky_gradient_tex:
		draw_texture_rect(_sky_gradient_tex, Rect2(Vector2.ZERO, size), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#0a0b16"))

	# 2. Twinkling Retro Pixel Stars
	for s in _stars:
		var current_alpha: float = clampf(0.35 + sin(s["alpha"]) * 0.45, 0.1, 1.0)
		draw_rect(Rect2(s["x"], s["y"], s["size"], s["size"]), Color(0.996, 0.941, 0.541, current_alpha))

	# 3. Moon in Upper Right with Soft Glow
	var mx := w * 0.86
	var my := h * 0.14
	for r in range(42, 6, -6):
		var frac := float(r) / 42.0
		var glow_alpha := (1.0 - frac) * 0.35
		draw_circle(Vector2(mx, my), float(r), Color(0.996, 0.953, 0.780, glow_alpha))
	# Soft Moon Body (20x20 pixel square at center)
	draw_rect(Rect2(mx - 10.0, my - 10.0, 20.0, 20.0), Color("#fef3c7"))

	# 4. Distant Castle Silhouette & Mountain Ranges at Bottom
	var m_pts := PackedVector2Array([
		Vector2(0.0, h),
		Vector2(0.0, h * 0.82),
		Vector2(w * 0.2, h * 0.74),
		Vector2(w * 0.45, h * 0.80),
		Vector2(w * 0.7, h * 0.72),
		Vector2(w, h * 0.79),
		Vector2(w, h)
	])
	draw_colored_polygon(m_pts, Color("#171120"))

	# Foreground Dark Castle Spire Silhouette
	var cx := w * 0.28
	var cy := h * 0.84
	var castle_color := Color("#0f0b14")

	# Spire 1
	draw_rect(Rect2(cx - 24.0, cy - 40.0, 48.0, 60.0), castle_color)
	draw_rect(Rect2(cx - 16.0, cy - 70.0, 32.0, 30.0), castle_color)
	draw_rect(Rect2(cx - 4.0, cy - 90.0, 8.0, 20.0), castle_color)

	# Spire 2
	draw_rect(Rect2(cx + 40.0, cy - 20.0, 30.0, 40.0), castle_color)
	draw_rect(Rect2(cx + 48.0, cy - 45.0, 14.0, 25.0), castle_color)
