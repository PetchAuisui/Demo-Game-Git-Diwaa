class_name AccountViewController
extends Control
## หน้า "บัญชีของฉัน": ดูชื่อ เปลี่ยนชื่อที่แสดง (ออนไลน์เท่านั้น) และออกจากระบบ
## ทีมเปิดหน้านี้ได้ด้วย get_tree().change_scene_to_file(PlayerSession.ACCOUNT_SCENE)
##
## ข้อควรรู้: การเช็คในหน้านี้ (กติกาชื่อ, ยืนยันก่อนเปลี่ยน) มีไว้ช่วยผู้เล่นเท่านั้น
## เรื่องชื่อซ้ำและกฎ 14 วัน server เป็นผู้ตัดสินเสมอ

const RENAME_COOLDOWN_DAYS := 14

var _mode_label: Label
var _display_name_value: Label
var _username_value: Label
var _rename_section: VBoxContainer
var _rename_input: LineEdit
var _rename_hint: Label
var _rename_status: Label
var _rename_btn: Button
var _sign_out_btn: Button
var _back_btn: Button

var _busy := false
# กดเปลี่ยนชื่อครั้งแรก = ขอให้ยืนยัน, ครั้งที่สอง = ส่งจริง (เพราะเปลี่ยนแล้วต้องรอ 14 วัน)
var _confirming := false
var _rename_btn_text := ""


func _ready() -> void:
	_bind_nodes()
	_wire_events()
	_apply_theme()
	_rename_btn_text = _rename_btn.text
	_refresh()
	_ensure_player.call_deferred()


func _bind_nodes() -> void:
	_mode_label = get_node("%ModeLabel") as Label
	_display_name_value = get_node("%DisplayNameValue") as Label
	_username_value = get_node("%UsernameValue") as Label
	_rename_section = get_node("%RenameSection") as VBoxContainer
	_rename_input = get_node("%RenameInput") as LineEdit
	_rename_hint = get_node("%RenameHint") as Label
	_rename_status = get_node("%RenameStatus") as Label
	_rename_btn = get_node("%RenameBtn") as Button
	_sign_out_btn = get_node("%SignOutBtn") as Button
	_back_btn = get_node("%BackBtn") as Button


func _wire_events() -> void:
	_rename_btn.pressed.connect(_on_rename_pressed)
	_rename_input.text_submitted.connect(func(_text: String) -> void: await _on_rename_pressed())
	_rename_input.text_changed.connect(func(_text: String) -> void: _cancel_confirm())
	_sign_out_btn.pressed.connect(_on_sign_out_pressed)
	_back_btn.pressed.connect(_on_back_pressed)
	PlayerSession.session_changed.connect(_refresh)


func _apply_theme() -> void:
	_rename_input.add_theme_stylebox_override("normal", AuthThemeTokens.create_input_style(AuthThemeTokens.INPUT_BORDER))
	_rename_input.add_theme_stylebox_override("focus", AuthThemeTokens.create_input_style(AuthThemeTokens.INPUT_BORDER_FOCUS))
	_rename_input.add_theme_color_override("font_color", AuthThemeTokens.TEXT_PRIMARY)
	_rename_input.add_theme_color_override("caret_color", AuthThemeTokens.TEXT_PRIMARY)

	var buttons: Array[Button] = [_rename_btn, _sign_out_btn, _back_btn]
	for btn in buttons:
		btn.add_theme_stylebox_override("normal", AuthThemeTokens.create_button_style(AuthThemeTokens.BUTTON_BG))
		btn.add_theme_stylebox_override("hover", AuthThemeTokens.create_button_style(AuthThemeTokens.BUTTON_HOVER_BG))
		btn.add_theme_stylebox_override("pressed", AuthThemeTokens.create_button_style(AuthThemeTokens.BUTTON_PRESSED_BG))
		btn.add_theme_stylebox_override("disabled", AuthThemeTokens.create_button_style(AuthThemeTokens.BUTTON_DISABLED_BG))
		btn.add_theme_color_override("font_color", AuthThemeTokens.BUTTON_TEXT)
		btn.add_theme_color_override("font_hover_color", AuthThemeTokens.BUTTON_TEXT)
		btn.add_theme_color_override("font_pressed_color", AuthThemeTokens.BUTTON_TEXT)
		btn.add_theme_color_override("font_disabled_color", AuthThemeTokens.BUTTON_DISABLED_TEXT)


