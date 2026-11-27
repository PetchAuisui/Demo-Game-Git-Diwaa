class_name RoomFurniture
extends Control
## เฟอร์นิเจอร์ pixel art ด้านล่างของแต่ละโซนในห้อง (วาดหลังรายการของ): ผ้าปูเวท · แท่นเตรียม · แท่นวางคัมภีร์
## ทำให้ห้องเป็น "สถานที่" แทนกล่องข้อความ และเป็นเวทีของคาถาหลักแต่ละด่าน:
##   ผ้าปูเวท (Kind.DESK = working tree) เป็นของที่เวลพกติดตัวขึ้นทุกชั้น: ก่อนมีคัมภีร์ยังม้วนมัดเชือกอยู่ แล้วคลี่ออกเมื่อห้องตื่น
##   แท่นเตรียมกับแท่นวางคัมภีร์เป็นหินของหอคอยเอง (มีทุกชั้น)
##   แท่นวางคัมภีร์ว่างเปล่าจนกว่าจะมีคัมภีร์ (git init / clone) → คัมภีร์ร่วงลงมาประทับ · จำนวนหน้า = จำนวนการจารึก
##   แท่นเตรียมเรืองตามจำนวนของบนแท่น · มีโดมโล่ของมิวราเมื่อแท่นปกป้องของได้ (safe = staged)
##   ห้องที่ยังไม่มีคัมภีร์ (ก่อน git init) หลับใหล: สีซีดเทา ผ้าปูยังม้วนอยู่ ตะเกียงดับมีควัน รูนดับ หยากไย่กับฝุ่นจับแท่นหิน
##   แล้วตื่นขึ้นทีละชิ้นเมื่อคลื่นแสงของคาถาผ่าน (wake)
## วาดด้วยสี่เหลี่ยมพิกเซลขนาดเท่ากันทั้งหมด (หน่วย _u) — ไม่มีการไล่สี ไม่ใช้ z_index

enum Kind { DESK, ALTAR, PEDESTAL }

const TOME_TEXTURE := "res://assets/cutscene/props/khampri/Khampri.png"
const FONT_BOLD := "res://assets/fonts/ChakraPetch-Bold.ttf"
const WOOD := [Color("2a170e"), Color("3b2416"), Color("5a3820"), Color("7a4e2c"), Color("9c6a3c")]
const STONE := [Color("1e1b2e"), Color("2c2842"), Color("3e3a5a"), Color("565078"), Color("7a74a0")]
const RUNE := Color("7af0d4")
const GOLD := Color("ffd36b")
const BRASS := [Color("8a6a2c"), Color("b08a3c"), Color("d9b45a")]
const CLOTH := [Color("2e0f1c"), Color("4a1828"), Color("6a2238"), Color("86304a")]
const LEATHER := [Color("3e2616"), Color("5c3a22"), Color("7a5232")]
const ROPE := Color("b89a68")
const MAT_ROWS := 16          # แถวพิกเซลของผ้าปู (จากขอบหลังถึงขอบหน้า)
const MAT_BACK := -19         # y ของขอบหลังผ้าปู
const MAT_MID := -11          # y กลางผืน (ที่วงอักขระปักอยู่ และจุดที่เอฟเฟกต์ลงบนผ้าปู)

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
var _material: ShaderMaterial
var _wake_flash := 0.0
var _unroll := 1.0          # ผ้าปู: 0 = ม้วนมัดเชือก · 1 = คลี่ปูเต็มผืน
var _unrolling := false
const DORMANT_SHADER := """
shader_type canvas_item;
uniform float awake = 1.0;
void fragment() {
	vec4 c = COLOR;
	float grey = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	vec3 dead = vec3(grey) * vec3(0.55, 0.53, 0.6);
	COLOR = vec4(mix(dead, c.rgb, awake), c.a);
}
"""
## คลื่นลูกหน้ามาในการกระทำถัดไปและมีของเสี่ยงอยู่บนเฟอร์นิเจอร์นี้ → สั่นกึก ๆ
var urgent := false
## ห้องเพิ่งปรากฏและคัมภีร์ยังไม่ร่วงลงมา — ไม่วาดคัมภีร์จนกว่า tome_born() จะเรียก
var hold_tome := false
## 0 = หลับใหล (ห้องก่อนมีคัมภีร์) · 1 = มีชีวิต — สีซีด/ตะเกียง/ผ้าปูม้วน/รูน/หยากไย่ ไล่ตามค่านี้
var awake := 1.0:
	set(value):
		awake = value
		if not _unrolling:
			_unroll = 1.0 if awake >= 1.0 else (0.0 if awake <= 0.0 else _unroll)
		if _material != null:
			_material.set_shader_parameter("awake", awake)
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = DORMANT_SHADER
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("awake", awake)
	material = _material
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
	var y := -34.0 if kind == Kind.PEDESTAL else (-24.0 if kind == Kind.ALTAR else float(MAT_MID))
	return global_position + base() + Vector2(0, y * u)


