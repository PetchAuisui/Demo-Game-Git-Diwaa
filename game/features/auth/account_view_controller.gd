class_name AccountViewController
extends Control
## หน้า "บัญชีของฉัน": ดูชื่อในเกม / อีเมล (ปิดบัง) / สถานะ, เปลี่ยนชื่อในเกม, ตั้งค่าตารางอันดับ
## (ไม่มีปุ่มออกจากระบบในหน้านี้ เพราะเปิดได้จากเมนูบัญชีเท่านั้น ซึ่งมีปุ่มออกจากระบบอยู่แล้ว)
##
## เปิดได้ 2 แบบ
## 1. หน้าต่างลอยทับหน้าปัจจุบัน (แบบที่เกมใช้ ผ่านปุ่ม "จัดการบัญชี" ในเมนูบัญชี):
##      AccountViewController.open(parent)
##    ปิด (× / Esc) แล้วกลับหน้าเดิมทันที หน้าข้างหลังไม่ถูกโหลดใหม่ จึงไม่เสียความคืบหน้า (เช่น เปิดจากกลางด่าน)
## 2. เปิดไฟล์ account_view.tscn ตรงๆ ด้วย F6 (ไว้ทดสอบ): ยังไม่มีผู้เล่นจะลองล็อกอินอัตโนมัติ ปิดแล้วไปหน้าเริ่ม
##
## ⚠️ หน้าตายังเป็นแบบทดสอบ ทีมออกแบบใหม่ได้ ถ้าทำหน้าใหม่ ให้เรียกผ่าน PlayerSession อย่างเดียว (ห้ามคุยกับ server เอง)
##   ข้อมูลผู้เล่น      PlayerSession.get_display_name(), state, is_online(), is_guest()
##   อีเมล             await PlayerSession.fetch_email()  แล้วแสดงด้วย AccountMenu.mask_email(email)
##   สิทธิ์เปลี่ยนชื่อ   await PlayerSession.refresh_display_name_status() แล้วอ่าน display_name_changes_available
##   เปลี่ยนชื่อ        await PlayerSession.change_display_name(new_name) แล้วเช็ค result.ok / result.code
##   ตารางอันดับ        await PlayerSession.get_leaderboard_consent() / set_leaderboard_consent(granted)
##   ออกจากระบบ        อยู่ในเมนูบัญชี (account_menu.gd)
##
## กฎที่ต้องรักษาไว้ (ความปลอดภัย / PDPA):
##   - ซ่อนการเปลี่ยนชื่อและตารางอันดับเมื่อไม่ออนไลน์
##   - ช่องยินยอมแสดงค่าจริงจาก server ถ้าโหลดไม่สำเร็จห้ามให้กด และถอนได้ง่ายเท่ากับให้ (กดครั้งเดียว)
##   - ยืนยันก่อนเปลี่ยนชื่อทุกครั้ง เพราะสิทธิ์มีจำกัด
##   - ไม่แสดงชื่อผู้ใช้ และอีเมลปิดบังเป็นค่าเริ่มต้น (กันหลุดตอนสตรีม / แคปจอ)
##   - ห้ามเอาข้อความดิบจาก server ไปแสดง และห้าม print token
## การเช็คในหน้านี้มีไว้ช่วยผู้เล่น เรื่องชื่อซ้ำ ชื่อสงวน และสิทธิ์เปลี่ยนชื่อ server เป็นผู้ตัดสินเสมอ

## ส่งครั้งเดียวตอนหน้าต่างปิด (แบบลอยทับเท่านั้น)
signal closed

const SCENE_PATH := "res://features/auth/account_view.tscn"
const RENAME_COOLDOWN_DAYS := 14

var _as_overlay := false
var _closed := false
var _busy := false
# โหลดสถานะการยินยอมจาก server สำเร็จแล้วหรือยัง (ยังไม่สำเร็จ = ห้ามให้กด เพราะไม่รู้ค่าจริง)
var _leaderboard_loaded := false
# อีเมลเก็บแค่ในตัวแปรของหน้านี้ ไม่บันทึกลงไฟล์ ปิดหน้าแล้วหายไปพร้อมกัน
var _email := ""

