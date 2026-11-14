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
const TOTAL_LEVELS := 40

## ตัวแปรส่งผ่านสถานะระหว่าง Scene ชั่วคราว (Transient Session State)
## ใช้แทนการประกาศ static var ไว้บน UI View Script โดยตรง
## - ด่านที่ผู้เล่นเลือกจากหน้าเลือกด่าน
## - ฉากที่ปุ่มออกของ Sandbox จะพากลับไป ("" = ค่าเริ่มต้นของ Sandbox คือหน้าเลือกด่าน)
static var _selected_level_number: int = 1
static var _sandbox_return_scene: String = ""
## ขั้นเล่นจริงที่ Sandbox ต้องแสดงแผงภารกิจ (0 = เปิด Sandbox แบบอิสระ) ตั้งโดยหน้าบทสนทนาก่อนเปลี่ยนฉาก
static var _pending_mission_step: int = 0
## ช่วงบทสนทนาที่หน้าบทสนทนาต้องเริ่มต่อหลังจบขั้นเล่นจริง (-1 = เริ่มตามปกติ) อ่านแล้วล้างทันที
static var _resume_dialogue_phase: int = -1

## การสุ่มสีหมวกเวทมนตร์ 3 สี (ม่วง, ฟ้า, เขียว) เมื่อเริ่มเข้าเกมใหม่ อัตราดรอปเท่ากัน 1/3 (Equal Drop Rate)
enum HatColor {
	PURPLE = 0,
	BLUE = 1,
	GREEN = 2,
}

const HAT_TEXTURE_PATHS: Array[String] = [
	"res://assets/art/hats/hat_witch_purple.png",
	"res://assets/art/hats/hat_witch_blue.png",
	"res://assets/art/hats/hat_witch_green.png",
]

static var _current_hat_color: int = -1

static func randomize_hat_color() -> int:
	_current_hat_color = randi() % 3
	return _current_hat_color

static func get_current_hat_color() -> int:
	if _current_hat_color < 0:
		randomize_hat_color()
	return _current_hat_color

static func get_current_hat_texture() -> Texture2D:
	var idx := get_current_hat_color()
	var path := HAT_TEXTURE_PATHS[idx]
	if ResourceLoader.exists(path):
		return load(path)
	return null

static func get_current_hat_color_name() -> String:
	match get_current_hat_color():
		HatColor.PURPLE:
			return "Purple"
		HatColor.BLUE:
			return "Blue"
		HatColor.GREEN:
			return "Green"
		_:
			return "Unknown"

static func set_selected_level_number(level_num: int) -> void:
	_selected_level_number = level_num

static func get_selected_level_number() -> int:
	return _selected_level_number

static func set_sandbox_return_scene(scene_path: String) -> void:
	_sandbox_return_scene = scene_path

static func get_sandbox_return_scene() -> String:
	return _sandbox_return_scene

static func set_pending_mission_step(step: int) -> void:
	_pending_mission_step = step

static func get_pending_mission_step() -> int:
	return _pending_mission_step

static func set_resume_dialogue_phase(phase: int) -> void:
	_resume_dialogue_phase = phase

static func consume_resume_dialogue_phase() -> int:
	var phase := _resume_dialogue_phase
	_resume_dialogue_phase = -1
	return phase


static var _level_time_remaining: float = -1.0
static var _level_timer_active_level: int = -1

static func reset_level_timer(level_num: int, time_seconds: float) -> void:
	_level_timer_active_level = level_num
	_level_time_remaining = time_seconds

static func get_level_time_remaining(level_num: int) -> float:
	if _level_timer_active_level == level_num:
		return _level_time_remaining
	return -1.0

static func set_level_time_remaining(level_num: int, remaining: float) -> void:
	_level_timer_active_level = level_num
	_level_time_remaining = remaining

static func clear_level_timer(level_num: int = -1) -> void:
	if level_num == -1 or _level_timer_active_level == level_num:
		_level_time_remaining = -1.0
		_level_timer_active_level = -1


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
	for i in range(1, TOTAL_LEVELS + 1):
		cfg.set_value(SECTION_LEVELS, "level_%d" % i, false)
	cfg.save(SAVE_PATH)
	_cached_cfg = cfg
	_selected_level_number = 1
	_sandbox_return_scene = ""
	_pending_mission_step = 0
	_resume_dialogue_phase = -1
