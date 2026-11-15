class_name MessagePopup
extends Control
## หน้าต่างข้อความสั้นๆ ลอยทับหน้าปัจจุบัน มี 2 แบบ
## 1. แจ้งผล (ปุ่ม "ตกลง" ปุ่มเดียว):
##      var popup := MessagePopup.open(get_tree(), "หัวข้อ", "ข้อความ")
##      if popup != null: await popup.closed
## 2. ถามยืนยัน (ปุ่ม "ยกเลิก" + ปุ่มยืนยันที่ตั้งชื่อตามการกระทำ เช่น "ออกจากระบบ"):
##      var popup := MessagePopup.open_confirm(parent, "หัวข้อ", "ข้อความ", "ออกจากระบบ", "ยกเลิก", true)
##      (พารามิเตอร์ตัวสุดท้าย danger = true ทำให้ปุ่มยืนยันเป็นสีแดง)
##      if popup != null: var confirmed: bool = await popup.closed
##    โฟกัสเริ่มที่ "ยกเลิก" และกด Esc = ยกเลิก กันกดยืนยันโดยไม่ตั้งใจ
## ใช้ Label ธรรมดา (ไม่ใช่ RichTextLabel) และห้ามส่งข้อความดิบจาก server มาแสดง

## ส่งครั้งเดียวตอนหน้าต่างปิด ไม่ว่าปิดทางไหน (ปุ่ม / Esc / เปลี่ยนหน้า) คนที่รออยู่จะไม่ค้าง
## confirmed = true เฉพาะตอนกดปุ่มยืนยัน (แบบแจ้งผล กด "ตกลง" ก็เป็น true)
signal closed(confirmed: bool)

const SCENE_PATH := "res://features/auth/message_popup.tscn"

var _title := ""
var _message := ""
var _ok_text := "ตกลง"
var _cancel_text := ""  # ว่าง = ไม่มีปุ่มยกเลิก (แบบแจ้งผล)
var _danger := false  # true = ปุ่มยืนยันเป็นสีแดง (การกระทำที่มีความเสี่ยง เช่น ออกจากระบบ)
var _closed := false


static func open(tree: SceneTree, title: String, message: String) -> MessagePopup:
	if tree.current_scene == null:
		push_error("MessagePopup: could not open the popup.")
		return null
	return _spawn(tree.current_scene, title, message, "ตกลง", "")


## แจ้งข้อมูล (ปุ่ม "ตกลง") แต่วางใน parent ที่กำหนด เช่น ในหน้าต่างที่ลอยอยู่ ให้ขึ้นบนสุด
static func open_info(parent: Node, title: String, message: String) -> MessagePopup:
	return _spawn(parent, title, message, "ตกลง", "")


## parent: ที่จะวางหน้าต่าง (เช่น CanvasLayer ของเมนู เพื่อให้อยู่บนสุดของหน้า)
static func open_confirm(parent: Node, title: String, message: String, confirm_text: String, cancel_text: String = "ยกเลิก", danger: bool = false) -> MessagePopup:
	return _spawn(parent, title, message, confirm_text, cancel_text, danger)


static func _spawn(parent: Node, title: String, message: String, ok_text: String, cancel_text: String, danger: bool = false) -> MessagePopup:
	var scene := load(SCENE_PATH) as PackedScene
	if scene == null or parent == null:
		push_error("MessagePopup: could not open the popup.")
		return null
	var popup := scene.instantiate() as MessagePopup
	popup._title = title
	popup._message = message
	popup._ok_text = ok_text
	popup._cancel_text = cancel_text
	popup._danger = danger
	parent.add_child(popup)
	return popup


func _ready() -> void:
	(get_node("%TitleLabel") as Label).text = _title
	(get_node("%MessageLabel") as Label).text = _message

	var ok_btn := get_node("%OkBtn") as Button
	if _danger:
		AuthThemeTokens.style_danger_button(ok_btn)
	else:
		AuthThemeTokens.style_button(ok_btn)
	ok_btn.text = _ok_text
	ok_btn.pressed.connect(_finish.bind(true))

	var cancel_btn := get_node("%CancelBtn") as Button
	if _cancel_text.is_empty():
		ok_btn.grab_focus()  # แบบแจ้งผล: กด Enter แล้วปิดได้ทันที
		return
	AuthThemeTokens.style_button(cancel_btn, AuthThemeTokens.INPUT_BG, Color.WHITE, AuthThemeTokens.CARD_BORDER)
	cancel_btn.text = _cancel_text
	cancel_btn.visible = true
	cancel_btn.pressed.connect(_finish.bind(false))
	cancel_btn.grab_focus()  # แบบถามยืนยัน: เริ่มที่ปุ่มที่ปลอดภัย


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish(false)


func _exit_tree() -> void:
	# ถูกปิดโดยไม่ผ่านปุ่ม (เช่น เปลี่ยนหน้า) ถือว่ายกเลิก
	if not _closed:
		_closed = true
		closed.emit(false)


func _finish(confirmed: bool) -> void:
	if _closed:
		return
	_closed = true
	closed.emit(confirmed)
	queue_free()
