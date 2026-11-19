class_name CommitEditorView
extends Control
## หน้าจารึกแห่งคัมภีร์ = editor ที่ git commit (ไม่มี -m) เปิดให้เขียนคำจารึก (COMMIT_EDITMSG)
## หน้าตาเป็นพิธีเวท: วงเวทหมุนอยู่หลังคัมภีร์ ประกายลอยขึ้น หน้ากระดาษเรืองแสง เขียนด้วยหมึก
## ประทับตรา (Ctrl+Enter) → แสงทองวาบ แล้ว finished(ข้อความ) · ปิดคัมภีร์ (Esc) → finished("") = ยกเลิกการจารึก

signal finished(message: String)

const FONT_BOLD := "res://assets/fonts/ChakraPetch-Bold.ttf"
const FONT_REGULAR := "res://assets/fonts/ChakraPetch-Regular.ttf"
const TOME := "res://assets/cutscene/props/khampri/Khampri.png"

const LEATHER := Color("3a1f12")
const LEATHER_EDGE := Color("1f0f08")
const GOLD := Color("e8b94a")
const GOLD_SOFT := Color("b8862b")
const ARCANE := Color("a98bff")
const PAPER := Color("f3e6c4")
const INK := Color("2b1a0e")
const INK_FADED := Color("8c7356")
const SEAL := Color("8e1c1c")

var _font_bold: Font
var _font_regular: Font
var _panel: PanelContainer
var _panel_style: StyleBoxFlat
var _title: Label
var _editor: TextEdit
var _seal_button: Button
var _circle: MagicCircle
var _motes: Motes
var _flash: ColorRect
var _done := false
var _time := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font_bold = load(FONT_BOLD) if ResourceLoader.exists(FONT_BOLD) else null
	_font_regular = load(FONT_REGULAR) if ResourceLoader.exists(FONT_REGULAR) else null
	_build()


## เปิดหน้าจารึก — command คือคาถาที่ผู้เล่นร่าย (แสดงบนหัว) text คือข้อความตั้งต้น
func open(command: String, text: String) -> void:
	_title.text = "หน้าจารึกแห่งคัมภีร์"
	(_panel.get_meta("subtitle") as Label).text = "คาถา \"%s\" ไม่ได้บอกคำจารึกมา (ไม่มี -m) คัมภีร์จึงเปิดหน้านี้ให้นายเขียนเอง" % command
	_editor.text = text
	_editor.set_caret_line(0)
	_editor.set_caret_column(_editor.get_line(0).length())
	modulate.a = 0.0
	_panel.scale = Vector2(0.88, 0.88)
	_circle.scale = Vector2(0.4, 0.4)
	_ready_pivots.call_deferred()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_circle, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_editor.grab_focus.call_deferred()


func _ready_pivots() -> void:
	_panel.pivot_offset = _panel.size * 0.5
	_circle.position = size * 0.5
	_motes.size = size


func _process(delta: float) -> void:
	_time += delta
	# ขอบทองของคัมภีร์และตราประทับเรืองแสงเป็นจังหวะ เหมือนคัมภีร์กำลังหายใจ
	var pulse := 0.5 + 0.5 * sin(_time * 2.4)
	_panel_style.border_color = GOLD_SOFT.lerp(GOLD, pulse)
	_panel_style.shadow_color = Color(ARCANE, 0.25 + 0.25 * pulse)
	if _seal_button != null:
		_seal_button.modulate = Color(1, 1, 1).lerp(Color(1.25, 1.15, 0.9), pulse * 0.6)


