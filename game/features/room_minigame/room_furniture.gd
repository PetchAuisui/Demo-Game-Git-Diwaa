class_name RoomFurniture
extends Control
## เฟอร์นิเจอร์ pixel art ด้านล่างของแต่ละโซนในห้อง (วาดหลังรายการของ): โต๊ะเขียน · แท่นเตรียม · แท่นวางคัมภีร์
## ทำให้ห้องเป็น "สถานที่" แทนกล่องข้อความ และเป็นเวทีของคาถาหลักแต่ละด่าน:
##   แท่นวางคัมภีร์ว่างเปล่าจนกว่าจะมีคัมภีร์ (git init / clone) → คัมภีร์ร่วงลงมาประทับ · จำนวนหน้า = จำนวนการจารึก
##   แท่นเตรียมเรืองตามจำนวนของบนแท่น · มีโดมโล่ของมิวราเมื่อแท่นปกป้องของได้ (safe = staged)
## วาดด้วยสี่เหลี่ยมพิกเซลขนาดเท่ากันทั้งหมด (หน่วย _u) — ไม่มีการไล่สี ไม่ใช้ z_index

enum Kind { DESK, ALTAR, PEDESTAL }

const TOME_TEXTURE := "res://assets/cutscene/props/khampri/Khampri.png"
const FONT_BOLD := "res://assets/fonts/ChakraPetch-Bold.ttf"
const WOOD := [Color("2a170e"), Color("3b2416"), Color("5a3820"), Color("7a4e2c"), Color("9c6a3c")]
const STONE := [Color("1e1b2e"), Color("2c2842"), Color("3e3a5a"), Color("565078"), Color("7a74a0")]
const RUNE := Color("7af0d4")
const GOLD := Color("ffd36b")

var kind := Kind.DESK
var staged := 0
var shield := false
var has_tome := false
var pages := 0
var max_pages := 0
var tint := GOLD            # สีเรืองของคัมภีร์ (เปลี่ยนตามมิติ)

var _font: Font
var _tome: Texture2D
var _time := 0.0
var _born := 1.0            # 0 → 1 ระหว่างคัมภีร์ร่วงลงมาประทับ (1 = อยู่บนแท่นแล้ว)
var _flip := 0.0            # คัมภีร์เด้งตอนถูกจารึกหน้าใหม่
var _pulse := 0.0           # แท่นเตรียมสว่างวาบตอนมีของขึ้นแท่น
var _page_pop := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = load(FONT_BOLD) if ResourceLoader.exists(FONT_BOLD) else ThemeDB.fallback_font
	_tome = load(TOME_TEXTURE) if ResourceLoader.exists(TOME_TEXTURE) else null


func _u() -> float:
	return maxf(1.0, round(size.y / 110.0))


## จุดฐานกลางของเฟอร์นิเจอร์ (พิกัดของ control นี้)
func base() -> Vector2:
	return Vector2(round(size.x * 0.5), size.y - 4.0)


## ตำแหน่งบนสุดของเฟอร์นิเจอร์ที่ของ/คัมภีร์วางอยู่ (พิกัด global) — ใช้เป็นเป้าของเอฟเฟกต์
func top_global() -> Vector2:
	var u := _u()
	var y := -34.0 if kind == Kind.PEDESTAL else (-24.0 if kind == Kind.ALTAR else -22.0)
	return global_position + base() + Vector2(0, y * u)


func tome_global() -> Vector2:
	return top_global() + Vector2(0, -14.0 * _u())


## git init / clone: คัมภีร์ร่วงจากฟ้าลงมาประทับบนแท่น
func tome_born() -> void:
	has_tome = true
	_born = 0.0


## จารึกหน้าใหม่: คัมภีร์เด้ง หน้าใหม่ป๊อปขึ้น
func page_written() -> void:
	_flip = 1.0
	_page_pop = 1.0


func altar_pulse() -> void:
	_pulse = 1.0


func _process(delta: float) -> void:
	_time += delta
	if _born < 1.0:
		_born = minf(1.0, _born + delta / 0.55)
	_flip = maxf(0.0, _flip - delta * 2.5)
	_pulse = maxf(0.0, _pulse - delta * 1.6)
	_page_pop = maxf(0.0, _page_pop - delta * 1.2)
	queue_redraw()


