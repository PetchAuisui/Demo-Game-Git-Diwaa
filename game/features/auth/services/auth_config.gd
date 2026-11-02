class_name AuthConfig
extends RefCounted
## "สมุดที่อยู่" ของ server บัญชีผู้ใช้: บอกว่า server อยู่ที่ไหน และกติกาการคุยกับ server
##
## ข้อควรรู้ด้านความปลอดภัย:
## 1. ตอน debug (กด F6 / รันจาก editor) เกมคุยกับ server ในเครื่องตัวเองผ่าน HTTP ธรรมดา
##    ข้อมูลไม่ได้ออกไปนอกเครื่อง จึงไม่ต้องเข้ารหัส
## 2. เกมตัวจริง (release) ต้องใช้ HTTPS เท่านั้น ไม่อย่างนั้นรหัสผ่านกับ token
##    จะวิ่งผ่านเน็ตแบบไม่เข้ารหัส คนที่อยู่ Wi-Fi เดียวกันดักอ่านได้
## 3. ห้ามใส่ความลับใดๆ ในไฟล์นี้ เพราะผู้เล่นแกะไฟล์เกมอ่านได้ทุกบรรทัด

# ที่อยู่ server ตอนพัฒนา: server ที่รันในเครื่องตัวเองด้วย `dotnet run` (port ดูได้จากบรรทัด "Now listening on")
const DEV_BASE_URL := "http://127.0.0.1:5000"
# ที่อยู่ server ตัวจริง: TODO แก้เป็นที่อยู่จริงตอนเลือก host ได้แล้ว
# ใช้ .invalid ไว้ก่อน เพราะเป็นโดเมนที่ไม่มีอยู่จริงแน่นอน เกมจึงไม่มีทางส่งข้อมูลไปผิดที่
const RELEASE_BASE_URL := "https://auth.invalid"
# ส่วนต้นของ path ที่ทุก endpoint ของบัญชีใช้ร่วมกัน (ต้องตรงกับ AccountEndpoints.cs)
const API_PREFIX := "/api/v1/accounts"

# รอคำตอบได้นานสุดกี่วินาที ถ้าเกินถือว่าเน็ตมีปัญหา ผู้ใช้จะได้ไม่ต้องรอค้างไปเรื่อยๆ
const REQUEST_TIMEOUT_SEC := 10.0
# ใช้ตอนเช็คว่า server ยังอยู่ไหม (ตอนเปิดหน้า login) ตั้งให้สั้นกว่า จะได้รู้เร็วว่าต้องขึ้นปุ่มเล่นออฟไลน์หรือเปล่า
const HEALTH_TIMEOUT_SEC := 5.0
# รับคำตอบได้ใหญ่สุดเท่าไหร่ (64 KB) คำตอบจริงของ server เล็กกว่านี้มาก
# กันไม่ให้ server ปลอมส่งข้อมูลก้อนใหญ่มาจนเกมค้าง
const MAX_RESPONSE_BYTES := 64 * 1024


## คืนที่อยู่ server ที่ build นี้ต้องใช้
## ถ้าเป็นเกมตัวจริงแต่ที่อยู่ไม่ขึ้นต้นด้วย https:// จะคืนค่า "" เพื่อให้หยุดส่ง แทนที่จะส่งแบบไม่ปลอดภัย
static func base_url() -> String:
	if OS.is_debug_build():
		return DEV_BASE_URL
	if not RELEASE_BASE_URL.begins_with("https://"):
		push_error("AuthConfig: release builds require an https:// server address.")
		return ""
	return RELEASE_BASE_URL
