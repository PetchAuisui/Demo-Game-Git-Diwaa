@tool
extends Control

## Act 3: The Summit Citadel — Horizontal Brick Walls & Floor Passages
## วาดกำแพงอิฐโกธิคขวางกั้นแต่ละชั้นของหอคอย โดยผู้เล่นจะปีนขึ้นสู่ชั้นถัดไปได้ทางช่องเปิด (Passage Openings) เท่านั้น

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

# สเปกของกำแพงอิฐ 7 ชั้นใน Act 3 พร้อมพิกัดช่องเปิด (Openings)
const WALL_SPECS: Array[Dictionary] = [
	{ "floor": 1, "y": 3450.0, "open_x": 1380.0, "open_w": 200.0, "title": "FLOOR I · THE INSPECTION DECK" },
	{ "floor": 2, "y": 2950.0, "open_x": 540.0, "open_w": 200.0, "title": "FLOOR II · RESTORATION VAULT" },
	{ "floor": 3, "y": 2450.0, "open_x": 1380.0, "open_w": 200.0, "title": "FLOOR III · BRANCHING CLOISTER" },
	{ "floor": 4, "y": 1950.0, "open_x": 540.0, "open_w": 200.0, "title": "FLOOR IV · GRAPH SANCTUARY" },
	{ "floor": 5, "y": 1450.0, "open_x": 1240.0, "open_w": 200.0, "title": "FLOOR V · BASTION OF MERGE" },
	{ "floor": 6, "y": 950.0, "open_x": 540.0, "open_w": 200.0, "title": "FLOOR VI · REMOTE ARCHIVES" },
	{ "floor": 7, "y": 460.0, "open_x": 960.0, "open_w": 240.0, "title": "FLOOR VII · THE CITADEL GATE" },
]

var _font_ta_pixel: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://assets/fonts/TA-8-bit.ttf"):
		_font_ta_pixel = load("res://assets/fonts/TA-8-bit.ttf") as Font
	queue_redraw()
	resized.connect(queue_redraw)


func _draw() -> void:
	var left_bound := 80.0
	var right_bound := 1680.0

	for spec in WALL_SPECS:
		var wall_y: float = spec["y"]
		var open_x: float = spec["open_x"]
		var open_w: float = spec["open_w"]
		var open_left := open_x - (open_w * 0.5)
		var open_right := open_x + (open_w * 0.5)

		# 1. วาดกำแพงอิฐฝั่งซ้ายของช่องเปิด (Left Wall Segment)
		if open_left > left_bound:
			_draw_wall_segment(left_bound, open_left, wall_y)

		# 2. วาดกำแพงอิฐฝั่งขวาของช่องเปิด (Right Wall Segment)
		if right_bound > open_right:
			_draw_wall_segment(open_right, right_bound, wall_y)

		# 3. วาดช่องเปิดสำหรับปีนขึ้นชั้นถัดไป (Passage Opening & Archway)
		_draw_passage_opening(open_x, open_w, wall_y)

		# 4. ป้ายสลักชื่อชั้นหอคอยโบราณ (Gothic Floor Inscription)
		_draw_floor_inscription(spec, left_bound, right_bound, open_left, open_right)

	# 5. ยอดหอคอยชั้นสูงสุด: แท่นบูชาและเงาปรมาจารย์ Git (Summit Spire Altar)
	_draw_summit_altar()


func _draw_wall_segment(x_start: float, x_end: float, wall_y: float) -> void:
	var w := x_end - x_start
	if w <= 1.0:
		return
	var wall_top := wall_y - 18.0
	var wall_height := 36.0

	# เงาทอดยาวใต้กำแพงสู่พื้นด้านล่าง (Deep Ambient Drop Shadow)
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

	# 1. ลำแสงมนตราเรืองรองส่องผ่านช่องทางขึ้น (Mystic Passage Ambient Light Beam)
	var beam_h := 100.0
	draw_rect(Rect2(x1 + 10.0, wall_y - (beam_h * 0.5), open_w - 20.0, beam_h), PASSAGE_BEAM_COLOR)
	draw_rect(Rect2(x1 + 30.0, wall_y - (beam_h * 0.35), open_w - 60.0, beam_h * 0.7), PASSAGE_GLOW_COLOR)

	# 2. เสาศิลาซุ้มประตูฝั่งซ้าย (Left Arch Pillar Jamb)
	_draw_arch_post(x1 - 14.0, wall_top - 8.0, 14.0, 52.0)

	# 3. เสาศิลาซุ้มประตูฝั่งขวา (Right Arch Pillar Jamb)
	_draw_arch_post(x2, wall_top - 8.0, 14.0, 52.0)

	# 4. บัวหินโค้งครอบหัวซุ้มประตู (Arch Lintel Header)
	var arch_rect := Rect2(x1 - 14.0, wall_top - 8.0, open_w + 28.0, 8.0)
	draw_rect(arch_rect, POST_COLOR)
	draw_line(Vector2(x1 - 14.0, wall_top - 7.5), Vector2(x2 + 14.0, wall_top - 7.5), POST_HIGHLIGHT, 1.0)
	draw_line(Vector2(x1 - 14.0, wall_top - 0.5), Vector2(x2 + 14.0, wall_top - 0.5), POST_SHADOW, 1.0)

	# ยอดศิลาหัวซุ้มประตู (Keystone Crest in Center)
	draw_rect(Rect2(open_x - 12.0, wall_top - 14.0, 24.0, 10.0), POST_COLOR)
	draw_line(Vector2(open_x - 12.0, wall_top - 13.5), Vector2(open_x + 12.0, wall_top - 13.5), POST_HIGHLIGHT, 1.0)
	draw_line(Vector2(open_x - 12.0, wall_top - 4.5), Vector2(open_x + 12.0, wall_top - 4.5), POST_SHADOW, 1.0)


