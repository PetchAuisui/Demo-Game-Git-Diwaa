@tool
extends Control

## Act Divider Walls & Environmental Architecture
## สถาปัตยกรรมโกธิคระบุจุดเปลี่ยนผ่านระหว่างบท (Act Transitions) และสิ่งแวดล้อมหอคอยโบราณ
##
## กฎสำคัญ:
## 1. กำแพงอิฐใช้เฉพาะ "จุดเปลี่ยนผ่านระหว่าง Act" (Act Transitions) เท่านั้น
## 2. ไม่มีการสร้างกำแพงอิฐกั้นระหว่างด่านใน Act 3
## 3. ด่านทั้งหมด 40 ด่านเชื่อมต่อกันเป็นเส้นทางไต่หอคอยแนวตั้งอย่างต่อเนื่อง (Continuous Tower Path)

# Gothic Stone & Mortar Palette (เข้ากันได้สมบูรณ์กับ brick_wall_pillar.gd)
const MORTAR_COLOR := Color(0.06, 0.07, 0.09, 1.0)
const BORDER_COLOR := Color(0.18, 0.22, 0.28, 1.0)
const HIGHLIGHT_COLOR := Color(0.35, 0.38, 0.44, 0.75)
const SHADOW_COLOR := Color(0.04, 0.05, 0.06, 0.90)

const COPING_TOP_COLOR := Color(0.24, 0.27, 0.33, 1.0)
const COPING_BOTTOM_COLOR := Color(0.16, 0.18, 0.23, 1.0)

const POST_COLOR := Color(0.26, 0.29, 0.36, 1.0)
const POST_HIGHLIGHT := Color(0.42, 0.46, 0.55, 0.9)
const POST_SHADOW := Color(0.05, 0.06, 0.08, 1.0)

const GATEWAY_STONE := Color(0.22, 0.24, 0.30, 1.0)
const GATEWAY_HIGHLIGHT := Color(0.38, 0.42, 0.50, 0.85)
const GATEWAY_SHADOW := Color(0.05, 0.06, 0.08, 1.0)

const PASSAGE_BEAM_COLOR := Color(0.85, 0.70, 0.45, 0.08)
const PASSAGE_GLOW_COLOR := Color(0.72, 0.60, 0.40, 0.12)

const BRICK_PALETTE: Array[Color] = [
	Color(0.20, 0.22, 0.25, 1.0),
	Color(0.17, 0.19, 0.22, 1.0),
	Color(0.23, 0.25, 0.28, 1.0),
	Color(0.19, 0.21, 0.24, 1.0),
	Color(0.15, 0.17, 0.20, 1.0),
	Color(0.22, 0.24, 0.27, 1.0),
	Color(0.18, 0.20, 0.23, 1.0),
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)


func _draw() -> void:
	var left_bound := 80.0
	var right_bound := 1680.0

	# 1. สถาปัตยกรรมสิ่งแวดล้อมส่วนบนของหอคอย Act 3 (Subtle Environmental Architecture)
	# บรรยากาศยอดหอคอยปราการแก้ปัญหา: หน้าต่างโกธิคเงาดำ ซุ้มโค้ง และแท่นบูชาปรมาจารย์
	_draw_act3_environmental_backdrop(left_bound, right_bound)

	# 2. จุดเปลี่ยนผ่าน Act 2 -> Act 3: ประตูศิลาปราการโบราณ (Distinctive Stone Gateway at y = 475)
	_draw_act2_to_act3_gateway(left_bound, right_bound)

	# 3. จุดเปลี่ยนผ่าน Act 1 -> Act 2: ซุ้มประตูกำแพงอิฐโกธิคใหญ่ (Large Gothic Brick Arch at y = 1050)
	_draw_act1_to_act2_arch(left_bound, right_bound)

	# 4. ฐานรากหอคอย Act 1: แนวกำแพงศิลาฐานราก (Tower Foundation at y = 4480)
	_draw_act1_base_foundation(left_bound, right_bound)