func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	var u := _u()
	var b := base()
	draw_rect(Rect2(b.x + x * u, b.y + y * u, w * u, h * u), c)


func _draw() -> void:
	match kind:
		Kind.DESK:
			_draw_desk()
		Kind.ALTAR:
			_draw_altar()
		Kind.PEDESTAL:
			_draw_pedestal()


func _draw_desk() -> void:
	_px(-36, -1, 72, 2, Color(0, 0, 0, 0.35)) # เงา
	for leg: int in [-31, 27]:
		_px(leg, -18, 4, 18, WOOD[1])
		_px(leg, -18, 1, 18, WOOD[2])
	_px(-36, -23, 72, 5, WOOD[3])
	_px(-36, -23, 72, 1, WOOD[4])
	_px(-36, -19, 72, 1, WOOD[1])
	for seam: int in [-20, 2, 20]:
		_px(seam, -22, 1, 3, WOOD[2])
	_px(-15, -17, 30, 8, WOOD[2])
	_px(-15, -17, 30, 1, WOOD[3])
	_px(-1, -14, 3, 2, Color("d9a650"))
	# ขวดหมึกกับขนนก
	_px(-29, -27, 6, 4, Color("1c1530"))
	_px(-28, -28, 4, 1, Color("2e2648"))
	_px(-25, -34, 1, 7, Color("e8e8f0"))
	_px(-24, -36, 1, 3, Color("cfd4ea"))
	# เทียน: เปลวไฟสั่นไหวและแสงรอบ ๆ
	_px(24, -31, 4, 8, Color("e8dcc0"))
	_px(24, -31, 1, 8, Color("fff6e0"))
	var flick := 1.0 if fmod(_time * 7.0, 1.0) > 0.5 else 0.0
	_px(23, -40, 6, 6, Color(1.0, 0.75, 0.3, 0.12))
	_px(25, -35 - flick, 2, 4 + flick, Color("ff8c3a"))
	_px(25, -34, 2, 2, Color("ffe07a"))


func _draw_altar() -> void:
	var glow := clampf(staged / 3.0, 0.0, 1.0) * 0.8 + _pulse * 0.6
	if glow > 0.02:
		# แสงลอยขึ้นจากแผ่นแท่น (ยิ่งของบนแท่นมากยิ่งสว่าง)
		for i in 5:
			var h := 18.0 + 10.0 * sin(_time * 2.0 + i)
			_px(-16 + i * 8, -24 - h, 2, h, Color(RUNE, 0.08 * glow + 0.04 * glow * sin(_time * 4.0 + i)))
	_px(-32, -1, 64, 2, Color(0, 0, 0, 0.35))
	_px(-30, -6, 60, 6, STONE[1])
	_px(-30, -6, 60, 1, STONE[3])
	_px(-24, -20, 48, 14, STONE[2])
	_px(14, -20, 10, 14, STONE[1])
	_px(-24, -20, 1, 14, STONE[3])
	_px(-28, -24, 56, 4, STONE[3])
	_px(-28, -24, 56, 1, STONE[4])
	# อักษรรูนสามตัวบนหน้าแท่น ติดตามจำนวนของบนแท่น
	for i in 3:
		var lit := i < staged or _pulse > 0.3
		var c := Color(RUNE, 0.95) if lit else Color("2a3a48")
		var x := -14 + i * 11
		_px(x, -16, 2, 7, c)
		_px(x + 2, -14, 2, 1, c)
		_px(x + 2, -11, 3, 1, c)
		if lit:
			_px(x - 1, -17, 5, 9, Color(RUNE, 0.12))
	if shield:
		_draw_dome()


## โดมโล่ของมิวรา: วงรีพิกเซลประกายวิ่งรอบ — ของบนแท่นรอดจากคลื่น
func _draw_dome() -> void:
	var cx := 0.0
	var cy := -24.0
	var rx := 38.0
	var ry := 40.0
	var steps := 64
	for i in steps:
		var a := PI + PI * float(i) / steps
		var x := roundf(cx + cos(a) * rx)
		var y := roundf(cy + sin(a) * ry)
		var band := 0.5 + 0.5 * sin(a * 3.0 - _time * 3.0)
		_px(x, y, 1, 1, Color(Color("8fd3ff"), 0.25 + 0.55 * band))
	_px(-rx, cy, rx * 2.0, 1, Color(Color("8fd3ff"), 0.35))