func _draw_arch_post(px: float, py: float, pw: float, ph: float) -> void:
	# ตัวเสาหินศิลา
	draw_rect(Rect2(px, py, pw, ph), POST_COLOR)
	draw_line(Vector2(px + 0.5, py), Vector2(px + 0.5, py + ph), POST_HIGHLIGHT, 1.0)
	draw_line(Vector2(px + pw - 0.5, py), Vector2(px + pw - 0.5, py + ph), POST_SHADOW, 1.0)

	# บัวหัวเสา (Capital)
	draw_rect(Rect2(px - 3.0, py, pw + 6.0, 5.0), HIGHLIGHT_COLOR)
	# ฐานเสา (Plinth)
	draw_rect(Rect2(px - 3.0, py + ph - 5.0, pw + 6.0, 5.0), SHADOW_COLOR)


func _draw_floor_inscription(spec: Dictionary, left_b: float, right_b: float, open_l: float, open_r: float) -> void:
	if not _font_ta_pixel:
		return
	var text: String = spec["title"]
	var wall_y: float = spec["y"]

	# วางป้ายสลักบนฝั่งกำแพงที่กว้างกว่า
	var left_w := open_l - left_b
	var right_w := right_b - open_r
	var label_center_x: float = (left_b + open_l) * 0.5 if left_w >= right_w else (open_r + right_b) * 0.5

	var txt_size := _font_ta_pixel.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
	var txt_pos := Vector2(label_center_x - (txt_size.x * 0.5), wall_y + 5.0)

	# กรอบแผ่นศิลาจารึก (Stone Inscription Plaque)
	var plaque_rect := Rect2(txt_pos.x - 12.0, wall_y - 12.0, txt_size.x + 24.0, 24.0)
	draw_rect(plaque_rect, Color(0.08, 0.09, 0.13, 0.88))
	draw_rect(plaque_rect, Color(0.30, 0.35, 0.44, 0.65), false, 1.0)

	# ข้อความสลักสีหม่นโกธิค
	draw_string(_font_ta_pixel, txt_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.70, 0.73, 0.82, 0.90))


func _draw_summit_altar() -> void:
	# ยอดหอคอย (The Summit Deck: y = 220, Git Master Altar: y = 80-160)
	var altar_center := Vector2(960.0, 110.0)

	# วงแหวนเวทมนตร์อักขระ Git โบราณเรืองแสงสีทองอำพันบนยอดหอคอย
	draw_arc(altar_center, 64.0, 0, TAU, 32, Color(0.722, 0.604, 0.404, 0.35), 2.0)
	draw_arc(altar_center, 78.0, 0, TAU, 32, Color(0.722, 0.604, 0.404, 0.20), 1.0)
	draw_arc(altar_center, 42.0, 0, TAU, 24, Color(0.961, 0.620, 0.043, 0.45), 2.0)

	# รัศมีแสงสีทองอร่ามบนยอดหอคอย (Golden Aura)
	draw_circle(altar_center, 35.0, Color(0.961, 0.78, 0.35, 0.12))

	# เงาปรมาจารย์ Git ผู้สาบสูญ (Grand Master Silhouette)
	# ลำตัว/เสื้อคลุมนักเวท
	var robe_pts := PackedVector2Array([
		Vector2(altar_center.x - 22.0, altar_center.y + 40.0),
		Vector2(altar_center.x + 22.0, altar_center.y + 40.0),
		Vector2(altar_center.x + 14.0, altar_center.y + 8.0),
		Vector2(altar_center.x + 10.0, altar_center.y - 12.0),
		Vector2(altar_center.x - 10.0, altar_center.y - 12.0),
		Vector2(altar_center.x - 14.0, altar_center.y + 8.0),
	])
	draw_colored_polygon(robe_pts, Color(0.08, 0.09, 0.14, 0.95))

	# หมวกทรงสูง/ฮู้ดปรมาจารย์
	var hood_pts := PackedVector2Array([
		Vector2(altar_center.x - 14.0, altar_center.y - 10.0),
		Vector2(altar_center.x + 14.0, altar_center.y - 10.0),
		Vector2(altar_center.x, altar_center.y - 36.0),
	])
	draw_colored_polygon(hood_pts, Color(0.06, 0.07, 0.11, 0.98))

	# ไม้เท้าคัมภีร์ Git โบราณ (Scripture Staff)
	draw_line(Vector2(altar_center.x + 24.0, altar_center.y - 32.0), Vector2(altar_center.x + 24.0, altar_center.y + 42.0), Color(0.722, 0.604, 0.404, 0.9), 2.5)
	draw_circle(Vector2(altar_center.x + 24.0, altar_center.y - 34.0), 6.0, Color(0.961, 0.88, 0.47, 1.0))
