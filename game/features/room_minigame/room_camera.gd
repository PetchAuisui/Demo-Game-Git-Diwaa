class_name RoomCamera
extends Control
## กล้องของห้องตอนยังไม่มีคัมภีร์ (ด่าน git init / ก่อน clone): ซูมใกล้ 1.5 เท่าที่แท่นวางคัมภีร์ที่ว่างเปล่า เลื่อนช้า ๆ
## ภาพที่เห็นคือห้องจริงที่อยู่ข้างหลัง (screen texture ขยาย) — ห้องหลับใหลตรงหน้า ไม่ใช่ภาพอีกภาพหนึ่ง
## ห้องตื่นขึ้นระหว่างที่กล้องถอยกลับเป็นขนาดจริง แล้วกล้องก็หายไปโดยไม่มีรอยต่อ
## ไม่รับเมาส์

const ZOOM_IN := 1.5
const FONT_BOLD := "res://assets/fonts/ChakraPetch-Bold.ttf"
const SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec2 rect_size = vec2(1.0);
uniform vec2 focus = vec2(0.0);
uniform vec2 target = vec2(0.0);
uniform float zoom = 1.0;
uniform float dark = 0.0;
void fragment() {
	vec2 local = UV * rect_size;
	vec2 world = focus + (local - target) / zoom;
	// ขนาดของสี่เหลี่ยมนี้ในพิกัด SCREEN_UV (คงที่ทั้งสี่เหลี่ยม) — แปลงพิกัดห้องเป็นตำแหน่งบนจอ
	vec2 span = vec2(dFdx(SCREEN_UV.x) / dFdx(UV.x), dFdy(SCREEN_UV.y) / dFdy(UV.y));
	vec4 c = texture(screen_tex, SCREEN_UV + (world - local) / rect_size * span);
	// ห้องมืด: ขอบภาพมืดลง เหลือแสงสลัวรอบแท่นวางคัมภีร์
	float edge = smoothstep(0.25, 0.8, distance(local / rect_size, target / rect_size));
	COLOR = vec4(c.rgb * (1.0 - dark * edge * 0.45), 1.0);
}
"""

## จุดโฟกัส: ฐานของแท่นวางคัมภีร์ (พิกัดของ control นี้) — RoomView ตั้งให้
var focus := Vector2.ZERO

var _backdrop: ColorRect
var _material: ShaderMaterial
var _caption: Label
var _zoom := ZOOM_IN
var _shift := 0.0      # 0 = โฟกัสอยู่กลางภาพ · 1 = โฟกัสอยู่ตำแหน่งจริง (ซูมออกเสร็จ)
var _dark := 1.0
var _time := 0.0
var _leaving := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_material = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = SHADER
	_material.shader = shader
	_backdrop = ColorRect.new()
	_backdrop.material = _material
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)
	_caption = Label.new()
	_caption.text = "ห้องนี้หลับใหล — ไม่มีคัมภีร์ให้จดจำสิ่งใด"
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.add_theme_font_size_override("font_size", 16)
	_caption.add_theme_color_override("font_color", Color("c9b6ff"))
	_caption.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_caption.add_theme_constant_override("outline_size", 4)
	if ResourceLoader.exists(FONT_BOLD):
		_caption.add_theme_font_override("font", load(FONT_BOLD))
	add_child(_caption)


func close_up() -> void:
	_leaving = false
	_zoom = ZOOM_IN
	_shift = 0.0
	_dark = 1.0
	_caption.visible = true
	modulate.a = 1.0
	visible = true


## กล้องถอยกลับเป็นขนาดจริงพร้อมกับที่ห้องตื่น แล้วซ่อนตัว (ภาพตรงกับห้องจริงทุกพิกเซลแล้ว)
func pull_back(seconds: float) -> void:
	if not visible or _leaving:
		return
	_leaving = true
	_caption.visible = false
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "_zoom", 1.0, seconds).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "_shift", 1.0, seconds).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "_dark", 0.0, seconds)
	tw.chain().tween_callback(func() -> void: visible = false)


func is_close() -> bool:
	return visible and not _leaving


## จุดในห้อง (พิกัดของ control นี้ที่สเกล 1) อยู่ตรงไหนบนจอตอนนี้ — ใช้เล็งเอฟเฟกต์ที่วาดทับกล้อง
func to_view(point: Vector2) -> Vector2:
	if not visible:
		return point
	return _target() + (point - focus) * _zoom


func _target() -> Vector2:
	var drift := Vector2(sin(_time * 0.4) * 6.0, sin(_time * 0.3) * 3.0) * (1.0 - _shift)
	var t := (size * Vector2(0.5, 0.78) + drift).lerp(focus, _shift)
	# กล้องไม่ออกนอกห้อง (ไม่เห็นกรอบหรือลานโกลาหลแบบขยาย)
	t.x = clampf(t.x, size.x - (size.x - focus.x) * _zoom, focus.x * _zoom)
	t.y = clampf(t.y, size.y - (size.y - focus.y) * _zoom, focus.y * _zoom)
	return t


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	_backdrop.size = size
	_caption.position = Vector2(0, 6)
	_caption.size = Vector2(size.x, 24)
	_material.set_shader_parameter("rect_size", size)
	_material.set_shader_parameter("focus", focus)
	_material.set_shader_parameter("target", _target())
	_material.set_shader_parameter("zoom", _zoom)
	_material.set_shader_parameter("dark", _dark)
