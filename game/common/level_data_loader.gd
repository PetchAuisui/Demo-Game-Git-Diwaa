class_name LevelDataLoader
extends RefCounted

## ตัวโหลดข้อมูลด่าน (Level Data Loader)
## อ่านข้อมูลจาก res://features/dialogue/levels/level_%02d.gd (static func get_data())
## ใช้ร่วมกันระหว่างหน้าบทสนทนา, หน้าเลือกด่าน, Sandbox และหน้าสรุปผลด่าน

const LEVEL_PATH_FORMAT := "res://features/dialogue/levels/level_%02d.gd"


static func get_level_path(level_num: int) -> String:
	return LEVEL_PATH_FORMAT % level_num


static func has_level(level_num: int) -> bool:
	return ResourceLoader.exists(get_level_path(level_num))


## คืนค่าข้อมูลด่าน หรือ Dictionary ว่างถ้าไม่มีไฟล์ข้อมูล
static func load_data(level_num: int) -> Dictionary:
	var path := get_level_path(level_num)
	if not ResourceLoader.exists(path):
		return {}
	var script = load(path)
	if script and script.has_method("get_data"):
		return script.get_data()
	return {}


## ชื่อคำสั่งหลักของด่าน สำหรับแสดงบนการ์ดเลือกด่านและหน้าสรุปผล
static func get_display_command(level_num: int, data: Dictionary = {}) -> String:
	if data.is_empty():
		data = load_data(level_num)
	if data.has("commands") and data["commands"].size() > 0:
		return str(data["commands"][0]).replace("--", "")
	if data.has("title"):
		return str(data["title"])
	return "git version" if level_num == 1 else "git command"

