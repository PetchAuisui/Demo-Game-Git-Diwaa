class_name ScrollReaderView
extends Control
## สมุดโน้ตที่เปิดอ่านเมื่อหยิบกระดาษในห้องขึ้นมา (การกระทำในโลกเกม แทนการพิมพ์คำสั่งอ่านไฟล์)
## ปกหนังสีน้ำตาล หน้ากระดาษสีครีม ห่วงสันสีแดงด้านซ้าย เลขหน้า "หน้า n / m" และปุ่มพลิกหน้า
## ข้อความยาวแบ่งเป็นหลายหน้าอัตโนมัติ: ←/→ พลิกหน้า, Enter = หน้าถัดไป (หน้าสุดท้าย = ปิด), Esc = ปิด
## style "proclamation" = ประกาศของหอคอย: หัวเรื่องสีแดง และตราประทับหอคอยในหน้าสุดท้าย

signal closed

const FONT_BOLD := "res://assets/fonts/ChakraPetch-Bold.ttf"
const FONT_REGULAR := "res://assets/fonts/ChakraPetch-Regular.ttf"
const LINES_PER_PAGE := 5
const PAGE_SIZE := Vector2(640, 620)

const LEATHER := Color("6e3b1f")
const LEATHER_DARK := Color("4a2614")
const PAPER := Color("f6eed6")
const PAPER_EDGE := Color("dccfa8")
const INK := Color("2f2216")
const INK_SOFT := Color("7a6145")
const RING := Color("b3261e")
const RULED := Color(0.55, 0.45, 0.3, 0.18)

var _book: PanelContainer
var _paper: Control
var _page_label: Label
var _title: Label
var _file_label: Label
var _body: Label
var _seal: Control
var _prev: Button
var _next: Button
var _close: Button

var _pages: Array[String] = []
var _page := 0
var _proclamation := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	visible = false


func show_scroll(title: String, path: String, content: String, style: String = "") -> void:
	_proclamation = style == "proclamation"
	_title.text = title
	_title.add_theme_color_override("font_color", RING if _proclamation else INK)
	_file_label.text = ("ประกาศแห่งหอคอยเวท · ไฟล์: " if _proclamation else "ไฟล์: ") + path
	_pages = paginate(content, LINES_PER_PAGE)
	_page = 0
	_show_page()
	visible = true
	modulate.a = 0.0
	_book.pivot_offset = _book.size * 0.5
	_book.scale = Vector2(0.92, 0.92)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	tw.tween_property(_book, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(_align_ruled_lines)


## แบ่งข้อความเป็นหน้า หน้าละ lines_per_page บรรทัด (บรรทัดว่างท้ายไฟล์ถูกตัด)
static func paginate(content: String, lines_per_page: int) -> Array[String]:
	var trimmed := content.strip_edges(false, true)
	var pages: Array[String] = []
	if trimmed.strip_edges().is_empty():
		pages.append("(หน้ากระดาษว่างเปล่า)")
		return pages
	var lines := trimmed.split("\n")
	var index := 0
	while index < lines.size():
		pages.append("\n".join(lines.slice(index, index + lines_per_page)))
		index += lines_per_page
	return pages


func close() -> void:
	if not visible:
		return
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func() -> void:
		visible = false
		closed.emit())


func turn(delta: int) -> void:
	var target := clampi(_page + delta, 0, _pages.size() - 1)
	if target == _page:
		return
	_page = target
	var tw := create_tween()
	tw.tween_property(_paper, "modulate:a", 0.3, 0.07)
	tw.tween_callback(_show_page)
	tw.tween_property(_paper, "modulate:a", 1.0, 0.1)


func _show_page() -> void:
	var last := _page >= _pages.size() - 1
	_page_label.text = "หน้า %d / %d" % [_page + 1, _pages.size()]
	_title.visible = _page == 0
	_file_label.visible = _page == 0
	_body.text = _pages[_page]
	_seal.visible = _proclamation and last
	var single := _pages.size() <= 1
	_prev.visible = not single
	_next.visible = not single
	_page_label.visible = not single
	_prev.disabled = _page == 0
	_next.disabled = last
	_prev.modulate.a = 0.35 if _prev.disabled else 1.0
	_next.modulate.a = 0.35 if _next.disabled else 1.0
	(_next if not last else _close).grab_focus.call_deferred()
	_align_ruled_lines.call_deferred()


