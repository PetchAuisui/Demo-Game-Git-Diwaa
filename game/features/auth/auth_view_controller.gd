class_name AuthViewController
extends Control

## Controller managing tab navigation, UI transitions, credential hygiene, validation,
## and sending login / register requests to the account server.

## ส่งออกเมื่อล็อกอินสำเร็จ: session คือคำตอบของ server {"profile": {...}, "token": String, "expiresAt": String}
## (ใน 4.4 PlayerSession จะมารับ signal นี้ไปเก็บ session แล้วพาเข้าเกม)
signal login_succeeded(session: Dictionary, remember_me: bool)

const EYE_ICON := preload("res://assets/icons/eye.svg")
const EYE_OFF_ICON := preload("res://assets/icons/eye_off.svg")
const LOGIN_BG_PATH := "res://assets/art/auth/login_bg.png"
const REGISTER_BG_PATH := "res://assets/art/auth/register_bg.png"

const FIELD_LABELS := {
	AuthRules.FIELD_IDENTIFIER: "อีเมล หรือ ชื่อผู้ใช้งาน",
	AuthRules.FIELD_DISPLAY_NAME: "ชื่อที่แสดง",
	AuthRules.FIELD_USERNAME: "ชื่อผู้ใช้",
	AuthRules.FIELD_EMAIL: "อีเมล",
	AuthRules.FIELD_PASSWORD: "รหัสผ่าน",
	AuthRules.FIELD_CONFIRM_PASSWORD: "ยืนยันรหัสผ่าน",
}

# --- UI References ---
var _background_image: TextureRect
var _login_tab_btn: Button
var _register_tab_btn: Button

# Forms
var _login_form: VBoxContainer
var _register_form: VBoxContainer

# Login Controls
var _identifier_input: LineEdit
var _identifier_error: Label
var _login_password_input: LineEdit
var _login_password_toggle: Button
var _login_password_error: Label
var _remember_me_check: CheckBox
var _login_status: Label
var _login_submit_btn: Button
var _go_register_link: LinkButton

# Register Controls
var _display_name_input: LineEdit
var _display_name_error: Label
var _username_input: LineEdit
var _username_error: Label
var _email_input: LineEdit
var _email_error: Label
var _register_password_input: LineEdit
var _register_password_toggle: Button
var _register_password_error: Label
var _confirm_password_input: LineEdit
var _confirm_password_error: Label
var _register_status: Label
var _register_submit_btn: Button
var _go_login_link: LinkButton

# Connection (แถบแจ้งเตือนเมื่อติดต่อ server ไม่ได้ อยู่เหนือฟอร์ม เห็นได้ทั้งสองแท็บ)
var _connection_panel: VBoxContainer
var _connection_label: Label
var _retry_connection_btn: Button

# --- Server ---
var _api: AuthApiClient
var _busy := false
var _login_submit_text := ""
var _register_submit_text := ""


func _ready() -> void:
	_api = AuthApiClient.new()
	add_child(_api)
	_bind_nodes()
	_login_submit_text = _login_submit_btn.text
	_register_submit_text = _register_submit_btn.text
	_wire_events()
	_apply_theme()
	_show_login()
	_check_connection.call_deferred()


func _bind_nodes() -> void:
	_background_image = get_node("%BackgroundImage") as TextureRect
	_login_tab_btn = get_node("%LoginTabBtn") as Button
	_register_tab_btn = get_node("%RegisterTabBtn") as Button

	_login_form = get_node("%LoginForm") as VBoxContainer
	_register_form = get_node("%RegisterForm") as VBoxContainer

	_identifier_input = get_node("%IdentifierInput") as LineEdit
	_identifier_error = get_node("%IdentifierError") as Label
	_login_password_input = get_node("%LoginPasswordInput") as LineEdit
	_login_password_toggle = get_node("%LoginPasswordToggle") as Button
	_login_password_error = get_node("%LoginPasswordError") as Label
	_remember_me_check = get_node("%RememberMeCheck") as CheckBox
	_login_status = get_node("%LoginStatus") as Label
	_login_submit_btn = get_node("%LoginSubmitBtn") as Button
	_go_register_link = get_node("%GoRegisterLink") as LinkButton

	_display_name_input = get_node("%DisplayNameInput") as LineEdit
	_display_name_error = get_node("%DisplayNameError") as Label
	_username_input = get_node("%UsernameInput") as LineEdit
	_username_error = get_node("%UsernameError") as Label
	_email_input = get_node("%EmailInput") as LineEdit
	_email_error = get_node("%EmailError") as Label
	_register_password_input = get_node("%RegisterPasswordInput") as LineEdit
	_register_password_toggle = get_node("%RegisterPasswordToggle") as Button
	_register_password_error = get_node("%RegisterPasswordError") as Label
	_confirm_password_input = get_node("%ConfirmPasswordInput") as LineEdit
	_confirm_password_error = get_node("%ConfirmPasswordError") as Label
	_register_status = get_node("%RegisterStatus") as Label
	_register_submit_btn = get_node("%RegisterSubmitBtn") as Button
	_go_login_link = get_node("%GoLoginLink") as LinkButton

	_connection_panel = get_node("%ConnectionPanel") as VBoxContainer
	_connection_label = get_node("%ConnectionLabel") as Label
	_retry_connection_btn = get_node("%RetryConnectionBtn") as Button


