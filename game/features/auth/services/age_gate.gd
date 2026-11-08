class_name AgeGate
extends RefCounted
## ถามปีเกิดครั้งแรกที่เปิดเกม แล้วจำคำตอบไว้ในเครื่อง ใช้ตัดสินว่าใช้บัญชีออนไลน์ได้ไหม
##
## ข้อควรรู้:
## 1. ผู้เล่นตอบเอง เราตรวจสอบจริงไม่ได้ (ไม่ขอบัตรประชาชน ตามที่ตกลงกันไว้)
## 2. ปีเกิดเก็บในเครื่องนี้เท่านั้น ห้ามส่งไป server (เก็บข้อมูลเท่าที่จำเป็น ตาม PDPA)
## 3. รู้แค่ปีเกิด ไม่รู้วันเกิด จึงคิดอายุแบบระมัดระวัง: ถือว่าปีนี้ยังไม่ถึงวันเกิด
##    คนที่เพิ่งอายุครบ 20 ในปีนี้จะใช้ออนไลน์ได้ตั้งแต่ 1 ม.ค. ปีถัดไป

const FILE_PATH := "user://age_gate.json"
const ONLINE_MIN_AGE := 20
# ให้เลือกปีเกิดย้อนหลังได้ไม่เกินกี่ปี
const MAX_AGE := 100
const MAX_FILE_BYTES := 1024

# ถ้าบันทึกไฟล์ไม่ได้ ใช้คำตอบนี้ไปก่อนจนกว่าจะปิดเกม จะได้ไม่ต้องถามซ้ำทุกหน้า
static var _unsaved_birth_year := 0


static func current_year() -> int:
	return int(Time.get_date_dict_from_system()["year"])


static func is_valid_birth_year(birth_year: int) -> bool:
	var year_now := current_year()
	return birth_year >= year_now - MAX_AGE and birth_year <= year_now


static func has_answer() -> bool:
	return load_birth_year() != 0


## อายุขั้นต่ำที่แน่ใจได้ (ปีปัจจุบัน - ปีเกิด - 1)
static func conservative_age(birth_year: int) -> int:
	return current_year() - birth_year - 1


## ใช้บัญชีออนไลน์ได้ไหม (ยังไม่ตอบ = ไม่ได้)
static func is_online_allowed() -> bool:
	var birth_year := load_birth_year()
	return birth_year != 0 and conservative_age(birth_year) >= ONLINE_MIN_AGE


## คืนปีเกิด (ค.ศ.) ที่บันทึกไว้ หรือ 0 ถ้ายังไม่ตอบ / ไฟล์ผิดรูปแบบ (ผู้เล่นแก้ไฟล์เองได้ จึงตรวจทุกครั้ง)
static func load_birth_year() -> int:
	if not FileAccess.file_exists(FILE_PATH):
		return _unsaved_birth_year
	var file := FileAccess.open(FILE_PATH, FileAccess.READ)
	if file == null:
		return _unsaved_birth_year
	if file.get_length() > MAX_FILE_BYTES:
		file.close()
		return 0
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return 0
	var value: Variant = (json.data as Dictionary).get("birth_year")
	if not (value is float or value is int):
		return 0
	var birth_year := int(value)
	return birth_year if is_valid_birth_year(birth_year) else 0


## บันทึกปีเกิด (ค.ศ.) คืนค่า true ถ้าบันทึกลงไฟล์ได้
static func save_birth_year(birth_year: int) -> bool:
	if not is_valid_birth_year(birth_year):
		return false
	_unsaved_birth_year = birth_year
	var file := FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"birth_year": birth_year}))
	file.close()
	return true
