class_name PlayerFileSystem
extends RefCounted
## ไฟล์ของผู้เล่นใน sandbox (ทุก path เป็น path สัมพัทธ์กับ repository ของผู้เล่น)
## เมธอดที่เปลี่ยนแปลงหรืออ่านไฟล์คืน OpResult เพื่อรายงานข้อผิดพลาดที่แสดงให้ผู้เล่นอ่านได้


func write_all_text(_relative_path: String, _content: String) -> OpResult:
	push_error("PlayerFileSystem.write_all_text ยังไม่ได้ implement")
	return OpResult.failure("not implemented")


## value = เนื้อหาไฟล์ หรือ null เมื่อไม่พบไฟล์
func read_all_text(_relative_path: String) -> OpResult:
	push_error("PlayerFileSystem.read_all_text ยังไม่ได้ implement")
	return OpResult.failure("not implemented")


func create_directory(_relative_path: String) -> OpResult:
	push_error("PlayerFileSystem.create_directory ยังไม่ได้ implement")
	return OpResult.failure("not implemented")


func move(_source_relative_path: String, _destination_relative_path: String) -> OpResult:
	push_error("PlayerFileSystem.move ยังไม่ได้ implement")
	return OpResult.failure("not implemented")


## value = true เมื่อลบจริง, false เมื่อไม่พบไฟล์
func delete(_relative_path: String) -> OpResult:
	push_error("PlayerFileSystem.delete ยังไม่ได้ implement")
	return OpResult.failure("not implemented")


## value = true เมื่อลบจริง, false เมื่อไม่พบโฟลเดอร์
func delete_directory(_relative_path: String, _recursive: bool = false) -> OpResult:
	push_error("PlayerFileSystem.delete_directory ยังไม่ได้ implement")
	return OpResult.failure("not implemented")


func list_files() -> Array[String]:
	push_error("PlayerFileSystem.list_files ยังไม่ได้ implement")
	return []


func list_entries() -> Array[PlayerWorkspaceEntry]:
	push_error("PlayerFileSystem.list_entries ยังไม่ได้ implement")
	return []