func _wire_events() -> void:
	_login_tab_btn.pressed.connect(_on_login_tab_pressed)
	_register_tab_btn.pressed.connect(_on_register_tab_pressed)
	_go_register_link.pressed.connect(_show_register)
	_go_login_link.pressed.connect(_show_login)

	_login_password_toggle.toggled.connect(
		_on_password_toggle.bind(_login_password_input, _login_password_toggle)
	)
	_register_password_toggle.toggled.connect(
		_on_password_toggle.bind(_register_password_input, _register_password_toggle)
	)

	login_succeeded.connect(_on_login_succeeded)
	_retry_connection_btn.pressed.connect(_check_connection)

	_login_submit_btn.pressed.connect(_on_login_submit)
	_login_password_input.text_submitted.connect(func(_text: String) -> void: await _on_login_submit())

	_register_submit_btn.pressed.connect(_on_register_submit)
	_confirm_password_input.text_submitted.connect(func(_text: String) -> void: await _on_register_submit())


func _on_login_tab_pressed() -> void:
	if not _login_form.visible:
		_show_login()


func _on_register_tab_pressed() -> void:
	if not _register_form.visible:
		_show_register()


func _show_login() -> void:
	_apply_background(LOGIN_BG_PATH)
	_login_form.visible = true
	_register_form.visible = false

	_login_tab_btn.button_pressed = true

	_clear_passwords()
	_reset_errors()

	_identifier_input.grab_focus()


func _show_register() -> void:
	_apply_background(REGISTER_BG_PATH)
	_login_form.visible = false
	_register_form.visible = true

	_register_tab_btn.button_pressed = true

	_clear_passwords()
	_reset_errors()

	_display_name_input.grab_focus()


func _apply_background(path: String) -> void:
	if ResourceLoader.exists(path):
		_background_image.texture = load(path) as Texture2D
	else:
		_background_image.texture = null


func _on_password_toggle(pressed: bool, input: LineEdit, btn: Button) -> void:
	input.secret = not pressed
	_set_toggle_visual(btn, pressed)


func _set_toggle_visual(btn: Button, revealed: bool) -> void:
	btn.icon = EYE_OFF_ICON if revealed else EYE_ICON
	btn.tooltip_text = "ซ่อนรหัสผ่าน" if revealed else "แสดงรหัสผ่าน"


func _clear_passwords() -> void:
	# Hygiene: purge secret fields and reset visibility toggle states
	_login_password_input.text = ""
	_login_password_input.secret = true
	_login_password_toggle.button_pressed = false
	_set_toggle_visual(_login_password_toggle, false)

	_register_password_input.text = ""
	_register_password_input.secret = true
	_register_password_toggle.button_pressed = false
	_set_toggle_visual(_register_password_toggle, false)

	_confirm_password_input.text = ""
	_confirm_password_input.secret = true


func _reset_errors() -> void:
	_identifier_error.visible = false
	_identifier_error.text = ""
	_login_password_error.visible = false
	_login_password_error.text = ""
	_login_status.visible = false
	_login_status.text = ""

	_display_name_error.visible = false
	_display_name_error.text = ""
	_username_error.visible = false
	_username_error.text = ""
	_email_error.visible = false
	_email_error.text = ""
	_register_password_error.visible = false
	_register_password_error.text = ""
	_confirm_password_error.visible = false
	_confirm_password_error.text = ""
	_register_status.visible = false
	_register_status.text = ""


