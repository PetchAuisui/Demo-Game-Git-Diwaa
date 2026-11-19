class_name SpellEffectOverlay
extends Control
## เล่นเอฟเฟกต์คาถากลางฉาก (พื้นที่ว่างระหว่างแผง Files / Git Graph / Terminal)
## วงเวทหมุน + ประกายไฟ + ชื่อผลลัพธ์ในโลกเวท + ความหมายจริงของ Git บรรทัดเล็ก
## ไม่รับเมาส์ (MOUSE_FILTER_IGNORE) จึงไม่บังการคลิกแผงอื่น

## จุดกึ่งกลางของ "เวที" เทียบกับขนาดหน้าจอ (ช่องว่างระหว่างแผงซ้าย-ขวา เหนือ Terminal)
const STAGE_CENTER := Vector2(0.5, 0.36)
const STAGE_RADIUS_RATIO := 0.11
const DURATION := 1.9
const STAGGER := 0.45

const COLORS := {
	SpellEffectDetector.Kind.RUNE_GLOW: Color("8fd3ff"),
	SpellEffectDetector.Kind.NAME_BOUND: Color("ffd27a"),
	SpellEffectDetector.Kind.TOME_CREATED: Color("ffd27a"),
	SpellEffectDetector.Kind.REVEALED: Color("b9c7ff"),
	SpellEffectDetector.Kind.TO_ALTAR: Color("7af0d4"),
	SpellEffectDetector.Kind.FROM_ALTAR: Color("9fb4c8"),
	SpellEffectDetector.Kind.INSCRIBED: Color("ffcf5a"),
	SpellEffectDetector.Kind.TIME_REWIND: Color("a8c8ff"),
	SpellEffectDetector.Kind.CURSE_LIFTED: Color("9dffb0"),
	SpellEffectDetector.Kind.DIMENSION_SPLIT: Color("c48bff"),
	SpellEffectDetector.Kind.DIMENSION_CLOSED: Color("8c7aa8"),
	SpellEffectDetector.Kind.DIMENSION_STEP: Color("b07bff"),
	SpellEffectDetector.Kind.DIMENSIONS_MERGED: Color("ffb3f0"),
	SpellEffectDetector.Kind.DIMENSION_CLASH: Color("ff6b6b"),
	SpellEffectDetector.Kind.PORTAL_SEND: Color("6fe3ff"),
	SpellEffectDetector.Kind.PORTAL_RECEIVE: Color("6fffc2"),
	SpellEffectDetector.Kind.FIZZLE: Color("ff5f5f"),
}

## ผลที่สำคัญน้อย (สำรวจ/ล้มเหลว) เล่นแบบเล็กและสั้นกว่า เพื่อไม่ให้ฉากรก
const SUBTLE_KINDS := [SpellEffectDetector.Kind.REVEALED, SpellEffectDetector.Kind.FIZZLE]

signal effect_started(effect: Dictionary)

var _queue: Array[Dictionary] = []
var _playing := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func play_all(effects: Array[Dictionary]) -> void:
	_queue.append_array(effects)
	if not _playing:
		_play_next()


func _play_next() -> void:
	if _queue.is_empty() or not is_inside_tree():
		_playing = false
		return
	_playing = true
	var effect: Dictionary = _queue.pop_front()
	_spawn(effect)
	effect_started.emit(effect)
	get_tree().create_timer(STAGGER if not _queue.is_empty() else 0.0).timeout.connect(_play_next)


