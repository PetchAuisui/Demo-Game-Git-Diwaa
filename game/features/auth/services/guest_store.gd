class_name GuestStore
extends RefCounted
## เก็บชื่อของผู้เล่นแบบไม่ล็อกอิน (guest) ไว้ในเครื่อง เพื่อเติมให้อัตโนมัติครั้งหน้า
##
## ข้อควรรู้:
## 1. ชื่อนี้ไม่ใช่ความลับ จึงไม่เข้ารหัส และห้ามส่งไป server หรือ leaderboard เด็ดขาด
## 2. ผู้เล่นแก้ไฟล์นี้เองได้ จึงตรวจขนาดไฟล์และตรวจชื่อด้วยกติกาเดียวกับชื่อที่แสดงทุกครั้งที่อ่าน
## 3. ใช้ JSON แทน ConfigFile เพราะ JSON อ่านออกมาได้แค่ข้อมูลธรรมดา สร้าง object แปลกๆ จากไฟล์ไม่ได้

const FILE_PATH := "user://guest_profile.json"
# ไฟล์จริงมีแค่ชื่อเดียว ไม่กี่สิบ byte ถ้าใหญ่กว่านี้แปลว่าถูกแก้ ไม่ต้องอ่าน
const MAX_FILE_BYTES := 4 * 1024


## อ่านชื่อ guest ที่บันทึกไว้ คืนค่า "" ถ้าไม่มี หรือข้อมูลผิดรูปแบบ
static func load_name() -> String:
	if not FileAccess.file_exists(FILE_PATH):
		return ""
	var file := FileAccess.open(FILE_PATH, FileAccess.READ)
	if file == null:
		return ""
	if file.get_length() > MAX_FILE_BYTES:
		file.close()
		return ""
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return ""
	var value: Variant = (json.data as Dictionary).get("display_name")
	if not (value is String):
		return ""
	var display_name := (value as String).strip_edges()
	return display_name if AuthRules.validate_display_name(display_name).is_empty() else ""


## บันทึกชื่อ guest คืนค่า true ถ้าสำเร็จ (ชื่อต้องผ่านกติกาเดียวกับชื่อที่แสดง)
static func save_name(raw_name: String) -> bool:
	var display_name := raw_name.strip_edges()
	if not AuthRules.validate_display_name(display_name).is_empty():
		return false
	var file := FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"display_name": display_name}))
	file.close()
	return true
