class_name LevelMissionPanel
extends PanelContainer

## แผงภารกิจของด่านที่แสดงทับพื้นที่กลางของ Sandbox: ขั้นที่ ชื่อภารกิจ เรื่องย่อ
## เช็กลิสต์ภารกิจ ข้อความตอบกลับเมื่อพิมพ์ผิด ปุ่มคำใบ้ และปุ่มไปต่อเมื่อทำครบ
## ไม่ตรวจคำสั่งเอง: รับ LevelMission มาแสดงและเรียก refresh() เมื่อสถานะเปลี่ยน

signal continue_pressed

const FONT_REGULAR_PATH := "res://assets/fonts/ChakraPetch-Regular.ttf"
const FONT_BOLD_PATH := "res://assets/fonts/ChakraPetch-Bold.ttf"
const DONE_COLOR := SandboxThemeTokens.PROMPT_GREEN
const MAX_FEEDBACK_SECONDS := 6.0

var _mission: LevelMission
var _font_regular: Font
var _font_bold: Font

var _badge_label: Label
var _title_label: Label
var _story_label: Label
var _rows_box: VBoxContainer
var _progress_row: HBoxContainer
var _progress_label: Label
var _progress_bar: ProgressBar
var _hint_button: Button
var _hint_label: Label
var _feedback_label: Label
var _complete_box: VBoxContainer
var _complete_label: Label
var _continue_button: Button
var _feedback_tween: Tween
var _hint_visible := false


func _init() -> void:
	name = "LevelMissionPanel"
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", SandboxThemeTokens.create_card_style())
	if ResourceLoader.exists(FONT_REGULAR_PATH):
		_font_regular = load(FONT_REGULAR_PATH) as Font
	if ResourceLoader.exists(FONT_BOLD_PATH):
		_font_bold = load(FONT_BOLD_PATH) as Font
	_build()


func setup(mission: LevelMission) -> void:
	_mission = mission
	_badge_label.text = "ด่านที่ %d  ·  ขั้นที่ %d/%d" % [mission.level_number, mission.step, mission.total_steps]
	_title_label.text = mission.title
	_story_label.text = mission.story
	_hint_visible = false
	_complete_box.visible = false
	_feedback_label.text = ""
	_feedback_label.visible = false
	refresh()


## วาดรายการภารกิจและแถบความคืบหน้าใหม่ตามสถานะใน LevelMission
func refresh() -> void:
	if _mission == null:
		return
	for child in _rows_box.get_children():
		_rows_box.remove_child(child)
		child.queue_free()

	# ภารกิจเดียว: ข้อความภารกิจไปอยู่ที่ช่องพิมพ์ของเทอร์มินัลแทน จึงไม่ต้องแสดงเช็กลิสต์/แถบความคืบหน้าซ้ำ
	var show_checklist := _mission.objectives.size() > 1
	_rows_box.visible = show_checklist
	_progress_row.visible = show_checklist

	var current := _mission.current_objective()
	for objective in _mission.objectives:
		var done := _mission.is_done(str(objective["id"]))
		var is_current: bool = not current.is_empty() and str(current["id"]) == str(objective["id"])
		_rows_box.add_child(_build_row(str(objective["text"]), done, is_current))

	_progress_label.text = "%d/%d ภารกิจ" % [_mission.done_count(), _mission.objectives.size()]
	_progress_bar.max_value = maxf(1.0, float(_mission.objectives.size()))
	_progress_bar.value = float(_mission.done_count())

	var finished := _mission.is_complete()
	_hint_button.visible = not finished
	_hint_label.visible = _hint_visible and not finished
	_hint_label.text = str(current.get("hint", ""))


## แสดงข้อความตอบกลับสั้น ๆ (เช่น เตือนพิมพ์ผิด / ยืนยันว่าทำสำเร็จ) แล้วจางหายเอง
func show_feedback(text: String, is_error: bool = false) -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback_label.text = text
	_feedback_label.visible = not text.is_empty()
	_feedback_label.add_theme_color_override("font_color",
			SandboxThemeTokens.ERROR_TEXT if is_error else DONE_COLOR)
	_feedback_label.modulate.a = 1.0
	if text.is_empty():
		return
	_feedback_tween = create_tween()
	_feedback_tween.tween_interval(MAX_FEEDBACK_SECONDS)
	_feedback_tween.tween_property(_feedback_label, "modulate:a", 0.0, 0.6)


func show_complete(message: String, button_text: String) -> void:
	_hint_visible = false
	_complete_label.text = message
	_continue_button.text = button_text
	_complete_box.visible = true
	_hint_button.visible = false
	_hint_label.visible = false
	show_feedback("")
	_complete_box.modulate.a = 0.0
	create_tween().tween_property(_complete_box, "modulate:a", 1.0, 0.35)
	_continue_button.grab_focus.call_deferred()


