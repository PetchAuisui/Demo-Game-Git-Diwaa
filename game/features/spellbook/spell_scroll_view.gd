class_name SpellScrollView
extends Control
## หน้าต่าง "ม้วนคาถาใหม่" (ตอนเริ่มขั้นที่สอนคาถา) และ "สมุดคาถา" (เปิดดูคาถาที่เรียนแล้วได้ตลอด)
## แต่ละคาถาแสดง: ชื่อในโลกเวท · คำสั่งจริง · ผลในโลก · ความหมายใน Git · ตัวอย่าง
## ปิดด้วยปุ่ม / Enter / Esc แล้วส่งสัญญาณ closed

signal closed

const FONT_BOLD := "res://assets/fonts/ChakraPetch-Bold.ttf"
const FONT_REGULAR := "res://assets/fonts/ChakraPetch-Regular.ttf"
const PAPER := "res://assets/cutscene/props/khampri/paper.png"
const TOME := "res://assets/cutscene/props/khampri/Khampri.png"

const INK := Color("3b2614")
const INK_SOFT := Color("6b4a2c")
const GOLD := Color("b8862b")
const COMMAND := Color("1f6b4a")
const PARCHMENT := Color("f1dfb8")
const PARCHMENT_EDGE := Color("a9824d")

var _font_bold: Font
var _font_regular: Font
var _dim: ColorRect
var _panel: PanelContainer
var _title: Label
var _subtitle: Label
var _list: VBoxContainer
var _scroll: ScrollContainer
var _button: Button
var _icon: TextureRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font_bold = load(FONT_BOLD) if ResourceLoader.exists(FONT_BOLD) else null
	_font_regular = load(FONT_REGULAR) if ResourceLoader.exists(FONT_REGULAR) else null
	_build()
	visible = false


## ม้วนคาถาใหม่ที่เพิ่งได้รับ (แสดงทุกคาถาในม้วนพร้อมกัน)
func show_new_spells(ids: Array[String], level: int) -> void:
	_title.text = "ได้รับม้วนคาถาใหม่!"
	_subtitle.text = "ด่านที่ %d · คาถาเหล่านี้ถูกเก็บลงสมุดคาถาแล้ว (เปิดดูได้ตลอดจากปุ่ม \"คาถา\" หรือพิมพ์ spells)" % level
	_button.text = "รับคาถา"
	_icon.texture = load(PAPER) if ResourceLoader.exists(PAPER) else null
	_fill(ids)
	_open()


## สมุดคาถา: ทุกคาถาที่เรียนมาแล้ว คาถาล่าสุดอยู่บนสุด
func show_spellbook(ids: Array[String]) -> void:
	_title.text = "สมุดคาถา"
	_subtitle.text = "คาถาที่นายเรียนมาแล้ว %d บท — ด่านนี้ต้องเลือกเองว่าจะใช้บทไหน เมื่อไร" % ids.size()
	_button.text = "ปิดสมุด"
	_icon.texture = load(TOME) if ResourceLoader.exists(TOME) else null
	var newest_first: Array[String] = ids.duplicate()
	newest_first.reverse()
	_fill(newest_first)
	_open()


func close() -> void:
	if not visible:
		return
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func() -> void:
		visible = false
		closed.emit())


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		close()


func _open() -> void:
	visible = true
	modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	_panel.pivot_offset = _panel.size * 0.5
	_scroll.scroll_vertical = 0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_button.grab_focus.call_deferred()


func _fill(ids: Array[String]) -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	for id in ids:
		if SpellCatalog.has_spell(id):
			_list.add_child(_make_card(SpellCatalog.spell(id)))
	_fit_height.call_deferred()


## พื้นที่รายการสูงเท่าเนื้อหา (ไม่เกิน MAX_LIST_RATIO ของจอ แล้วค่อยเลื่อน) — ม้วนคาถาสั้นจึงไม่มีช่องว่างเปล่า
const MAX_LIST_RATIO := 0.58


func _fit_height() -> void:
	var content := _list.get_combined_minimum_size().y
	var limit := get_viewport_rect().size.y * MAX_LIST_RATIO
	_scroll.custom_minimum_size.y = clampf(content, 120.0, limit)
	_panel.reset_size()
	_panel.pivot_offset = _panel.size * 0.5


func _build() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.01, 0.05, 0.72)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(980, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = PARCHMENT
	style.border_color = PARCHMENT_EDGE
	style.set_border_width_all(6)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(26)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 24
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	_panel.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(72, 72)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	header.add_child(_icon)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	_title = _label(36, INK, true)
	titles.add_child(_title)
	_subtitle = _label(19, INK_SOFT, false)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(_subtitle)

	var rule := ColorRect.new()
	rule.color = Color(PARCHMENT_EDGE, 0.6)
	rule.custom_minimum_size = Vector2(0, 2)
	root.add_child(rule)

	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(0, 160)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 14)
	_scroll.add_child(_list)

	_button = Button.new()
	_button.custom_minimum_size = Vector2(260, 54)
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button.add_theme_font_size_override("font_size", 22)
	if _font_bold != null:
		_button.add_theme_font_override("font", _font_bold)
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


func _make_card(spell: Dictionary) -> Control:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.35)
	style.border_color = Color(PARCHMENT_EDGE, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(16)
	card.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 14)
	box.add_child(name_row)
	var name := _label(26, GOLD.darkened(0.25), true)
	name.text = "✦ " + str(spell["name"])
	name_row.add_child(name)
	var command := _label(24, COMMAND, true)
	command.text = str(spell["command"])
	name_row.add_child(command)

	var does := _label(20, INK, false)
	does.text = str(spell["does"])
	does.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(does)

	var real := _label(16, INK_SOFT, false)
	real.text = "ใน Git: " + str(spell["real"])
	real.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(real)

	var example := PanelContainer.new()
	var ex_style := StyleBoxFlat.new()
	ex_style.bg_color = Color("1c140c")
	ex_style.set_corner_radius_all(8)
	ex_style.set_content_margin_all(10)
	example.add_theme_stylebox_override("panel", ex_style)
	var ex_label := _label(19, Color("8ff0b8"), false)
	ex_label.text = "ตัวอย่าง  $ " + str(spell["example"])
	example.add_child(ex_label)
	box.add_child(example)
	return card


func _label(font_size: int, color: Color, bold: bool) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	var font := _font_bold if bold else _font_regular
	if font != null:
		label.add_theme_font_override("font", font)
	return label
