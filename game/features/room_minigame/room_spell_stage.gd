class_name RoomSpellStage
extends RefCounted
## ฉากของคาถาในห้อง: ทุกคาถาหลักของแต่ละด่านมี "ช่วงเวลาเด่น" ของตัวเองบนเฟอร์นิเจอร์และลานโกลาหล
## เหตุ → การปะทะ → ผล เสมอ (เวลร่าย → พลังวิ่งไปที่เป้า → เป้าตอบสนอง) ไม่ใช่สติกเกอร์ลอย ๆ
##   git init      แท่นวางคัมภีร์ว่างเปล่า → วงเวทกาง แสงทองฟาด → คัมภีร์ร่วงลงมาประทับ ภูตกระเจิง
##   git clone     ประตูคลังเวทเปิดเหนือแท่น → คัมภีร์ลอยออกจากประตูลงมาประทับ
##   git status    แสงตะเกียงกวาดทั้งห้อง (ห้องมืดถูกเปิดเผย)
##   git log       หน้าประวัติปลิวออกจากคัมภีร์
##   git diff      ลำแสงเทียบรอยระหว่างสองโซน (- แดง / + เขียว) ตามรูปแบบคาถา
##   git add       แท่นเตรียมเรืองวาบ · git commit  พลังจากแท่นพุ่งเข้าคัมภีร์ หน้าใหม่ถูกจารึก
##   git restore   ควันคำสาปหลุดลอย · git reset  นาฬิกาเวทหมุนย้อน
## ข้อมูลทั้งหมดมาจาก SpellEffectDetector (สิ่งที่ Git ทำจริง) ไม่ใช่การเดาจากข้อความคำสั่ง

const DESK := RoomGame.STATE_DESK
const ALTAR := RoomGame.STATE_ALTAR
const TOME := RoomGame.STATE_TOME

var _view: RoomView


func _init(view: RoomView) -> void:
	_view = view


func play(effects: Array[Dictionary], command: String, snapshot: GitRepositorySnapshot) -> void:
	var tokens := LevelMission.tokenize(command)
	var spell := tokens[1] if tokens.size() >= 2 and tokens[0] == "git" else ""
	for effect in effects:
		match int(effect["kind"]):
			SpellEffectDetector.Kind.TOME_CREATED:
				if spell == "clone":
					_tome_from_vault()
				else:
					_tome_born()
			SpellEffectDetector.Kind.INSCRIBED:
				_inscribe()
			SpellEffectDetector.Kind.TO_ALTAR:
				_to_altar()
			SpellEffectDetector.Kind.FROM_ALTAR:
				_from_altar()
			SpellEffectDetector.Kind.REVEALED:
				match spell:
					"status":
						_lantern_sweep()
					"log", "show":
						_history_pages(snapshot)
					"diff":
						_compare_beam(tokens)
			SpellEffectDetector.Kind.CURSE_LIFTED:
				_curse_lifted(str(effect.get("detail", "")))
			SpellEffectDetector.Kind.TIME_REWIND:
				_rewind()
			SpellEffectDetector.Kind.FIZZLE:
				_view.lane().fizzle()


# ---------------------------------------------------------------- จุดอ้างอิง

func _fx() -> Control:
	return _view.fx_layer()


func _u() -> float:
	return _view.fx_unit()


func _top(state: String) -> Vector2:
	var furniture := _view.furniture(state)
	return _view.to_fx(furniture.top_global()) if furniture != null else _fx().size * 0.5


func _tome_point() -> Vector2:
	var furniture := _view.furniture(TOME)
	return _view.to_fx(furniture.tome_global()) if furniture != null else _fx().size * 0.5


func _wait(seconds: float) -> void:
	await _view.get_tree().create_timer(seconds).timeout


# ---------------------------------------------------------------- คัมภีร์

