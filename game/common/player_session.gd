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
# หน้า "บัญชีของฉัน" (ดูชื่อ / เปลี่ยนชื่อ / ออกจากระบบ) ทีมเปิดได้ด้วย change_scene_to_file(ACCOUNT_SCENE)
const ACCOUNT_SCENE := "res://features/auth/account_view.tscn"

# ผลของการล็อกอินอัตโนมัติตอนเปิดเกม (restore_saved_session)
const RESTORE_NONE := "none"  # ไม่มี session ที่จดจำไว้
const RESTORE_OK := "restored"  # ล็อกอินอัตโนมัติสำเร็จ
const RESTORE_NEED_LOGIN := "need_login"  # session หมดอายุหรือถูกยกเลิก ต้องล็อกอินใหม่
const RESTORE_NETWORK_FAILED := "network_failed"  # ติดต่อ server ไม่ได้ (session ในเครื่องยังเก็บไว้ ใช้กับโหมดออฟไลน์)

var state: State = State.SIGNED_OUT
var _session: Dictionary = {}
var _remembered := false
var _api: AuthApiClient
## username ล่าสุดที่เคยล็อกอินในเครื่องนี้ ใช้เติมช่องให้ตอนต้องล็อกอินใหม่ (ไม่ใช่ความลับในเครื่องตัวเอง)
var last_username := ""
## เวลา (unix) ที่เปลี่ยนชื่อที่แสดงได้อีกครั้ง 0 = ยังไม่รู้ ใช้แค่บอกผู้เล่น server เป็นผู้ตัดสินจริง
var display_name_next_change_unix := 0


func _ready() -> void:
	_api = AuthApiClient.new()
	add_child(_api)


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
	_session = session
	_remembered = remember_me
	display_name_next_change_unix = 0
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
	_session = {}
	_remembered = false
	state = State.SIGNED_OUT
	SessionStore.clear()
	session_changed.emit()
	display_name_next_change_unix = 0
	if not token.is_empty():
		# แจ้ง server เบื้องหลัง ไม่ต้องให้หน้าจอรอ ถ้าเน็ตหลุดก็ไม่เป็นไร ในเครื่องลบไปแล้ว และ token จะหมดอายุเองบน server
		_logout_on_server.call_deferred(token)


func _logout_on_server(token: String) -> void:
	await _api.logout(token)


## เปลี่ยนชื่อที่แสดง (ออนไลน์เท่านั้น) server เป็นผู้ตัดสินเรื่องชื่อซ้ำและกฎ 14 วัน
## สำเร็จ: อัปเดตชื่อในเครื่อง (และในไฟล์ถ้าจดจำไว้) แล้วส่ง session_changed
func change_display_name(new_name: String) -> AuthApiResult:
	if state != State.ONLINE:
		return AuthApiResult.failure(0, AuthApiResult.NETWORK_UNAVAILABLE)
	var result := await _api.change_display_name(get_token(), new_name.strip_edges())

	if result.code == AuthApiResult.DISPLAY_NAME_CHANGE_COOLDOWN:
		display_name_next_change_unix = int(Time.get_unix_time_from_system()) + result.retry_after_sec
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
	display_name_next_change_unix = SessionStore.parse_utc_unix(result.data.get("nextChangeAllowedAt"))
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
		_session = fresh
		_remembered = true
		state = State.ONLINE
		if not SessionStore.save(fresh):
			# บันทึก token ใบใหม่ไม่ได้: ลบไฟล์ทิ้ง ห้ามปล่อย token ใบเก่าค้างไว้
			# เพราะถ้าครั้งหน้าเอาใบเก่าไปใช้ server จะเข้าใจว่าถูกขโมย แล้วตัด session ทั้งหมดของบัญชีนี้
			SessionStore.clear()
		session_changed.emit()
		return RESTORE_OK

	if result.code == AuthApiResult.INVALID_CREDENTIALS:
		# server ไม่รับ token นี้แล้ว (หมดอายุ / logout จากที่อื่น / ถูกยกเลิก)
		SessionStore.clear()
		return RESTORE_NEED_LOGIN

	# เน็ตหลุด / server ล่ม / ถูกจำกัดจำนวนครั้ง: เก็บ session ในเครื่องไว้ก่อน ยังไม่ลบ
	return RESTORE_NETWORK_FAILED


func _profile_value(key: String) -> String:
	var profile: Variant = _session.get("profile")
	if not (profile is Dictionary):
		return ""
	var value: Variant = profile.get(key)
	return value if value is String else ""