var _backdrop: ColorRect
var _card: PanelContainer
var _close_btn: Button
var _display_name_value: Label
var _email_row: HBoxContainer
var _email_label: Label
var _reveal_btn: Button
var _status_label: Label
var _sep_top: HSeparator
var _sep_middle: HSeparator
var _rename_section: VBoxContainer
var _rename_input: LineEdit
var _rename_btn: Button
var _rename_hint: Label
var _rename_status: Label
var _leaderboard_section: VBoxContainer
var _leaderboard_check: CheckBox
var _leaderboard_help: Button
var _leaderboard_status: Label
var _offline_note: Label
var _privacy_link: LinkButton
var _contact_label: Label


## เปิดเป็นหน้าต่างลอยทับ: parent ควรเป็นชั้นบนสุดของหน้า (เช่น CanvasLayer ของเมนูบัญชี)
static func open(parent: Node) -> AccountViewController:
	var scene := load(SCENE_PATH) as PackedScene
	if scene == null or parent == null:
		push_error("AccountView: could not open the account view.")
		return null
	var view := scene.instantiate() as AccountViewController
	view._as_overlay = true
	parent.add_child(view)
	return view


func _ready() -> void:
	_bind_nodes()
	_wire_events()
	_apply_theme()
	_backdrop.color = Color(0, 0, 0, 0.6) if _as_overlay else AuthThemeTokens.BACKDROP
	_rename_input.max_length = AuthRules.DISPLAY_NAME_MAX_LEN
	_leaderboard_help.tooltip_text = PrivacyNotice.LEADERBOARD_HELP_TEXT
	_contact_label.text = "แจ้งปัญหา หรือขอลบบัญชี: %s" % PrivacyPolicy.CONTACT_EMAIL
	_refresh()
	_rename_input.text = PlayerSession.get_display_name()
	_update_save_button()
	_leaderboard_check.disabled = true  # รอค่าจริงจาก server ก่อน
	_close_btn.grab_focus()
	_load_all.call_deferred()


func _bind_nodes() -> void:
	_backdrop = get_node("%Backdrop") as ColorRect
	_card = get_node("%Card") as PanelContainer
	_close_btn = get_node("%CloseBtn") as Button
	_display_name_value = get_node("%DisplayNameValue") as Label
	_email_row = get_node("%EmailRow") as HBoxContainer
	_email_label = get_node("%EmailLabel") as Label
	_reveal_btn = get_node("%RevealEmailBtn") as Button
	_status_label = get_node("%StatusLabel") as Label
	_sep_top = get_node("%SepTop") as HSeparator
	_sep_middle = get_node("%SepMiddle") as HSeparator
	_rename_section = get_node("%RenameSection") as VBoxContainer
	_rename_input = get_node("%RenameInput") as LineEdit
	_rename_btn = get_node("%RenameBtn") as Button
	_rename_hint = get_node("%RenameHint") as Label
	_rename_status = get_node("%RenameStatus") as Label
	_leaderboard_section = get_node("%LeaderboardSection") as VBoxContainer
	_leaderboard_check = get_node("%LeaderboardCheck") as CheckBox
	_leaderboard_help = get_node("%LeaderboardHelp") as Button
	_leaderboard_status = get_node("%LeaderboardStatus") as Label
	_offline_note = get_node("%OfflineNote") as Label
	_privacy_link = get_node("%PrivacyLink") as LinkButton
	_contact_label = get_node("%ContactLabel") as Label


