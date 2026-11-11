extends Node
## ตัวกลางเก็บสถานะการล็อกอินของผู้เล่น เรียกใช้ได้จากทุกหน้าผ่านชื่อ PlayerSession (autoload)
## (เป็น autoload จึงไม่ประกาศ class_name เพื่อไม่ให้ชื่อชนกับ singleton แบบเดียวกับ GameWindow)
##
## ข้อควรรู้ด้านความปลอดภัย:
## 1. token อยู่ในตัวแปรของไฟล์นี้เท่านั้น ห้าม print ห้ามแสดงบนจอ ใช้ส่งให้ AuthApiClient อย่างเดียว
## 2. ข้อมูลโปรไฟล์ใช้แสดงผลได้ แต่ห้ามใช้ตัดสินสิทธิ์อะไร เพราะผู้เล่นแก้ค่าในเครื่องได้ server เป็นผู้ตัดสินเสมอ

## ส่งออกทุกครั้งที่สถานะการล็อกอินเปลี่ยน (ล็อกอิน / ออกจากระบบ)
signal session_changed

## SIGNED_OUT = ยังไม่ได้เข้าสู่ระบบ
## ONLINE = เข้าสู่ระบบแล้วและติดต่อ server ได้ ใช้ฟีเจอร์ออนไลน์ได้
## OFFLINE = ใช้บัญชีที่จดจำไว้ในเครื่องตอนติดต่อ server ไม่ได้ เล่นได้แต่ใช้ฟีเจอร์ออนไลน์ไม่ได้
## GUEST = เล่นแบบไม่ล็อกอิน ไม่มีบัญชี ใช้ชื่อที่ตั้งเองในเครื่อง ใช้ฟีเจอร์ออนไลน์ไม่ได้
enum State { SIGNED_OUT, ONLINE, OFFLINE, GUEST }

# หน้าที่พาไปหลังล็อกอินสำเร็จ (หน้าแรกของทีม)
const START_SCENE := "res://features/start/start_view.tscn"
const AUTH_SCENE := "res://features/auth/auth_view.tscn"
# หน้า "บัญชีของฉัน" เปิดแบบลอยทับหน้าปัจจุบันด้วย AccountViewController.open(parent) (เมนูบัญชีเรียกให้แล้ว)
# ตอนนี้ชี้ไปที่หน้าทดสอบ ทำหน้าจริงแล้วให้แก้ path นี้ (รายละเอียดอยู่หัวไฟล์ account_view_controller.gd)
const ACCOUNT_SCENE := "res://features/auth/account_view.tscn"
# ไฟล์ปีเกิดของระบบถามอายุแบบเก่า (เลิกใช้แล้ว) ลบทิ้งตอนเปิดเกม ไม่เก็บข้อมูลที่ไม่ใช้แล้วไว้ในเครื่องผู้เล่น
const LEGACY_AGE_GATE_FILE := "user://age_gate.json"

# ผลของการล็อกอินอัตโนมัติตอนเปิดเกม (restore_saved_session)
const RESTORE_NONE := "none"  # ไม่มี session ที่จดจำไว้
const RESTORE_OK := "restored"  # ล็อกอินอัตโนมัติสำเร็จ
const RESTORE_NEED_LOGIN := "need_login"  # session หมดอายุหรือถูกยกเลิก ต้องล็อกอินใหม่
const RESTORE_NETWORK_FAILED := "network_failed"  # ติดต่อ server ไม่ได้ (session ในเครื่องยังเก็บไว้ ใช้กับโหมดออฟไลน์)
# ต่ออายุ token ล่วงหน้าเมื่อเหลืออายุไม่เกินนี้ (วินาที) ทำตอนจะส่งคำขอที่ใช้ token (ดู _refresh_if_expiring)
const REFRESH_MARGIN_SEC := 30 * 60

const RESTORE_RATE_LIMITED := "rate_limited"  # ลองบ่อยเกินไป ต้องรอ (วินาทีที่ต้องรออยู่ใน last_retry_after_sec) session ในเครื่องยังเก็บไว้