func _spawn(effect: Dictionary) -> void:
	var kind: int = effect["kind"]
	var subtle: bool = kind in SUBTLE_KINDS
	var color: Color = COLORS.get(kind, Color.WHITE)
	var stage := Vector2(size.x * STAGE_CENTER.x, size.y * STAGE_CENTER.y)
	var radius := minf(size.x, size.y) * STAGE_RADIUS_RATIO * (0.6 if subtle else 1.0)

	var circle := MagicCircle.new()
	circle.color = color
	circle.radius = radius
	circle.kind = kind
	circle.position = stage
	circle.scale = Vector2.ONE * 0.4
	circle.modulate.a = 0.0
	add_child(circle)

	var title := _make_label(str(effect["title"]), int(radius * 0.36) if not subtle else int(radius * 0.5), color)
	var meaning := _make_label(_meaning_line(effect), int(radius * 0.18) if not subtle else int(radius * 0.26), Color(1, 1, 1, 0.85))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)
	box.add_child(meaning)
	box.modulate.a = 0.0
	add_child(box)
	box.reset_size()
	box.position = stage + Vector2(-box.size.x * 0.5, radius * 1.15)

	var duration := DURATION * (0.6 if subtle else 1.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(circle, "modulate:a", 1.0, 0.18)
	tw.tween_property(circle, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(box, "modulate:a", 1.0, 0.25).set_delay(0.12)
	tw.tween_property(box, "position:y", box.position.y - radius * 0.15, duration).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_interval(maxf(0.0, duration - 0.75))
	tw.chain().set_parallel(true)
	tw.tween_property(circle, "modulate:a", 0.0, 0.45)
	tw.tween_property(circle, "scale", Vector2.ONE * 1.35, 0.45)
	tw.tween_property(box, "modulate:a", 0.0, 0.45)
	tw.chain().tween_callback(func() -> void:
		circle.queue_free()
		box.queue_free())


func _meaning_line(effect: Dictionary) -> String:
	var detail := str(effect.get("detail", ""))
	var meaning := str(effect["meaning"])
	return meaning if detail.is_empty() else "%s · %s" % [meaning, detail.left(40)]


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", maxi(font_size, 14))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.1, 0.95))
	label.add_theme_constant_override("outline_size", maxi(4, font_size / 6))
	return label


## วงเวทที่วาดเอง: วงแหวนสองชั้นหมุนสวนกัน ขีดอักขระรอบวง และประกายไฟลอยขึ้น
## รูปร่างเปลี่ยนเล็กน้อยตามชนิดผล (ย้อนกาลหมุนกลับทิศ, ปะทะสั่น, มิติแยกเป็นสองวง)
class MagicCircle:
	extends Node2D

	var color := Color.WHITE
	var radius := 60.0
	var kind := 0
	var _time := 0.0
	var _sparks: Array[Dictionary] = []

	func _ready() -> void:
		for i in 18:
			_sparks.append({
				"angle": randf() * TAU,
				"distance": randf_range(0.2, 1.0),
				"speed": randf_range(0.25, 0.8),
				"size": randf_range(1.5, 3.5),
			})

	func _process(delta: float) -> void:
		_time += delta
		if kind == SpellEffectDetector.Kind.DIMENSION_CLASH or kind == SpellEffectDetector.Kind.FIZZLE:
			position.x += sin(_time * 60.0) * 1.2
		queue_redraw()

	func _draw() -> void:
		var direction := -1.0 if kind == SpellEffectDetector.Kind.TIME_REWIND else 1.0
		var spin := _time * 1.6 * direction
		var glow := color
		glow.a = 0.18
		draw_circle(Vector2.ZERO, radius * 1.05, glow)

		if kind == SpellEffectDetector.Kind.DIMENSION_SPLIT or kind == SpellEffectDetector.Kind.DIMENSIONS_MERGED:
			var gap := radius * 0.35 * (1.0 - minf(_time, 1.0) if kind == SpellEffectDetector.Kind.DIMENSIONS_MERGED else minf(_time, 1.0))
			_draw_ring(Vector2(-gap, 0), radius * 0.8, spin)
			_draw_ring(Vector2(gap, 0), radius * 0.8, -spin)
		else:
			_draw_ring(Vector2.ZERO, radius, spin)
			_draw_ring(Vector2.ZERO, radius * 0.66, -spin * 1.4)

		for spark in _sparks:
			var t: float = fmod(_time * spark["speed"], 1.0)
			var p: Vector2 = Vector2.from_angle(spark["angle"]) * radius * float(spark["distance"])
			p.y -= t * radius * 0.9
			var c := color.lightened(0.4)
			c.a = 1.0 - t
			draw_circle(p, spark["size"], c)

	func _draw_ring(center: Vector2, r: float, rotation_angle: float) -> void:
		draw_arc(center, r, 0.0, TAU, 64, color, 2.5, true)
		draw_arc(center, r * 0.9, 0.0, TAU, 64, Color(color, 0.55), 1.2, true)
		for i in 12:
			var a := rotation_angle + TAU * i / 12.0
			var inner := center + Vector2.from_angle(a) * r * 0.9
			var outer := center + Vector2.from_angle(a) * r
			draw_line(inner, outer, color, 2.0, true)
			if i % 3 == 0:
				draw_circle(center + Vector2.from_angle(a) * r * 0.78, r * 0.035, color)
		var star := PackedVector2Array()
		for i in 6:
			star.append(center + Vector2.from_angle(rotation_angle * 0.5 + TAU * i / 5.0 * 2.0) * r * 0.62)
		draw_polyline(star, Color(color, 0.8), 1.6, true)