func _wire_events() -> void:
	_close_btn.pressed.connect(_close)
	_reveal_btn.toggled.connect(func(_on: bool) -> void: _show_email())
	_rename_input.text_changed.connect(_on_rename_text_changed)
	_rename_input.text_submitted.connect(func(_text: String) -> void: await _on_rename_pressed())
	_rename_btn.pressed.connect(_on_rename_pressed)
	_leaderboard_check.toggled.connect(_on_leaderboard_toggled)
	_leaderboard_help.pressed.connect(func() -> void:
		MessagePopup.open_info(self, "ตารางอันดับ", PrivacyNotice.LEADERBOARD_HELP_TEXT)
	)
	_privacy_link.pressed.connect(func() -> void: PrivacyNotice.open_in(self))
	PlayerSession.session_changed.connect(_refresh)


# ---------------------------------------------------------------- เปิด / ปิด

## Esc = ปิด (หน้าต่างย่อยที่เปิดทับอยู่ เช่น ยืนยัน / นโยบาย จะรับ Esc ไปก่อน)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	if _closed:
		return
	_closed = true
	if not _as_overlay:
		get_tree().change_scene_to_file(PlayerSession.START_SCENE)
		return
	closed.emit()
	queue_free()


func _exit_tree() -> void:
	if _as_overlay and not _closed:
		_closed = true
		closed.emit()


## โหลดข้อมูลจาก server ทีละอย่าง (ส่งคำขอได้ทีละครั้ง) ปิดหน้าไประหว่างรอก็หยุดทันที
func _load_all() -> void:
	if not PlayerSession.has_player():
		if _as_overlay:
			_close()  # ไม่มีผู้เล่นแล้ว (เช่น ออกจากระบบไปแล้ว) ไม่มีอะไรให้แสดง
			return
		if not await _restore_for_standalone():
			return
		_refresh()
		_rename_input.text = PlayerSession.get_display_name()
		_update_save_button()
	if not PlayerSession.is_online():
		return
	await _load_display_name_status()
	if not is_inside_tree():
		return
	await _load_leaderboard_consent()
	if not is_inside_tree():
		return
	await _load_email()


## เปิดด้วย F6 ตอนยังไม่มีผู้เล่น: ลองล็อกอินอัตโนมัติด้วย session ที่จดจำไว้
func _restore_for_standalone() -> bool:
	if not PlayerSession.has_saved_session():
		get_tree().change_scene_to_file(PlayerSession.AUTH_SCENE)
		return false
	_set_busy(true)
	var outcome := await PlayerSession.restore_saved_session()
	if not is_inside_tree():
		return false
	_set_busy(false)
	if outcome != PlayerSession.RESTORE_OK:
		get_tree().change_scene_to_file(PlayerSession.AUTH_SCENE)
		return false
	return true


# ---------------------------------------------------------------- ข้อมูลผู้เล่น

## อัปเดตทุกอย่างตามสถานะตอนนี้ (เรียกตอนเปิด และทุกครั้งที่ชื่อ / สถานะการล็อกอินเปลี่ยน)
## ไม่แตะช่องกรอกชื่อ เพราะผู้เล่นอาจกำลังพิมพ์อยู่
func _refresh() -> void:
	var display_name := PlayerSession.get_display_name()
	_display_name_value.text = display_name

	var online := PlayerSession.is_online()
	match PlayerSession.state:
		PlayerSession.State.ONLINE:
			_set_status("ออนไลน์", AuthThemeTokens.SUCCESS_TEXT)
		PlayerSession.State.OFFLINE:
			_set_status("ต้องเข้าสู่ระบบใหม่" if PlayerSession.session_expired else "ออฟไลน์", AuthThemeTokens.TEXT_MUTED)
		PlayerSession.State.GUEST:
			_set_status("เล่นแบบไม่ล็อกอิน", AuthThemeTokens.TEXT_MUTED)
		_:
			_set_status("", AuthThemeTokens.TEXT_MUTED)

	_rename_section.visible = online
	_sep_middle.visible = online
	_leaderboard_section.visible = online
	_offline_note.visible = not online
	if PlayerSession.is_guest():
		_offline_note.text = "ชื่อนี้อยู่ในเครื่องนี้เท่านั้น เปลี่ยนชื่อในเกมและตั้งค่าตารางอันดับได้เมื่อเล่นด้วยบัญชี"
	elif PlayerSession.session_expired:
		_offline_note.text = "การเข้าสู่ระบบหมดอายุแล้ว ออกจากระบบแล้วเข้าสู่ระบบใหม่เพื่อเปลี่ยนชื่อในเกมและตั้งค่าตารางอันดับ"
	else:
		_offline_note.text = "เปลี่ยนชื่อในเกมและตั้งค่าตารางอันดับได้เมื่อเชื่อมต่อ server"

	if not online:
		_email = ""
	_show_email()
	_update_rename_hint()
	_update_save_button()