var state: State = State.SIGNED_OUT
var _session: Dictionary = {}
var _remembered := false
var _api: AuthApiClient
## username ล่าสุดที่เคยล็อกอินในเครื่องนี้ ใช้เติมช่องให้ตอนต้องล็อกอินใหม่ (ไม่ใช่ความลับในเครื่องตัวเอง)
var last_username := ""
## วินาทีที่ต้องรอ เมื่อ restore_saved_session() คืนค่า RESTORE_RATE_LIMITED
var last_retry_after_sec := 0
## เวลา (unix) ที่เปลี่ยนชื่อที่แสดงได้อีกครั้ง 0 = ยังไม่รู้ ใช้แค่บอกผู้เล่น server เป็นผู้ตัดสินจริง
var display_name_next_change_unix := 0
## ตอนนี้เปลี่ยนชื่อได้อีกกี่ครั้ง (-1 = ยังไม่รู้) ใช้แค่บอกผู้เล่น server เป็นผู้ตัดสินจริง
var display_name_changes_available := -1
## true = ระหว่างเล่น server ไม่รับ token แล้ว (หมดอายุ / ถูกยกเลิก) สถานะจะเป็น OFFLINE: เล่นต่อได้ แต่ต้องออกจากระบบ
## แล้วเข้าสู่ระบบใหม่ถึงจะใช้ฟีเจอร์ออนไลน์ได้ หน้าจอใช้ค่านี้เลือกข้อความ (ต่างจากออฟไลน์เพราะเน็ตหลุด)
var session_expired := false

var _refreshing := false
signal _refresh_finished

# อีเมลที่จำไว้ในหน่วยความจำ (ดู fetch_email) ห้าม print ห้ามบันทึกลงไฟล์
var _email_cache := ""
var _email_cache_owner := ""
var _email_fetching := false
signal _email_fetched


func _ready() -> void:
	_api = AuthApiClient.new()
	add_child(_api)
	# TODO: ลบ 2 บรรทัดนี้ (และ LEGACY_AGE_GATE_FILE) ได้เมื่อไม่มีใครใช้เวอร์ชันที่ถามปีเกิดแล้ว
	if FileAccess.file_exists(LEGACY_AGE_GATE_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_AGE_GATE_FILE))


## มีบัญชีจริงอยู่ไหม (ONLINE หรือ OFFLINE) guest ไม่นับ
func is_signed_in() -> bool:
	return state == State.ONLINE or state == State.OFFLINE


func is_guest() -> bool:
	return state == State.GUEST


## มีผู้เล่นพร้อมเล่นแล้วหรือยัง (บัญชีจริง หรือ guest)
func has_player() -> bool:
	return state != State.SIGNED_OUT


func get_display_name() -> String:
	return _profile_value("display_name")


func get_username() -> String:
	return _profile_value("username")


func get_user_id() -> String:
	return _profile_value("id")


## ใช้ตอนเรียก server เท่านั้น ห้ามเก็บไว้ที่อื่น และห้าม print
func get_token() -> String:
	var token: Variant = _session.get("token")
	return token if token is String else ""


## เริ่ม session จากคำตอบของ server ตอนล็อกอิน คืนค่า false ถ้าข้อมูลจาก server ผิดรูปแบบ
func start_session(login_data: Dictionary, remember_me: bool) -> bool:
	var session := SessionStore.from_login_response(login_data)
	if session.is_empty():
		return false
	_forget_email()  # ล็อกอินใหม่: ห้ามใช้อีเมลที่จำไว้ของบัญชีก่อนหน้า
	session_expired = false
	_session = session
	_remembered = remember_me
	display_name_next_change_unix = 0
	display_name_changes_available = -1
	state = State.ONLINE
	if remember_me:
		if not SessionStore.save(session):
			push_warning("PlayerSession: could not save the session; it will last until the game closes.")
	else:
		# ไม่ได้ติ๊กจดจำ: ลบ session เก่าที่อาจเคยจดจำไว้ด้วย คนที่ใช้เครื่องต่อจะได้เข้าบัญชีนั้นไม่ได้
		SessionStore.clear()
	session_changed.emit()
	return true


