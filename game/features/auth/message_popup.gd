class_name MessagePopup
extends Control
## หน้าต่างข้อความสั้นๆ ลอยทับหน้าปัจจุบัน มีปุ่ม "ตกลง" ปุ่มเดียว (กด Enter / Esc ก็ปิดได้)
## เปิด:  var popup := MessagePopup.open(get_tree(), "หัวข้อ", "ข้อความ")
## รอปิด: if popup != null: await popup.closed
## ใช้ Label ธรรมดา (ไม่ใช่ RichTextLabel) และห้ามส่งข้อความดิบจาก server มาแสดง

## ส่งครั้งเดียวตอนหน้าต่างปิด ไม่ว่าปิดทางไหน (ตกลง / Esc / เปลี่ยนหน้า) คนที่รออยู่จะไม่ค้าง
signal closed

const SCENE_PATH := "res://features/auth/message_popup.tscn"

var _title := ""
var _message := ""
var _closed := false


static func open(tree: SceneTree, title: String, message: String) -> MessagePopup:
	var scene := load(SCENE_PATH) as PackedScene
	if scene == null or tree.current_scene == null:
		push_error("MessagePopup: could not open the popup.")
		return null
	var popup := scene.instantiate() as MessagePopup
	popup._title = title
	popup._message = message
	tree.current_scene.add_child(popup)
	return popup


func _ready() -> void:
	(get_node("%TitleLabel") as Label).text = _title
	(get_node("%MessageLabel") as Label).text = _message

	var ok_btn := get_node("%OkBtn") as Button
	ok_btn.add_theme_stylebox_override("normal", AuthThemeTokens.create_button_style(AuthThemeTokens.BUTTON_BG))
	ok_btn.add_theme_stylebox_override("hover", AuthThemeTokens.create_button_style(AuthThemeTokens.BUTTON_HOVER_BG))
	ok_btn.add_theme_stylebox_override("pressed", AuthThemeTokens.create_button_style(AuthThemeTokens.BUTTON_PRESSED_BG))
	ok_btn.add_theme_color_override("font_color", AuthThemeTokens.BUTTON_TEXT)
	ok_btn.add_theme_color_override("font_hover_color", AuthThemeTokens.BUTTON_TEXT)
	ok_btn.add_theme_color_override("font_pressed_color", AuthThemeTokens.BUTTON_TEXT)
	ok_btn.pressed.connect(_finish)
	ok_btn.grab_focus()  # กด Enter แล้วปิดได้ทันที


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish()


func _exit_tree() -> void:
	if not _closed:
		_closed = true
		closed.emit()


func _finish() -> void:
	if _closed:
		return
	_closed = true
	closed.emit()
	queue_free()