## git init: วงเวทกางใต้แท่น → แสงทองฟาดลงมา → คัมภีร์ร่วงลงมาประทับ (หยุดภาพตอนกระทบ) → ภูตกระเจิง
func _tome_born() -> void:
	var at := _top(TOME)
	var u := _u()
	_view.lane().vel_cast()
	PixelFx.spawn(_fx(), "banish", at + Vector2(0, 6 * u), u * 0.55, 1.2)
	await _wait(0.35)
	var beam := PixelFx.spawn(_fx(), "fragment_beam", at, u * 0.8)
	if beam != null:
		_view.get_tree().create_timer(0.9).timeout.connect(beam.queue_free)
	_view.furniture(TOME).tome_born()
	await _wait(0.5)
	PixelFx.hit_stop(_view.get_tree(), 0.08)
	PixelFx.spawn(_fx(), "commit_sparkle", at, u * 1.2)
	_view.shake(7.0)
	_view.lane().scatter_imps()


## git clone: ประตูคลังเวทเปิดเหนือแท่น แล้วคัมภีร์ (พร้อมประวัติทั้งเล่ม) ลอยลงมาประทับ
func _tome_from_vault() -> void:
	var at := _top(TOME)
	var u := _u()
	var portal := PixelFx.spawn(_fx(), "vault_portal", at + Vector2(0, -70 * u), u * 0.7)
	await _wait(0.45)
	_view.furniture(TOME).tome_born()
	_stream(at + Vector2(0, -95 * u), _tome_point(), 5, Color("ffe07a"))
	await _wait(0.6)
	PixelFx.hit_stop(_view.get_tree(), 0.06)
	PixelFx.spawn(_fx(), "commit_sparkle", at, u * 1.2)
	_view.shake(5.0)
	_view.lane().scatter_imps()
	await _wait(0.6)
	if is_instance_valid(portal):
		var tw := portal.create_tween()
		tw.tween_property(portal, "scale", Vector2(portal.scale.x, 0.0), 0.25).set_ease(Tween.EASE_IN)
		tw.tween_callback(portal.queue_free)