func _apply_theme() -> void:
	var input_normal := AuthThemeTokens.create_input_style(AuthThemeTokens.INPUT_BORDER)
	var input_focus := AuthThemeTokens.create_input_style(AuthThemeTokens.INPUT_BORDER_FOCUS)

	var inputs: Array[LineEdit] = [
		_identifier_input,
		_login_password_input,
		_display_name_input,
		_username_input,
		_email_input,
		_register_password_input,
		_confirm_password_input
	]

	for input in inputs:
		input.add_theme_stylebox_override("normal", input_normal)
		input.add_theme_stylebox_override("focus", input_focus)
		input.add_theme_color_override("font_color", AuthThemeTokens.TEXT_PRIMARY)
		input.add_theme_color_override("caret_color", AuthThemeTokens.TEXT_PRIMARY)

	var btn_normal := AuthThemeTokens.create_button_style(AuthThemeTokens.BUTTON_BG)
	var btn_hover := AuthThemeTokens.create_button_style(AuthThemeTokens.BUTTON_HOVER_BG)
	var btn_pressed := AuthThemeTokens.create_button_style(AuthThemeTokens.BUTTON_PRESSED_BG)
	var btn_disabled := AuthThemeTokens.create_button_style(AuthThemeTokens.BUTTON_DISABLED_BG)

	var submit_buttons: Array[Button] = [_login_submit_btn, _register_submit_btn, _retry_connection_btn]
	for btn in submit_buttons:
		btn.add_theme_stylebox_override("normal", btn_normal)
		btn.add_theme_stylebox_override("hover", btn_hover)
		btn.add_theme_stylebox_override("pressed", btn_pressed)
		btn.add_theme_stylebox_override("disabled", btn_disabled)
		btn.add_theme_color_override("font_color", AuthThemeTokens.BUTTON_TEXT)
		btn.add_theme_color_override("font_hover_color", AuthThemeTokens.BUTTON_TEXT)
		btn.add_theme_color_override("font_pressed_color", AuthThemeTokens.BUTTON_TEXT)
		btn.add_theme_color_override("font_disabled_color", AuthThemeTokens.BUTTON_DISABLED_TEXT)

	# Theming for password toggle buttons
	var toggle_normal := AuthThemeTokens.create_button_style(AuthThemeTokens.TOGGLE_BG)
	var toggle_hover := AuthThemeTokens.create_button_style(AuthThemeTokens.TOGGLE_HOVER_BG)

	var toggle_buttons: Array[Button] = [_login_password_toggle, _register_password_toggle]
	for toggle_btn in toggle_buttons:
		toggle_btn.add_theme_stylebox_override("normal", toggle_normal)
		toggle_btn.add_theme_stylebox_override("pressed", toggle_normal)
		toggle_btn.add_theme_stylebox_override("hover", toggle_hover)
		toggle_btn.add_theme_stylebox_override("hover_pressed", toggle_hover)

		toggle_btn.add_theme_color_override("icon_normal_color", AuthThemeTokens.TOGGLE_ICON)
		toggle_btn.add_theme_color_override("icon_hover_color", AuthThemeTokens.TOGGLE_ICON)
		toggle_btn.add_theme_color_override("icon_pressed_color", AuthThemeTokens.TOGGLE_ICON)
		toggle_btn.add_theme_color_override("icon_hover_pressed_color", AuthThemeTokens.TOGGLE_ICON)
		toggle_btn.add_theme_color_override("icon_focus_color", AuthThemeTokens.TOGGLE_ICON)

	_go_register_link.add_theme_color_override("font_color", AuthThemeTokens.LINK_TEXT)
	_go_login_link.add_theme_color_override("font_color", AuthThemeTokens.LINK_TEXT)


func _on_login_submit() -> void:
	if _busy:
		return
	_reset_errors()

	var id_reason := AuthRules.validate_login_identifier(_identifier_input.text)
	var pw_reason := AuthRules.validate_login_password(_login_password_input.text)

	var first_invalid: LineEdit = null

	if not id_reason.is_empty():
		_identifier_error.text = _message_for(AuthRules.FIELD_IDENTIFIER, id_reason)
		_identifier_error.visible = true
		if first_invalid == null:
			first_invalid = _identifier_input

	if not pw_reason.is_empty():
		_login_password_error.text = _message_for(AuthRules.FIELD_PASSWORD, pw_reason)
		_login_password_error.visible = true
		if first_invalid == null:
			first_invalid = _login_password_input

	if first_invalid != null:
		first_invalid.grab_focus()
		return

	var id_val := _identifier_input.text.strip_edges()
	var pw_val := _login_password_input.text
	var remember_val := _remember_me_check.button_pressed

	_clear_passwords()
	await _submit_login(id_val, pw_val, remember_val)


