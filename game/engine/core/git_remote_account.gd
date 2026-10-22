class_name GitRemoteAccount
extends RefCounted
## บัญชีผู้เล่นบน GitHub จำลอง: มีได้หลาย repo เลือกเปิดและสร้างใหม่ได้เหมือน GitHub จริง
## แต่ละ repo เป็น GitRemoteHost ของตัวเอง (PR/branch แยกกัน)

var owner: String = ""


func list_repositories() -> Array[RemoteRepositoryInfo]:
	push_error("GitRemoteAccount.list_repositories ยังไม่ได้ implement")
	return []


## host ของ repo ตามชื่อ (ไม่สนตัวพิมพ์ใหญ่เล็ก) หรือ null ถ้าไม่มี
func open_repository(_name: String) -> GitRemoteHost:
	push_error("GitRemoteAccount.open_repository ยังไม่ได้ implement")
	return null


## สร้าง repo ว่างใหม่ ชื่อซ้ำหรือไม่ถูกรูปแบบจะคืน OpResult ที่ล้มเหลวพร้อมข้อความที่ผู้เล่นอ่านได้
## (value = RemoteRepositoryInfo เมื่อสำเร็จ)
func create_repository(_name: String, _description: String) -> OpResult:
	push_error("GitRemoteAccount.create_repository ยังไม่ได้ implement")
	return OpResult.failure("not implemented")