func _draw_pedestal() -> void:
	var t := tint
	if has_tome and _born >= 1.0:
		# ประกายเล็ก ๆ วนรอบคัมภีร์ (กะพริบเป็นจังหวะ ไม่ใช่กล่องแสง)
		for i in 3:
			var a := _time * 1.4 + i * TAU / 3.0
			var on := fmod(_time * 2.0 + i * 0.37, 1.0) > 0.4
			if on or _flip > 0.0:
				var sx := roundf(cos(a) * 17.0)
				var sy := roundf(-48.0 + sin(a) * 9.0)
				_px(sx, sy, 1, 1, Color(t, 0.9))
				_px(sx - 1, sy, 3, 1, Color(t, 0.35))
				_px(sx, sy - 1, 1, 3, Color(t, 0.35))
	_px(-20, -1, 40, 2, Color(0, 0, 0, 0.35))
	_px(-17, -6, 34, 6, STONE[1])
	_px(-17, -6, 34, 1, STONE[3])
	_px(-10, -30, 20, 24, STONE[2])
	_px(5, -30, 5, 24, STONE[1])
	for flute: int in [-6, -1]:
		_px(flute, -28, 1, 20, STONE[1])
	_px(-16, -34, 32, 4, STONE[3])
	_px(-16, -34, 32, 1, STONE[4])
	if has_tome and _tome != null:
		_draw_tome()
	elif not has_tome:
		# ยังไม่มีคัมภีร์: เงาโครงหนังสือกะพริบ รอให้ถูกสร้าง
		var a := 0.18 + 0.14 * sin(_time * 3.0)
		var c := Color(1, 1, 1, a)
		for i in range(-10, 11, 3):
			_px(i, -58, 2, 1, c)
			_px(i, -36, 2, 1, c)
		for j in range(-58, -35, 3):
			_px(-11, j, 1, 2, c)
			_px(10, j, 1, 2, c)
		_text("?", Vector2(0, -44), 22, Color(1, 1, 1, a + 0.1))
	if pages > 0 or max_pages > 0:
		var label := "หน้า %d" % pages if max_pages <= 0 else "หน้า %d/%d" % [pages, max_pages]
		var over := max_pages > 0 and pages > max_pages
		var color := Color("ff7b7b") if over else GOLD
		var pop := 1.0 + 0.5 * _page_pop
		_text(label, Vector2(0, -17), int(13 * pop), color)


func _draw_tome() -> void:
	var u := _u()
	var b := base()
	var h := 26.0 * u
	var w := h * 155.0 / 166.0
	var bob := sin(_time * 2.0) * u
	var fall := (1.0 - ease(_born, 2.6)) * size.y * 0.9
	var squash := 0.0
	if _born >= 1.0 and _flip > 0.0:
		squash = sin(_flip * PI) * 0.25
	var landing := 1.0 - _born
	var sx := w * (1.0 + squash)
	var sy := h * (1.0 - squash)
	var bottom := b.y - 34.0 * u - 2.0 * u + bob - fall - _flip * 6.0 * u
	var rect := Rect2(b.x - sx * 0.5, bottom - sy, sx, sy)
	draw_texture_rect(_tome, rect, false, Color(1, 1, 1, clampf(_born * 3.0, 0.0, 1.0)))
	if landing > 0.0 and _born > 0.9:
		_px(-20, -36, 40, 2, Color(GOLD, 0.8))


func _text(text: String, at: Vector2, font_size: int, color: Color) -> void:
	var u := _u()
	var p := base() + at * u
	var width := 120.0
	draw_string_outline(_font, Vector2(p.x - width * 0.5, p.y), text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, 4, Color(0, 0, 0, 0.85))
	draw_string(_font, Vector2(p.x - width * 0.5, p.y), text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)
