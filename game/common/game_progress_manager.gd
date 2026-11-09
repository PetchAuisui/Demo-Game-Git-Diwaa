class_name GameProgressManager
extends RefCounted

## ระบบจัดการการบันทึกความคืบหน้าของผู้เล่น (Player Progress Manager)
## บันทึกสถานะลงใน user://game_progress.cfg
## - ตรวจสอบว่าผู้เล่นเคยดูคัตซีนเปิดตัวแล้วหรือไม่ (has_seen_intro_cutscene)
##   ถ้ายังไม่เคยดู -> บังคับดูคัตซีนเปิดตัว (cut_scence_normal.tscn)
##   ถ้าเคยดูแล้ว -> กด START จะพาเข้าสู่หน้าเลือกรวมด่าน (level_select_view.tscn) ทันที

const SAVE_PATH := "user://game_progress.cfg"
const SECTION_PROGRESS := "progress"
const KEY_INTRO_SEEN := "has_seen_intro_cutscene"
const SECTION_LEVELS := "levels_cleared"

## ตัวแปรส่งผ่านสถานะระหว่าง Scene ชั่วคราว (Transient Session State)
## ใช้แทนการประกาศ static var ไว้บน UI View Script โดยตรง
## พร้อมฟังก์ชัน consume ที่จะเคลียร์ค่ากลับเป็น 0 ทันทีที่อ่าน ป้องกันค่าค้างข้าม Session
static var _pending_dialogue_phase: int = 0
static var _selected_level_number: int = 1
static var _current_gameplay_step: int = 0
static var _gameplay_return_scene: String = "res://features/cutscene/inside_tower_cutscene.tscn"

static func set_selected_level_number(level_num: int) -> void:
	_selected_level_number = level_num

static func get_selected_level_number() -> int:
	return _selected_level_number

static func set_pending_dialogue_phase(phase: int) -> void:
	_pending_dialogue_phase = phase

static func consume_pending_dialogue_phase() -> int:
	var phase := _pending_dialogue_phase
	_pending_dialogue_phase = 0
	return phase

static func set_current_gameplay_step(step: int) -> void:
	_current_gameplay_step = step

static func get_current_gameplay_step() -> int:
	return _current_gameplay_step

static func set_gameplay_return_scene(scene_path: String) -> void:
	_gameplay_return_scene = scene_path

static func get_gameplay_return_scene() -> String:
	return _gameplay_return_scene

static var _cached_cfg: ConfigFile = null

static func _get_config() -> ConfigFile:
	if _cached_cfg == null:
		_cached_cfg = ConfigFile.new()
		if FileAccess.file_exists(SAVE_PATH):
			var err := _cached_cfg.load(SAVE_PATH)
			if err != OK:
				# ไฟล์เซฟเสีย/อ่านไม่ได้: สำรองไฟล์เดิมไว้ก่อน เพื่อไม่ให้การบันทึกครั้งถัดไปเขียนทับความคืบหน้าจนหายหมด
				var abs_path := ProjectSettings.globalize_path(SAVE_PATH)
				var backup_err := DirAccess.copy_absolute(abs_path, abs_path + ".corrupt.bak")
				push_warning("[GameProgressManager] Failed to load %s (error %d). Backup %s." % [
					SAVE_PATH, err, "saved to game_progress.cfg.corrupt.bak" if backup_err == OK else "FAILED (error %d)" % backup_err])
				_cached_cfg = ConfigFile.new()
	return _cached_cfg

static func _save_config() -> void:
	if _cached_cfg != null:
		_cached_cfg.save(SAVE_PATH)

static func has_seen_intro_cutscene() -> bool:
	return _get_config().get_value(SECTION_PROGRESS, KEY_INTRO_SEEN, false)

static func set_intro_cutscene_seen(seen: bool = true) -> void:
	var cfg := _get_config()
	cfg.set_value(SECTION_PROGRESS, KEY_INTRO_SEEN, seen)
	_save_config()

static func is_level_cleared(level_num: int) -> bool:
	return _get_config().get_value(SECTION_LEVELS, "level_%d" % level_num, false)

static func set_level_cleared(level_num: int, cleared: bool = true) -> void:
	var cfg := _get_config()
	cfg.set_value(SECTION_LEVELS, "level_%d" % level_num, cleared)
	_save_config()

static func reset_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION_PROGRESS, KEY_INTRO_SEEN, false)
	for i in range(1, 16):
		cfg.set_value(SECTION_LEVELS, "level_%d" % i, false)
	cfg.save(SAVE_PATH)
	_cached_cfg = cfg
