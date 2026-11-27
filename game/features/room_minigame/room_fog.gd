class_name RoomFog
extends Control
## หมอกมืดของห้องที่ "มองไม่เห็น" (blind — ด่าน 3) ปกคลุมผ้าปู แท่น และคัมภีร์จนกว่าจะร่าย git status
## ก้อนหมอกพิกเซลลอยเอื่อย ๆ มีเครื่องหมาย ? กะพริบ — พอหยั่งสถานะ หมอกถูกแสงตะเกียงกวาดหายจากซ้ายไปขวา
## ไม่รับเมาส์: ผู้เล่นยังคลิกหยิบกระดาษในหมอกขึ้นมาอ่านได้

const FOG := Color("140f24")

var _time := 0.0
var _clear := 0.0     # 0 = หมอกเต็ม · 1 = ถูกกวาดหายหมดแล้ว
var _revealing := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func reveal() -> void:
	if _revealing or not visible:
		return
	_revealing = true
	var tw := create_tween()
	tw.tween_property(self, "_clear", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void: visible = false)


func cover() -> void:
	_revealing = false
	_clear = 0.0
	visible = true


func _process(delta: float) -> void:
	if visible:
		_time += delta
		queue_redraw()


func _draw() -> void:
	var edge := size.x * _clear
	var cell := maxf(6.0, round(size.y / 40.0))
	var cols := int(size.x / cell) + 1
	var rows := int(size.y / cell) + 1
	for cy in rows:
		for cx in cols:
			var x := cx * cell
			if x < edge:
				continue
			var y := cy * cell
			# ความหนาแน่นหมอกแบบคลื่นซ้อน (เลื่อนช้า ๆ) ตัดเป็นขั้น ไม่ไล่สีเรียบ
			var n := sin(cx * 0.45 + _time * 0.6) + sin(cy * 0.7 - _time * 0.4) + sin((cx + cy) * 0.3 + _time * 0.25)
			var a := 0.62 if n > 0.6 else (0.52 if n > -0.4 else 0.44)
			if x - edge < cell * 3.0:
				a *= (x - edge) / (cell * 3.0) # ขอบที่แสงกำลังกวาดบางลง
			draw_rect(Rect2(x, y, cell, cell), Color(FOG, a))
	if _clear <= 0.0:
		var font := ThemeDB.fallback_font
		for i in 5:
			var phase := _time * 0.8 + i * 1.7
			var on := fmod(phase, 2.0) < 1.2
			if not on:
				continue
			var p := Vector2(size.x * (0.12 + 0.19 * i), size.y * (0.35 + 0.25 * sin(phase * 0.7)))
			draw_string(font, p, "?", HORIZONTAL_ALIGNMENT_CENTER, -1, int(cell * 3.0), Color(0.75, 0.7, 1.0, 0.35))