func _set_status(text: String, color: Color) -> void:
	_status_label.text = text
	_status_label.visible = not text.is_empty()
	_status_label.add_theme_color_override("font_color", color)


func _load_email() -> void:
	var owner_id := PlayerSession.get_user_id()
	var email := await PlayerSession.fetch_email()
	# ระหว่างรอ ปิดหน้า / ออกจากระบบ / เปลี่ยนบัญชีไปแล้ว: ทิ้งคำตอบนี้
	if not is_inside_tree() or not PlayerSession.is_online() or PlayerSession.get_user_id() != owner_id:
		return
	_email = email
	_show_email()


## อีเมลปิดบังเป็นค่าเริ่มต้น กดรูปตาเพื่อดูเต็ม (รูปแบบเดียวกับเมนูบัญชี)
func _show_email() -> void:
	_email_row.visible = not _email.is_empty()
	var revealed := _reveal_btn.button_pressed
	_email_label.text = _email if revealed else AccountMenu.mask_email(_email)
	_reveal_btn.tooltip_text = "ซ่อนอีเมล" if revealed else "แสดงอีเมล"


# ---------------------------------------------------------------- เปลี่ยนชื่อในเกม

func _update_rename_hint() -> void:
	var changes := PlayerSession.display_name_changes_available
	var next_change := PlayerSession.display_name_next_change_unix
	if changes > 0:
		_rename_hint.text = "เปลี่ยนได้อีก %d ครั้ง (ใช้หมดแล้วได้คืน 1 ครั้งทุก %d วัน)" % [changes, RENAME_COOLDOWN_DAYS]
	elif changes == 0 and next_change > int(Time.get_unix_time_from_system()):
		_rename_hint.text = "ใช้สิทธิ์เปลี่ยนชื่อหมดแล้ว เปลี่ยนได้อีกครั้ง: %s" % _format_local_datetime(next_change)
	else:
		_rename_hint.text = "เปลี่ยนชื่อได้จำนวนจำกัด ใช้หมดแล้วได้คืน 1 ครั้งทุก %d วัน" % RENAME_COOLDOWN_DAYS


func _on_rename_text_changed(_text: String) -> void:
	_rename_status.visible = false
	_update_save_button(true)


## ปุ่มบันทึกกดได้เฉพาะเมื่อ: พิมพ์ชื่อใหม่ที่ต่างจากเดิม ถูกกติกา และยังมีสิทธิ์เหลือ
## show_reason: บอกเหตุผลใต้ช่องทันทีถ้าชื่อที่พิมพ์ใช้ไม่ได้ (ไม่ต้องรอกดก่อนถึงรู้)
func _update_save_button(show_reason: bool = false) -> void:
	var new_name := AuthRules.trim_spaces(_rename_input.text)
	var changed := new_name != PlayerSession.get_display_name()
	var reason := AuthRules.validate_new_display_name(new_name) if changed else ""
	var no_credit := PlayerSession.display_name_changes_available == 0
	_rename_btn.disabled = _busy or not changed or not reason.is_empty() or no_credit
	if show_reason and not reason.is_empty():
		_show_rename_status(_message_for_reason(reason), AuthThemeTokens.ERROR_TEXT)


