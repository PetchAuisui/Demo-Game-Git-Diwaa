class_name AuthViewController
extends Control

## Controller managing tab navigation, UI transitions, credential hygiene, validation,
## and sending login / register requests to the account server.

## ส่งออกเมื่อล็อกอินสำเร็จ: session คือคำตอบของ server {"profile": {...}, "token": String, "expiresAt": String}
## สคริปต์นี้ติดอยู่ที่ root (AuthView) ใครอยากรู้ว่าล็อกอินสำเร็จ ต่อ signal นี้จาก root ได้เลย
## (ปกติไม่ต้องต่อ: _on_login_succeeded ส่งต่อให้ PlayerSession แล้วพาเข้าหน้าเริ่มให้เอง หรือฟัง PlayerSession.session_changed แทน)
signal login_succeeded(session: Dictionary, remember_me: bool)

const EYE_ICON := preload("res://assets/icons/eye.svg")
const EYE_OFF_ICON := preload("res://assets/icons/eye_off.svg")
# รูปพื้นหลังหน้าเข้าสู่ระบบ / สมัคร: ตอนนี้ยังไม่มีไฟล์ใน repo (ตั้งใจ) หน้าจอจึงใช้พื้นสีเข้มของ Backdrop ไปก่อน
# อยากใส่รูป: วางไฟล์ตาม path นี้ หรือแก้ path ตรงนี้ให้ชี้ไปที่รูปที่มี (ไม่ต้องแก้โค้ดส่วนอื่น _apply_background โหลดให้เอง)
# ถ้าไม่มีไฟล์ตาม path ก็ไม่ error แค่ไม่แสดงรูป
const LOGIN_BG_PATH := "res://assets/art/auth/login_bg.png"
const REGISTER_BG_PATH := "res://assets/art/auth/register_bg.png"
# ชื่อ guest ที่โชว์บนลิงก์ยาวได้สุดกี่ตัวอักษร (ชื่อยาวกว่านี้ตัดแล้วต่อด้วย …) กันลิงก์ดันการ์ดจนกว้างเกิน
const GUEST_NAME_PREVIEW_LEN := 20

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
var _connection_panel: HBoxContainer
var _connection_label: Label
var _retry_connection_btn: LinkButton
var _offline_play_btn: LinkButton

# Guest (เล่นแบบไม่ล็อกอิน)
var _go_guest_link: LinkButton
var _change_guest_name_link: LinkButton
var _guest_form: VBoxContainer
var _guest_name_input: LineEdit
var _guest_name_error: Label
var _guest_start_btn: Button
var _guest_back_link: LinkButton

# หน้าต่างนโยบายตอนสมัครเปิดอยู่ไหม (กันกดสมัครซ้ำจนเปิดซ้อน)
var _consent_open := false
# รับทราบนโยบายไว้กับชื่อผู้ใช้ + อีเมลชุดไหน และเลือกเรื่องตารางอันดับไว้ว่าอะไร
# สมัครไม่ผ่านแล้วแก้แค่รหัสผ่าน: ไม่ต้องอ่านนโยบายซ้ำ
# ชื่อผู้ใช้หรืออีเมลเปลี่ยน = อาจเป็นคนใหม่ใช้เครื่องต่อ: ต้องอ่านนโยบาย ยืนยันอายุ และเลือกตารางอันดับใหม่เสมอ
# (ห้ามใช้ความยินยอมของคนก่อน) ล้างเมื่อสมัครสำเร็จใน _clear_register_form
var _policy_acknowledged_for := ""
var _leaderboard_choice := false
# สมัครครั้งล่าสุดไม่รู้ผล (คำขออาจไปถึง server แล้วแต่คำตอบหาย) ด้วยชื่อผู้ใช้ + อีเมลชุดไหน
# กดสมัครซ้ำด้วยชุดเดิมแล้วเจอ "ถูกใช้แล้ว" = น่าจะเป็นบัญชีที่เพิ่งสมัครสำเร็จ: บอกให้ลองเข้าสู่ระบบ
var _register_unknown_for := ""

# --- Server ---
var _api: AuthApiClient
var _busy := false
# นับถอยหลังหลังโดนจำกัดจำนวนครั้ง (เวลาตาม Time.get_ticks_msec หน่วย ms / 0 = ไม่ได้นับ)
var _cooldown_until_msec := 0
var _cooldown_timer: Timer
var _login_submit_text := ""
var _register_submit_text := ""