## 1. สิ่งแวดล้อมบรรยากาศหอคอยส่วนบนของ Act 3 (Git Troubleshooting Citadel)
func _draw_act3_environmental_backdrop(left_b: float, right_b: float) -> void:
	var win_color := Color(0.11, 0.13, 0.20, 0.30)
	var win_border := Color(0.20, 0.23, 0.32, 0.40)

	# เงาโครงหน้าต่างทรงโค้งยอดแหลมโกธิค (Gothic Lancet Windows) ในพื้นหลังลึกของ Act 3
	var win_positions: Array[float] = [200.0, 510.0, 1110.0, 1420.0]
	var win_y_tiers: Array[float] = [300.0, 550.0, 780.0]
	for wy in win_y_tiers:
		for wx in win_positions:
			var ww := 72.0
			var wh := 110.0
			# ช่องหน้าต่างสี่เหลี่ยม
			draw_rect(Rect2(wx, wy + 24.0, ww, wh - 24.0), win_color)
			draw_rect(Rect2(wx, wy + 24.0, ww, wh - 24.0), win_border, false, 1.0)
			# ยอดโค้งแหลม (Pointed Arch Top)
			var arch_pts := PackedVector2Array([
				Vector2(wx, wy + 24.0),
				Vector2(wx + (ww * 0.5), wy),
				Vector2(wx + ww, wy + 24.0),
			])
			draw_colored_polygon(arch_pts, win_color)
			draw_polyline(arch_pts, win_border, 1.0)

	# คานรับน้ำหนักศิลาบนเสาขนาบข้าง (Side Corbels & Vault Ribs)
	draw_line(Vector2(left_b, 300.0), Vector2(left_b + 40.0, 340.0), Color(0.24, 0.27, 0.34, 0.5), 2.0)
	draw_line(Vector2(left_b, 580.0), Vector2(left_b + 40.0, 620.0), Color(0.24, 0.27, 0.34, 0.5), 2.0)
	draw_line(Vector2(left_b, 820.0), Vector2(left_b + 40.0, 860.0), Color(0.24, 0.27, 0.34, 0.5), 2.0)
	draw_line(Vector2(right_b, 300.0), Vector2(right_b - 40.0, 340.0), Color(0.24, 0.27, 0.34, 0.5), 2.0)
	draw_line(Vector2(right_b, 580.0), Vector2(right_b - 40.0, 620.0), Color(0.24, 0.27, 0.34, 0.5), 2.0)
	draw_line(Vector2(right_b, 820.0), Vector2(right_b - 40.0, 860.0), Color(0.24, 0.27, 0.34, 0.5), 2.0)


## 2. ประตูศิลาปราการโบราณคั่นระหว่าง Act 2 และ Act 3 (Distinctive Stone Gateway at y = 1080)
func _draw_act2_to_act3_gateway(left_b: float, right_b: float) -> void:
	var wall_y := 1080.0
	var open_x := 510.0
	var open_w := 240.0
	var open_left := open_x - (open_w * 0.5)
	var open_right := open_x + (open_w * 0.5)

	# 1. กำแพงอิฐศิลาฝั่งซ้ายและขวา
	_draw_wall_segment(left_b, open_left, wall_y)
	_draw_wall_segment(open_right, right_b, wall_y)

	# 2. ซุ้มประตูศิลาพร้อมเสาประตูคู่ยอดแหลม (Distinctive Stone Gateway Portal)
	_draw_passage_opening(open_x, open_w, wall_y, true)

	# 3. ฐานแผ่นศิลาจารึกแบนเนอร์ Act 3 (Stone Plaque Backing)
	var plaque_rect := Rect2(90.0, wall_y - 12.0, 430.0, 24.0)
	draw_rect(plaque_rect, Color(0.05, 0.06, 0.09, 0.94))
	draw_rect(plaque_rect, Color(0.96, 0.62, 0.07, 0.55), false, 1.0)


## 3. ซุ้มประตูกำแพงอิฐโกธิคใหญ่คั่นระหว่าง Act 1 และ Act 2 (Large Gothic Brick Arch at y = 1655)
func _draw_act1_to_act2_arch(left_b: float, right_b: float) -> void:
	var wall_y := 1655.0
	var open_x := 960.0
	var open_w := 200.0
	var open_left := open_x - (open_w * 0.5)
	var open_right := open_x + (open_w * 0.5)

	# 1. กำแพงอิฐศิลาฝั่งซ้ายและขวา
	_draw_wall_segment(left_b, open_left, wall_y)
	_draw_wall_segment(open_right, right_b, wall_y)

	# 2. ซุ้มประตูกลางหอคอยใหญ่พร้อมลำแสงมนตรา
	_draw_passage_opening(open_x, open_w, wall_y, false)

	# 3. ฐานแผ่นศิลาจารึกแบนเนอร์ Act 2
	var plaque_rect := Rect2(90.0, wall_y - 12.0, 710.0, 24.0)
	draw_rect(plaque_rect, Color(0.05, 0.06, 0.09, 0.94))
	draw_rect(plaque_rect, Color(0.35, 0.82, 0.60, 0.55), false, 1.0)


