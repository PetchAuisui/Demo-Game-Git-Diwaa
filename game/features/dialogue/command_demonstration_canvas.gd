class_name CommandDemonstrationCanvas
extends Control

## ผ้าใบแสดงผลภาพเวทมนตร์ประจำคำสั่ง (Grimoire Spell Visualizer)
## ปรับเปลี่ยนการแสดงผลตามประเภทคำสั่งจริงของแต่ละด่าน:
## - VERSION_CHECK: วงเวทตรวจสอบระดับพลังเวท (สำหรับ git --version)
## - CONFIG_REGISTRY: ตราประทับและสมุดทะเบียนตัวตนนักเวท (สำหรับ git config)
## - GIT_GRAPH: ภาพกราฟประวัติการจารึก (สำหรับคำสั่ง commit/branch ในด่านที่มีประวัติจริง)

signal animation_started
signal animation_finished

enum DisplayMode {
	VERSION_CHECK,
	CONFIG_REGISTRY,
	GIT_GRAPH,
}

var current_mode: DisplayMode = DisplayMode.VERSION_CHECK

# สถานะทั่วไป
var is_activated: bool = false
var is_animating: bool = false
var magic_pulse: float = 0.0
var activation_progress: float = 0.0
var _tween: Tween

# ฟอนต์
var _font_bold: Font
var _font_reg: Font

# สีธีมคัมภีร์เวทมนตร์ (Grimoire Color Palette)
const COLOR_BOOK_PAGE_BG := Color(0.09, 0.08, 0.16, 0.95)
const COLOR_PARCHMENT_BORDER := Color(0.72, 0.58, 0.32, 0.7)
const COLOR_RUNE_GOLD := Color(0.92, 0.80, 0.44, 1.0)
const COLOR_RUNE_AURA := Color(0.92, 0.80, 0.44, 0.18)
const COLOR_MANA_CYAN := Color(0.45, 0.75, 0.95, 1.0)
const COLOR_MANA_GLOW := Color(0.45, 0.75, 0.95, 0.25)
const COLOR_SUCCESS_GREEN := Color(0.38, 0.94, 0.75, 1.0)
const COLOR_DARK_INK := Color(0.12, 0.10, 0.18, 1.0)
const COLOR_TEXT_MUTED := Color(0.75, 0.78, 0.85, 0.85)

# ข้อมูลเฉพาะ Git Graph (สำหรับด่านที่มีกราฟ)
var node_c0_pos := Vector2.ZERO
var node_c1_pos := Vector2.ZERO
var node_c2_pos := Vector2.ZERO
var node_radius := 26.0
var c2_visible := false
var c2_scale := 0.0
var branch_pos_t := 0.0


func _ready() -> void:
	if ResourceLoader.exists("res://assets/fonts/ChakraPetch-Bold.ttf"):
		_font_bold = load("res://assets/fonts/ChakraPetch-Bold.ttf")
	if ResourceLoader.exists("res://assets/fonts/ChakraPetch-Regular.ttf"):
		_font_reg = load("res://assets/fonts/ChakraPetch-Regular.ttf")
	
	resized.connect(_recalculate_positions)
	_recalculate_positions()
	reset_animation()


func _process(delta: float) -> void:
	magic_pulse += delta * 2.2
	queue_redraw()


func _recalculate_positions() -> void:
	var center_x := size.x * 0.5
	var start_y := size.y * 0.22
	var spacing_y := size.y * 0.26
	
	node_c0_pos = Vector2(center_x, start_y)
	node_c1_pos = Vector2(center_x, start_y + spacing_y)
	node_c2_pos = Vector2(center_x, start_y + spacing_y * 2.0)


func set_mode(mode: DisplayMode) -> void:
	current_mode = mode
	reset_animation()


func reset_animation() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	
	is_animating = false
	is_activated = false
	activation_progress = 0.0
	
	c2_visible = false
	c2_scale = 0.0
	branch_pos_t = 0.0
	
	queue_redraw()


