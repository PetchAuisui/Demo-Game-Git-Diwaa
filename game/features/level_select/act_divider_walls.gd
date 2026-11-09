@tool
extends Control

## Act Divider Walls — Horizontal Brick Dividers Between Acts
## กำแพงอิฐโกธิคคั่นระหว่าง Act 1, Act 2, และ Act 3 พร้อมซุ้มประตูศิลาและป้ายศิลาจารึกประจำบท

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

# สเปกของกำแพงอิฐกั้นคั่นระหว่าง Act 1, Act 2, และ Act 3
const ACT_WALL_SPECS: Array[Dictionary] = [
	# 1. กำแพงอิฐฐานหอคอย Act 1 (ด้านล่างด่าน 01)
	{
		"id": "act1_base",
		"y": 4480.0,
		"has_opening": false,
		"open_x": 960.0,
		"open_w": 0.0,
		"plaque_x": 90.0,
		"plaque_w": 680.0,
		"plaque_border": Color(0.38, 0.74, 0.98, 0.45)
	},
	# 2. กำแพงอิฐคั่นระหว่าง Act 1 และ Act 2 (ระหว่างด่าน 15 และด่าน 16)
	{
		"id": "act1_to_act2",
		"y": 1050.0,
		"has_opening": true,
		"open_x": 960.0,
		"open_w": 200.0,
		"plaque_x": 90.0,
		"plaque_w": 700.0,
		"plaque_border": Color(0.35, 0.82, 0.60, 0.45)
	},
	# 3. กำแพงอิฐคั่นระหว่าง Act 2 และ Act 3 (ระหว่างด่าน 20 และด่าน 21)
	{
		"id": "act2_to_act3",
		"y": 475.0,
		"has_opening": true,
		"open_x": 550.0,
		"open_w": 200.0,
		"plaque_x": 90.0,
		"plaque_w": 420.0,
		"plaque_border": Color(0.96, 0.62, 0.07, 0.45)
	},
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	resized.connect(queue_redraw)


func _draw() -> void:
	var left_bound := 80.0
	var right_bound := 1680.0

	for spec in ACT_WALL_SPECS:
		var wall_y: float = spec["y"]
		var has_opening: bool = spec["has_opening"]

		if has_opening:
			var open_x: float = spec["open_x"]
			var open_w: float = spec["open_w"]
			var open_left := open_x - (open_w * 0.5)
			var open_right := open_x + (open_w * 0.5)

			# 1. วาดกำแพงอิฐฝั่งซ้ายของช่องเปิด
			if open_left > left_bound:
				_draw_wall_segment(left_bound, open_left, wall_y)

			# 2. วาดกำแพงอิฐฝั่งขวาของช่องเปิด
			if right_bound > open_right:
				_draw_wall_segment(open_right, right_bound, wall_y)

			# 3. วาดซุ้มประตูศิลาพร้อมลำแสงมนตรา
			_draw_passage_opening(open_x, open_w, wall_y)
		else:
			# กำแพงทึบเต็มความกว้าง (ฐานหอคอย)
			_draw_wall_segment(left_bound, right_bound, wall_y)

		# 4. ฐานแผ่นศิลาจารึกรองรับแบนเนอร์ประจำบท (Stone Plaque Backing)
		var plaque_x: float = spec["plaque_x"]
		var plaque_w: float = spec["plaque_w"]
		var border_col: Color = spec["plaque_border"]
		var plaque_rect := Rect2(plaque_x, wall_y - 12.0, plaque_w, 24.0)
		draw_rect(plaque_rect, Color(0.05, 0.06, 0.09, 0.92))
		draw_rect(plaque_rect, border_col, false, 1.0)


func _draw_wall_segment(x_start: float, x_end: float, wall_y: float) -> void:
	var w := x_end - x_start
	if w <= 1.0:
		return
	var wall_top := wall_y - 18.0
	var wall_height := 36.0

	# เงาทอดยาวใต้กำแพงสู่พื้นด้านล่าง
	draw_rect(Rect2(x_start, wall_y + 18.0, w, 24.0), Color(0.0, 0.0, 0.0, 0.45))

	# ปูนก่อยึดฐานกำแพง (Mortar Base)
	draw_rect(Rect2(x_start, wall_top, w, wall_height), MORTAR_COLOR)

	# ลายอิฐสลับแถว (Running Bond Pixel Brick Pattern)
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

				# เนื้ออิฐศิลา
				draw_rect(brick_rect, col)

				# ขอบแสงด้านบนและซ้าย (Embossed Pixel Highlights)
				draw_line(Vector2(bx, by + 0.5), Vector2(bx + bw, by + 0.5), HIGHLIGHT_COLOR, 1.0)
				if cur_x >= x_start:
					draw_line(Vector2(bx + 0.5, by), Vector2(bx + 0.5, by + brick_h), HIGHLIGHT_COLOR, 1.0)

				# ขอบเงาด้านล่างและขวา (Recessed Pixel Shadows)
				draw_line(Vector2(bx, by + brick_h - 0.5), Vector2(bx + bw, by + brick_h - 0.5), SHADOW_COLOR, 1.0)
				if bx + bw < x_end:
					draw_line(Vector2(bx + bw - 0.5, by), Vector2(bx + bw - 0.5, by + brick_h), SHADOW_COLOR, 1.0)

			cur_x += brick_w + mortar
			col_idx += 1

	# คานหินบัวบน (Top Gothic Coping Ledge)
	draw_rect(Rect2(x_start, wall_top, w, 5.0), COPING_TOP_COLOR)
	draw_line(Vector2(x_start, wall_top + 0.5), Vector2(x_end, wall_top + 0.5), POST_HIGHLIGHT, 1.0)
	draw_line(Vector2(x_start, wall_top + 4.5), Vector2(x_end, wall_top + 4.5), SHADOW_COLOR, 1.0)

	# คานหินบัวล่าง (Bottom Coping Trim)
	draw_rect(Rect2(x_start, wall_y + 13.0, w, 5.0), COPING_BOTTOM_COLOR)
	draw_line(Vector2(x_start, wall_y + 13.5), Vector2(x_end, wall_y + 13.5), HIGHLIGHT_COLOR, 1.0)
	draw_line(Vector2(x_start, wall_y + 17.5), Vector2(x_end, wall_y + 17.5), SHADOW_COLOR, 1.0)


func _draw_passage_opening(open_x: float, open_w: float, wall_y: float) -> void:
	var x1 := open_x - (open_w * 0.5)
	var x2 := open_x + (open_w * 0.5)
	var wall_top := wall_y - 18.0

	# 1. ลำแสงมนตราเรืองรองส่องผ่านช่องทางขึ้น
	var beam_h := 100.0
	draw_rect(Rect2(x1 + 10.0, wall_y - (beam_h * 0.5), open_w - 20.0, beam_h), PASSAGE_BEAM_COLOR)
	draw_rect(Rect2(x1 + 30.0, wall_y - (beam_h * 0.35), open_w - 60.0, beam_h * 0.7), PASSAGE_GLOW_COLOR)

	# 2. เสาศิลาซุ้มประตูฝั่งซ้าย
	_draw_arch_post(x1 - 14.0, wall_top - 8.0, 14.0, 52.0)

	# 3. เสาศิลาซุ้มประตูฝั่งขวา
	_draw_arch_post(x2, wall_top - 8.0, 14.0, 52.0)

	# 4. บัวหินโค้งครอบหัวซุ้มประตู
	var arch_rect := Rect2(x1 - 14.0, wall_top - 8.0, open_w + 28.0, 8.0)
	draw_rect(arch_rect, POST_COLOR)
	draw_line(Vector2(x1 - 14.0, wall_top - 7.5), Vector2(x2 + 14.0, wall_top - 7.5), POST_HIGHLIGHT, 1.0)
	draw_line(Vector2(x1 - 14.0, wall_top - 0.5), Vector2(x2 + 14.0, wall_top - 0.5), POST_SHADOW, 1.0)

	# ยอดศิลาหัวซุ้มประตู (Keystone Crest in Center)
	draw_rect(Rect2(open_x - 12.0, wall_top - 14.0, 24.0, 10.0), POST_COLOR)
	draw_line(Vector2(open_x - 12.0, wall_top - 13.5), Vector2(open_x + 12.0, wall_top - 13.5), POST_HIGHLIGHT, 1.0)
	draw_line(Vector2(open_x - 12.0, wall_top - 4.5), Vector2(open_x + 12.0, wall_top - 4.5), POST_SHADOW, 1.0)


func _draw_arch_post(px: float, py: float, pw: float, ph: float) -> void:
	draw_rect(Rect2(px, py, pw, ph), POST_COLOR)
	draw_line(Vector2(px + 0.5, py), Vector2(px + 0.5, py + ph), POST_HIGHLIGHT, 1.0)
	draw_line(Vector2(px + pw - 0.5, py), Vector2(px + pw - 0.5, py + ph), POST_SHADOW, 1.0)

	# บัวหัวเสา (Capital)
	draw_rect(Rect2(px - 3.0, py, pw + 6.0, 5.0), HIGHLIGHT_COLOR)
	# ฐานเสา (Plinth)
	draw_rect(Rect2(px - 3.0, py + ph - 5.0, pw + 6.0, 5.0), SHADOW_COLOR)
