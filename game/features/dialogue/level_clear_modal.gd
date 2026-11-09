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
@export var replay_scene_path: String = "res://features/dialogue/level_dialogue_view.tscn"
@export var level_select_scene_path: String = "res://features/level_select/level_select_view.tscn"

@onready var level_title_label: Label = $WindowPanel/VBoxMain/Margin/VBox/LevelTitle
@onready var keyword_header_label: Label = $WindowPanel/VBoxMain/Margin/VBox/KeywordPanel/VBoxKW/Header
@onready var keyword_body_label: Label = $WindowPanel/VBoxMain/Margin/VBox/KeywordPanel/VBoxKW/Body

func _ready() -> void:
	_apply_level_info()
	if btn_replay:
		btn_replay.focus_mode = Control.FOCUS_NONE
		btn_replay.pressed.connect(_on_replay_pressed)
	if btn_level_select:
		btn_level_select.focus_mode = Control.FOCUS_NONE
		btn_level_select.pressed.connect(_on_level_select_pressed)
	if btn_next_level:
		btn_next_level.focus_mode = Control.FOCUS_NONE
		btn_next_level.pressed.connect(_on_next_level_pressed)

## ดึงข้อมูลด่านที่เพิ่งเล่นจบ (ด่านที่เลือกไว้) มาแสดงชื่อคำสั่งและคีย์เวิร์ดประจำด่าน
func _apply_level_info() -> void:
	level_number = GameProgressManager.get_selected_level_number()
	var data := LevelDataLoader.load_data(level_number)
	if not data.is_empty():
		level_command = LevelDataLoader.get_display_command(level_number, data)
		level_keyword = str(data.get("clear_keyword", level_keyword))
	if level_title_label:
		level_title_label.text = "ด่านที่ %d : %s" % [level_number, level_command]
	if keyword_header_label:
		keyword_header_label.text = "[คีย์เวิร์ดประจำด่านที่ %d]" % level_number
	if keyword_body_label:
		keyword_body_label.text = level_keyword

func _on_replay_pressed() -> void:
	var target = replay_scene_path
	if target == "" or not ResourceLoader.exists(target):
		target = "res://features/dialogue/level_dialogue_view.tscn"
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