func _on_register_submit() -> void:
	if _busy:
		return
	_reset_errors()

	var dn_reason := AuthRules.validate_display_name(_display_name_input.text)
	var un_reason := AuthRules.validate_username(_username_input.text)
	var em_reason := AuthRules.validate_email(_email_input.text)
	var pw_reason := AuthRules.validate_register_password(_register_password_input.text)

	var cp_reason := ""
	if _confirm_password_input.text.is_empty():
		cp_reason = AuthRules.REQUIRED
	elif _confirm_password_input.text != _register_password_input.text:
		cp_reason = AuthRules.MISMATCH

	var first_invalid: LineEdit = null

	if not dn_reason.is_empty():
		_display_name_error.text = _message_for(AuthRules.FIELD_DISPLAY_NAME, dn_reason)
		_display_name_error.visible = true
		if first_invalid == null:
			first_invalid = _display_name_input

	if not un_reason.is_empty():
		_username_error.text = _message_for(AuthRules.FIELD_USERNAME, un_reason)
		_username_error.visible = true
		if first_invalid == null:
			first_invalid = _username_input

	if not em_reason.is_empty():
		_email_error.text = _message_for(AuthRules.FIELD_EMAIL, em_reason)
		_email_error.visible = true
		if first_invalid == null:
			first_invalid = _email_input

	if not pw_reason.is_empty():
		_register_password_error.text = _message_for(AuthRules.FIELD_PASSWORD, pw_reason)
		_register_password_error.visible = true
		if first_invalid == null:
			first_invalid = _register_password_input

	if not cp_reason.is_empty():
		_confirm_password_error.text = _message_for(AuthRules.FIELD_CONFIRM_PASSWORD, cp_reason)
		_confirm_password_error.visible = true
		if first_invalid == null:
			first_invalid = _confirm_password_input

	if first_invalid != null:
		first_invalid.grab_focus()
		return

	var un_val := _username_input.text.strip_edges()
	var dn_val := _display_name_input.text.strip_edges()
	var em_val := _email_input.text.strip_edges()
	var pw_val := _register_password_input.text

	_clear_passwords()
	await _submit_register(un_val, dn_val, em_val, pw_val)


func _message_for(field: String, reason: String) -> String:
	var label: String = FIELD_LABELS.get(field, "ข้อมูล")

	match reason:
		AuthRules.REQUIRED:
			return "กรุณากรอก%s" % label
		AuthRules.TOO_SHORT:
			if field == AuthRules.FIELD_USERNAME:
				return "ชื่อผู้ใช้ต้องมี %d–%d ตัวอักษร" % [
					AuthRules.USERNAME_MIN_LEN,
					AuthRules.USERNAME_MAX_LEN
				]
			if field == AuthRules.FIELD_PASSWORD:
				return "รหัสผ่านต้องมีอย่างน้อย %d ตัวอักษร" % AuthRules.PASSWORD_MIN_LEN
			return "%sสั้นเกินไป" % label
		AuthRules.TOO_LONG:
			if field == AuthRules.FIELD_USERNAME:
				return "ชื่อผู้ใช้ต้องมี %d–%d ตัวอักษร" % [
					AuthRules.USERNAME_MIN_LEN,
					AuthRules.USERNAME_MAX_LEN
				]
			return "%sยาวเกินไป" % label
		AuthRules.INVALID_CHARACTERS:
			if field == AuthRules.FIELD_USERNAME:
				return "ใช้ได้เฉพาะ a-z, 0-9 และ -"
			if field == AuthRules.FIELD_EMAIL:
				return "รูปแบบอีเมลไม่ถูกต้อง"
			if field == AuthRules.FIELD_DISPLAY_NAME:
				return "ชื่อที่แสดงมีอักขระที่ไม่รองรับ"
			return "%sมีอักขระไม่ถูกต้อง" % label
		AuthRules.INVALID_FORMAT:
			if field == AuthRules.FIELD_USERNAME:
				return "ต้องขึ้นต้นและลงท้ายด้วยตัวอักษรหรือตัวเลข"
			if field == AuthRules.FIELD_EMAIL:
				return "รูปแบบอีเมลไม่ถูกต้อง"
			return "รูปแบบ%sไม่ถูกต้อง" % label
		AuthRules.TAKEN:
			if field == AuthRules.FIELD_DISPLAY_NAME:
				return "ชื่อที่แสดงนี้มีผู้ใช้แล้ว กรุณาเลือกชื่ออื่น"
			return "%sนี้ถูกใช้แล้ว" % label
		AuthRules.MISMATCH:
			return "รหัสผ่านไม่ตรงกัน"
		_:
			return "ข้อมูล%sไม่ถูกต้อง" % label