## ออกจากระบบ: ลบ session ในเครื่องก่อน แล้วค่อยแจ้ง server ให้ยกเลิก token
func sign_out() -> void:
	if state == State.GUEST:
		# guest ไม่มีบัญชี: แค่ออกจากโหมด guest ห้ามลบ session ของบัญชีที่จดจำไว้ในเครื่อง
		_session = {}
		state = State.SIGNED_OUT
		session_changed.emit()
		return
	var token := get_token()
	session_expired = false
	_forget_email()
	_session = {}
	_remembered = false
	state = State.SIGNED_OUT
	SessionStore.clear()
	session_changed.emit()
	display_name_next_change_unix = 0
	display_name_changes_available = -1
	if not token.is_empty():
		# แจ้ง server เบื้องหลัง ไม่ต้องให้หน้าจอรอ ถ้าเน็ตหลุดก็ไม่เป็นไร ในเครื่องลบไปแล้ว และ token จะหมดอายุเองบน server
		_logout_on_server.call_deferred(token)


func _logout_on_server(token: String) -> void:
	await _api.logout(token)


# ---------------------------------------------------------------- คำขอที่ใช้ token

## ส่งคำขอที่ใช้ token (ทุกฟังก์ชันออนไลน์ด้านล่างเรียกผ่านตัวนี้) request รับ token แล้วคืน AuthApiResult
## 1. ก่อนส่ง: ถ้า token ใกล้หมดอายุ ต่ออายุก่อน ผู้เล่นที่เปิดเกมค้างไว้นานจะไม่หลุดกลางทาง
## 2. หลังส่ง: ถ้า server ไม่รับ token แล้ว เปลี่ยนเป็นออฟไลน์และบอกทุกหน้า (session_changed)
##    เดิมสถานะค้างเป็น ONLINE ทั้งที่ทุกฟีเจอร์ออนไลน์ล้มจนกว่าจะปิดเกมแล้วเปิดใหม่
func _send_with_token(request: Callable) -> AuthApiResult:
	if state != State.ONLINE:
		return AuthApiResult.failure(0, AuthApiResult.NETWORK_UNAVAILABLE)
	await _refresh_if_expiring()
	if state != State.ONLINE:
		return AuthApiResult.failure(0, AuthApiResult.INVALID_CREDENTIALS)
	var owner_id := get_user_id()
	var result: AuthApiResult = await request.call(get_token())
	# ระหว่างรอ ออกจากระบบ / เปลี่ยนบัญชีไปแล้ว: คำตอบนี้ไม่เกี่ยวกับ session ปัจจุบัน
	if result.code == AuthApiResult.INVALID_CREDENTIALS and state == State.ONLINE and get_user_id() == owner_id:
		_end_online_session()
	return result


## ต่ออายุ token ถ้าเหลืออายุไม่เกิน REFRESH_MARGIN_SEC (server เปลี่ยน token ใบใหม่ให้ ใบเก่าใช้ไม่ได้อีก)
## ไม่ต่ออายุเมื่อเจอ 401 เฉยๆ: token ที่ถูกยกเลิกแล้วเอาไปต่ออายุ server จะถือว่าถูกขโมยและตัดทุก session ของบัญชี
func _refresh_if_expiring() -> void:
	if _refreshing:
		await _refresh_finished  # มีคำขออื่นกำลังต่ออายุอยู่ รอผลเดียวกัน ห้ามต่อซ้อน (ใบเก่าใช้ได้ครั้งเดียว)
		return
	var expires: Variant = _session.get("expires_unix")
	if not (expires is int):
		return
	var seconds_left := int(expires) - int(Time.get_unix_time_from_system())
	if seconds_left > REFRESH_MARGIN_SEC:
		return
	if seconds_left <= 0:
		_end_online_session()  # หมดอายุไปแล้ว server ไม่ต่อให้ ต้องเข้าสู่ระบบใหม่
		return

	_refreshing = true
	var owner_id := get_user_id()
	var result := await _api.refresh(get_token())
	_refreshing = false
	var fresh := SessionStore.from_login_response(result.data) if result.ok else {}
	if state != State.ONLINE or get_user_id() != owner_id:
		# ระหว่างรอ ออกจากระบบไปแล้ว: token ใบใหม่ไม่มีใครใช้ แจ้ง server ให้ยกเลิกด้วย
		if not fresh.is_empty():
			_logout_on_server.call_deferred(fresh["token"])
	elif result.ok:
		var fresh_profile: Dictionary = fresh.get("profile", {})
		if fresh.is_empty() or fresh_profile.get("id") != owner_id:
			_end_online_session()
		else:
			_session = fresh
			if _remembered and not SessionStore.save(fresh):
				# บันทึกใบใหม่ไม่ได้: ลบไฟล์ทิ้ง ห้ามปล่อยใบเก่าค้างไว้ (เหตุผลเดียวกับ restore_saved_session)
				SessionStore.clear()
	elif result.code == AuthApiResult.INVALID_CREDENTIALS:
		_end_online_session()
	# เน็ตหลุด / ถูกจำกัดจำนวนครั้ง: ใช้ token ใบเดิมไปก่อน (ยังไม่หมดอายุ) คำขอครั้งหน้าจะลองต่ออายุใหม่
	_refresh_finished.emit()


