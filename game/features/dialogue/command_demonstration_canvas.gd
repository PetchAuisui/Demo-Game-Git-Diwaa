class_name CommandDemonstrationCanvas
extends Control

## ผ้าใบแสดงผลการจำลองการทำงานจริงของคำสั่ง Git (Authentic Terminal & Git Visualizer)
## แสดงผลตามหลักการทำงานจริงของ Git:
## - VERSION_CHECK: จำลองการพิมพ์ `git version` / `git --version` ใน Terminal และผลลัพธ์ที่ Git ตอบกลับ
## - CONFIG_REGISTRY: จำลองการตั้งค่า user.name และ user.email ผ่าน `git config` และการตรวจสอบค่า
## - GIT_GRAPH: ภาพกราฟประวัติ Commit (สำหรับด่านที่ใช้คำสั่ง commit / branch จริง)

signal animation_started
signal animation_finished(command_name: String)

enum DisplayMode {
	VERSION_CHECK,
	CONFIG_REGISTRY,
	GIT_GRAPH,
}

var current_mode: DisplayMode = DisplayMode.VERSION_CHECK

# สถานะ Terminal Simulator
var simulated_prompt: String = "learner@diwaa:~ $"
var active_command: String = "git version"
var displayed_typed_cmd: String = ""
var terminal_output_lines: Array[String] = []
var is_typing: bool = false
var typing_cursor_visible: bool = true
var cursor_timer: float = 0.0
var _typing_tween: Tween

# ฟอนต์ตาม Design Guide
var _font_bold: Font
var _font_reg: Font
var _font_ta8bit: Font

# สีจาก SandboxThemeTokens & Fonts Guide
const COLOR_TERM_BG := Color(0.015, 0.02, 0.035, 0.98)
const COLOR_TERM_BORDER := Color(0.85, 0.70, 0.38, 0.8)
const COLOR_PROMPT_GREEN := Color(0.31, 0.95, 0.62, 1.0)
const COLOR_CMD_CYAN := Color(0.45, 0.75, 0.95, 1.0)
const COLOR_TEXT_WHITE := Color(0.92, 0.94, 0.97, 1.0)
const COLOR_GOLD := Color(1.0, 0.79, 0.35, 1.0)
const COLOR_MUTED := Color(0.55, 0.60, 0.70, 1.0)
const COLOR_CARD_BG := Color(0.08, 0.07, 0.14, 0.95)


func _ready() -> void:
	if ResourceLoader.exists("res://assets/fonts/ChakraPetch-Bold.ttf"):
		_font_bold = load("res://assets/fonts/ChakraPetch-Bold.ttf")
	if ResourceLoader.exists("res://assets/fonts/ChakraPetch-Regular.ttf"):
		_font_reg = load("res://assets/fonts/ChakraPetch-Regular.ttf")
	if ResourceLoader.exists("res://assets/fonts/TA-8-bit.ttf"):
		_font_ta8bit = load("res://assets/fonts/TA-8-bit.ttf")
	
	reset_animation()


func _process(delta: float) -> void:
	cursor_timer += delta
	if cursor_timer >= 0.45:
		cursor_timer = 0.0
		typing_cursor_visible = !typing_cursor_visible
		queue_redraw()


func set_mode(mode: DisplayMode) -> void:
	current_mode = mode
	reset_animation()


func reset_animation() -> void:
	if _typing_tween and _typing_tween.is_valid():
		_typing_tween.kill()
	
	is_typing = false
	displayed_typed_cmd = ""
	terminal_output_lines.clear()
	
	if current_mode == DisplayMode.VERSION_CHECK:
		active_command = "git version"
	elif current_mode == DisplayMode.CONFIG_REGISTRY:
		active_command = "git config --global user.name \"Vel\""
	
	queue_redraw()


