@tool
extends Control

@export var is_right_side: bool = false
@export var brick_width: float = 37.0
@export var brick_height: float = 16.0
@export var mortar_thickness: float = 2.0

# Dark Gothic Fantasy grey stone palette (หินศิลาโกธิคสีเทา คมชัด สวยงาม มีมิติ)
const MORTAR_COLOR := Color(0.06, 0.07, 0.09, 1.0)
const BORDER_COLOR := Color(0.18, 0.22, 0.28, 1.0)
const HIGHLIGHT_COLOR := Color(0.35, 0.38, 0.44, 0.75)
const SHADOW_COLOR := Color(0.04, 0.05, 0.06, 0.90)

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
	queue_redraw()
	resized.connect(queue_redraw)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 0.0 or h <= 0.0:
		return
	
	# 1. Dark mortar foundation
	draw_rect(Rect2(0, 0, w, h), MORTAR_COLOR)
	
	# 2. Running bond brick pattern
	var row_step: float = brick_height + mortar_thickness
	var num_rows: int = int(ceil(h / row_step)) + 2
	
	for row in range(num_rows):
		var y: float = row * row_step
		var is_odd: bool = (row % 2 == 1)
		var offset_x: float = -(brick_width * 0.5) if is_odd else 0.0
		
		var cur_x: float = offset_x
		var col_idx: int = 0
		while cur_x < w:
			var bx: float = max(0.0, cur_x)
			var bw: float = min(brick_width, w - cur_x)
			if cur_x < 0.0:
				bw = brick_width + cur_x
			
			if bw > 1.0:
				var brick_rect := Rect2(bx, y, bw, brick_height)
				var hash_idx: int = abs((row * 7919 + col_idx * 104729) % BRICK_PALETTE.size())
				var col: Color = BRICK_PALETTE[hash_idx]
				
				# Fill brick
				draw_rect(brick_rect, col)
				
				# Top edge highlight (subtle embossed relief)
				draw_line(Vector2(bx, y + 0.5), Vector2(bx + bw, y + 0.5), HIGHLIGHT_COLOR, 1.0)
				# Left edge highlight
				if cur_x >= 0.0:
					draw_line(Vector2(bx + 0.5, y), Vector2(bx + 0.5, y + brick_height), HIGHLIGHT_COLOR, 1.0)
				
				# Bottom edge shadow
				draw_line(Vector2(bx, y + brick_height - 0.5), Vector2(bx + bw, y + brick_height - 0.5), SHADOW_COLOR, 1.0)
				# Right edge shadow
				if bx + bw < w:
					draw_line(Vector2(bx + bw - 0.5, y), Vector2(bx + bw - 0.5, y + brick_height), SHADOW_COLOR, 1.0)
			
			cur_x += brick_width + mortar_thickness
			col_idx += 1
	
	# 3. Inner border and soft vignette to blend with tower chamber
	if is_right_side:
		# Inner dividing border on the left edge of RightPillar
		draw_line(Vector2(1.0, 0), Vector2(1.0, h), BORDER_COLOR, 2.0)
		# Subtle shadow gradient on inner edge
		draw_rect(Rect2(0, 0, 10.0, h), Color(0.0, 0.0, 0.0, 0.35))
	else:
		# Inner dividing border on the right edge of LeftPillar
		draw_line(Vector2(w - 1.0, 0), Vector2(w - 1.0, h), BORDER_COLOR, 2.0)
		# Subtle shadow gradient on inner edge
		draw_rect(Rect2(w - 10.0, 0, 10.0, h), Color(0.0, 0.0, 0.0, 0.35))
