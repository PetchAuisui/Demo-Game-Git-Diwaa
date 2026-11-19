class_name CommitEditorView
extends Control
## หน้าจารึกของคัมภีร์ = editor ที่ git commit (ไม่มี -m) เปิดให้เขียนคำจารึก (COMMIT_EDITMSG)
## บันทึก (Ctrl+Enter) → finished(ข้อความ) · ปิด (Esc) → finished("") = ยกเลิกการจารึก

signal finished(message: String)

const FONT_BOLD := "res://assets/fonts/ChakraPetch-Bold.ttf"
const FONT_REGULAR := "res://assets/fonts/ChakraPetch-Regular.ttf"
const INK := Color("3b2614")
const INK_SOFT := Color("6b4a2c")
const PARCHMENT := Color("f1dfb8")
const PARCHMENT_EDGE := Color("a9824d")

var _font_bold: Font
var _font_regular: Font
var _panel: PanelContainer
var _title: Label
var _editor: TextEdit
var _done := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font_bold = load(FONT_BOLD) if ResourceLoader.exists(FONT_BOLD) else null
	_font_regular = load(FONT_REGULAR) if ResourceLoader.exists(FONT_REGULAR) else null
	_build()


## เปิดหน้าจารึก — command คือคำสั่งที่ผู้เล่นพิมพ์ (แสดงบนหัว) text คือข้อความตั้งต้น
func open(command: String, text: String) -> void:
	_title.text = "COMMIT_EDITMSG — หน้าจารึกที่ \"%s\" เปิดให้" % command
	_editor.text = text
	_editor.set_caret_line(0)
	_editor.set_caret_column(_editor.get_line(0).length())
	modulate.a = 0.0
	_panel.pivot_offset = _panel.size * 0.5
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	_editor.grab_focus.call_deferred()


func _finish(message: String) -> void:
	if _done:
		return
	_done = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func() -> void:
		finished.emit(message)
		queue_free())


func _input(event: InputEvent) -> void:
	if _done or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := event as InputEventKey
	if key.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_finish("")
	elif key.keycode in [KEY_ENTER, KEY_KP_ENTER] and (key.ctrl_pressed or key.meta_pressed):
		get_viewport().set_input_as_handled()
		_finish(_editor.text)


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.05, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(900, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = PARCHMENT
	style.border_color = PARCHMENT_EDGE
	style.set_border_width_all(6)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(24)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 24
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	_panel.add_child(root)

	_title = _label(26, INK, true)
	root.add_child(_title)
	var sub := _label(17, INK_SOFT, false)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.text = "ไม่มี -m คัมภีร์จึงเปิดหน้าให้เขียนคำจารึกเอง (ใน Git จริงคือ editor เช่น vim / nano / VS Code) — เขียนได้หลายบรรทัด"
	root.add_child(sub)

	_editor = TextEdit.new()
	_editor.custom_minimum_size = Vector2(0, 300)
	_editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_editor.add_theme_font_size_override("font_size", 20)
	if _font_regular != null:
		_editor.add_theme_font_override("font", _font_regular)
	_editor.add_theme_color_override("font_color", Color("e8f5e9"))
	_editor.add_theme_color_override("caret_color", Color("8ff0b8"))
	var box := StyleBoxFlat.new()
	box.bg_color = Color("1c140c")
	box.set_corner_radius_all(8)
	box.set_content_margin_all(12)
	_editor.add_theme_stylebox_override("normal", box)
	_editor.add_theme_stylebox_override("focus", box)
	# บรรทัดคอมเมนต์ (#) สีจางเหมือนใน editor จริง
	var highlighter := CodeHighlighter.new()
	highlighter.add_color_region("#", "", Color("8a7a66"), true)
	_editor.syntax_highlighter = highlighter
	root.add_child(_editor)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	root.add_child(row)
	row.add_child(_button("ยกเลิก (Esc)", Color("7a4a3a"), func() -> void: _finish("")))
	row.add_child(_button("บันทึกคำจารึก (Ctrl+Enter)", Color("6b3f1d"), func() -> void: _finish(_editor.text)))


func _button(text: String, color: Color, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(280, 50)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	if _font_bold != null:
		button.add_theme_font_override("font", _font_bold)
	button.add_theme_color_override("font_color", PARCHMENT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	for state in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = color if state != "hover" else color.lightened(0.15)
		sb.set_corner_radius_all(10)
		sb.set_content_margin_all(10)
		button.add_theme_stylebox_override(state, sb)
	button.pressed.connect(action)
	return button


func _label(font_size: int, color: Color, bold: bool) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	var font := _font_bold if bold else _font_regular
	if font != null:
		label.add_theme_font_override("font", font)
	return label