## จำลองการพิมพ์คำสั่งที่เลือกและแสดงผลลัพธ์จริง
func simulate_command(cmd: String) -> void:
	if is_typing:
		return
	
	active_command = cmd
	displayed_typed_cmd = ""
	terminal_output_lines.clear()
	is_typing = true
	animation_started.emit()
	
	if _typing_tween and _typing_tween.is_valid():
		_typing_tween.kill()
	
	_typing_tween = create_tween()
	
	# จำลองการพิมพ์ทีละตัวอักษร
	var cmd_length := cmd.length()
	for i in range(1, cmd_length + 1):
		var partial := cmd.substr(0, i)
		_typing_tween.tween_callback(func() -> void:
			displayed_typed_cmd = partial
			queue_redraw()
		)
		_typing_tween.tween_interval(0.035)
	
	# ดีเลย์ก่อน Enter ตอบกลับ
	_typing_tween.tween_interval(0.18)
	
	# ตอบกลับผลลัพธ์ตามหลักการจริงของคำสั่ง
	_typing_tween.tween_callback(func() -> void:
		_append_real_output_for_command(cmd)
		is_typing = false
		queue_redraw()
		animation_finished.emit(cmd)
	)


func _append_real_output_for_command(cmd: String) -> void:
	var trimmed := cmd.strip_edges()
	
	if trimmed == "git version" or trimmed == "git --version":
		terminal_output_lines.append("git version 2.40.1")
		terminal_output_lines.append("")
		terminal_output_lines.append("[ ผลลัพธ์: ตรวจพบระบบ Git 2.40.1 พร้อมใช้งานในหอคอย ]")
	elif trimmed.begins_with("git config") and trimmed.contains("user.name") and trimmed.contains("\"Vel\""):
		terminal_output_lines.append("")
		terminal_output_lines.append("[ บันทึกนาม \"Vel\" สำเร็จ (คำสั่งนี้ไม่มี output ตามปกติของ Git) ]")
	elif trimmed.begins_with("git config") and trimmed.contains("user.email"):
		terminal_output_lines.append("")
		terminal_output_lines.append("[ บันทึกอีเมล \"vel@magic-tower.local\" สำเร็จ ]")
	elif trimmed == "git config --global user.name":
		terminal_output_lines.append("Vel")
		terminal_output_lines.append("")
		terminal_output_lines.append("[ ตรวจสอบพบชื่อที่จดจำไว้: \"Vel\" ]")
	else:
		terminal_output_lines.append("command executed successfully.")


func _draw() -> void:
	var page_rect := Rect2(Vector2.ZERO, size)
	draw_rect(page_rect, COLOR_CARD_BG)
	
	# กรอบทองของหน้าคัมภีร์
	var border_rect := page_rect.grow(-8.0)
	draw_rect(border_rect, COLOR_TERM_BORDER * 0.7, false, 1.5)
	
	# แผ่นจำลอง Terminal
	var term_rect := Rect2(size.x * 0.05, size.y * 0.06, size.x * 0.9, size.y * 0.88)
	draw_rect(term_rect, COLOR_TERM_BG)
	draw_rect(term_rect, COLOR_TERM_BORDER, false, 2.0)
	
	# Header bar ของ Terminal
	var header_h := 36.0
	var header_rect := Rect2(term_rect.position.x, term_rect.position.y, term_rect.size.x, header_h)
	draw_rect(header_rect, Color(0.12, 0.10, 0.20, 1.0))
	draw_line(Vector2(term_rect.position.x, term_rect.position.y + header_h), Vector2(term_rect.end.x, term_rect.position.y + header_h), COLOR_TERM_BORDER * 0.6, 1.5)
	
	# ข้อความหัวแถบ Terminal
	if _font_bold != null:
		var title := "●  ●  ●    TERMINAL PREVIEW — learner@diwaa:~"
		draw_string(_font_bold, Vector2(header_rect.position.x + 14, header_rect.position.y + 24), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_GOLD)
	
	# วาดเนื้อหาใน Terminal
	var text_start := Vector2(term_rect.position.x + 18, term_rect.position.y + header_h + 30)
	_draw_terminal_content(text_start, term_rect)


