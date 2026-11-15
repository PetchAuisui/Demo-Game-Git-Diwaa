class_name SceneLoader
extends RefCounted

## ตัวช่วยโหลดฉากล่วงหน้าแบบ Background Threaded Loading และสลับฉากทันที
## - request_preload(): ขอโหลดล่วงหน้าเพียงครั้งเดียวต่อ path (ไม่ request ซ้ำขณะยังโหลด/ยังไม่ถูกนำไปใช้)
## - change_scene(): ใช้ผลที่โหลดไว้ (ถ้ามี) แล้วสลับฉาก ถ้าไม่มีจะโหลดแบบปกติแทน
## - flush_preloads(): เก็บกวาด resource ที่ preload ค้างไว้ ป้องกัน ObjectDB leak ตอนออกจากเกม

static var _pending_preloads: Dictionary = {}


static func request_preload(path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
		_pending_preloads[path] = true
		return
	if ResourceLoader.load_threaded_request(path) == OK:
		_pending_preloads[path] = true


## คืนค่า false ถ้าไม่พบไฟล์ฉากหรือเปลี่ยนฉากไม่สำเร็จ
static func change_scene(tree: SceneTree, path: String) -> bool:
	if tree == null or path.is_empty() or not ResourceLoader.exists(path):
		return false
	var packed: PackedScene = null
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
		packed = ResourceLoader.load_threaded_get(path) as PackedScene
	_pending_preloads.erase(path)
	if packed == null:
		packed = load(path) as PackedScene
	if packed:
		return tree.change_scene_to_packed(packed) == OK
	return tree.change_scene_to_file(path) == OK


## เก็บกวาด resource ที่ preload ค้างไว้ ป้องกัน ObjectDB leak
## - wait = false (ค่าเริ่มต้น): เก็บกวาดเฉพาะที่โหลดเสร็จแล้วทันที ไม่บล็อก Main Thread เพื่อป้องกันอาการกระตุกตอนเปลี่ยนฉาก
## - wait = true: รอจนกว่าโหลดเสร็จทั้งหมด (ใช้ตอนปิดหน้าต่างเกม)
static func flush_preloads(wait: bool = false) -> void:
	var paths := _pending_preloads.keys()
	for path_var: Variant in paths:
		var path := str(path_var)
		var status := ResourceLoader.load_threaded_get_status(path)
		if wait and status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			ResourceLoader.load_threaded_get(path)
			_pending_preloads.erase(path)
		elif status == ResourceLoader.THREAD_LOAD_LOADED:
			ResourceLoader.load_threaded_get(path)
			_pending_preloads.erase(path)
		elif status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_pending_preloads.erase(path)