func _finish(message: String) -> void:
	if _done:
		return
	_done = true
	var sealed := not CommitEditor.clean_message(message).is_empty()
	var tw := create_tween()
	if sealed:
		# ประทับตรา: แสงทองวาบ ประกายพุ่ง วงเวทขยายแล้วจางหาย
		_motes.burst(_panel.get_global_rect().get_center() - global_position)
		tw.set_parallel(true)
		tw.tween_property(_flash, "color:a", 0.55, 0.12)
		tw.tween_property(_circle, "scale", Vector2(1.6, 1.6), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.tween_property(_panel, "scale", Vector2(1.04, 1.04), 0.12)
		tw.chain().tween_property(_flash, "color:a", 0.0, 0.3)
		tw.tween_property(self, "modulate:a", 0.0, 0.35)
	else:
		tw.set_parallel(true)
		tw.tween_property(_panel, "scale", Vector2(0.9, 0.9), 0.18)
		tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(func() -> void:
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
	dim.color = Color(0.03, 0.01, 0.08, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_circle = MagicCircle.new()
	_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_circle)

	_motes = Motes.new()
	_motes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_motes.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_motes)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(920, 0)
	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color = LEATHER
	_panel_style.border_color = GOLD
	_panel_style.set_border_width_all(5)
	_panel_style.set_corner_radius_all(18)
	_panel_style.set_content_margin_all(26)
	_panel_style.shadow_size = 36
	_panel.add_theme_stylebox_override("panel", _panel_style)
	center.add_child(_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	_panel.add_child(root)

	# หัวคัมภีร์: รูปคัมภีร์ + ชื่อพิธี + ชื่อจริงใน Git
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)
	var icon := TextureRect.new()
	icon.texture = load(TOME) if ResourceLoader.exists(TOME) else null
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	header.add_child(icon)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 2)
	header.add_child(titles)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 14)
	titles.add_child(title_row)
	_title = _label(32, GOLD, true)
	title_row.add_child(_title)
	var real := _label(16, ARCANE, false)
	real.text = "✦ COMMIT_EDITMSG"
	real.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_row.add_child(real)
	var sub := _label(17, Color("e9d9b8"), false)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(sub)
	_panel.set_meta("subtitle", sub)

	# หน้ากระดาษ: เขียนด้วยหมึก บรรทัด # คือเสียงกระซิบของคัมภีร์ (ถูกละเว้นตอนจารึก)
	var page := PanelContainer.new()
	var page_style := StyleBoxFlat.new()
	page_style.bg_color = PAPER
	page_style.border_color = GOLD_SOFT
	page_style.set_border_width_all(2)
	page_style.set_corner_radius_all(10)
	page_style.set_content_margin_all(6)
	page_style.shadow_color = Color(GOLD, 0.35)
	page_style.shadow_size = 10
	page.add_theme_stylebox_override("panel", page_style)
	root.add_child(page)

	_editor = TextEdit.new()
	_editor.custom_minimum_size = Vector2(0, 290)
	_editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_editor.add_theme_font_size_override("font_size", 21)
	if _font_regular != null:
		_editor.add_theme_font_override("font", _font_regular)
	_editor.add_theme_color_override("font_color", INK)
	_editor.add_theme_color_override("caret_color", SEAL)
	_editor.add_theme_color_override("selection_color", Color(GOLD, 0.45))
	_editor.add_theme_constant_override("line_spacing", 8)
	var box := StyleBoxEmpty.new()
	box.set_content_margin_all(14)
	_editor.add_theme_stylebox_override("normal", box)
	_editor.add_theme_stylebox_override("focus", box)
	var highlighter := CodeHighlighter.new()
	highlighter.add_color_region("#", "", INK_FADED, true)
	_editor.syntax_highlighter = highlighter
	page.add_child(_editor)

	var guide := _label(15, Color("cdb88f"), false)
	guide.text = "บรรทัดแรก = หัวเรื่องสั้น ๆ  ·  เว้นหนึ่งบรรทัด  ·  แล้วเล่ารายละเอียด  —  หน้าว่าง = การจารึกถูกยกเลิก"
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(guide)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	root.add_child(row)
	row.add_child(_button("ปิดคัมภีร์  (Esc)", Color("4a2a1a"), Color("c9b48a"), func() -> void: _finish("")))
	_seal_button = _button("✦  ประทับตราจารึก  (Ctrl+Enter)", SEAL, Color("ffe2a8"), func() -> void: _finish(_editor.text))
	row.add_child(_seal_button)

	_flash = ColorRect.new()
	_flash.color = Color(1.0, 0.86, 0.45, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)


