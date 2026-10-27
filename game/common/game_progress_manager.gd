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

## ตัวแปรส่งผ่านสถานะระหว่าง Scene ชั่วคราว (Transient Session State)
## ใช้แทนการประกาศ static var ไว้บน UI View Script โดยตรง
## พร้อมฟังก์ชัน consume ที่จะเคลียร์ค่ากลับเป็น 0 ทันทีที่อ่าน ป้องกันค่าค้างข้าม Session
static var _pending_dialogue_phase: int = 0

static func set_pending_dialogue_phase(phase: int) -> void:
	_pending_dialogue_phase = phase

static func consume_pending_dialogue_phase() -> int:
	var phase := _pending_dialogue_phase
	_pending_dialogue_phase = 0
	return phase

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