## server ไม่รับ token แล้ว: ทิ้ง token ทั้งในหน่วยความจำและในไฟล์ แล้วเล่นต่อแบบออฟไลน์ในบัญชีเดิม
## (ความคืบหน้ายังอยู่กับบัญชีเดิม) ไม่เก็บ token ที่ใช้ไม่ได้ไว้: ครั้งหน้าที่เปิดเกมจะได้ถามล็อกอินใหม่ตรงๆ
## ไม่ใช่เอาใบที่ถูกยกเลิกไปต่ออายุจน server ตัดทุก session
func _end_online_session() -> void:
	if state != State.ONLINE:
		return
	var profile: Dictionary = (_session.get("profile", {}) as Dictionary).duplicate()
	last_username = profile.get("username", "")
	_forget_email()
	_session = {"profile": profile}
	_remembered = false
	SessionStore.clear()
	display_name_next_change_unix = 0
	display_name_changes_available = -1
	session_expired = true
	state = State.OFFLINE
	session_changed.emit()


## ดูว่าตอนนี้ยินยอมให้แสดงชื่อบนตารางอันดับไหม (ออนไลน์เท่านั้น)
## สำเร็จ: result.data["leaderboardOptIn"] เป็น bool (ตรวจชนิดอีกครั้งก่อนใช้)
func get_leaderboard_consent() -> AuthApiResult:
	if state != State.ONLINE:
		return AuthApiResult.failure(0, AuthApiResult.NETWORK_UNAVAILABLE)
	return await _send_with_token(func(token: String) -> AuthApiResult:
		return await _api.get_leaderboard_consent(token))


## ให้หรือถอนความยินยอมแสดงชื่อบนตารางอันดับ ส่งเวอร์ชันนโยบายที่เกมนี้แสดงไปด้วย
func set_leaderboard_consent(granted: bool) -> AuthApiResult:
	if state != State.ONLINE:
		return AuthApiResult.failure(0, AuthApiResult.NETWORK_UNAVAILABLE)
	return await _send_with_token(func(token: String) -> AuthApiResult:
		return await _api.set_leaderboard_consent(token, granted, PrivacyPolicy.VERSION))


## ถาม server ว่าตอนนี้เปลี่ยนชื่อได้อีกกี่ครั้ง / เมื่อไหร่ (ออนไลน์เท่านั้น) ผลเก็บไว้ที่
## display_name_changes_available และ display_name_next_change_unix
func refresh_display_name_status() -> AuthApiResult:
	if state != State.ONLINE:
		return AuthApiResult.failure(0, AuthApiResult.NETWORK_UNAVAILABLE)
	var result := await _send_with_token(func(token: String) -> AuthApiResult:
		return await _api.get_display_name_status(token))
	if result.ok:
		_apply_display_name_status(result.data)
	return result


## อ่านสถานะจากคำตอบของ server แบบตรวจชนิดก่อนใช้ ค่าแปลกๆ ถือว่า "ยังไม่รู้"
func _apply_display_name_status(data: Dictionary) -> void:
	var changes: Variant = data.get("changesAvailable")
	if changes is int or changes is float:
		display_name_changes_available = clampi(int(changes), 0, 10)
	else:
		display_name_changes_available = -1
	display_name_next_change_unix = SessionStore.parse_utc_unix(data.get("nextChangeAllowedAt"))


