class_name ScrollReaderView
extends Control
## หยิบกระดาษขึ้นมาอ่าน: การกระทำในโลกเกม (คลิกกระดาษในห้อง) แทนการพิมพ์คำสั่งอ่านไฟล์
## แสดงชื่อในโลกเวท + ชื่อไฟล์ และเนื้อหาบนกระดาษ ปิดด้วยปุ่ม / Enter / Esc

signal closed

const FONT_BOLD := "res://assets/fonts/ChakraPetch-Bold.ttf"
const FONT_REGULAR := "res://assets/fonts/ChakraPetch-Regular.ttf"
const PAPER := "res://assets/cutscene/props/khampri/paper.png"
const INK := Color("3b2614")
const INK_SOFT := Color("6b4a2c")
const PARCHMENT := Color("f1dfb8")
const PARCHMENT_EDGE := Color("a9824d")

var _panel: PanelContainer
var _title: Label
var _file_label: Label
var _content: Label
var _button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	visible = false


func show_scroll(title: String, path: String, content: String) -> void:
	_title.text = title
	_file_label.text = "ไฟล์: " + path
	_content.text = content.strip_edges() if not content.strip_edges().is_empty() else "(กระดาษว่างเปล่า)"
	visible = true
	modulate.a = 0.0
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.9, 0.9)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_button.grab_focus.call_deferred()


func close() -> void:
	if not visible:
		return
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func() -> void:
		visible = false
		closed.emit())


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo \
			and event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		close()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.05, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			close())
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(760, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = PARCHMENT
	style.border_color = PARCHMENT_EDGE
	style.set_border_width_all(6)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(28)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 20
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	_panel.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	root.add_child(header)
	var icon := TextureRect.new()
	icon.texture = load(PAPER) if ResourceLoader.exists(PAPER) else null
	icon.custom_minimum_size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	header.add_child(icon)
	var titles := VBoxContainer.new()
	header.add_child(titles)
	_title = _label(30, INK, true)
	titles.add_child(_title)
	_file_label = _label(16, INK_SOFT, false)
	titles.add_child(_file_label)

	var rule := ColorRect.new()
	rule.color = Color(PARCHMENT_EDGE, 0.6)
	rule.custom_minimum_size = Vector2(0, 2)
	root.add_child(rule)

	_content = _label(24, INK, false)
	_content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.custom_minimum_size = Vector2(700, 80)
	root.add_child(_content)

	_button = Button.new()
	_button.text = "วางกระดาษลง"
	_button.custom_minimum_size = Vector2(240, 50)
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button.add_theme_font_size_override("font_size", 21)
	if ResourceLoader.exists(FONT_BOLD):
		_button.add_theme_font_override("font", load(FONT_BOLD))
	_button.add_theme_color_override("font_color", PARCHMENT)
	_button.add_theme_color_override("font_hover_color", Color.WHITE)
	for state in ["normal", "hover", "pressed", "focus"]:
		var btn := StyleBoxFlat.new()
		btn.bg_color = Color("6b3f1d") if state != "hover" else Color("8a5427")
		btn.set_corner_radius_all(10)
		btn.set_content_margin_all(10)
		_button.add_theme_stylebox_override(state, btn)
	_button.pressed.connect(close)
	root.add_child(_button)


func _label(font_size: int, color: Color, bold: bool) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	var path := FONT_BOLD if bold else FONT_REGULAR
	if ResourceLoader.exists(path):
		label.add_theme_font_override("font", load(path))
	return label
