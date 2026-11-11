class_name SceneLoader
extends RefCounted

## ตัวช่วยโหลดฉากล่วงหน้าแบบ Background Threaded Loading และสลับฉากทันที
## - request_preload(): ขอโหลดล่วงหน้าเพียงครั้งเดียวต่อ path (ไม่ request ซ้ำขณะยังโหลด/ยังไม่ถูกนำไปใช้)
## - change_scene(): ใช้ผลที่โหลดไว้ (ถ้ามี) แล้วสลับฉาก ถ้าไม่มีจะโหลดแบบปกติแทน


static func request_preload(path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
		return
	ResourceLoader.load_threaded_request(path)


## คืนค่า false ถ้าไม่พบไฟล์ฉากหรือเปลี่ยนฉากไม่สำเร็จ
static func change_scene(tree: SceneTree, path: String) -> bool:
	if tree == null or path.is_empty() or not ResourceLoader.exists(path):
		return false
	var packed: PackedScene = null
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
		packed = ResourceLoader.load_threaded_get(path) as PackedScene
	if packed == null:
		packed = load(path) as PackedScene
	if packed:
		return tree.change_scene_to_packed(packed) == OK
	return tree.change_scene_to_file(path) == OK
