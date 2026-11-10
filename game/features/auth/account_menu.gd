class_name AccountMenu
extends Button
## ปุ่มบัญชีมุมขวาบน (อยู่ใน StartTopBar) กดแล้วเปิดเมนู: ชื่อผู้เล่น / จัดการบัญชี / ออกจากระบบ
## ซ่อนตัวเองเมื่อยังไม่มีผู้เล่น เช่น ที่หน้าเข้าสู่ระบบ (ใช้ StartTopBar ตัวเดียวกัน)
## เปิดเมนูแล้ว: กดที่อื่นหรือกด Esc = ปิด
##
## ความปลอดภัย:
## 1. อีเมล: ขอจาก server ตอนเปิดเมนูครั้งแรก (ออนไลน์เท่านั้น) เก็บแค่ในตัวแปร ไม่บันทึกลงไฟล์
##    แสดงแบบปิดบังเสมอ (ไม่บอกความยาว) กดรูปตาถึงเห็นเต็ม และปิดเมนูแล้วกลับไปปิดบังเอง กันหลุดตอนสตรีม / แคปจอ
## 2. ชื่อที่มาจาก server แสดงด้วย Label ธรรมดาเท่านั้น ไม่ตีความเป็นคำสั่งจัดรูปแบบ
## 3. ปุ่มนี้แค่พาไปหน้าอื่น ไม่ได้ตัดสินสิทธิ์อะไร (server ตรวจ token เองทุกครั้ง)

# ระยะห่างระหว่างปุ่มกับเมนู และระยะห่างจากขอบจอ (pixel)
const PANEL_GAP := 8.0
const SCREEN_MARGIN := 8.0

var _panel: PanelContainer
var _avatar: Label
var _name_label: Label
var _sub_label: Label
var _manage_btn: Button
var _sign_out_btn: Button
var _guest_hint: Label
var _email_row: HBoxContainer
var _email_label: Label
var _reveal_btn: Button

# อีเมลของบัญชีไหน (user id) ถ้าเปลี่ยนบัญชีหรือออกจากระบบ ลืมทิ้งทันที
var _email := ""
var _email_owner := ""
var _email_loading := false


func _ready() -> void:
	_panel = get_node("%Panel") as PanelContainer
	_avatar = get_node("%Avatar") as Label
	_name_label = get_node("%NameLabel") as Label
	_sub_label = get_node("%SubLabel") as Label
	_manage_btn = get_node("%ManageBtn") as Button
	_sign_out_btn = get_node("%SignOutBtn") as Button
	_guest_hint = get_node("%GuestHint") as Label
	_email_row = get_node("%EmailRow") as HBoxContainer
	_email_label = get_node("%EmailLabel") as Label
	_reveal_btn = get_node("%RevealEmailBtn") as Button
	_apply_theme()

	pressed.connect(_toggle)
	_manage_btn.pressed.connect(_on_manage_pressed)
	_sign_out_btn.pressed.connect(_on_sign_out_pressed)
	_reveal_btn.toggled.connect(func(_on: bool) -> void: _show_email())
	PlayerSession.session_changed.connect(_refresh)
	_refresh()