func _ready() -> void:
	_api = AuthApiClient.new()
	add_child(_api)
	_cooldown_timer = Timer.new()
	_cooldown_timer.wait_time = 1.0
	_cooldown_timer.timeout.connect(_on_cooldown_tick)
	add_child(_cooldown_timer)
	_bind_nodes()
	_login_submit_text = _login_submit_btn.text
	_register_submit_text = _register_submit_btn.text
	_wire_events()
	_apply_theme()
	_route_on_open()


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

	_connection_panel = get_node("%ConnectionPanel") as HBoxContainer
	_connection_label = get_node("%ConnectionLabel") as Label
	_retry_connection_btn = get_node("%RetryConnectionBtn") as LinkButton
	_offline_play_btn = get_node("%OfflinePlayBtn") as LinkButton

	_go_guest_link = get_node("%GoGuestLink") as LinkButton
	_change_guest_name_link = get_node("%ChangeGuestNameLink") as LinkButton
	_guest_form = get_node("%GuestForm") as VBoxContainer
	_guest_name_input = get_node("%GuestNameInput") as LineEdit
	_guest_name_error = get_node("%GuestNameError") as Label
	_guest_start_btn = get_node("%GuestStartBtn") as Button
	_guest_back_link = get_node("%GuestBackLink") as LinkButton




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
	_offline_play_btn.pressed.connect(_on_offline_play_pressed)

	_go_guest_link.pressed.connect(_on_go_guest_pressed)
	_change_guest_name_link.pressed.connect(_show_guest)
	_guest_back_link.pressed.connect(_show_login)
	_guest_start_btn.pressed.connect(_on_guest_start)
	_guest_name_input.text_submitted.connect(func(_text: String) -> void: _on_guest_start())

	_login_submit_btn.pressed.connect(_on_login_submit)
	_login_password_input.text_submitted.connect(func(_text: String) -> void: await _on_login_submit())

	_register_submit_btn.pressed.connect(_on_register_submit)
	_confirm_password_input.text_submitted.connect(func(_text: String) -> void: await _on_register_submit())

	# กด Enter ในช่องที่ยังไม่ใช่ช่องสุดท้าย = ไปช่องถัดไป (ช่องสุดท้ายกด Enter = ส่งฟอร์ม)
	_identifier_input.text_submitted.connect(func(_text: String) -> void: _login_password_input.grab_focus())
	_username_input.text_submitted.connect(func(_text: String) -> void: _email_input.grab_focus())
	_email_input.text_submitted.connect(func(_text: String) -> void: _register_password_input.grab_focus())
	_register_password_input.text_submitted.connect(func(_text: String) -> void: _confirm_password_input.grab_focus())

	# ให้กด Tab ไปถึงลิงก์ได้ทุกอัน (แล้วกด Enter / Space เพื่อกดลิงก์) คนที่ใช้แต่คีย์บอร์ดจะได้ไปได้ทุกทาง
	var links: Array[LinkButton] = [
		_go_register_link, _go_login_link, _retry_connection_btn, _offline_play_btn,
		_go_guest_link, _change_guest_name_link, _guest_back_link,
	]
	for link in links:
		link.focus_mode = Control.FOCUS_ALL


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
	_guest_form.visible = false

	_login_tab_btn.button_pressed = true
	_place_connection_panel(_login_status)

	_clear_passwords()
	_reset_errors()
	_refresh_guest_link()

	_identifier_input.grab_focus()


func _show_register() -> void:
	_apply_background(REGISTER_BG_PATH)
	_login_form.visible = false
	_register_form.visible = true
	_guest_form.visible = false

	_register_tab_btn.button_pressed = true
	_place_connection_panel(_register_status)

	_clear_passwords()
	_reset_errors()

	_username_input.grab_focus()


## หน้าเล่นแบบไม่ล็อกอิน: เติมชื่อที่เคยใช้ไว้ให้
func _show_guest() -> void:
	_apply_background(LOGIN_BG_PATH)
	_login_form.visible = false
	_register_form.visible = false
	_guest_form.visible = true

	_clear_passwords()
	_reset_errors()

	_guest_name_input.text = GuestStore.load_name()
	_guest_name_input.grab_focus()