func _build() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 6)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	_badge_label = _make_label(18, SandboxThemeTokens.GOLD_TITLE, true)
	_badge_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_badge_label)
	_hint_button = Button.new()
	_hint_button.text = "คำใบ้"
	_hint_button.focus_mode = Control.FOCUS_NONE
	_hint_button.add_theme_stylebox_override("normal", SandboxThemeTokens.create_button_style())
	_hint_button.add_theme_stylebox_override("hover", SandboxThemeTokens.create_button_style())
	_hint_button.add_theme_stylebox_override("pressed", SandboxThemeTokens.create_button_style())
	_hint_button.add_theme_font_size_override("font_size", 16)
	_hint_button.pressed.connect(_on_hint_pressed)
	header.add_child(_hint_button)

	_title_label = _make_label(26, SandboxThemeTokens.BRAND_TEXT, true)
	root.add_child(_title_label)
	_story_label = _make_label(18, SandboxThemeTokens.SUBTITLE_TEXT, false)
	_story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_story_label)

	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 6)
	root.add_child(_rows_box)

	_hint_label = _make_label(17, SandboxThemeTokens.GOLD_TITLE, false)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.visible = false
	root.add_child(_hint_label)

	_progress_row = HBoxContainer.new()
	_progress_row.add_theme_constant_override("separation", 10)
	root.add_child(_progress_row)
	_progress_bar = ProgressBar.new()
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(0, 10)
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_progress_bar.add_theme_stylebox_override("background", _flat(SandboxThemeTokens.INPUT_BG, 5))
	_progress_bar.add_theme_stylebox_override("fill", _flat(DONE_COLOR, 5))
	_progress_row.add_child(_progress_bar)
	_progress_label = _make_label(16, SandboxThemeTokens.TEXT_SECONDARY, false)
	_progress_row.add_child(_progress_label)

	_feedback_label = _make_label(17, DONE_COLOR, false)
	_feedback_label.visible = false
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_feedback_label)

	_complete_box = VBoxContainer.new()
	_complete_box.visible = false
	_complete_box.add_theme_constant_override("separation", 8)
	root.add_child(_complete_box)
	_complete_label = _make_label(22, DONE_COLOR, true)
	_complete_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_complete_box.add_child(_complete_label)
	_continue_button = Button.new()
	_continue_button.custom_minimum_size = Vector2(0, 44)
	_continue_button.add_theme_font_size_override("font_size", 20)
	_continue_button.add_theme_stylebox_override("normal", _flat(Color(0.12, 0.42, 0.3, 0.96), 8))
	_continue_button.add_theme_stylebox_override("hover", _flat(Color(0.16, 0.54, 0.38, 1.0), 8))
	_continue_button.add_theme_stylebox_override("pressed", _flat(Color(0.1, 0.34, 0.24, 1.0), 8))
	if _font_bold != null:
		_continue_button.add_theme_font_override("font", _font_bold)
	_continue_button.pressed.connect(func() -> void: continue_pressed.emit())
	_complete_box.add_child(_continue_button)


func _build_row(text: String, done: bool, is_current: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var check := _CheckBox.new()
	check.done = done
	check.custom_minimum_size = Vector2(24, 24)
	check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(check)
	var color := SandboxThemeTokens.TEXT_SECONDARY if done \
			else (SandboxThemeTokens.PRIMARY_TEXT if is_current else SandboxThemeTokens.TEXT_SECONDARY)
	var label := _make_label(19, color, is_current)
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return row


func _on_hint_pressed() -> void:
	_hint_visible = not _hint_visible
	refresh()


func _make_label(font_size: int, color: Color, bold: bool) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	var font := _font_bold if bold else _font_regular
	if font != null:
		label.add_theme_font_override("font", font)
	return label


static func _flat(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(8)
	return style


## ช่องติ๊กวาดเอง (วงกลม + ขีดถูก) ไม่พึ่งว่าฟอนต์มีอักขระ ✓
class _CheckBox extends Control:
	var done := false

	func _draw() -> void:
		var center := size / 2.0
		var radius := minf(size.x, size.y) / 2.0 - 1.0
		if done:
			draw_circle(center, radius, SandboxThemeTokens.PROMPT_GREEN)
			var tick := PackedVector2Array([
				center + Vector2(-radius * 0.45, 0.0),
				center + Vector2(-radius * 0.1, radius * 0.38),
				center + Vector2(radius * 0.5, -radius * 0.38)])
			draw_polyline(tick, Color(0.02, 0.06, 0.04), 2.5, true)
		else:
			draw_arc(center, radius, 0.0, TAU, 32, SandboxThemeTokens.CARD_BORDER, 2.0, true)
