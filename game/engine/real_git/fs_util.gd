class_name FsUtil
extends RefCounted
## ตัวช่วยจัดการไฟล์/โฟลเดอร์ด้วย path แบบ absolute (ใช้ "/" เป็นตัวคั่นเสมอ)

static func is_windows() -> bool:
	return OS.get_name() == "Windows"


static func normalize(path: String) -> String:
	return path.replace("\\", "/")


static func is_rooted(path: String) -> bool:
	var p := normalize(path)
	return p.begins_with("/") or (p.length() >= 2 and p[1] == ":")


## เทียบ path โดยไม่สนตัวพิมพ์บน Windows
static func same_path(a: String, b: String) -> bool:
	if is_windows():
		return a.to_lower() == b.to_lower()
	return a == b


static func starts_with_path(path: String, prefix: String) -> bool:
	if is_windows():
		return path.to_lower().begins_with(prefix.to_lower())
	return path.begins_with(prefix)


## path เต็มที่ตัด . และ .. แล้ว ไม่มี "/" ท้าย
static func full_path(path: String) -> String:
	var p := normalize(path)
	if not is_rooted(p):
		p = normalize(ProjectSettings.globalize_path("res://")).path_join(p)
	p = p.simplify_path()
	if p.length() > 1 and p.ends_with("/"):
		p = p.substr(0, p.length() - 1)
	return p


static func dir_exists(path: String) -> bool:
	return DirAccess.dir_exists_absolute(path)


static func file_exists(path: String) -> bool:
	return FileAccess.file_exists(path)


static func make_dirs(path: String) -> bool:
	return DirAccess.make_dir_recursive_absolute(path) == OK


static func is_symlink(path: String) -> bool:
	var dir := DirAccess.open(path.get_base_dir())
	return dir != null and dir.is_link(path.get_file())


## ชื่อไฟล์/โฟลเดอร์ย่อย (รวมไฟล์ซ่อน) ของโฟลเดอร์ ไม่รวม . และ ..
static func list_children(path: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(path)
	if dir == null:
		return result
	dir.include_hidden = true
	dir.include_navigational = false
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		result.append(name)
		name = dir.get_next()
	dir.list_dir_end()
	return result


static func dir_has_entries(path: String) -> bool:
	return not list_children(path).is_empty()


static func write_text(path: String, content: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(content)
	file.close()
	return true


## null เมื่ออ่านไม่ได้
static func read_text(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var text := file.get_as_text()
	file.close()
	return text


static func delete_recursive(path: String) -> void:
	if not dir_exists(path):
		return
	for child in list_children(path):
		var child_path := path.path_join(child)
		if dir_exists(child_path) and not is_symlink(child_path):
			delete_recursive(child_path)
		else:
			DirAccess.remove_absolute(child_path)
	DirAccess.remove_absolute(path)
