class_name CommandDemonstrationCanvas
extends Control

## ผ้าใบแสดงผลการจำลองการทำงานจริงของคำสั่ง Git
## ใช้ Node-based UI แทน custom _draw() เพื่อความน่าเชื่อถือของ layout
## - VERSION_CHECK: จำลองการพิมพ์ `git version` / `git --version` ใน Terminal
## - CONFIG_REGISTRY: จำลองการตั้งค่า user.name และ user.email ผ่าน `git config`
## - GIT_GRAPH: สำหรับด่านที่ใช้ commit / branch จริง (อนาคต)

signal animation_started
signal animation_finished(command_name: String)

enum DisplayMode {
	VERSION_CHECK,
	CONFIG_REGISTRY,
	GIT_GRAPH,
}

var current_mode: DisplayMode = DisplayMode.VERSION_CHECK

var simulated_prompt: String = "learner@diwaa:~ $"
var active_command: String = "git version"
var displayed_typed_cmd: String = ""
var terminal_output_lines: Array[String] = []
var is_typing: bool = false
var _typing_tween: Tween

# สีจาก SandboxThemeTokens
const COLOR_TERM_BG   := Color(0.015, 0.02, 0.035, 0.98)
const COLOR_HEADER_BG := Color(0.12, 0.10, 0.20, 1.0)
const COLOR_BORDER    := Color(0.85, 0.70, 0.38, 0.8)
const COLOR_PROMPT    := Color(0.31, 0.95, 0.62, 1.0)
const COLOR_CMD       := Color(0.45, 0.75, 0.95, 1.0)
const COLOR_WHITE     := Color(0.92, 0.94, 0.97, 1.0)
const COLOR_GOLD      := Color(1.0, 0.79, 0.35, 1.0)
const COLOR_MUTED     := Color(0.55, 0.60, 0.70, 1.0)
const COLOR_NOTE_BG   := Color(0.08, 0.10, 0.16, 0.95)

# UI Nodes สร้างใน _ready() แบบ dynamic เพื่อไม่ต้องพึ่ง .tscn
var _root_vbox: VBoxContainer
var _header_panel: Panel
var _header_label: Label
var _terminal_scroll: ScrollContainer
var _terminal_lines_vbox: VBoxContainer
var _note_panel: PanelContainer
var _note_vbox: VBoxContainer

var _font_bold: Font
var _font_reg: Font


func _ready() -> void:
	if ResourceLoader.exists("res://assets/fonts/ChakraPetch-Bold.ttf"):
		_font_bold = load("res://assets/fonts/ChakraPetch-Bold.ttf")
	if ResourceLoader.exists("res://assets/fonts/ChakraPetch-Regular.ttf"):
		_font_reg = load("res://assets/fonts/ChakraPetch-Regular.ttf")

	_build_ui()
	reset_animation()


# ---- สร้าง UI ด้วย GDScript ไม่ผ่าน .tscn ----