## อีเมลของบัญชีที่ล็อกอินอยู่ (คืน "" ถ้าไม่ออนไลน์ / ขอไม่สำเร็จ)
## ขอจาก server ครั้งแรกครั้งเดียวต่อการล็อกอิน แล้วจำไว้ในหน่วยความจำ (ลดคำขอที่กินโควตาของ server)
## ไม่เก็บลงไฟล์ และลืมทิ้งทันทีเมื่อออกจากระบบ / ล็อกอินบัญชีใหม่ (_forget_email)
## ใช้แสดงให้เจ้าของดูเท่านั้น (เมนูบัญชีปิดบังไว้ก่อน) ห้าม print หรือส่งต่อไปที่อื่น
func fetch_email() -> String:
	if state != State.ONLINE:
		return ""
	var owner_id := get_user_id()
	if _email_fetching:
		# มีคนกำลังขออยู่ (เช่น เมนูกับหน้าบัญชีเปิดพร้อมกัน) รอผลเดียวกัน ไม่ต้องขอซ้ำ
		await _email_fetched
		return _cached_email_for(owner_id)
	if not _cached_email_for(owner_id).is_empty():
		return _email_cache

	_email_fetching = true
	var result := await _send_with_token(func(token: String) -> AuthApiResult:
		return await _api.get_my_email(token))
	_email_fetching = false
	var email: Variant = result.data.get("email") if result.ok else null
	# ระหว่างรอ ออกจากระบบ / เปลี่ยนบัญชีไปแล้ว: ไม่จำ และไม่คืนอีเมลของบัญชีเก่า
	if email is String and (email as String).length() <= 254 and (email as String).contains("@") \
			and state == State.ONLINE and get_user_id() == owner_id:
		_email_cache = email
		_email_cache_owner = owner_id
	_email_fetched.emit()
	return _cached_email_for(owner_id)


func _cached_email_for(owner_id: String) -> String:
	if state != State.ONLINE or owner_id.is_empty() or _email_cache_owner != owner_id or get_user_id() != owner_id:
		return ""
	return _email_cache


func _forget_email() -> void:
	_email_cache = ""
	_email_cache_owner = ""


## เปลี่ยนชื่อที่แสดง (ออนไลน์เท่านั้น) server เป็นผู้ตัดสินเรื่องชื่อซ้ำและกฎ 14 วัน
## สำเร็จ: อัปเดตชื่อในเครื่อง (และในไฟล์ถ้าจดจำไว้) แล้วส่ง session_changed
func change_display_name(new_name: String) -> AuthApiResult:
	if state != State.ONLINE:
		return AuthApiResult.failure(0, AuthApiResult.NETWORK_UNAVAILABLE)
	var trimmed_name := new_name.strip_edges()
	var result := await _send_with_token(func(token: String) -> AuthApiResult:
		return await _api.change_display_name(token, trimmed_name))

	if result.code == AuthApiResult.DISPLAY_NAME_CHANGE_COOLDOWN:
		display_name_next_change_unix = int(Time.get_unix_time_from_system()) + result.retry_after_sec
		display_name_changes_available = 0
	if not result.ok:
		return result

	# ตรวจคำตอบของ server ก่อนเชื่อ: ต้องเป็นบัญชีเดิม และชื่อต้องผ่านกติกา
	var profile: Variant = result.data.get("profile")
	if not (profile is Dictionary):
		return AuthApiResult.failure(result.status, AuthApiResult.SERVER_ERROR)
	var new_id: Variant = (profile as Dictionary).get("id")
	var display_name: Variant = (profile as Dictionary).get("displayName")
	if not (new_id is String) or new_id != get_user_id():
		return AuthApiResult.failure(result.status, AuthApiResult.SERVER_ERROR)
	if not (display_name is String) or not AuthRules.validate_display_name(display_name).is_empty():
		return AuthApiResult.failure(result.status, AuthApiResult.SERVER_ERROR)

	var session_profile: Dictionary = _session["profile"]
	session_profile["display_name"] = display_name
	_apply_display_name_status(result.data)
	if _remembered and not SessionStore.save(_session):
		push_warning("PlayerSession: could not save the new display name.")
	session_changed.emit()
	return result


