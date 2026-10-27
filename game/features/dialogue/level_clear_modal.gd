extends Control

## หน้าต่างสรุปผลเมื่อผ่านด่าน (Level Clear / Success Modal)
## แสดงโครงสร้างหน้าต่าง Success พร้อมผลดาว สรุปคะแนน คีย์เวิร์ดประจำด่าน
## และปุ่มควบคุม 3 ปุ่ม: "เล่นอีกครั้ง", "กลับไปหน้าเลือกด่าน", "ด่านต่อไป"

@onready var btn_replay: Button = $WindowPanel/VBoxMain/Margin/VBox/HBoxButtons/BtnReplay
@onready var btn_level_select: Button = $WindowPanel/VBoxMain/Margin/VBox/HBoxButtons/BtnLevelSelect
@onready var btn_next_level: Button = $WindowPanel/VBoxMain/Margin/VBox/HBoxButtons/BtnNextLevel

@export var level_number: int = 1
@export var level_command: String = "git version"
@export var level_keyword: String = "การตรวจสอบพลัง หมายถึง git --version"
@export var replay_scene_path: String = "res://features/cutscene/inside_tower_cutscene.tscn"
@export var level_select_scene_path: String = "res://features/level_select/level_select_view.tscn"

func _ready() -> void:
	if btn_replay:
		btn_replay.focus_mode = Control.FOCUS_NONE
		btn_replay.pressed.connect(_on_replay_pressed)
	if btn_level_select:
		btn_level_select.focus_mode = Control.FOCUS_NONE
		btn_level_select.pressed.connect(_on_level_select_pressed)
	if btn_next_level:
		btn_next_level.focus_mode = Control.FOCUS_NONE
		btn_next_level.pressed.connect(_on_next_level_pressed)

func _on_replay_pressed() -> void:
	var target = replay_scene_path
	if target == "" or not ResourceLoader.exists(target):
		target = "res://features/cutscene/inside_tower_cutscene.tscn"
	get_tree().change_scene_to_file(target)

func _on_level_select_pressed() -> void:
	var target = level_select_scene_path
	if target == "" or not ResourceLoader.exists(target):
		target = "res://features/level_select/level_select_view.tscn"
	get_tree().change_scene_to_file(target)

func _on_next_level_pressed() -> void:
	# ปัจจุบันด่านถัดไปยังเป็นโครง จึงเปิดหน้าเลือกด่าน
	_on_level_select_pressed()

func _input(event: InputEvent) -> void:
	# ปิดการใช้งานปุ่ม Spacebar และ Enter บนหน้าดาว เพื่อให้ผู้เล่นใช้การคลิกเมาส์เท่านั้นตามคำขอ
	if event is InputEventKey:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
			get_viewport().set_input_as_handled()
			_on_level_select_pressed()