# --- ส่งข้อมูลไป server ---
# รหัสผ่านถูกล้างออกจากช่องก่อนส่งแล้ว ถ้า server ตอบว่าผิด ผู้ใช้ต้องพิมพ์ใหม่ (แอปทั่วไปก็ทำแบบนี้)

func _submit_login(identifier: String, password: String, remember_me: bool) -> void:
	_set_busy(true)
	var result := await _api.login(identifier, password, remember_me)
	_set_busy(false)

	if result.ok:
		_show_status(_login_status, "เข้าสู่ระบบสำเร็จ", true)
		login_succeeded.emit(result.data, remember_me)
		return

	match result.code:
		AuthApiResult.INVALID_CREDENTIALS:
			# ข้อความเดียวกันทุกกรณี (รหัสผิด / ไม่มีบัญชีนี้ / ถูกพักชั่วคราว) ตามที่ server ตั้งใจ
			# เพื่อไม่ให้ใครใช้หน้านี้เดาว่าบัญชีไหนมีอยู่จริง
			_show_status(_login_status, "อีเมล/ชื่อผู้ใช้ หรือรหัสผ่านไม่ถูกต้อง\nหากใส่ผิดหลายครั้ง ระบบจะพักการเข้าสู่ระบบชั่วคราว", false)
			_login_password_input.grab_focus()
		AuthApiResult.VALIDATION_FAILED:
			var shown := _apply_field_errors(result.field_errors, {
				AuthRules.FIELD_IDENTIFIER: _identifier_error,
				AuthRules.FIELD_PASSWORD: _login_password_error,
			})
			if not shown:
				_show_status(_login_status, _message_for_failure(result), false)
		_:
			_show_status(_login_status, _message_for_failure(result), false)


func _submit_register(username: String, display_name: String, email: String, password: String) -> void:
	_set_busy(true)
	var result := await _api.register(username, display_name, email, password)
	_set_busy(false)

	if result.ok:
		# สมัครสำเร็จ: ล้างฟอร์มสมัคร (กันคนใช้เครื่องต่อเห็นข้อมูล) แล้วพาไปหน้า login พร้อมเติม username ให้
		_clear_register_form()
		_show_login()
		_identifier_input.text = username
		_show_status(_login_status, "สมัครสมาชิกสำเร็จ กรุณาเข้าสู่ระบบ", true)
		_login_password_input.grab_focus()
		return

	if result.code == AuthApiResult.IDENTIFIER_TAKEN or result.code == AuthApiResult.VALIDATION_FAILED:
		var shown := _apply_field_errors(result.field_errors, {
			AuthRules.FIELD_DISPLAY_NAME: _display_name_error,
			AuthRules.FIELD_USERNAME: _username_error,
			AuthRules.FIELD_EMAIL: _email_error,
			AuthRules.FIELD_PASSWORD: _register_password_error,
		})
		if shown:
			return
	_show_status(_register_status, _message_for_failure(result), false)


## แสดง error ใต้ช่องตามที่ server บอก คืนค่า true ถ้าแสดงได้อย่างน้อย 1 ช่อง
## ข้อความมาจาก _message_for เสมอ ไม่เอาข้อความดิบจาก server ไปแสดงบนจอ
func _apply_field_errors(errors: Array[Dictionary], targets: Dictionary) -> bool:
	var shown := false
	for entry in errors:
		var field: String = entry.get("field", "")
		var label: Label = targets.get(field)
		if label == null:
			continue
		label.text = _message_for(field, entry.get("reason", ""))
		label.visible = true
		shown = true
	return shown


func _message_for_failure(result: AuthApiResult) -> String:
	match result.code:
		AuthApiResult.RATE_LIMITED:
			return "ลองหลายครั้งเกินไป กรุณารอประมาณ %d วินาทีแล้วลองใหม่" % maxi(result.retry_after_sec, 1)
		AuthApiResult.NETWORK_UNAVAILABLE:
			return "เชื่อมต่อ server ไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่"
		AuthApiResult.IDENTIFIER_TAKEN:
			return "ชื่อผู้ใช้หรืออีเมลนี้ถูกใช้แล้ว"
		AuthApiResult.VALIDATION_FAILED:
			return "ข้อมูลไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง"
		_:
			return "เกิดข้อผิดพลาดที่ server กรุณาลองใหม่ภายหลัง"