## เปิดหน้านี้ตรงๆ (เช่น กด F6) ตอนยังไม่มีผู้เล่น: ลองล็อกอินอัตโนมัติ ไม่ได้ก็กลับหน้าเข้าสู่ระบบ
func _ensure_player() -> void:
	if PlayerSession.has_player():
		return
	if not PlayerSession.has_saved_session():
		get_tree().change_scene_to_file(PlayerSession.AUTH_SCENE)
		return
	_set_busy(true)
	var outcome := await PlayerSession.restore_saved_session()
	_set_busy(false)
	if outcome != PlayerSession.RESTORE_OK:
		get_tree().change_scene_to_file(PlayerSession.AUTH_SCENE)
		return
	_refresh()


func _refresh() -> void:
	_display_name_value.text = PlayerSession.get_display_name()

	var username := PlayerSession.get_username()
	_username_value.visible = not username.is_empty()
	_username_value.text = "ชื่อผู้ใช้: %s (ใช้เข้าสู่ระบบเท่านั้น ไม่แสดงให้ผู้อื่นเห็น)" % username

	match PlayerSession.state:
		PlayerSession.State.ONLINE:
			_mode_label.text = "ออนไลน์"
		PlayerSession.State.OFFLINE:
			_mode_label.text = "ออฟไลน์: เปลี่ยนชื่อและใช้ตารางอันดับไม่ได้จนกว่าจะเชื่อมต่อ server"
		PlayerSession.State.GUEST:
			_mode_label.text = "เล่นแบบไม่ล็อกอิน: ชื่อนี้อยู่ในเครื่องนี้เท่านั้น"
		_:
			_mode_label.text = ""

	_rename_section.visible = PlayerSession.is_online()
	_sign_out_btn.text = "ออกจากโหมดไม่ล็อกอิน" if PlayerSession.is_guest() else "ออกจากระบบ"
	_update_rename_hint()


func _update_rename_hint() -> void:
	var next_change := PlayerSession.display_name_next_change_unix
	if next_change > int(Time.get_unix_time_from_system()):
		_rename_hint.text = "เปลี่ยนชื่อได้อีกครั้ง: %s" % _format_local_datetime(next_change)
	else:
		_rename_hint.text = "เปลี่ยนได้ 1 ครั้งทุก %d วัน ชื่อเก่าจะว่างให้คนอื่นใช้ได้ทันที" % RENAME_COOLDOWN_DAYS


func _on_rename_pressed() -> void:
	if _busy:
		return
	_rename_status.visible = false

	var new_name := _rename_input.text.strip_edges()
	var reason := AuthRules.validate_display_name(new_name)
	if not reason.is_empty():
		_cancel_confirm()
		_show_rename_status(_message_for_reason(reason), AuthThemeTokens.ERROR_TEXT)
		return
	if new_name == PlayerSession.get_display_name():
		_cancel_confirm()
		_show_rename_status("นี่คือชื่อปัจจุบันของคุณอยู่แล้ว", AuthThemeTokens.ERROR_TEXT)
		return

	if not _confirming:
		_confirming = true
		_rename_btn.text = "กดอีกครั้งเพื่อยืนยัน"
		_show_rename_status(
			"เปลี่ยนเป็น \"%s\" แล้วจะเปลี่ยนอีกไม่ได้ %d วัน" % [new_name, RENAME_COOLDOWN_DAYS],
			AuthThemeTokens.TEXT_PRIMARY
		)
		return

	_confirming = false
	_set_busy(true)
	var result := await PlayerSession.change_display_name(new_name)
	_set_busy(false)

	if result.ok:
		_rename_input.text = ""
		_refresh()
		_show_rename_status("เปลี่ยนชื่อเรียบร้อย", AuthThemeTokens.SUCCESS_TEXT)
		return
	_update_rename_hint()
	_show_rename_status(_message_for_failure(result), AuthThemeTokens.ERROR_TEXT)