func _button(text: String, color: Color, font_color: Color, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300, 52)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	if _font_bold != null:
		button.add_theme_font_override("font", _font_bold)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	for state in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = color if state != "hover" else color.lightened(0.15)
		sb.border_color = GOLD_SOFT
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(26)
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


## วงเวทหมุนช้า ๆ อยู่หลังคัมภีร์: วงซ้อน อักขระรอบวง และดาวหกแฉก
class MagicCircle extends Control:
	var _angle := 0.0

	func _process(delta: float) -> void:
		_angle += delta * 0.12
		queue_redraw()

	func _draw() -> void:
		var color := Color(0.66, 0.55, 1.0, 0.22)
		var gold := Color(0.91, 0.73, 0.29, 0.22)
		draw_arc(Vector2.ZERO, 560, 0, TAU, 128, color, 3.0, true)
		draw_arc(Vector2.ZERO, 520, 0, TAU, 128, gold, 2.0, true)
		draw_arc(Vector2.ZERO, 380, 0, TAU, 96, color, 2.0, true)
		# อักขระรอบวง: เพชรเล็กสลับจุด หมุนตามวง
		for i in 36:
			var a := _angle + TAU * i / 36.0
			var p := Vector2(cos(a), sin(a)) * 540.0
			if i % 3 == 0:
				var d := Vector2(cos(a), sin(a)) * 9.0
				var n := Vector2(-d.y, d.x) * 0.55
				draw_colored_polygon(PackedVector2Array([p + d, p + n, p - d, p - n]), gold)
			else:
				draw_circle(p, 3.0, color)
		# ดาวหกแฉก (สองสามเหลี่ยมหมุนสวนกัน)
		for k in 2:
			var points := PackedVector2Array()
			for j in 4:
				var a2 := -_angle * 1.6 + PI * k / 3.0 + TAU * j / 3.0
				points.append(Vector2(cos(a2), sin(a2)) * 380.0)
			draw_polyline(points, color, 2.0, true)


## ประกายเวทลอยขึ้นช้า ๆ และพุ่งกระจายตอนประทับตรา
class Motes extends Control:
	var _motes: Array[Dictionary] = []

	func _ready() -> void:
		for i in 46:
			_motes.append(_new_mote(true))

	func _new_mote(anywhere: bool) -> Dictionary:
		var area := size if size != Vector2.ZERO else Vector2(1600, 900)
		return {
			"p": Vector2(randf() * area.x, randf() * area.y if anywhere else area.y + 10.0),
			"v": Vector2(randf_range(-8, 8), randf_range(-38, -14)),
			"r": randf_range(1.2, 3.2),
			"c": Color(0.95, 0.8, 0.4) if randf() < 0.6 else Color(0.72, 0.62, 1.0),
			"life": -1.0,
		}

	func burst(at: Vector2) -> void:
		for i in 70:
			var a := randf() * TAU
			_motes.append({"p": at, "v": Vector2(cos(a), sin(a)) * randf_range(180, 520),
					"r": randf_range(1.5, 4.0), "c": Color(1.0, 0.85, 0.45), "life": randf_range(0.5, 0.9)})

	func _process(delta: float) -> void:
		for i in range(_motes.size() - 1, -1, -1):
			var m: Dictionary = _motes[i]
			m["p"] += m["v"] * delta
			if m["life"] >= 0.0:
				m["life"] -= delta
				m["v"] *= 0.92
				if m["life"] <= 0.0:
					_motes.remove_at(i)
			elif m["p"].y < -10.0:
				_motes[i] = _new_mote(false)
		queue_redraw()

	func _draw() -> void:
		var t := Time.get_ticks_msec() / 1000.0
		for m in _motes:
			var twinkle := 0.45 + 0.55 * absf(sin(t * 2.0 + m["p"].x * 0.05))
			var c: Color = m["c"]
			draw_circle(m["p"], m["r"] * 2.6, Color(c, 0.12 * twinkle))
			draw_circle(m["p"], m["r"], Color(c, 0.85 * twinkle))
