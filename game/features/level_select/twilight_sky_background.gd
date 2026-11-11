extends Control

const STAR_BUCKET_COUNT := 6

var _sky_gradient_tex: GradientTexture2D
var _stars_by_bucket: Array[Array] = []
var _star_layers: Array[Control] = []
var _star_phases: PackedFloat32Array = PackedFloat32Array()
var _star_speeds: PackedFloat32Array = PackedFloat32Array()
var _foreground_layer: Control = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_gradient()
	_setup_layers()
	_init_stars()
	_redraw_all_layers()
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


func _setup_layers() -> void:
	_star_layers.clear()
	_star_phases.resize(STAR_BUCKET_COUNT)
	_star_speeds.resize(STAR_BUCKET_COUNT)

	for i in range(STAR_BUCKET_COUNT):
		var layer := Control.new()
		layer.name = "StarLayer_%d" % i
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		var bucket_idx := i
		layer.draw.connect(func() -> void: _draw_star_bucket(layer, bucket_idx))
		add_child(layer)
		_star_layers.append(layer)
		_star_phases[i] = (float(i) / float(STAR_BUCKET_COUNT)) * TAU + randf() * 0.4
		_star_speeds[i] = 0.015 + (float(i) / float(maxi(1, STAR_BUCKET_COUNT - 1))) * 0.025
		layer.modulate.a = clampf(0.35 + sin(_star_phases[i]) * 0.45, 0.1, 1.0)

	_foreground_layer = Control.new()
	_foreground_layer.name = "TwilightForeground"
	_foreground_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foreground_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_foreground_layer.draw.connect(_draw_foreground)
	add_child(_foreground_layer)


func _init_stars() -> void:
	_stars_by_bucket.clear()
	for i in range(STAR_BUCKET_COUNT):
		_stars_by_bucket.append([])

	var w := size.x if size.x > 0.0 else 1920.0
	var h := size.y if size.y > 0.0 else 1080.0
	var count := int(floorf((w * h) / 12000.0)) + 35
	for i in range(count):
		var bucket_idx := i % STAR_BUCKET_COUNT
		_stars_by_bucket[bucket_idx].append({
			"x": randf() * w,
			"y": randf() * (h * 0.7),
			"size": 3.0 if randf() > 0.85 else 2.0,
		})


func _redraw_all_layers() -> void:
	queue_redraw()
	for layer in _star_layers:
		if is_instance_valid(layer):
			layer.queue_redraw()
	if is_instance_valid(_foreground_layer):
		_foreground_layer.queue_redraw()


func _on_resized() -> void:
	_init_stars()
	_redraw_all_layers()


func _process(delta: float) -> void:
	var step := delta * 60.0
	for i in range(_star_layers.size()):
		var next_phase := fmod(_star_phases[i] + _star_speeds[i] * step, TAU)
		_star_phases[i] = next_phase
		var layer := _star_layers[i]
		if is_instance_valid(layer):
			layer.modulate.a = clampf(0.35 + sin(next_phase) * 0.45, 0.1, 1.0)


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


func _draw_star_bucket(layer: Control, bucket_idx: int) -> void:
	if bucket_idx < 0 or bucket_idx >= _stars_by_bucket.size():
		return
	var w := layer.size.x
	var h := layer.size.y
	if w <= 0.0 or h <= 0.0:
		return

	# 2. Twinkling Retro Pixel Stars (alpha animated cleanly via layer.modulate.a)
	var star_color := Color(0.996, 0.941, 0.541, 1.0)
	for s: Dictionary in _stars_by_bucket[bucket_idx]:
		layer.draw_rect(Rect2(float(s["x"]), float(s["y"]), float(s["size"]), float(s["size"])), star_color)


func _draw_foreground() -> void:
	if not is_instance_valid(_foreground_layer):
		return
	var w := _foreground_layer.size.x
	var h := _foreground_layer.size.y
	if w <= 0.0 or h <= 0.0:
		return

	# 3. Moon in Upper Right with Soft Glow
	var mx := w * 0.86
	var my := h * 0.14
	for r in range(42, 6, -6):
		var frac := float(r) / 42.0
		var glow_alpha := (1.0 - frac) * 0.35
		_foreground_layer.draw_circle(Vector2(mx, my), float(r), Color(0.996, 0.953, 0.780, glow_alpha))
	# Soft Moon Body (20x20 pixel square at center)
	_foreground_layer.draw_rect(Rect2(mx - 10.0, my - 10.0, 20.0, 20.0), Color("#fef3c7"))

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
	_foreground_layer.draw_colored_polygon(m_pts, Color("#171120"))

	# Foreground Dark Castle Spire Silhouette
	var cx := w * 0.28
	var cy := h * 0.84
	var castle_color := Color("#0f0b14")

	# Spire 1
	_foreground_layer.draw_rect(Rect2(cx - 24.0, cy - 40.0, 48.0, 60.0), castle_color)
	_foreground_layer.draw_rect(Rect2(cx - 16.0, cy - 70.0, 32.0, 30.0), castle_color)
	_foreground_layer.draw_rect(Rect2(cx - 4.0, cy - 90.0, 8.0, 20.0), castle_color)

	# Spire 2
	_foreground_layer.draw_rect(Rect2(cx + 40.0, cy - 20.0, 30.0, 40.0), castle_color)
	_foreground_layer.draw_rect(Rect2(cx + 48.0, cy - 45.0, 14.0, 25.0), castle_color)
