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
	queue_redraw()


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
