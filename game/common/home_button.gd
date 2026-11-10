class_name HomeButton
extends Button
## ปุ่มวงกลมไอคอนบ้าน กดแล้วกลับหน้าหลัก (ถามยืนยันก่อนได้)
##
## วิธีใช้ / วิธีแก้ (ไม่ต้องแก้โค้ดในไฟล์นี้):
##   - ใส่ในหน้าไหนก็ได้: ลาก res://common/home_button.tscn ไปวางในแถบบนของหน้านั้น
##   - ย้ายตำแหน่ง: ลาก node HomeButton ไปที่อื่นใน Scene tree (ตอนนี้อยู่ซ้ายสุดของแถบบนหน้าเล่นด่าน)
##   - ระยะห่างจากโลโก้: ปรับ custom_minimum_size ของ node HomeGap ใน top_bar_panel.tscn
##   - หน้าปลายทาง / ข้อความถามยืนยัน / สี / ขนาด: แก้ค่าใน Inspector (ค่าด้านล่างที่มี @export ทั้งหมด)
##   - คำที่ขึ้นตอนชี้: tooltip_text ใน Inspector
##   - ไอคอน: เปลี่ยนไฟล์ res://assets/icons/home.svg หรือเปลี่ยน icon ใน Inspector (ใช้รูปเส้นสีขาว ระบบจะย้อมสีให้)
##
## หมายเหตุ: ปุ่มนี้แค่เปลี่ยนหน้า ไม่ได้ล้างสถานะของด่าน (GameProgressManager) ถ้าต้องการให้ล้าง ให้คนทำส่วนเล่นด่านตัดสินใจ

## หน้าที่จะไปเมื่อกด
@export_file("*.tscn") var target_scene := "res://features/start/start_view.tscn"

@export_group("ถามยืนยันก่อนออก")
## true = ถามก่อน (ใช้กับหน้าที่ออกแล้วเสียความคืบหน้า เช่น หน้าเล่นด่าน)
@export var confirm_before_leave := true
@export var confirm_title := "กลับหน้าหลักตอนนี้?"
@export_multiline var confirm_message := "ความคืบหน้าที่ยังไม่บันทึกจะหาย"
@export var confirm_button_text := "กลับหน้าหลัก"

@export_group("หน้าตา")
@export var button_size := 48.0
@export var bg_color := Color("fdf5e6")
@export var hover_bg_color := Color.WHITE
@export var border_color := Color("b6a07f")
@export var focus_color := Color("705335")
@export var icon_color := Color("2c241d")
## ระยะจากขอบวงกลมถึงไอคอน (ยิ่งมาก ไอคอนยิ่งเล็ก)
@export var icon_padding := 11

var _asking := false


func _ready() -> void:
	custom_minimum_size = Vector2(button_size, button_size)
	_apply_theme()
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	if _asking:
		return
	if not confirm_before_leave:
		_go()
		return
	_asking = true
	# วางหน้าต่างยืนยันในชั้นบนสุดของจอ ไม่ให้ส่วนอื่นของหน้าบังไว้
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var popup := MessagePopup.open_confirm(layer, confirm_title, confirm_message, confirm_button_text)
	var confirmed := false
	if popup != null:
		confirmed = await popup.closed
	if is_instance_valid(layer):
		layer.queue_free()
	_asking = false
	if not is_inside_tree():
		return
	if confirmed:
		_go()
	else:
		grab_focus()


func _go() -> void:
	if not ResourceLoader.exists(target_scene):
		push_error("HomeButton: target scene not found: %s" % target_scene)
		return
	Engine.time_scale = 1.0  # บางหน้าปรับความเร็วเวลาไว้ ทำเหมือนที่หน้าเล่นด่านทำก่อนเปลี่ยนฉาก
	get_tree().change_scene_to_file(target_scene)


func _apply_theme() -> void:
	add_theme_stylebox_override("normal", _circle(bg_color))
	add_theme_stylebox_override("pressed", _circle(bg_color))
	add_theme_stylebox_override("hover", _circle(hover_bg_color))
	var ring := StyleBoxFlat.new()
	ring.draw_center = false
	ring.border_color = focus_color
	ring.set_border_width_all(3)
	ring.set_corner_radius_all(999)
	add_theme_stylebox_override("focus", ring)
	for color_name in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
		add_theme_color_override(color_name, icon_color)


func _circle(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(999)
	style.set_content_margin_all(icon_padding)
	return style