func _cancel_confirm() -> void:
	_confirming = false
	if not _busy:
		_rename_btn.text = _rename_btn_text


## ออกจากระบบ: ลบข้อมูลในเครื่องทันที (แจ้ง server เบื้องหลัง) แล้วกลับหน้าเข้าสู่ระบบ
func _on_sign_out_pressed() -> void:
	if _busy:
		return
	PlayerSession.sign_out()
	get_tree().change_scene_to_file(PlayerSession.AUTH_SCENE)


func _on_back_pressed() -> void:
	if _busy:
		return
	get_tree().change_scene_to_file(PlayerSession.START_SCENE)


func _set_busy(busy: bool) -> void:
	_busy = busy
	_rename_btn.disabled = busy
	_sign_out_btn.disabled = busy
	_back_btn.disabled = busy
	_rename_input.editable = not busy
	_rename_btn.text = "กำลังดำเนินการ..." if busy else _rename_btn_text


func _show_rename_status(text: String, color: Color) -> void:
	_rename_status.text = text
	_rename_status.add_theme_color_override("font_color", color)
	_rename_status.visible = true


## ข้อความทั้งหมดเขียนเองที่นี่ ไม่เอาข้อความดิบจาก server ไปแสดง
func _message_for_failure(result: AuthApiResult) -> String:
	match result.code:
		AuthApiResult.DISPLAY_NAME_CHANGE_COOLDOWN:
			var next_change := int(Time.get_unix_time_from_system()) + result.retry_after_sec
			return "ยังเปลี่ยนชื่อไม่ได้ เปลี่ยนได้อีกครั้ง: %s" % _format_local_datetime(next_change)
		AuthApiResult.IDENTIFIER_TAKEN:
			return _message_for_reason(AuthRules.TAKEN)
		AuthApiResult.VALIDATION_FAILED:
			if not result.field_errors.is_empty():
				return _message_for_reason(result.field_errors[0].get("reason", ""))
			return "ชื่อที่แสดงไม่ถูกต้อง"
		AuthApiResult.RATE_LIMITED:
			return "ลองหลายครั้งเกินไป กรุณารอประมาณ %d วินาทีแล้วลองใหม่" % maxi(result.retry_after_sec, 1)
		AuthApiResult.NETWORK_UNAVAILABLE:
			return "เชื่อมต่อ server ไม่ได้ กรุณาลองใหม่"
		AuthApiResult.INVALID_CREDENTIALS:
			return "การเข้าสู่ระบบหมดอายุแล้ว กรุณาออกจากระบบแล้วเข้าสู่ระบบใหม่"
		_:
			return "เกิดข้อผิดพลาดที่ server กรุณาลองใหม่ภายหลัง"


func _message_for_reason(reason: String) -> String:
	match reason:
		AuthRules.REQUIRED:
			return "กรุณากรอกชื่อที่แสดง"
		AuthRules.TOO_LONG:
			return "ชื่อที่แสดงยาวได้ไม่เกิน %d ตัวอักษร" % AuthRules.DISPLAY_NAME_MAX_LEN
		AuthRules.INVALID_CHARACTERS:
			return "ชื่อที่แสดงมีตัวอักษรที่ใช้ไม่ได้"
		AuthRules.TAKEN:
			return "ชื่อที่แสดงนี้มีผู้ใช้แล้ว กรุณาเลือกชื่ออื่น"
		_:
			return "ชื่อที่แสดงไม่ถูกต้อง"


## แสดงเวลาตามเขตเวลาของเครื่อง รูปแบบ วัน/เดือน/ปี ชั่วโมง:นาที
func _format_local_datetime(unix_time: int) -> String:
	var bias_minutes: int = Time.get_time_zone_from_system().get("bias", 0)
	var d := Time.get_datetime_dict_from_unix_time(unix_time + bias_minutes * 60)
	return "%02d/%02d/%04d %02d:%02d" % [d["day"], d["month"], d["year"], d["hour"], d["minute"]]
