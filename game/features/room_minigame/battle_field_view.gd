class_name BattleFieldView
extends Control
## สนามรบในห้อง (RoomGame.battle): เวลยืนในวงเวทฝั่งซ้าย ภูตโกลาหลคลานเข้ามาตามทาง บอสยืนขวางทางฝั่งขวา
## วาดด้วยโค้ดทั้งหมด (ยังไม่มีภาพศัตรูใน assets) — ข้อมูลมาจาก RoomGame เสมอ
## เหตุการณ์ (play): banish = แสงวงเวทระเบิดเผาภูต · damage = เวลสั่นแดง · boss_hit = บอสสั่น · boss_down = บอสถล่ม

const VEL_TEXTURE := "res://assets/cutscene/characters/vel/vel_Hblue_Sredyellow_idle.png"
const FONT_BOLD := "res://assets/fonts/ChakraPetch-Bold.ttf"
const CHAOS := Color("b06bff")
const GOLD := Color("ffd36b")
const STONE := Color("4a4458")
const STONE_DARK := Color("2c2836")

var _font: Font
var _vel: TextureRect
var _imps: Array[int] = []
var _max_distance := 4
var _boss: Dictionary = {}
var _boss_hp := 0
var _boss_attack_in := -1
## ผู้เฝ้าประตู (gate): ค่าที่จารึกแล้ว ประตูเปิด และคำถามที่กำลังถาม
var _gate: Dictionary = {}
var _engraved: Dictionary = {}
var _gate_open := 0.0       # บานประตูเลื่อนเปิด 0..1
var _gate_opening := false
var _engrave_glow := {}     # key -> ความสว่างตอนเพิ่งจารึก
var _guard_line := ""
var _guard_line_shown := 0.0
var _time := 0.0
## เอฟเฟกต์ชั่วคราว
var _light := 0.0          # วงแสงจากวงเวท (banish) 0..1
var _boss_flash := 0.0
var _boss_shake := 0.0
var _boss_fall := 0.0      # บอสถล่ม 0..1
var _vel_hurt := 0.0
var _sparks: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = load(FONT_BOLD) if ResourceLoader.exists(FONT_BOLD) else ThemeDB.fallback_font
	_vel = TextureRect.new()
	_vel.texture = load(VEL_TEXTURE) if ResourceLoader.exists(VEL_TEXTURE) else null
	_vel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_vel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_vel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vel)


func update_battle(game: RoomGame) -> void:
	_imps = game.imps.duplicate()
	_max_distance = maxi(int(game.imp_config.get("distance", 4)), 4)
	for distance in _imps:
		_max_distance = maxi(_max_distance, distance)
	_boss = game.boss
	_boss_hp = game.boss_hp
	_boss_attack_in = game.turns_until_boss_attack()
	_gate = game.gate
	_engraved = game.engraved.duplicate()
	if game.gate_open and _gate_open == 0.0:
		_gate_opening = true
	queue_redraw()


func set_guard_line(text: String) -> void:
	if text != _guard_line:
		_guard_line = text
		_guard_line_shown = 0.0


func play(events: Array[Dictionary]) -> void:
	for event in events:
		match str(event["type"]):
			"banish":
				_light = 1.0
				for i in 40:
					var a := randf() * TAU
					_sparks.append({"p": _vel_feet(), "v": Vector2(cos(a), sin(a) * 0.45) * randf_range(120, 420),
							"life": randf_range(0.4, 0.8), "c": GOLD})
			"damage":
				_vel_hurt = 1.0
			"boss_hit":
				_boss_flash = 1.0
				_boss_shake = 1.0
				_burst(_boss_center(), Color("ff9a6b"))
			"engrave":
				_engrave_glow[str(event.get("key", ""))] = 1.0
				_burst(_plaque_center(), GOLD)
			"gate_open":
				_gate_opening = true
				_burst(_plaque_center(), GOLD)
			"boss_down":
				_boss_flash = 1.0
				_boss_fall = 0.001
				_burst(_boss_center(), GOLD)
			"imp_spawn":
				pass


func _burst(at: Vector2, color: Color) -> void:
	for i in 34:
		var a := randf() * TAU
		_sparks.append({"p": at, "v": Vector2(cos(a), sin(a)) * randf_range(80, 300), "life": randf_range(0.4, 0.9), "c": color})


