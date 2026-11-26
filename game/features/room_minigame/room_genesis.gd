class_name RoomGenesis
extends Control
## ห้องก่อนมีคัมภีร์ (ด่าน git init / ก่อน clone): ภาพซูมใกล้ของห้องโถงร้างแทนพื้นที่ว่าง
##   กำแพงอิฐ หน้าต่างโค้งที่แสงจันทร์ส่องลงมา คบไฟสั่นไหว ฝุ่นลอยในแสง
##   วงเวทจาง ๆ บนพื้นตรงที่แท่นวางคัมภีร์จะตั้ง และหน้ากระดาษเปล่าลอยวนรอคัมภีร์ที่ยังไม่ถือกำเนิด
## เมื่อคัมภีร์ถือกำเนิด: กล้องซูมออก หน้ากระดาษถูกดูดเข้าวงเวท ภาพนี้จางหาย เผยห้องจริงที่เฟอร์นิเจอร์ร่วงลงมา
## วาดด้วยพิกเซลขนาดเท่ากัน (ไม่ไล่สี) — ไม่รับเมาส์

const ZOOM_IN := 2.2
const WALL := [Color("120d22"), Color("1a1430"), Color("241c3f")]
const FLOOR := [Color("1c1530"), Color("2a2046"), Color("3a2d5c")]
const MOON := Color("c9d8ff")
const FLAME := [Color("ff8c3a"), Color("ffd36b"), Color("fff3c0")]
const FONT_BOLD := "res://assets/fonts/ChakraPetch-Bold.ttf"

## จุดที่วงเวท/แท่นวางคัมภีร์อยู่ (พิกัดของ control นี้ที่สเกล 1) — RoomView ตั้งให้
var focus := Vector2.ZERO

var _world: World
var _circle: PixelFx
var _zoom := ZOOM_IN
var _shift := 0.0      # 0 = จุดโฟกัสอยู่กลางจอ · 1 = จุดโฟกัสอยู่ที่ตำแหน่งจริง (ซูมออกเสร็จ)
var _suck := 0.0       # หน้ากระดาษถูกดูดเข้าวงเวท
var _leaving := false
var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_font = load(FONT_BOLD) if ResourceLoader.exists(FONT_BOLD) else ThemeDB.fallback_font
	_world = World.new()
	_world.owner_view = self
	add_child(_world)


## แสดงห้องโถงร้างแบบซูมใกล้ (เรียกเมื่อห้องยังไม่มีคัมภีร์)
func show_empty() -> void:
	_leaving = false
	_zoom = ZOOM_IN
	_shift = 0.0
	_suck = 0.0
	modulate.a = 1.0
	visible = true


## คัมภีร์กำลังถือกำเนิด: กล้องซูมออก หน้ากระดาษถูกดูดเข้าวงเวท แล้วภาพนี้จางหาย (seconds = เวลาทั้งหมด)
func zoom_out(seconds: float = 1.1) -> void:
	if not visible or _leaving:
		return
	_leaving = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "_suck", 1.0, seconds * 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "_zoom", 1.0, seconds).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "_shift", 1.0, seconds).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "modulate:a", 0.0, seconds * 0.5).set_delay(seconds * 0.5)
	tw.chain().tween_callback(func() -> void: visible = false)


func unit() -> float:
	return maxf(1.0, round(size.y / 110.0))


func _process(_delta: float) -> void:
	if not visible:
		return
	if _circle == null:
		_circle = PixelFx.spawn(_world, "vel_circle", focus, unit() * 0.45)
		if _circle != null:
			_circle.modulate = Color(1.2, 1.0, 0.6, 0.55)
	if _circle != null:
		_circle.position = focus
		_circle.modulate.a = 0.45 + 0.25 * _suck
	# กล้อง: จุดโฟกัส (วงเวท) อยู่กลางจอตอนซูมใกล้ แล้วเลื่อนกลับไปตำแหน่งจริงตอนซูมออก
	var target := (size * Vector2(0.5, 0.86)).lerp(focus, _shift)
	_world.scale = Vector2.ONE * _zoom
	_world.position = target - focus * _zoom
	_world.queue_redraw()
	queue_redraw()


func _draw() -> void:
	if _leaving:
		return
	var text := "ห้องยังว่างเปล่า… หน้ากระดาษเปล่าลอยวนรอคัมภีร์ที่ยังไม่ถือกำเนิด"
	draw_string_outline(_font, Vector2(0, 22), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, 4, Color(0, 0, 0, 0.85))
	draw_string(_font, Vector2(0, 22), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, Color("c9b6ff"))