func _on_rename_pressed() -> void:
	if _busy or _rename_btn.disabled:
		return
	var new_name := AuthRules.trim_spaces(_rename_input.text)
	var warning := "เปลี่ยนชื่อในเกมเป็น \"%s\"" % new_name
	var changes := PlayerSession.display_name_changes_available
	if changes == 1:
		warning += "\nนี่เป็นสิทธิ์สุดท้าย หลังจากนี้ต้องรอ %d วัน" % RENAME_COOLDOWN_DAYS
	elif changes > 1:
		warning += "\n(จะเหลือสิทธิ์อีก %d ครั้ง)" % (changes - 1)

	var popup := MessagePopup.open_confirm(self, "เปลี่ยนชื่อในเกม?", warning, "เปลี่ยนชื่อ")
	if popup == null:
		return
	var confirmed: bool = await popup.closed
	if not confirmed or not is_inside_tree():
		return

	_set_busy(true)
	var result := await PlayerSession.change_display_name(new_name)
	if not is_inside_tree():
		return
	_set_busy(false)
	if result.ok:
		_rename_input.text = PlayerSession.get_display_name()
		_refresh()
		_show_rename_status("เปลี่ยนชื่อเรียบร้อย", AuthThemeTokens.SUCCESS_TEXT)
		return
	_update_rename_hint()
	_update_save_button()
	_show_rename_status(_message_for_failure(result), AuthThemeTokens.ERROR_TEXT)


## โหลดสิทธิ์เปลี่ยนชื่อที่เหลือจาก server มาแสดงก่อนผู้เล่นกดเปลี่ยน
func _load_display_name_status() -> void:
	_set_busy(true)
	await PlayerSession.refresh_display_name_status()
	if not is_inside_tree():
		return
	_set_busy(false)
	_update_rename_hint()
	_update_save_button()


func _show_rename_status(text: String, color: Color) -> void:
	_rename_status.text = text
	_rename_status.add_theme_color_override("font_color", color)
	_rename_status.visible = true


# ---------------------------------------------------------------- ตารางอันดับ

## โหลดสถานะการยินยอมจาก server แสดงตามค่าจริงบน server เสมอ
func _load_leaderboard_consent() -> void:
	_set_busy(true)
	var result := await PlayerSession.get_leaderboard_consent()
	if not is_inside_tree():
		return
	var value: Variant = result.data.get("leaderboardOptIn") if result.ok else null
	_leaderboard_loaded = value is bool
	if _leaderboard_loaded:
		_leaderboard_check.set_pressed_no_signal(value)
		_leaderboard_status.visible = false
	else:
		_show_leaderboard_status("โหลดสถานะตารางอันดับไม่สำเร็จ ลองเปิดหน้านี้ใหม่อีกครั้ง", AuthThemeTokens.ERROR_TEXT)
	_set_busy(false)


## ติ๊ก = ให้ความยินยอม, เอาติ๊กออก = ถอนความยินยอม (ถอนได้ง่ายเท่ากับให้)
func _on_leaderboard_toggled(pressed: bool) -> void:
	if _busy or not _leaderboard_loaded:
		_leaderboard_check.set_pressed_no_signal(not pressed)
		return
	_set_busy(true)
	var result := await PlayerSession.set_leaderboard_consent(pressed)
	if not is_inside_tree():
		return
	var value: Variant = result.data.get("leaderboardOptIn") if result.ok else null
	if value is bool:
		_leaderboard_check.set_pressed_no_signal(value)
		var message := "บันทึกแล้ว: ชื่อของคุณจะแสดงบนตารางอันดับ" if value else "บันทึกแล้ว: ชื่อของคุณจะไม่แสดงบนตารางอันดับ"
		_show_leaderboard_status(message, AuthThemeTokens.SUCCESS_TEXT)
	else:
		# ไม่สำเร็จ: กลับไปค่าเดิม ห้ามแสดงค่าที่ server ยังไม่ได้บันทึก
		_leaderboard_check.set_pressed_no_signal(not pressed)
		_show_leaderboard_status(_consent_failure_message(result), AuthThemeTokens.ERROR_TEXT)
	_set_busy(false)