func has_saved_session() -> bool:
	return SessionStore.has_saved_session()


## ใช้ฟีเจอร์ออนไลน์ได้ไหม (leaderboard, เปลี่ยนชื่อ ฯลฯ) หน้าอื่นต้องเช็คตัวนี้ ไม่ใช่ is_signed_in()
func is_online() -> bool:
	return state == State.ONLINE


## ชื่อที่แสดงของบัญชีที่จดจำไว้ในเครื่อง ("" ถ้าไม่มี) ใช้บอกผู้เล่นว่าจะเล่นออฟไลน์ในชื่อไหน
func get_saved_display_name() -> String:
	var saved := SessionStore.load_session()
	if saved.is_empty():
		return ""
	var saved_profile: Dictionary = saved["profile"]
	return saved_profile["display_name"]


## เข้าเล่นแบบออฟไลน์ด้วยบัญชีที่จดจำไว้ในเครื่อง ใช้ตอนติดต่อ server ไม่ได้เท่านั้น
## ไม่มีวันหมดอายุ (token หมดอายุแค่ทำให้ใช้ฟีเจอร์ออนไลน์ไม่ได้)
## ความปลอดภัย: ไม่โหลด token ขึ้นมาในโหมดนี้ (token ยังอยู่ในไฟล์ไว้ล็อกอินอัตโนมัติครั้งหน้า)
## และข้อมูลในไฟล์ผู้เล่นแก้เองได้ จึงห้ามให้โหมดนี้ปลดล็อกอะไรที่ server ต้องเป็นผู้ตัดสิน
func start_offline() -> bool:
	if state == State.ONLINE:
		return false
	var saved := SessionStore.load_session()
	if saved.is_empty():
		return false
	var saved_profile: Dictionary = saved["profile"]
	_session = {"profile": saved_profile.duplicate()}
	_remembered = true
	session_expired = false
	last_username = saved_profile["username"]
	state = State.OFFLINE
	session_changed.emit()
	return true


## เข้าเล่นแบบไม่ล็อกอิน (guest) ด้วยชื่อที่ตั้งเอง คืนค่า false ถ้าชื่อไม่ผ่านกติกา
## ชื่อนี้อยู่ในเครื่องเท่านั้น ห้ามส่งไป server / leaderboard (หน้าอื่นเช็คด้วย is_online())
func start_guest(raw_name: String) -> bool:
	if state == State.ONLINE:
		return false
	var display_name := raw_name.strip_edges()
	if not AuthRules.validate_display_name(display_name).is_empty():
		return false
	_session = {"profile": {"id": "", "username": "", "display_name": display_name}}
	_remembered = false
	session_expired = false
	state = State.GUEST
	session_changed.emit()
	return true


