class_name AccountMenu
extends Button
## ปุ่มบัญชีมุมขวาบน (อยู่ใน StartTopBar) กดแล้วเปิดเมนู: ชื่อผู้เล่น / จัดการบัญชี / ออกจากระบบ
## ซ่อนตัวเองเมื่อยังไม่มีผู้เล่น เช่น ที่หน้าเข้าสู่ระบบ (ใช้ StartTopBar ตัวเดียวกัน)
## เปิดเมนูแล้ว: กดที่อื่นหรือกด Esc = ปิด
##
## ความปลอดภัย:
## 1. ไม่แสดงอีเมล เกมไม่ได้รับอีเมลจาก server (ตั้งใจไว้ กันอีเมลหลุดตอนสตรีม / แคปจอ / ใช้เครื่องร่วมกัน)
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


func _ready() -> void:
	_panel = get_node("%Panel") as PanelContainer
	_avatar = get_node("%Avatar") as Label
	_name_label = get_node("%NameLabel") as Label
	_sub_label = get_node("%SubLabel") as Label
	_manage_btn = get_node("%ManageBtn") as Button
	_sign_out_btn = get_node("%SignOutBtn") as Button
	_guest_hint = get_node("%GuestHint") as Label
	_apply_theme()

	pressed.connect(_toggle)
	_manage_btn.pressed.connect(_on_manage_pressed)
	_sign_out_btn.pressed.connect(_on_sign_out_pressed)
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
	match PlayerSession.state:
		PlayerSession.State.GUEST:
			_sub_label.text = "เล่นแบบไม่ล็อกอิน"
		PlayerSession.State.OFFLINE:
			_sub_label.text = "@%s · ออฟไลน์" % PlayerSession.get_username()
		_:
			_sub_label.text = "@%s" % PlayerSession.get_username()

	# หน้าจัดการบัญชีต้องคุยกับ server จึงใช้ได้เฉพาะตอนออนไลน์
	_manage_btn.visible = PlayerSession.state == PlayerSession.State.ONLINE
	_sign_out_btn.text = "ออกจากโหมดไม่ล็อกอิน" if guest else "ออกจากระบบ"
	_guest_hint.visible = guest


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


func _close() -> void:
	_panel.visible = false


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