func _show_leaderboard_status(text: String, color: Color) -> void:
	_leaderboard_status.text = text
	_leaderboard_status.add_theme_color_override("font_color", color)
	_leaderboard_status.visible = true


# ---------------------------------------------------------------- ทั่วไป

## ระหว่างรอ server: ล็อกเฉพาะสิ่งที่ส่งคำขอ ปุ่มปิด / นโยบาย / รูปตา ยังกดได้
func _set_busy(busy: bool) -> void:
	_busy = busy
	_rename_input.editable = not busy
	_leaderboard_check.disabled = busy or not _leaderboard_loaded
	_rename_btn.text = "กำลังบันทึก..." if busy else "บันทึก"
	_update_save_button()


func _apply_theme() -> void:
	var card := StyleBoxFlat.new()
	card.bg_color = AuthThemeTokens.CARD_BG
	card.border_color = AuthThemeTokens.CARD_BORDER
	card.set_border_width_all(3)
	card.set_corner_radius_all(10)
	card.shadow_color = Color(0, 0, 0, 0.4)
	card.shadow_size = 16
	_card.add_theme_stylebox_override("panel", card)

	var line := StyleBoxLine.new()
	line.color = AuthThemeTokens.CARD_BORDER
	line.thickness = 1
	for sep: HSeparator in find_children("*", "HSeparator", true, false):
		sep.add_theme_stylebox_override("separator", line)

	for label: Label in find_children("*", "Label", true, false):
		label.add_theme_color_override("font_color", AuthThemeTokens.TEXT_PRIMARY)
	for muted: Label in [_rename_hint, _contact_label, _offline_note]:
		muted.add_theme_color_override("font_color", AuthThemeTokens.TEXT_MUTED)
	_email_label.add_theme_color_override("font_color", AuthThemeTokens.TEXT_MUTED)

	_rename_input.add_theme_stylebox_override("normal", AuthThemeTokens.create_input_style(AuthThemeTokens.INPUT_BORDER))
	_rename_input.add_theme_stylebox_override("focus", AuthThemeTokens.create_input_style(AuthThemeTokens.INPUT_BORDER_FOCUS))
	_rename_input.add_theme_stylebox_override("read_only", AuthThemeTokens.create_input_style(AuthThemeTokens.INPUT_BORDER))
	_rename_input.add_theme_color_override("font_color", AuthThemeTokens.TEXT_PRIMARY)
	_rename_input.add_theme_color_override("font_uneditable_color", AuthThemeTokens.TEXT_MUTED)
	_rename_input.add_theme_color_override("font_placeholder_color", AuthThemeTokens.TEXT_MUTED)
	_rename_input.add_theme_color_override("caret_color", AuthThemeTokens.TEXT_PRIMARY)

	_style_button(_rename_btn, AuthThemeTokens.BUTTON_BG, AuthThemeTokens.BUTTON_HOVER_BG, AuthThemeTokens.BUTTON_PRESSED_BG)

	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_close_btn.add_theme_color_override(color_name, AuthThemeTokens.TEXT_PRIMARY)
		_leaderboard_check.add_theme_color_override(color_name, AuthThemeTokens.TEXT_PRIMARY)
	for icon_btn: Button in [_reveal_btn, _leaderboard_help]:
		for icon_color in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
			icon_btn.add_theme_color_override(icon_color, AuthThemeTokens.TEXT_MUTED)
	_privacy_link.add_theme_color_override("font_color", AuthThemeTokens.LINK_TEXT)
	_privacy_link.focus_mode = Control.FOCUS_ALL