## ล็อกอินอัตโนมัติด้วย session ที่จดจำไว้ โดยขอ token ใบใหม่จาก server (token ใบเก่าจะใช้ไม่ได้อีก)
## คืนค่าเป็น RESTORE_* ตัวใดตัวหนึ่ง
func restore_saved_session() -> String:
	var saved := SessionStore.load_session()
	if saved.is_empty():
		return RESTORE_NONE
	var saved_profile: Dictionary = saved["profile"]
	last_username = saved_profile["username"]

	if SessionStore.is_expired(saved):
		SessionStore.clear()
		return RESTORE_NEED_LOGIN

	var result := await _api.refresh(saved["token"])
	if result.ok:
		var fresh := SessionStore.from_login_response(result.data)
		if fresh.is_empty():
			SessionStore.clear()
			return RESTORE_NEED_LOGIN
		# server เปลี่ยน token ให้แล้ว ใบเก่าใช้ไม่ได้อีก ต้องเก็บใบใหม่เสมอ (แม้ผู้เล่นจะเลือกเล่นแบบอื่นไประหว่างรอ)
		if not SessionStore.save(fresh):
			# บันทึก token ใบใหม่ไม่ได้: ลบไฟล์ทิ้ง ห้ามปล่อย token ใบเก่าค้างไว้
			# เพราะถ้าครั้งหน้าเอาใบเก่าไปใช้ server จะเข้าใจว่าถูกขโมย แล้วตัด session ทั้งหมดของบัญชีนี้
			SessionStore.clear()
		# ระหว่างรอ ผู้เล่นเลือกเล่นแบบอื่นไปแล้ว (เช่น เล่นโดยไม่ล็อกอิน): ไม่เปลี่ยนสถานะทับการเลือกนั้น
		# ครั้งหน้าที่เปิดเกมจะล็อกอินอัตโนมัติด้วย token ใบใหม่ที่เก็บไว้ได้ตามปกติ
		if state != State.SIGNED_OUT:
			return RESTORE_NONE
		_session = fresh
		_remembered = true
		session_expired = false
		state = State.ONLINE
		session_changed.emit()
		return RESTORE_OK

	if result.code == AuthApiResult.INVALID_CREDENTIALS:
		# server ไม่รับ token นี้แล้ว (หมดอายุ / logout จากที่อื่น / ถูกยกเลิก)
		SessionStore.clear()
		return RESTORE_NEED_LOGIN

	if result.code == AuthApiResult.RATE_LIMITED:
		# server ยังอยู่ แค่ต้องรอ: เก็บ session ในเครื่องไว้ ครบเวลาแล้วลองใหม่ได้
		last_retry_after_sec = result.retry_after_sec
		return RESTORE_RATE_LIMITED

	# เน็ตหลุด / server ล่ม: เก็บ session ในเครื่องไว้ก่อน ยังไม่ลบ
	# ถ้าคำขอไปถึง server แล้วแต่คำตอบหาย token ในไฟล์จะเป็นใบเก่า: server ผ่อนผันให้ต่ออายุซ้ำด้วยใบเก่าได้ 60 วินาที
	# (กด "ลองใหม่" ทัน = เข้าได้ตามปกติ) เลยจากนั้นใบเก่าจะถูกมองว่าถูกขโมย ต้องล็อกอินใหม่ทุกเครื่อง
	return RESTORE_NETWORK_FAILED


## ชื่อโฟลเดอร์เซฟของผู้เล่นตอนนี้ ให้ระบบเซฟใช้แยกความคืบหน้าของแต่ละคน (เช่น user://saves/<slot>/)
## บัญชี (ออนไลน์/ออฟไลน์) = "user_<id>" ใช้ id เพราะไม่เปลี่ยน (ชื่อที่แสดงเปลี่ยนได้ทุก 14 วัน)
## guest = "guest" / ยังไม่มีผู้เล่น = ""
## ข้อควรรู้: ไฟล์เซฟอยู่ในเครื่อง ผู้เล่นแก้เองได้ ห้ามใช้เป็นแหล่งคะแนนของ leaderboard
func get_save_slot() -> String:
	match state:
		State.ONLINE, State.OFFLINE:
			var user_id := get_user_id()
			return "user_" + user_id if _is_safe_slot_id(user_id) else ""
		State.GUEST:
			return "guest"
		_:
			return ""


## id ต้องเป็น GUID ตัวพิมพ์เล็กเท่านั้น (36 ตัว: 0-9 a-f -) เพราะจะถูกเอาไปต่อเป็นชื่อโฟลเดอร์
## กันไม่ให้ id ที่ถูกแก้ในไฟล์ (เช่น "../..") พาไปเขียนไฟล์นอกโฟลเดอร์เซฟ
func _is_safe_slot_id(value: String) -> bool:
	if value.length() != 36:
		return false
	for i in range(value.length()):
		var c := value.unicode_at(i)
		var is_digit := c >= 0x30 and c <= 0x39  # 0-9
		var is_hex_lower := c >= 0x61 and c <= 0x66  # a-f
		if not (is_digit or is_hex_lower or c == 0x2D):  # -
			return false
	return true


func _profile_value(key: String) -> String:
	var profile: Variant = _session.get("profile")
	if not (profile is Dictionary):
		return ""
	var value: Variant = profile.get(key)
	return value if value is String else ""
