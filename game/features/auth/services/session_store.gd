class_name SessionStore
extends RefCounted
## เก็บ session (token + โปรไฟล์) ไว้ในเครื่อง เพื่อให้ "จดจำการเข้าสู่ระบบ" และโหมดออฟไลน์ใช้ได้
##
## ข้อควรรู้ด้านความปลอดภัย:
## 1. เก็บเฉพาะเมื่อผู้เล่นติ๊ก "จดจำการเข้าสู่ระบบ" และไม่เก็บรหัสผ่านเด็ดขาด เก็บแค่ token
## 2. ไฟล์ถูกเข้ารหัสด้วยกุญแจที่สร้างจากรหัสประจำเครื่อง: copy ไฟล์ไปเครื่องอื่นแล้วเปิดไม่ได้
## 3. ข้อจำกัด: กันโปรแกรมอันตรายที่อยู่ในเครื่องเดียวกันไม่ได้ เพราะ Godot ไม่มีที่เก็บความลับของระบบ
##    (Keychain / Credential Manager) ให้ใช้ ชดเชยด้วย token มีวันหมดอายุ และ server ยกเลิก token ได้
## 4. ข้อมูลที่อ่านจากไฟล์ถูกตรวจทุกช่องก่อนใช้ ไฟล์เสียหรือถูกแก้ จะถูกลบทิ้งแล้วให้ล็อกอินใหม่

const FOLDER := "user://auth"
const FILE_PATH := "user://auth/session.dat"
# เขียนลงไฟล์ชั่วคราวก่อน แล้วค่อยสลับชื่อ ถ้าเกมดับกลางทาง ไฟล์ session เดิมจะไม่พัง
const TEMP_PATH := "user://auth/session.tmp"
const FORMAT_VERSION := 1
# ค่าผสมกุญแจ (ไม่ใช่ความลับ ผู้เล่นแกะอ่านได้) ใช้กันไม่ให้กุญแจซ้ำกับโปรแกรมอื่นที่ใช้รหัสเครื่องเหมือนกัน
const KEY_SALT := "git-diwaa/auth-session/v1"

const MAX_TOKEN_LENGTH := 128
const MAX_TEXT_LENGTH := 254


## แปลงคำตอบของ server ตอนล็อกอิน ({"profile": {...}, "token": ..., "expiresAt": ...})
## ให้เป็น session ที่เกมใช้ คืนค่า {} ถ้าข้อมูลไม่ครบหรือผิดรูปแบบ
static func from_login_response(data: Dictionary) -> Dictionary:
	var profile: Variant = data.get("profile")
	if not (profile is Dictionary):
		return {}
	var session := {
		"version": FORMAT_VERSION,
		"token": data.get("token"),
		"expires_unix": _parse_utc_unix(data.get("expiresAt")),
		"profile": {
			"id": profile.get("id"),
			"username": profile.get("username"),
			"display_name": profile.get("displayName"),
		},
	}
	return session if is_valid(session) else {}


## ตรวจว่า session มีครบทุกช่อง และทุกช่องเป็นชนิดที่ถูกต้อง
static func is_valid(session: Dictionary) -> bool:
	if session.get("version") != FORMAT_VERSION:
		return false
	var token: Variant = session.get("token")
	if not (token is String) or not _is_safe_token(token):
		return false
	var expires: Variant = session.get("expires_unix")
	if not (expires is int) or expires <= 0:
		return false
	var profile: Variant = session.get("profile")
	if not (profile is Dictionary):
		return false
	for key in ["id", "username", "display_name"]:
		var value: Variant = profile.get(key)
		if not (value is String) or value.is_empty() or value.length() > MAX_TEXT_LENGTH:
			return false
	return true


## เช็คว่าหมดอายุหรือยัง (ใช้นาฬิกาในเครื่อง จึงใช้แค่ตัดสินว่าควรลองต่ออายุไหม server เป็นผู้ตัดสินจริงเสมอ)
static func is_expired(session: Dictionary) -> bool:
	var expires: Variant = session.get("expires_unix")
	if not (expires is int):
		return true
	return int(Time.get_unix_time_from_system()) >= expires