## git commit: พลังจากแท่นเตรียมพุ่งเป็นลูกไฟทองเข้าคัมภีร์ → หน้าใหม่ถูกจารึก
func _inscribe() -> void:
	var from := _top(ALTAR)
	var to := _tome_point()
	var u := _u()
	_view.lane().vel_cast()
	_view.furniture(ALTAR).altar_pulse()
	var bolt := PixelFx.spawn(_fx(), "spell_bolt", from, u * 0.6)
	if bolt != null:
		bolt.rotation = (to - from).angle()
		var tw := bolt.create_tween()
		tw.tween_property(bolt, "position", to, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(bolt.queue_free)
	await _wait(0.28)
	PixelFx.hit_stop(_view.get_tree(), 0.06)
	_view.furniture(TOME).page_written()
	PixelFx.spawn(_fx(), "commit_sparkle", to + Vector2(0, 10 * u), u)
	_view.shake(4.0)


func _to_altar() -> void:
	await _wait(0.4) # ให้ของบินถึงแท่นก่อน
	_view.furniture(ALTAR).altar_pulse()


func _from_altar() -> void:
	PixelFx.spawn(_fx(), "imp_poof", _top(ALTAR), _u() * 0.6)


# ---------------------------------------------------------------- ฟื้นคืน / ย้อนกาล

## git restore: ควันคำสาปสีม่วงลอยหลุดออกจากของแต่ละชิ้น แล้วประกายเขียวแห่งการฟื้นคืน
func _curse_lifted(detail: String) -> void:
	var u := _u()
	for path in detail.split(", ", false):
		var at := _view.row_point(path)
		if at == Vector2.INF:
			at = _top(DESK)
		var smoke := PixelFx.spawn(_fx(), "imp_poof", at + Vector2(0, 8 * u), u * 0.7)
		if smoke != null:
			var tw := smoke.create_tween()
			tw.tween_property(smoke, "position:y", at.y - 30 * u, 0.9).set_ease(Tween.EASE_OUT)
		var heal := PixelFx.spawn(_fx(), "stage_sparkle", at + Vector2(0, 12 * u), u * 0.8)
		if heal != null:
			heal.modulate = Color(0.7, 1.4, 0.8)
		await _wait(0.12)


## git reset: หน้าปัดนาฬิกาเวทลอยกลางห้อง เข็มหมุนย้อน แสงสีฟ้ากวาดจากขวาไปซ้าย
func _rewind() -> void:
	_view.lane().vel_cast()
	var clock := ClockFace.new()
	var rect := _view.zone_rect(DESK).merge(_view.zone_rect(TOME))
	clock.position = rect.position
	clock.size = rect.size
	_fx().add_child(clock)
	var tw := clock.create_tween()
	tw.tween_property(clock, "progress", 1.0, 1.3).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(clock.queue_free)
	var sweep := LightSweep.new()
	sweep.color = Color("a8c8ff")
	sweep.position = rect.position
	sweep.size = rect.size
	sweep.progress = 1.0
	_fx().add_child(sweep)
	var back := sweep.create_tween()
	back.tween_property(sweep, "progress", 0.0, 0.9).set_trans(Tween.TRANS_SINE)
	back.tween_callback(sweep.queue_free)
	_view.shake(3.0)


# ---------------------------------------------------------------- คาถาสำรวจ

## git status: ลำแสงตะเกียงกวาดจากซ้ายไปขวาทั่วทั้งสามโซน
func _lantern_sweep() -> void:
	var sweep := LightSweep.new()
	sweep.color = Color("fff3c0")
	var rect := _view.zone_rect(DESK).merge(_view.zone_rect(TOME))
	sweep.position = rect.position
	sweep.size = rect.size
	_fx().add_child(sweep)
	var tw := sweep.create_tween()
	tw.tween_property(sweep, "progress", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(sweep.queue_free)


## git log: หน้าประวัติปลิวออกจากคัมภีร์ทีละหน้า (หนึ่งหน้าต่อหนึ่งการจารึก สูงสุด 7)
func _history_pages(snapshot: GitRepositorySnapshot) -> void:
	var count := clampi(snapshot.commits.size() if snapshot != null else 3, 1, 7)
	var from := _tome_point()
	var u := _u()
	for i in count:
		var to := from + Vector2(randf_range(-90, 40) * u * 0.6, randf_range(-80, -40) * u * 0.6)
		_flutter(from, to, Color("f6ead0"))
		await _wait(0.08)


## git diff: ลำแสงเทียบรอยระหว่างสองโซน มีอักขระ - (แดง) และ + (เขียว) ไหลไปตามลำแสง
##   diff = โต๊ะ ↔ แท่น · diff --staged = แท่น ↔ คัมภีร์ · diff HEAD = โต๊ะ ↔ คัมภีร์
func _compare_beam(tokens: PackedStringArray) -> void:
	var a := DESK
	var b := ALTAR
	if tokens.has("--staged") or tokens.has("--cached"):
		a = ALTAR
		b = TOME
	elif tokens.has("HEAD"):
		a = DESK
		b = TOME
	var beam := CompareBeam.new()
	beam.from = _top(a) + Vector2(0, -20 * _u())
	beam.to = _top(b) + Vector2(0, -20 * _u())
	beam.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx().add_child(beam)
	var tw := beam.create_tween()
	tw.tween_property(beam, "progress", 1.0, 1.4)
	tw.tween_callback(beam.queue_free)


# ---------------------------------------------------------------- ตัวช่วย

## กระดาษปลิวจาก a ไป b แล้วจางหาย
func _flutter(a: Vector2, b: Vector2, color: Color) -> void:
	var page := ColorRect.new()
	page.color = color
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.size = Vector2(6, 8) * _u()
	page.pivot_offset = page.size * 0.5
	page.position = a
	_fx().add_child(page)
	var tw := page.create_tween()
	tw.tween_method(func(t: float) -> void:
		page.position = a.lerp(b, ease(t, 0.5)) + Vector2(sin(t * 9.0) * 6.0, 0)
		page.rotation = sin(t * 7.0) * 0.6, 0.0, 1.0, 0.9)
	tw.parallel().tween_property(page, "modulate:a", 0.0, 0.4).set_delay(0.5)
	tw.tween_callback(page.queue_free)


## สายของแสง (หน้าคัมภีร์) ไหลจาก a ไป b ทีละชิ้น
func _stream(a: Vector2, b: Vector2, count: int, color: Color) -> void:
	for i in count:
		var page := ColorRect.new()
		page.color = color
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.size = Vector2(5, 7) * _u()
		page.position = a
		_fx().add_child(page)
		var lift := Vector2(randf_range(-30, 30), 0)
		var tw := page.create_tween()
		tw.tween_interval(i * 0.09)
		tw.tween_method(func(t: float) -> void:
			page.position = a.lerp(b, ease(t, -1.6)) + lift * sin(t * PI)
			page.rotation = t * 6.0, 0.0, 1.0, 0.45)
		tw.tween_callback(page.queue_free)


## แสงตะเกียง: แถบแสงพิกเซลแนวตั้งที่กวาดผ่าน (ขอบแข็ง ไม่ไล่สี)
class LightSweep extends Control:
	var progress := 0.0:
		set(value):
			progress = value
			queue_redraw()
	var color := Color.WHITE

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var x := lerpf(-60.0, size.x + 60.0, progress)
		var bands := [[0.0, 26.0, 0.3], [-10.0, 46.0, 0.14], [-24.0, 74.0, 0.07]]
		for band in bands:
			draw_rect(Rect2(x + band[0] - band[1] * 0.5, 0, band[1], size.y), Color(color, band[2]))


## หน้าปัดนาฬิกาเวท: วงจุดพิกเซล 12 ขีด เข็มยาว/สั้นหมุนทวนเข็มสองรอบ แล้วจางหาย
class ClockFace extends Control:
	var progress := 0.0:
		set(value):
			progress = value
			queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var fade := minf(1.0, progress / 0.15) * (1.0 - maxf(0.0, (progress - 0.75) / 0.25))
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.36
		var col := Color(Color("a8c8ff"), 0.85 * fade)
		var dim := Color(Color("a8c8ff"), 0.25 * fade)
		draw_circle(c, r, Color(0.05, 0.08, 0.2, 0.45 * fade))
		for i in 72:
			var a := TAU * i / 72.0
			var p := (c + Vector2(cos(a), sin(a)) * r).round()
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(3, 3)), dim)
		for i in 12:
			var a := TAU * i / 12.0
			var p := (c + Vector2(cos(a), sin(a)) * (r - 8.0)).round()
			draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), col)
		var turn := -ease(progress, 0.5) * TAU * 2.0
		for hand in [[r * 0.8, 1.0, 4.0], [r * 0.5, 1.0 / 12.0, 6.0]]:
			var a: float = turn * float(hand[1]) - PI * 0.5
			var steps := int(float(hand[0]) / 4.0)
			for k in steps:
				var p := (c + Vector2(cos(a), sin(a)) * k * 4.0).round()
				draw_rect(Rect2(p - Vector2(hand[2], hand[2]) * 0.5, Vector2(hand[2], hand[2])), col)
		draw_rect(Rect2(c - Vector2(5, 5), Vector2(10, 10)), Color(1, 1, 1, fade))