## อัปเดตตามสถานะผู้เล่นตอนนี้ (เรียกตอนเปิดหน้า และทุกครั้งที่ล็อกอิน / ออกจากระบบ / เปลี่ยนชื่อ)
func _refresh() -> void:
	visible = PlayerSession.has_player()
	if not visible:
		_close()
		return

	var display_name := PlayerSession.get_display_name()
	var initial := display_name.left(1).to_upper() if not display_name.is_empty() else "?"
	text = initial
	_avatar.text = initial
	_name_label.text = display_name

	var guest := PlayerSession.is_guest()
	# ไม่แสดงชื่อผู้ใช้: เป็นครึ่งหนึ่งของข้อมูลเข้าสู่ระบบ ไม่ควรโผล่ตอนสตรีม / แคปจอ (ตัวตนดูจากชื่อในเกม + อีเมลแบบปิดบังแทน)
	match PlayerSession.state:
		PlayerSession.State.GUEST:
			_sub_label.text = "เล่นแบบไม่ล็อกอิน"
		PlayerSession.State.OFFLINE:
			_sub_label.text = "ออฟไลน์"
		_:
			_sub_label.text = ""
	_sub_label.visible = not _sub_label.text.is_empty()

	# หน้าจัดการบัญชีต้องคุยกับ server จึงใช้ได้เฉพาะตอนออนไลน์
	_manage_btn.visible = PlayerSession.state == PlayerSession.State.ONLINE
	_sign_out_btn.text = "ออกจากโหมดไม่ล็อกอิน" if guest else "ออกจากระบบ"
	_guest_hint.visible = guest

	if PlayerSession.state != PlayerSession.State.ONLINE or _email_owner != PlayerSession.get_user_id():
		_email = ""
	_show_email()


func _toggle() -> void:
	if _panel.visible:
		_close()
	else:
		_open()


## วางเมนูใต้ปุ่ม ชิดขวาของปุ่ม และไม่ให้ล้นขอบจอ
func _open() -> void:
	_panel.visible = true
	_panel.reset_size()
	var anchor := get_global_rect()
	var panel_size := _panel.get_combined_minimum_size()
	var screen := get_viewport_rect().size
	var x := clampf(anchor.end.x - panel_size.x, SCREEN_MARGIN, maxf(SCREEN_MARGIN, screen.x - panel_size.x - SCREEN_MARGIN))
	_panel.position = Vector2(x, anchor.end.y + PANEL_GAP)
	if _manage_btn.visible:
		_manage_btn.grab_focus()
	else:
		_sign_out_btn.grab_focus()
	if _email.is_empty() and PlayerSession.state == PlayerSession.State.ONLINE:
		_load_email()


func _load_email() -> void:
	if _email_loading:
		return
	_email_loading = true
	var owner_id := PlayerSession.get_user_id()
	var email := await PlayerSession.fetch_email()
	_email_loading = false
	# ระหว่างรอ ออกจากระบบหรือเปลี่ยนบัญชีไปแล้ว: ทิ้งคำตอบนี้
	if not is_inside_tree() or PlayerSession.state != PlayerSession.State.ONLINE or PlayerSession.get_user_id() != owner_id:
		return
	_email = email
	_email_owner = owner_id
	_show_email()


## แสดงอีเมล: ปิดบังเป็นค่าเริ่มต้น กดรูปตาเพื่อดูเต็ม (ไม่มีอีเมล = ซ่อนทั้งแถว)
func _show_email() -> void:
	_email_row.visible = not _email.is_empty()
	var revealed := _reveal_btn.button_pressed
	_email_label.text = _email if revealed else _mask_email(_email)
	_reveal_btn.tooltip_text = "ซ่อนอีเมล" if revealed else "แสดงอีเมล"


## p•••@gmail.com: เหลือตัวแรกกับโดเมน และใช้ ••• เท่ากันทุกอีเมล ไม่บอกว่าชื่อยาวกี่ตัว
static func _mask_email(email: String) -> String:
	var at := email.rfind("@")
	if at <= 0:
		return "•••"
	return email.left(1) + "•••" + email.substr(at)


func _close() -> void:
	_panel.visible = false
	# ปิดเมนูแล้วกลับไปปิดบังอีเมลเสมอ
	_reveal_btn.set_pressed_no_signal(false)
	_show_email()


## เมนูเปิดอยู่: กด Esc หรือกดนอกเมนู = ปิดเมนู (และไม่ให้คลิกนั้นไปกดปุ่มข้างหลังโดยไม่ตั้งใจ)
func _input(event: InputEvent) -> void:
	if not _panel.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_close()
		grab_focus()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		var pos := (event as InputEventMouseButton).position
		if not _panel.get_global_rect().has_point(pos) and not get_global_rect().has_point(pos):
			_close()
			get_viewport().set_input_as_handled()