## บันทึก session ลงเครื่อง คืนค่า true ถ้าสำเร็จ
static func save(session: Dictionary) -> bool:
	if not is_valid(session):
		return false
	var key := _derive_key()
	if key.is_empty():
		# เครื่องนี้ไม่มีรหัสประจำเครื่อง: ไม่บันทึก ดีกว่าบันทึกด้วยกุญแจที่ทุกเครื่องเหมือนกัน
		return false
	if not DirAccess.dir_exists_absolute(FOLDER) and DirAccess.make_dir_recursive_absolute(FOLDER) != OK:
		return false

	var file := FileAccess.open_encrypted_with_pass(TEMP_PATH, FileAccess.WRITE, key)
	if file == null:
		return false
	file.store_string(JSON.stringify(session))
	file.close()

	if DirAccess.rename_absolute(TEMP_PATH, FILE_PATH) != OK:
		# บางระบบสลับชื่อทับไฟล์เดิมไม่ได้: ลบไฟล์เดิมแล้วลองใหม่
		DirAccess.remove_absolute(FILE_PATH)
		if DirAccess.rename_absolute(TEMP_PATH, FILE_PATH) != OK:
			DirAccess.remove_absolute(TEMP_PATH)
			return false
	return true


## อ่าน session จากเครื่อง คืนค่า {} ถ้าไม่มี อ่านไม่ได้ หรือข้อมูลผิดรูปแบบ (และลบไฟล์ที่เสียทิ้ง)
static func load_session() -> Dictionary:
	if not FileAccess.file_exists(FILE_PATH):
		return {}
	var key := _derive_key()
	if key.is_empty():
		return {}

	var file := FileAccess.open_encrypted_with_pass(FILE_PATH, FileAccess.READ, key)
	if file == null:
		# กุญแจไม่ตรง (ไฟล์มาจากเครื่องอื่น) หรือไฟล์ถูกแก้
		clear()
		return {}
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		clear()
		return {}
	var session: Dictionary = json.data
	# JSON อ่านตัวเลขออกมาเป็น float เสมอ แปลงกลับเป็น int ก่อนตรวจ
	var expires: Variant = session.get("expires_unix")
	if expires is float:
		session["expires_unix"] = int(expires)
	var version: Variant = session.get("version")
	if version is float:
		session["version"] = int(version)
	if not is_valid(session):
		clear()
		return {}
	return session


## มีไฟล์ session ที่จดจำไว้หรือเปล่า (ยังไม่ได้ตรวจว่าใช้ได้ไหม)
static func has_saved_session() -> bool:
	return FileAccess.file_exists(FILE_PATH)


## ลบ session ออกจากเครื่อง (ใช้ตอน logout, token ใช้ไม่ได้แล้ว หรือไฟล์เสีย)
static func clear() -> void:
	for path in [FILE_PATH, TEMP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


static func _derive_key() -> String:
	var machine_id := OS.get_unique_id()
	if machine_id.is_empty():
		return ""
	return (KEY_SALT + machine_id).sha256_text()


## แปลงเวลาแบบ ISO 8601 ที่ server ส่งมา (เช่น "2026-12-02T09:00:00.1234567+00:00") เป็น unix time
## server ส่งเวลาเป็น UTC เสมอ จึงตัดเศษวินาทีและ timezone ทิ้งได้ คืนค่า 0 ถ้ารูปแบบผิด
static func _parse_utc_unix(value: Variant) -> int:
	if not (value is String) or value.length() < 19:
		return 0
	var text: String = value
	if not (text.ends_with("Z") or text.ends_with("+00:00")):
		return 0
	var unix := Time.get_unix_time_from_datetime_string(text.substr(0, 19))
	return unix if unix > 0 else 0


static func _is_safe_token(token: String) -> bool:
	if token.is_empty() or token.length() > MAX_TOKEN_LENGTH:
		return false
	for i in range(token.length()):
		var c := token.unicode_at(i)
		var is_lower := c >= 0x61 and c <= 0x7A  # a-z
		var is_upper := c >= 0x41 and c <= 0x5A  # A-Z
		var is_digit := c >= 0x30 and c <= 0x39  # 0-9
		var is_url_safe := c == 0x2D or c == 0x5F  # - _
		if not (is_lower or is_upper or is_digit or is_url_safe):
			return false
	return true