func _process(delta: float) -> void:
	_time += delta
	_light = maxf(0.0, _light - delta * 1.4)
	_boss_flash = maxf(0.0, _boss_flash - delta * 2.5)
	_boss_shake = maxf(0.0, _boss_shake - delta * 3.0)
	if _gate_opening:
		_gate_open = minf(1.0, _gate_open + delta * 0.45)
	for key in _engrave_glow.keys():
		_engrave_glow[key] = maxf(0.0, float(_engrave_glow[key]) - delta * 0.8)
	_guard_line_shown = minf(1.0, _guard_line_shown + delta * 1.2)
	_vel_hurt = maxf(0.0, _vel_hurt - delta * 2.2)
	if _boss_fall > 0.0 and _boss_fall < 1.0:
		_boss_fall = minf(1.0, _boss_fall + delta * 0.9)
	for i in range(_sparks.size() - 1, -1, -1):
		var s: Dictionary = _sparks[i]
		s["p"] += s["v"] * delta
		s["v"] *= 0.93
		s["life"] -= delta
		if s["life"] <= 0.0:
			_sparks.remove_at(i)
	# เวลยืนบนวงเวท สั่นเมื่อโดนโจมตี
	var vel_h := size.y * 0.62
	_vel.size = Vector2(vel_h * 48.0 / 83.0, vel_h)
	_vel.position = Vector2(size.x * 0.1 - _vel.size.x * 0.5 + sin(_time * 60.0) * 6.0 * _vel_hurt,
			_ground_y() - vel_h + sin(_time * 2.0) * 2.0)
	_vel.modulate = Color(1, 1, 1).lerp(Color(1.6, 0.5, 0.5), _vel_hurt)
	queue_redraw()


func _ground_y() -> float:
	return size.y * 0.86


func _vel_feet() -> Vector2:
	return Vector2(size.x * 0.1, _ground_y())


func _lane_x(distance: float) -> float:
	# ช่องที่ 1 ประชิดเวล ช่องไกลสุดอยู่หน้าบอส
	var start := size.x * 0.2
	var end := size.x * (0.66 if not _boss.is_empty() else 0.9)
	return start + (end - start) * (distance - 1.0) / maxf(1.0, _max_distance - 1.0)


func _boss_center() -> Vector2:
	return Vector2(size.x * 0.83, _ground_y() - size.y * 0.36)


func _draw() -> void:
	var ground := _ground_y()
	# ทางเดินหิน + ช่องที่ภูตยืน
	draw_rect(Rect2(0, ground, size.x, size.y - ground), Color(0.1, 0.08, 0.14, 0.9))
	draw_line(Vector2(0, ground), Vector2(size.x, ground), Color(CHAOS, 0.5), 2.0)
	for d in range(1, _max_distance + 1):
		var x := _lane_x(d)
		draw_line(Vector2(x, ground + 4), Vector2(x, ground + 12), Color(1, 1, 1, 0.15), 2.0)
	# วงเวทใต้เท้าเวล (สว่างจ้าเมื่อร่ายแสง)
	var feet := _vel_feet()
	var glow := 0.35 + 0.15 * sin(_time * 3.0) + _light * 0.65
	for r in 3:
		draw_arc(feet, 46.0 + r * 12.0, 0, TAU, 48, Color(GOLD, glow * (0.8 - r * 0.2)), 2.0, true)
	if _light > 0.0:
		var radius := (1.0 - _light) * size.x * 0.75
		draw_arc(feet, radius, -PI * 0.5, PI * 0.5, 64, Color(GOLD, _light), 10.0 * _light + 2.0, true)
	# ภูตโกลาหล
	for index in _imps.size():
		_draw_imp(Vector2(_lane_x(_imps[index]), ground), index)
	if not _gate.is_empty():
		_draw_gate()
	# บอส
	if not _boss.is_empty():
		_draw_boss()
	for s in _sparks:
		var c: Color = s["c"]
		draw_circle(s["p"], 3.0, Color(c, clampf(s["life"] * 1.5, 0.0, 1.0)))