func _build_ui() -> void:
	# Root VBox เต็ม Control
	_root_vbox = VBoxContainer.new()
	_root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_vbox.add_theme_constant_override("separation", 0)
	add_child(_root_vbox)

	# --- Header bar ---
	_header_panel = Panel.new()
	_header_panel.custom_minimum_size = Vector2(0, 36)
	var hdr_style := StyleBoxFlat.new()
	hdr_style.bg_color = COLOR_HEADER_BG
	_header_panel.add_theme_stylebox_override("panel", hdr_style)
	_root_vbox.add_child(_header_panel)

	_header_label = Label.new()
	_header_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_header_label.add_theme_constant_override("margin_left", 14)
	_header_label.text = "●  ●  ●    TERMINAL PREVIEW — learner@diwaa:~"
	_header_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_header_label.add_theme_color_override("font_color", COLOR_GOLD)
	_header_label.add_theme_font_size_override("font_size", 14)
	if _font_bold:
		_header_label.add_theme_font_override("font", _font_bold)
	_header_panel.add_child(_header_label)

	# Separator line under header
	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = COLOR_BORDER * Color(1, 1, 1, 0.5)
	sep.add_theme_stylebox_override("separator", sep_style)
	sep.add_theme_constant_override("separation", 1)
	_root_vbox.add_child(sep)

	# --- Terminal body (scrollable) ---
	var body_panel := PanelContainer.new()
	body_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body_style := StyleBoxFlat.new()
	body_style.bg_color = COLOR_TERM_BG
	body_panel.add_theme_stylebox_override("panel", body_style)
	_root_vbox.add_child(body_panel)

	var body_margin := MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 16)
	body_margin.add_theme_constant_override("margin_top", 12)
	body_margin.add_theme_constant_override("margin_right", 16)
	body_margin.add_theme_constant_override("margin_bottom", 8)
	body_panel.add_child(body_margin)

	var body_vbox := VBoxContainer.new()
	body_vbox.add_theme_constant_override("separation", 0)
	body_margin.add_child(body_vbox)

	_terminal_scroll = ScrollContainer.new()
	_terminal_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_terminal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_vbox.add_child(_terminal_scroll)

	_terminal_lines_vbox = VBoxContainer.new()
	_terminal_lines_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_terminal_lines_vbox.add_theme_constant_override("separation", 2)
	_terminal_scroll.add_child(_terminal_lines_vbox)

	# --- Note panel (ด้านล่าง) ---
	_note_panel = PanelContainer.new()
	_note_panel.custom_minimum_size = Vector2(0, 110)
	var note_style := StyleBoxFlat.new()
	note_style.bg_color = COLOR_NOTE_BG
	note_style.border_color = Color(0.35, 0.45, 0.65, 0.7)
	note_style.border_width_left   = 1
	note_style.border_width_top    = 1
	note_style.border_width_right  = 1
	note_style.border_width_bottom = 1
	note_style.set_corner_radius_all(6)
	_note_panel.add_theme_stylebox_override("panel", note_style)
	body_vbox.add_child(_note_panel)

	var note_margin := MarginContainer.new()
	note_margin.add_theme_constant_override("margin_left", 14)
	note_margin.add_theme_constant_override("margin_top", 10)
	note_margin.add_theme_constant_override("margin_right", 14)
	note_margin.add_theme_constant_override("margin_bottom", 10)
	_note_panel.add_child(note_margin)

	_note_vbox = VBoxContainer.new()
	_note_vbox.add_theme_constant_override("separation", 6)
	note_margin.add_child(_note_vbox)


# ---- Public API ----

func set_mode(mode: DisplayMode) -> void:
	current_mode = mode
	reset_animation()


func reset_animation() -> void:
	if _typing_tween and _typing_tween.is_valid():
		_typing_tween.kill()

	is_typing = false
	displayed_typed_cmd = ""
	terminal_output_lines.clear()

	match current_mode:
		DisplayMode.VERSION_CHECK:
			active_command = "git version"
		DisplayMode.CONFIG_REGISTRY:
			active_command = "git config --global user.name \"Vel\""

	_refresh_terminal_ui()
	_refresh_note_ui()


func simulate_command(cmd: String) -> void:
	if is_typing:
		return

	active_command = cmd
	displayed_typed_cmd = ""
	terminal_output_lines.clear()
	is_typing = true
	animation_started.emit()

	_refresh_terminal_ui()

	if _typing_tween and _typing_tween.is_valid():
		_typing_tween.kill()

	_typing_tween = create_tween()

	var cmd_length := cmd.length()
	for i in range(1, cmd_length + 1):
		var partial := cmd.substr(0, i)
		_typing_tween.tween_callback(func() -> void:
			displayed_typed_cmd = partial
			_refresh_terminal_ui()
		)
		_typing_tween.tween_interval(0.035)

	_typing_tween.tween_interval(0.18)

	_typing_tween.tween_callback(func() -> void:
		_append_real_output_for_command(cmd)
		is_typing = false
		_refresh_terminal_ui()
		animation_finished.emit(cmd)
	)