## วางเส้นบรรทัดของกระดาษให้อยู่ใต้ข้อความพอดี (ตำแหน่งข้อความเปลี่ยนตามหน้า: หน้าแรกมีหัวเรื่อง)
func _align_ruled_lines() -> void:
	var page := _paper as NotebookPage
	if page == null or not is_instance_valid(_body):
		return
	var step := float(_body.get_line_height()) + float(_body.get_theme_constant("line_spacing"))
	page.line_step = maxf(step, 24.0)
	# ใช้ตำแหน่งในพิกัดของหน้ากระดาษ (ไม่ขึ้นกับการย่อ/ขยายตอนเปิดสมุด)
	var body_top := _paper.get_global_transform().affine_inverse() * _body.global_position
	page.line_start = body_top.y + float(_body.get_line_height()) + 4.0
	page.queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ESCAPE:
			close()
		KEY_ENTER, KEY_KP_ENTER:
			if _page >= _pages.size() - 1:
				close()
			else:
				turn(1)
		KEY_RIGHT:
			turn(1)
		KEY_LEFT:
			turn(-1)
		_:
			return
	get_viewport().set_input_as_handled()


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

	# ปกหนัง
	_book = PanelContainer.new()
	var cover := StyleBoxFlat.new()
	cover.bg_color = LEATHER
	cover.border_color = LEATHER_DARK
	cover.set_border_width_all(6)
	cover.set_corner_radius_all(14)
	cover.set_content_margin_all(16)
	cover.shadow_color = Color(0, 0, 0, 0.55)
	cover.shadow_size = 22
	_book.add_theme_stylebox_override("panel", cover)
	center.add_child(_book)

	# หน้ากระดาษ (วาดเส้นบรรทัด ห่วงสัน และมุมกระดาษเอง)
	_paper = NotebookPage.new()
	_paper.custom_minimum_size = PAGE_SIZE
	_book.add_child(_paper)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 66)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_paper.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	_page_label = _label(18, INK_SOFT, true)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_page_label)

	_title = _label(30, INK, true)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_title)
	_file_label = _label(15, INK_SOFT, false)
	root.add_child(_file_label)

	_body = _label(24, INK, false)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_constant_override("line_spacing", 14)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_body)

	_seal = _make_seal()
	root.add_child(_seal)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	root.add_child(bar)
	_prev = _page_button("◀ หน้าก่อน")
	_prev.pressed.connect(func() -> void: turn(-1))
	bar.add_child(_prev)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	_close = _page_button("ปิดสมุด")
	_close.pressed.connect(close)
	bar.add_child(_close)
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer2)
	_next = _page_button("หน้าถัดไป ▶")
	_next.pressed.connect(func() -> void: turn(1))
	bar.add_child(_next)


func _make_seal() -> Control:
	var holder := HBoxContainer.new()
	holder.alignment = BoxContainer.ALIGNMENT_END
	var seal := PanelContainer.new()
	seal.custom_minimum_size = Vector2(84, 84)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("9e1d1d")
	style.border_color = Color("6e1010")
	style.set_border_width_all(4)
	style.set_corner_radius_all(42)
	seal.add_theme_stylebox_override("panel", style)
	var text := _label(16, Color("ffe2b0"), true)
	text.text = "ตรา\nหอคอย"
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	seal.add_child(text)
	seal.rotation_degrees = -8.0
	holder.add_child(seal)
	return holder


func _page_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 42)
	button.add_theme_font_size_override("font_size", 18)
	if ResourceLoader.exists(FONT_BOLD):
		button.add_theme_font_override("font", load(FONT_BOLD))
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", PAPER)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("8a5427") if state in ["hover", "focus"] else LEATHER
		box.set_corner_radius_all(8)
		box.content_margin_left = 14
		box.content_margin_right = 14
		box.content_margin_top = 6
		box.content_margin_bottom = 6
		button.add_theme_stylebox_override(state, box)
	return button


func _label(font_size: int, color: Color, bold: bool) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	var path := FONT_BOLD if bold else FONT_REGULAR
	if ResourceLoader.exists(path):
		label.add_theme_font_override("font", load(path))
	return label


## หน้ากระดาษ: พื้นครีม เส้นบรรทัดจาง ห่วงสันสีแดงด้านซ้าย ขอบขวาเข้มลง และมุมกระดาษพับขวาล่าง
class NotebookPage:
	extends Control

	var line_start := 132.0
	var line_step := 41.0

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), ScrollReaderView.PAPER)
		draw_rect(Rect2(size.x - 14, 0, 14, size.y), ScrollReaderView.PAPER_EDGE)
		var y := line_start
		while y < size.y - 70.0:
			draw_line(Vector2(56, y), Vector2(size.x - 26, y), ScrollReaderView.RULED, 1.0)
			y += line_step
		draw_line(Vector2(48, 0), Vector2(48, size.y), Color(ScrollReaderView.RING, 0.35), 2.0)
		var ring_y := 22.0
		while ring_y < size.y - 16.0:
			draw_rect(Rect2(10, ring_y, 22, 7), ScrollReaderView.RING)
			draw_circle(Vector2(30, ring_y + 3.5), 4.0, Color("7a1712"))
			ring_y += 34.0
		var corner := PackedVector2Array([Vector2(size.x - 40, size.y), Vector2(size.x, size.y - 40), Vector2(size.x, size.y)])
		draw_colored_polygon(corner, Color("cdbd92"))
