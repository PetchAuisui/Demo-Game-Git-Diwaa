class_name CommandDemonstrationCanvas
extends Control

## ผ้าใบแสดงผลการจำลองคำสั่ง Git (Interactive Git Graph Demonstration Canvas)
## รองรับการวาดกราฟ Commit โหนด, กิ่งเวท (branch pointer main*), เส้นเชื่อมโยง (arrows)
## และเอฟเฟกต์แอนิเมชันเวทมนตร์เมื่อผู้เล่นกดร่ายคำสั่ง

signal animation_started
signal animation_finished

enum DemoMode {
	COMMIT,
	CONFIG,
}

var current_mode: DemoMode = DemoMode.COMMIT

# โหนดกราฟ Commit
var node_c0_pos := Vector2.ZERO
var node_c1_pos := Vector2.ZERO
var node_c2_pos := Vector2.ZERO
var node_radius := 28.0

# สถานะแอนิเมชันสำหรับ Commit Demo
var c2_visible := false
var c2_scale := 0.0
var c2_alpha := 0.0
var arrow_c2_to_c1_progress := 0.0
var branch_target_node := 1 # 1 = c1, 2 = c2
var branch_pos_t := 0.0 # 0.0 = at c1, 1.0 = at c2
var magic_pulse := 0.0
var is_animating := false

# สถานะแอนิเมชันสำหรับ Config / Version Demo
var config_verified := false
var config_name_set := false
var config_email_set := false
var config_anim_step := 0
var config_seal_scale := 0.0

# สีธีมเวทมนตร์
const COLOR_CANVAS_BG := Color(0.08, 0.12, 0.22, 1.0)
const COLOR_NODE_FILL := Color(0.38, 0.94, 0.75, 1.0)
const COLOR_NODE_BORDER := Color(0.12, 0.45, 0.35, 1.0)
const COLOR_NODE_GLOW := Color(0.38, 0.94, 0.75, 0.35)
const COLOR_TEXT_DARK := Color(0.06, 0.22, 0.16, 1.0)
const COLOR_ARROW := Color(0.15, 0.25, 0.38, 1.0)
const COLOR_ARROW_ACTIVE := Color(0.38, 0.94, 0.75, 1.0)
const COLOR_BRANCH_BADGE := Color(0.20, 0.92, 0.58, 1.0)
const COLOR_BRANCH_TEXT := Color(0.04, 0.20, 0.12, 1.0)
const COLOR_GRID_LINE := Color(0.15, 0.22, 0.35, 0.3)
const COLOR_RUNE_AURA := Color(0.45, 0.55, 0.95, 0.15)

var _tween: Tween
var _font_bold: Font
var _font_reg: Font


func _ready() -> void:
	if ResourceLoader.exists("res://assets/fonts/ChakraPetch-Bold.ttf"):
		_font_bold = load("res://assets/fonts/ChakraPetch-Bold.ttf")
	if ResourceLoader.exists("res://assets/fonts/ChakraPetch-Regular.ttf"):
		_font_reg = load("res://assets/fonts/ChakraPetch-Regular.ttf")
	
	resized.connect(_recalculate_positions)
	_recalculate_positions()
	reset_animation()


func _process(delta: float) -> void:
	magic_pulse += delta * 2.5
	queue_redraw()


func _recalculate_positions() -> void:
	var center_x := size.x * 0.5
	var start_y := size.y * 0.22
	var spacing_y := size.y * 0.26
	
	node_c0_pos = Vector2(center_x, start_y)
	node_c1_pos = Vector2(center_x, start_y + spacing_y)
	node_c2_pos = Vector2(center_x, start_y + spacing_y * 2.0)


func set_mode(mode: DemoMode) -> void:
	current_mode = mode
	reset_animation()


## รีเซ็ตแอนิเมชันกลับสู่สถานะก่อนร่ายคาถา
func reset_animation() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	
	is_animating = false
	c2_visible = false
	c2_scale = 0.0
	c2_alpha = 0.0
	arrow_c2_to_c1_progress = 0.0
	branch_target_node = 1
	branch_pos_t = 0.0
	
	config_verified = false
	config_name_set = false
	config_email_set = false
	config_anim_step = 0
	config_seal_scale = 0.0
	
	queue_redraw()


