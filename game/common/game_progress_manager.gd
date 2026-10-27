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

static func has_seen_intro_cutscene() -> bool:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err == OK:
		return cfg.get_value(SECTION_PROGRESS, KEY_INTRO_SEEN, false)
	return false

static func set_intro_cutscene_seen(seen: bool = true) -> void:
	var cfg := ConfigFile.new()
	var _err := cfg.load(SAVE_PATH)
	cfg.set_value(SECTION_PROGRESS, KEY_INTRO_SEEN, seen)
	cfg.save(SAVE_PATH)

static func reset_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION_PROGRESS, KEY_INTRO_SEEN, false)
	cfg.save(SAVE_PATH)