## 4. แนวกำแพงศิลาฐานรากหอคอย Act 1 (Tower Base Foundation at y = 5085)
func _draw_act1_base_foundation(left_b: float, right_b: float) -> void:
	var wall_y := 5085.0
	_draw_wall_segment(left_b, right_b, wall_y)

	# ฐานแผ่นศิลาจารึกแบนเนอร์ Act 1
	var plaque_rect := Rect2(90.0, wall_y - 12.0, 690.0, 24.0)
	draw_rect(plaque_rect, Color(0.05, 0.06, 0.09, 0.94))
	draw_rect(plaque_rect, Color(0.38, 0.74, 0.98, 0.55), false, 1.0)


## วาดท่อนกำแพงอิฐศิลาพิกเซลอาร์ต (Running Bond Pixel Brick Segment)
func _draw_wall_segment(x_start: float, x_end: float, wall_y: float) -> void:
	var w := x_end - x_start
	if w <= 1.0:
		return
	var wall_top := wall_y - 18.0
	var wall_height := 36.0

	# เงาทอดยาวใต้กำแพง
	draw_rect(Rect2(x_start, wall_y + 18.0, w, 24.0), Color(0.0, 0.0, 0.0, 0.45))

	# ปูนก่อยึดฐานกำแพง (Mortar Base)
	draw_rect(Rect2(x_start, wall_top, w, wall_height), MORTAR_COLOR)

	# ลายอิฐสลับแถว (Running Bond)
	var brick_w := 36.0
	var brick_h := 14.0
	var mortar := 2.0
	var num_rows := 2

	for r in range(num_rows):
		var by := wall_top + 3.0 + r * (brick_h + mortar)
		var is_odd := (r % 2 == 1)
		var offset_x := -(brick_w * 0.5) if is_odd else 0.0
		var cur_x := x_start + offset_x
		var col_idx := 0

		while cur_x < x_end:
			var bx := maxf(x_start, cur_x)
			var bw := minf(brick_w, x_end - cur_x)
			if cur_x < x_start:
				bw = brick_w + (cur_x - x_start)

			if bw > 1.0:
				var brick_rect := Rect2(bx, by, bw, brick_h)
				var hash_idx: int = abs((int(wall_y) * 31 + r * 7919 + col_idx * 104729) % BRICK_PALETTE.size())
				var col: Color = BRICK_PALETTE[hash_idx]

				draw_rect(brick_rect, col)
				draw_line(Vector2(bx, by + 0.5), Vector2(bx + bw, by + 0.5), HIGHLIGHT_COLOR, 1.0)
				if cur_x >= x_start:
					draw_line(Vector2(bx + 0.5, by), Vector2(bx + 0.5, by + brick_h), HIGHLIGHT_COLOR, 1.0)

				draw_line(Vector2(bx, by + brick_h - 0.5), Vector2(bx + bw, by + brick_h - 0.5), SHADOW_COLOR, 1.0)
				if bx + bw < x_end:
					draw_line(Vector2(bx + bw - 0.5, by), Vector2(bx + bw - 0.5, by + brick_h), SHADOW_COLOR, 1.0)

			cur_x += brick_w + mortar
			col_idx += 1

	# คานหินบัวบน (Top Gothic Coping)
	draw_rect(Rect2(x_start, wall_top, w, 5.0), COPING_TOP_COLOR)
	draw_line(Vector2(x_start, wall_top + 0.5), Vector2(x_end, wall_top + 0.5), POST_HIGHLIGHT, 1.0)
	draw_line(Vector2(x_start, wall_top + 4.5), Vector2(x_end, wall_top + 4.5), SHADOW_COLOR, 1.0)

	# คานหินบัวล่าง (Bottom Coping)
	draw_rect(Rect2(x_start, wall_y + 13.0, w, 5.0), COPING_BOTTOM_COLOR)
	draw_line(Vector2(x_start, wall_y + 13.5), Vector2(x_end, wall_y + 13.5), HIGHLIGHT_COLOR, 1.0)
	draw_line(Vector2(x_start, wall_y + 17.5), Vector2(x_end, wall_y + 17.5), SHADOW_COLOR, 1.0)