func _show_status(label: Label, text: String, success: bool) -> void:
	label.text = text
	label.add_theme_color_override("font_color", AuthThemeTokens.SUCCESS_TEXT if success else AuthThemeTokens.ERROR_TEXT)
	label.visible = true


## ระหว่างรอ server: ปิดปุ่มทั้งหมด กันกดซ้ำ และกันสลับฟอร์มกลางทาง
func _set_busy(busy: bool) -> void:
	_busy = busy
	var buttons: Array[BaseButton] = [
		_login_submit_btn,
		_register_submit_btn,
		_login_tab_btn,
		_register_tab_btn,
		_go_register_link,
		_go_login_link,
		_retry_connection_btn,
	]
	for btn in buttons:
		btn.disabled = busy
	_login_submit_btn.text = "กำลังเข้าสู่ระบบ..." if busy else _login_submit_text
	_register_submit_btn.text = "กำลังสมัครสมาชิก..." if busy else _register_submit_text


## เช็คว่าติดต่อ server ได้ไหม (ตอนเปิดหน้านี้ และตอนกด "ลองเชื่อมต่อใหม่")
## ติดต่อได้ → ลองล็อกอินอัตโนมัติต่อ / ติดต่อไม่ได้ → ขึ้นแถบแจ้งเตือนพร้อมปุ่มลองใหม่
## ผลของการเช็คนี้ใช้แค่ตัดสินว่าจะแสดงอะไรบนจอ ไม่ได้ใช้ตัดสินสิทธิ์ใดๆ
func _check_connection() -> void:
	if _busy:
		return
	if PlayerSession.is_signed_in():
		get_tree().change_scene_to_file(PlayerSession.START_SCENE)
		return

	_set_busy(true)
	_login_submit_btn.text = "กำลังเชื่อมต่อ server..."
	var result := await _api.health()
	_set_busy(false)

	if not result.ok:
		_show_connection_problem(result)
		return
	_connection_panel.visible = false
	await _try_restore_session()


func _show_connection_problem(result: AuthApiResult) -> void:
	_connection_label.text = _message_for_failure(result)
	_connection_panel.visible = true


## ถ้ามี session ที่จดจำไว้ ลองล็อกอินอัตโนมัติ (เรียกหลังเช็คแล้วว่าติดต่อ server ได้)
func _try_restore_session() -> void:
	if not PlayerSession.has_saved_session():
		return

	_set_busy(true)
	_login_submit_btn.text = "กำลังเข้าสู่ระบบอัตโนมัติ..."
	var outcome := await PlayerSession.restore_saved_session()
	_set_busy(false)

	if outcome == PlayerSession.RESTORE_OK:
		get_tree().change_scene_to_file(PlayerSession.START_SCENE)
		return
	if not PlayerSession.last_username.is_empty():
		_identifier_input.text = PlayerSession.last_username
		_login_password_input.grab_focus()
	if outcome == PlayerSession.RESTORE_NEED_LOGIN:
		_show_status(_login_status, "การเข้าสู่ระบบหมดอายุแล้ว กรุณาเข้าสู่ระบบใหม่", false)
	elif outcome == PlayerSession.RESTORE_NETWORK_FAILED:
		# server หลุดไประหว่างเช็คกับต่ออายุ: ขึ้นแถบแจ้งเตือนเดียวกัน กดลองใหม่ได้
		_show_connection_problem(AuthApiResult.failure(0, AuthApiResult.NETWORK_UNAVAILABLE))


## ล็อกอินสำเร็จ: ส่งต่อให้ PlayerSession เก็บ session แล้วพาเข้าหน้าแรกของเกม
func _on_login_succeeded(session: Dictionary, remember_me: bool) -> void:
	if not PlayerSession.start_session(session, remember_me):
		_show_status(_login_status, "ข้อมูลจาก server ไม่ถูกต้อง กรุณาลองใหม่", false)
		return
	get_tree().change_scene_to_file(PlayerSession.START_SCENE)


func _clear_register_form() -> void:
	_display_name_input.text = ""
	_username_input.text = ""
	_email_input.text = ""