func _draw_imp(at: Vector2, index: int) -> void:
	var k := clampf(size.y / 230.0, 1.0, 1.9)
	var bob := sin(_time * 5.0 + index * 1.7) * 4.0
	var center := at + Vector2(0, -26.0 * k + bob)
	draw_circle(center, 32.0 * k, Color(CHAOS, 0.2))
	# ตัวเป็นหยดมืดมีหนามด้านบน
	var body := PackedVector2Array()
	for i in 18:
		var a := TAU * i / 18.0
		var r := (20.0 + (7.0 if i % 3 == 0 and sin(a) < 0 else 0.0)) * k + sin(_time * 8.0 + i) * 1.5
		body.append(center + Vector2(cos(a), sin(a) * 0.9) * r)
	draw_colored_polygon(body, Color("1a0f24"))
	draw_polyline(body + PackedVector2Array([body[0]]), Color(CHAOS, 0.9), 2.0, true)
	# ตาเรืองแสง (มองไปทางเวล)
	var eye := Color("ff5aa0")
	draw_circle(center + Vector2(-8, -3) * k, 3.5 * k, eye)
	draw_circle(center + Vector2(2, -3) * k, 3.5 * k, eye)
	draw_circle(at + Vector2(0, 2), 14.0 * k, Color(0, 0, 0, 0.35))


func _gate_rect() -> Rect2:
	var h := size.y * 0.74
	var w := minf(size.x * 0.34, h * 0.95)
	return Rect2(size.x * 0.66 - w * 0.5, _ground_y() - h, w, h)


func _plaque_center() -> Vector2:
	var r := _gate_rect()
	return Vector2(r.get_center().x, r.position.y + r.size.y * 0.58)


## ประตูหินโค้ง: ซุ้มก้อนหิน · หน้าผู้เฝ้าบนหินหัวซุ้ม (ตาเรืองแสง กะพริบ) · บานประตูคู่มีแผ่นจารึกนาม/ตราประทับ
## ค่าที่ตั้งด้วย git config ปรากฏเป็นอักษรทองบนแผ่นจารึก · ประตูเปิด = บานเลื่อนออกและแสงสาดออกมา
func _draw_gate() -> void:
	var r := _gate_rect()
	var arch_r := r.size.x * 0.5
	var center_top := Vector2(r.get_center().x, r.position.y + arch_r)
	var inner := r.grow_individual(-r.size.x * 0.12, -r.size.x * 0.12, -r.size.x * 0.12, 0)
	var inner_r := inner.size.x * 0.5
	var inner_top := Vector2(inner.get_center().x, inner.position.y + inner_r)
	# ซุ้มหิน
	draw_circle(center_top, arch_r, STONE)
	draw_rect(Rect2(r.position.x, center_top.y, r.size.x, r.end.y - center_top.y), STONE)
	# ก้อนหินรอบซุ้ม
	for i in 9:
		var a := PI + PI * i / 8.0
		var p1 := center_top + Vector2(cos(a), sin(a)) * inner_r
		var p2 := center_top + Vector2(cos(a), sin(a)) * arch_r
		draw_line(p1, p2, STONE_DARK, 2.0)
	for i in 5:
		var y := center_top.y + (r.end.y - center_top.y) * (i + 1) / 6.0
		draw_line(Vector2(r.position.x, y), Vector2(inner.position.x, y), STONE_DARK, 2.0)
		draw_line(Vector2(inner.end.x, y), Vector2(r.end.x, y), STONE_DARK, 2.0)
	# ช่องประตู: แสงข้างหลัง (เห็นเมื่อเปิด)
	var light := Color(GOLD, 0.15 + 0.75 * _gate_open)
	draw_circle(inner_top, inner_r, light)
	draw_rect(Rect2(inner.position.x, inner_top.y, inner.size.x, inner.end.y - inner_top.y), light)
	# บานประตูคู่ เลื่อนออกด้านข้างเมื่อเปิด
	var leaf_w := inner.size.x * 0.5 * (1.0 - _gate_open)
	var wood := Color("5a3a24")
	var wood_dark := Color("3a2416")
	if leaf_w > 1.0:
		var leaf_top := inner_top.y
		draw_rect(Rect2(inner.position.x, leaf_top, leaf_w, inner.end.y - leaf_top), wood)
		draw_rect(Rect2(inner.end.x - leaf_w, leaf_top, leaf_w, inner.end.y - leaf_top), wood)
		for i in 4:
			var y := leaf_top + (inner.end.y - leaf_top) * (i + 1) / 5.0
			draw_line(Vector2(inner.position.x, y), Vector2(inner.position.x + leaf_w, y), wood_dark, 3.0)
			draw_line(Vector2(inner.end.x - leaf_w, y), Vector2(inner.end.x, y), wood_dark, 3.0)
		# ส่วนโค้งของบาน
		if _gate_open < 0.05:
			draw_circle(inner_top, inner_r, wood)
			draw_line(Vector2(inner_top.x, inner_top.y - inner_r), Vector2(inner_top.x, inner.end.y), wood_dark, 3.0)
	# แผ่นจารึก นาม / ตราประทับ (บนบานประตู — เลือนไปเมื่อเปิด)
	var plaque_alpha := 1.0 - _gate_open
	if plaque_alpha > 0.0:
		var pc := _plaque_center()
		var pw := r.size.x * 1.15
		var ph := 64.0
		var plaque := Rect2(pc.x - pw * 0.5, pc.y - ph * 0.5, pw, ph)
		draw_rect(plaque, Color(Color("2b2233"), 0.92 * plaque_alpha))
		draw_rect(plaque, Color(GOLD, 0.6 * plaque_alpha), false, 2.0)
		var rows := [["user.name", "นาม"], ["user.email", "ตรา"]]
		for i in rows.size():
			var key: String = rows[i][0]
			var has := _engraved.has(key)
			var value := str(_engraved.get(key, "· · · · ·"))
			var glow := float(_engrave_glow.get(key, 0.0))
			var color := GOLD.lerp(Color(1, 1, 1), glow) if has else Color(1, 1, 1, 0.3)
			var y := plaque.position.y + 26 + i * 26
			draw_string(_font, Vector2(plaque.position.x + 10, y), "%s:" % rows[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 0.85, 0.7, 0.8 * plaque_alpha))
			draw_string(_font, Vector2(plaque.position.x + 48, y), value, HORIZONTAL_ALIGNMENT_LEFT, pw - 54, 15, Color(color, color.a * plaque_alpha))
	# หน้าผู้เฝ้าบนหินหัวซุ้ม
	var face := Vector2(center_top.x, r.position.y + arch_r * 0.32)
	draw_circle(face, arch_r * 0.24, STONE.lightened(0.12))
	draw_arc(face, arch_r * 0.24, 0, TAU, 32, STONE_DARK, 2.0, true)
	var blink := 1.0 if fmod(_time, 4.0) > 0.12 else 0.15
	var eye_col := (GOLD if _gate_open > 0.0 else CHAOS.lightened(0.3))
	for side in [-1.0, 1.0]:
		var e: Vector2 = face + Vector2(side * arch_r * 0.09, -arch_r * 0.02)
		draw_rect(Rect2(e - Vector2(5, 4 * blink), Vector2(10, 8 * blink)), eye_col)
	draw_line(face + Vector2(-arch_r * 0.07, arch_r * 0.11), face + Vector2(arch_r * 0.07, arch_r * 0.11), STONE_DARK, 3.0)
	# ชื่อ
	var name := str(_gate.get("name", "ผู้เฝ้าประตู"))
	draw_string(_font, Vector2(r.position.x - 40, r.position.y - 10), name, HORIZONTAL_ALIGNMENT_CENTER, r.size.x + 80, 17, Color(1, 0.9, 0.8))
	# คำถามของผู้เฝ้า (กรอบคำพูดข้างหน้า ชี้ไปทางเวล)
	if not _guard_line.is_empty() and _gate_open == 0.0:
		_draw_guard_bubble(face + Vector2(-arch_r * 0.3, 0))