## ร่ายการทดสอบจำลอง (Test Spell Cast)
func play_test_animation() -> void:
	if is_animating:
		return
	
	is_animating = true
	animation_started.emit()
	
	if _tween and _tween.is_valid():
		_tween.kill()
	
	_tween = create_tween()
	
	if current_mode == DisplayMode.VERSION_CHECK:
		# แอนิเมชันตรวจจับพลังเวท: วงเวทหมุนเร็วขึ้นและแผ่ออร่า
		_tween.tween_property(self, "activation_progress", 1.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	elif current_mode == DisplayMode.CONFIG_REGISTRY:
		# แอนิเมชันประทับตราวิญญาณ: ตราประทับขยายลงบนหน้าสมุด
		_tween.tween_property(self, "activation_progress", 1.0, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	else:
		# แอนิเมชัน Git Graph
		c2_visible = true
		_tween.tween_property(self, "c2_scale", 1.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.parallel().tween_property(self, "branch_pos_t", 1.0, 0.5)
	
	_tween.tween_callback(func() -> void:
		is_activated = true
		is_animating = false
		animation_finished.emit()
	)


func _draw() -> void:
	# วาดพื้นหลังหน้าคัมภีร์ฝั่งขวา (Right Page of Grimoire)
	var page_rect := Rect2(Vector2.ZERO, size)
	draw_rect(page_rect, COLOR_BOOK_PAGE_BG)
	
	# วาดกรอบเดินลายทองคัมภีร์
	_draw_grimoire_page_border(page_rect)
	
	match current_mode:
		DisplayMode.VERSION_CHECK:
			_draw_version_check_visual()
		DisplayMode.CONFIG_REGISTRY:
			_draw_config_registry_visual()
		DisplayMode.GIT_GRAPH:
			_draw_git_graph_visual()


func _draw_grimoire_page_border(rect: Rect2) -> void:
	var inset := rect.grow(-12.0)
	draw_rect(inset, COLOR_PARCHMENT_BORDER, false, 1.5)
	
	# มุมลวดลายทอง 4 มุม (Ornate Corners)
	var c_len := 16.0
	var corners := [
		inset.position,
		Vector2(inset.end.x, inset.position.y),
		Vector2(inset.position.x, inset.end.y),
		inset.end
	]
	for c in corners:
		draw_circle(c, 3.5, COLOR_RUNE_GOLD)


# ==============================================================================
# 1. VERSION CHECK VISUAL (ด่านที่ 1 ขั้นที่ 1: git --version)
# ==============================================================================
func _draw_version_check_visual() -> void:
	var center := size * 0.5 - Vector2(0, 30)
	var pulse := sin(magic_pulse) * 3.0
	
	# วงแหวนเวทมนตร์ชั้นนอก (Arcane Outer Rune Ring)
	var r_outer := 95.0 + pulse
	draw_arc(center, r_outer, 0, TAU, 48, COLOR_RUNE_AURA, 2.0)
	draw_arc(center, r_outer * 0.85, 0, TAU, 36, COLOR_RUNE_GOLD * 0.5, 1.0)
	
	# วาดขีดอักขระรอบวงแหวน (Runic Ticks)
	var ticks := 12
	for i in ticks:
		var angle := float(i) * TAU / float(ticks) + (magic_pulse * 0.2 if is_activated else 0.0)
		var p1 := center + Vector2(cos(angle), sin(angle)) * (r_outer * 0.85)
		var p2 := center + Vector2(cos(angle), sin(angle)) * r_outer
		draw_line(p1, p2, COLOR_RUNE_GOLD * 0.7, 1.5)
	
	# ดวงแก้วพลังเวทแกนกลาง (Core Mana Focus Orb)
	var r_core := 52.0 + (pulse * 0.5)
	var core_color := COLOR_MANA_CYAN if is_activated else Color(0.35, 0.45, 0.65, 0.8)
	var glow_color := COLOR_MANA_GLOW if not is_activated else Color(0.38, 0.94, 0.75, 0.35 + sin(magic_pulse * 2.0) * 0.1)
	
	draw_circle(center, r_core + 14.0, glow_color)
	draw_circle(center, r_core, core_color * 0.35)
	draw_arc(center, r_core, 0, TAU, 36, core_color, 2.5)
	
	# ข้อความสัญลักษณ์กลางดวงแก้ว
	if _font_bold != null:
		var symbol := "GIT"
		var sz := _font_bold.get_string_size(symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
		draw_string(_font_bold, Vector2(center.x - sz.x * 0.5, center.y + sz.y * 0.35), symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color(1, 1, 1, 0.95))
	
	# ป้ายสถานะผลการตรวจสอบด้านล่างดวงแก้ว (Detection Status Banner)
	var banner_rect := Rect2(size.x * 0.12, size.y * 0.68, size.x * 0.76, size.y * 0.24)
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color(0.12, 0.15, 0.26, 0.95)
	banner_style.border_color = COLOR_SUCCESS_GREEN if is_activated else Color(0.35, 0.42, 0.58, 0.8)
	banner_style.border_width_left = 2
	banner_style.border_width_top = 2
	banner_style.border_width_right = 2
	banner_style.border_width_bottom = 2
	banner_style.set_corner_radius_all(8)
	draw_style_box(banner_style, banner_rect)
	
	if _font_bold != null and _font_reg != null:
		var status_header := "✦ สถานะระดับพลังเวท ✦"
		var h_sz := _font_bold.get_string_size(status_header, HORIZONTAL_ALIGNMENT_CENTER, -1, 15)
		draw_string(_font_bold, Vector2(center.x - h_sz.x * 0.5, banner_rect.position.y + 24), status_header, HORIZONTAL_ALIGNMENT_CENTER, -1, 15, COLOR_RUNE_GOLD)
		
		if is_activated:
			var res_line1 := "ผลลัพธ์: git version 2.40+"
			var res_line2 := "✓ พลังเวท Git ตื่นขึ้นอย่างสมบูรณ์ พร้อมร่ายคาถา!"
			draw_string(_font_bold, Vector2(banner_rect.position.x + 16, banner_rect.position.y + 50), res_line1, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_MANA_CYAN)
			draw_string(_font_reg, Vector2(banner_rect.position.x + 16, banner_rect.position.y + 72), res_line2, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_SUCCESS_GREEN)
		else:
			var idle_text := "กดปุ่ม 'ทดสอบร่ายคาถา' ฝั่งซ้าย เพื่อตรวจสอบการตอบสนอง"
			draw_string(_font_reg, Vector2(banner_rect.position.x + 16, banner_rect.position.y + 60), idle_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_TEXT_MUTED)


# ==============================================================================
# 2. CONFIG REGISTRY VISUAL (ด่านที่ 1 ขั้นที่ 2: git config user.name / user.email)
# ==============================================================================
func _draw_config_registry_visual() -> void:
	var card_rect := Rect2(size.x * 0.1, size.y * 0.12, size.x * 0.8, size.y * 0.76)
	
	# แผ่นศิลาจารึกตัวตน (Registry Tablet)
	var tablet := StyleBoxFlat.new()
	tablet.bg_color = Color(0.12, 0.13, 0.22, 0.95)
	tablet.border_color = COLOR_RUNE_GOLD
	tablet.border_width_left = 2
	tablet.border_width_top = 2
	tablet.border_width_right = 2
	tablet.border_width_bottom = 2
	tablet.set_corner_radius_all(10)
	draw_style_box(tablet, card_rect)
	
	if _font_bold == null or _font_reg == null:
		return
	
	# หัวข้อ
	var title_text := "✦ สมุดทะเบียนตัวตนนักเวท (Mage Registry) ✦"
	var t_sz := _font_bold.get_string_size(title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
	draw_string(_font_bold, Vector2(size.x * 0.5 - t_sz.x * 0.5, card_rect.position.y + 36), title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, COLOR_RUNE_GOLD)
	
	# รายการข้อมูล
	var y1 := card_rect.position.y + 80.0
	_draw_registry_row(Vector2(card_rect.position.x + 20, y1), "👤 นามนักเวท (user.name):", "\"Vel\"", is_activated)
	
	var y2 := y1 + 55.0
	_draw_registry_row(Vector2(card_rect.position.x + 20, y2), "✉️ ตราประทับ (user.email):", "\"vel@magic-tower.local\"", is_activated)
	
	var y3 := y2 + 55.0
	_draw_registry_row(Vector2(card_rect.position.x + 20, y3), "📜 ขอบเขตคาถา:", "--global (บันทึกทั่วทั้งหอคอย)", is_activated)
	
	# ตราประทับวิญญาณสีทอง (Wax Seal)
	var seal_center := Vector2(size.x * 0.5, y3 + 70.0)
	var seal_r := 34.0 * (1.0 if not is_animating else activation_progress)
	if seal_r > 1.0:
		draw_circle(seal_center, seal_r + 4.0, Color(0.92, 0.80, 0.44, 0.25))
		draw_arc(seal_center, seal_r, 0, TAU, 32, COLOR_RUNE_GOLD, 2.5)
		draw_arc(seal_center, seal_r * 0.72, 0, TAU, 24, COLOR_MANA_CYAN, 1.5)
		var seal_lbl := "REGISTERED" if is_activated else "PENDING"
		var s_color := COLOR_SUCCESS_GREEN if is_activated else Color(0.8, 0.8, 0.8)
		var s_sz := _font_bold.get_string_size(seal_lbl, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
		draw_string(_font_bold, Vector2(seal_center.x - s_sz.x * 0.5, seal_center.y + 4), seal_lbl, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, s_color)


func _draw_registry_row(pos: Vector2, label: String, value: String, is_set: bool) -> void:
	draw_string(_font_reg, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_TEXT_MUTED)
	var val_color := COLOR_MANA_CYAN if is_set else Color(0.5, 0.55, 0.65)
	draw_string(_font_bold, pos + Vector2(0, 22), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, val_color)


# ==============================================================================
# 3. GIT GRAPH VISUAL (สำหรับด่านที่มีการ commit/branch จริงในอนาคต)
# ==============================================================================
func _draw_git_graph_visual() -> void:
	# วาดเส้นเชื่อมโยง
	draw_line(node_c1_pos, node_c0_pos, Color(0.35, 0.45, 0.65), 3.0)
	_draw_commit_circle(node_c0_pos, "c0", 1.0)
	_draw_commit_circle(node_c1_pos, "c1", 1.0)
	
	if c2_visible:
		draw_line(node_c2_pos, node_c1_pos, COLOR_SUCCESS_GREEN, 3.0)
		_draw_commit_circle(node_c2_pos, "c2", c2_scale)


func _draw_commit_circle(pos: Vector2, label: String, sc: float) -> void:
	if sc <= 0.05:
		return
	var r := node_radius * sc
	draw_circle(pos, r + 4.0, Color(0.38, 0.94, 0.75, 0.25))
	draw_circle(pos, r, COLOR_SUCCESS_GREEN)
	draw_arc(pos, r, 0, TAU, 32, Color(0.12, 0.35, 0.25), 2.0)
	if _font_bold != null:
		var sz := _font_bold.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
		draw_string(_font_bold, Vector2(pos.x - sz.x * 0.5, pos.y + sz.y * 0.35), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, COLOR_DARK_INK)
