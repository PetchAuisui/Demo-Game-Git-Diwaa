class_name AuthViewController
extends Control

## Controller managing tab navigation, UI transitions, and credential hygiene.

const EYE_ICON := preload("res://assets/icons/eye.svg")
const EYE_OFF_ICON := preload("res://assets/icons/eye_off.svg")

# --- UI References ---
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


func _ready() -> void:
	_bind_nodes()
	_wire_events()
	_apply_theme()
	_show_login()


func _bind_nodes() -> void:
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


func _on_login_tab_pressed() -> void:
	if not _login_form.visible:
		_show_login()


func _on_register_tab_pressed() -> void:
	if not _register_form.visible:
		_show_register()


func _show_login() -> void:
	_login_form.visible = true
	_register_form.visible = false

	_login_tab_btn.button_pressed = true

	_clear_passwords()
	_reset_errors()

	_identifier_input.grab_focus()


func _show_register() -> void:
	_login_form.visible = false
	_register_form.visible = true

	_register_tab_btn.button_pressed = true

	_clear_passwords()
	_reset_errors()

	_display_name_input.grab_focus()


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
	_login_password_error.visible = false
	_login_status.visible = false

	_display_name_error.visible = false
	_username_error.visible = false
	_email_error.visible = false
	_register_password_error.visible = false
	_confirm_password_error.visible = false
	_register_status.visible = false


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

	var submit_buttons: Array[Button] = [_login_submit_btn, _register_submit_btn]
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

