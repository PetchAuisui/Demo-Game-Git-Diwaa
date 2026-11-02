extends Node
## ตัวกลางเก็บสถานะการล็อกอินของผู้เล่น เรียกใช้ได้จากทุกหน้าผ่านชื่อ PlayerSession (autoload)
## (เป็น autoload จึงไม่ประกาศ class_name เพื่อไม่ให้ชื่อชนกับ singleton แบบเดียวกับ GameWindow)
##
## ข้อควรรู้ด้านความปลอดภัย:
## 1. token อยู่ในตัวแปรของไฟล์นี้เท่านั้น ห้าม print ห้ามแสดงบนจอ ใช้ส่งให้ AuthApiClient อย่างเดียว
## 2. ข้อมูลโปรไฟล์ใช้แสดงผลได้ แต่ห้ามใช้ตัดสินสิทธิ์อะไร เพราะผู้เล่นแก้ค่าในเครื่องได้ server เป็นผู้ตัดสินเสมอ

## ส่งออกทุกครั้งที่สถานะการล็อกอินเปลี่ยน (ล็อกอิน / ออกจากระบบ)
signal session_changed

enum State { SIGNED_OUT, ONLINE }

# หน้าที่พาไปหลังล็อกอินสำเร็จ (หน้าแรกของทีม)
const START_SCENE := "res://features/start/start_view.tscn"
const AUTH_SCENE := "res://features/auth/auth_view.tscn"

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


func _ready() -> void:
	_api = AuthApiClient.new()
	add_child(_api)


func is_signed_in() -> bool:
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
	var token := get_token()
	_session = {}
	_remembered = false
	state = State.SIGNED_OUT
	SessionStore.clear()
	session_changed.emit()
	if not token.is_empty():
		# ถ้าเน็ตหลุดก็ไม่เป็นไร ในเครื่องลบไปแล้ว และ token จะหมดอายุเองบน server
		await _api.logout(token)


func has_saved_session() -> bool:
	return SessionStore.has_saved_session()


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