static func _style_button(btn: Button, normal: Color, hover: Color, pressed_bg: Color) -> void:
	btn.add_theme_stylebox_override("normal", AuthThemeTokens.create_button_style(normal))
	btn.add_theme_stylebox_override("hover", AuthThemeTokens.create_button_style(hover))
	btn.add_theme_stylebox_override("pressed", AuthThemeTokens.create_button_style(pressed_bg))
	btn.add_theme_stylebox_override("disabled", AuthThemeTokens.create_button_style(AuthThemeTokens.BUTTON_DISABLED_BG))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(color_name, AuthThemeTokens.BUTTON_TEXT)
	btn.add_theme_color_override("font_disabled_color", AuthThemeTokens.BUTTON_DISABLED_TEXT)


# ---------------------------------------------------------------- ข้อความ (เขียนเองทั้งหมด ไม่เอาข้อความดิบจาก server)

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
			return "ชื่อในเกมไม่ถูกต้อง"
		AuthApiResult.RATE_LIMITED:
			return "ลองหลายครั้งเกินไป กรุณารอประมาณ %d วินาทีแล้วลองใหม่" % maxi(result.retry_after_sec, 1)
		AuthApiResult.NETWORK_UNAVAILABLE:
			return "เชื่อมต่อ server ไม่ได้ กรุณาลองใหม่"
		AuthApiResult.INVALID_CREDENTIALS:
			return "การเข้าสู่ระบบหมดอายุแล้ว กรุณาออกจากระบบแล้วเข้าสู่ระบบใหม่"
		_:
			return "เกิดข้อผิดพลาดที่ server กรุณาลองใหม่ภายหลัง"


func _consent_failure_message(result: AuthApiResult) -> String:
	match result.code:
		AuthApiResult.VALIDATION_FAILED:
			return "เกมเวอร์ชันนี้ใช้นโยบายฉบับเก่า กรุณาอัปเดตเกมแล้วลองใหม่"
		AuthApiResult.RATE_LIMITED:
			return "ลองหลายครั้งเกินไป กรุณารอประมาณ %d วินาทีแล้วลองใหม่" % maxi(result.retry_after_sec, 1)
		AuthApiResult.NETWORK_UNAVAILABLE:
			return "เชื่อมต่อ server ไม่ได้ กรุณาลองใหม่"
		AuthApiResult.INVALID_CREDENTIALS:
			return "การเข้าสู่ระบบหมดอายุแล้ว กรุณาออกจากระบบแล้วเข้าสู่ระบบใหม่"
		_:
			return "บันทึกไม่สำเร็จ กรุณาลองใหม่ภายหลัง"


func _message_for_reason(reason: String) -> String:
	match reason:
		AuthRules.REQUIRED:
			return "กรุณากรอกชื่อในเกม"
		AuthRules.TOO_LONG:
			return "ชื่อในเกมยาวได้ไม่เกิน %d ตัวอักษร" % AuthRules.DISPLAY_NAME_MAX_LEN
		AuthRules.INVALID_CHARACTERS:
			return "ชื่อในเกมมีตัวอักษรที่ใช้ไม่ได้"
		AuthRules.TAKEN:
			return "ชื่อในเกมนี้มีผู้ใช้แล้ว กรุณาเลือกชื่ออื่น"
		AuthRules.RESERVED:
			return "ชื่อรูปแบบ player-ตัวเลข สงวนไว้ให้ระบบ กรุณาใช้ชื่ออื่น"
		_:
			return "ชื่อในเกมไม่ถูกต้อง"


## แสดงเวลาตามเขตเวลาของเครื่อง รูปแบบ วัน/เดือน/ปี ชั่วโมง:นาที
func _format_local_datetime(unix_time: int) -> String:
	var bias_minutes: int = Time.get_time_zone_from_system().get("bias", 0)
	var d := Time.get_datetime_dict_from_unix_time(unix_time + bias_minutes * 60)
	return "%02d/%02d/%04d %02d:%02d" % [d["day"], d["month"], d["year"], d["hour"], d["minute"]]