# ---- Internal ----

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


## วาดบรรทัด Prompt + command + output ลงใน VBoxContainer จริงๆ
func _refresh_terminal_ui() -> void:
	if _terminal_lines_vbox == null:
		return

	# Clear old children
	for child in _terminal_lines_vbox.get_children():
		child.queue_free()

	# 1. Prompt + command line
	var prompt_hbox := HBoxContainer.new()
	prompt_hbox.add_theme_constant_override("separation", 0)
	_terminal_lines_vbox.add_child(prompt_hbox)

	var prompt_lbl := _make_label(simulated_prompt + " ", COLOR_PROMPT, true, 15)
	prompt_hbox.add_child(prompt_lbl)

	var cmd_text := displayed_typed_cmd
	if cmd_text == "" and not is_typing:
		cmd_text = active_command

	var cmd_lbl := _make_label(cmd_text, COLOR_CMD, true, 15)
	prompt_hbox.add_child(cmd_lbl)

	# Blinking cursor while typing
	if is_typing:
		var cursor_lbl := _make_label("▋", COLOR_PROMPT, false, 14)
		prompt_hbox.add_child(cursor_lbl)

	# 2. Output lines
	for line in terminal_output_lines:
		if line == "":
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(0, 6)
			_terminal_lines_vbox.add_child(spacer)
		elif line.begins_with("["):
			var out_lbl := _make_label(line, COLOR_GOLD, false, 13)
			out_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_terminal_lines_vbox.add_child(out_lbl)
		else:
			var out_lbl := _make_label(line, COLOR_WHITE, true, 15)
			_terminal_lines_vbox.add_child(out_lbl)

	# Scroll to bottom
	await get_tree().process_frame
	if _terminal_scroll:
		_terminal_scroll.scroll_vertical = 99999


func _refresh_note_ui() -> void:
	if _note_vbox == null:
		return

	for child in _note_vbox.get_children():
		child.queue_free()

	match current_mode:
		DisplayMode.VERSION_CHECK:
			_add_note_line("💡 หลักการทำงานของคำสั่งตรวจสอบเวอร์ชัน:", COLOR_GOLD, true, 14)
			_add_note_line("• สามารถพิมพ์ได้ 2 แบบ: git version (ไม่มีขีด) หรือ git --version (ขีดคู่)", COLOR_WHITE, false, 13)
			_add_note_line("• คำสั่งนี้จะถามโปรแกรม Git และพิมพ์เวอร์ชันที่ติดตั้งออกมาทันที", COLOR_MUTED, false, 13)
			_add_note_line("• ไม่มีการเปลี่ยนแปลงหรือสร้างไฟล์ใดๆ ในระบบ", COLOR_PROMPT, false, 13)
		DisplayMode.CONFIG_REGISTRY:
			_add_note_line("💡 หลักการทำงานของคำสั่ง git config:", COLOR_GOLD, true, 14)
			_add_note_line("• เมื่อตั้งค่า (Set) Git จะบันทึกเงียบๆ โดยไม่แสดงข้อความใดๆ ตอบกลับ", COLOR_WHITE, false, 13)
			_add_note_line("• ถ้าต้องการตรวจค่า (Get) ให้พิมพ์คำสั่งเดิมแต่ไม่ต้องใส่ค่าต่อท้าย", COLOR_MUTED, false, 13)
			_add_note_line("• ตัวอย่าง: git config --global user.name จะแสดงผลเป็น \"Vel\"", COLOR_PROMPT, false, 13)


func _add_note_line(text: String, color: Color, bold: bool, size: int) -> void:
	var lbl := _make_label(text, color, bold, size)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note_vbox.add_child(lbl)


func _make_label(text: String, color: Color, bold: bool, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	if bold and _font_bold:
		lbl.add_theme_font_override("font", _font_bold)
	elif _font_reg:
		lbl.add_theme_font_override("font", _font_reg)
	return lbl