func tome_global() -> Vector2:
	return top_global() + Vector2(0, -14.0 * _u())


## git init / clone: คัมภีร์ร่วงจากฟ้าลงมาประทับบนแท่น
func tome_born() -> void:
	has_tome = true
	hold_tome = false
	_born = 0.0


## จารึกหน้าใหม่: คัมภีร์เด้ง หน้าใหม่ป๊อปขึ้น
func page_written() -> void:
	_flip = 1.0
	_page_pop = 1.0


## คลื่นแสงผ่าน: ฝุ่นกับหยากไย่ปลิวหาย สีกลับมา แล้วสิ่งที่มีชีวิตเริ่มขยับ (ตะเกียงติด รูนเรือง)
## ผ้าปูเวท: เชือกหลุด ม้วนผ้ากลิ้งคลี่ออกมาเป็นผืน
func wake(seconds: float = 0.35) -> void:
	_wake_flash = 1.0
	var tw := create_tween()
	tw.tween_property(self, "awake", 1.0, seconds).set_trans(Tween.TRANS_SINE)
	if kind == Kind.DESK and _unroll < 1.0:
		_unrolling = true
		var roll := create_tween()
		roll.tween_property(self, "_unroll", 1.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		roll.tween_callback(func() -> void: _unrolling = false)


func altar_pulse() -> void:
	_pulse = 1.0


func _process(delta: float) -> void:
	_time += delta
	if _born < 1.0:
		_born = minf(1.0, _born + delta / 0.3)
	_flip = maxf(0.0, _flip - delta * 2.5)
	_pulse = maxf(0.0, _pulse - delta * 1.6)
	_page_pop = maxf(0.0, _page_pop - delta * 1.2)
	_wake_flash = maxf(0.0, _wake_flash - delta * 2.5)
	queue_redraw()


func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	var u := _u()
	var b := base()
	draw_rect(Rect2(b.x + x * u, b.y + y * u, w * u, h * u), c)


func _draw() -> void:
	if urgent and kind != Kind.PEDESTAL and awake >= 1.0:
		draw_set_transform(Vector2((1.0 if fmod(_time * 24.0, 1.0) > 0.5 else -1.0) * _u(), 0.0))
	match kind:
		Kind.DESK:
			_draw_mat()
		Kind.ALTAR:
			_draw_altar()
		Kind.PEDESTAL:
			_draw_pedestal()
	draw_set_transform(Vector2.ZERO)
	if awake < 1.0 and kind != Kind.DESK:
		_draw_neglect(1.0 - awake) # ผ้าปูเป็นของที่เวลเพิ่งนำมา ไม่มีฝุ่นจับ
	if _wake_flash > 0.0:
		var top := -20.0 if kind == Kind.DESK else -40.0
		_px(-40, top, 80, -top, Color(1.0, 0.9, 0.6, 0.18 * _wake_flash))


## ฝุ่นจับและหยากไย่ (ห้องที่หลับใหล) — จางหายเมื่อห้องตื่น
func _draw_neglect(amount: float) -> void:
	var web := Color(0.85, 0.85, 0.9, 0.35 * amount)
	var top := -34.0 if kind == Kind.PEDESTAL else -24.0
	var half := 28.0 if kind == Kind.ALTAR else 16.0
	for i in 6:
		_px(half - 1 - i, top + i * 2 - 10, 1, 2, web) # เส้นใยเฉียงจากมุมขวาบน
		_px(half - 1 - i * 2, top - 10, 2, 1, Color(web, web.a * 0.6))
	for i in 5:
		_px(-half + i * 2, top - 8 + i, 1, 1, web)
	var dust := Color(0.75, 0.72, 0.7, 0.4 * amount)
	for i in 7:
		_px(-half + 4 + i * (half * 2 - 8) / 7.0, top, 2, 1, dust)


## ผ้าปูเวท: ผ้าทอสีเลือดหมูขลิบทอง ปูบนพื้นหินแบบมองจากด้านหน้าเฉียงบน (ขอบหลังแคบกว่าขอบหน้า)
## กลางผืนปักวงอักขระที่เรืองแสงเบา ๆ · ขอบหน้ามีพู่ทองไหวตามลม
## ย่ามหนังวางมุมหน้าซ้าย ตะเกียงทองเหลืองวางมุมหน้าขวา (ของติดตัวเวล)
func _draw_mat() -> void:
	var f := clampf(_unroll, 0.0, 1.0)
	# แถวแรกที่คลี่แล้ว (นับจากขอบหลัง): ม้วนผ้าเริ่มที่ขอบหน้าแล้วกลิ้งออกไปทางขอบหลัง
	var first := roundi((1.0 - f) * (MAT_ROWS - 1))
	if f > 0.0:
		for r in range(first, MAT_ROWS):
			var y := MAT_BACK + r
			var half := _mat_half(r)
			_px(-half, y, half * 2, 1, CLOTH[1] if r == 0 else CLOTH[2])
			_px(-half, y, 1, 1, CLOTH[1])
			_px(half - 1, y, 1, 1, CLOTH[1])
			if r >= 1 and r <= MAT_ROWS - 2:
				# ขลิบทองด้านข้าง
				_px(-half + 2, y, 1, 1, BRASS[0])
				_px(half - 3, y, 1, 1, BRASS[0])
			if r == 1 or r == MAT_ROWS - 2:
				# ขลิบทองขอบหลัง/หน้า ปักเป็นจุดสลับ
				var x := -half + 2
				while x <= half - 3:
					_px(x, y, 1, 1, BRASS[1] if (x + r) % 3 != 0 else BRASS[0])
					x += 1
		var front := MAT_BACK + MAT_ROWS
		var front_half := _mat_half(MAT_ROWS - 1)
		_px(-front_half, front, front_half * 2, 1, CLOTH[0]) # ชายผ้าพับลงหาพื้น
		var sway := 1 if fmod(_time * 1.3, 2.0) > 1.0 and awake >= 1.0 else 0
		var tx := -front_half + 3
		var i := 0
		while tx < front_half - 2:
			_px(tx + (sway if i % 2 == 0 else 0), front + 1, 1, 2, BRASS[1])
			tx += 6
			i += 1
	if f >= 1.0:
		_draw_mat_sigil()
	else:
		_draw_mat_roll(f, first)
	_draw_satchel()
	_draw_lantern()


## ความกว้างครึ่งผืนของแถวที่ r (ขอบหลังแคบ ขอบหน้ากว้าง ให้ดูเป็นพื้นที่ทอดไปข้างหลัง)
func _mat_half(r: int) -> int:
	return roundi(lerpf(27.0, 38.0, float(r) / (MAT_ROWS - 1)))


## วงอักขระปักกลางผืน: วงรีทองหม่น ดาวสี่แฉกตรงกลาง เรืองขึ้นลงช้า ๆ
func _draw_mat_sigil() -> void:
	var cy := float(MAT_MID)
	var glow := 0.55 + 0.25 * sin(_time * 1.6) * awake
	var thread := Color(BRASS[2], glow)
	var steps := 40
	for i in steps:
		var a := TAU * float(i) / steps
		_px(roundf(cos(a) * 14.0), roundf(cy + sin(a) * 4.5), 1, 1, thread)
	_px(0, cy - 3, 1, 7, thread)
	_px(-3, cy, 7, 1, thread)
	_px(-1, cy - 1, 3, 3, Color(BRASS[2], glow * 0.5))
	for side: int in [-1, 1]:
		_px(side * 8, cy, 1, 1, Color(BRASS[2], glow * 0.7))
		_px(side * 4, cy + side * 3, 1, 1, Color(BRASS[2], glow * 0.5))


## ผ้าปูที่ยังม้วนอยู่: ม้วนวางพื้นระหว่างย่ามกับตะเกียง แล้วกลิ้งออกไปทางขอบหลัง (ยิ่งคลี่ยิ่งเล็ก)
## ก่อนคลี่มีเชือกมัดสองเปลาะ
func _draw_mat_roll(f: float, row: int) -> void:
	var d := roundi(lerpf(5.0, 2.0, f))
	var bottom := MAT_BACK + row
	var half := _mat_half(row) - 1
	var top := bottom - d + 1
	_px(-half, top, half * 2, d, CLOTH[2])
	_px(-half, top, half * 2, 1, CLOTH[3])
	_px(-half, bottom, half * 2, 1, CLOTH[1])
	for side: int in [-1, 1]:
		# ปลายม้วน: วงก้นหอยเห็นชั้นผ้า
		var ex := -half - 1 if side < 0 else half
		_px(ex, top, 1, d, CLOTH[1])
		if d >= 3:
			_px(ex, top + 1, 1, d - 2, CLOTH[3])
	if f <= 0.0:
		for cord: int in [-14, 13]:
			_px(cord, top - 1, 1, d + 1, ROPE)
			_px(cord + 1, top, 1, d - 1, ROPE.darkened(0.3))


## ย่ามหนังของเวล: ทรงมนมีฝาพับปลายโค้ง หัวเข็มขัดทองเหลือง สายสะพายโค้งอยู่ข้างบน ม้วนกระดาษโผล่จากปาก
func _draw_satchel() -> void:
	var x := -40
	_px(x + 9, -13, 2, 3, Color("e8dcc0"))
	_px(x + 2, -15, 1, 5, LEATHER[0])
	_px(x + 3, -16, 7, 1, LEATHER[0])
	_px(x + 10, -15, 1, 5, LEATHER[0])
	_px(x + 1, -10, 11, 8, LEATHER[1])
	_px(x, -9, 13, 6, LEATHER[1])
	_px(x + 12, -9, 1, 6, LEATHER[0])
	_px(x + 1, -3, 11, 1, LEATHER[0])
	_px(x + 1, -10, 11, 4, LEATHER[2])
	_px(x, -9, 1, 3, LEATHER[2])
	_px(x + 3, -6, 7, 1, LEATHER[2])
	_px(x + 1, -6, 2, 1, LEATHER[0])
	_px(x + 10, -6, 2, 1, LEATHER[0])
	_px(x + 3, -5, 7, 1, LEATHER[0])
	_px(x + 1, -10, 11, 1, Color(LEATHER[2].lightened(0.2)))
	_px(x + 5, -7, 3, 2, BRASS[1])
	_px(x + 6, -7, 1, 1, BRASS[0])


## ตะเกียงทองเหลือง: เปลวไฟในโคมแก้วสั่นไหว ส่องแสงอุ่นลงบนผ้า · ห้องหลับ = ตะเกียงดับมีควันลอย
func _draw_lantern() -> void:
	var x := 30
	var lit := awake >= 0.5
	var flame := clampf((awake - 0.5) * 2.0, 0.0, 1.0)
	_px(x + 1, -17, 3, 1, BRASS[0])
	_px(x, -16, 1, 2, BRASS[0])
	_px(x + 4, -16, 1, 2, BRASS[0])
	_px(x - 1, -14, 7, 1, BRASS[1])
	_px(x, -13, 5, 8, Color(1.0, 0.85, 0.55, 0.28 * flame) if lit else Color(0.2, 0.2, 0.25, 0.6))
	_px(x, -13, 1, 8, BRASS[0])
	_px(x + 4, -13, 1, 8, BRASS[0])
	_px(x - 1, -5, 7, 2, BRASS[0])
	_px(x - 1, -5, 7, 1, BRASS[1])
	if lit:
		var flick := 1.0 if fmod(_time * 7.0, 1.0) > 0.5 else 0.0
		_px(x + 2, -10 - flick, 1, 3 + flick, Color(Color("ff8c3a"), flame))
		_px(x + 2, -8, 1, 1, Color(Color("ffe07a"), flame))
	else:
		for i in 4:
			var t := fmod(_time * 0.6 + i * 0.25, 1.0)
			var sx := roundf(sin(t * 9.0 + i) * 1.5)
			_px(x + 2 + sx, -18 - t * 10.0, 1, 1, Color(0.7, 0.7, 0.75, 0.4 * (1.0 - t)))


func _draw_altar() -> void:
	var glow := (clampf(staged / 3.0, 0.0, 1.0) * 0.8 + _pulse * 0.6) * awake
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
		var lit := (i < staged or _pulse > 0.3) and awake >= 1.0
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
	if has_tome and not hold_tome and _tome != null:
		_draw_tome()
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