## วาดซุ้มประตูศิลาพร้อมลำแสงมนตรา (Passage Archway with Light Beam)
func _draw_passage_opening(open_x: float, open_w: float, wall_y: float, is_distinctive_gateway: bool = false) -> void:
	var x1 := open_x - (open_w * 0.5)
	var x2 := open_x + (open_w * 0.5)
	var wall_top := wall_y - 18.0

	# 1. ลำแสงมนตราเรืองรอง
	var beam_h := 110.0
	draw_rect(Rect2(x1 + 10.0, wall_y - (beam_h * 0.5), open_w - 20.0, beam_h), PASSAGE_BEAM_COLOR)
	draw_rect(Rect2(x1 + 30.0, wall_y - (beam_h * 0.35), open_w - 60.0, beam_h * 0.7), PASSAGE_GLOW_COLOR)

	var p_color := GATEWAY_STONE if is_distinctive_gateway else POST_COLOR
	var p_high := GATEWAY_HIGHLIGHT if is_distinctive_gateway else POST_HIGHLIGHT
	var p_shdw := GATEWAY_SHADOW if is_distinctive_gateway else POST_SHADOW

	# 2. เสาศิลาซุ้มประตูฝั่งซ้ายและขวา
	_draw_arch_post(x1 - 16.0, wall_top - 10.0, 16.0, 56.0, p_color, p_high, p_shdw)
	_draw_arch_post(x2, wall_top - 10.0, 16.0, 56.0, p_color, p_high, p_shdw)

	# 3. บัวหินโค้งครอบหัวซุ้มประตู
	var arch_rect := Rect2(x1 - 16.0, wall_top - 10.0, open_w + 32.0, 9.0)
	draw_rect(arch_rect, p_color)
	draw_line(Vector2(x1 - 16.0, wall_top - 9.5), Vector2(x2 + 16.0, wall_top - 9.5), p_high, 1.0)
	draw_line(Vector2(x1 - 16.0, wall_top - 1.5), Vector2(x2 + 16.0, wall_top - 1.5), p_shdw, 1.0)

	# 4. ยอดศิลาหัวซุ้มประตู (Keystone Crest in Center)
	var ks_w := 28.0 if is_distinctive_gateway else 24.0
	var ks_h := 14.0 if is_distinctive_gateway else 10.0
	draw_rect(Rect2(open_x - (ks_w * 0.5), wall_top - 10.0 - (ks_h - 4.0), ks_w, ks_h), p_color)
	draw_line(Vector2(open_x - (ks_w * 0.5), wall_top - 10.0 - (ks_h - 4.5)), Vector2(open_x + (ks_w * 0.5), wall_top - 10.0 - (ks_h - 4.5)), p_high, 1.0)
	draw_line(Vector2(open_x - (ks_w * 0.5), wall_top - 6.5), Vector2(open_x + (ks_w * 0.5), wall_top - 6.5), p_shdw, 1.0)


## วาดเสาหินซุ้มประตู (Gothic Pillar Post with Capital and Plinth)
func _draw_arch_post(px: float, py: float, pw: float, ph: float, col: Color, high: Color, shdw: Color) -> void:
	draw_rect(Rect2(px, py, pw, ph), col)
	draw_line(Vector2(px + 0.5, py), Vector2(px + 0.5, py + ph), high, 1.0)
	draw_line(Vector2(px + pw - 0.5, py), Vector2(px + pw - 0.5, py + ph), shdw, 1.0)

	# บัวหัวเสา (Capital)
	draw_rect(Rect2(px - 3.0, py, pw + 6.0, 5.0), HIGHLIGHT_COLOR)
	# ฐานเสา (Plinth)
	draw_rect(Rect2(px - 3.0, py + ph - 5.0, pw + 6.0, 5.0), SHADOW_COLOR)
