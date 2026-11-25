class_name FragmentCeremony
extends Control
## ฉากรับเศษคัมภีร์: ลำแสงทองพุ่งลงกลางจอ เศษคริสตัลลอยขึ้น ข้อความของปรมาจารย์ค่อย ๆ ปรากฏ
## แล้วช่องเก็บเศษ 12 ช่องสว่างขึ้นทีละช่องจนถึงชิ้นใหม่ — คลิกที่ไหนก็ได้ หรือรอสักครู่เพื่อปิด
## ไม่เปลี่ยนเนื้อเรื่อง: ข้อความมาจาก FragmentLedger ซึ่งเทสต์ผูกไว้กับไฟล์ด่าน

signal finished

const FONT_BOLD := "res://assets/fonts/ChakraPetch-Bold.ttf"
const FONT_REGULAR := "res://assets/fonts/ChakraPetch-Regular.ttf"
const GOLD := Color("ffd36b")
const HOLD_SECONDS := 4.2

var _number := 0
var _owned := 0
var _font_bold: Font
var _font_regular: Font
var _dim: ColorRect
var _fx: Node2D
var _title: Label
var _quote: Label
var _slots: Array[ColorRect] = []
var _closing := false


static func play(parent: Node, number: int, owned_after: int) -> FragmentCeremony:
	var ceremony := FragmentCeremony.new()
	ceremony._number = number
	ceremony._owned = owned_after
	parent.add_child(ceremony)
	return ceremony


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font_bold = load(FONT_BOLD) if ResourceLoader.exists(FONT_BOLD) else null
	_font_regular = load(FONT_REGULAR) if ResourceLoader.exists(FONT_REGULAR) else null
	_dim = ColorRect.new()
	_dim.color = Color(0.03, 0.02, 0.08, 0.0)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	_fx = Node2D.new()
	add_child(_fx)
	_title = _label(_font_bold, 40, GOLD)
	_quote = _label(_font_regular, 30, Color("fff3d6"))
	add_child(_title)
	add_child(_quote)
	_title.text = "ได้รับเศษคัมภีร์ชิ้นที่ %d" % _number
	_quote.text = "\"%s\"" % FragmentLedger.text_of(_number)
	_quote.visible_ratio = 0.0
	_title.modulate.a = 0.0
	_build_slots()
	_run.call_deferred()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and (event as InputEventKey).keycode in [KEY_ENTER, KEY_ESCAPE, KEY_SPACE]:
		_close()
		get_viewport().set_input_as_handled()


func _unit() -> float:
	return maxf(2.0, round(size.y / 260.0))


func _run() -> void:
	var center := size * Vector2(0.5, 0.42)
	var unit := _unit()
	create_tween().tween_property(_dim, "color:a", 0.72, 0.25)
	# ลำแสงทองฟาดลงมาก่อน (เหตุ) แล้วเศษคริสตัลลอยขึ้นจากจุดที่แสงกระทบพื้น (ผล)
	var beam := PixelFx.spawn(_fx, "fragment_beam", center + Vector2(0, 40 * unit), unit)
	if beam != null:
		beam.scale = Vector2(unit, 0.0)
		var tw := beam.create_tween()
		tw.tween_property(beam, "scale", Vector2.ONE * unit, 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	PixelFx.hit_stop(get_tree(), 0.06)
	PixelFx.spawn(_fx, "commit_sparkle", center + Vector2(0, 40 * unit), unit * 1.4)
	var shard := PixelFx.spawn(_fx, "fragment_icon", center + Vector2(0, 40 * unit), unit * 1.6)
	if shard != null:
		var rise := shard.create_tween()
		rise.tween_property(shard, "position:y", center.y + 6 * unit, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	PixelFx.spawn(_fx, "confetti", Vector2(size.x * 0.3, size.y), unit)
	PixelFx.spawn(_fx, "confetti", Vector2(size.x * 0.7, size.y), unit, 0.0, true)
	_title.position = Vector2(0, center.y + 56 * unit)
	_title.size = Vector2(size.x, 60)
	_quote.position = Vector2(0, _title.position.y + 58)
	_quote.size = Vector2(size.x, 50)
	var text := create_tween()
	text.tween_interval(0.35)
	text.tween_property(_title, "modulate:a", 1.0, 0.25)
	text.tween_property(_quote, "visible_ratio", 1.0, clampf(_quote.text.length() * 0.05, 0.6, 1.6))
	text.tween_callback(_light_slots)
	text.tween_interval(HOLD_SECONDS)
	text.tween_callback(_close)


## ช่องเก็บเศษ 12 ช่อง: ที่มีอยู่แล้วเป็นทอง ชิ้นใหม่กะพริบแล้วติดสว่าง
func _build_slots() -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_top = -110
	row.offset_bottom = -80
	row.offset_left = -300
	row.offset_right = 300
	add_child(row)
	for i in FragmentLedger.TOTAL:
		var slot := ColorRect.new()
		slot.custom_minimum_size = Vector2(26, 34)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.color = GOLD if i < _owned - 1 else Color(1, 1, 1, 0.12)
		row.add_child(slot)
		_slots.append(slot)
	var count := _label(_font_bold, 24, GOLD)
	count.text = "เศษคัมภีร์ %d/%d" % [_owned, FragmentLedger.TOTAL]
	count.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	count.offset_top = -70
	count.offset_bottom = -36
	count.offset_left = -300
	count.offset_right = 300
	add_child(count)


func _light_slots() -> void:
	var index := _owned - 1
	if index < 0 or index >= _slots.size():
		return
	var slot := _slots[index]
	var tw := slot.create_tween()
	for i in 3:
		tw.tween_property(slot, "color", Color.WHITE, 0.08)
		tw.tween_property(slot, "color", GOLD, 0.12)
	var at := slot.global_position - global_position + slot.size * Vector2(0.5, 1.0)
	PixelFx.spawn(_fx, "stage_sparkle", at, _unit() * 0.6)


func _close() -> void:
	if _closing:
		return
	_closing = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void:
		finished.emit()
		queue_free())


func _label(font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 6)
	if font != null:
		label.add_theme_font_override("font", font)
	return label
