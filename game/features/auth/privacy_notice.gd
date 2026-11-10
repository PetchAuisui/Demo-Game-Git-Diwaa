class_name PrivacyNotice
extends Control
## หน้าต่างนโยบายความเป็นส่วนตัว ลอยทับหน้าปัจจุบัน มี 2 แบบ
## 1. อ่านอย่างเดียว:  PrivacyNotice.open(get_tree())
## 2. ตอนสมัคร:      var notice := PrivacyNotice.open_for_sign_up(get_tree())
##                    var choice: Array = await notice.closed   # [กดยืนยันไหม, ยินยอมตารางอันดับไหม]
##    ต้องเลื่อนอ่านจนสุดก่อนถึงจะติ๊กได้ และต้องติ๊กรับทราบก่อนถึงจะกดยืนยันได้
##
## ใช้ Label ธรรมดา (ไม่ใช่ RichTextLabel) เพื่อไม่ให้ข้อความถูกตีความเป็นคำสั่งจัดรูปแบบ
## หมายเหตุ: ช่องแรกคือ "รับทราบ" (การแจ้งนโยบาย) ไม่ใช่ "ยินยอม" การยินยอมมีแค่เรื่องตารางอันดับ ซึ่งไม่บังคับ

## ส่งครั้งเดียวตอนหน้าต่างปิด ไม่ว่าปิดทางไหน (ยืนยัน / ยกเลิก / Esc / เปลี่ยนหน้า) คนที่รออยู่จะไม่ค้าง
signal closed(accepted: bool, leaderboard_opt_in: bool)

const SCENE_PATH := "res://features/auth/privacy_notice.tscn"
# เหลือระยะเลื่อนไม่เกินนี้ (pixel) ถือว่าอ่านถึงท้ายแล้ว
const BOTTOM_TOLERANCE := 4.0
# คำอธิบายช่องตารางอันดับ: ชี้ที่ไอคอนแล้วขึ้น เอาเมาส์ออกแล้วหาย / กดไอคอนแล้วค้างไว้จนกว่าจะกดที่อื่นหรือกด Esc
# (tooltip + toggletip: คนที่ชี้ไม่ได้ เช่น จอสัมผัส ก็กดอ่านได้ และอ่านได้นานเท่าที่ต้องการ)
const LEADERBOARD_HELP_TEXT := "ไม่บังคับ ไม่มีผลต่อการสมัครหรือการเล่น\nติ๊ก: ชื่อในเกมของคุณจะขึ้นบนตารางอันดับ ผู้เล่นคนอื่นเห็นได้\nไม่ติ๊ก: เล่นได้ตามปกติ แค่ชื่อจะไม่ขึ้นบนตารางอันดับ\nเปลี่ยนใจได้ทุกเมื่อในหน้า \"บัญชีของฉัน\""
# ระยะห่างระหว่างไอคอนกับกล่องคำอธิบาย และระยะห่างจากขอบจอ (pixel)
const HELP_GAP := 6.0
const HELP_SCREEN_MARGIN := 8.0

var _sign_up_mode := false
var _read_to_end := false
var _closed := false

var _scroll: ScrollContainer
var _ack_check: CheckBox
var _leaderboard_check: CheckBox
var _consent_box: VBoxContainer
var _confirm_btn: Button
var _cancel_btn: Button
var _help_btn: Button
var _help_popup: PanelContainer
var _help_pinned := false


static func open(tree: SceneTree) -> PrivacyNotice:
	return _spawn(tree, false)


static func open_for_sign_up(tree: SceneTree) -> PrivacyNotice:
	return _spawn(tree, true)


static func _spawn(tree: SceneTree, sign_up: bool) -> PrivacyNotice:
	var scene := load(SCENE_PATH) as PackedScene
	if scene == null or tree.current_scene == null:
		push_error("PrivacyNotice: could not open the privacy notice.")
		return null
	var notice := scene.instantiate() as PrivacyNotice
	notice._sign_up_mode = sign_up
	tree.current_scene.add_child(notice)
	return notice


func _ready() -> void:
	_scroll = get_node("%Scroll") as ScrollContainer
	_ack_check = get_node("%AckCheck") as CheckBox
	_leaderboard_check = get_node("%LeaderboardCheck") as CheckBox
	_consent_box = get_node("%ConsentBox") as VBoxContainer
	_confirm_btn = get_node("%ConfirmBtn") as Button
	_cancel_btn = get_node("%CancelBtn") as Button
	_help_btn = get_node("%LeaderboardHelp") as Button
	_help_popup = get_node("%HelpPopup") as PanelContainer
	(get_node("%HelpLabel") as Label).text = LEADERBOARD_HELP_TEXT
	_help_btn.mouse_entered.connect(_show_help)
	_help_btn.mouse_exited.connect(func() -> void:
		if not _help_pinned:
			_hide_help()
	)
	_help_btn.pressed.connect(_on_help_pressed)

	(get_node("%BodyLabel") as Label).text = PrivacyPolicy.notice_text()
	(get_node("%VersionLabel") as Label).text = "ฉบับวันที่ %s" % PrivacyPolicy.VERSION
	_style_button(_confirm_btn)
	_style_button(_cancel_btn)

	_consent_box.visible = _sign_up_mode
	_cancel_btn.visible = _sign_up_mode
	if _sign_up_mode:
		_confirm_btn.text = "ยืนยันและสมัคร"
		_ack_check.disabled = true
		_leaderboard_check.disabled = true
		_ack_check.toggled.connect(func(_on: bool) -> void: _update_confirm())
		var bar := _scroll.get_v_scroll_bar()
		bar.value_changed.connect(func(_value: float) -> void: _check_read_to_end())
		bar.changed.connect(_check_read_to_end)
		_check_read_to_end.call_deferred()
		_cancel_btn.pressed.connect(_finish.bind(false))
		_confirm_btn.pressed.connect(_finish.bind(true))
		_cancel_btn.grab_focus()
	else:
		_confirm_btn.text = "ปิด"
		_confirm_btn.pressed.connect(_finish.bind(false))
		_confirm_btn.grab_focus()
	_update_confirm()