## โลกของห้องโถง (พิกัดเดียวกับ control ที่สเกล 1) — ถูกขยายด้วยกล้อง
class World extends Node2D:
	var owner_view: RoomGenesis
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta

	func _draw() -> void:
		var v := owner_view
		if v == null:
			return
		var w := v.size.x
		var h := v.size.y
		var u := v.unit()
		# จัดฉากรอบจุดโฟกัส (วงเวท) เพราะตอนซูมใกล้ กล้องเห็นแค่บริเวณนี้
		var f := v.focus
		var floor_y := f.y + 2.0 * u
		# กำแพงอิฐ: แถวสลับ รอยต่อเข้ม
		draw_rect(Rect2(0, 0, w, floor_y), RoomGenesis.WALL[1])
		var brick_h := 8.0 * u
		var brick_w := 22.0 * u
		var row := 0
		var y := 0.0
		while y < floor_y:
			draw_rect(Rect2(0, y, w, u), RoomGenesis.WALL[0])
			var x := -brick_w * 0.5 if row % 2 == 1 else 0.0
			while x < w:
				draw_rect(Rect2(x, y, u, brick_h), RoomGenesis.WALL[0])
				x += brick_w
			y += brick_h
			row += 1
		# หน้าต่างโค้ง + แสงจันทร์เฉียงลงพื้น
		var ww := 16.0 * u
		var wx := f.x - 34.0 * u - ww * 0.5
		var wtop := floor_y - 40.0 * u
		var wh := 22.0 * u
		draw_rect(Rect2(wx - 3 * u, wtop - 3 * u, ww + 6 * u, wh + 6 * u), RoomGenesis.WALL[2])
		draw_rect(Rect2(wx, wtop, ww, wh), Color("2c3a66"))
		draw_rect(Rect2(wx + ww * 0.5 - u * 0.5, wtop, u, wh), RoomGenesis.WALL[0])
		draw_rect(Rect2(wx, wtop + wh * 0.5, ww, u), RoomGenesis.WALL[0])
		for i in 6:
			var t := float(i) / 6.0
			var bx := wx + t * ww
			draw_colored_polygon(PackedVector2Array([
				Vector2(bx, wtop + wh), Vector2(bx + ww / 6.0, wtop + wh),
				Vector2(bx + ww / 6.0 + 30.0 * u, floor_y), Vector2(bx + 30.0 * u, floor_y)]),
				Color(RoomGenesis.MOON, 0.05 + 0.02 * (i % 2)))
		# พื้นหิน
		draw_rect(Rect2(0, floor_y, w, h - floor_y), RoomGenesis.FLOOR[1])
		draw_rect(Rect2(0, floor_y, w, u * 2), RoomGenesis.FLOOR[2])
		var tile := 30.0 * u
		var tx := 0.0
		while tx < w:
			draw_rect(Rect2(tx, floor_y + 2 * u, u, h - floor_y), RoomGenesis.FLOOR[0])
			tx += tile
		# คบไฟสองข้าง
		for fx: float in [f.x - 64.0 * u, f.x + 40.0 * u]:
			_torch(Vector2(fx, floor_y - 30.0 * u), u)
		# หยากไย่ที่มุมหน้าต่าง: ห้องนี้ร้างมานาน
		for i in 5:
			draw_rect(Rect2(wx - 6 * u + i * 2 * u, wtop - 6 * u + i * 2 * u, 2 * u, u), Color(1, 1, 1, 0.12))
			draw_rect(Rect2(wx - 6 * u, wtop - 6 * u + i * 3 * u, u, 2 * u), Color(1, 1, 1, 0.08))
		# ฝุ่นในแสงจันทร์ลอยขึ้นช้า ๆ
		for i in 26:
			var k := float(i) * 12.9898
			var px := wx + fmod(k * 37.0, 60.0 * u) + sin(_time * 0.5 + i) * 4.0 * u
			var py := floor_y - fmod(_time * (3.0 + fmod(k, 4.0)) * u + k * 7.0, 40.0 * u)
			var a := 0.25 + 0.25 * sin(_time * 2.0 + i)
			draw_rect(Rect2(px, py, u, u), Color(RoomGenesis.MOON, a))
		# หน้ากระดาษเปล่าลอยวนเหนือวงเวท (ถูกดูดเข้าหาจุดกลางตอนคัมภีร์ถือกำเนิด)
		var c := v.focus + Vector2(0, -18.0 * u)
		for i in 7:
			var a := _time * (0.8 + 0.1 * i) + TAU * i / 7.0
			var r := (26.0 + 8.0 * sin(_time * 1.3 + i)) * u * (1.0 - v._suck)
			var p := c + Vector2(cos(a) * r, sin(a) * r * 0.45 - sin(_time * 2.0 + i) * 3.0 * u)
			var flip := absf(cos(a * 2.0))
			var pw := maxf(u, 6.0 * u * flip)
			draw_rect(Rect2(p.x - pw * 0.5, p.y - 4.0 * u, pw, 8.0 * u), Color("f6ead0"))
			draw_rect(Rect2(p.x - pw * 0.5, p.y - 4.0 * u, pw, u), Color("fffaf0"))
			draw_rect(Rect2(p.x - pw * 0.5, p.y + 3.0 * u, pw, u), Color("c9b48a"))

	func _torch(at: Vector2, u: float) -> void:
		draw_rect(Rect2(at.x - 2 * u, at.y, 4 * u, 12 * u), Color("4a3020"))
		draw_rect(Rect2(at.x - 4 * u, at.y - 2 * u, 8 * u, 3 * u), Color("6a4a30"))
		var flick := 1.0 if fmod(_time * 8.0 + at.x, 1.0) > 0.5 else 0.0
		draw_rect(Rect2(at.x - 12 * u, at.y - 18 * u, 24 * u, 20 * u), Color(1.0, 0.7, 0.3, 0.06))
		draw_rect(Rect2(at.x - 3 * u, at.y - 9 * u - flick * u, 6 * u, 7 * u + flick * u), RoomGenesis.FLAME[0])
		draw_rect(Rect2(at.x - 2 * u, at.y - 7 * u, 4 * u, 5 * u), RoomGenesis.FLAME[1])
		draw_rect(Rect2(at.x - u, at.y - 5 * u, 2 * u, 3 * u), RoomGenesis.FLAME[2])