func _on_manage_pressed() -> void:
	_close()
	get_tree().change_scene_to_file(PlayerSession.ACCOUNT_SCENE)


## ออกจากระบบ (บัญชี) หรือออกจากโหมดไม่ล็อกอิน (guest) แล้วกลับหน้าเข้าสู่ระบบ
## guest: ไม่ลบอะไร ความคืบหน้าและชื่อยังอยู่ในเครื่อง / บัญชี: ลบการจดจำในเครื่องและแจ้ง server (ดู PlayerSession.sign_out)
func _on_sign_out_pressed() -> void:
	_close()
	PlayerSession.sign_out()
	get_tree().change_scene_to_file(PlayerSession.AUTH_SCENE)


func _apply_theme() -> void:
	# ปุ่มวงกลมตัวอักษรแรกของชื่อ
	var circle := _circle_style(AuthThemeTokens.INPUT_BG)
	var circle_hover := _circle_style(Color.WHITE)
	var focus_ring := StyleBoxFlat.new()
	focus_ring.draw_center = false
	focus_ring.border_color = AuthThemeTokens.INPUT_BORDER_FOCUS
	focus_ring.set_border_width_all(3)
	focus_ring.set_corner_radius_all(999)
	add_theme_stylebox_override("normal", circle)
	add_theme_stylebox_override("pressed", circle)
	add_theme_stylebox_override("hover", circle_hover)
	add_theme_stylebox_override("focus", focus_ring)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		add_theme_color_override(color_name, AuthThemeTokens.TEXT_PRIMARY)
	_avatar.add_theme_stylebox_override("normal", circle)
	_avatar.add_theme_color_override("font_color", AuthThemeTokens.TEXT_PRIMARY)

	# กล่องเมนู
	var panel := StyleBoxFlat.new()
	panel.bg_color = AuthThemeTokens.CARD_BG
	panel.border_color = AuthThemeTokens.CARD_BORDER
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(12)
	panel.shadow_color = Color(0, 0, 0, 0.35)
	panel.shadow_size = 8
	_panel.add_theme_stylebox_override("panel", panel)

	_name_label.add_theme_color_override("font_color", AuthThemeTokens.TEXT_PRIMARY)
	_sub_label.add_theme_color_override("font_color", AuthThemeTokens.TEXT_MUTED)
	_guest_hint.add_theme_color_override("font_color", AuthThemeTokens.TEXT_MUTED)
	_email_label.add_theme_color_override("font_color", AuthThemeTokens.TEXT_MUTED)
	for icon_color in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
		_reveal_btn.add_theme_color_override(icon_color, AuthThemeTokens.TEXT_MUTED)

	# ปุ่มหลัก (จัดการบัญชี) สีทอง / ปุ่มรอง (ออกจากระบบ) สีอ่อน
	_style_button(_manage_btn, AuthThemeTokens.BUTTON_BG, AuthThemeTokens.BUTTON_HOVER_BG, AuthThemeTokens.BUTTON_PRESSED_BG)
	_style_button(_sign_out_btn, AuthThemeTokens.INPUT_BG, Color.WHITE, AuthThemeTokens.CARD_BORDER)


static func _circle_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = AuthThemeTokens.CARD_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(999)
	return style


static func _style_button(btn: Button, normal: Color, hover: Color, pressed_bg: Color) -> void:
	btn.add_theme_stylebox_override("normal", AuthThemeTokens.create_button_style(normal))
	btn.add_theme_stylebox_override("hover", AuthThemeTokens.create_button_style(hover))
	btn.add_theme_stylebox_override("pressed", AuthThemeTokens.create_button_style(pressed_bg))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(color_name, AuthThemeTokens.BUTTON_TEXT)