func _draw_terminal_content(start_pos: Vector2, term_rect: Rect2) -> void:
	if _font_bold == null or _font_reg == null:
		return
	
	var cur_y := start_pos.y
	
	# 1. แถว Prompt + คำสั่งที่กำลังพิมพ์
	var prompt := simulated_prompt + " "
	var prompt_sz := _font_bold.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
	draw_string(_font_bold, Vector2(start_pos.x, cur_y), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, COLOR_PROMPT_GREEN)
	
	var cmd_display := displayed_typed_cmd
	if cmd_display == "" and not is_typing:
		cmd_display = active_command
	
	var cmd_x := start_pos.x + prompt_sz.x
	draw_string(_font_bold, Vector2(cmd_x, cur_y), cmd_display, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, COLOR_CMD_CYAN)
	
	# ตัวเคอร์เซอร์กระพริบ ▋
	if typing_cursor_visible:
		var cmd_sz := _font_bold.get_string_size(cmd_display, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
		draw_string(_font_bold, Vector2(cmd_x + cmd_sz.x + 2, cur_y), "▋", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_PROMPT_GREEN)
	
	cur_y += 32.0
	
	# 2. บรรทัดผลลัพธ์จาก Terminal
	for line in terminal_output_lines:
		if line.begins_with("["):
			draw_string(_font_reg, Vector2(start_pos.x, cur_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_GOLD)
		else:
			draw_string(_font_bold, Vector2(start_pos.x, cur_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, COLOR_TEXT_WHITE)
		cur_y += 24.0
	
	# 3. กล่องคำอธิบายหลักการทำงานจริงของคำสั่ง (ด้านล่างจอ Terminal)
	var note_y := term_rect.end.y - 120.0
	var note_rect := Rect2(term_rect.position.x + 12, note_y, term_rect.size.x - 24, 108)
	var note_style := StyleBoxFlat.new()
	note_style.bg_color = Color(0.08, 0.10, 0.16, 0.95)
	note_style.border_color = Color(0.35, 0.45, 0.65, 0.7)
	note_style.border_width_left = 1
	note_style.border_width_top = 1
	note_style.border_width_right = 1
	note_style.border_width_bottom = 1
	note_style.set_corner_radius_all(6)
	draw_style_box(note_style, note_rect)
	
	_draw_explanation_notes(note_rect)


func _draw_explanation_notes(rect: Rect2) -> void:
	if _font_bold == null or _font_reg == null:
		return
	
	var px := rect.position.x + 14.0
	var py := rect.position.y + 22.0
	
	if current_mode == DisplayMode.VERSION_CHECK:
		draw_string(_font_bold, Vector2(px, py), "💡 หลักการทำงานของคำสั่งตรวจสอบเวอร์ชัน:", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_GOLD)
		py += 22.0
		draw_string(_font_reg, Vector2(px, py), "• สามารถพิมพ์ได้ 2 แบบ: git version (ไม่มีขีด) หรือ git --version (ขีดคู่)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_TEXT_WHITE)
		py += 20.0
		draw_string(_font_reg, Vector2(px, py), "• คำสั่งนี้จะถามโปรแกรม Git และพิมพ์เวอร์ชันที่ติดตั้งออกมาทันที", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_MUTED)
		py += 20.0
		draw_string(_font_reg, Vector2(px, py), "• ไม่มีการเปลี่ยนแปลงหรือสร้างไฟล์ใดๆ ในระบบ", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_PROMPT_GREEN)
	elif current_mode == DisplayMode.CONFIG_REGISTRY:
		draw_string(_font_bold, Vector2(px, py), "💡 หลักการทำงานของคำสั่ง git config:", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_GOLD)
		py += 22.0
		draw_string(_font_reg, Vector2(px, py), "• เมื่อตั้งค่า (Set) Git จะบันทึกเงียบๆ โดยไม่แสดงข้อความใดๆ ตอบกลับ", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_TEXT_WHITE)
		py += 20.0
		draw_string(_font_reg, Vector2(px, py), "• ถ้าต้องการตรวจค่า (Get) ให้พิมพ์คำสั่งเดิมแต่ไม่ต้องใส่ค่าต่อท้าย", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_MUTED)
		py += 20.0
		draw_string(_font_reg, Vector2(px, py), "• ตัวอย่าง: git config --global user.name จะแสดงผลเป็น \"Vel\"", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_PROMPT_GREEN)
