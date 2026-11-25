class_name FragmentLedger
extends RefCounted
## สมุดเศษคัมภีร์ต้นกำเนิด: เศษ 12 ชิ้นที่ปรมาจารย์ทิ้งไว้ ได้ทีละชิ้นในด่าน 4–15 (ตามเนื้อเรื่องเดิม)
## ข้อความของแต่ละชิ้นต้องตรงกับไฟล์ด่าน — เทสต์ "fragment ledger" ตรวจว่าทุกด่านยังให้เศษของตัวเองอยู่
## ใช้แสดงตัวนับ n/12 ในห้อง และฉากรับเศษเมื่อเนื้อเรื่องบอกว่า "ได้รับเศษคัมภีร์ชิ้นที่ N"

const TOTAL := 12
const FRAGMENTS := {
	1: {"level": 4, "text": "ศิษย์ของข้า…"},
	2: {"level": 5, "text": "ความรู้ที่ไม่ถูกจารึก"},
	3: {"level": 6, "text": "ย่อมสูญหายไปกับกาลเวลา"},
	4: {"level": 7, "text": "จงสังเกตทุกรอยที่เปลี่ยนไป"},
	5: {"level": 8, "text": "ความผิดพลาดแก้ไขได้เสมอ"},
	6: {"level": 9, "text": "หากเจ้ากล้าย้อนกลับไปมอง"},
	7: {"level": 10, "text": "เส้นทางมีมากกว่าหนึ่งเสมอ"},
	8: {"level": 11, "text": "จงกล้าลองในโลกคู่ขนาน"},
	9: {"level": 12, "text": "แล้วนำสิ่งที่ดีที่สุดกลับมารวมกัน"},
	10: {"level": 13, "text": "ความรู้ที่ไม่ถูกแบ่งปัน"},
	11: {"level": 14, "text": "ย่อมดับไปพร้อมผู้ครอบครอง"},
	12: {"level": 15, "text": "ข้ารอเจ้าอยู่ที่คลังเวทกลาง"},
}

static var _regex: RegEx


## เลขเศษที่ข้อความเนื้อเรื่องประกาศว่าได้รับ (0 = ไม่ได้ประกาศ)
static func announced(text: String) -> int:
	if _regex == null:
		_regex = RegEx.create_from_string("ได้รับเศษคัมภีร์ชิ้นที่\\s*(\\d+)")
	var found := _regex.search(text)
	return int(found.get_string(1)) if found != null else 0


## เศษที่ได้ในด่านนี้ (0 = ด่านนี้ไม่มีเศษ เช่น ด่าน 1–3 ที่ยังเป็นการเริ่มต้นเรื่อง)
static func for_level(level: int) -> int:
	for number in FRAGMENTS:
		if int(FRAGMENTS[number]["level"]) == level:
			return int(number)
	return 0


## จำนวนเศษที่ผู้เล่นมีอยู่แล้วตอนเริ่มด่าน (ได้จากด่านก่อนหน้าทั้งหมด)
static func collected_before(level: int) -> int:
	var count := 0
	for number in FRAGMENTS:
		if int(FRAGMENTS[number]["level"]) < level:
			count += 1
	return count


static func text_of(number: int) -> String:
	return str((FRAGMENTS.get(number, {}) as Dictionary).get("text", ""))