## ร่ายแอนิเมชันสร้าง Commit ใหม่ (c2) พร้อมขยับ branch pointer main*
func play_commit_animation() -> void:
	if is_animating:
		return
	
	is_animating = true
	animation_started.emit()
	
	if _tween and _tween.is_valid():
		_tween.kill()
	
	c2_visible = true
	c2_scale = 0.0
	c2_alpha = 0.0
	arrow_c2_to_c1_progress = 0.0
	
	_tween = create_tween().set_parallel(false)
	
	# 1. โหนด c2 ขยายและปรากฏขึ้น
	_tween.parallel().tween_property(self, "c2_scale", 1.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "c2_alpha", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	
	# 2. วาดเส้นลูกศรเชื่อมโยงจาก c2 ไปยัง c1
	_tween.tween_property(self, "arrow_c2_to_c1_progress", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 3. ขยับป้าย main* จาก c1 ไปยัง c2
	_tween.tween_property(self, "branch_pos_t", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(func() -> void:
		branch_target_node = 2
		is_animating = false
		animation_finished.emit()
	)


## ร่ายแอนิเมชันสำหรับ Config & Version Demo
func play_config_animation() -> void:
	if is_animating:
		return
	
	is_animating = true
	animation_started.emit()
	
	if _tween and _tween.is_valid():
		_tween.kill()
	
	_tween = create_tween()
	_tween.tween_property(self, "config_seal_scale", 1.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(func() -> void:
		config_verified = true
		config_name_set = true
		config_email_set = true
		is_animating = false
		animation_finished.emit()
	)


func _draw() -> void:
	# 1. วาดพื้นหลังฉากเวทมนตร์ (Astral Portal Background)
	var bg_rect := Rect2(Vector2.ZERO, size)
	draw_rect(bg_rect, COLOR_CANVAS_BG)
	_draw_celestial_grid()
	_draw_magic_runic_circle(node_c1_pos if not c2_visible else node_c2_pos)
	
	if current_mode == DemoMode.COMMIT:
		_draw_commit_demonstration()
	else:
		_draw_config_demonstration()


func _draw_celestial_grid() -> void:
	var step := 36.0
	var cols := int(size.x / step) + 1
	var rows := int(size.y / step) + 1
	
	for i in cols:
		var x := i * step
		draw_line(Vector2(x, 0), Vector2(x, size.y), COLOR_GRID_LINE, 1.0)
	for j in rows:
		var y := j * step
		draw_line(Vector2(0, y), Vector2(size.x, y), COLOR_GRID_LINE, 1.0)


func _draw_magic_runic_circle(center: Vector2) -> void:
	var radius := 80.0 + sin(magic_pulse) * 4.0
	draw_arc(center, radius, 0, TAU, 36, COLOR_RUNE_AURA, 1.5)
	draw_arc(center, radius * 0.6, 0, TAU, 24, COLOR_RUNE_AURA * 0.7, 1.0)


func _draw_commit_demonstration() -> void:
	# 1. วาดเส้นและลูกศรระหว่าง c1 -> c0
	_draw_arrow(node_c1_pos, node_c0_pos, COLOR_ARROW, 1.0)
	
	# 2. วาดเส้นและลูกศรระหว่าง c2 -> c1 (ตาม progress)
	if c2_visible and arrow_c2_to_c1_progress > 0.0:
		var current_target := node_c2_pos.lerp(node_c1_pos, arrow_c2_to_c1_progress)
		_draw_arrow(node_c2_pos, current_target, COLOR_ARROW_ACTIVE, arrow_c2_to_c1_progress)
	
	# 3. วาดโหนด c0
	_draw_commit_node(node_c0_pos, "c0", 1.0)
	
	# 4. วาดโหนด c1
	_draw_commit_node(node_c1_pos, "c1", 1.0)
	
	# 5. วาดโหนด c2 (ถ้ามี)
	if c2_visible:
		_draw_commit_node(node_c2_pos, "c2", c2_scale, c2_alpha)
	
	# 6. วาดป้าย branch pointer main*
	_draw_branch_pointer()


func _draw_commit_node(pos: Vector2, label: String, scale_factor: float, alpha: float = 1.0) -> void:
	if scale_factor <= 0.01 or alpha <= 0.01:
		return
	
	var r := node_radius * scale_factor
	var glow_color := COLOR_NODE_GLOW
	glow_color.a *= alpha
	var fill_color := COLOR_NODE_FILL
	fill_color.a *= alpha
	var border_color := COLOR_NODE_BORDER
	border_color.a *= alpha
	
	# แสงเรืองรอบโหนด (Glow pulse)
	var pulse_r := r + 6.0 + sin(magic_pulse + pos.y * 0.01) * 2.0
	draw_circle(pos, pulse_r, glow_color)
	
	# วงกลมหลัก
	draw_circle(pos, r, fill_color)
	draw_arc(pos, r, 0, TAU, 32, border_color, 2.5)
	
	# ข้อความรหัส commit
	if _font_bold != null:
		var font_size := int(18.0 * scale_factor)
		var text_size := _font_bold.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos := Vector2(pos.x - text_size.x * 0.5, pos.y + text_size.y * 0.35)
		var text_color := COLOR_TEXT_DARK
		text_color.a *= alpha
		draw_string(_font_bold, text_pos, label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)


func _draw_arrow(from_pos: Vector2, to_pos: Vector2, color: Color, progress: float) -> void:
	var dir := (to_pos - from_pos).normalized()
	var dist := from_pos.distance_to(to_pos)
	
	var start_offset := dir * (node_radius + 4.0)
	var end_offset := dir * (node_radius + 6.0)
	
	var p_start := from_pos + start_offset
	var p_end := to_pos - end_offset
	
	if progress < 1.0:
		p_end = p_start.lerp(p_end, progress)
	
	# เส้นตรง
	draw_line(p_start, p_end, color, 3.5, true)
	
	# หัวลูกศร (ชี้ไปทาง to_pos)
	if progress >= 0.7:
		var arrow_size := 12.0
		var perp := Vector2(-dir.y, dir.x)
		var tip := p_end
		var left := p_end - dir * arrow_size + perp * (arrow_size * 0.6)
		var right := p_end - dir * arrow_size - perp * (arrow_size * 0.6)
		
		var points := PackedVector2Array([tip, left, right])
		draw_colored_polygon(points, color)


func _draw_branch_pointer() -> void:
	# คำนวณตำแหน่งของป้าย main* โดย interpolate ระหว่าง c1 และ c2
	var target_commit_pos := node_c1_pos.lerp(node_c2_pos, branch_pos_t)
	var badge_offset := Vector2(85.0, 0.0)
	var badge_center := target_commit_pos + badge_offset
	
	var badge_w := 78.0
	var badge_h := 32.0
	var badge_rect := Rect2(badge_center.x - badge_w * 0.5, badge_center.y - badge_h * 0.5, badge_w, badge_h)
	
	# แสงเรืองรองของป้ายกิ่งเวท
	var glow_rect := badge_rect.grow(4.0)
	draw_rect(glow_rect, Color(COLOR_BRANCH_BADGE.r, COLOR_BRANCH_BADGE.g, COLOR_BRANCH_BADGE.b, 0.25), true, -1)
	
	# ป้ายกล่องมน
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_BRANCH_BADGE
	sb.set_corner_radius_all(6)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(1, 1, 1, 0.85)
	draw_style_box(sb, badge_rect)
	
	# ลูกศรชี้จากป้ายเข้าหาโหนด commit
	var arrow_start := Vector2(badge_rect.position.x, badge_center.y)
	var arrow_end := Vector2(target_commit_pos.x + node_radius + 6.0, target_commit_pos.y)
	
	var arrow_dir := (arrow_end - arrow_start).normalized()
	var perp := Vector2(-arrow_dir.y, arrow_dir.x)
	var head_size := 10.0
	
	draw_line(arrow_start, arrow_end, COLOR_BRANCH_BADGE, 4.0, true)
	var arrow_pts := PackedVector2Array([
		arrow_end,
		arrow_end - arrow_dir * head_size + perp * (head_size * 0.7),
		arrow_end - arrow_dir * head_size - perp * (head_size * 0.7)
	])
	draw_colored_polygon(arrow_pts, COLOR_BRANCH_BADGE)
	
	# ตัวอักษร main*
	if _font_bold != null:
		var text := "main*"
		var font_size := 16
		var text_size := _font_bold.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos := Vector2(badge_center.x - text_size.x * 0.5, badge_center.y + text_size.y * 0.35)
		draw_string(_font_bold, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, COLOR_BRANCH_TEXT)


func _draw_config_demonstration() -> void:
	# การแสดงผลสำหรับหน้าสรุป Config / Version
	var center_x := size.x * 0.5
	var card_w := size.x * 0.82
	var card_h := size.y * 0.76
	var card_rect := Rect2(center_x - card_w * 0.5, size.y * 0.12, card_w, card_h)
	
	# แผ่นคัมภีร์มนตรา
	var parchment := StyleBoxFlat.new()
	parchment.bg_color = Color(0.12, 0.14, 0.24, 0.95)
	parchment.border_color = Color(0.92, 0.80, 0.44, 0.9)
	parchment.border_width_left = 2
	parchment.border_width_top = 2
	parchment.border_width_right = 2
	parchment.border_width_bottom = 2
	parchment.set_corner_radius_all(10)
	draw_style_box(parchment, card_rect)
	
	if _font_bold == null:
		return
	
	# หัวข้อแผ่นคัมภีร์
	var title_text := "✦ ตราประทับวิญญาณและตัวตนนักเวท ✦"
	var title_sz := _font_bold.get_string_size(title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18)
	draw_string(_font_bold, Vector2(center_x - title_sz.x * 0.5, card_rect.position.y + 36.0), title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(0.95, 0.82, 0.45))
	
	# แถวที่ 1: ตรวจสอบพลัง Git
	var row1_y := card_rect.position.y + 80.0
	_draw_config_item(Vector2(card_rect.position.x + 24.0, row1_y), "คาถาตรวจสอบพลัง:", "git --version", "✓ Git 2.40+ (พร้อมใช้งาน)", config_verified)
	
	# แถวที่ 2: ประกาศนาม (user.name)
	var row2_y := row1_y + 60.0
	_draw_config_item(Vector2(card_rect.position.x + 24.0, row2_y), "ประกาศนามนักเวท:", "git config user.name", "\"Vel\"" if config_name_set else "(ยังไม่ลงทะเบียน)", config_name_set)
	
	# แถวที่ 3: ผูกตราประทับอีเมล (user.email)
	var row3_y := row2_y + 60.0
	_draw_config_item(Vector2(card_rect.position.x + 24.0, row3_y), "ผูกตราประทับวิญญาณ:", "git config user.email", "\"vel@magic-tower.local\"" if config_email_set else "(ยังไม่ลงทะเบียน)", config_email_set)
	
	# วาดดวงตราเวทมนตร์กลมด้านล่าง
	var seal_center := Vector2(center_x, row3_y + 70.0)
	var seal_r := 36.0 * (1.0 if not is_animating else config_seal_scale)
	if seal_r > 0.0:
		draw_circle(seal_center, seal_r + 4.0, Color(0.92, 0.80, 0.44, 0.25))
		draw_arc(seal_center, seal_r, 0, TAU, 32, Color(0.92, 0.80, 0.44, 0.9), 2.0)
		draw_arc(seal_center, seal_r * 0.7, 0, TAU, 24, Color(0.45, 0.75, 0.95, 0.8), 1.5)
		var seal_lbl := "SEALED" if config_name_set else "READY"
		var seal_sz := _font_bold.get_string_size(seal_lbl, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
		draw_string(_font_bold, Vector2(seal_center.x - seal_sz.x * 0.5, seal_center.y + 4.0), seal_lbl, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(1, 1, 1, 0.95))


func _draw_config_item(pos: Vector2, title: String, cmd: String, value: String, is_active: bool) -> void:
	if _font_bold == null or _font_reg == null:
		return
	
	# หัวข้อ
	draw_string(_font_reg, pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.84, 0.92))
	# คำสั่ง
	draw_string(_font_bold, pos + Vector2(170, 0), cmd, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.45, 0.75, 0.95))
	# ค่าสถานะ
	var val_color := Color(0.38, 0.94, 0.75) if is_active else Color(0.65, 0.68, 0.75, 0.8)
	draw_string(_font_bold, pos + Vector2(350, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, val_color)