func _draw_guard_bubble(anchor: Vector2) -> void:
	var text := _guard_line.substr(0, int(ceil(_guard_line.length() * _guard_line_shown)))
	var max_w := size.x * 0.36
	var left := clampf(anchor.x - max_w - 24, size.x * 0.2, size.x)
	var font_size := 15
	var lines := _wrap(text, max_w - 20, font_size)
	var line_h := 20.0
	var box := Rect2(left, anchor.y - 18, max_w, 14 + lines.size() * line_h)
	draw_rect(box, Color("f6ead0"))
	draw_rect(box, Color("8a5a2b"), false, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(box.end.x - 2, anchor.y - 6), Vector2(anchor.x, anchor.y), Vector2(box.end.x - 2, anchor.y + 8)]), Color("f6ead0"))
	for i in lines.size():
		draw_string(_font, Vector2(box.position.x + 10, box.position.y + 20 + i * line_h), lines[i], HORIZONTAL_ALIGNMENT_LEFT, max_w - 20, font_size, Color("3a2614"))


## ตัดบรรทัดตามความกว้าง (ภาษาไทยไม่มีช่องว่าง จึงตัดทีละตัวอักษรเมื่อจำเป็น)
func _wrap(text: String, width: float, font_size: int) -> PackedStringArray:
	var lines := PackedStringArray()
	var current := ""
	for ch in text:
		if _font.get_string_size(current + ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width and not current.is_empty():
			var cut := current.rfind(" ")
			if cut > 0:
				lines.append(current.substr(0, cut))
				current = current.substr(cut + 1)
			else:
				lines.append(current)
				current = ""
		current += ch
	if not current.is_empty():
		lines.append(current)
	return lines


func _draw_boss() -> void:
	var c := _boss_center() + Vector2(sin(_time * 70.0) * 10.0 * _boss_shake, 0)
	var h := size.y * 0.62
	var w := size.x * 0.17
	if _boss_fall >= 1.0:
		return
	var fall := _boss_fall
	var alpha := 1.0 - fall
	c.y += fall * h * 0.5
	# ประตูหินมีชีวิต: บานประตูโค้ง + กำปั้น + ตาอักขระ
	var top := c.y - h * 0.5
	var rect := Rect2(c.x - w * 0.5, top + w * 0.5, w, h - w * 0.5)
	var stone := STONE.lerp(Color("ff8a6b"), _boss_flash * 0.6)
	draw_rect(rect, Color(stone, alpha))
	draw_circle(Vector2(c.x, top + w * 0.5), w * 0.5, Color(stone, alpha))
	draw_rect(Rect2(c.x - w * 0.32, top + w * 0.62, w * 0.64, h * 0.58), Color(STONE_DARK, alpha))
	for i in 4:
		var y := top + w * 0.7 + i * h * 0.13
		draw_line(Vector2(c.x - w * 0.32, y), Vector2(c.x + w * 0.32, y), Color(0, 0, 0, 0.35 * alpha), 2.0)
	# ตาเรืองแสงสีม่วง (แรงขึ้นเมื่อใกล้โจมตี)
	var rage := 1.0 if _boss_attack_in == 1 else 0.55
	var eye := Color(CHAOS.lightened(0.3), alpha)
	draw_circle(Vector2(c.x - w * 0.18, top + w * 0.42), 7.0 + rage * 3.0 * (0.5 + 0.5 * sin(_time * 6.0)), eye)
	draw_circle(Vector2(c.x + w * 0.18, top + w * 0.42), 7.0 + rage * 3.0 * (0.5 + 0.5 * sin(_time * 6.0)), eye)
	# กำปั้นหิน
	var fist_lift := (sin(_time * 3.0) * 6.0) + (24.0 if _boss_attack_in == 1 else 0.0)
	draw_circle(Vector2(rect.position.x - 16, c.y + h * 0.12 - fist_lift), w * 0.16, Color(stone.darkened(0.15), alpha))
	draw_circle(Vector2(rect.end.x + 16, c.y + h * 0.12 - fist_lift), w * 0.16, Color(stone.darkened(0.15), alpha))
	# ชื่อ + แถบพลัง + จังหวะโจมตี
	var name := str(_boss.get("name", "บอส"))
	var max_hp := maxi(1, int(_boss.get("hp", 1)))
	var bar_w := w * 1.5
	var bar := Rect2(c.x - bar_w * 0.5, top - 22, bar_w, 12)
	draw_string(_font, Vector2(bar.position.x, bar.position.y - 8), name, HORIZONTAL_ALIGNMENT_CENTER, bar_w, 17, Color(1, 0.9, 0.8, alpha))
	draw_rect(bar, Color(0, 0, 0, 0.6 * alpha))
	draw_rect(Rect2(bar.position, Vector2(bar_w * _boss_hp / max_hp, bar.size.y)), Color(Color("ff5a7a"), alpha))
	for i in range(1, max_hp):
		var x := bar.position.x + bar_w * i / max_hp
		draw_line(Vector2(x, bar.position.y), Vector2(x, bar.end.y), Color(0, 0, 0, 0.8 * alpha), 2.0)
	if _boss_attack_in > 0 and fall == 0.0:
		var warn := "โจมตีในอีก %d การกระทำ" % _boss_attack_in if _boss_attack_in > 1 else "กำลังจะฟาด!"
		var warn_color := Color("ffb3c4") if _boss_attack_in == 1 else Color(1, 1, 1, 0.7)
		draw_string(_font, Vector2(bar.position.x - 30, bar.position.y - 30), warn, HORIZONTAL_ALIGNMENT_CENTER, bar_w + 60, 15, warn_color)