## กล่องคำอธิบายเปิดอยู่: กดที่อื่นหรือกด Esc = ปิดกล่องก่อน (Esc จะไม่ปิดทั้งหน้าต่างในจังหวะนี้)
func _input(event: InputEvent) -> void:
	if not _help_popup.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_hide_help()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if not _help_btn.get_global_rect().has_point((event as InputEventMouseButton).position):
			_hide_help()


## กดไอคอน: ค้างคำอธิบายไว้ / กดซ้ำ: ปิด
func _on_help_pressed() -> void:
	_help_pinned = not _help_pinned
	if _help_pinned:
		_show_help()
	else:
		_hide_help()


func _show_help() -> void:
	_help_popup.visible = true
	_help_popup.size = _help_popup.get_combined_minimum_size()
	# วางใต้ไอคอน ถ้าล้นขอบล่างย้ายไปไว้เหนือไอคอน และไม่ให้ล้นขอบซ้ายขวา
	var anchor := _help_btn.get_global_rect()
	var popup_size := _help_popup.size
	var screen := get_viewport_rect().size
	var pos := Vector2(anchor.position.x, anchor.end.y + HELP_GAP)
	if pos.y + popup_size.y > screen.y - HELP_SCREEN_MARGIN:
		pos.y = anchor.position.y - popup_size.y - HELP_GAP
	pos.x = clampf(pos.x, HELP_SCREEN_MARGIN, maxf(HELP_SCREEN_MARGIN, screen.x - popup_size.x - HELP_SCREEN_MARGIN))
	_help_popup.global_position = pos


func _hide_help() -> void:
	_help_pinned = false
	_help_popup.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish(false)


func _exit_tree() -> void:
	# ถูกปิดโดยไม่ผ่านปุ่ม (เช่น เปลี่ยนหน้า) ก็ยังต้องบอกคนที่รออยู่ ถือว่ายกเลิก
	if not _closed:
		_closed = true
		closed.emit(false, false)


## ปลดล็อกช่องติ๊กเมื่อเลื่อนถึงท้าย (หรือข้อความสั้นจนไม่ต้องเลื่อน)
func _check_read_to_end() -> void:
	if _read_to_end:
		return
	var bar := _scroll.get_v_scroll_bar()
	if bar.page <= 0.0:
		return  # ยังจัดหน้าไม่เสร็จ รอรอบถัดไป
	if bar.value + bar.page < bar.max_value - BOTTOM_TOLERANCE:
		return
	_read_to_end = true
	_ack_check.disabled = false
	_leaderboard_check.disabled = false
	_update_confirm()


func _update_confirm() -> void:
	if _sign_up_mode:
		_confirm_btn.disabled = not (_read_to_end and _ack_check.button_pressed)


func _finish(accepted: bool) -> void:
	if _closed:
		return
	_closed = true
	var confirmed := accepted and _sign_up_mode and _read_to_end and _ack_check.button_pressed
	var opt_in := confirmed and _leaderboard_check.button_pressed
	closed.emit(confirmed, opt_in)
	queue_free()


func _style_button(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", AuthThemeTokens.create_button_style(AuthThemeTokens.BUTTON_BG))
	btn.add_theme_stylebox_override("hover", AuthThemeTokens.create_button_style(AuthThemeTokens.BUTTON_HOVER_BG))
	btn.add_theme_stylebox_override("pressed", AuthThemeTokens.create_button_style(AuthThemeTokens.BUTTON_PRESSED_BG))
	btn.add_theme_stylebox_override("disabled", AuthThemeTokens.create_button_style(AuthThemeTokens.BUTTON_DISABLED_BG))
	btn.add_theme_color_override("font_color", AuthThemeTokens.BUTTON_TEXT)
	btn.add_theme_color_override("font_hover_color", AuthThemeTokens.BUTTON_TEXT)
	btn.add_theme_color_override("font_pressed_color", AuthThemeTokens.BUTTON_TEXT)
	btn.add_theme_color_override("font_disabled_color", AuthThemeTokens.BUTTON_DISABLED_TEXT)