## ลำแสงเทียบรอย: จุดพิกเซลเรียงเป็นเส้นระหว่างสองจุด มีอักขระ - และ + ไหลสวนกัน
class CompareBeam extends Control:
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var progress := 0.0:
		set(value):
			progress = value
			queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var fade := 1.0 - maxf(0.0, (progress - 0.75) / 0.25)
		var grow := minf(1.0, progress / 0.25)
		var end := from.lerp(to, grow)
		var steps := int(from.distance_to(end) / 6.0)
		for i in steps:
			var p := from.lerp(end, float(i) / maxf(1.0, steps))
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(3, 3)), Color(1, 1, 1, 0.5 * fade))
		var font := ThemeDB.fallback_font
		for i in 4:
			var t := fmod(progress * 1.6 + i * 0.25, 1.0)
			var minus := from.lerp(to, t) + Vector2(0, -10)
			var plus := to.lerp(from, t) + Vector2(0, 14)
			draw_string(font, minus, "−", HORIZONTAL_ALIGNMENT_CENTER, -1, 22, Color(Color("ff7b7b"), fade))
			draw_string(font, plus, "+", HORIZONTAL_ALIGNMENT_CENTER, -1, 22, Color(Color("7ee8a8"), fade))
		for point in [from, to]:
			draw_rect(Rect2(point - Vector2(5, 5), Vector2(10, 10)), Color(1, 1, 1, 0.35 * fade), false, 2.0)
