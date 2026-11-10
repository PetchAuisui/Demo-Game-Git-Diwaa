class_name PlayerAvatar
extends PanelContainer
## รูปโปรไฟล์ผู้เล่นแบบวงกลม ใช้ร่วมกันทุกที่: ปุ่มเมนูบัญชี, หัวเมนูบัญชี, หน้าบัญชี (และในอนาคต เช่น ตารางอันดับ)
## ตอนนี้แสดงอักษรตัวแรกของชื่อในเกม
##
## วิธีใช้: วาง player_avatar.tscn แล้วตั้งค่าใน Inspector
##   diameter / font_size        ขนาดวงกลมและตัวอักษร
##   follow_session = true       แสดงผู้เล่นที่ล็อกอินอยู่ และอัปเดตเองเมื่อชื่อเปลี่ยน (ค่าเริ่มต้น)
##   follow_session = false      เรียก show_name("ชื่อ") เอง เช่น แสดงผู้เล่นคนอื่นในตารางอันดับ
##   กลุ่ม "สี"                   สีพื้น / ขอบ / ตัวอักษร
##
## วันที่มีรูปโปรไฟล์จริง: แก้ที่ไฟล์นี้ไฟล์เดียว ทุกหน้าเปลี่ยนตามเอง
##   - โหลดรูปแล้วเรียก set_picture(texture) รูปจะถูกตัดเป็นวงกลมให้เอง (clip_children)
##   - set_picture(null) = กลับไปแสดงตัวอักษร (ใช้ตอนโหลดรูปไม่สำเร็จ หรือผู้เล่นไม่มีรูป)
##   - ความปลอดภัย: รูปต้องมาจาก server ของเราผ่าน PlayerSession เท่านั้น ห้ามโหลดจาก URL ที่ผู้เล่นตั้งเอง

@export var diameter := 56.0:
	set(value):
		diameter = value
		custom_minimum_size = Vector2(value, value)
@export var font_size := 26
@export var follow_session := true

@export_group("สี")
@export var bg_color := Color("fdf5e6")
@export var border_color := Color("b6a07f")
@export var border_width := 2
@export var text_color := Color("2c241d")

var _initial: Label
var _picture: TextureRect


func _ready() -> void:
	_initial = get_node("%InitialLabel") as Label
	_picture = get_node("%Picture") as TextureRect
	custom_minimum_size = Vector2(diameter, diameter)
	_apply_style()
	if follow_session:
		PlayerSession.session_changed.connect(_show_current_player)
		_show_current_player()


## แสดงตัวอักษรแรกของชื่อ (ชื่อว่าง = "?")
func show_name(display_name: String) -> void:
	var trimmed := display_name.strip_edges()
	_initial.text = trimmed.left(1).to_upper() if not trimmed.is_empty() else "?"
	set_picture(null)


## ใส่รูปโปรไฟล์ (เผื่ออนาคต) / null = แสดงตัวอักษรแทน
func set_picture(texture: Texture2D) -> void:
	_picture.texture = texture
	_picture.visible = texture != null
	_initial.visible = texture == null


func _show_current_player() -> void:
	show_name(PlayerSession.get_display_name())


func _apply_style() -> void:
	var circle := StyleBoxFlat.new()
	circle.bg_color = bg_color
	circle.border_color = border_color
	circle.set_border_width_all(border_width)
	circle.set_corner_radius_all(999)
	add_theme_stylebox_override("panel", circle)
	_initial.add_theme_font_size_override("font_size", font_size)
	_initial.add_theme_color_override("font_color", text_color)