## เปิดหน้านี้: มีผู้เล่นอยู่แล้ว (ล็อกอินค้างไว้ / guest) → ไปหน้าเริ่ม / ยังไม่มี → หน้าเข้าสู่ระบบ
## เรื่องอายุ: ไม่ถามตอนเปิดเกมแล้ว ถามตอนสมัครเท่านั้นด้วยช่องติ๊ก "อายุ 20 ปีขึ้นไป" ในหน้านโยบาย (privacy_notice.gd)
func _route_on_open() -> void:
	if PlayerSession.has_player():
		get_tree().change_scene_to_file.call_deferred(PlayerSession.START_SCENE)
		return
	_show_login()
	_check_connection.call_deferred()


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
	_guest_name_error.visible = false
	_guest_name_error.text = ""


func _apply_theme() -> void:
	var input_normal := AuthThemeTokens.create_input_style(AuthThemeTokens.INPUT_BORDER)
	var input_focus := AuthThemeTokens.create_input_style(AuthThemeTokens.INPUT_BORDER_FOCUS)

	var inputs: Array[LineEdit] = [
		_identifier_input,
		_login_password_input,
		_username_input,
		_email_input,
		_register_password_input,
		_confirm_password_input,
		_guest_name_input,
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

	var submit_buttons: Array[Button] = [_login_submit_btn, _register_submit_btn, _guest_start_btn]
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
	_go_guest_link.add_theme_color_override("font_color", AuthThemeTokens.LINK_TEXT)
	_change_guest_name_link.add_theme_color_override("font_color", AuthThemeTokens.TEXT_MUTED)
	_guest_back_link.add_theme_color_override("font_color", AuthThemeTokens.LINK_TEXT)
	_retry_connection_btn.add_theme_color_override("font_color", AuthThemeTokens.LINK_TEXT)
	_offline_play_btn.add_theme_color_override("font_color", AuthThemeTokens.LINK_TEXT)


func _on_login_submit() -> void:
	if _busy or _cooldown_left_sec() > 0:
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
	if _busy or _consent_open or _cooldown_left_sec() > 0:
		return
	_reset_errors()

	var un_reason := AuthRules.validate_username(_username_input.text)
	var em_reason := AuthRules.validate_email(_email_input.text)
	var pw_reason := AuthRules.validate_register_password(_register_password_input.text)

	var cp_reason := ""
	if _confirm_password_input.text.is_empty():
		cp_reason = AuthRules.REQUIRED
	elif _confirm_password_input.text != _register_password_input.text:
		cp_reason = AuthRules.MISMATCH

	var first_invalid: LineEdit = null

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
	var em_val := _email_input.text.strip_edges()
	var pw_val := _register_password_input.text

	var consent_key := _consent_key(un_val, em_val)
	if _policy_acknowledged_for != consent_key:
		# ข้อมูลชุดใหม่: ทิ้งความยินยอมเดิมก่อน ถ้ายกเลิกกลางทางจะไม่เหลือค่าของชุดก่อนค้างไว้
		_policy_acknowledged_for = ""
		_leaderboard_choice = false
		# ถาม server ก่อนว่าชื่อผู้ใช้/อีเมลใช้ได้ไหม จะได้ไม่ต้องอ่านนโยบายจนจบแล้วค่อยรู้ว่าซ้ำ
		if not await _check_registration(un_val, em_val):
			return

		# เปิดนโยบายให้อ่านจนจบ ติ๊กรับทราบ + ยืนยันอายุ และเลือกเรื่องตารางอันดับ
		_consent_open = true
		var notice := PrivacyNotice.open_for_sign_up(get_tree())
		if notice == null:
			_consent_open = false
			return
		var choice: Array = await notice.closed
		_consent_open = false
		if not choice[0]:
			return  # ยกเลิก: ข้อมูลในฟอร์มยังอยู่ แก้แล้วกดสมัครใหม่ได้
		_policy_acknowledged_for = consent_key
		_leaderboard_choice = choice[1]

	# ไม่ล้างรหัสผ่านตรงนี้: ถ้าสมัครไม่ผ่านจะได้ไม่ต้องพิมพ์ใหม่ (สมัครสำเร็จ / สลับหน้า ล้างให้เองใน _show_login)
	await _submit_register(un_val, em_val, pw_val, _leaderboard_choice)


## กุญแจของความยินยอม: ชื่อผู้ใช้กับอีเมลตามที่พิมพ์ (ไม่แปลงตัวเล็กตัวใหญ่ เปลี่ยนแม้แต่ตัวเดียวก็ถามใหม่)
## คั่นด้วยขึ้นบรรทัดใหม่ ซึ่งกติกาของทั้งสองช่องไม่อนุญาต กุญแจของคนละชุดจึงไม่มีทางซ้ำกัน
func _consent_key(username: String, email: String) -> String:
	return username + "\n" + email


## ตรวจกับ server ก่อนเปิดหน้านโยบาย คืนค่า true ถ้าไปต่อได้
## ผลนี้ไม่ใช่การจองชื่อ ตอนสมัครจริง server ตรวจซ้ำอีกครั้งเสมอ
func _check_registration(username: String, email: String) -> bool:
	_set_busy(true)
	var result := await _api.check_registration(username, email)
	_set_busy(false)
	_note_rate_limit(result)
	_note_server_answered(result)
	# ระหว่างรอ ผู้เล่นสลับไปหน้าอื่นแล้ว: ไม่เปิดหน้านโยบายขึ้นมาทับหน้าที่เขาเลือก
	if not _register_form.visible:
		return false
	if result.ok:
		return true
	if result.code == AuthApiResult.VALIDATION_FAILED:
		var shown := _apply_field_errors(result.field_errors, {
			AuthRules.FIELD_USERNAME: _username_error,
			AuthRules.FIELD_EMAIL: _email_error,
		})
		if shown:
			return false
	_show_status(_register_status, _message_for_failure(result), false)
	return false


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
		AuthRules.TOO_COMMON:
			return "รหัสผ่านนี้เดาง่ายเกินไป (เช่น 12345678, password หรือเหมือนชื่อผู้ใช้) กรุณาตั้งรหัสอื่น"
		AuthRules.RESERVED:
			return "ชื่อรูปแบบ player-ตัวเลข สงวนไว้ให้ระบบ กรุณาใช้ชื่ออื่น"
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
	_note_rate_limit(result)
	_note_server_answered(result)

	if result.ok:
		_show_status(_login_status, "เข้าสู่ระบบสำเร็จ", true)
		login_succeeded.emit(result.data, remember_me)
		return

	match result.code:
		AuthApiResult.INVALID_CREDENTIALS:
			# ข้อความเดียวกันทุกกรณี (รหัสผิด / ไม่มีบัญชีนี้ / ถูกพักชั่วคราว) ตามที่ server ตั้งใจ
			# เพื่อไม่ให้ใครใช้หน้านี้เดาว่าบัญชีไหนมีอยู่จริง
			_show_status(_login_status, "อีเมล/ชื่อผู้ใช้ หรือรหัสผ่านไม่ถูกต้อง\nกรอกผิดเกินกำหนด ระบบจะพักการเข้าสู่ระบบ 15 นาที", false)
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


func _submit_register(username: String, email: String, password: String, leaderboard_opt_in: bool) -> void:
	_set_busy(true)
	# ส่งเวอร์ชันนโยบายที่ผู้เล่นเห็น และการยินยอมแสดงชื่อบนตารางอันดับ (ค่าเริ่มต้น = ไม่ยินยอม)
	var result := await _api.register(
		username, "", email, password,  # ชื่อที่แสดงเว้นว่าง: server ตั้งให้เป็น player-<เลข>
		PrivacyPolicy.VERSION, leaderboard_opt_in
	)
	_set_busy(false)
	_note_rate_limit(result)
	_note_server_answered(result)

	var attempt_key := _consent_key(username, email)
	if not result.ok and result.maybe_delivered:
		_register_unknown_for = attempt_key
		_show_status(_register_status, "ไม่แน่ใจว่าสมัครสำเร็จหรือยัง ลองเข้าสู่ระบบก่อน\nถ้าเข้าไม่ได้ ค่อยกดสมัครอีกครั้ง", false)
		return
	if result.code == AuthApiResult.IDENTIFIER_TAKEN and _register_unknown_for == attempt_key:
		_show_status(_register_status, "ชื่อผู้ใช้หรืออีเมลนี้ถูกใช้แล้ว\nถ้าเพิ่งกดสมัครไป บัญชีอาจสร้างแล้ว ลองเข้าสู่ระบบก่อน", false)
		return

	if result.ok:
		# สมัครสำเร็จ: ล้างฟอร์มสมัคร (กันคนใช้เครื่องต่อเห็นข้อมูล) แล้วพาไปหน้า login พร้อมเติม username ให้
		_clear_register_form()
		_show_login()
		_identifier_input.text = username
		# แจ้งผลด้วยหน้าต่าง ปิดแล้วพร้อมกรอกรหัสผ่านต่อ (ไม่บอกชื่อในเกม ผู้เล่นเห็นเองหลังเข้าสู่ระบบ)
		var popup := MessagePopup.open(get_tree(), "สมัครสมาชิกสำเร็จ", "เข้าสู่ระบบด้วยชื่อผู้ใช้และรหัสผ่านที่เพิ่งตั้งได้เลย")
		if popup != null:
			await popup.closed
		if is_inside_tree():
			_login_password_input.grab_focus()
		return

	if result.code == AuthApiResult.IDENTIFIER_TAKEN or result.code == AuthApiResult.VALIDATION_FAILED:
		var shown := _apply_field_errors(result.field_errors, {
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
			return "ลองหลายครั้งเกินไป กรุณารอจนปุ่มกดได้อีกครั้งแล้วลองใหม่"
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


## ระหว่างรอ server: ล็อกเฉพาะปุ่มที่ส่งคำขอไป server (ส่งได้ทีละคำขอ) ที่เหลือกดได้ตามปกติ
## เช่น server ไม่ตอบ ผู้เล่นยังสลับแท็บ หรือกด "เล่นโดยไม่ล็อกอิน" ได้ทันที ไม่ต้องรอจนหมดเวลา
## ถ้าผู้เล่นออกจากหน้านี้ไประหว่างรอ คำตอบที่มาทีหลังจะถูกทิ้ง (หน้านี้ถูกลบไปพร้อม AuthApiClient ของมัน)
func _set_busy(busy: bool) -> void:
	_busy = busy
	_refresh_request_buttons()
	if busy:
		_login_submit_btn.text = "กำลังเข้าสู่ระบบ..."
		_register_submit_btn.text = "กำลังสมัครสมาชิก..."


## ปุ่มที่ส่งคำขอไป server: กดไม่ได้ระหว่างรอคำตอบ และระหว่างนับถอยหลังหลังโดนจำกัดจำนวนครั้ง
func _refresh_request_buttons() -> void:
	var wait_sec := _cooldown_left_sec()
	var buttons: Array[BaseButton] = [_login_submit_btn, _register_submit_btn, _retry_connection_btn]
	for btn in buttons:
		btn.disabled = _busy or wait_sec > 0
	if _busy:
		return  # ข้อความบนปุ่มระหว่างรอ ตั้งใน _set_busy / _check_connection
	if wait_sec > 0:
		var wait_text := "ลองใหม่ได้ใน %d วินาที" % wait_sec
		_login_submit_btn.text = wait_text
		_register_submit_btn.text = wait_text
	else:
		_login_submit_btn.text = _login_submit_text
		_register_submit_btn.text = _register_submit_text


## โดนจำกัดจำนวนครั้ง (429): นับถอยหลังตามเวลาที่ server บอก (Retry-After) ระหว่างนั้นกดส่งคำขอไม่ได้
## กันผู้เล่นกดซ้ำจนโดนนับเพิ่ม (ตัวตัดสินจริงยังเป็น server เสมอ)
func _note_rate_limit(result: AuthApiResult) -> void:
	if result.code != AuthApiResult.RATE_LIMITED:
		return
	_cooldown_until_msec = Time.get_ticks_msec() + maxi(result.retry_after_sec, 1) * 1000
	_cooldown_timer.start()
	_refresh_request_buttons()


## server ตอบกลับมาจริง (ไม่ใช่เน็ตหลุด / server ล่ม / ถูกจำกัดจำนวนครั้ง): ซ่อนแถบ "เชื่อมต่อ server ไม่ได้"
## ที่อาจค้างจากตอนเปิดหน้านี้ (เช่น เปิดเกมก่อนเปิด server) ไม่ให้ขึ้นคู่กับคำตอบจาก server จนผู้เล่นงง
## status 0 = ไม่ได้คำตอบจาก server / 5xx = server มีปัญหา / 429 = แถบนี้ใช้บอกให้รอ: คงแถบไว้
func _note_server_answered(result: AuthApiResult) -> void:
	if result.status >= 200 and result.status < 500 and result.code != AuthApiResult.RATE_LIMITED:
		_hide_connection_problem()


func _cooldown_left_sec() -> int:
	return maxi(0, ceili((_cooldown_until_msec - Time.get_ticks_msec()) / 1000.0))


func _on_cooldown_tick() -> void:
	if _cooldown_left_sec() == 0:
		_cooldown_timer.stop()
	_refresh_request_buttons()


## เช็คว่าติดต่อ server ได้ไหม (ตอนเปิดหน้านี้ และตอนกด "ลองเชื่อมต่อใหม่")
## ติดต่อได้ → ลองล็อกอินอัตโนมัติต่อ / ติดต่อไม่ได้ → ขึ้นแถบแจ้งเตือนพร้อมปุ่มลองใหม่
## ผลของการเช็คนี้ใช้แค่ตัดสินว่าจะแสดงอะไรบนจอ ไม่ได้ใช้ตัดสินสิทธิ์ใดๆ
func _check_connection() -> void:
	if _busy or _cooldown_left_sec() > 0:
		return
	if PlayerSession.has_player():
		get_tree().change_scene_to_file(PlayerSession.START_SCENE)
		return

	_set_busy(true)
	_login_submit_btn.text = "กำลังเชื่อมต่อ server..."
	var result := await _api.health()
	_set_busy(false)
	_note_rate_limit(result)
	_note_server_answered(result)

	if not result.ok:
		_show_connection_problem(result)
		return
	_hide_connection_problem()
	await _try_restore_session()


## แถบ "เชื่อมต่อ server ไม่ได้" มีอันเดียว ย้ายไปอยู่ในฟอร์มที่เปิดอยู่ ตรงเหนือข้อความสถานะและปุ่มส่ง
func _place_connection_panel(before: Control) -> void:
	var form := before.get_parent()
	if _connection_panel.get_parent() != form:
		_connection_panel.reparent(form, false)
	var target := before.get_index()
	if _connection_panel.get_index() < target:
		target -= 1
	form.move_child(_connection_panel, target)


## ข้อความสั้นบรรทัดเดียว (ไม่เอาข้อความจาก server มาแสดง)
func _connection_message(result: AuthApiResult) -> String:
	if result.code == AuthApiResult.RATE_LIMITED:
		return "ลองบ่อยเกินไป รอสักครู่แล้วลองใหม่"
	return "เชื่อมต่อ server ไม่ได้"


## ซ่อนแถบเชื่อมต่อพร้อมปุ่มเล่นออฟไลน์ (ปุ่มไม่ได้อยู่ในแถบ ต้องซ่อนเองด้วย ไม่งั้นค้างหลัง server กลับมา)
func _hide_connection_problem() -> void:
	_connection_panel.visible = false
	_offline_play_btn.visible = false


func _show_connection_problem(result: AuthApiResult) -> void:
	_connection_label.text = _connection_message(result)
	_connection_panel.visible = true

	# ปุ่มเล่นออฟไลน์: ขึ้นเฉพาะตอน server ติดต่อไม่ได้จริง (เน็ตหลุด / server ล่ม)
	# ไม่ขึ้นตอนถูกจำกัดจำนวนครั้ง (429) เพราะ server ยังอยู่ แค่ต้องรอ
	# และต้องมีบัญชีที่จดจำไว้ในเครื่องนี้ด้วย
	var server_unreachable := result.code in [AuthApiResult.NETWORK_UNAVAILABLE, AuthApiResult.SERVER_ERROR]
	var saved_name := PlayerSession.get_saved_display_name() if server_unreachable else ""
	_offline_play_btn.visible = not saved_name.is_empty()
	if _offline_play_btn.visible:
		_offline_play_btn.text = "เล่นด้วยบัญชี %s แบบออฟไลน์" % _short_name(saved_name)


func _on_offline_play_pressed() -> void:
	if not PlayerSession.start_offline():
		_offline_play_btn.visible = false
		_connection_label.text = "ไม่พบบัญชีที่จดจำไว้ในเครื่องนี้"
		return
	get_tree().change_scene_to_file(PlayerSession.START_SCENE)


## เริ่มเล่นแบบไม่ล็อกอิน: ตรวจชื่อด้วยกติกาเดียวกับชื่อที่แสดง แล้วบันทึกไว้ในเครื่อง
func _on_guest_start() -> void:
	_guest_name_error.visible = false
	var display_name := AuthRules.trim_spaces(_guest_name_input.text)
	var reason := AuthRules.validate_new_display_name(display_name)
	if not reason.is_empty():
		_guest_name_error.text = _message_for(AuthRules.FIELD_DISPLAY_NAME, reason)
		_guest_name_error.visible = true
		_guest_name_input.grab_focus()
		return
	if not GuestStore.save_name(display_name):
		# บันทึกไม่ได้ก็ยังเล่นได้ แค่ครั้งหน้าต้องพิมพ์ชื่อใหม่
		push_warning("AuthView: could not save the guest name.")
	if not PlayerSession.start_guest(display_name):
		_guest_name_error.text = "เริ่มเล่นไม่ได้ กรุณาลองใหม่"
		_guest_name_error.visible = true
		return
	get_tree().change_scene_to_file(PlayerSession.START_SCENE)


## กดลิงก์ guest ในหน้าเข้าสู่ระบบ: ถ้าเคยตั้งชื่อไว้แล้ว เข้าเกมในชื่อนั้นเลย ไม่ต้องกรอกซ้ำ
## ยังไม่เคยตั้งชื่อ (หรือไฟล์ชื่อเสีย) → ไปหน้าตั้งชื่อ
func _on_go_guest_pressed() -> void:
	var saved_name := GuestStore.load_name()
	if saved_name.is_empty() or not PlayerSession.start_guest(saved_name):
		_show_guest()
		return
	get_tree().change_scene_to_file(PlayerSession.START_SCENE)


## ข้อความบนลิงก์ guest: ถ้าเคยตั้งชื่อไว้ บอกชื่อที่จะใช้ และโชว์ลิงก์ "เปลี่ยนชื่อ"
func _refresh_guest_link() -> void:
	var saved_name := GuestStore.load_name()
	_change_guest_name_link.visible = not saved_name.is_empty()
	if saved_name.is_empty():
		_go_guest_link.text = "เล่นโดยไม่ล็อกอิน"
		return
	_go_guest_link.text = "เล่นโดยไม่ล็อกอิน (ชื่อ: %s)" % _short_name(saved_name)


## ตัดชื่อยาวๆ ให้สั้นลง (ต่อด้วย …) กันลิงก์ดันการ์ดจนกว้างเกิน
func _short_name(display_name: String) -> String:
	if display_name.length() <= GUEST_NAME_PREVIEW_LEN:
		return display_name
	return display_name.left(GUEST_NAME_PREVIEW_LEN) + "…"


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
	elif outcome == PlayerSession.RESTORE_RATE_LIMITED:
		# server ยังอยู่ แค่ลองบ่อยเกินไป: บอกตามจริง (ไม่ใช่ "เชื่อมต่อไม่ได้") และนับถอยหลังบนปุ่ม
		var limited := AuthApiResult.failure(429, AuthApiResult.RATE_LIMITED)
		limited.retry_after_sec = maxi(PlayerSession.last_retry_after_sec, 1)
		_note_rate_limit(limited)
		_show_connection_problem(limited)


## ล็อกอินสำเร็จ: ส่งต่อให้ PlayerSession เก็บ session แล้วพาเข้าหน้าแรกของเกม
func _on_login_succeeded(session: Dictionary, remember_me: bool) -> void:
	if not PlayerSession.start_session(session, remember_me):
		_show_status(_login_status, "ข้อมูลจาก server ไม่ถูกต้อง กรุณาลองใหม่", false)
		return
	get_tree().change_scene_to_file(PlayerSession.START_SCENE)


func _clear_register_form() -> void:
	_username_input.text = ""
	_email_input.text = ""
	_policy_acknowledged_for = ""
	_leaderboard_choice = false
	_register_unknown_for = ""
